module dcache #(
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
logic plru_in;

logic [255:0] data_out [2];
logic [22:0] tag_out [2];
logic dirty_out [2];
logic plru_out [16];
logic valid_out [2];
logic valid_we [2];
logic data_we [2];
logic tag_we [2];
logic plru_we [16];
logic dirty_we [2];

logic [31:0] write_mask;

logic way;
logic hit;

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
        for (int idx=0; idx<2; idx++) begin
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
        plru_in = 1'b0;

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
                plru_in = 1'b0;
                // going to memory
                pmem_wdata = 256'b0;
                pmem_address = 32'b0;
                pmem_read = 1'b0;
                pmem_write = 1'b0;
                // going to cpu
                mem_resp = 1'b0;

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
                end

                // case 3: r/w miss clean (read data from pmem and store in cache)
                else if (!hit && !dirty_out[way]) begin
                    // change nothing
                end

                // case 2: r/w miss dirty (write dirty data to pmem)
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
                plru_in = 1'b0;

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
                if (hit) begin
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
    generate for (genvar i = 0; i < 2; i++) begin : arrays
        mp3_data_array data_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (data_we[i]),
            .wmask0     (write_mask),
            .addr0      (set),
            .din0       (data_in),
            .dout0      (data_out[i])
        );
    end endgenerate

    // tag array
    generate for (genvar j = 0; j < 2; j++) begin
        mp3_tag_array tag_array (
            .clk0       (clk),
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
    generate for (genvar k = 0; k < 2; k++) begin 
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
    generate for (genvar m = 0; m < 2; m++) begin 
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
        dplru plru_array
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
    // logic sel2;
    // logic sel3;

    logic [1:0] compare;

    always_comb begin
        sel0 = 1'b0;
        sel1 = 1'b0;
        // sel2 = 1'b0;
        // sel3 = 1'b0;
        hit = 1'b0;

        compare[0] = (tag_out[0] == tag) && valid_out[0];
        compare[1] = (tag_out[1] == tag) && valid_out[1];
        // compare[2] = (tag_out[2] == tag) && valid_out[2];
        // compare[3] = (tag_out[3] == tag) && valid_out[3];

        // if hit -- im using the reduction operator syntax
        if (|compare) begin
            hit = 1'b1;
            // way 0
            if (compare[0]) begin
                sel0 = 1'b1;
                way = 1'b0;
                // update PLRU
                // plru_in = way;
            end

            // way 1
            else if (compare[1]) begin
                sel1 = 1'b1;
                way = 1'b1;
                // update PLRU
                // plru_in = way;

            end

            // way 2
            // else if (compare[2]) begin
            //     sel2 = 1'b1;
            //     way = 2'b10;
            //     // update PLRU
            //     // plru_in = way;
            // end

            // // way 3
            // else begin
            //     sel3 = 1'b1;
            //     way = 2'b11;
            //     // update PLRU
            //     // plru_in = way;
            // end
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

endmodule : dcache