module hazard_detection (
    input  logic        i_clk,
    input  logic        i_reset,
    // From ID Stage
    input  logic [4:0]  id_rs1_addr,        // RS1 register in ID stage
    input  logic [4:0]  id_rs2_addr,        // RS2 register in ID stage
    // From EX Stage
    input  logic [4:0]  ex_rd_addr,         // Destination register in EX stage
    input  logic        ex_is_load,         // Load instruction in EX stage
    input  logic        ex_branch,          // Branch instruction in EX stage

    // From MEM Stage
    input  logic [4:0]  mem_rd_addr,
    input  logic        mem_is_load,
    input  logic        mem_branch_taken,   // Branch resolved in MEM stage

    // From WB Stage
    input  logic [4:0]  wb_rd_addr,
    input  logic        wb_is_load,

    input  logic        id_I_type,

    // Control Signals
    output logic       pc_stall,      // Stall PC update
    output logic       if_id_stall,   // Stall IF/ID register
    output logic       id_ex_stall,   // Stall ID/EX register

    output logic       if_id_flush,   // Flush IF/ID register
    output logic       id_ex_flush,   // Flush ID/EX register
    output logic       ex_mem_flush   // Flush EX/MEM register
);


    logic data_hazard;
    // Load-use hazard detection
    logic load_use_hazard;
    assign load_use_hazard = ex_is_load && ((id_rs1_addr == ex_rd_addr) || (~id_I_type && (id_rs2_addr == ex_rd_addr))) &&
                            (ex_rd_addr != 5'b0); // x0 can't cause hazards

    logic mem_data_hazard;
    assign mem_data_hazard = mem_is_load && ((id_rs1_addr == mem_rd_addr) || (~id_I_type && (id_rs2_addr == mem_rd_addr))) &&
                            (mem_rd_addr != 5'b0); // x0 can't cause hazards

    logic wb_data_hazard;
    assign wb_data_hazard = wb_is_load && ((id_rs1_addr == wb_rd_addr) || (~id_I_type && (id_rs2_addr == wb_rd_addr))) &&
                            (wb_rd_addr != 5'b0); // x0 can't cause hazards

    assign data_hazard = (load_use_hazard || mem_data_hazard || wb_data_hazard);

    // Branch hazard (control hazard)
    logic branch_hazard;

    assign branch_hazard = ex_branch;

    // Stall signals
    assign pc_stall    = data_hazard;
    assign if_id_stall = data_hazard;
    assign id_ex_stall = 0;

    // Flush signals
    assign id_ex_flush = data_hazard | branch_hazard;
    assign if_id_flush = branch_hazard;
    assign ex_mem_flush = 0;


endmodule
