
module pipelined (
    input logic i_clk,
    input logic i_reset,

    output logic [31:0] o_pc_debug,
    output logic o_insn_vld,
    output logic o_ctrl,
    output logic o_mispred,

    output logic [31:0] o_io_ledr, // Output for red LEDs
    output logic [31:0] o_io_ledg, // Output for green LEDs
    output logic [6:0] o_io_hex0,  // Output for 7-segment display 0
    output logic [6:0] o_io_hex1,  // Output for 7-segment display 1
    output logic [6:0] o_io_hex2,  // Output for 7-segment display 2
    output logic [6:0] o_io_hex3,  // Output for 7-segment display 3
    output logic [6:0] o_io_hex4,  // Output for 7-segment display 4
    output logic [6:0] o_io_hex5,  // Output for 7-segment display 5
    output logic [6:0] o_io_hex6,  // Output for 7-segment display 6
    output logic [6:0] o_io_hex7,  // Output for 7-segment display 7
    output logic [31:0] o_io_lcd,  // Output for LCD register
    input logic [31:0] i_io_sw    // Input for switches
);
////////////////////////////////
    logic pc_stall, if_id_stall, id_ex_stall;
    logic if_id_flush, id_ex_flush, ex_mem_flush;
    // assign stall = 0;
    // assign if_id_stall = 0;
    // assign id_ex_stall = 0;

    // assign if_id_flush = 0;
    // assign id_ex_flush = 0;
    // assign ex_mem_flush = 0;


////////////////////////////////
    logic [31:0] pc_next, pc_four;
// IF STAGE SIGNAL ///////////
    logic [31:0] if_pc;
    // logic[31:0] if_instr;
// ID STAGE SIGNAL ///////////
    logic [31:0] id_pc;
    logic id_insn_vld;
// REGFILE ID STAGE //////
    logic[31:0] id_rs1_data, id_rs2_data;
// REGFILE ID STAGE //////
    logic[31:0] id_imm;

// CONTROL UNIT ID STAGE //////
    logic[31:0] id_instr; // ID
    logic [2:0] id_imm_sel; // ID

    logic id_pc_sel; // EX
    logic id_br_un; // EX
    logic id_opa_sel; //EX
    logic id_opb_sel; //EX
    logic[3:0] id_alu_op; // EX
    logic id_branch_cmd;
    logic[2:0] id_branch_type;

    logic id_mem_wren; // MEM
    logic[1:0] id_lsu_op;
    logic id_ld_un;

    logic id_rd_wren; // WB
    logic[1:0] id_wb_sel;
    logic[4:0] id_wb_addr;

        // ===== OPCODES  =====                    
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_JAL    = 7'b1101111; 
    localparam OP_OP_IMM = 7'b0010011;
    localparam OP_OP     = 7'b0110011;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;

    // Opcode của lệnh đang ở ID stage
    logic [6:0] id_opcode;
    assign id_opcode = id_instr[6:0];              

    
////////////////////////////////

// EX STAGE SIGNAL ///////////
    logic[31:0] operand_a, operand_b;
    logic[31:0] ex_alu_data;

    logic [31:0] ex_pc;
    logic ex_insn_vld;
    logic ex_ctrl;
    logic[31:0] ex_rs1_data, ex_rs2_data;
    logic[31:0] ex_imm;

    logic ex_pc_sel; // EX
    logic ex_br_un; // EX
    logic ex_opa_sel; //EX
    logic ex_opb_sel; //EX
    logic[3:0] ex_alu_op; // EX
    logic ex_branch_cmd;
    logic[2:0] ex_branch_type;

    logic ex_mem_wren; // MEM
    logic[1:0] ex_lsu_op;
    logic ex_ld_un;

    logic ex_rd_wren; // WB
    logic[1:0] ex_wb_sel;
    logic[4:0] ex_wb_addr;

    logic ex_jmp, ex_br_jmp;
    logic ex_mem_read;

