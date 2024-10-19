module instruction_decode
import types::*;
(
    input                   clk,
    input                   rst,
    input                   ctrl_hazard,
    input  rv32i_reg        wb_rd,
    input  logic            load_regfile,
    input  logic [31:0]     rd_data,
    input  if_id_t          if_id,
    output id_ex_t          id_ex_next
);

// load instruction from cache
logic [31:0] data;  
ctrl_word_t decoder_ctrl;

always_comb begin : valid_flush_check
    if (ctrl_hazard) begin
        // flush for branches and jumps
        data = {25'b0, 7'b0010011};
        id_ex_next.ctrl = '0;
        id_ex_next.valid = '0;
    end else if (if_id.valid) begin
        data = if_id.ir;
        id_ex_next.ctrl = decoder_ctrl;
        id_ex_next.valid = if_id.valid;
    end else begin
        // push a nop
        data = {25'b0, 7'b0010011};
        id_ex_next.ctrl = '0;
        id_ex_next.valid = '0;
    end
end

instruction_t instr;
assign id_ex_next.instr = instr;

assign instr.funct3 = data[14:12];
assign instr.funct7 = data[31:25];
assign instr.opcode = rv32i_opcode'(data[6:0]);
assign instr.i_imm = {{21{data[31]}}, data[30:20]};
assign instr.s_imm = {{21{data[31]}}, data[30:25], data[11:7]};
assign instr.b_imm = {{20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
assign instr.u_imm = {data[31:12], 12'h000};
assign instr.j_imm = {{12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};
// assign instr.rs1 = data[19:15];
// assign instr.rs2 = data[24:20];
// assign instr.rd = (instr.opcode == op_store || instr.opcode == op_br) ? '0 : data[11:7];

logic [31:0] regfile_rs1_data;
logic [31:0] regfile_rs2_data;

always_comb begin : rs1_mux
    unique case(instr.opcode)
        op_lui,
        op_auipc,
        op_jal:
            instr.rs1 = '0;
        default: 
            instr.rs1 = data[19:15];
    endcase
end

always_comb begin : rs2_mux
    unique case(instr.opcode)
        op_lui,
        op_auipc,
        op_jal,
        op_jalr,
        op_load,
        op_imm,
        op_csr:
            instr.rs2 = '0;
        default: 
            instr.rs2 = data[24:20];
    endcase

end

always_comb begin : rd_mux
    unique case(instr.opcode)
        op_store,
        op_br:
            instr.rd = '0;
        default:
            instr.rd = data[11:7];
    endcase
end


always_comb begin : regfile_forwarding
    if (wb_rd ? (instr.rs1 == wb_rd) : '0) id_ex_next.reg_out.rs1_data = rd_data;
    else id_ex_next.reg_out.rs1_data = regfile_rs1_data;

    if (wb_rd ? (instr.rs2 == wb_rd) : '0) id_ex_next.reg_out.rs2_data = rd_data;
    else id_ex_next.reg_out.rs2_data = regfile_rs2_data;
end

// update pc and pcmux
assign id_ex_next.reg_out.pc_out = if_id.reg_out.pc_out;
assign id_ex_next.reg_out.pcmux_out = if_id.reg_out.pcmux_out;
// assign id_ex_next.valid   = if_id.valid; // for rvfi order


assign id_ex_next.ir       = if_id.ir;
assign id_ex_next.br_taken = if_id.br_taken;
assign id_ex_next.order    = if_id.order;
assign id_ex_next.br_pc    = if_id.br_pc;


regfile REGFILE(
    .clk    (clk),
    .rst    (rst),
    .load   (load_regfile),
    .in     (rd_data),
    .src_a  (instr.rs1),
    .src_b  (instr.rs2),
    .dest   (wb_rd),
    .reg_a  (regfile_rs1_data),
    .reg_b  (regfile_rs2_data)
);

decoder DECODER(
    .opcode     (rv32i_opcode'(instr.opcode)),
    .ctrl       (decoder_ctrl),
    .funct3     (instr.funct3),
    .funct7     (instr.funct7)
);

endmodule : instruction_decode