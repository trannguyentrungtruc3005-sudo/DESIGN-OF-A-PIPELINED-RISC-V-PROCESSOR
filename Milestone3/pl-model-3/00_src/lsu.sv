
`define MEMFILE "../02_test/isa_4b.hex"
`define MEMSIZE 65536
`define ADDRBIT 16

module lsu (
    input  logic        i_clk,          // Global clock
    input  logic        i_reset,        // Global active reset
    input  logic [31:0] i_lsu_addr,     // Address for data read/write
    input  logic [31:0] i_st_data,      // Data to be stored
    input  logic        i_lsu_wren,     // Write enable signal (1 if writing)
    output logic  [31:0] o_ld_data,      // Data read from memory

    // I/O
    output logic [31:0] o_io_ledr,      // Output for red LEDs
    output logic [31:0] o_io_ledg,      // Output for green LEDs
    output logic [6:0]  o_io_hex0,      // Output for 7-segment display 0
    output logic [6:0]  o_io_hex1,      // Output for 7-segment display 1
    output logic [6:0]  o_io_hex2,      // Output for 7-segment display 2
    output logic [6:0]  o_io_hex3,      // Output for 7-segment display 3
    output logic [6:0]  o_io_hex4,      // Output for 7-segment display 4
    output logic [6:0]  o_io_hex5,      // Output for 7-segment display 5
    output logic [6:0]  o_io_hex6,      // Output for 7-segment display 6
    output logic [6:0]  o_io_hex7,      // Output for 7-segment display 7
    output logic [31:0] o_io_lcd,       // Output for LCD register
    input  logic [31:0] i_io_sw,        // Input for switches

    input  logic [1:0]  i_lsu_op,       // 0x: word, 10: half, 11: byte
    input  logic        i_ld_un        // 0: signed, 1: unsigned

);

    logic [31:0] d_mem [`MEMSIZE/4-1:0];

    // Map 0000 - 7FFF Flash
    // Map 8000 - FFFF Sram

    logic [31:0] sw_buffer;
    logic [31:0] io_buffer[15:0];

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : loop
            initial begin
                io_buffer[i] = 32'b0;
            end    
        end
    endgenerate
        
    initial begin
        d_mem = '{default:'0};
    end    

    // ---- Helper cho RAM (xử lý misalign) ----
    logic [`ADDRBIT-3:0] addr;       // word index hiện tại
    logic [`ADDRBIT-3:0] next_addr;  // word kế tiếp (addr + 1 word)
    logic [31:0]         word1;      // d_mem[addr]
    logic [31:0]         word2;      // d_mem[next_addr]

    assign addr      = i_lsu_addr[`ADDRBIT-1:2];
    assign next_addr = addr + 1'b1;
 
    assign word1 = d_mem[addr];
    assign word2 = d_mem[next_addr];
    // -----------------------------------------

    /// IO mapping
    assign o_io_ledr = io_buffer[0];
    assign o_io_ledg = io_buffer[1];

    assign o_io_hex0 = io_buffer[2][6:0];
    assign o_io_hex1 = io_buffer[2][14:8];
    assign o_io_hex2 = io_buffer[2][22:16];
    assign o_io_hex3 = io_buffer[2][30:24];

    assign o_io_hex4 = io_buffer[3][6:0];
    assign o_io_hex5 = io_buffer[3][14:8];
    assign o_io_hex6 = io_buffer[3][22:16];
    assign o_io_hex7 = io_buffer[3][30:24];

    assign o_io_lcd  = io_buffer[4];
    
    assign sw_buffer = i_io_sw;

    initial begin
        $readmemh(`MEMFILE, d_mem);
        o_ld_data = 32'b0;
    end


    // LSU 
    always @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            o_ld_data <= 32'b0;
        end 
        else begin
            // =========================
            //           STORE
            // =========================
            if (i_lsu_wren) begin
                case (i_lsu_addr[31:16])
                    // ---------- IO WRITE ----------
                    16'h1000: begin
                        if (!i_lsu_op[1]) begin
                            // SW to IO
                            io_buffer[i_lsu_addr[15:12]] <= i_st_data;
                        end
                        else if (i_lsu_op[1] & ~i_lsu_op[0]) begin
                            // SH to IO
                            if (!i_lsu_addr[1])
                                io_buffer[i_lsu_addr[15:12]][15:0]  <= i_st_data[15:0];
                            else
                                io_buffer[i_lsu_addr[15:12]][31:16] <= i_st_data[15:0];
                        end
                        else if (i_lsu_op[1] & i_lsu_op[0]) begin
                            // SB to IO
                            case (i_lsu_addr[1:0])
                                2'b00: io_buffer[i_lsu_addr[15:12]][7:0]   <= i_st_data[7:0];
                                2'b01: io_buffer[i_lsu_addr[15:12]][15:8]  <= i_st_data[7:0];
                                2'b10: io_buffer[i_lsu_addr[15:12]][23:16] <= i_st_data[7:0];
                                2'b11: io_buffer[i_lsu_addr[15:12]][31:24] <= i_st_data[7:0];
                            endcase
                        end
                    end

                    // ---------- RAM WRITE (0000) + MISALIGN ----------
                    16'h0000: begin
                        // i_lsu_op:
                        // 0x: word
                        // 10: half
                        // 11: byte
                        if (!i_lsu_op[1]) begin
                            // -------- SW: STORE WORD (có MISALIGN) --------
                            case (i_lsu_addr[1:0])
                                2'b00: begin
                                    d_mem[addr] <= i_st_data;
                                end
                                2'b01: begin
                                    d_mem[addr][31:8]      <= i_st_data[23:0];
                                    d_mem[next_addr][7:0]  <= i_st_data[31:24];
                                end
                                2'b10: begin
                                    d_mem[addr][31:16]     <= i_st_data[15:0];
                                    d_mem[next_addr][15:0] <= i_st_data[31:16];
                                end
                                2'b11: begin
                                    d_mem[addr][31:24]     <= i_st_data[7:0];
                                    d_mem[next_addr][23:0] <= i_st_data[31:8];
                                end
                            endcase
                        end
                        else if (i_lsu_op[1] & ~i_lsu_op[0]) begin
                            // -------- SH: STORE HALFWORD (có MISALIGN) --------
                            case (i_lsu_addr[1:0])
                                2'b00: begin
                                    // ...00: byte0,1 trong cùng word
                                    d_mem[addr][15:0] <= i_st_data[15:0];
                                end
                                2'b01: begin
                                    // ...01: byte1,2 trong cùng word
                                    d_mem[addr][15:8]  <= i_st_data[7:0];
                                    d_mem[addr][23:16] <= i_st_data[15:8];
                                end
                                2'b10: begin
                                    // ...10: byte2,3 trong cùng word
                                    d_mem[addr][31:16] <= i_st_data[15:0];
                                end
                                2'b11: begin
                                    // ...11: byte3(word1) + byte0(word2)
                                    d_mem[addr][31:24]     <= i_st_data[7:0];
                                    d_mem[next_addr][7:0]  <= i_st_data[15:8];
                                end
                            endcase
                        end
                        else if (i_lsu_op[1] & i_lsu_op[0]) begin
                            // -------- SB: STORE BYTE --------
                            case (i_lsu_addr[1:0])
                                2'b00: d_mem[addr][7:0]   <= i_st_data[7:0];
                                2'b01: d_mem[addr][15:8]  <= i_st_data[7:0];
                                2'b10: d_mem[addr][23:16] <= i_st_data[7:0];
                                2'b11: d_mem[addr][31:24] <= i_st_data[7:0];
                            endcase
                        end
                    end

                    // ---------- Reserved / other regions ----------
                    default: ;
                endcase
            end
            // =========================
            //           LOAD
            // =========================
            else begin
                case (i_lsu_addr[31:16])
                    // ---------- IO READ ----------
                    16'h1000: begin
                        if (!i_lsu_op[1]) begin 
                            // LW from IO
                            o_ld_data <= io_buffer[i_lsu_addr[15:12]];
                        end
                        else if (i_lsu_op[1] & ~i_lsu_op[0]) begin
                            // LH/LHU from IO
                            if (!i_lsu_addr[1]) begin
                                o_ld_data[15:0]  <= io_buffer[i_lsu_addr[15:12]][15:0];
                                o_ld_data[31:16] <= {16{io_buffer[i_lsu_addr[15:12]][15] & ~i_ld_un}};
                            end
                            else begin
                                o_ld_data[15:0]  <= io_buffer[i_lsu_addr[15:12]][31:16];
                                o_ld_data[31:16] <= {16{io_buffer[i_lsu_addr[15:12]][31] & ~i_ld_un}};
                            end
                        end
                        else if (i_lsu_op[1] & i_lsu_op[0]) begin
                            // LB/LBU from IO
                            case (i_lsu_addr[1:0])
                                2'b00: begin
                                    o_ld_data[7:0]  <= io_buffer[i_lsu_addr[15:12]][7:0];
                                    o_ld_data[31:8] <= {24{io_buffer[i_lsu_addr[15:12]][7] & ~i_ld_un}};
                                end
                                2'b01: begin
                                    o_ld_data[7:0]  <= io_buffer[i_lsu_addr[15:12]][15:8];
                                    o_ld_data[31:8] <= {24{io_buffer[i_lsu_addr[15:12]][15] & ~i_ld_un}};
                                end
                                2'b10: begin
                                    o_ld_data[7:0]  <= io_buffer[i_lsu_addr[15:12]][23:16];
                                    o_ld_data[31:8] <= {24{io_buffer[i_lsu_addr[15:12]][23] & ~i_ld_un}};
                                end
                                2'b11: begin
                                    o_ld_data[7:0]  <= io_buffer[i_lsu_addr[15:12]][31:24];
                                    o_ld_data[31:8] <= {24{io_buffer[i_lsu_addr[15:12]][31] & ~i_ld_un}};
                                end
                            endcase
                        end
                    end
                    
                    // ---------- SWITCHES READ ----------
                    16'h1001: begin
                        if (!i_lsu_op[1]) begin 
                            o_ld_data <= sw_buffer;
                        end
                        else if (i_lsu_op[1] & ~i_lsu_op[0]) begin
                            if (!i_lsu_addr[1]) begin
                                o_ld_data[15:0]  <= sw_buffer[15:0];
                                o_ld_data[31:16] <= {16{sw_buffer[15] & ~i_ld_un}};
                            end
                            else begin
                                o_ld_data[15:0]  <= sw_buffer[31:16];
                                o_ld_data[31:16] <= {16{sw_buffer[31] & ~i_ld_un}};
                            end
                        end
                        else if (i_lsu_op[1] & i_lsu_op[0]) begin
                            case (i_lsu_addr[1:0])
                                2'b00: begin
                                    o_ld_data[7:0]  <= sw_buffer[7:0];
                                    o_ld_data[31:8] <= {24{sw_buffer[7] & ~i_ld_un}};
                                end
                                2'b01: begin
                                    o_ld_data[7:0]  <= sw_buffer[15:8];
                                    o_ld_data[31:8] <= {24{sw_buffer[15] & ~i_ld_un}};
                                end
                                2'b10: begin
                                    o_ld_data[7:0]  <= sw_buffer[23:16];
                                    o_ld_data[31:8] <= {24{sw_buffer[23] & ~i_ld_un}};
                                end
                                2'b11: begin
                                    o_ld_data[7:0]  <= sw_buffer[31:24];
                                    o_ld_data[31:8] <= {24{sw_buffer[31] & ~i_ld_un}};
                                end
                            endcase
                        end
                    end

                    // ---------- RAM READ (0000) + MISALIGN ----------
                    16'h0000: begin
                        if (!i_lsu_op[1]) begin
                            // -------- LW: LOAD WORD (có MISALIGN) --------
                            case (i_lsu_addr[1:0])
                                2'b00: o_ld_data <= word1;
                                2'b01: o_ld_data <= {word2[7:0],   word1[31:8]};
                                2'b10: o_ld_data <= {word2[15:0],  word1[31:16]};
                                2'b11: o_ld_data <= {word2[23:0],  word1[31:24]};
                            endcase
                        end
                        else if (i_lsu_op[1] & ~i_lsu_op[0]) begin
                            // -------- LH / LHU: LOAD HALFWORD (có MISALIGN) --------
                            case (i_lsu_addr[1:0])
                                2'b00: begin
                                    o_ld_data[15:0]  <= word1[15:0];
                                    o_ld_data[31:16] <= {16{word1[15] & ~i_ld_un}};
                                end
                                2'b01: begin
                                    o_ld_data[15:0]  <= word1[23:8];
                                    o_ld_data[31:16] <= {16{word1[23] & ~i_ld_un}};
                                end
                                2'b10: begin
                                    o_ld_data[15:0]  <= word1[31:16];
                                    o_ld_data[31:16] <= {16{word1[31] & ~i_ld_un}};
                                end
                                2'b11: begin
                                    // byte3(word1) + byte0(word2)
                                    o_ld_data[15:0]  <= {word2[7:0], word1[31:24]};
                                    o_ld_data[31:16] <= {16{word2[7] & ~i_ld_un}};
                                end
                            endcase
                        end
                        else begin
                            // -------- LB / LBU: LOAD BYTE --------
                            case (i_lsu_addr[1:0])
                                2'b00: begin
                                    o_ld_data[7:0]  <= word1[7:0];
                                    o_ld_data[31:8] <= {24{word1[7] & ~i_ld_un}};
                                end
                                2'b01: begin
                                    o_ld_data[7:0]  <= word1[15:8];
                                    o_ld_data[31:8] <= {24{word1[15] & ~i_ld_un}};
                                end
                                2'b10: begin
                                    o_ld_data[7:0]  <= word1[23:16];
                                    o_ld_data[31:8] <= {24{word1[23] & ~i_ld_un}};
                                end
                                2'b11: begin
                                    o_ld_data[7:0]  <= word1[31:24];
                                    o_ld_data[31:8] <= {24{word1[31] & ~i_ld_un}};
                                end
                            endcase
                        end
                    end
                    
                    // ---------- Reserved ----------
                    default: ;
                endcase
            end
        end
    end

endmodule
