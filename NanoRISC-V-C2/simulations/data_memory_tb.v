// =============================================================================
// File: data_memory_tb.v
// Module: data_memory_tb
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Dedicated testbench for data_memory module testing all RV32I
//              load/store combinations (LB, LH, LW, LBU, LHU, SB, SH, SW)
//              with GTKWave VCD waveform dump support.
// =============================================================================

`timescale 1ns / 1ps

module data_memory_tb;

    reg         clk;
    reg         rst_n;
    reg         mem_read;
    reg         mem_write;
    reg  [2:0]  funct3;
    reg  [31:0] addr;
    reg  [31:0] wdata;
    wire [31:0] rdata;

    integer errors = 0;

    // Instantiate UUT
    data_memory #(
        .MEM_DEPTH(64)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .funct3(funct3),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata)
    );

    // Clock generator (50 MHz)
    always #10 clk = ~clk;

    initial begin
        $dumpfile("data_memory.vcd");
        $dumpvars(0, data_memory_tb);

        $display("--------------------------------------------------");
        $display("Starting Testbench: data_memory_tb");
        $display("--------------------------------------------------");

        clk       = 0;
        rst_n     = 0;
        mem_read  = 0;
        mem_write = 0;
        funct3    = 3'b010;
        addr      = 0;
        wdata     = 0;

        #25;
        rst_n = 1;
        #5;

        // Test 1: Store Word (SW) and Load Word (LW)
        @(negedge clk);
        mem_write = 1;
        funct3    = 3'b010; // SW
        addr      = 32'h00000008;
        wdata     = 32'h12345678;
        @(posedge clk);
        #1;
        mem_write = 0;

        // Read back with LW
        mem_read = 1;
        funct3   = 3'b010; // LW
        addr     = 32'h00000008;
        #5;
        if (rdata !== 32'h12345678) begin
            $display("[FAIL] SW/LW failed: expected 0x12345678, got 0x%08h", rdata);
            errors = errors + 1;
        end else begin
            $display("[PASS] SW and LW verified: 0x%08h", rdata);
        end
        mem_read = 0;

        // Test 2: Store Byte (SB) and Load Byte Signed (LB) with negative byte (0xFE)
        // Store byte at address 0x00000010 (offset 0)
        @(negedge clk);
        mem_write = 1;
        funct3    = 3'b000; // SB
        addr      = 32'h00000010;
        wdata     = 32'h000000FE; // Negative 8-bit value (-2)
        @(posedge clk);
        #1;
        mem_write = 0;

        // Read with LB (signed): should sign-extend 0xFE to 0xFFFFFFFE (-2)
        mem_read = 1;
        funct3   = 3'b000; // LB
        addr     = 32'h00000010;
        #5;
        if (rdata !== 32'hFFFFFFFE) begin
            $display("[FAIL] LB signed extension failed: expected 0xFFFFFFFE, got 0x%08h", rdata);
            errors = errors + 1;
        end else begin
            $display("[PASS] LB signed extension verified: 0x%08h", rdata);
        end

        // Read with LBU (unsigned): should zero-extend to 0x000000FE (254)
        funct3 = 3'b100; // LBU
        #5;
        if (rdata !== 32'h000000FE) begin
            $display("[FAIL] LBU zero extension failed: expected 0x000000FE, got 0x%08h", rdata);
            errors = errors + 1;
        end else begin
            $display("[PASS] LBU zero extension verified: 0x%08h", rdata);
        end
        mem_read = 0;

        // Test 3: Store Halfword (SH) and Load Halfword Signed (LH) / Unsigned (LHU)
        // Store 0x8ABC at byte offset 2 of word 0x14 -> addr = 0x00000016
        @(negedge clk);
        mem_write = 1;
        funct3    = 3'b001; // SH
        addr      = 32'h00000016;
        wdata     = 32'h00008ABC;
        @(posedge clk);
        #1;
        mem_write = 0;

        // Read back with LH (signed, should sign-extend 0x8ABC -> 0xFFFF8ABC)
        mem_read = 1;
        funct3   = 3'b001; // LH
        addr     = 32'h00000016;
        #5;
        if (rdata !== 32'hFFFF8ABC) begin
            $display("[FAIL] LH signed extension failed: expected 0xFFFF8ABC, got 0x%08h", rdata);
            errors = errors + 1;
        end else begin
            $display("[PASS] LH signed extension verified: 0x%08h", rdata);
        end

        // Read back with LHU (unsigned, should zero-extend -> 0x00008ABC)
        funct3 = 3'b101; // LHU
        #5;
        if (rdata !== 32'h00008ABC) begin
            $display("[FAIL] LHU zero extension failed: expected 0x00008ABC, got 0x%08h", rdata);
            errors = errors + 1;
        end else begin
            $display("[PASS] LHU zero extension verified: 0x%08h", rdata);
        end
        mem_read = 0;

        #20;
        $display("--------------------------------------------------");
        if (errors == 0)
            $display("TEST RESULT: ALL TESTS PASSED (data_memory)");
        else
            $display("TEST RESULT: %0d ERRORS ENCOUNTERED", errors);
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
