module instruction_fetch
import types::*;
(
    input                   clk,
    input                   rst,

    input                   load_pipeline,
    input  instruction_t    instr,          // the instruction which is currently in execute
    input  logic [31:0]     exec_pc,        // the pc address which is currently in execute
    
    input  ctrl_packet      ctrl_pkt,
    input  logic [31:0]     alu_out,

    input  logic [31:0]     imem_rdata,

    output if_id_t          if_id_next,
    output logic [31:0]     f_pc,
    input  logic [63:0]     order
);

logic [31:0] pc;
logic [31:0] pcmux_out;
logic [31:0] pc_predict;
logic        ctrl_hazard;
assign if_id_next.reg_out.pcmux_out = pcmux_out;
assign if_id_next.reg_out.pc_out    = pc;
assign if_id_next.ir                = imem_rdata;
assign if_id_next.order             = order;
assign if_id_next.br_pc             = pc_predict;
assign f_pc                         = pc;

always_comb begin
    if (ctrl_pkt.br_t_mis | ctrl_pkt.br_n_mis | ctrl_pkt.br_addr_mis) 
        if_id_next.valid = '0;
    else  
        if_id_next.valid = load_pipeline;
end

`define ENABLE_PREDICTOR
`define USE_LOCAL_PREDICTOR

`ifdef ENABLE_PREDICTOR
    `ifdef USE_LOCAL_PREDICTOR
        local_bpu BRANCH_PREDICT(
            .clk            (clk),
            .rst            (rst),
            .alu_out        (alu_out),
            .ctrl_pkt       (ctrl_pkt),
            .pc             (pc),
            
            .pc_predict     (pc_predict),
            .ctrl_hazard    (ctrl_hazard),
            .br_taken       (if_id_next.br_taken) 
        );
    `else
        global_bpu BRANCH_PREDICT(
            .clk            (clk),
            .rst            (rst),
            .alu_out        (alu_out),
            .ctrl_pkt       (ctrl_pkt),
            .pc             (pc),
            
            .pc_predict     (pc_predict),
            .ctrl_hazard    (ctrl_hazard),
            .br_taken       (if_id_next.br_taken) 
        );
    `endif
`else
    static_bpu BRANCH_PREDICT(
        .pc             (pc),
        .pc_predict     (pc_predict),
        .ctrl_hazard    (ctrl_hazard),
        .br_taken       (if_id_next.br_taken)
    );
`endif


always_comb begin : muxes
    /* 
    *  The br_en signal from execute has priority over the branch prediction from fetch.
    *  In the case that execute has a correctly predicted control hazard, the defaults 
    *  asserted below ensure that the fetch prediction has priority over the PC.
    */
    if (ctrl_hazard & if_id_next.br_taken) pcmux_out = pc_predict;
    else                                   pcmux_out = pc + 4;

    case (instr.opcode) 
        op_br: begin
            if (ctrl_pkt.br_t_mis | ctrl_pkt.br_addr_mis)
                pcmux_out = alu_out;
            if (ctrl_pkt.br_n_mis)
                pcmux_out = exec_pc + 4;
        end
        op_jal: begin
            if (ctrl_pkt.br_t_mis | ctrl_pkt.br_addr_mis)
                pcmux_out = alu_out;
        end
        op_jalr: begin
            if (ctrl_pkt.br_t_mis | ctrl_pkt.br_addr_mis)
                pcmux_out = {alu_out[31:1], 1'b0};
        end
    endcase
end

always_ff @(posedge clk) begin : pc_register
    if (rst) begin
        pc <= 32'h40000000;
    end
    else if (load_pipeline) begin
        pc <= pcmux_out;
    end
end

endmodule : instruction_fetch