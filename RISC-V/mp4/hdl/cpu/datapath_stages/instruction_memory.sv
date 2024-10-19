module instruction_memory
import types::*;
(
    input  ex_mem_t      ex_mem,
    output mem_wb_t      mem_wb_next,

    output logic [31:0]  regfilemux_out,

    input  logic [31:0]  dmem_rdata,
    output logic [3:0]   rmask,        
    output logic [3:0]   wmask,        
    output logic [31:0]  dmem_wdata,
    output logic [31:0]  dmem_addr,

    input  dmem_t        dmem_all
);

logic [31:0] pc_out;
logic [31:0] alu_out;
ctrl_word_t ctrl;

always_comb begin : assign_values
    // Assign names for use in memory stage
    pc_out = ex_mem.reg_out.pc_out;
    alu_out = ex_mem.alu_out;
    ctrl = ex_mem.ctrl;

    // Copy to next stage
    mem_wb_next.reg_out = ex_mem.reg_out;
    mem_wb_next.reg_out.rs1_data = ex_mem.reg_out.rs1_data;
    mem_wb_next.reg_out.rs2_data = ex_mem.reg_out.rs2_data;
    mem_wb_next.reg_out.pc_out = ex_mem.reg_out.pc_out;

    mem_wb_next.instr = ex_mem.instr;
    mem_wb_next.ctrl = ex_mem.ctrl;
    mem_wb_next.alu_out = ex_mem.alu_out;
    mem_wb_next.br_en = ex_mem.br_en;
    mem_wb_next.ir = ex_mem.ir;
    mem_wb_next.valid = ex_mem.valid;
    mem_wb_next.order = ex_mem.order;
    
    mem_wb_next.dmem_rdata = dmem_rdata;
    mem_wb_next.dmem_all = dmem_all;
end

logic [31:0] marmux_out;

logic [31:0] shifted_rdata;   //account for byte addressability on lb/lh
logic [1:0] shift_amount_ld;
always_comb begin : shifting
    shift_amount_ld = ex_mem.reg_out.rs1_data[1:0] + ex_mem.instr.i_imm[1:0]; //lower bytes of address, decides whether address is aligned
    case (shift_amount_ld)
        2'b01 : shifted_rdata = (dmem_rdata >> 8);
        2'b10 : shifted_rdata = (dmem_rdata >> 16);
        2'b11 : shifted_rdata = (dmem_rdata >> 24);
        default : shifted_rdata = dmem_rdata;
    endcase
end

always_comb begin : muxes
    unique case(ctrl.marmux_sel)
        marmux::pc_out:     marmux_out = pc_out;
        marmux::alu_out:    marmux_out = alu_out;
    endcase
    unique case(ctrl.regfilemux_sel)
        regfilemux::alu_out  : regfilemux_out = ex_mem.alu_out;
        regfilemux::br_en    : regfilemux_out = {31'b0, ex_mem.br_en};
        regfilemux::u_imm    : regfilemux_out = ex_mem.instr.u_imm;
        regfilemux::lw       : regfilemux_out = shifted_rdata;
        regfilemux::pc_plus4 : regfilemux_out = ex_mem.reg_out.pc_out + 4;
        regfilemux::lb       : regfilemux_out = { {24{shifted_rdata[7]}}, shifted_rdata[7:0]}; // double check later?
        regfilemux::lbu      : regfilemux_out = {24'b0, shifted_rdata[7:0]};
        regfilemux::lh       : regfilemux_out = { {16{shifted_rdata[15]}}, shifted_rdata[15:0]};
        regfilemux::lhu      : regfilemux_out = {16'b0, shifted_rdata[15:0]};
        default              : regfilemux_out = '0;
    endcase
end

// logic for wmask and rmask
// wmask and rmask -- use hierarchal reference to send to rvfi monitor
load_funct3_t load_funct3;
assign load_funct3 = load_funct3_t'(ex_mem.instr.funct3);
store_funct3_t store_funct3;
assign store_funct3 = store_funct3_t'(ex_mem.instr.funct3);


always_comb begin : masks
    // set rmask
    unique case(load_funct3)
        lw: rmask = 4'b1111;
        lh, lhu: rmask = 4'b0011 << marmux_out[1:0];
        lb, lbu: rmask = 4'b0001 << marmux_out[1:0];
        default: rmask = '0;
    endcase

    // set wmask
    unique case(store_funct3)
        sw: wmask = 4'b1111;
        sh: wmask = 4'b0011 << marmux_out[1:0];
        sb: wmask = 4'b0001 << marmux_out[1:0];
        default: wmask = '0;
    endcase
end

assign dmem_wdata = ex_mem.reg_out.rs2_data << (8*marmux_out[1:0]);
assign dmem_addr = marmux_out; // magic memory writes to dmem_rdata for CP1

endmodule : instruction_memory