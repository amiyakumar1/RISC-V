module ff_cache #(
            parameter       s_offset = 5,
            parameter       s_index  = 4,
            parameter       s_tag    = 32 - s_offset - s_index,
            parameter       s_mask   = 2**s_offset,
            parameter       s_line   = 8*s_mask,
            parameter       num_sets = 2**s_index
)(
    input                   clk,
    input                   rst,

    /* CPU side signals */
    input   logic   [31:0]  mem_address,
    input   logic           mem_read,
    input   logic           mem_write,
    input   logic   [31:0]  mem_byte_enable,
    output  logic   [255:0] mem_rdata,
    input   logic   [255:0] mem_wdata,
    output  logic           mem_resp,

    /* Memory side signals */
    output  logic   [31:0]  pmem_address,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic   [255:0] pmem_rdata,
    output  logic   [255:0] pmem_wdata,
    input   logic           pmem_resp
);

    /*
    ****************************************************************************************************************************************************************
    ****************************************************************************************************************************************************************
    ****************************************************************************************************************************************************************
    ****************************************************************************************************************************************************************
    ****************************************************************************CONTROL*****************************************************************************
    ****************************************************************************************************************************************************************
    ****************************************************************************************************************************************************************
    ****************************************************************************************************************************************************************
    ****************************************************************************************************************************************************************
    */
logic [22:0] tag;
logic [3:0] set;
logic [4:0] offset;
assign tag = mem_address[31:9];
assign set = mem_address[8:5];
assign offset = mem_address[4:0];

logic load_data;
logic load_tag;
logic load_valid;
logic load_dirty;
logic load_plru;
logic [255:0] data_in;
logic [22:0] tag_in;
logic dirty_in;
logic [1:0] plru_in;

logic [255:0] data_out [4];
logic [22:0] tag_out [4];
logic dirty_out [4];
logic [1:0] plru_out [16];
logic valid_out [4];
logic valid_we [4];
logic data_we [4];
logic tag_we [4];
logic plru_we [16];
logic dirty_we [4];

logic [31:0] write_mask;

logic [1:0] way;
logic hit;

logic [31:0] mem_address_store;

assign mem_rdata = data_out[way];

// list of states
enum int unsigned {
    IDLE,
    CACHE_RW,
    PMEM_R,
    PMEM_W

} state, next_state;

