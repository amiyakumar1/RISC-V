module cpu 
import types::*;
(
    input clk,
    input rst,
    output  logic   [31:0]  imem_address,
    output  logic           imem_read,
    input   logic   [31:0]  imem_rdata,
    input   logic           imem_resp,
    output  logic   [31:0]  dmem_address,
    output  logic           dmem_read,
    output  logic           dmem_write,
    output  logic   [3:0]   dmem_wmask,
    input   logic   [31:0]  dmem_rdata,
    output  logic   [31:0]  dmem_wdata,
    input   logic           dmem_resp,
    output  logic   [31:0]  f_pc,
    output  logic           load_pipeline
);

// pipeline registers and their next values
if_id_t  if_id_next;
if_id_t  if_id;
id_ex_t  id_ex_next;
id_ex_t  id_ex;
ex_mem_t ex_mem_next;
ex_mem_t ex_mem;
mem_wb_t mem_wb_next;
mem_wb_t mem_wb;

// forwarding signals
logic [31:0] wb_regfilemux_out;
logic [31:0] mem_regfilemux_out;

// signals fed back to fetch stage
logic [31:0] alu_out;

// stall for multiply
logic mul_stall;
ctrl_packet  ctrl_pkt;

// RVFI signals
logic        valid;
logic [63:0] order;
logic [3:0]  rmask;
logic [31:0] wb_mem_rdata;
dmem_t       dmem_all;    // passed into mem_wb_next in memory stage
always_comb begin
    dmem_all.dmem_address = dmem_address;
    dmem_all.dmem_read    = dmem_read;
    dmem_all.dmem_write   = dmem_write;
    dmem_all.dmem_rmask   = rmask;
    dmem_all.dmem_wmask   = dmem_wmask;
    dmem_all.dmem_rdata   = dmem_rdata;
    dmem_all.dmem_wdata   = dmem_wdata;
    dmem_all.dmem_resp    = dmem_resp;
end

/************************** FETCH STAGE **************************/
assign dmem_read  = ex_mem.ctrl.dmem_read;
assign dmem_write = ex_mem.ctrl.dmem_write;
assign imem_address = if_id_next.reg_out.pcmux_out;
assign imem_read  = '1;
instruction_fetch FETCH(
    .clk            (clk),
    .rst            (rst),
    .load_pipeline  (load_pipeline),
    .instr          (id_ex.instr),  // instruction in the execute stage
    .ctrl_pkt       (ctrl_pkt),
    .alu_out        (alu_out),
    .imem_rdata     (imem_rdata),
    .if_id_next     (if_id_next),
    .exec_pc        (id_ex.reg_out.pc_out),
    .f_pc           (f_pc),
    .order          (order)
);

/************************** DECODE STAGE **************************/
instruction_decode DECODE(
    .clk            (clk),
    .rst            (rst),
    .ctrl_hazard    (ctrl_pkt.br_t_mis | ctrl_pkt.br_n_mis | ctrl_pkt.br_addr_mis),
    .wb_rd          (mem_wb.instr.rd),
    .load_regfile   (mem_wb.ctrl.load_regfile), 
    .rd_data        (wb_regfilemux_out),
    .if_id          (if_id),
    .id_ex_next     (id_ex_next)
);

/************************** EXECUTE STAGE **************************/
instruction_execute EXECUTE(
    .clk            (clk),
    .rst            (rst),
    .id_ex          (id_ex),
    .ex_mem_next    (ex_mem_next),
    .alu_out        (alu_out),
    .mul_stall      (mul_stall),
    .ctrl_pkt       (ctrl_pkt),
    .ex_mem_rd      (ex_mem.instr.rd),   // assign in mem stage
    .mem_wb_rd      (mem_wb.instr.rd),   // assign in wb stage
    .mem_rd_data    (mem_regfilemux_out),
    .wb_rd_data     (wb_regfilemux_out)
);

/************************** MEMORY STAGE **************************/
instruction_memory MEMORY(
    .ex_mem         (ex_mem),
    .mem_wb_next    (mem_wb_next),
    .regfilemux_out (mem_regfilemux_out),
    .rmask          (rmask),
    .wmask          (dmem_wmask),
    .dmem_wdata     (dmem_wdata),
    .dmem_rdata     (dmem_rdata),
    .dmem_addr      (dmem_address),   // for CP1 - goes to magic memory
    .dmem_all       (dmem_all)
);

/************************** WRITEBACK STAGE **************************/
instruction_writeback WRITEBACK(
    .mem_wb         (mem_wb),
    .regfilemux_out (wb_regfilemux_out),
    .wb_mem_rdata   (wb_mem_rdata)
);

/************************** RVFI VALID/ORDER *************************/
assign valid = mem_wb.valid && load_pipeline; 
always_ff @(posedge clk) begin
    if      (rst)   order <= '0;
    else if (valid) order <= order + 1'b1;
end

/**************** UPDATE REGISTERS & HAZARD DETECTION ****************/
always_comb begin
    // rearranged to give priority to dcache miss
    if (~imem_resp | (~dmem_resp & (ex_mem.instr.opcode == op_load | ex_mem.instr.opcode == op_store)) | mul_stall) begin
        load_pipeline = 1'b0;
    end else begin
        load_pipeline = 1'b1;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        if_id  <= '0;
        id_ex  <= '0;
        ex_mem <= '0;
        mem_wb <= '0;
    end else if (load_pipeline) begin
        if_id  <= if_id_next;
        id_ex  <= id_ex_next;
        ex_mem <= ex_mem_next;
        mem_wb <= mem_wb_next;
    end
end

endmodule : cpu
