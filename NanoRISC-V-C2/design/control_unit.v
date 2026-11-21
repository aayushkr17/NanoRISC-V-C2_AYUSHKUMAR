// =============================================================================
// File: control_unit.v
// Module: control_unit
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Main Control Unit and ALU Decoder for base RV32I ISA.
//              Generates control signals for pipeline datapath, memory access,
//              register writeback, ALU operations, and branch/jump redirection.
// =============================================================================

`timescale 1ns / 1ps

module control_unit (
    input  wire [6:0] opcode,      // Instruction opcode [6:0]
    input  wire [2:0] funct3,      // Instruction funct3 [14:12]
    input  wire [6:0] funct7,      // Instruction funct7 [31:25]
    output reg        reg_write,   // Register file write enable
    output reg        mem_read,    // Data memory read enable
    output reg        mem_write,   // Data memory write enable
    output reg  [1:0] mem_to_reg,  // Writeback source: 00=ALU, 01=MEM, 10=PC+4
    output reg        alu_src_a,   // ALU operand A: 0=rs1, 1=PC
    output reg        alu_src_b,   // ALU operand B: 0=rs2, 1=Immediate
    output reg  [3:0] alu_ctrl,    // ALU operation control
    output reg        branch,      // Conditional branch flag
    output reg        jump,        // Unconditional jump flag
    output reg        is_jalr,     // JALR instruction flag
    output reg  [2:0] imm_src      // Immediate generator selector
);

    // RV32I Opcode Definitions
    localparam OPC_R_TYPE   = 7'b0110011; // R-type: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
    localparam OPC_I_ARITH  = 7'b0010011; // I-type ALU: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
    localparam OPC_LOAD     = 7'b0000011; // Load: LB, LH, LW, LBU, LHU
    localparam OPC_STORE    = 7'b0100011; // Store: SB, SH, SW
    localparam OPC_BRANCH   = 7'b1100011; // Branch: BEQ, BNE, BLT, BGE, BLTU, BGEU
    localparam OPC_JAL      = 7'b1101111; // JAL: Jump and Link
    localparam OPC_JALR     = 7'b1100111; // JALR: Jump and Link Register
    localparam OPC_LUI      = 7'b0110111; // LUI: Load Upper Immediate
    localparam OPC_AUIPC    = 7'b0010111; // AUIPC: Add Upper Immediate to PC
    localparam OPC_SYSTEM   = 7'b1110011; // SYSTEM: ECALL, EBREAK
    localparam OPC_FENCE    = 7'b0001111; // FENCE

    // ALU Operation Constants
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

    // Immediate format selectors
    localparam IMM_I = 3'b000;
    localparam IMM_S = 3'b001;
    localparam IMM_B = 3'b010;
    localparam IMM_U = 3'b011;
    localparam IMM_J = 3'b100;

    always @(*) begin
        // Default safe values (NOP)
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 2'b00;
        alu_src_a  = 1'b0;
        alu_src_b  = 1'b0;
        alu_ctrl   = ALU_ADD;
        branch     = 1'b0;
        jump       = 1'b0;
        is_jalr    = 1'b0;
        imm_src    = IMM_I;

        case (opcode)
            OPC_R_TYPE: begin
                reg_write  = 1'b1;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 2'b00; // ALU result
                alu_src_a  = 1'b0;  // rs1
                alu_src_b  = 1'b0;  // rs2
                case (funct3)
                    3'b000: alu_ctrl = (funct7[5]) ? ALU_SUB : ALU_ADD; // ADD / SUB
                    3'b001: alu_ctrl = ALU_SLL;                         // SLL
                    3'b010: alu_ctrl = ALU_SLT;                         // SLT
                    3'b011: alu_ctrl = ALU_SLTU;                        // SLTU
                    3'b100: alu_ctrl = ALU_XOR;                         // XOR
                    3'b101: alu_ctrl = (funct7[5]) ? ALU_SRA : ALU_SRL; // SRL / SRA
                    3'b110: alu_ctrl = ALU_OR;                          // OR
                    3'b111: alu_ctrl = ALU_AND;                         // AND
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            OPC_I_ARITH: begin
                reg_write  = 1'b1;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 2'b00; // ALU result
                alu_src_a  = 1'b0;  // rs1
                alu_src_b  = 1'b1;  // Immediate
                imm_src    = IMM_I;
                case (funct3)
                    3'b000: alu_ctrl = ALU_ADD;                         // ADDI
                    3'b001: alu_ctrl = ALU_SLL;                         // SLLI
                    3'b010: alu_ctrl = ALU_SLT;                         // SLTI
                    3'b011: alu_ctrl = ALU_SLTU;                        // SLTIU
                    3'b100: alu_ctrl = ALU_XOR;                         // XORI
                    3'b101: alu_ctrl = (funct7[5]) ? ALU_SRA : ALU_SRL; // SRLI / SRAI
                    3'b110: alu_ctrl = ALU_OR;                          // ORI
                    3'b111: alu_ctrl = ALU_AND;                         // ANDI
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            OPC_LOAD: begin
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                mem_write  = 1'b0;
                mem_to_reg = 2'b01; // Data Memory read data
                alu_src_a  = 1'b0;  // rs1
                alu_src_b  = 1'b1;  // Immediate
                imm_src    = IMM_I;
                alu_ctrl   = ALU_ADD; // Address calculation rs1 + imm
            end

            OPC_STORE: begin
                reg_write  = 1'b0;
                mem_read   = 1'b0;
                mem_write  = 1'b1;
                alu_src_a  = 1'b0;  // rs1
                alu_src_b  = 1'b1;  // Immediate
                imm_src    = IMM_S;
                alu_ctrl   = ALU_ADD; // Address calculation rs1 + imm
            end

            OPC_BRANCH: begin
                reg_write  = 1'b0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                alu_src_a  = 1'b0;  // rs1
                alu_src_b  = 1'b0;  // rs2
                imm_src    = IMM_B;
                alu_ctrl   = ALU_SUB;
                branch     = 1'b1;
            end

            OPC_JAL: begin
                reg_write  = 1'b1;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 2'b10; // PC + 4 to rd
                alu_src_a  = 1'b1;  // PC
                alu_src_b  = 1'b1;  // Immediate
                imm_src    = IMM_J;
                alu_ctrl   = ALU_ADD;
                jump       = 1'b1;
                is_jalr    = 1'b0;
            end

            OPC_JALR: begin
                reg_write  = 1'b1;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 2'b10; // PC + 4 to rd
                alu_src_a  = 1'b0;  // rs1
                alu_src_b  = 1'b1;  // Immediate
                imm_src    = IMM_I;
                alu_ctrl   = ALU_ADD;
                jump       = 1'b1;
                is_jalr    = 1'b1;
            end

            OPC_LUI: begin
                reg_write  = 1'b1;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 2'b00; // ALU result
                alu_src_a  = 1'b0;  // Don't care
                alu_src_b  = 1'b1;  // Immediate
                imm_src    = IMM_U;
                alu_ctrl   = ALU_PASS_B;
            end

            OPC_AUIPC: begin
                reg_write  = 1'b1;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 2'b00; // ALU result
                alu_src_a  = 1'b1;  // PC
                alu_src_b  = 1'b1;  // Immediate
                imm_src    = IMM_U;
                alu_ctrl   = ALU_ADD;
            end

            OPC_SYSTEM, OPC_FENCE: begin
                // System instructions (ECALL/EBREAK) and FENCE act as NOP
                reg_write  = 1'b0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 2'b00;
                alu_src_a  = 1'b0;
                alu_src_b  = 1'b0;
                alu_ctrl   = ALU_ADD;
                branch     = 1'b0;
                jump       = 1'b0;
                is_jalr    = 1'b0;
                imm_src    = IMM_I;
            end

            default: begin
                reg_write  = 1'b0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 2'b00;
                alu_src_a  = 1'b0;
                alu_src_b  = 1'b0;
                alu_ctrl   = ALU_ADD;
                branch     = 1'b0;
                jump       = 1'b0;
                is_jalr    = 1'b0;
                imm_src    = IMM_I;
            end
        endcase
    end

endmodule
