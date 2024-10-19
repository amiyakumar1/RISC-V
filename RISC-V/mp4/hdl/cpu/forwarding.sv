module forwarding
import types::*;
(
    input  rv32i_reg  id_ex_rs1,
    input  rv32i_reg  id_ex_rs2,
    input  rv32i_reg  ex_mem_rd,
    input  rv32i_reg  mem_wb_rd,

    output logic[1:0] forwardA,
    output logic[1:0] forwardB
);

logic f0, f1, f2, f3;

assign f0 = id_ex_rs1 ? (id_ex_rs1 == ex_mem_rd) : '0;
assign f1 = id_ex_rs1 ? (id_ex_rs1 == mem_wb_rd) : '0;
assign f2 = id_ex_rs2 ? (id_ex_rs2 == ex_mem_rd) : '0;
assign f3 = id_ex_rs2 ? (id_ex_rs2 == mem_wb_rd) : '0;

always_comb begin
    unique case(f0 & f1)
        1'b0:    forwardA = {f1, f0};
        1'b1:    forwardA = ex_mem_haz;
        default: forwardA = no_haz;
    endcase

    unique case(f2 & f3)
        1'b0:    forwardB = {f3, f2};
        1'b1:    forwardB = ex_mem_haz;
        default: forwardB = no_haz;
    endcase
end

endmodule