// MEM STAGE SIGNAL ///////////
    logic[31:0] mem_alu_data;
    logic [31:0] mem_pc;
    logic mem_insn_vld;
    logic mem_ctrl, mem_mispred;
    logic[31:0] mem_rs2_data, mem_pc_four, mem_alu_pc_data;



    logic mem_mem_wren; // MEM
    logic[1:0] mem_lsu_op;
    logic mem_ld_un;

    logic mem_rd_wren; // WB
    logic[1:0] mem_wb_sel;
    logic[4:0] mem_wb_addr;


// WB STAGE SIGNAL ///////////
    logic wb_rd_wren; // WB
    logic[1:0] wb_wb_sel;
    logic[4:0] wb_wb_addr;

    logic[31:0] wb_alu_pc_data, wb_ld_data, wb_wb_data;


    initial begin
        // o_pc_debug = 0;
    end

    logic mem_branch_taken;
    logic id_I_type;

	/////////////////////
    hazard_detection hzd(
        .i_clk(i_clk),
        .i_reset(i_reset),
        .id_rs1_addr(id_instr[19:15]),        // RS1 register in ID stage
        .id_rs2_addr(id_instr[24:20]),        // RS2 register in ID stage
        .ex_rd_addr(ex_wb_addr),         // Destination register in EX stage
        .ex_is_load(ex_rd_wren),   // Load instruction in EX stage
        .ex_branch(ex_jmp),     // Branch instruction in EX stage
        .mem_rd_addr(mem_wb_addr),
        .mem_is_load(mem_rd_wren),
        .wb_rd_addr(wb_wb_addr),
        .wb_is_load(wb_rd_wren),
        .mem_branch_taken(mem_branch_taken),
        .id_I_type(id_I_type),

        .pc_stall(pc_stall),      // Stall PC update
        .if_id_stall(if_id_stall),   // Stall IF/ID register
        .id_ex_stall(id_ex_stall),   // Stall ID/EX register
        .if_id_flush(if_id_flush),   // Flush IF/ID register
        .id_ex_flush(id_ex_flush),   // Flush ID/EX register
        .ex_mem_flush(ex_mem_flush)   // Flush EX/MEM register
    );

	
