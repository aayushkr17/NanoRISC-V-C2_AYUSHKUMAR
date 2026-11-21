`timescale 1ns / 1ps

module imm_gen_tb;

    reg  [31:0] instr;
    reg  [2:0]  imm_src;
    wire [31:0] imm;

    integer errors = 0;

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

        instr   = 32'h02A00093;
        imm_src = 3'b000;
        #5;
        if (imm !== 32'd42) begin
            $display("[FAIL] I-type positive failed: expected 42, got %0d", imm);
            errors = errors + 1;
        end else begin
            $display("[PASS] I-type positive immediate verified: %0d", imm);
        end

        instr   = 32'hFFF00093;
        imm_src = 3'b000;
        #5;
        if (imm !== 32'hFFFFFFFF) begin
            $display("[FAIL] I-type negative failed: expected -1, got 0x%08h", imm);
            errors = errors + 1;
        end else begin
            $display("[PASS] I-type negative sign-extension verified: 0x%08h (-1)", imm);
        end
        instr   = 32'h0020A823;
        imm_src = 3'b001;
        #5;
        if (imm !== 32'd16) begin
            $display("[FAIL] S-type immediate failed: expected 16, got %0d", imm);
            errors = errors + 1;
        end else begin
            $display("[PASS] S-type immediate verified: %0d", imm);
        end

        instr   = 32'h00208863;
        imm_src = 3'b010;
        #5;
        if (imm !== 32'd16) begin
            $display("[FAIL] B-type positive branch offset failed: expected 16, got %0d", imm);
            errors = errors + 1;
        end else begin
            $display("[PASS] B-type positive branch offset verified: %0d", imm);
        end

        instr   = 32'hFE000EE3;
        imm_src = 3'b010;
        #5;
        if (imm !== 32'hFFFFFFFC) begin
            $display("[FAIL] B-type negative branch offset failed: expected -4, got %0d (0x%08h)", $signed(imm), imm);
            errors = errors + 1;
        end else begin
            $display("[PASS] B-type negative branch offset verified: %0d (0x%08h)", $signed(imm), imm);
        end

        instr   = 32'h123450B7;
        imm_src = 3'b011;
        #5;
        if (imm !== 32'h12345000) begin
            $display("[FAIL] U-type failed: expected 0x12345000, got 0x%08h", imm);
            errors = errors + 1;
        end else begin
            $display("[PASS] U-type upper immediate verified: 0x%08h", imm);
        end

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
