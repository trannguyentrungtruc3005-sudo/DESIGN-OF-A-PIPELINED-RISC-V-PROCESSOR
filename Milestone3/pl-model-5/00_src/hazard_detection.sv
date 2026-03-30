module hazard_detection (
    input  logic        i_clk,
    input  logic        i_reset,

    // // From EX Stage
    input  logic [4:0]  ex_rs1_addr,        // RS1 register in ID stage
    input  logic [4:0]  ex_rs2_addr,        // RS2 register in ID stage
    // From EX Stage
    input  logic        ex_branch,     // Branch instruction in EX stage

    // From MEM Stage
    input  logic [4:0]  mem_rd_addr,
    input  logic        mem_is_load,
    input  logic        mem_rd_wren,


    // Control Signals
    output logic        pc_stall,      // Stall PC update
    output logic        if_id_stall,   // Stall IF/ID register
    output logic        id_ex_stall,   // Stall ID/EX register

    output logic        if_id_flush,   // Flush IF/ID register
    output logic        id_ex_flush,   // Flush ID/EX register
    output logic        ex_mem_flush   // Flush EX/MEM register
);

    // Load-use hazard detection
    logic load_use_hazard;
    assign load_use_hazard = (mem_rd_wren && mem_is_load && ((ex_rs1_addr == mem_rd_addr) || ((ex_rs2_addr == mem_rd_addr))) &&
                            (mem_rd_addr != 5'b0)); // x0 can't cause hazards


    // Branch hazard (control hazard)
    logic branch_hazard;
    // assign branch_hazard = ex_branch || mem_branch_taken;
    assign branch_hazard = ex_branch & ~load_use_hazard;

    // Stall signals
    assign pc_stall    = load_use_hazard;
    assign if_id_stall = load_use_hazard;
    assign id_ex_stall = load_use_hazard;

    // Flush signals
    assign id_ex_flush = branch_hazard;
    assign if_id_flush = branch_hazard;
    assign ex_mem_flush = load_use_hazard;


endmodule