//// IF STAGE //////////
    assign pc_next = (ex_jmp) ? ex_alu_data : pc_four; // pc_sel = 1 -> alu_data

	  add_sub pc_4(
        .x(if_pc), 
        .y(32'd4), 
        .c_in(1'b0), 
        .s(pc_four), 
        .c_out()
    ); 

    pipeline_register #(32, 0) if_pc_reg (
        .clk(i_clk), .reset(i_reset), .flush(1'b0),
        .stall(pc_stall), .data_in(pc_next), .data_out(if_pc)
    );


    pipeline_register #(32, 0) if_id_pc_reg (
        .clk(i_clk), .reset(i_reset), .flush(if_id_flush),
        .stall(if_id_stall), .data_in(if_pc), .data_out(id_pc)
    );
  
//// ID STAGE //////////
    
	control_unit CU(
        .i_instr(id_instr), // ID
        .o_imm_sel(id_imm_sel), // ID

        .o_pc_sel(id_pc_sel), // EX
        .o_br_un(id_br_un), // EX
        .o_opa_sel(id_opa_sel), // EX
        .o_opb_sel(id_opb_sel), // EX
        .o_alu_op(id_alu_op), // EX

        .o_mem_wren(id_mem_wren), // MEM
        .o_lsu_op(id_lsu_op), // MEM 0x: word handle, 10: Half word, 11: byte
        .o_ld_un(id_ld_un), // MEM 0: for signed, 1: for unsigned

        .o_wb_sel(id_wb_sel), // WB
        .o_rd_wren(id_rd_wren), // WB
        .o_insn_vld(id_insn_vld) // WB
    );

    // regfile block
    regfile RF(
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_rs1_addr(id_instr[19:15]),
        .i_rs2_addr(id_instr[24:20]),
        .o_rs1_data(id_rs1_data),
        .o_rs2_data(id_rs2_data),

        .i_rd_addr(wb_wb_addr),
        .i_rd_data(wb_wb_data),
        .i_rd_wren(wb_rd_wren)
    );
    assign id_wb_addr = id_instr[11:7];
    // immediate block
    immgen IG(
        .i_instr(id_instr[31:7]),
        .i_imm_sel(id_imm_sel), // bit 1: 0 for S type, 1 for B type, // bit 0: 0 for I-J type 1 for S type
        .o_imm(id_imm)
    );
    assign id_branch_cmd = ~id_imm_sel[2] & ~id_imm_sel[1] & id_imm_sel[0];
    assign id_branch_type = id_instr[14:12];
    // id_I_type = 1 nếu lệnh KHÔNG dùng rs2 (I-type, load, jalr, lui, auipc)
    // id_I_type = 0 nếu lệnh có dùng rs2 (R-type, branch, store, ...)
    assign id_I_type = (id_opcode == OP_OP_IMM) || (id_opcode == OP_LOAD) || (id_opcode == OP_JALR)   || (id_opcode == OP_LUI)  || (id_opcode == OP_AUIPC);            //FIX O DAY

    



//// ID STAGE //////////
    pipeline_register #(32, 0) id_ex_pc_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_pc), .data_out(ex_pc)
    );
    pipeline_register #(1, 0) id_ex_insn_vld_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_insn_vld), .data_out(ex_insn_vld)
    );

    pipeline_register #(32, 3) id_ex_imm_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_imm), .data_out(ex_imm)
    );
    pipeline_register #(32, 0) id_ex_rs1_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_rs1_data), .data_out(ex_rs1_data)
    );
    pipeline_register #(32, 0) id_ex_rs2_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_rs2_data), .data_out(ex_rs2_data)
    );

    // EX control
    pipeline_register #(1, 0) id_ex_pc_sel_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_pc_sel), .data_out(ex_pc_sel)
    );
    pipeline_register #(1, 0) id_ex_br_un_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_br_un), .data_out(ex_br_un)
    );
    pipeline_register #(1, 0) id_ex_opa_sel_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_opa_sel), .data_out(ex_opa_sel)
    );
    pipeline_register #(1, 1) id_ex_opb_sel_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_opb_sel), .data_out(ex_opb_sel)
    );
    pipeline_register #(4, 0) id_ex_alu_op_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_alu_op), .data_out(ex_alu_op)
    );
    pipeline_register #(1, 0) id_ex_branch_cmd_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_branch_cmd), .data_out(ex_branch_cmd)
    );
    pipeline_register #(3, 0) id_ex_branch_type_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_branch_type), .data_out(ex_branch_type)
    );
    // MEM control
    pipeline_register #(1, 0) id_ex_mem_wren_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_mem_wren), .data_out(ex_mem_wren)
    );
    pipeline_register #(2, 0) id_ex_lsu_op_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_lsu_op), .data_out(ex_lsu_op)
    );
    pipeline_register #(1, 0) id_ex_ld_un_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_ld_un), .data_out(ex_ld_un)
    );
    // WB control
    pipeline_register #(2, 1) id_ex_wb_sel_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_wb_sel), .data_out(ex_wb_sel)
    );
    pipeline_register #(1, 1) id_ex_rd_wren_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_rd_wren), .data_out(ex_rd_wren)
    );
    pipeline_register #(5, 0) id_ex_wb_addr_reg (
        .clk(i_clk), .reset(i_reset), .flush(id_ex_flush),
        .stall(id_ex_stall), .data_in(id_wb_addr), .data_out(ex_wb_addr)
    );


//// EX STAGE //////////
    // add forward mux//
    assign operand_a = (ex_opa_sel) ? ex_pc : ex_rs1_data;
    assign operand_b = (ex_opb_sel) ? ex_imm : ex_rs2_data;
    alu AL(
        .i_op_a(operand_a),
        .i_op_b(operand_b),
        .i_alu_op(ex_alu_op),
        .o_alu_data(ex_alu_data)
    );

    brc_control BRC(
        .i_rs1_data(ex_rs1_data),
        .i_rs2_data(ex_rs2_data),
        .i_br_un(ex_br_un), // 1: unsigned, 0 for signed
        .i_br_type(ex_branch_type),
        .o_jump(ex_br_jmp)
    );
    assign ex_jmp = (ex_branch_cmd & ex_br_jmp) | ex_pc_sel;
    assign ex_ctrl = ex_pc_sel | ex_branch_cmd;
    assign ex_mem_read = (~ex_wb_sel[1]) & (~ex_wb_sel[0]);

