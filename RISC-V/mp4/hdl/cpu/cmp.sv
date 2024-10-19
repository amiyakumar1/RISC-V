module cmp
import types::*; 
(
    input logic [2:0]  cmpop, 
    input logic [31:0] rs1_data,
    input logic [31:0] rs2_data,

    output logic br_en
);

always_comb
begin
    unique case (cmpop)
        beq:  br_en = rs1_data == rs2_data ? 1'b1 : 1'b0;
        bne:  br_en = rs1_data != rs2_data ? 1'b1 : 1'b0;
        blt:  br_en = $signed(rs1_data) <  $signed(rs2_data) ? 1'b1 : 1'b0;
        bge:  br_en = $signed(rs1_data) >= $signed(rs2_data) ? 1'b1 : 1'b0;
        bltu: br_en = rs1_data <  rs2_data ? 1'b1 : 1'b0;
        bgeu: br_en = rs1_data >= rs2_data ? 1'b1 : 1'b0;

        default: br_en = 1'b0;
    endcase
end

endmodule : cmp