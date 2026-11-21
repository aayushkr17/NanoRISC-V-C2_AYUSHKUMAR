`timescale 1ns / 1ps

module register_file_tb;

    reg         clk;
    reg         rst_n;
    reg         we;
    reg  [4:0]  raddr1;
    reg  [4:0]  raddr2;
    reg  [4:0]  waddr;
    reg  [31:0] wdata;
    wire [31:0] rdata1;
    wire [31:0] rdata2;

    integer errors = 0;
    register_file uut (
        .clk(clk),
        .rst_n(rst_n),
        .we(we),
        .raddr1(raddr1),
        .raddr2(raddr2),
        .waddr(waddr),
        .wdata(wdata),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );

    always #10 clk = ~clk;

    initial begin
        $dumpfile("register_file.vcd");
        $dumpvars(0, register_file_tb);

        $display("--------------------------------------------------");
        $display("Starting Testbench: register_file_tb");
        $display("--------------------------------------------------");

        clk    = 0;
        rst_n  = 0;
        we     = 0;
        raddr1 = 0;
        raddr2 = 0;
        waddr  = 0;
        wdata  = 0;

        #25;
        rst_n = 1;
        #5;

        raddr1 = 5'd1;
        raddr2 = 5'd2;
        #5;
        if (rdata1 !== 32'd0 || rdata2 !== 32'd0) begin
            $display("[FAIL] Registers not zero after reset: x1=%h, x2=%h", rdata1, rdata2);
            errors = errors + 1;
        end else begin
            $display("[PASS] Reset state verified: x1 = 0, x2 = 0");
        end
        @(negedge clk);
        we    = 1;
        waddr = 5'd0;
        wdata = 32'hDEADBEEF;
        @(posedge clk);
        #1;
        we     = 0;
        raddr1 = 5'd0;
        #5;
        if (rdata1 !== 32'd0) begin
            $display("[FAIL] x0 was modified! Expected 0, got 0x%08h", rdata1);
            errors = errors + 1;
        end else begin
            $display("[PASS] Hardwired x0 verified: remains 0 after write attempt");
        end
         @(negedge clk);
        we    = 1;
        waddr = 5'd1;
        wdata = 32'h11112222;
        @(posedge clk);
        #1;

        @(negedge clk);
        waddr = 5'd2;
        wdata = 32'h33334444;
        @(posedge clk);
        #1;

        @(negedge clk);
        waddr = 5'd31;
        wdata = 32'hAAAA5555;
        @(posedge clk);
        #1;
        we = 0;
        raddr1 = 5'd1;
        raddr2 = 5'd2;
        #5;
        if (rdata1 !== 32'h11112222 || rdata2 !== 32'h33334444) begin
            $display("[FAIL] Readback error: x1=%h, x2=%h", rdata1, rdata2);
            errors = errors + 1;
        end else begin
            $display("[PASS] Dual read port readback verified: x1=0x%08h, x2=0x%08h", rdata1, rdata2);
        end

        raddr1 = 5'd31;
        #5;
        if (rdata1 !== 32'hAAAA5555) begin
            $display("[FAIL] Readback error for x31: got %h", rdata1);
            errors = errors + 1;
        end else begin
            $display("[PASS] Readback x31 verified: 0x%08h", rdata1);
        end
        @(negedge clk);
        we     = 1;
        waddr  = 5'd5;
        wdata  = 32'hFACECAFE;
        raddr1 = 5'd5;
        #5;
        if (rdata1 !== 32'hFACECAFE) begin
            $display("[FAIL] Internal forwarding bypass failed: got %h", rdata1);
            errors = errors + 1;
        end else begin
            $display("[PASS] Write-forwarding bypass verified: rdata1 immediately sees wdata");
        end
        @(posedge clk);
        #1;
        we = 0;

        #20;
        $display("--------------------------------------------------");
        if (errors == 0)
            $display("TEST RESULT: ALL TESTS PASSED (register_file)");
        else
            $display("TEST RESULT: %0d ERRORS ENCOUNTERED", errors);
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
