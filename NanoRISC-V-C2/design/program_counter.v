// =============================================================================
// File: program_counter.v
// Module: program_counter
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Program Counter register with synchronous write and active-low
//              asynchronous reset.
// =============================================================================

`timescale 1ns / 1ps

module program_counter (
    input  wire        clk,       // Clock signal
    input  wire        rst_n,     // Active-low asynchronous reset
    input  wire        pc_write,  // Program counter write enable (stall control)
    input  wire [31:0] pc_next,   // Next program counter value
    output reg  [31:0] pc         // Current program counter value
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'h00000000;
        end else if (pc_write) begin
            pc <= pc_next;
        end
    end

endmodule
