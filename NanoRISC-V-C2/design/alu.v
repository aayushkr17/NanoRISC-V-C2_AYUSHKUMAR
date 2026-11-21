// =============================================================================
// File: alu.v
// Module: alu
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Arithmetic Logic Unit for RV32I supporting all standard base
//              operations: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND,
//              and PASS_B. Produces zero flag for status/branching.
// =============================================================================

`timescale 1ns / 1ps

module alu (
    input  wire [31:0] a,         // Operand A
    input  wire [31:0] b,         // Operand B
    input  wire [3:0]  alu_ctrl,  // ALU Control selection
    output reg  [31:0] result,    // ALU Computation Result
    output wire        zero       // Zero flag: high when result == 0
);

    // ALU Operation encodings
    localparam ALU_ADD    = 4'b0000;
    localparam ALU_SUB    = 4'b0001;
    localparam ALU_SLL    = 4'b0010;
    localparam ALU_SLT    = 4'b0011;
    localparam ALU_SLTU   = 4'b0100;
    localparam ALU_XOR    = 4'b0101;
    localparam ALU_SRL    = 4'b0110;
    localparam ALU_SRA    = 4'b0111;
    localparam ALU_OR     = 4'b1000;
    localparam ALU_AND    = 4'b1001;
    localparam ALU_PASS_B = 4'b1010;

    always @(*) begin
        case (alu_ctrl)
            ALU_ADD:    result = a + b;
            ALU_SUB:    result = a - b;
            ALU_SLL:    result = a << b[4:0];
            ALU_SLT:    result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU:   result = (a < b) ? 32'd1 : 32'd0;
            ALU_XOR:    result = a ^ b;
            ALU_SRL:    result = a >> b[4:0];
            ALU_SRA:    result = $signed(a) >>> b[4:0];
            ALU_OR:     result = a | b;
            ALU_AND:    result = a & b;
            ALU_PASS_B: result = b;
            default:    result = 32'h00000000;
        endcase
    end

    assign zero = (result == 32'h00000000);

endmodule
