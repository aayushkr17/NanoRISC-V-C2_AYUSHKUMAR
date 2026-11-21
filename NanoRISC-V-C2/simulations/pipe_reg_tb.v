`timescale 1ns / 1ps

module pipe_reg_tb;

    reg         clk;
    reg         rst_n;
    reg         flush;
    reg         stall;
    reg  [31:0] pc_in;
    reg  [31:0] instr_in;
    reg         valid_in;
    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire        valid_out;

    integer errors = 0;
    pipe_reg uut (
        .clk(clk),
        .rst_n(rst_n),
        .flush(flush),
        .stall(stall),
        .pc_in(pc_in),
        .instr_in(instr_in),
        .valid_in(valid_in),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .valid_out(valid_out)
    );

  
  always #10 clk = ~clk;

    initial begin
        $dumpfile("pipe_reg.vcd");
        $dumpvars(0, pipe_reg_tb);

        $display("--------------------------------------------------");
        $display("Starting Testbench: pipe_reg_tb");
        $display("--------------------------------------------------");

        clk      = 0;
        rst_n    = 0;
        flush    = 0;
        stall    = 0;
        pc_in    = 32'h00000000;
        instr_in = 32'h00000013;
        valid_in = 0;

        #25;
        rst_n = 1;
        #1;
        if (instr_out !== 32'h00000013 || valid_out !== 1'b0) begin
            $display("[FAIL] Reset state incorrect: instr=0x%08h, valid=%b", instr_out, valid_out);
            errors = errors + 1;
        end else begin
            $display("[PASS] Reset state verified");
        end

        @(negedge clk);
        pc_in    = 32'h00000004;
        instr_in = 32'h12345678;
        valid_in = 1'b1;
        @(posedge clk);
        #1;
        if (pc_out !== 32'h00000004 || instr_out !== 32'h12345678 || valid_out !== 1'b1) begin
            $display("[FAIL] Normal propagation failed: pc=0x%08h, instr=0x%08h, valid=%b", pc_out, instr_out, valid_out);
            errors = errors + 1;
        end else begin
            $display("[PASS] Normal pipeline propagation verified");
        end

        @(negedge clk);
        stall    = 1;
        pc_in    = 32'h00000008;
        instr_in = 32'hAABBCCDD;
        valid_in = 1'b1;
        @(posedge clk);
        #1;
        if (pc_out !== 32'h00000004 || instr_out !== 32'h12345678) begin
            $display("[FAIL] Stall failed: values changed when stall was high");
            errors = errors + 1;
        end else begin
            $display("[PASS] Stall hold verified");
        end

        @(negedge clk);
        stall = 0;
        @(posedge clk);
        #1;
        if (pc_out !== 32'h00000008 || instr_out !== 32'hAABBCCDD) begin
            $display("[FAIL] Resume after stall failed");
            errors = errors + 1;
        end else begin
            $display("[PASS] Resume after stall verified");
        end

        @(negedge clk);
        flush    = 1;
        pc_in    = 32'h0000000C;
        instr_in = 32'hDEADBEEF;
        valid_in = 1'b1;
        @(posedge clk);
        #1;
        if (instr_out !== 32'h00000013 || valid_out !== 1'b0) begin
            $display("[FAIL] Flush failed: instr=0x%08h, valid=%b", instr_out, valid_out);
            errors = errors + 1;
        end else begin
            $display("[PASS] Flush bubble insertion verified: NOP injected and valid=0");
        end

        @(negedge clk);
        flush = 0;
        #20;

        $display("--------------------------------------------------");
        if (errors == 0)
            $display("TEST RESULT: ALL TESTS PASSED (pipe_reg)");
        else
            $display("TEST RESULT: %0d ERRORS ENCOUNTERED", errors);
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
