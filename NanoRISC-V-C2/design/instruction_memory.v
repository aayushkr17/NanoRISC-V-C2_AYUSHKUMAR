// =============================================================================
// File: instruction_memory.v
// Module: instruction_memory
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Pure Verilog Instruction Memory for Stage 1 (Fetch).
//              Word-aligned asynchronous read addressing. Uninitialized
//              or out-of-bounds locations default to RV32I NOP (addi x0, x0, 0).
// =============================================================================

`timescale 1ns / 1ps

module instruction_memory #(
    parameter MEM_DEPTH = 1024 // Depth in 32-bit words (1024 words = 4096 bytes)
)(
    input  wire [31:0] addr,   // Byte address from Program Counter
    output wire [31:0] instr   // 32-bit fetched instruction word
);

    // Memory array
    reg [31:0] mem [0:MEM_DEPTH-1];

    // Word address: addr[31:2]
    wire [29:0] word_addr = addr[31:2];

    // Combinational read: returns memory contents or NOP if out of bounds
    assign instr = (word_addr < MEM_DEPTH) ? mem[word_addr] : 32'h00000013;

    integer i;
    initial begin
        // Initialize entire instruction memory to NOP (addi x0, x0, 0 = 32'h00000013)
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem[i] = 32'h00000013;
        end
    end

endmodule
