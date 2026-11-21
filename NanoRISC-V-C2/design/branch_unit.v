// =============================================================================
// File: branch_unit.v
// Module: branch_unit
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Branch evaluation and jump target calculation unit. Supports all
//              six RV32I branch comparisons (BEQ, BNE, BLT, BGE, BLTU, BGEU)
//              and unconditional jumps (JAL, JALR with LSB clearing).
// =============================================================================

`timescale 1ns / 1ps

module branch_unit (
    input  wire        branch,     // Branch instruction enable
    input  wire        jump,       // Unconditional jump enable (JAL/JALR)
    input  wire        is_jalr,    // 1 for JALR, 0 for JAL / Branch
    input  wire [2:0]  funct3,     // Branch condition type [14:12]
    input  wire [31:0] rdata1,     // Register source 1 (rs1)
    input  wire [31:0] rdata2,     // Register source 2 (rs2)
    input  wire [31:0] pc,         // Program Counter of current instruction
    input  wire [31:0] imm,        // Immediate offset
    output wire        pc_sel,     // 1: Redirect PC to target, 0: Sequential PC+4
    output wire [31:0] pc_target   // Redirected PC target address
);

    reg condition_met;

    always @(*) begin
        case (funct3)
            3'b000: condition_met = (rdata1 == rdata2);                           // BEQ
            3'b001: condition_met = (rdata1 != rdata2);                           // BNE
            3'b100: condition_met = ($signed(rdata1) < $signed(rdata2));         // BLT
            3'b101: condition_met = ($signed(rdata1) >= $signed(rdata2));        // BGE
            3'b110: condition_met = (rdata1 < rdata2);                           // BLTU
            3'b111: condition_met = (rdata1 >= rdata2);                          // BGEU
            default: condition_met = 1'b0;
        endcase
    end

    // Assert pc_sel if an unconditional jump is taken or a conditional branch evaluates true
    assign pc_sel = jump | (branch & condition_met);

    // Target calculation:
    // JALR: (rs1 + imm) & ~1 (LSB cleared to zero as required by RV32I spec)
    // JAL / Branch: pc + imm
    wire [31:0] jalr_target       = (rdata1 + imm) & 32'hFFFFFFFE;
    wire [31:0] branch_jal_target = pc + imm;

    assign pc_target = is_jalr ? jalr_target : branch_jal_target;

endmodule
