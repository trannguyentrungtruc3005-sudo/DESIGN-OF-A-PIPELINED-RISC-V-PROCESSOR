
module regfile (
	      input logic i_clk,
	      input logic i_reset,
	      input logic[4:0] i_rs1_addr,
          input logic[4:0] i_rs2_addr,
          output logic[31:0] o_rs1_data,
          output logic[31:0] o_rs2_data,
	      input logic[4:0] i_rd_addr,
          input logic[31:0] i_rd_data,
	      input logic i_rd_wren
);
    logic [31:0] regfile_mem[31:0];
    
    genvar i;
    generate
        for (i = 0; i<32; i++) begin
            initial begin
                regfile_mem[i] = 0;
            end    
        end
    endgenerate


    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
        end
        else begin
            if (i_rd_wren) begin
                if (i_rd_wren && i_rd_addr != 5'd0) regfile_mem[i_rd_addr] <= i_rd_data;
            end   
        end
    end

    always @(*) begin
        o_rs1_data <= regfile_mem[i_rs1_addr];
        o_rs2_data <= regfile_mem[i_rs2_addr];
    end

endmodule
