// =============================================================================
// File: instruction_memory_tb.v
// Module: instruction_memory_tb
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Dedicated testbench for instruction_memory module with GTKWave
//              VCD waveform dump support.
// =============================================================================

`timescale 1ns / 1ps

module instruction_memory_tb;

    reg  [31:0] addr;
    wire [31:0] instr;

    integer errors = 0;

    // Instantiate UUT
    instruction_memory #(
        .MEM_DEPTH(64)
    ) uut (
        .addr(addr),
        .instr(instr)
    );

    initial begin
        // Waveform generation for GTKWave
        $dumpfile("instruction_memory.vcd");
        $dumpvars(0, instruction_memory_tb);

        $display("--------------------------------------------------");
        $display("Starting Testbench: instruction_memory_tb");
        $display("--------------------------------------------------");

        // Preload sample test instructions into UUT memory
        uut.mem[0] = 32'h00A00093; // addi x1, x0, 10
        uut.mem[1] = 32'h01400113; // addi x2, x0, 20
        uut.mem[2] = 32'h002081B3; // add  x3, x1, x2
        uut.mem[3] = 32'h40110233; // sub  x4, x2, x1

        #10;
        // Test word 0 at byte address 0x00000000
        addr = 32'h00000000;
        #5;
        if (instr !== 32'h00A00093) begin
            $display("[FAIL] Addr 0x00: Expected 0x00A00093, got 0x%08h", instr);
            errors = errors + 1;
        end else begin
            $display("[PASS] Addr 0x00: Correctly fetched 0x%08h", instr);
        end

        // Test word 1 at byte address 0x00000004
        addr = 32'h00000004;
        #5;
        if (instr !== 32'h01400113) begin
            $display("[FAIL] Addr 0x04: Expected 0x01400113, got 0x%08h", instr);
            errors = errors + 1;
        end else begin
            $display("[PASS] Addr 0x04: Correctly fetched 0x%08h", instr);
        end

        // Test word 2 at byte address 0x00000008
        addr = 32'h00000008;
        #5;
        if (instr !== 32'h002081B3) begin
            $display("[FAIL] Addr 0x08: Expected 0x002081B3, got 0x%08h", instr);
            errors = errors + 1;
        end else begin
            $display("[PASS] Addr 0x08: Correctly fetched 0x%08h", instr);
        end

        // Test word 3 at byte address 0x0000000C
        addr = 32'h0000000C;
        #5;
        if (instr !== 32'h40110233) begin
            $display("[FAIL] Addr 0x0C: Expected 0x40110233, got 0x%08h", instr);
            errors = errors + 1;
        end else begin
            $display("[PASS] Addr 0x0C: Correctly fetched 0x%08h", instr);
        end

        // Test uninitialized location (should return NOP 0x00000013)
        addr = 32'h00000020;
        #5;
        if (instr !== 32'h00000013) begin
            $display("[FAIL] Addr 0x20: Expected NOP 0x00000013, got 0x%08h", instr);
            errors = errors + 1;
        end else begin
            $display("[PASS] Addr 0x20 (default): Correctly fetched NOP 0x%08h", instr);
        end

        // Test out-of-bounds address (should return NOP 0x00000013)
        addr = 32'h00001000;
        #5;
        if (instr !== 32'h00000013) begin
            $display("[FAIL] Addr 0x1000 (out-of-bounds): Expected NOP, got 0x%08h", instr);
            errors = errors + 1;
        end else begin
            $display("[PASS] Addr 0x1000 (out-of-bounds): Correctly returned NOP 0x%08h", instr);
        end

        #10;
        $display("--------------------------------------------------");
        if (errors == 0)
            $display("TEST RESULT: ALL TESTS PASSED (instruction_memory)");
        else
            $display("TEST RESULT: %0d ERRORS ENCOUNTERED", errors);
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
