module arbiter(
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

    enum int unsigned{
        IMEM,
        DMEM,
        IDLE
    } state, next_state;

    /* Next state assignment */
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    /* Next state logic */
    always_comb begin
        next_state = IDLE;
        unique case(state)
            IMEM: begin
                if (resp_o) begin
                    if (dpmem_read | dpmem_write) begin
                        next_state = DMEM;
                    end else begin
                        next_state = IDLE;
                    end
                end
                else next_state = IMEM;
            end
            DMEM: begin
                if (resp_o) begin
                    if (ipmem_read) begin
                        next_state = IMEM;
                    end else begin
                        next_state = IDLE;
                    end
                end
                else next_state = DMEM;
            end
            IDLE: begin
                if      (dpmem_read | dpmem_write)  next_state = DMEM;
                else if (ipmem_read)                next_state = IMEM;
                else                                next_state = IDLE;
            end
        endcase
    end


    /* State Actions */
    always_comb begin

        /* default values on a IDLE */
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
                address_i   = ipmem_address;
                ipmem_resp  = resp_o;
                ipmem_rdata = line_o;
                read_i      = '1;
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
        endcase
    end

endmodule : arbiter
