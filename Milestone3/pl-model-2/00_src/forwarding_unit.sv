module forwarding_unit(
    input  logic [4:0] ex_rs1_addr,
    input  logic [4:0] ex_rs2_addr,
    input  logic [4:0] mem_rd_addr,
    input  logic       mem_reg_write,
    input  logic [4:0] wb_rd_addr,
    input  logic       wb_reg_write,
    input  logic [4:0] temp_rd_addr,
    input  logic       temp_reg_write,
    output logic [1:0]  forward_a,
    output logic [1:0]  forward_b
);
    always_comb begin
        // Forward A
        if (mem_reg_write && (mem_rd_addr != 0) && (mem_rd_addr == ex_rs1_addr)) 
            forward_a = 2'b10;
        else if (wb_reg_write && (wb_rd_addr != 0) && (wb_rd_addr == ex_rs1_addr))
            forward_a = 2'b01;
        else if (temp_reg_write && (temp_rd_addr != 0) && (temp_rd_addr == ex_rs1_addr))
            forward_a = 2'b11;
        else 
            forward_a = 2'b00;
        
        // Forward B
        if (mem_reg_write && (mem_rd_addr != 0) && (mem_rd_addr == ex_rs2_addr))
            forward_b = 2'b10;
        else if (wb_reg_write && (wb_rd_addr != 0) && (wb_rd_addr == ex_rs2_addr))
            forward_b = 2'b01;
        else if (temp_reg_write && (temp_rd_addr != 0) && (temp_rd_addr == ex_rs2_addr))
            forward_b = 2'b11;
        else 
            forward_b = 2'b00;
    end
endmodule
