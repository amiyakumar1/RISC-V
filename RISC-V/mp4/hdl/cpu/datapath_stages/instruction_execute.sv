module instruction_execute
import types::*;
(
    input               clk,
    input               rst,
    input  id_ex_t      id_ex,
    output ex_mem_t     ex_mem_next,

    output logic [31:0] alu_out,
    output logic        mul_stall,
    output ctrl_packet  ctrl_pkt,
    
    /* signals for forwarding unit */
    input  logic [4:0]  ex_mem_rd,
    input  logic [4:0]  mem_wb_rd,
    input  logic [31:0] mem_rd_data,
    input  logic [31:0] wb_rd_data
);

ctrl_word_t  ctrl;
instruction_t instruction;
logic [31:0] pc_out;
logic [31:0] rs1_data;
logic [31:0] rs2_data;
logic [31:0] rs1_data_forward;
logic [31:0] rs2_data_forward;

logic [31:0] br_mux_out;
logic [31:0] alumux1_out;
logic [31:0] alumux2_out;
logic [31:0] cmpmux_out;

logic [1:0]  forwardA;
logic [1:0]  forwardB;

logic        br_en;

logic        mode;
logic        stall;
logic [63:0] mul_div_out;
logic        mul_forward;
logic [31:0] alu_out_no_forward;

always_comb begin : assign_values
    // Assign names for use in execute stage
    ctrl        = id_ex.ctrl;
    instruction = id_ex.instr;
    pc_out      = id_ex.reg_out.pc_out;
    rs1_data    = id_ex.reg_out.rs1_data;
    rs2_data    = id_ex.reg_out.rs2_data;

    // Copy to next stage
    ex_mem_next.reg_out.rs1_data = rs1_data_forward;    
    ex_mem_next.reg_out.rs2_data = rs2_data_forward;
    ex_mem_next.reg_out.pc_out   = pc_out;
    ex_mem_next.instr            = id_ex.instr;
    ex_mem_next.ctrl             = id_ex.ctrl;
    ex_mem_next.alu_out          = alu_out;
    ex_mem_next.br_en            = br_en;
    ex_mem_next.ir               = id_ex.ir;
    ex_mem_next.valid            = id_ex.valid;
    ex_mem_next.order            = id_ex.order;
    ex_mem_next.mul_div_out      = mul_div_out;

    ctrl_pkt.br_pc = id_ex.reg_out.pc_out;
end

always_comb begin

    /* The branch address was mispredicted if:
          - the branch was determined taken in execute, or the opcode is jal or jalr
        & - the branch predicted address does not match the calculated address
    */
    ctrl_pkt.br_addr_mis = (
        (
            (instruction.opcode == op_jalr  | instruction.opcode == op_jal) 
          | (instruction.opcode == op_br    & br_en)
        ) 
        & ( id_ex.br_pc != alu_out)
    );
    ctrl_pkt.br_t_mis    = (instruction.opcode == op_br &  br_en) & ~id_ex.br_taken;
    ctrl_pkt.br_n_mis    = (instruction.opcode == op_br & ~br_en) &  id_ex.br_taken;
    ctrl_pkt.ctrl_hazard = '1;
    ctrl_pkt.br_taken       = '1;    


    unique case (instruction.opcode)
        op_br: begin
            ex_mem_next.reg_out.pcmux_out = (
                (ctrl_pkt.br_t_mis | ctrl_pkt.br_addr_mis) ? alu_out    :
                (ctrl_pkt.br_n_mis                       ) ? pc_out + 4 :
                /* else */                                   id_ex.reg_out.pcmux_out
            );
            ctrl_pkt.br_taken = br_en; 
        end
        op_jal:  begin
            ex_mem_next.reg_out.pcmux_out = alu_out; 
        end
        op_jalr: begin 
            ex_mem_next.reg_out.pcmux_out = {alu_out[31:1], 1'b0}; 
        end
        default: begin 
            ex_mem_next.reg_out.pcmux_out = id_ex.reg_out.pcmux_out;
            ctrl_pkt.br_t_mis             = '0;
            ctrl_pkt.br_n_mis             = '0;
            ctrl_pkt.ctrl_hazard          = '0;
            ctrl_pkt.br_addr_mis          = '0;
            ctrl_pkt.br_taken             = '0;    
        end


    endcase

end

// mode indicates multiplication, need to stall when multiplying
assign mode = (instruction.opcode == op_reg) ? instruction.funct7[0] : '0;
assign mul_stall = (instruction.opcode == op_reg) ? stall : '0;
assign mul_forward = '0; // temp, should check ex stage and mem stage opcode
alu ALU(
    .clk     (clk),
    .rst     (rst),
    .aluop   (alu_ops'(ctrl.aluop)),
    .mode    (mode),
    .a       (alumux1_out),
    .b       (alumux2_out),
    .stall   (stall),
    .f       (alu_out_no_forward),
    .mul_div_out (mul_div_out)
);
always_comb begin : mul_forwarding
    if (mul_forward) alu_out = mul_div_out[31:0];
    else alu_out = alu_out_no_forward; 
end

cmp CMP(    
    .cmpop      (ctrl.cmpop),
    .rs1_data   (rs1_data_forward),
    .rs2_data   (cmpmux_out),
    .br_en      (br_en)
);

forwarding FORWARDING(
    .id_ex_rs1  (instruction.rs1),
    .id_ex_rs2  (instruction.rs2),
    .ex_mem_rd  (ex_mem_rd),
    .mem_wb_rd  (mem_wb_rd),
    .forwardA   (forwardA),
    .forwardB   (forwardB)
);

always_comb begin : muxes

    unique case (ctrl.alumux1_sel)
        alumux::rs1_data:   alumux1_out = rs1_data_forward;
        alumux::pc_out:     alumux1_out = pc_out;
        default:            alumux1_out = '0;
    endcase
    
    unique case (ctrl.alumux2_sel)
        alumux::i_imm:      alumux2_out = instruction.i_imm;
        alumux::u_imm:      alumux2_out = instruction.u_imm;
        alumux::b_imm:      alumux2_out = instruction.b_imm;
        alumux::s_imm:      alumux2_out = instruction.s_imm;
        alumux::j_imm:      alumux2_out = instruction.j_imm;
        alumux::rs2_data:   alumux2_out = rs2_data_forward;
        default:            alumux2_out = '0;
    endcase

    unique case (ctrl.cmpmux_sel)
        cmpmux::rs2_data:   cmpmux_out = rs2_data_forward;
        cmpmux::i_imm:      cmpmux_out = instruction.i_imm;
        default:            cmpmux_out = '0;
    endcase

end : muxes

always_comb begin : forwarding_muxes
    unique case (forwardA)
        no_haz:         rs1_data_forward = rs1_data;
        ex_mem_haz:     rs1_data_forward = mem_rd_data;
        mem_wb_haz:     rs1_data_forward = wb_rd_data;
        default:        rs1_data_forward = '0;
    endcase

    unique case (forwardB)
        no_haz:         rs2_data_forward = rs2_data;
        ex_mem_haz:     rs2_data_forward = mem_rd_data;
        mem_wb_haz:     rs2_data_forward = wb_rd_data;
        default:        rs2_data_forward = '0;
    endcase

end : forwarding_muxes

endmodule