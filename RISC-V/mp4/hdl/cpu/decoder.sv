module decoder
import types::*;
(
    input  rv32i_opcode opcode,
    input  logic [2:0]  funct3,
    input  logic [6:0]  funct7,
    output ctrl_word_t  ctrl
);

arith_funct3_t arith_funct3;
assign arith_funct3 = arith_funct3_t'(funct3);
load_funct3_t load_funct3;
assign load_funct3 = load_funct3_t'(funct3);
branch_funct3_t branch_funct3;
assign branch_funct3 = branch_funct3_t'(funct3);
mul_funct3_t mul_funct3;
assign mul_funct3 = mul_funct3_t'(funct3);

always_comb begin
    ctrl = '0;
    case(opcode)
        op_lui : begin
            // x[rd] = sext(immediate[31:12] << 12)
            ctrl.alumux1_sel = alumux::pc_out; // not used here
            ctrl.alumux2_sel = alumux::j_imm; // not used here
            ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
            ctrl.aluop = alu_ops'(alu_add); // not used here
            ctrl.cmpop = beq; // not used here
            ctrl.marmux_sel = marmux::pc_out;
            ctrl.regfilemux_sel = regfilemux::u_imm;
            ctrl.load_regfile = '1;
        end

        op_auipc : begin
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::u_imm;
            ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
            ctrl.aluop = alu_ops'(alu_add);
            ctrl.cmpop = beq; // not used here
            ctrl.marmux_sel = marmux::pc_out;
            ctrl.regfilemux_sel = regfilemux::alu_out;
            ctrl.load_regfile = '1;
        end

        op_jal : begin
            // x[rd] = pc + 4; pc += sext(offset)
            // offset is j-imm, alu inputs are pc and j_imm, alu adds and goes to pc
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::j_imm;
            ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
            ctrl.aluop = alu_ops'(alu_add);
            ctrl.cmpop = beq; // not used here
            ctrl.marmux_sel = marmux::pc_out;
            ctrl.regfilemux_sel = regfilemux::pc_plus4;
            ctrl.load_regfile = '1;
        end

        op_jalr : begin
            //  t = pc+4, pc = (x[rs1] + sext(offset))&~1; x[rd]=t
            ctrl.alumux1_sel = alumux::rs1_data;
            ctrl.alumux2_sel = alumux::i_imm;
            ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
            ctrl.aluop = alu_ops'(alu_add);
            ctrl.cmpop = beq; // not used here
            ctrl.marmux_sel = marmux::pc_out;
            ctrl.regfilemux_sel = regfilemux::pc_plus4;
            ctrl.load_regfile = '1;
        end

        op_br : begin
            // compare rs1 and rs2, add offset, then branch depending on result
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::b_imm;
            ctrl.cmpmux_sel = cmpmux::rs2_data;
            ctrl.aluop = alu_ops'(alu_add);
            ctrl.cmpop = branch_funct3;
            ctrl.marmux_sel = marmux::pc_out;
            ctrl.regfilemux_sel = regfilemux::pc_plus4;
            ctrl.load_regfile = '0;
        end

        op_load : begin
            ctrl.dmem_read = 1'b1;
            ctrl.alumux1_sel = alumux::rs1_data;
            ctrl.alumux2_sel = alumux::i_imm;
            ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
            ctrl.aluop = alu_ops'(alu_add); // not used here
            ctrl.cmpop = beq; // not used here
            ctrl.marmux_sel = marmux::alu_out;

            case(load_funct3)
                lb : begin
                    ctrl.regfilemux_sel = regfilemux::lb;
                end

                lh : begin
                    ctrl.regfilemux_sel = regfilemux::lh;
                end

                lw : begin
                    ctrl.regfilemux_sel = regfilemux::lw;
                end

                lbu : begin
                    ctrl.regfilemux_sel = regfilemux::lbu;
                end

                lhu : begin
                    ctrl.regfilemux_sel = regfilemux::lhu;
                end
            endcase  
            ctrl.load_regfile = '1;
        end

        op_store : begin
            ctrl.dmem_write = 1'b1;
            ctrl.alumux1_sel = alumux::rs1_data;
            ctrl.alumux2_sel = alumux::s_imm;
            ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
            ctrl.aluop = alu_ops'(alu_add);
            ctrl.cmpop = beq; // not used here
            ctrl.marmux_sel = marmux::alu_out;
            ctrl.regfilemux_sel = regfilemux::alu_out; // not used here
            ctrl.load_regfile = '0;
        end

        op_imm : begin
            case(arith_funct3)
                // ADDi
                //    -> x[rd] = x[rs1] + sext(immediate)
                add : begin
                    ctrl.alumux1_sel = alumux::rs1_data;
                    ctrl.alumux2_sel = alumux::i_imm;
                    ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
                    ctrl.aluop = alu_ops'(funct3);
                    ctrl.cmpop = beq; // not used here
                    ctrl.marmux_sel = marmux::pc_out;
                    ctrl.regfilemux_sel = regfilemux::alu_out;
                end
                
                // SLTi
                //   -> x[rd] = x[rs1] s sext(immediate)
                // use comparator between rs1 and i_imm (cmpmux::i_imm)
                slt : begin
                    ctrl.alumux1_sel = alumux::rs1_data; // not used here
                    ctrl.alumux2_sel = alumux::i_imm; // not used here
                    ctrl.cmpmux_sel = cmpmux::i_imm;
                    ctrl.aluop = alu_ops'(funct3); // not used here
                    ctrl.cmpop = blt;
                    ctrl.marmux_sel = marmux::pc_out;
                    ctrl.regfilemux_sel = regfilemux::br_en;
                end

                // SLTiu
                //    -> x[rd] = x[rs1] u sext(immediate)
                sltu : begin
                    ctrl.alumux1_sel = alumux::rs1_data; // not used here
                    ctrl.alumux2_sel = alumux::i_imm; // not used here
                    ctrl.cmpmux_sel = cmpmux::i_imm;
                    ctrl.aluop = alu_ops'(funct3); // not used here
                    ctrl.cmpop = bltu;
                    ctrl.marmux_sel = marmux::pc_out;
                    ctrl.regfilemux_sel = regfilemux::br_en;
                end

                // XORi
                //    -> x[rd] = x[rs1] ^ sext(immediate)
                axor : begin
                    ctrl.alumux1_sel = alumux::rs1_data;
                    ctrl.alumux2_sel = alumux::i_imm;
                    ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
                    ctrl.aluop = alu_ops'(funct3);
                    ctrl.cmpop = beq; // not used here
                    ctrl.marmux_sel = marmux::pc_out;
                    ctrl.regfilemux_sel = regfilemux::alu_out;
                end

                // ORi
                //    -> x[rd] = x[rs1] | sext(immediate)
                aor : begin
                    ctrl.alumux1_sel = alumux::rs1_data;
                    ctrl.alumux2_sel = alumux::i_imm;
                    ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
                    ctrl.aluop = alu_ops'(funct3);
                    ctrl.cmpop = beq; // not used here
                    ctrl.marmux_sel = marmux::pc_out;
                    ctrl.regfilemux_sel = regfilemux::alu_out;
                end

                // ANDi
                //    -> x[rd] = x[rs1] & sext(immediate)
                aand : begin
                    ctrl.alumux1_sel = alumux::rs1_data;
                    ctrl.alumux2_sel = alumux::i_imm;
                    ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
                    ctrl.aluop = alu_ops'(funct3);
                    ctrl.cmpop = beq; // not used here
                    ctrl.marmux_sel = marmux::pc_out;
                    ctrl.regfilemux_sel = regfilemux::alu_out;
                end

                // SLLi
                //    -> x[rd] = x[rs1]  shamt
                sll : begin
                    ctrl.alumux1_sel = alumux::rs1_data;
                    ctrl.alumux2_sel = alumux::i_imm;
                    ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
                    ctrl.aluop = alu_ops'(funct3);
                    ctrl.cmpop = beq; // not used here
                    ctrl.marmux_sel = marmux::pc_out;
                    ctrl.regfilemux_sel = regfilemux::alu_out;
                end

                /*
                // SRLi
                //    -> x[rd] = x[rs1] >>u shamt

                // SRAi
                //    -> x[rd] = x[rs1] >>s shamt
                */
                sr : begin
                    // differentiate with bit 30 - if its 0 go to srl otherwise sra
                    ctrl.alumux1_sel = alumux::rs1_data;
                    ctrl.alumux2_sel = alumux::i_imm;
                    ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here

                    if(funct7[5] == '0) begin
                        ctrl.aluop = alu_srl;
                    end
                    else begin
                        ctrl.aluop = alu_sra;
                    end

                    ctrl.cmpop = beq; // not used here
                    ctrl.marmux_sel = marmux::pc_out;
                    ctrl.regfilemux_sel = regfilemux::alu_out;
                end
            endcase
            ctrl.load_regfile = '1;
        end

        op_reg : begin
            if (funct7[0] == '1) begin  // multiplication and division
                ctrl.alumux1_sel = alumux::rs1_data;
                ctrl.alumux2_sel = alumux::rs2_data;
                ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
                ctrl.aluop = alu_ops'(funct3);
                ctrl.cmpop = beq; // not used here
                ctrl.marmux_sel = marmux::pc_out;
                ctrl.regfilemux_sel = regfilemux::alu_out;
                ctrl.load_regfile = '1;
            end else begin  // standard arithmetic functions
                case(arith_funct3)
                // ADD/SUB -- check bit30 to determine which one
                //    -> x[rd] = x[rs1] + sext(immediate)
                    add : begin

                        ctrl.alumux1_sel = alumux::rs1_data;
                        ctrl.alumux2_sel = alumux::rs2_data;
                        ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here

                        // add
                        if(funct7[5] == '0) begin
                            ctrl.aluop = alu_ops'(alu_add);
                        end
                        // sub
                        else begin
                            ctrl.aluop = alu_ops'(alu_sub);
                        end

                        ctrl.cmpop = beq; // not used here
                        ctrl.marmux_sel = marmux::pc_out;
                        ctrl.regfilemux_sel = regfilemux::alu_out;
                    end
                    
                    // SLL
                    //   -> x[rd] = x[rs1]  x[rs2]
                    sll : begin
                        ctrl.alumux1_sel = alumux::rs1_data;
                        ctrl.alumux2_sel = alumux::rs2_data;
                        ctrl.cmpmux_sel = cmpmux::rs2_data;
                        ctrl.aluop = alu_ops'(funct3);
                        ctrl.cmpop = beq;
                        ctrl.marmux_sel = marmux::pc_out;
                        ctrl.regfilemux_sel = regfilemux::alu_out;
                    end

                    // SLT
                    //    -> x[rd] = x[rs1] s x[rs2]
                    // use comparator between rs1 and i_imm (cmpmux::i_imm)
                    slt : begin
                        ctrl.alumux1_sel = alumux::rs1_data; // not used here
                        ctrl.alumux2_sel = alumux::rs2_data; // not used here
                        ctrl.cmpmux_sel = cmpmux::rs2_data;
                        ctrl.aluop = alu_ops'(funct3); // not used here
                        ctrl.cmpop = blt;
                        ctrl.marmux_sel = marmux::pc_out; // not used here
                        ctrl.regfilemux_sel = regfilemux::br_en;
                    end

                    // SLTu
                    //    -> x[rd] = x[rs1] u x[rs2]
                    sltu : begin
                        ctrl.alumux1_sel = alumux::rs1_data; // not used here
                        ctrl.alumux2_sel = alumux::rs2_data; // not used here
                        ctrl.cmpmux_sel = cmpmux::rs2_data;
                        ctrl.aluop = alu_ops'(funct3); // not used here
                        ctrl.cmpop = bltu;
                        ctrl.marmux_sel = marmux::pc_out; // not used here
                        ctrl.regfilemux_sel = regfilemux::br_en;
                    end

                    // XOR
                    //    -> x[rd] = x[rs1] ^ x[rs2]
                    axor : begin
                        ctrl.alumux1_sel = alumux::rs1_data;
                        ctrl.alumux2_sel = alumux::rs2_data;
                        ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
                        ctrl.aluop = alu_ops'(funct3);
                        ctrl.cmpop = blt; // not used here
                        ctrl.marmux_sel = marmux::pc_out;
                        ctrl.regfilemux_sel = regfilemux::alu_out;
                    end

                    /*
                    // SRL
                    //    -> x[rd] = x[rs1] >>u x[rs2]

                    // SRA
                    //    -> x[rd] = x[rs1] >>s x[rs2]
                    */
                    sr : begin
                        // differenitniate with bit 30 - if its 0 go to srl otherwise sra
                        ctrl.alumux1_sel = alumux::rs1_data;
                        ctrl.alumux2_sel = alumux::rs2_data;
                        ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
                        if(funct7[5] == '0) begin
                            ctrl.aluop = alu_srl;
                        end 
                        else begin
                            ctrl.aluop = alu_sra;
                        end
                        ctrl.cmpop = blt; // not used here
                        ctrl.marmux_sel = marmux::pc_out;
                        ctrl.regfilemux_sel = regfilemux::alu_out;
                    end

                    // OR
                    //    -> x[rd] = x[rs1] | x[rs2]
                    aor : begin
                        ctrl.alumux1_sel = alumux::rs1_data;
                        ctrl.alumux2_sel = alumux::rs2_data;
                        ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
                        ctrl.aluop = alu_ops'(funct3);
                        ctrl.cmpop = blt; // not used here
                        ctrl.marmux_sel = marmux::pc_out;
                        ctrl.regfilemux_sel = regfilemux::alu_out;
                    end

                    // AND
                    //    -> x[rd] = x[rs1] & x[rs2]
                    aand : begin
                        ctrl.alumux1_sel = alumux::rs1_data;
                        ctrl.alumux2_sel = alumux::rs2_data;
                        ctrl.cmpmux_sel = cmpmux::rs2_data; // not used here
                        ctrl.aluop = alu_ops'(funct3);
                        ctrl.cmpop = blt; // not used here
                        ctrl.marmux_sel = marmux::pc_out;
                        ctrl.regfilemux_sel = regfilemux::alu_out;
                    end

                endcase
                ctrl.load_regfile = '1;
            end
        end

        op_csr : begin
            // NA
        end

    endcase
end


endmodule