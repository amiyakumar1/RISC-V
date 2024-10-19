module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory (dram)
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

// load (dram to llc)
// to read data from dram to llc: raise the read_o signal while holding address_o constant. while
// resp_i is high, the data comoing form burst_i is valid. this happens four times, which together
// will comprise the 256 valid bits. this signifies data coming OUT of the dram. now i must put
// that data in the llc. to do this, i need to assemble the data into one 256 bit packet (cacheline).
// similarly now, i must raise resp_o and send data via line_o to llc.
// dram --> cacheline --> llc

// for a fsm, there must be 3 states: idle, read, write ??

// signals that i can control from perspective of cacheline adaptor:
// line_o, resp_o, burst_o, address_o, read_o, write_o

logic [1:0] state;
logic [3:0] i;

// signal to go back to idle state
logic done;

assign address_o = address_i;
assign burst_o = line_i[64*i+:64];

always @ (posedge clk or negedge reset_n) begin
    if(~reset_n) begin
        // idle state
        state <= 2'b00;
        line_o <= 256'b0;
        resp_o <= 1'b0;
        // burst_o <= 64'b0;
        // address_o <= 0;
        read_o <= 1'b0;
        write_o <= 1'b0;
        i <= 4'b0;
    end
    else begin
        case(state)
            // idle
            2'b00: begin
                // do nothing
                if (write_i) begin
                    state <= 2'b10;
                    i <= 4'b0;
                end
                if (read_i) begin
                    state <= 2'b01;
                    i <= 4'b0;
                end
            end

            // state 001: read (dram to llc)
            2'b01: begin
                if(i<4) begin
                    read_o <= 1'b1;
                    if(resp_i) begin
                        line_o[64*i+:64] <= burst_i;
                        i <= i + 1'b1;
                    end
                    if(i==3) begin
                        read_o <= 1'b0;
                    end
                end
                
                else if(i==4) begin
                    // now we are ready to transmit the collected burst data onto line_o -- raise resp_o for a single cycle??
                    // line_o <= cacheline_buffer;
                    resp_o <= 1'b1;
                    i <= i + 1'b1;
                end
                else begin
                    resp_o <= 1'b0;
                    i <= 4'b0;
                    state <= 2'b00;
                end
            end

            // write (llc to dram)
            // essentially the opposite of read. break up 256 bits into 4 64 bit chunks and send from llc to dram.
            // the llc will first receive a write request. while the write_i signal is high, the address_i and 
            // line_i signals are valid. the resp_o signal concludes this.
            // now write this buffered data to dram. raise write_o once address_o and burst_o are valid.

            // state 10: write (llc to dram)

            2'b10: begin
                if(i<4) begin
                    write_o <= 1'b1;
                    if(resp_i) begin
                        
                        i <= i + 1'b1;
                    end
                    if(i==3) begin
                        write_o <= 1'b0;
                    end
                end
                
                else if(i==4) begin
                    resp_o <= 1'b1;
                    i <= i + 1'b1;
                end
                else begin
                    resp_o <= 1'b0;
                    i <= 4'b0;
                    state <= 2'b00;
                end
            end

            default: begin
                state <= 2'b00;
            end
        endcase
    end
end

endmodule : cacheline_adaptor
