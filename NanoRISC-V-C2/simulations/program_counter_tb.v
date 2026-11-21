`timescale 1ns / 1ps

module program_counter_tb;

    reg         clk;
    reg         rst_n;
    reg         pc_write;
    reg  [31:0] pc_next;
    wire [31:0] pc;

    integer errors = 0;
    program_counter uut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_write(pc_write),
        .pc_next(pc_next),
        .pc(pc)
    );
    always #10 clk = ~clk;

    initial begin
        $dumpfile("program_counter.vcd");
        $dumpvars(0, program_counter_tb);

        $display("--------------------------------------------------");
        $display("Starting Testbench: program_counter_tb");
        $display("--------------------------------------------------");

        clk      = 0;
        rst_n    = 0;
        pc_write = 0;
        pc_next  = 32'h00000000;

        #25;
        rst_n = 1;
        if (pc !== 32'h00000000) begin
            $display("[FAIL] Expected PC = 0 after reset, got 0x%08h", pc);
            errors = errors + 1;
        end else begin
            $display("[PASS] Reset verified: PC = 0x%08h", pc);
        end

        @(negedge clk);
        pc_write = 1;
        pc_next  = 32'h00000004;
        @(posedge clk);
        #1;
        if (pc !== 32'h00000004) begin
            $display("[FAIL] Expected PC = 0x4, got 0x%08h", pc);
            errors = errors + 1;
        end else begin
            $display("[PASS] PC increment to 0x4 verified");
        end

        @(negedge clk);
        pc_next = 32'h00000008;
        @(posedge clk);
        #1;
        if (pc !== 32'h00000008) begin
            $display("[FAIL] Expected PC = 0x8, got 0x%08h", pc);
            errors = errors + 1;
        end else begin
            $display("[PASS] PC increment to 0x8 verified");
        end
        @(negedge clk);
        pc_write = 0;
        pc_next  = 32'h0000000C;
        @(posedge clk);
        #1;
        if (pc !== 32'h00000008) begin
            $display("[FAIL] Stall failed! Expected PC = 0x8, got 0x%08h", pc);
            errors = errors + 1;
        end else begin
            $display("[PASS] PC Stall verified: PC held at 0x%08h", pc);
        end

        @(negedge clk);
        pc_write = 1;
        pc_next  = 32'h00001000;
        @(posedge clk);
        #1;
        if (pc !== 32'h00001000) begin
            $display("[FAIL] Jump target update failed! Expected 0x1000, got 0x%08h", pc);
            errors = errors + 1;
        end else begin
            $display("[PASS] Branch/Jump target update verified: PC = 0x%08h", pc);
        end

        #5;
        rst_n = 0;
        #1;
        if (pc !== 32'h00000000) begin
            $display("[FAIL] Async reset failed! Expected 0x0, got 0x%08h", pc);
            errors = errors + 1;
        end else begin
            $display("[PASS] Async reset during operation verified: PC = 0x%08h", pc);
        end

        #20;
        $display("--------------------------------------------------");
        if (errors == 0)
            $display("TEST RESULT: ALL TESTS PASSED (program_counter)");
        else
            $display("TEST RESULT: %0d ERRORS ENCOUNTERED", errors);
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
