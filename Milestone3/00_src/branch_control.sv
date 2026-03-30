module branch_control (
    input logic clk,
    input logic reset,

    input logic [31:0] i_instr,
    input logic [31:0] pc,

    output logic [31:0] branch_pc,
    output logic branch_taken

);

	logic [31:0] tmp1, tmp2, result1, result2;


	assign tmp1 = {{12{i_instr[31]}}, i_instr[19:12], i_instr[20], i_instr[30:25], i_instr[24:21], 1'b0};
	assign tmp2 = {{20{i_instr[31]}}, i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0};

	 add_sub dut1(
        .x(pc), 
        .y(tmp1),
        .c_in(1'b0),
        .s(result1),
        .c_out()
	);
	
 	add_sub dut2(
        .x(pc), 
        .y(tmp2),
        .c_in(1'b0),
        .s(result2),
        .c_out()
	);


    always_comb begin
        if (i_instr[6:2] == 5'b11011) begin
            branch_taken = 1;
            branch_pc = result1;
        end
        else if (i_instr[6:2] == 5'b11000) begin // always taken
            branch_taken = 1;
            branch_pc = result2;
        end
        else begin 
            branch_taken = 0;
            branch_pc = 0;
        end
    end
    
endmodule
