module branch_control (
    input logic clk,
    input logic reset,

    input logic [31:0] i_instr,
    input logic [31:0] pc,

    output logic [31:0] branch_pc,
    output logic branch_taken,

    input logic update_en,
    input logic actual_taken
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

    logic prediction;

    branch_predictor_2bit #(
        .PC_WIDTH(32)
    ) predictor (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .predict_taken(prediction),
        .update_en(update_en),
        .actual_taken(actual_taken)
    );

    always_comb begin
        if (i_instr[6:2] == 5'b11011) begin
            branch_taken = 1;
            branch_pc = result1;
        end
        else if (i_instr[6:2] == 5'b11000) begin // always taken
            branch_taken = prediction;
            branch_pc = result2;
        end
        else begin 
            branch_taken = 0;
            branch_pc = 0;
        end
    end
    
endmodule

