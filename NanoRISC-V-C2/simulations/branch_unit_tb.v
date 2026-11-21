// =============================================================================
// File: branch_unit_tb.v
// Module: branch_unit_tb
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Dedicated testbench for branch_unit module with GTKWave VCD
//              waveform dump support and automated assertions.
// =============================================================================

`timescale 1ns / 1ps

module branch_unit_tb;

    reg        branch;
    reg        jump;
    reg        is_jalr;
    reg  [2:0] funct3;
    reg  [31:0] rdata1;
    reg  [31:0] rdata2;
    reg  [31:0] pc;
    reg  [31:0] imm;
    wire       pc_sel;
    wire [31:0] pc_target;

    integer errors = 0;

    // Instantiate UUT
    branch_unit uut (
        .branch(branch),
        .jump(jump),
        .is_jalr(is_jalr),
        .funct3(funct3),
        .rdata1(rdata1),
        .rdata2(rdata2),
        .pc(pc),
        .imm(imm),
        .pc_sel(pc_sel),
        .pc_target(pc_target)
    );

    initial begin
        $dumpfile("branch_unit.vcd");
        $dumpvars(0, branch_unit_tb);

        $display("--------------------------------------------------");
        $display("Starting Testbench: branch_unit_tb");
        $display("--------------------------------------------------");

        // Test 1: BEQ Taken (rdata1 == rdata2)
        branch = 1; jump = 0; is_jalr = 0; funct3 = 3'b000;
        rdata1 = 32'd25; rdata2 = 32'd25; pc = 32'h00000100; imm = 32'd16;
        #5;
        if (pc_sel !== 1'b1 || pc_target !== 32'h00000110) begin
            $display("[FAIL] BEQ taken failed: pc_sel=%b, target=0x%08h", pc_sel, pc_target);
            errors = errors + 1;
        end else begin
            $display("[PASS] BEQ taken verified: target=0x%08h", pc_target);
        end

        // Test 2: BEQ Untaken (rdata1 != rdata2)
        rdata2 = 32'd30;
        #5;
        if (pc_sel !== 1'b0) begin
            $display("[FAIL] BEQ untaken failed: pc_sel=%b", pc_sel);
            errors = errors + 1;
        end else begin
            $display("[PASS] BEQ untaken verified");
        end

        // Test 3: BLT signed taken (-10 < 5)
        funct3 = 3'b100; rdata1 = -32'd10; rdata2 = 32'd5;
        #5;
        if (pc_sel !== 1'b1) begin
            $display("[FAIL] BLT signed taken failed: pc_sel=%b", pc_sel);
            errors = errors + 1;
        end else begin
            $display("[PASS] BLT signed taken verified");
        end

        // Test 4: BLTU unsigned untaken (0xFFFFFFFF < 5 is false)
        funct3 = 3'b110; rdata1 = 32'hFFFFFFFF; rdata2 = 32'd5;
        #5;
        if (pc_sel !== 1'b0) begin
            $display("[FAIL] BLTU unsigned untaken failed: pc_sel=%b", pc_sel);
            errors = errors + 1;
        end else begin
            $display("[PASS] BLTU unsigned untaken verified");
        end

        // Test 5: JAL (unconditional jump, target = pc + imm)
        branch = 0; jump = 1; is_jalr = 0;
        pc = 32'h00000200; imm = 32'h00000040;
        #5;
        if (pc_sel !== 1'b1 || pc_target !== 32'h00000240) begin
            $display("[FAIL] JAL target calculation failed: target=0x%08h", pc_target);
            errors = errors + 1;
        end else begin
            $display("[PASS] JAL verified: pc_sel=%b, target=0x%08h", pc_sel, pc_target);
        end

        // Test 6: JALR (target = (rs1 + imm) & ~1)
        branch = 0; jump = 1; is_jalr = 1;
        rdata1 = 32'h00001005; imm = 32'h00000004; // sum = 0x1009 -> cleared LSB = 0x1008
        #5;
        if (pc_sel !== 1'b1 || pc_target !== 32'h00001008) begin
            $display("[FAIL] JALR target failed: expected 0x1008, got 0x%08h", pc_target);
            errors = errors + 1;
        end else begin
            $display("[PASS] JALR LSB-cleared target verified: 0x%08h", pc_target);
        end

        #10;
        $display("--------------------------------------------------");
        if (errors == 0)
            $display("TEST RESULT: ALL TESTS PASSED (branch_unit)");
        else
            $display("TEST RESULT: %0d ERRORS ENCOUNTERED", errors);
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
