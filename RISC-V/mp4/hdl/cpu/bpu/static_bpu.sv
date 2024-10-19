module static_bpu 
/*
 * Static branch-not-taken predictor
*/
import types::*;
(
    input  logic[31:0]  pc,

    output logic[31:0]  pc_predict,
    output logic        ctrl_hazard,
    output logic        br_taken
);

// simple enough :)
assign pc_predict  = pc + 4;
assign br_taken    = '0;
assign ctrl_hazard = '0;

endmodule