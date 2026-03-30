module alu(
    input  logic [31:0] i_op_a, i_op_b,
    input  logic [3:0]  i_alu_op,
    output logic [31:0] o_alu_data
);

    parameter ADD  = 4'b0000; // 0
    parameter SLL  = 4'b0001; // 1
    parameter SLT  = 4'b0010; // 2
    parameter SLTU = 4'b0011; // 3
    parameter XOR  = 4'b0100; // 4
    parameter SRL  = 4'b0101; // 5
    parameter OR   = 4'b0110; // 6
    parameter AND  = 4'b0111; // 7
    parameter SUB  = 4'b1000; // 8  
    parameter SRA  = 4'b1101; // 13 
    parameter LUI  = 4'b1111; // 15 

    // --- ADD/SUB Logic ---
    logic [31:0] add_result, sub_result;
    logic tmp0, tmp1;

    // Phép Cộng
    add_sub uut1(
        .x(i_op_a), 
        .y(i_op_b),
        .c_in(1'b0),
        .s(add_result),
        .c_out(tmp0)
    );
        
    // Phép Trừ 
    add_sub uut2(
        .x(i_op_a),
        .y(i_op_b),
        .c_in(1'b1),
        .s(sub_result),
        .c_out(tmp1)
    );

    // --- LUI Logic ---
    logic [31:0] lui_result;
    logic tmp5;
    add_sub uut3(
        .x(32'h0000_0000), 
        .y(i_op_b), 
        .c_in(1'b0), 
        .s(lui_result), 
        .c_out(tmp5)
    );
                    
    // --- SLT Logic ---
    logic [31:0] slt_result;
    logic slt_bit;
    // So sánh có dấu: Nếu cùng dấu, kết quả là bit dấu của phép trừ. Nếu khác dấu, số dương lớn hơn.
    assign slt_bit = sub_result[31] ^ ((i_op_a[31] ^ i_op_b[31]) & (sub_result[31] ^ i_op_a[31]));
    assign slt_result = {31'b0, slt_bit};
     
    // --- SLTU Logic ---
    logic [31:0] sltu_result;
    // So sánh không dấu dựa vào Carry out (mượn) của phép trừ
    assign sltu_result = {31'b0, ~tmp1}; 

    // --- Shift Functions ---
    // SRA (Shift Right Arithmetic)
    function logic [31:0] sra_fc;
        input logic [31:0] r1;
        input logic [4:0] r2;
        logic [31:0] tmp0, tmp1, tmp2, tmp3, tmp4;
        begin
            tmp0 = (r2[0]) ? {r1[31], r1[31:1]} : r1;
            tmp1 = (r2[1]) ? {{2{tmp0[31]}}, tmp0[31:2]} : tmp0;
            tmp2 = (r2[2]) ? {{4{tmp0[31]}}, tmp1[31:4]} : tmp1;
            tmp3 = (r2[3]) ? {{8{tmp0[31]}}, tmp2[31:8]} : tmp2;
            sra_fc = (r2[4]) ? {{16{tmp0[31]}}, tmp3[31:16]} : tmp3;
        end
    endfunction
    
    // SLL (Shift Left Logical)
    function logic [31:0] sll_fc;
        input logic [31:0] x;
        input logic [4:0] shamt;
        logic [31:0] stage [0:5]; 
        begin
            stage[0] = x;
            stage[1] = shamt[0] ? {stage[0][30:0], 1'b0} : stage[0];
            stage[2] = shamt[1] ? {stage[1][29:0], 2'b00} : stage[1];
            stage[3] = shamt[2] ? {stage[2][27:0], {4{1'b0}}} : stage[2];
            stage[4] = shamt[3] ? {stage[3][23:0], {8{1'b0}}} : stage[3];
            stage[5] = shamt[4] ? {stage[4][15:0], {16{1'b0}}} : stage[4];        
            sll_fc = stage[5];
        end
    endfunction

    // SRL (Shift Right Logical)
    function logic [31:0] srl_fc;
        input logic [31:0] x;
        input logic [4:0] shamt;    
        logic [31:0] stage [0:5]; 
        begin
            stage[0] = x;
            stage[1] = shamt[0] ? {1'b0, stage[0][31:1]} : stage[0];
            stage[2] = shamt[1] ? {2'b00, stage[1][31:2]} : stage[1];
            stage[3] = shamt[2] ? {{4{1'b0}}, stage[2][31:4]} : stage[2];
            stage[4] = shamt[3] ? {{8{1'b0}}, stage[3][31:8]} : stage[3];
            stage[5] = shamt[4] ? {{16{1'b0}}, stage[4][31:16]} : stage[4];    
            srl_fc = stage[5];
        end
    endfunction 
                    
    // --- Output MUX ---
    always_comb begin
        case(i_alu_op)
            ADD:     o_alu_data = add_result;
            SUB:     o_alu_data = sub_result;
            XOR:     o_alu_data = i_op_a ^ i_op_b;
            OR:      o_alu_data = i_op_a | i_op_b;
            AND:     o_alu_data = i_op_a & i_op_b;
            SLT:     o_alu_data = slt_result;
            SLTU:    o_alu_data = sltu_result;
            SRA:     o_alu_data = sra_fc(i_op_a, i_op_b[4:0]);
            SRL:     o_alu_data = srl_fc(i_op_a, i_op_b[4:0]);
            SLL:     o_alu_data = sll_fc(i_op_a, i_op_b[4:0]);
            LUI:     o_alu_data = lui_result;
            default: o_alu_data = 32'h0;
        endcase 
    end
            
endmodule