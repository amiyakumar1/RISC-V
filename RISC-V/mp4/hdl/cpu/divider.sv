module divider
import types::*;
(
    input logic clk,
    input logic rst,
    input logic [31:0] dividend,
    input logic [31:0] divisor,
    input logic start,
    output logic ready,
    output logic [31:0] quotient,
    output logic [31:0] remainder,
    output logic done
);

logic [31:0] Q;
logic [31:0] R;
logic [31:0] i;
logic do_shift;
logic do_load;
logic test;

assign quotient = Q;
assign remainder = R;

logic dividing;

always_ff @(posedge clk) begin
    if (rst) begin
        Q <= '0;
        R <= '0;
        ready <= 1'b1;
        done <= 1'b0;
        dividing <= 1'b0;
        i <= '0;
        do_shift <= '0;
        do_load <= '0;
        test <= '0;
    end
    else if (done) begin // done stays high for a single cycle
        done <= 1'b0;
        ready <= 1'b1;
    end
    else if (start && ready) begin  // initialize Q and R
        Q <= '0;
        R <= '0;
        ready <= 1'b0;
        dividing <= 1'b1;
        i <= 32'h31;
        do_shift <= 1'b1;
        do_load <= '0;
        test <= '0;
    end
    else if (dividing) begin    // begin division
        if (divisor == '0) begin    // divide by zero
            Q <= '1;
            R <= dividend;
            done <= 1'b1;
            dividing <= 1'b0;
        end 
        
        if (i == '1) begin  // done, raise flag
            done <= 1'b1;
            dividing <= 1'b0;
        end else if (do_shift) begin
            R <= R << 1'b1;
            do_shift <= 1'b0;
            do_load <= 1'b1;
            if (dividend[i]) test <= '1;
            else test <= '0;
        end else if (do_load) begin
            R[0] <= test;
            do_load <= 1'b0;
        end else if (R >= divisor) begin // do division by simple subtraction and addition
            R <= R - divisor;
            Q[i] <= 1'b1;
            do_shift <= 1'b1;
            i <= i - 1'b1;
        end else begin
            do_shift <= 1'b1;
            i <= i - 1'b1;
        end

    end
end

endmodule : divider