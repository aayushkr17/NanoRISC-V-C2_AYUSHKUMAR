`timescale 1ns / 1ps

module instruction_memory_tb;

    reg  [31:0] addr;
    wire [31:0] instr;

    integer errors = 0;

    instruction_memory #(
        .MEM_DEPTH(64)
    ) uut (
        .addr(addr),
        .instr(instr)
    );

    initial begin
 
        $dumpfile("instruction_memory.vcd");
        $dumpvars(0, instruction_memory_tb);

        $display("--------------------------------------------------");
        $display("Starting Testbench: instruction_memory_tb");
        $display("--------------------------------------------------");
        
        uut.mem[0] = 32'h00A00093;
        uut.mem[1] = 32'h01400113;
        uut.mem[2] = 32'h002081B3; 
        uut.mem[3] = 32'h40110233; 

        #10;

        addr = 32'h00000000;
        #5;
        if (instr !== 32'h00A00093) begin
            $display("[FAIL] Addr 0x00: Expected 0x00A00093, got 0x%08h", instr);
            errors = errors + 1;
        end else begin
            $display("[PASS] Addr 0x00: Correctly fetched 0x%08h", instr);
        end

    
        addr = 32'h00000004;
        #5;
        if (instr !== 32'h01400113) begin
            $display("[FAIL] Addr 0x04: Expected 0x01400113, got 0x%08h", instr);
            errors = errors + 1;
        end else begin
            $display("[PASS] Addr 0x04: Correctly fetched 0x%08h", instr);
        end

        addr = 32'h00000008;
        #5;
        if (instr !== 32'h002081B3) begin
            $display("[FAIL] Addr 0x08: Expected 0x002081B3, got 0x%08h", instr);
            errors = errors + 1;
        end else begin
            $display("[PASS] Addr 0x08: Correctly fetched 0x%08h", instr);
        end

        addr = 32'h0000000C;
        #5;
        if (instr !== 32'h40110233) begin
            $display("[FAIL] Addr 0x0C: Expected 0x40110233, got 0x%08h", instr);
            errors = errors + 1;
        end else begin
            $display("[PASS] Addr 0x0C: Correctly fetched 0x%08h", instr);
        end

        addr = 32'h00000020;
        #5;
        if (instr !== 32'h00000013) begin
            $display("[FAIL] Addr 0x20: Expected NOP 0x00000013, got 0x%08h", instr);
            errors = errors + 1;
        end else begin
            $display("[PASS] Addr 0x20 (default): Correctly fetched NOP 0x%08h", instr);
        end

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
