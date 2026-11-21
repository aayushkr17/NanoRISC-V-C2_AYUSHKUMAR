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

        @(negedge clk);
        mem_write = 1;
        funct3    = 3'b010;
        addr      = 32'h00000008;
        wdata     = 32'h12345678;
        @(posedge clk);
        #1;
        mem_write = 0;

        mem_read = 1;
        funct3   = 3'b010;
        addr     = 32'h00000008;
        #5;
        if (rdata !== 32'h12345678) begin
            $display("[FAIL] SW/LW failed: expected 0x12345678, got 0x%08h", rdata);
            errors = errors + 1;
        end else begin
            $display("[PASS] SW and LW verified: 0x%08h", rdata);
        end
        mem_read = 0;

        @(negedge clk);
        mem_write = 1;
        funct3    = 3'b000;
        addr      = 32'h00000010;
        wdata     = 32'h000000FE;
        @(posedge clk);
        #1;
        mem_write = 0;

        mem_read = 1;
        funct3   = 3'b000; 
        addr     = 32'h00000010;
        #5;
        if (rdata !== 32'hFFFFFFFE) begin
            $display("[FAIL] LB signed extension failed: expected 0xFFFFFFFE, got 0x%08h", rdata);
            errors = errors + 1;
        end else begin
            $display("[PASS] LB signed extension verified: 0x%08h", rdata);
        end
        funct3 = 3'b100; 
        #5;
        if (rdata !== 32'h000000FE) begin
            $display("[FAIL] LBU zero extension failed: expected 0x000000FE, got 0x%08h", rdata);
            errors = errors + 1;
        end else begin
            $display("[PASS] LBU zero extension verified: 0x%08h", rdata);
        end
        mem_read = 0;

        @(negedge clk);
        mem_write = 1;
        funct3    = 3'b001;
        addr      = 32'h00000016;
        wdata     = 32'h00008ABC;
        @(posedge clk);
        #1;
        mem_write = 0;

        mem_read = 1;
        funct3   = 3'b001; 
        addr     = 32'h00000016;
        #5;
        if (rdata !== 32'hFFFF8ABC) begin
            $display("[FAIL] LH signed extension failed: expected 0xFFFF8ABC, got 0x%08h", rdata);
            errors = errors + 1;
        end else begin
            $display("[PASS] LH signed extension verified: 0x%08h", rdata);
        end

        funct3 = 3'b101;
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
