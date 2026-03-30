module immgen (
	      input logic[31:7] i_instr,
          input logic[2:0] i_imm_sel, // bit 1: 0 for S type, 1 for B type, // bit 0: 0 for I-J type 1 for S type
          output logic[31:0] o_imm
);
    localparam S_type = 3'b000;
    localparam B_type = 3'b001;
    localparam I_type = 3'b011;
    localparam J_type = 3'b010;
    localparam U_type = 3'b110;
    always_comb begin
        case (i_imm_sel)
            S_type: o_imm = {{20{i_instr[31]}}, i_instr[31:25], i_instr[11:7]};
            I_type: o_imm = {{20{i_instr[31]}}, i_instr[31:20]};
            B_type: o_imm = {{20{i_instr[31]}}, i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0};
            U_type: o_imm = {i_instr[31:12], 12'd0};
            J_type: o_imm = {{12{i_instr[31]}}, i_instr[19:12], i_instr[20], i_instr[30:25], i_instr[24:21], 1'b0};
            default: ;
        endcase
    end

endmodule
