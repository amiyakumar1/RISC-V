
module multiplier
import types::*;
(
    input logic clk,
    input logic rst,
    input logic [31:0] multiplicand,
    input logic [31:0] multiplier,
    input logic start,
    output logic ready,
    output logic [63:0] product,
    output logic done
);

logic [63:0] P;
logic [63:0] a;
logic [63:0] b;

assign product = P;

logic multiplying;

logic do_add;
logic do_shift;

always_ff @(posedge clk) begin
    if (rst) begin
        P <= '0;
        a <= '0;
        b <= '0;
        ready <= 1'b1;
        done <= 1'b0;
        multiplying <= 1'b0;
        do_add <= '0;
        do_shift <= '0;
    end else if (done) begin // done stays high for a single cycle
        done <= 1'b0;
        ready <= 1'b1;
    end else if (start && ready) begin  // initialize a and b and P
        P <= '0;
        a <= {32'b0, multiplicand};
        b <= {32'b0, multiplier};
        ready <= 1'b0;
        multiplying <= 1'b1;
        do_add <= '0;
        do_shift <= '0;
    end else if (multiplying) begin // begin multiplication
        if (do_add) begin   // add a to P
            P <= P + a;
            do_add <= 1'b0;
        end
        else if (do_shift) begin    // shift a
            a <= a << 1'b1;
            do_shift <= 1'b0;
        end
        else if (b) begin   // check if all bits of b have been shifted out
            if (b[0] == 1'b1) begin // add a on next cycle only if current bit is 1
                do_add <= 1'b1;
            end else do_add <= 1'b0;
            do_shift <= 1'b1;   // always shift a and b until b is 0
            b <= b >> 1'b1;
        end
        else begin  // done, raise flag
            done <= 1'b1;
            multiplying <= 1'b0;
        end
    end
end

endmodule : multiplier
