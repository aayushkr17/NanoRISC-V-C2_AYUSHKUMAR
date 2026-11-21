// =============================================================================
// File: imm_gen.v
// Module: imm_gen
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Immediate Generator for RV32I base integer instruction formats:
//              - I-type (ALU immediate, Load, JALR)
//              - S-type (Store)
//              - B-type (Branch conditional)
//              - U-type (LUI, AUIPC)
//              - J-type (JAL unconditional jump)
// =============================================================================

`timescale 1ns / 1ps

module imm_gen (
    input  wire [31:0] instr,    // 32-bit instruction word
    input  wire [2:0]  imm_src,  // Control selector for immediate format
    output reg  [31:0] imm       // 32-bit sign-extended immediate
);

    // Immediate format selectors
    localparam IMM_I = 3'b000;
    localparam IMM_S = 3'b001;
    localparam IMM_B = 3'b010;
    localparam IMM_U = 3'b011;
    localparam IMM_J = 3'b100;

    always @(*) begin
        case (imm_src)
            IMM_I: imm = {{20{instr[31]}}, instr[31:20]};
            IMM_S: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            IMM_B: imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            IMM_U: imm = {instr[31:12], 12'b0};
            IMM_J: imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            default: imm = 32'h00000000;
        endcase
    end

endmodule
