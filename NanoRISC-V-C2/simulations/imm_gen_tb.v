// =============================================================================
// File: imm_gen_tb.v
// Module: imm_gen_tb
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Dedicated testbench for imm_gen module with GTKWave VCD waveform
//              dump support and automated assertions.
// =============================================================================

`timescale 1ns / 1ps

module imm_gen_tb;

    reg  [31:0] instr;
    reg  [2:0]  imm_src;
    wire [31:0] imm;

    integer errors = 0;

    // Instantiate UUT
    imm_gen uut (
        .instr(instr),
        .imm_src(imm_src),
        .imm(imm)
    );

    initial begin
        $dumpfile("imm_gen.vcd");
        $dumpvars(0, imm_gen_tb);

        $display("--------------------------------------------------");
        $display("Starting Testbench: imm_gen_tb");
        $display("--------------------------------------------------");

        // Test 1: I-type positive immediate (addi x1, x0, 42) -> imm = 42
        // imm[11:0] = 12'd42 = 0x02A -> instr[31:20] = 12'h02A
        instr   = 32'h02A00093;
        imm_src = 3'b000;
        #5;
        if (imm !== 32'd42) begin
            $display("[FAIL] I-type positive failed: expected 42, got %0d", imm);
            errors = errors + 1;
        end else begin
            $display("[PASS] I-type positive immediate verified: %0d", imm);
        end

        // Test 2: I-type negative immediate (addi x1, x0, -1) -> imm = -1 = 0xFFFFFFFF
        // instr[31:20] = 12'hFFF
        instr   = 32'hFFF00093;
        imm_src = 3'b000;
        #5;
        if (imm !== 32'hFFFFFFFF) begin
            $display("[FAIL] I-type negative failed: expected -1, got 0x%08h", imm);
            errors = errors + 1;
        end else begin
            $display("[PASS] I-type negative sign-extension verified: 0x%08h (-1)", imm);
        end

        // Test 3: S-type immediate (sw x2, 16(x1)) -> imm = 16
        // imm[11:5] = 0, imm[4:0] = 5'd16 = 5'b10000 -> instr[11:7] = 5'b10000
        instr   = 32'h0020A823;
        imm_src = 3'b001;
        #5;
        if (imm !== 32'd16) begin
            $display("[FAIL] S-type immediate failed: expected 16, got %0d", imm);
            errors = errors + 1;
        end else begin
            $display("[PASS] S-type immediate verified: %0d", imm);
        end

        // Test 4: B-type immediate (beq x1, x2, 16) -> offset +16
        // bit 12=0, bit 11=0, bits 10:5=0, bits 4:1=4'b1000, bit 0=0 -> imm = 16 (0x00000010)
        // instr[31]=0, instr[7]=0, instr[30:25]=6'b000000, instr[11:8]=4'b1000
        instr   = 32'h00208863;
        imm_src = 3'b010;
        #5;
        if (imm !== 32'd16) begin
            $display("[FAIL] B-type positive branch offset failed: expected 16, got %0d", imm);
            errors = errors + 1;
        end else begin
            $display("[PASS] B-type positive branch offset verified: %0d", imm);
        end

        // Test 5: B-type negative branch offset (beq x0, x0, -4) -> imm = -4 (32'hFFFFFFFC)
        // -4 in 13-bit 2's complement = 13'h1FFC = 13'b1_1111_1111_1100
        // bit 12=1, bit 11=1, bits 10:5=6'b111111, bits 4:1=4'b1110, bit 0=0
        // instr[31]=1, instr[7]=1, instr[30:25]=6'b111111, instr[11:8]=4'b1110
        instr   = 32'hFE000EE3;
        imm_src = 3'b010;
        #5;
        if (imm !== 32'hFFFFFFFC) begin
            $display("[FAIL] B-type negative branch offset failed: expected -4, got %0d (0x%08h)", $signed(imm), imm);
            errors = errors + 1;
        end else begin
            $display("[PASS] B-type negative branch offset verified: %0d (0x%08h)", $signed(imm), imm);
        end

        // Test 6: U-type immediate (lui x1, 0x12345) -> imm = 0x12345000
        instr   = 32'h123450B7;
        imm_src = 3'b011;
        #5;
        if (imm !== 32'h12345000) begin
            $display("[FAIL] U-type failed: expected 0x12345000, got 0x%08h", imm);
            errors = errors + 1;
        end else begin
            $display("[PASS] U-type upper immediate verified: 0x%08h", imm);
        end

        // Test 7: J-type immediate (jal x1, 2048) -> offset = 2048 = 0x00000800
        // 2048 = 21'b0_00000001_0_0000000000_0
        // bit 20=0, bits 19:12=8'h01, bit 11=0, bits 10:1=10'h000, bit 0=0
        instr   = 32'h001000EF;
        imm_src = 3'b100;
        #5;
        if (imm !== 32'd2048) begin
            $display("[FAIL] J-type positive jump offset failed: expected 2048, got %0d", imm);
            errors = errors + 1;
        end else begin
            $display("[PASS] J-type positive jump offset verified: %0d", imm);
        end

        #10;
        $display("--------------------------------------------------");
        if (errors == 0)
            $display("TEST RESULT: ALL TESTS PASSED (imm_gen)");
        else
            $display("TEST RESULT: %0d ERRORS ENCOUNTERED", errors);
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
