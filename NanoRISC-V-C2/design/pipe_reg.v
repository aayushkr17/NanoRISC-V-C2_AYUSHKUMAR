// =============================================================================
// File: pipe_reg.v
// Module: pipe_reg
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Pipeline Register separating Stage 1 (Instruction Fetch) and
//              Stage 2 (Decode / Execute / Memory / Writeback). Supports
//              synchronous flush (on branch/jump redirect) and stall controls.
// =============================================================================

`timescale 1ns / 1ps

module pipe_reg (
    input  wire        clk,        // Clock
    input  wire        rst_n,      // Active-low asynchronous reset
    input  wire        flush,      // Flush pipeline register (insert bubble/NOP)
    input  wire        stall,      // Stall pipeline register (freeze contents)
    input  wire [31:0] pc_in,      // Program counter from Stage 1
    input  wire [31:0] instr_in,   // Instruction word from Stage 1
    input  wire        valid_in,   // Valid instruction flag from Stage 1
    output reg  [31:0] pc_out,     // Program counter to Stage 2
    output reg  [31:0] instr_out,  // Instruction word to Stage 2
    output reg         valid_out   // Valid instruction flag to Stage 2
);

    // RV32I NOP: addi x0, x0, 0
    localparam [31:0] NOP_INSTR = 32'h00000013;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out    <= 32'h00000000;
            instr_out <= NOP_INSTR;
            valid_out <= 1'b0;
        end else if (flush) begin
            // Insert bubble / flush on branch or jump taken
            pc_out    <= 32'h00000000;
            instr_out <= NOP_INSTR;
            valid_out <= 1'b0;
        end else if (!stall) begin
            pc_out    <= pc_in;
            instr_out <= instr_in;
            valid_out <= valid_in;
        end
        // If stall is active and no flush, retain current values
    end

endmodule
