`define MEMFILE "../02_test/isa_4b.hex"
`define MEMSIZE 65536
`define ADDRBIT 16
module imem (	
    input  logic        i_clk,          // Global clock
    input  logic        i_reset,        // Global active reset
    input  logic        flush,
    input  logic        stall,
    input  logic [31:0] i_pc,
    output logic  [31:0] o_instr
);
	  // Memory declaration 
    logic [31:0] d_mem [`MEMSIZE/4-1:0];

    initial begin
        d_mem = '{default:'0};
    end    

    initial begin
        $readmemh(`MEMFILE, d_mem);
    end

    /// imem
    logic [`ADDRBIT-3:0] pc_addr;

  
    assign pc_addr = {i_pc[`ADDRBIT-1:2]};
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            // Reset outputs
            o_instr <= 0;
        end 
        else begin
            if (flush) begin
                o_instr <= 0;  // Flush overrides stall
            end else if (!stall) begin
                o_instr <= d_mem[pc_addr];      // Normal operation
            end
        end
    end
    /////
endmodule