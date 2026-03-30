module control_unit (
    input  logic [31:0] i_instr,
    output logic [3:0]  o_alu_op,    
    output logic        o_rd_wren,     
    output logic        o_opa_sel,     // 0:rs1; 1: pc
    output logic        o_opb_sel,     // 0: rs2; 1: IMM
    output logic [2:0]  o_imm_sel,    
    output logic [1:0]  o_wb_sel,      // 00:data; 01:ALU, 10:PC+4
    output logic        o_mem_wren,    
    output logic        o_br_un,      
    output logic        o_pc_sel,      // 0: branch, 1: jal/jalr 
    output logic        o_insn_vld,   
    output logic [1:0]  o_lsu_op,      // 00: word, 10: half word, 11: byte
    output logic        o_ld_un        // 0: signed, 1: unsigned
);

    // ===== OPCODES =====
    localparam OP_LOAD     = 7'b0000011;
    localparam OP_STORE    = 7'b0100011;
    localparam OP_BRANCH   = 7'b1100011;
    localparam OP_JALR     = 7'b1100111;
    localparam OP_JAL      = 7'b1101111; 
    localparam OP_OP_IMM   = 7'b0010011;
    localparam OP_OP       = 7'b0110011;
    localparam OP_LUI      = 7'b0110111;
    localparam OP_AUIPC    = 7'b0010111;
    
    // ===== IMMEDIATE TYPES =====
    localparam IMM_I  = 3'b011;
    localparam IMM_S  = 3'b000;
    localparam IMM_B  = 3'b001;
    localparam IMM_U  = 3'b110;
    localparam IMM_J  = 3'b010;

    // ===== ALU OPERATIONS =====
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b1000;
    localparam ALU_SLL  = 4'b0001;
    localparam ALU_SLT  = 4'b0010;
    localparam ALU_SLTU = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SRL  = 4'b0101;
    localparam ALU_SRA  = 4'b1101;
    localparam ALU_OR   = 4'b0110;
    localparam ALU_AND  = 4'b0111;
    localparam ALU_LUI  = 4'b1111; // For LUI: AND with 32'hFFFF_FFFF

    // ===== FUNCTION3 =====
    localparam F3_ADD_SUB  = 3'b000;
    localparam F3_SLL      = 3'b001;
    localparam F3_SLT      = 3'b010;
    localparam F3_SLTU     = 3'b011;
    localparam F3_XOR      = 3'b100;
    localparam F3_SRL_SRA  = 3'b101;
    localparam F3_OR       = 3'b110;
    localparam F3_AND      = 3'b111;

    // ===== LOAD/STORE =====
    localparam F3_LB_SB  = 3'b000;
    localparam F3_LH_SH  = 3'b001;
    localparam F3_LW_SW  = 3'b010;
    localparam F3_LBU    = 3'b100;
    localparam F3_LHU    = 3'b101;

    // ===== BRANCH =====
    localparam F3_BEQ  = 3'b000;
    localparam F3_BNE  = 3'b001;
    localparam F3_BLT  = 3'b100;
    localparam F3_BGE  = 3'b101;
    localparam F3_BLTU = 3'b110;
    localparam F3_BGEU = 3'b111;

    // Internal decode
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = i_instr[6:0];
    assign funct3 = i_instr[14:12];
    assign funct7 = i_instr[31:25];

    // ===== MAIN CONTROL =====
    always_comb begin
        o_alu_op     = ALU_ADD;
        o_rd_wren    = 1'b0;
        o_opa_sel    = 1'b0;
        o_opb_sel    = 1'b0;
        o_imm_sel    = IMM_I;
        o_wb_sel     = 2'b00;  
        o_mem_wren   = 1'b0;
        o_pc_sel     = 1'b0;
        o_insn_vld   = 1'b1;
        o_br_un      = 1'b0;
        o_lsu_op     = 2'b00;
        o_ld_un      = 1'b0;

        case (opcode)
            // ===== R-TYPE =====
            OP_OP: begin
                o_rd_wren   = 1'b1;
                o_opa_sel   = 1'b0;      // rs1
                o_opb_sel   = 1'b0;      // rs2
                o_wb_sel    = 2'b01;     // ALU result
                o_br_un     = 1'b0;      
                case (funct3)
                    F3_ADD_SUB: o_alu_op = (funct7[5]) ? ALU_SUB : ALU_ADD;
                    F3_SLL:     o_alu_op = ALU_SLL;
                    F3_SLT:     o_alu_op = ALU_SLT;
                    F3_SLTU:    o_alu_op = ALU_SLTU;
                    F3_XOR:     o_alu_op = ALU_XOR;
                    F3_SRL_SRA: o_alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
                    F3_OR:      o_alu_op = ALU_OR;
                    F3_AND:     o_alu_op = ALU_AND;
                    default:    o_insn_vld = 1'b0;
                endcase
            end

            // ===== I-TYPE IMM =====
            OP_OP_IMM: begin
                o_rd_wren   = 1'b1;
                o_opa_sel   = 1'b0;      // rs1
                o_opb_sel   = 1'b1;      // IMM
                o_wb_sel    = 2'b01;     // ALU result
                o_br_un     = 1'b0;     
                case (funct3)
                    F3_ADD_SUB: o_alu_op = ALU_ADD;
                    F3_SLL:     o_alu_op = ALU_SLL;
                    F3_SLT:     o_alu_op = ALU_SLT;
                    F3_SLTU:    o_alu_op = ALU_SLTU;
                    F3_XOR:     o_alu_op = ALU_XOR;
                    F3_SRL_SRA: o_alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
                    F3_OR:      o_alu_op = ALU_OR;
                    F3_AND:     o_alu_op = ALU_AND;
                    default:    o_insn_vld = 1'b0;
                endcase
            end

            // ===== LOAD =====
            OP_LOAD: begin
                o_rd_wren   = 1'b1;
                o_opa_sel   = 1'b0;      // rs1
                o_opb_sel   = 1'b1;      // IMM
                o_imm_sel   = IMM_I;
                o_wb_sel    = 2'b00;     // Memory data
                o_alu_op    = ALU_ADD;
                o_br_un     = 1'b0;      
                case (funct3)
                    F3_LW_SW:  begin
                        o_lsu_op = 2'b00; 
                        o_ld_un = 1'b0; 
                    end 
                    F3_LB_SB:  begin 
                        o_lsu_op = 2'b11; 
                        o_ld_un = 1'b0; 
                    end 
                    F3_LBU:    begin 
                        o_lsu_op = 2'b11; 
                        o_ld_un = 1'b1; 
                    end 
                    F3_LH_SH:  begin 
                        o_lsu_op = 2'b10;   
                        o_ld_un = 1'b0; 
                    end 
                    F3_LHU:    begin 
                        o_lsu_op = 2'b10; 
                        o_ld_un = 1'b1; 
                    end 
                    default:   o_insn_vld = 1'b0;
                endcase
            end

            // ===== STORE =====
            OP_STORE: begin     
                o_mem_wren  = 1'b1;
                o_opa_sel   = 1'b0;      // rs1
                o_opb_sel   = 1'b1;      // IMM
                o_imm_sel   = IMM_S;
                o_alu_op    = ALU_ADD;
                o_br_un     = 1'b0;    
                case (funct3)
                    F3_LW_SW: begin 
                        o_lsu_op = 2'b00;   
                        o_ld_un = 1'b0; 
                    end 
                    F3_LB_SB: begin 
                        o_lsu_op = 2'b11; 
                        o_ld_un = 1'b0; 
                    end 
                    F3_LH_SH: begin 
                        o_lsu_op = 2'b10; 
                        o_ld_un = 1'b0; 
                    end 
                    default:  o_insn_vld = 1'b0;
                endcase
            end

            // ===== BRANCH =====
            OP_BRANCH: begin 
                o_opa_sel = 1'b1; // PC
                o_opb_sel = 1'b1; // IMM
                o_imm_sel = IMM_B;
                o_pc_sel  = 1'b0;
                case (funct3)
                    F3_BEQ, F3_BNE, F3_BLT, F3_BGE: 
                        o_br_un = 1'b0; // Signed 
                    F3_BLTU, F3_BGEU: 
                        o_br_un = 1'b1; // Unsigned
                    default: begin
                        o_insn_vld = 1'b0;
                        o_br_un = 1'b0; 
                    end
                endcase
            end

            // ===== JAL =====
            OP_JAL: begin
                o_rd_wren   = 1'b1;
                o_opa_sel   = 1'b1; // PC
                o_opb_sel   = 1'b1; // IMM
                o_imm_sel   = IMM_J;
                o_wb_sel    = 2'b10; // PC+4
                o_pc_sel    = 1'b1;  
                o_br_un     = 1'b0;  
            end

            // ===== JALR =====
            OP_JALR: begin
                o_rd_wren   = 1'b1;
                o_opa_sel   = 1'b0; // rs1
                o_opb_sel   = 1'b1; // IMM
                o_imm_sel   = IMM_I;
                o_wb_sel    = 2'b10; // PC+4
                o_pc_sel    = 1'b1;  
                o_br_un     = 1'b0;  
                o_insn_vld  = (funct3 == 3'b000);
            end

            // ===== LUI =====
            OP_LUI: begin
                o_rd_wren   = 1'b1;
                o_opa_sel   = 1'b0; // Don't care
                o_opb_sel   = 1'b1; // IMM
                o_imm_sel   = IMM_U;
                o_alu_op    = ALU_LUI; // 4'b1111
                o_wb_sel    = 2'b01; // ALU result
                o_br_un     = 1'b0;  
            end

            // ===== AUIPC =====
            OP_AUIPC: begin
                o_rd_wren   = 1'b1;
                o_opa_sel   = 1'b1; // PC
                o_opb_sel   = 1'b1; // IMM
                o_imm_sel   = IMM_U;
                o_alu_op    = ALU_ADD;
                o_wb_sel    = 2'b01; // ALU result
                o_br_un     = 1'b0;  
            end

            // ===== INVALID =====
            default: begin
                o_insn_vld = 1'b0;
                o_br_un    = 1'b0; 
            end
        endcase
    end

endmodule