//// EX STAGE //////////
    pipeline_register #(32, 0) ex_mem_pc_reg (
        .clk(i_clk), .reset(i_reset), .flush(ex_mem_flush),
        .stall(1'b0), .data_in(ex_pc), .data_out(mem_pc)
    );
    pipeline_register #(1, 0) ex_mem_insn_vld_reg (
        .clk(i_clk), .reset(i_reset), .flush(ex_mem_flush),
        .stall(1'b0), .data_in(ex_insn_vld), .data_out(mem_insn_vld)
    );
    pipeline_register #(1, 0) ex_mem_ctrl_reg (
        .clk(i_clk), .reset(i_reset), .flush(ex_mem_flush),
        .stall(1'b0), .data_in(ex_ctrl), .data_out(mem_ctrl)
    );
    pipeline_register #(1, 0) ex_mem_mispred_reg (
        .clk(i_clk), .reset(i_reset), .flush(ex_mem_flush),
        .stall(1'b0), .data_in(ex_jmp), .data_out(mem_mispred)
    );

    pipeline_register #(32, 0) ex_mem_pc_four_reg (
        .clk(i_clk), .reset(i_reset), .flush(ex_mem_flush),
        .stall(1'b0), .data_in(ex_pc+4), .data_out(mem_pc_four)
    );
    pipeline_register #(32, 0) ex_mem_alu_data_reg (
        .clk(i_clk), .reset(i_reset), .flush(ex_mem_flush),
        .stall(1'b0), .data_in(ex_alu_data), .data_out(mem_alu_data)
    );
    pipeline_register #(32, 0) ex_mem_rs2_reg (
        .clk(i_clk), .reset(i_reset), .flush(ex_mem_flush),
        .stall(1'b0), .data_in(ex_rs2_data), .data_out(mem_rs2_data)
    );

    // MEM control
    pipeline_register #(1, 0) ex_mem_mem_wren_reg (
        .clk(i_clk), .reset(i_reset), .flush(ex_mem_flush),
        .stall(1'b0), .data_in(ex_mem_wren), .data_out(mem_mem_wren)
    );
    pipeline_register #(2, 0) ex_mem_lsu_op_reg (
        .clk(i_clk), .reset(i_reset), .flush(ex_mem_flush),
        .stall(1'b0), .data_in(ex_lsu_op), .data_out(mem_lsu_op)
    );
    pipeline_register #(1, 0) ex_mem_ld_un_reg (
        .clk(i_clk), .reset(i_reset), .flush(ex_mem_flush),
        .stall(1'b0), .data_in(ex_ld_un), .data_out(mem_ld_un)
    );
    pipeline_register #(1, 0) ex_mem_branch_taken_reg (
        .clk(i_clk), .reset(i_reset), .flush(ex_mem_flush),
        .stall(1'b0), .data_in(ex_br_jmp), .data_out(mem_branch_taken)
    );

    // WB control
    pipeline_register #(2, 1) ex_mem_wb_sel_reg (
        .clk(i_clk), .reset(i_reset), .flush(ex_mem_flush),
        .stall(1'b0), .data_in(ex_wb_sel), .data_out(mem_wb_sel)
    );
    pipeline_register #(1, 1) ex_mem_rd_wren_reg (
        .clk(i_clk), .reset(i_reset), .flush(ex_mem_flush),
        .stall(1'b0), .data_in(ex_rd_wren), .data_out(mem_rd_wren)
    );
    pipeline_register #(5, 0) ex_mem_wb_addr_reg (
        .clk(i_clk), .reset(i_reset), .flush(ex_mem_flush),
        .stall(1'b0), .data_in(ex_wb_addr), .data_out(mem_wb_addr)
    );

