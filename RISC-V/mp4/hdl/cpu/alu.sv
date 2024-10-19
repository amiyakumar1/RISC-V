module alu
import types::*;
(
    input                  clk,
    input                  rst,
    input alu_ops          aluop,
    input logic            mode,
    input logic     [31:0] a, b,
    output logic           stall,
    output logic    [31:0] f,
    output logic    [63:0] mul_div_out
);

logic neg_sign;
assign neg_sign = a[31] ^ b[31];

logic start_m;
// logic start_m_in;
logic ready_m;
logic done_m;
logic [63:0] product;
logic [31:0] multiplicand;
logic [31:0] multiplier;

logic start_d;
// logic start_d_in;
logic ready_d;
logic done_d;
logic [31:0] quotient;
logic [31:0] remainder;
logic [31:0] quotient_sign;
logic [31:0] remainder_sign;
logic [31:0] dividend;
logic [31:0] divisor;

always_comb
begin
    if (mode == '1) begin // multiply mode
        unique case (mul_ops'(aluop))
            alu_mul:    begin 
                        multiplicand = a;
                        multiplier  =  b;   
                        mul_div_out = product;
                        f = mul_div_out[31:0];
                        stall = ~done_m;
                        start_m = 1'b1;
                        //defaults
                        dividend = '0;
                        divisor = '0;
                        quotient_sign = '0;
                        remainder_sign = '0;
                        start_d = '0;
            end
            alu_mulh:   begin 
                        multiplicand = a[31] ? (~a + 1'b1) : a; // convert to positive unsigned
                        multiplier  =  b[31] ? (~b + 1'b1) : b;
                        mul_div_out =  neg_sign ? (~product + 1'b1) : product;  // convert to negative signed if necessary
                        f = mul_div_out[63:32];
                        stall = ~done_m;
                        start_m = 1'b1;
                        //defaults
                        dividend = '0;
                        divisor = '0;
                        quotient_sign = '0;
                        remainder_sign = '0;
                        start_d = '0;
            end
            alu_mulhsu: begin
                        multiplicand = a[31] ? (~a + 1'b1) : a; // convert to positive unsigned
                        multiplier  =  b;
                        mul_div_out =  a[31] ? (~product + 1'b1) : product;
                        f = mul_div_out[63:32];
                        stall = ~done_m;
                        start_m = 1'b1;
                        //defaults
                        dividend = '0;
                        divisor = '0;
                        quotient_sign = '0;
                        remainder_sign = '0;
                        start_d = '0;
            end
            alu_mulhu:  begin 
                        multiplicand = a;
                        multiplier  =  b;   
                        mul_div_out = product;
                        f = mul_div_out[63:32];
                        stall = ~done_m;
                        start_m = 1'b1;
                        //defaults
                        dividend = '0;
                        divisor = '0;
                        quotient_sign = '0;
                        remainder_sign = '0;
                        start_d = '0;
            end
            alu_div:    begin
                        dividend = a[31] ? (~a + 1'b1) : a;
                        divisor =  b[31] ? (~b + 1'b1) : b;
                        quotient_sign = neg_sign ? (~quotient + 1'b1) : quotient;
                        remainder_sign = a[31] ? (~remainder + 1'b1) : remainder;
                        mul_div_out = {remainder_sign, quotient_sign};
                        if (b == '0) f = '1;
                        else f = mul_div_out[31:0];
                        stall = ~done_d;
                        start_d = 1'b1;
                        //defaults
                        multiplicand = '0;
                        multiplier = '0;
                        start_m = '0;
            end
            alu_divu:   begin
                        dividend = a;
                        divisor = b;
                        mul_div_out = {remainder, quotient};
                        if (b == '0) f = '1;
                        else f = mul_div_out[31:0];
                        stall = ~done_d;
                        start_d = 1'b1;
                        //defaults
                        multiplicand = '0;
                        multiplier = '0;
                        quotient_sign = '0;
                        remainder_sign = '0;
                        start_m = '0;
            end
            alu_rem:    begin
                        dividend = a[31] ? (~a + 1'b1) : a;
                        divisor =  b[31] ? (~b + 1'b1) : b;
                        quotient_sign = neg_sign ? (~quotient + 1'b1) : quotient;
                        remainder_sign = a[31] ? (~remainder + 1'b1) : remainder;
                        mul_div_out = {remainder_sign, quotient_sign};
                        if (b == '0) f = a;
                        else f = mul_div_out[63:32];
                        stall = ~done_d;
                        start_d = 1'b1;
                        //defaults
                        multiplicand = '0;
                        multiplier = '0;
                        start_m = '0;
            end
            alu_remu:   begin
                        dividend = a;
                        divisor = b;
                        mul_div_out = {remainder, quotient};
                        if (b == '0) f = a;
                        else f = mul_div_out[63:32];
                        stall = ~done_d;
                        start_d = 1'b1;
                        //defaults
                        multiplicand = '0;
                        multiplier = '0;
                        quotient_sign = '0;
                        remainder_sign = '0;
                        start_m = '0;
            end
            default:    f = '0;
        endcase
    end else begin        // standard arithmetic mode
        unique case (aluop)
            alu_add:  f = a + b;
            alu_sll:  f = a << b[4:0];
            alu_sra:  f = $unsigned($signed(a) >>> b[4:0]);
            alu_sub:  f = a - b;
            alu_xor:  f = a ^ b;
            alu_srl:  f = a >> b[4:0];
            alu_or:   f = a | b;
            alu_and:  f = a & b;
            default:  f = a + b;
        endcase
        stall = '0;  // standard ops never stall
        mul_div_out = '0;
        start_m = 1'b0;
        start_d = 1'b0;
        multiplicand = a;
        multiplier  =  b;   
        dividend = a;
        divisor = b;
        quotient_sign = '0;
        remainder_sign = '0;
    end
end

multiplier MULTIPLIER(
    .clk              (clk),
    .rst          (rst),
    .multiplicand     (multiplicand),
    .multiplier       (multiplier),
    .start            (start_m),
    .ready            (ready_m),
    .product          (product),
    .done             (done_m)
);

divider DIVIDER(
    .clk              (clk),
    .rst          (rst),
    .dividend         (dividend),
    .divisor          (divisor),
    .start            (start_d),
    .ready            (ready_d),
    .quotient         (quotient),
    .remainder        (remainder),
    .done             (done_d)
);

// always_ff @(posedge clk) begin : start_done_logic
//     if (done_m) start_m_in <= '0;
//     else if (start_m && ready_m) start_m_in <= '1;
//     else start_m_in <= '0;

//     if (done_d) start_d_in <= '0;
//     else if (start_d && ready_d) start_d_in <= '1;
//     else start_d_in <= '0;
// end

endmodule : alu