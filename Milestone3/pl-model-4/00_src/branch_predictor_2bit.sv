module branch_predictor_2bit #(
    parameter PC_WIDTH = 32
) (
    input logic clk,
    input logic reset,
    // Prediction interface
    input logic [PC_WIDTH-1:0] pc,
    output logic predict_taken,
    // Update interface
    input logic update_en,
    input logic actual_taken
);

// 2-bit saturating counters
logic [1:0] counter;


// Prediction logic
always_comb begin
    predict_taken = counter[1];  // Predict taken if MSB is 1
end

// Update logic
always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
        counter <= 2'b01;
    end
    else if (update_en) begin
        case (counter)
            2'b00: counter <= actual_taken ? 2'b01 : 2'b00;
            2'b01: counter <= actual_taken ? 2'b10 : 2'b00;
            2'b10: counter <= actual_taken ? 2'b11 : 2'b01;
            2'b11: counter <= actual_taken ? 2'b11 : 2'b10;
        endcase
    end
end

endmodule

