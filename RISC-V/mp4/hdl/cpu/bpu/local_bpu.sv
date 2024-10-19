module local_bpu 
/*
 * BTB based predictor, keeping track of local branches
*/
import types::*;
#(
    parameter IDX_SIZE = 4,
    parameter TAG_SIZE = 30 - IDX_SIZE 
)(
    input               clk,
    input               rst,
    input  logic[31:0]  alu_out,
    input  ctrl_packet  ctrl_pkt,
    input  logic[31:0]  pc,

    output logic[31:0]  pc_predict,
    output logic        ctrl_hazard,
    output logic        br_taken
);

/* 
* the reasoning for this numbering is so that the default value
* of the predictor (00) is weakly rejected, and the MSB can be used
* to determine branch taken/rejected 
*/
typedef enum logic [1:0] {
    W_REJECTED = 2'b00,
    S_REJECTED = 2'b01,
    W_TAKEN    = 2'b10,
    S_TAKEN    = 2'b11
} predictor;

logic [TAG_SIZE - 1 : 0] tag_arr     [2**IDX_SIZE - 1:0];
logic [31           : 0] pc_pr_arr   [2**IDX_SIZE - 1:0];
logic [1            : 0] brp_arr     [2**IDX_SIZE - 1:0];

/* Fetch stage PC signals */
logic [TAG_SIZE - 1 : 0] fpc_tag;
logic [IDX_SIZE - 1 : 0] fpc_idx;
logic                    f_hit;

/* Execute stage PC signals */
logic [TAG_SIZE - 1 : 0] epc_tag;
logic [IDX_SIZE - 1 : 0] epc_idx;
logic                    e_hit;

assign fpc_tag = pc[31           : 32 - TAG_SIZE];
assign fpc_idx = pc[IDX_SIZE + 1 : 2            ];
assign f_hit   = (tag_arr[fpc_idx] == fpc_tag);

assign epc_tag = ctrl_pkt.br_pc[31           : 32 - TAG_SIZE];
assign epc_idx = ctrl_pkt.br_pc[IDX_SIZE + 1 : 2            ];
assign e_hit   = (tag_arr[epc_idx] == epc_tag);


/* branch reads */
always_comb begin

    ctrl_hazard = '0;
    br_taken    = '0;
    pc_predict  = pc + 4;

    if(f_hit & brp_arr[fpc_idx][1]) begin
        ctrl_hazard = '1;
        br_taken    = '1;
        pc_predict  = pc_pr_arr[fpc_idx];
    end 
end

/* branch writes */
integer i;
always_ff @(posedge clk) begin 
    if (rst) begin
        tag_arr <= '{default: '0};
    end else if (ctrl_pkt.ctrl_hazard) begin
        if(e_hit) begin
            /* 
             * if the pc branched to differs from the cached 
             * predicted target, update the predictec target
             */
            if(alu_out != pc_pr_arr[epc_idx])
                pc_pr_arr[epc_idx] <= alu_out;

            case(predictor'(brp_arr[epc_idx]))
                W_REJECTED: begin
                    brp_arr[epc_idx] <= ctrl_pkt.br_taken ? W_TAKEN : S_REJECTED;
                end
                S_REJECTED: begin
                    brp_arr[epc_idx] <= ctrl_pkt.br_taken ? W_REJECTED : S_REJECTED;
                end
                W_TAKEN: begin
                    brp_arr[epc_idx] <= ctrl_pkt.br_taken ? S_TAKEN : W_REJECTED;
                end
                S_TAKEN: begin
                    brp_arr[epc_idx] <= ctrl_pkt.br_taken ? S_TAKEN : W_TAKEN;
                end
            endcase

        end else begin
            /* if the PC is not cached, but causes a ctrl hazard */
            tag_arr[epc_idx]   <= epc_tag;
            pc_pr_arr[epc_idx] <= alu_out;
            brp_arr[epc_idx]   <= '0;
        end
    end
end

endmodule