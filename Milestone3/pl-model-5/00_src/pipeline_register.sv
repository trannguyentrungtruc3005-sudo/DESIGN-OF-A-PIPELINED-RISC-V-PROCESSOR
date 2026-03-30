module pipeline_register #(
    parameter DATA_WIDTH = 32,           // Width of the data bus
    parameter RESET_VALUE = 0            // Value to load on flush/reset
) (
    input  logic                     clk,       
    input  logic                     reset,     
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
        // If stall=1, do nothing (retain current value)
    end
end

endmodule
