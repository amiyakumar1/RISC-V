module instruction_writeback
import types::*;
(
    input  mem_wb_t     mem_wb,

    output logic [31:0] regfilemux_out,
    output logic [31:0] wb_mem_rdata // only for rvfi
);

ctrl_word_t       ctrl;
instruction_t     instruction;
logic   [31:0]    alu_out;
logic             br_en;
logic   [31:0]    mem_rdata;
logic   [31:0]    pc_out;

always_comb begin : assign_values
    ctrl = mem_wb.ctrl;
    instruction = mem_wb.instr;
    alu_out = mem_wb.alu_out;
    br_en = mem_wb.br_en;
    mem_rdata = mem_wb.dmem_rdata;
    wb_mem_rdata = mem_rdata;
    pc_out = mem_wb.reg_out.pc_out;
end

logic [31:0] shifted_rdata;   //account for byte addressability on lb/lh
logic [1:0] shift_amount_ld;
always_comb begin : shifting
    shift_amount_ld = mem_wb.reg_out.rs1_data[1:0] + instruction.i_imm[1:0]; //lower bytes of address, decides whether address is aligned
    case (shift_amount_ld)
        2'b01 :  shifted_rdata = (mem_rdata >> 8);
        2'b10 :  shifted_rdata = (mem_rdata >> 16);
        2'b11 :  shifted_rdata = (mem_rdata >> 24);
        default: shifted_rdata = mem_rdata;
    endcase
end

always_comb begin : muxes
    if(~mem_wb.valid) begin
        regfilemux_out = '0;
    end else begin
        unique case(ctrl.regfilemux_sel)
            regfilemux::alu_out  : regfilemux_out = alu_out;
            regfilemux::br_en    : regfilemux_out = {31'b0, br_en};
            regfilemux::u_imm    : regfilemux_out = instruction.u_imm;
            regfilemux::lw       : regfilemux_out = shifted_rdata;
            regfilemux::pc_plus4 : regfilemux_out = pc_out + 4;
            regfilemux::lb       : regfilemux_out = { {24{shifted_rdata[7]}}, shifted_rdata[7:0]}; // double check later?
            regfilemux::lbu      : regfilemux_out = {24'b0, shifted_rdata[7:0]};
            regfilemux::lh       : regfilemux_out = { {16{shifted_rdata[15]}}, shifted_rdata[15:0]};
            regfilemux::lhu      : regfilemux_out = {16'b0, shifted_rdata[15:0]};
            default              : regfilemux_out = '0;
        endcase
    end
end

endmodule : instruction_writeback