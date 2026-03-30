module branch_predictor_2bit #(
    parameter NUM_ENTRIES = 1024,  // Number of prediction entries
    parameter PC_WIDTH = 32        // Program counter width
) (
    input logic clk,
    input logic reset,
    // Prediction interface
    input logic [PC_WIDTH-1:0] pc,
    input logic [PC_WIDTH-1:0] ex_pc,
    output logic predict_taken,
    // Update interface
    input logic update_en,
    input logic actual_taken
);

// 2-bit saturating counters
logic [1:0] counter [0:NUM_ENTRIES-1];


// Index calculation (use lower bits of PC)
localparam INDEX_BITS = $clog2(NUM_ENTRIES);
// KHAI BÁO trước
logic [INDEX_BITS-1:0] index;
logic [INDEX_BITS-1:0] ex_index;

// GÁN LIÊN TỤC sau (bắt buộc dùng assign)
assign index    = pc[INDEX_BITS+1:2];
assign ex_index = ex_pc[INDEX_BITS+1:2];

// Prediction logic
always_comb begin
    predict_taken = counter[index][1];  // Predict taken if MSB is 1
end

// Update logic
always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
        // Initialize all counters to weakly taken (01)
        counter <= '{default: 2'b01};
    end
    else if (update_en) begin
        // Update saturating counter
        case (counter[ex_index])
            2'b00: counter[ex_index] <= actual_taken ? 2'b01 : 2'b00;
            2'b01: counter[ex_index] <= actual_taken ? 2'b10 : 2'b00;
            2'b10: counter[ex_index] <= actual_taken ? 2'b11 : 2'b01;
            2'b11: counter[ex_index] <= actual_taken ? 2'b11 : 2'b10;
        endcase
    end
end

endmodule

