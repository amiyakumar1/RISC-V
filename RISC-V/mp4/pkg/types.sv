
package types;

/****************************** RV32I ENUMS ****************************/
typedef logic [4:0] rv32i_reg;

typedef enum logic [6:0] {
    op_lui   = 7'b0110111, //load upper immediate (U type)
    op_auipc = 7'b0010111, //add upper immediate PC (U type)
    op_jal   = 7'b1101111, //jump and link (J type)
    op_jalr  = 7'b1100111, //jump and link register (I type)
    op_br    = 7'b1100011, //branch (B type)
    op_load  = 7'b0000011, //load (I type)
    op_store = 7'b0100011, //store (S type)
    op_imm   = 7'b0010011, //arith ops with register/immediate operands (I type)
    op_reg   = 7'b0110011, //arith ops with register operands (R type)
    op_csr   = 7'b1110011  //control and status register (I type)
} rv32i_opcode;

typedef enum logic [2:0] {
    beq  = 3'b000,
    bne  = 3'b001,
    blt  = 3'b100,
    bge  = 3'b101,
    bltu = 3'b110,
    bgeu = 3'b111
} branch_funct3_t;

typedef enum logic [2:0] {
    lb  = 3'b000,
    lh  = 3'b001,
    lw  = 3'b010,
    lbu = 3'b100,
    lhu = 3'b101
} load_funct3_t;

typedef enum logic [2:0] {
    sb = 3'b000,
    sh = 3'b001,
    sw = 3'b010
} store_funct3_t;

typedef enum logic [2:0] {
    add  = 3'b000, //check logic30 for sub if op_reg opcode
    sll  = 3'b001,
    slt  = 3'b010,
    sltu = 3'b011,
    axor = 3'b100,
    sr   = 3'b101, //check logic30 for logical/arithmetic
    aor  = 3'b110,
    aand = 3'b111
} arith_funct3_t;

typedef enum logic [2:0] {
    alu_add = 3'b000,
    alu_sll = 3'b001,
    alu_sra = 3'b010,
    alu_sub = 3'b011,
    alu_xor = 3'b100,
    alu_srl = 3'b101,
    alu_or  = 3'b110,
    alu_and = 3'b111
} alu_ops;

typedef enum logic [2:0] {
    mul     = 3'b000,
    mulh    = 3'b001,
    mulhsu  = 3'b010,
    mulhu   = 3'b011,
    div     = 3'b100,
    divu    = 3'b101,
    rem     = 3'b110,
    remu    = 3'b111
} mul_funct3_t;

typedef enum logic [2:0] {
    alu_mul     = 3'b000,
    alu_mulh    = 3'b001,
    alu_mulhsu  = 3'b010,
    alu_mulhu   = 3'b011,
    alu_div     = 3'b100,
    alu_divu    = 3'b101,
    alu_rem     = 3'b110,
    alu_remu    = 3'b111
} mul_ops;

typedef enum logic [1:0] {
    no_haz      = 2'b00,
    ex_mem_haz  = 2'b01,
    mem_wb_haz  = 2'b10
} forward_t;

/****************************** DMEM STRUCT ******************************/
typedef struct packed {
    logic [31:0] dmem_address;
    logic        dmem_read;
    logic        dmem_write;
    logic [3:0]  dmem_rmask;
    logic [3:0]  dmem_wmask;
    logic [31:0] dmem_rdata;
    logic [31:0] dmem_wdata;
    logic        dmem_resp;
} dmem_t;

/****************************** CTRL WORD STRUCT ******************************/
typedef struct packed {
    logic       alumux1_sel;
    logic [2:0] alumux2_sel;
    logic       cmpmux_sel;
    logic [2:0] aluop;
    logic [2:0] cmpop;
    logic       marmux_sel;
    logic [3:0] regfilemux_sel;
    logic       dmem_read;
    logic       dmem_write;
    logic       load_regfile;
} ctrl_word_t;

