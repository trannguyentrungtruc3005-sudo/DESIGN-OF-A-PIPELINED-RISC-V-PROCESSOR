
module pipeline_register #(
    parameter DATA_WIDTH = 32,           
    parameter RESET_VALUE = 0            
) (
    input  logic                     clk,       // Clock
    input  logic                     reset,     // Async reset
    input  logic                     flush,     // Flush signal 
    input  logic                     stall,     // Stall signal 
    input  logic [DATA_WIDTH-1:0]    data_in,   // Input data
    output logic  [DATA_WIDTH-1:0]    data_out   // Output data
);

always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
        data_out <= RESET_VALUE;
    end else begin
        if (flush) begin
            data_out <= RESET_VALUE;  // Flush overrides stall
        end else if (!stall) begin
            data_out <= data_in;      // Normal operation
        end
       
    end
end

endmodule
