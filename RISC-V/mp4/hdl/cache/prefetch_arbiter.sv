module prefetch_arbiter #(
    parameter logic[31:0] STRIDE = 32'h20
)(
    input  logic         clk,
    input  logic         rst,

    // icache signals
    input  logic [31:0]  ipmem_address,
    input  logic         ipmem_read,
    output logic [255:0] ipmem_rdata,
    output logic         ipmem_resp,

    // dcache signals
    input  logic [31:0]  dpmem_address,
    input  logic         dpmem_read,
    input  logic         dpmem_write,
    input  logic [255:0] dpmem_wdata,
    output logic [255:0] dpmem_rdata,
    output logic         dpmem_resp,

    // cacheline adapter signals
    output logic [255:0] line_i,
    input  logic [255:0] line_o,
    output logic [31:0]  address_i,
    output logic         read_i,
    output logic         write_i,
    input  logic         resp_o
);

    logic [31:0]  prefetch_addr;
    logic [255:0] cacheline;
    logic         q_prefetch;

    enum int unsigned{
        IMEM,
        DMEM,
        IDLE,
        PREFETCH
    } state, next_state;

    /* Next state assignment */
    always_ff @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            q_prefetch <= '0;
        end else begin
            state <= next_state;
        end

        /* store the cacheline and cachetag into the prefetcher */
        if (state == IMEM & resp_o) begin
            prefetch_addr <= ipmem_address + STRIDE;
            cacheline     <= ipmem_rdata;
            q_prefetch    <= dpmem_read | dpmem_write;
        end else if (state == PREFETCH) begin
            q_prefetch <= '0;
            if(resp_o) 
                cacheline <= line_o;
        end
    end

    /* Next state logic */
    always_comb begin
        next_state = IDLE;
        unique case(state)
            IMEM: begin
                if (resp_o | (ipmem_address == prefetch_addr)) begin
                    if (dpmem_read | dpmem_write) begin
                        next_state = DMEM;
                    end else begin
                        next_state = PREFETCH;
                    end
                end
                else next_state = IMEM;
            end
            DMEM: begin
                if (resp_o) begin
                    if      (ipmem_read) next_state = IMEM;
                    else if (q_prefetch) next_state = PREFETCH;
                    else                 next_state = IDLE;
                end
                else next_state = DMEM;
            end
            IDLE: begin
                if      (dpmem_read | dpmem_write)  next_state = DMEM;
                else if (ipmem_read)                next_state = IMEM;
                else                                next_state = IDLE;
            end
            PREFETCH: begin
                if (resp_o) begin
                    if      (dpmem_read | dpmem_write)  next_state = DMEM;
                    else if (ipmem_read)                next_state = IMEM;
                    else                                next_state = IDLE;
                end
                else next_state = PREFETCH;
            end
        endcase
    end


    /* State Actions */
    always_comb begin

        /* default values on an IDLE */
        read_i      = '0;
        write_i     = '0;
        ipmem_rdata = '0;
        ipmem_resp  = '0;
        dpmem_rdata = '0;
        dpmem_resp  = '0;
        line_i      = '0;
        address_i   = '0;

        case(state)
            IMEM: begin
                if(ipmem_address == prefetch_addr) begin
                    ipmem_rdata = cacheline;
                    ipmem_resp  = '1;
                end else begin
                    address_i   = ipmem_address;
                    ipmem_resp  = resp_o;
                    ipmem_rdata = line_o;
                    read_i      = '1;
                end
            end
            DMEM: begin
                address_i  = dpmem_address;
                dpmem_resp = resp_o;
                if (dpmem_read) begin
                    dpmem_rdata = line_o;
                    read_i      = '1;
                end else begin : dmem_write
                    line_i      = dpmem_wdata;
                    write_i     = '1;
                end : dmem_write
            end
            PREFETCH: begin
                address_i = prefetch_addr;
                read_i    = '1;
            end
        endcase
    end

endmodule : prefetch_arbiter