/*
internal signals (loads)
    load_data,
    load_tag,
    load_valid,
    load_dirty, 
    load_plru

    (inputs)
    data_in,
    tag_in,
    valid_in,  -- dont need this signal, i can just tie it to 1
    dirty_in,
    plru_in,

going to memory
    pmem_wdata
    pmem_address
    pmem_read
    pmem_write

going to cpu
    mem_rdata
    mem_resp

*/

    always_comb
    begin : state_actions

        // default actions -- set all write enables low (active low)
        for (int idx=0; idx<4; idx++) begin
            data_we[idx] = 1'b1;
            tag_we[idx] = 1'b1;
            valid_we[idx] = 1'b1;
            dirty_we[idx] = 1'b1;
        end

        for (int idx2 = 0; idx2<16; idx2++) begin
            plru_we[idx2] = 1'b1;
        end

        // these signals should not matter, since the loads are all low
        data_in = 256'b0;
        tag_in = 23'b0;
        dirty_in = 1'b0;
        plru_in = 2'b00;

        write_mask = 32'hffffffff;

        // going to memory
        pmem_wdata = 256'b0;
        pmem_address = 32'b0;
        pmem_read = 1'b0;
        pmem_write = 1'b0;

        // going to cpu
        mem_resp = 1'b0;

        case(state)
            IDLE : begin
                if (mem_address_store == mem_address) mem_resp = 1'b1;
            end

            CACHE_RW : begin
                // default values
                // internal signals
                // load_data = 1'b0;
                // load_tag = 1'b0;
                // load_valid = 1'b0;
                // load_dirty = 1'b0;
                // load_plru = 1'b0;

                data_we[way] = 1'b1;
                tag_we[way] = 1'b1;
                valid_we[way] = 1'b1;
                dirty_we[way] = 1'b1;
                plru_we[set] = 1'b1;

                // data_in = 256'b0;
                tag_in = 23'b0;
                dirty_in = 1'b0;
                plru_in = 2'b0;
                // going to memory
                pmem_wdata = 256'b0;
                pmem_address = 32'b0;
                pmem_read = 1'b0;
                pmem_write = 1'b0;
                // going to cpu
                mem_resp = 1'b0;
                mem_address_store = '0;

                // just outline the four cases here, read hit, write hit, r/w miss clean, r/w miss dirty

                // case 1: read hit. in read hits we only get data out of data array
                if (!mem_write && mem_read && hit) begin
                    // internal signals
                    // load_plru = 1'b1;
                    plru_we[set] = 1'b0;
                    plru_in = way;

                    // going to cpu -- mem_resp should be 1 on hits of any kind
                    // and on reads, mem_rdata should be the data output
                    mem_resp = 1'b1;
                    mem_address_store = mem_address;
                end

                // case 2: write hit
                else if (mem_write && !mem_read && hit) begin
                    // internal signals
                    // load_data = 1'b1; // in write hit, we want to write  new data in
                    // load_dirty = 1'b1; // we are dirtying the data by writing in new data
                    // load_plru = 1'b1;
                    data_we[way] = 1'b0;
                    write_mask = mem_byte_enable;
                    dirty_we[way] = 1'b0;
                    plru_we[set] = 1'b0;

                    data_in = mem_wdata; // should be whatever data we get in from cpu (mem_wdata)
                    dirty_in = 1'b1;
                    plru_in = way; // double check this

                    // going to cpu -- mem_resp should be 1 on hits of any kind
                    // and on reads, mem_rdata should be the data output
                    mem_resp = 1'b1;
                    mem_address_store = mem_address;
                end

                // case 3: r/w miss clean (read data from pmem and store in cache)
                else if (!hit && !dirty_out[way]) begin
                    // change nothing
                end

                // case 4: r/w miss dirty (write dirty data to pmem)
                else if (!hit && dirty_out[way]) begin
                    // change nothing
                end
            end

            PMEM_R : begin
                // internal signals
                // load_data = 1'b1; // in clean miss, we should write new data into cache
                // load_tag = 1'b1;    // likewise we write new tag into cache
                // load_valid = 1'b1;  // make the cacheline valid on a miss
                // load_dirty = 1'b0; 
                // load_plru = 1'b0;

                data_we[way] = 1'b0;
                write_mask = 32'hffffffff;
                tag_we[way] = 1'b0;
                valid_we[way] = 1'b0;
                dirty_we[way] = 1'b1;
                plru_we[set] = 1'b1;

                data_in = pmem_rdata; // should be whatever data we get in from pmem (pmem_rdata)
                tag_in = tag; // just the tag from the cpu
                dirty_in = 1'b0;
                plru_in = way; // double check this

                // going to memory -- we are reading data at address {tag,set,5'b00000} from 
                pmem_wdata = 256'b0;
                pmem_address = {tag,set,5'b00000};
                pmem_read = 1'b1;
                pmem_write = 1'b0;

                // going to cpu
                mem_resp = 1'b0;
            end

            PMEM_W : begin
                // internal signals
                // load_data = 1'b0; // we are not writing to cache 
                // load_tag = 1'b0;
                // load_valid = 1'b0;
                // load_dirty = 1'b1; // we are writing dirty data to pmem, so write a 0 to dirty array because now everything lines up
                // load_plru = 1'b0;

                data_we[way] = 1'b1;
                tag_we[way] = 1'b1;
                valid_we[way] = 1'b1;
                dirty_we[way] = 1'b0;
                plru_we[set] = 1'b1;

                // data_in = 256'b0;
                tag_in = 23'b0; 
                dirty_in = 1'b0;
                plru_in = 2'b0;

                // going to memory -- we are writing what is currently in the data array to pmem address  {tag_array_n[set],set,5'b00000}
                pmem_wdata = data_out[way];
                pmem_address = {tag_out[way],set,5'b00000};
                pmem_read = 1'b0;
                pmem_write = 1'b1;

                // going to cpu 
                mem_resp = 1'b0;
            end
        endcase
    end

    always_comb
    begin : next_state_logic
        next_state = IDLE;
        case(state)
            IDLE : begin
                if (mem_read || mem_write) begin
                    next_state = CACHE_RW;
                end
                else begin
                    next_state = IDLE;
                end
            end

            CACHE_RW : begin
                // if hit we good
                if (hit || (!mem_read && !mem_write)) begin
                    next_state = IDLE;
                end
                else begin
                    // dirty miss --> eviction so write to pmem
                    if (dirty_out[way]) begin
                        next_state = PMEM_W;
                    end
                    // clean miss --> just read from pmem
                    else begin
                        next_state = PMEM_R;
                    end
                end
            end

            PMEM_R : begin
                if (pmem_resp) begin
                    next_state = CACHE_RW;
                end
                else begin
                    next_state = PMEM_R;
                end
            end

            PMEM_W : begin
                if (pmem_resp) begin
                    next_state = PMEM_R;
                end
                else begin
                    next_state = PMEM_W;
                end
            end
        endcase

    end

    always_ff @(posedge clk)
    begin: next_state_assignment;
        if(rst) begin
            state <= IDLE;
        end
        else begin
        /* Assignment of next state on clock edge */
        // here all i do is just set current state to next state i think, its just the transition on the clock edge.
            state <= next_state;
        end
    end


    /*
    ****************************************************************************************************************************************************************
    ****************************************************************************************************************************************************************
    ****************************************************************************************************************************************************************
    ****************************************************************************************************************************************************************
    ****************************************************************************DATAPATH****************************************************************************
    ****************************************************************************************************************************************************************
    ****************************************************************************************************************************************************************
    ****************************************************************************************************************************************************************
    ****************************************************************************************************************************************************************
    */

    // data array
    logic [255:0] data_in_masked;
    generate for (genvar i = 0; i < 4; i++) begin : arrays
        ff_array_comb #(.s_index(4), .width(256)) data_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),
            .web0       (data_we[i]),
            // .wmask0     (write_mask),
            .addr0      (set),
            .din0       (data_in_masked),
            .dout0      (data_out[i])
        );
    end endgenerate

    always_comb begin
        		if (write_mask[0])
                data_in_masked[7:0] = data_in[7:0];  
		else
				data_in_masked[7:0] = data_out[way][7:0]; 
        if (write_mask[1])
                data_in_masked[15:8] = data_in[15:8]; 
 else 
                 data_in_masked[15:8] = data_out[way][15:8];

        if (write_mask[2])
                data_in_masked[23:16] = data_in[23:16]; 
 else 
                 data_in_masked[23:16] = data_out[way][23:16];

        if (write_mask[3])
                data_in_masked[31:24] = data_in[31:24]; 
 else 
                 data_in_masked[31:24] = data_out[way][31:24];

        if (write_mask[4])
                data_in_masked[39:32] = data_in[39:32]; 
 else 
                 data_in_masked[39:32] = data_out[way][39:32];

        if (write_mask[5])
                data_in_masked[47:40] = data_in[47:40]; 
 else 
                 data_in_masked[47:40] = data_out[way][47:40];

        if (write_mask[6])
                data_in_masked[55:48] = data_in[55:48]; 
 else 
                 data_in_masked[55:48] = data_out[way][55:48];
 
        if (write_mask[7])
                data_in_masked[63:56] = data_in[63:56]; 
 else 
                 data_in_masked[63:56] = data_out[way][63:56];

        if (write_mask[8])
                data_in_masked[71:64] = data_in[71:64]; 
 else 
                 data_in_masked[71:64] = data_out[way][71:64];

        if (write_mask[9])
                data_in_masked[79:72] = data_in[79:72]; 
 else 
	                data_in_masked[79:72] = data_out[way][79:72];

        if (write_mask[10])
                data_in_masked[87:80] = data_in[87:80]; 
 else 
                 data_in_masked[87:80] = data_out[way][87:80];

        if (write_mask[11])
                data_in_masked[95:88] = data_in[95:88]; 
 else 
                 data_in_masked[95:88] = data_out[way][95:88];

        if (write_mask[12])
                data_in_masked[103:96] = data_in[103:96]; 
 else 
                 data_in_masked[103:96] = data_out[way][103:96];

        if (write_mask[13])
                data_in_masked[111:104] = data_in[111:104]; 
 else 
                 data_in_masked[111:104] = data_out[way][111:104];

        if (write_mask[14])
                data_in_masked[119:112] = data_in[119:112]; 
 else 
                 data_in_masked[119:112] = data_out[way][119:112];

        if (write_mask[15])
                data_in_masked[127:120] = data_in[127:120]; 
 else 
                 data_in_masked[127:120] = data_out[way][127:120];

        if (write_mask[16])
                data_in_masked[135:128] = data_in[135:128]; 
 else 
                 data_in_masked[135:128] = data_out[way][135:128];

        if (write_mask[17])
                data_in_masked[143:136] = data_in[143:136]; 
 else 
                 data_in_masked[143:136] = data_out[way][143:136];

        if (write_mask[18])
                data_in_masked[151:144] = data_in[151:144]; 
 else 
                 data_in_masked[151:144] = data_out[way][151:144];

        if (write_mask[19])
                data_in_masked[159:152] = data_in[159:152]; 
 else 
                 data_in_masked[159:152] = data_out[way][159:152];

        if (write_mask[20])
                data_in_masked[167:160] = data_in[167:160]; 
 else 
                 data_in_masked[167:160] = data_out[way][167:160];

        if (write_mask[21])
                data_in_masked[175:168] = data_in[175:168]; 
 else 
                 data_in_masked[175:168] = data_out[way][175:168];

        if (write_mask[22])
                data_in_masked[183:176] = data_in[183:176]; 
 else 
                 data_in_masked[183:176] = data_out[way][183:176];

        if (write_mask[23])
                data_in_masked[191:184] = data_in[191:184]; 
 else 
                 data_in_masked[191:184] = data_out[way][191:184];

        if (write_mask[24])
                data_in_masked[199:192] = data_in[199:192]; 
 else 
                  data_in_masked[199:192] = data_out[way][199:192];

        if (write_mask[25])
                data_in_masked[207:200] = data_in[207:200]; 
 else 
                data_in_masked[207:200] = data_out[way][207:200];

        if (write_mask[26])
                data_in_masked[215:208] = data_in[215:208]; 
 else 
                 data_in_masked[215:208] = data_out[way][215:208];

        if (write_mask[27])
                data_in_masked[223:216] = data_in[223:216]; 
 else 
                 data_in_masked[223:216] = data_out[way][223:216];

        if (write_mask[28])
                data_in_masked[231:224] = data_in[231:224]; 
 else 
                 data_in_masked[231:224] = data_out[way][231:224];

        if (write_mask[29])
                data_in_masked[239:232] = data_in[239:232]; 
 else 
                 data_in_masked[239:232] = data_out[way][239:232];

        if (write_mask[30])
                data_in_masked[247:240] = data_in[247:240]; 
 else 
                 data_in_masked[247:240] = data_out[way][247:240];

        if (write_mask[31])
                data_in_masked[255:248] = data_in[255:248]; 
 else 
                 data_in_masked[255:248] = data_out[way][255:248];
    end


    // tag array
    generate for (genvar j = 0; j < 4; j++) begin
        ff_array_comb #(.s_index(4), .width(23)) tag_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),
            .web0       (tag_we[j]),
            .addr0      (set),
            .din0       (tag_in),
            .dout0      (tag_out[j])
        );
    end endgenerate

    // ******************************
    // to implement: NO EVICTION IF VALID BIT IS 0
    // ******************************
    // valid array -- 4x
    generate for (genvar k = 0; k < 4; k++) begin 
        ff_array #(.s_index(4), .width(1)) valid_array
        (
            .clk0(clk),
            .rst0(rst),
            .csb0(1'b0),
            .web0(valid_we[k]),
            .addr0(set),
            .din0(1'b1),
            .dout0(valid_out[k])
        );
    end endgenerate

    // dirty array (make x4)
    generate for (genvar m = 0; m < 4; m++) begin 
        ff_array #(.s_index(4), .width(1)) dirty_array
        (
            .clk0(clk),
            .rst0(rst),
            .csb0(1'b0),
            .web0(dirty_we[m]),
            .addr0(set),
            .din0(dirty_in),
            .dout0(dirty_out[m])
        );
    end endgenerate


    // plru array -- plru array is 16 separate arrays (one per set), where each entry is 3 bits
    // so repeat this x16

    generate for (genvar n = 0; n < 16; n++) begin 
        plru plru_array
        (
            .clk0(clk),
            .rst0(rst),
            .csb0(1'b0),
            .web0(plru_we[n]),
            .din0(plru_in),
            .dout0(plru_out[n])
        );
    end endgenerate

    // comparators for tag array -- determine hit signal
    // also determine way
    // the memory access is either a miss or a hit. on a hit, we can find the way we are writing to just by seeing which way had the hit.
    // on a miss, we have to use the plru to determine the way. no matter what type of miss (read clean, read dirty, write clean, write dirty),
    // we will always need to evict the old way and use the plru to determine which way to write to next

    // the plru is only updated in hits, because then we select a way to write to. so on misses, the way is just the output of the plru. no updating needed.

    logic sel0;
    logic sel1;
    logic sel2;
    logic sel3;

    logic [3:0] compare;

    always_comb begin
        sel0 = 1'b0;
        sel1 = 1'b0;
        sel2 = 1'b0;
        sel3 = 1'b0;
        hit = 1'b0;

        compare[0] = (tag_out[0] == tag) && valid_out[0];
        compare[1] = (tag_out[1] == tag) && valid_out[1];
        compare[2] = (tag_out[2] == tag) && valid_out[2];
        compare[3] = (tag_out[3] == tag) && valid_out[3];

        // if hit -- im using the reduction operator syntax
        if (|compare) begin
            hit = 1'b1;
            // way 0
            if (compare[0]) begin
                sel0 = 1'b1;
                way = 2'b00;
                // update PLRU
                // plru_in = way;
            end

            // way 1
            else if (compare[1]) begin
                sel1 = 1'b1;
                way = 2'b01;
                // update PLRU
                // plru_in = way;

            end

            // way 2
            else if (compare[2]) begin
                sel2 = 1'b1;
                way = 2'b10;
                // update PLRU
                // plru_in = way;
            end

            // way 3
            else begin
                sel3 = 1'b1;
                way = 2'b11;
                // update PLRU
                // plru_in = way;
            end
        end    

        // else if miss
        else begin
            way = plru_out[set];
        end

    end
    // now there are 4 cases: read hit, write hit, read miss (clean/dirty), write miss (clean/dirty)
    // here i will set up the hardware required for each of these cases

    // case 1: read hit (taken care of)
    // in a read hit, i use the hit signal and select signals generated above. all i need is the data signal mux
    // this is the output data mux for read hits, sends cache data back to cpu using "data" variable

    // case 2: write hit (taken care of)
    // this block also contains the logic for loading new information into the data array. in a write hit, also set dirty bit to 1.
    // i already took care of all the load and input signals in the control unit, so i can just wire up the enables here
    
    // here cover logic for cases 3 and 4
    // case 3: r/w miss clean
    // in this case, we simply load data from memory to cache. set up hardware for if pmem_read signal goes hgih
    // case 4: r/w miss dirty
    // in this case, we first write dirty data to memory.
    // is there any hardware needed for these states ????

endmodule : ff_cache