//// MEM STAGE //////////
    lsu LS(
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_lsu_addr(mem_alu_data), // Address for data read/write
        .i_st_data(mem_rs2_data),  // Data to be stored
        .i_lsu_wren(mem_mem_wren),     // Write enable signal (1 if writing)

        .o_ld_data(wb_ld_data), // Data read from memory // data change if clock posedge
        .o_io_ledr(o_io_ledr), // Output for red LEDs
        .o_io_ledg(o_io_ledg), // Output for green LEDs
        .o_io_hex0(o_io_hex0),  // Output for 7-segment display 0
        .o_io_hex1(o_io_hex1),  // Output for 7-segment display 1
        .o_io_hex2(o_io_hex2),  // Output for 7-segment display 2
        .o_io_hex3(o_io_hex3),  // Output for 7-segment display 3
        .o_io_hex4(o_io_hex4),  // Output for 7-segment display 4
        .o_io_hex5(o_io_hex5),  // Output for 7-segment display 5
        .o_io_hex6(o_io_hex6),  // Output for 7-segment display 6
        .o_io_hex7(o_io_hex7),  // Output for 7-segment display 7
        .o_io_lcd(o_io_lcd),  // Output for LCD register
        .i_io_sw(i_io_sw),   // Input for switches

        .i_lsu_op(mem_lsu_op), // 0x: word handle, 10: Half word, 11: byte
        .i_ld_un(mem_ld_un), // 0: for signed, 1: for unsigned

        .stall(if_id_stall),
        .flush(if_id_flush),
        .i_pc(if_pc), // Intruction fetch stage
        .o_instr(id_instr) // Intruction decode stage
    );

    assign mem_alu_pc_data = (mem_wb_sel[1]) ?  mem_pc_four : mem_alu_data; // 1x: pc4, 01: aludata, 00: lddata

//// MEM STAGE //////////
    pipeline_register #(32, 0) mem_wb_pc_reg (
        .clk(i_clk), .reset(i_reset), .flush(1'b0),
        .stall(1'b0), .data_in(mem_pc), .data_out(o_pc_debug)
    );
    pipeline_register #(1, 0) mem_wb_insn_vld_reg (
        .clk(i_clk), .reset(i_reset), .flush(1'b0),
        .stall(1'b0), .data_in(mem_insn_vld), .data_out(o_insn_vld)
    );
    pipeline_register #(1, 0) mem_wb_ctrl_reg (
        .clk(i_clk), .reset(i_reset), .flush(1'b0),
        .stall(1'b0), .data_in(mem_ctrl), .data_out(o_ctrl)
    );
    pipeline_register #(1, 0) mem_wb_mispred_reg (
        .clk(i_clk), .reset(i_reset), .flush(1'b0),
        .stall(1'b0), .data_in(mem_mispred), .data_out(o_mispred)
    );

    pipeline_register #(32, 0) mem_wb_alu_pc_reg (
        .clk(i_clk), .reset(i_reset), .flush(1'b0),
        .stall(1'b0), .data_in(mem_alu_pc_data), .data_out(wb_alu_pc_data)
    );

    // WB control
    pipeline_register #(2, 1) mem_wb_wb_sel_reg (
        .clk(i_clk), .reset(i_reset), .flush(1'b0),
        .stall(1'b0), .data_in(mem_wb_sel), .data_out(wb_wb_sel)
    );
    pipeline_register #(1, 1) mem_wb_rd_wren_reg (
        .clk(i_clk), .reset(i_reset), .flush(1'b0),
        .stall(1'b0), .data_in(mem_rd_wren), .data_out(wb_rd_wren)
    );
    pipeline_register #(5, 0) mem_wb_wb_addr_reg (
        .clk(i_clk), .reset(i_reset), .flush(1'b0),
        .stall(1'b0), .data_in(mem_wb_addr), .data_out(wb_wb_addr)
    );

//// WB STAGE //////////
    assign wb_wb_data = (wb_wb_sel[1] | wb_wb_sel[0]) ? wb_alu_pc_data : wb_ld_data; // 1x: pc4, 01: aludata, 00: lddata


endmodule
