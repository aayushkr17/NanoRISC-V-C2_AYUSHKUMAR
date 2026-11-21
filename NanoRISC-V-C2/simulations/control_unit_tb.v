`timescale 1ns / 1ps

module control_unit_tb;

    reg  [6:0] opcode;
    reg  [2:0] funct3;
    reg  [6:0] funct7;
    wire       reg_write;
    wire       mem_read;
    wire       mem_write;
    wire [1:0] mem_to_reg;
    wire       alu_src_a;
    wire       alu_src_b;
    wire [3:0] alu_ctrl;
    wire       branch;
    wire       jump;
    wire       is_jalr;
    wire [2:0] imm_src;

    integer errors = 0;

    control_unit uut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .alu_ctrl(alu_ctrl),
        .branch(branch),
        .jump(jump),
        .is_jalr(is_jalr),
        .imm_src(imm_src)
    );

    initial begin
        $dumpfile("control_unit.vcd");
        $dumpvars(0, control_unit_tb);

        $display("--------------------------------------------------");
        $display("Starting Testbench: control_unit_tb");
        $display("--------------------------------------------------");

        opcode = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0000000;
        #5;
        if (reg_write !== 1'b1 || alu_ctrl !== 4'b0000 || alu_src_b !== 1'b0 || mem_to_reg !== 2'b00) begin
            $display("[FAIL] R-type ADD control decode failed");
            errors = errors + 1;
        end else begin
            $display("[PASS] R-type ADD decode verified");
        end

        opcode = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0100000;
        #5;
        if (reg_write !== 1'b1 || alu_ctrl !== 4'b0001) begin
            $display("[FAIL] R-type SUB control decode failed: alu_ctrl=%b", alu_ctrl);
            errors = errors + 1;
        end else begin
            $display("[PASS] R-type SUB decode verified");
        end

        opcode = 7'b0010011; funct3 = 3'b000; funct7 = 7'b0000000;
        #5;
        if (reg_write !== 1'b1 || alu_src_b !== 1'b1 || imm_src !== 3'b000 || alu_ctrl !== 4'b0000) begin
            $display("[FAIL] I-type ADDI control decode failed");
            errors = errors + 1;
        end else begin
            $display("[PASS] I-type ADDI decode verified");
        end
        opcode = 7'b0000011; funct3 = 3'b010; funct7 = 7'b0000000;
        #5;
        if (reg_write !== 1'b1 || mem_read !== 1'b1 || mem_to_reg !== 2'b01) begin
            $display("[FAIL] Load LW control decode failed");
            errors = errors + 1;
        end else begin
            $display("[PASS] Load LW decode verified");
        end
        opcode = 7'b0100011; funct3 = 3'b010; funct7 = 7'b0000000;
        #5;
        if (reg_write !== 1'b0 || mem_write !== 1'b1 || imm_src !== 3'b001) begin
            $display("[FAIL] Store SW control decode failed");
            errors = errors + 1;
        end else begin
            $display("[PASS] Store SW decode verified");
        end

        opcode = 7'b1100011; funct3 = 3'b000; funct7 = 7'b0000000;
        #5;
        if (branch !== 1'b1 || reg_write !== 1'b0 || imm_src !== 3'b010) begin
            $display("[FAIL] Branch BEQ control decode failed");
            errors = errors + 1;
        end else begin
            $display("[PASS] Branch BEQ decode verified");
        end
        opcode = 7'b1101111; funct3 = 3'b000; funct7 = 7'b0000000;
        #5;
        if (jump !== 1'b1 || is_jalr !== 1'b0 || mem_to_reg !== 2'b10 || reg_write !== 1'b1) begin
            $display("[FAIL] JAL control decode failed");
            errors = errors + 1;
        end else begin
            $display("[PASS] JAL decode verified");
        end
        opcode = 7'b1100111; funct3 = 3'b000; funct7 = 7'b0000000;
        #5;
        if (jump !== 1'b1 || is_jalr !== 1'b1 || mem_to_reg !== 2'b10 || reg_write !== 1'b1) begin
            $display("[FAIL] JALR control decode failed");
            errors = errors + 1;
        end else begin
            $display("[PASS] JALR decode verified");
        end

        opcode = 7'b0110111; funct3 = 3'b000; funct7 = 7'b0000000;
        #5;
        if (alu_ctrl !== 4'b1010 || reg_write !== 1'b1 || imm_src !== 3'b011) begin
            $display("[FAIL] LUI control decode failed");
            errors = errors + 1;
        end else begin
            $display("[PASS] LUI decode verified");
        end

        opcode = 7'b0010111; funct3 = 3'b000; funct7 = 7'b0000000;
        #5;
        if (alu_src_a !== 1'b1 || alu_src_b !== 1'b1 || reg_write !== 1'b1) begin
            $display("[FAIL] AUIPC control decode failed");
            errors = errors + 1;
        end else begin
            $display("[PASS] AUIPC decode verified");
        end

        #10;
        $display("--------------------------------------------------");
        if (errors == 0)
            $display("TEST RESULT: ALL TESTS PASSED (control_unit)");
        else
            $display("TEST RESULT: %0d ERRORS ENCOUNTERED", errors);
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