/****************************** INSTRUCTION STRUCT ******************************/
typedef struct packed {
    rv32i_opcode opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [31:0] i_imm;
    logic [31:0] s_imm;
    logic [31:0] b_imm;
    logic [31:0] u_imm;
    logic [31:0] j_imm;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
} instruction_t;

/****************************** REGISTER OUTPUTS ******************************/
typedef struct packed {
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] pc_out;
    logic [31:0] pcmux_out;
} register_out_t;

/****************************** PIPELINE REGISTERS ******************************/
typedef struct packed {
    // Set by fetch - Used by decode
    register_out_t reg_out;  //pc_out_fe from fetch
    logic [31:0] ir;
    logic valid;
    logic br_taken;
    logic [31:0] br_pc;
    logic [63:0] order;
} if_id_t;

typedef struct packed {
    // Set by decode - Used by execute
    register_out_t reg_out;
    instruction_t instr;
    ctrl_word_t ctrl;
    logic [31:0] ir;
    logic valid;
    logic br_taken;
    logic [31:0] br_pc;
    logic [63:0] order;
} id_ex_t;

typedef struct packed {
    // Set by execute - Used by memory
    register_out_t reg_out;
    instruction_t instr;
    ctrl_word_t ctrl;
    logic [31:0] alu_out;
    logic br_en;
    logic [31:0] ir;
    logic valid;
    logic [63:0] mul_div_out;
    logic [63:0] order;
} ex_mem_t;

typedef struct packed {
    // Set by memory - Used by writeback
    register_out_t reg_out;
    instruction_t instr;
    ctrl_word_t ctrl;
    logic [31:0] alu_out;
    logic br_en;
    logic [31:0] dmem_rdata;
    logic [31:0] ir;
    dmem_t dmem_all;
    logic  valid;
    logic [63:0] order;
} mem_wb_t;

typedef struct packed {
    logic        ctrl_hazard; // is this instruction a control hazard?
    logic        br_taken;    // if its a control hazard, then was the branch taken
    logic [31:0] br_pc;       // and whats the pc of the instruction corresponding to the hazard?
    logic        br_addr_mis; // if the direction of the branch was predicted correctly, was the branch address?
    logic        br_t_mis;    // branch taken, predict not taken
    logic        br_n_mis;    // branch not taken, predict taken
} ctrl_packet;

endpackage : types

/****************************** MUX ENUMS ******************************/
package pcmux;
typedef enum logic [1:0] {
    pc_plus4  = 2'b00
    ,alu_out  = 2'b01
    ,alu_mod2 = 2'b10
} pcmux_sel_t;
endpackage

package marmux;
typedef enum logic {
    pc_out = 1'b0
    ,alu_out = 1'b1
} marmux_sel_t;
endpackage

package cmpmux;
typedef enum logic {
    rs2_data = 1'b0
    ,i_imm   = 1'b1
} cmpmux_sel_t;
endpackage

package alumux;
typedef enum logic {
    rs1_data = 1'b0
    ,pc_out  = 1'b1
} alumux1_sel_t;

typedef enum logic [2:0] {
    i_imm    = 3'b000
    ,u_imm   = 3'b001
    ,b_imm   = 3'b010
    ,s_imm   = 3'b011
    ,j_imm   = 3'b100
    ,rs2_data = 3'b101
} alumux2_sel_t;
endpackage

package regfilemux;
typedef enum logic [3:0] {
    alu_out   = 4'b0000
    ,br_en    = 4'b0001
    ,u_imm    = 4'b0010
    ,lw       = 4'b0011
    ,pc_plus4 = 4'b0100
    ,lb        = 4'b0101
    ,lbu       = 4'b0110  // unsigned byte
    ,lh        = 4'b0111
    ,lhu       = 4'b1000  // unsigned halfword
} regfilemux_sel_t;
endpackage