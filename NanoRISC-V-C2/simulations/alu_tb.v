`timescale 1ns / 1ps

module alu_tb;

    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero;

    integer errors = 0;

    alu uut (
        .a(a),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .result(result),
        .zero(zero)
    );

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);

        $display("--------------------------------------------------");
        $display("Starting Testbench: alu_tb");
        $display("--------------------------------------------------");

        a = 32'd15; b = 32'd27; alu_ctrl = 4'b0000;
        #5;
        if (result !== 32'd42 || zero !== 1'b0) begin
            $display("[FAIL] ADD failed: expected 42, got %0d", result);
            errors = errors + 1;
        end else begin
            $display("[PASS] ADD (15 + 27 = %0d, zero = %b)", result, zero);
        end

        a = 32'd100; b = 32'd100; alu_ctrl = 4'b0001;
        #5;
        if (result !== 32'd0 || zero !== 1'b1) begin
            $display("[FAIL] SUB zero flag failed: result=%0d, zero=%b", result, zero);
            errors = errors + 1;
        end else begin
            $display("[PASS] SUB resulting in Zero (100 - 100 = %0d, zero = %b)", result, zero);
        end

        a = 32'd10; b = 32'd25; alu_ctrl = 4'b0001;
        #5;
        if ($signed(result) !== -15) begin
            $display("[FAIL] SUB negative failed: expected -15, got %0d", $signed(result));
            errors = errors + 1;
        end else begin
            $display("[PASS] SUB negative (10 - 25 = %0d)", $signed(result));
        end

        a = 32'd1; b = 32'd4; alu_ctrl = 4'b0010;
        #5;
        if (result !== 32'd16) begin
            $display("[FAIL] SLL failed: expected 16, got %0d", result);
            errors = errors + 1;
        end else begin
            $display("[PASS] SLL (1 << 4 = %0d)", result);
        end

        a = -32'd10; b = 32'd5; alu_ctrl = 4'b0011;
        #5;
        if (result !== 32'd1) begin
            $display("[FAIL] SLT failed: expected 1, got %0d", result);
            errors = errors + 1;
        end else begin
            $display("[PASS] SLT signed (-10 < 5 = %0d)", result);
        end

        a = 32'hFFFFFFFF; b = 32'd5; alu_ctrl = 4'b0100;
        #5;
        if (result !== 32'd0) begin
            $display("[FAIL] SLTU failed: expected 0, got %0d", result);
            errors = errors + 1;
        end else begin
            $display("[PASS] SLTU unsigned (0xFFFFFFFF < 5 = %0d)", result);
        end

        a = 32'hFF00FF00; b = 32'hF0F0F0F0; alu_ctrl = 4'b0101;
        #5;
        if (result !== 32'h0FF00FF0) begin
            $display("[FAIL] XOR failed: expected 0x0FF00FF0, got 0x%08h", result);
            errors = errors + 1;
        end else begin
            $display("[PASS] XOR verified: 0x%08h", result);
        end

        a = 32'h80000000; b = 32'd2; alu_ctrl = 4'b0110;
        #5;
        if (result !== 32'h20000000) begin
            $display("[FAIL] SRL failed: expected 0x20000000, got 0x%08h", result);
            errors = errors + 1;
        end else begin
            $display("[PASS] SRL logical right shift verified: 0x%08h", result);
        end
        
        a = 32'h80000000; b = 32'd2; alu_ctrl = 4'b0111;
        #5;
        if (result !== 32'hE0000000) begin
            $display("[FAIL] SRA failed: expected 0xE0000000, got 0x%08h", result);
            errors = errors + 1;
        end else begin
            $display("[PASS] SRA arithmetic right shift verified: 0x%08h", result);
        end

        a = 32'hAA550000; b = 32'h0000AA55; alu_ctrl = 4'b1000;
        #5;
        if (result !== 32'hAA55AA55) begin
            $display("[FAIL] OR failed: expected 0xAA55AA55, got 0x%08h", result);
            errors = errors + 1;
        end else begin
            $display("[PASS] OR verified: 0x%08h", result);
        end

        a = 32'hFFFF0000; b = 32'h00FFFF00; alu_ctrl = 4'b1001;
        #5;
        if (result !== 32'h00FF0000) begin
            $display("[FAIL] AND failed: expected 0x00FF0000, got 0x%08h", result);
            errors = errors + 1;
        end else begin
            $display("[PASS] AND verified: 0x%08h", result);
        end

        a = 32'h11223344; b = 32'h55667788; alu_ctrl = 4'b1010;
        #5;
        if (result !== 32'h55667788) begin
            $display("[FAIL] PASS_B failed: expected 0x55667788, got 0x%08h", result);
            errors = errors + 1;
        end else begin
            $display("[PASS] PASS_B verified: 0x%08h", result);
        end

        #10;
        $display("--------------------------------------------------");
        if (errors == 0)
            $display("TEST RESULT: ALL TESTS PASSED (alu)");
        else
            $display("TEST RESULT: %0d ERRORS ENCOUNTERED", errors);
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
