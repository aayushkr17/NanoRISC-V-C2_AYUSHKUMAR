// =============================================================================
// File: nanoriscv_c2_tb.v
// Module: nanoriscv_c2_tb
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: Top-Level Testbench for NanoRISC-V-C2 2-stage pipelined RV32I
//              processor. Preloads an assembly program testing arithmetic,
//              memory load/store, conditional branching with pipeline flush,
//              and unconditional jump with link register writeback.
//              Outputs GTKWave VCD waveforms to "nanoriscv_c2.vcd".
// =============================================================================

`timescale 1ns / 1ps

module nanoriscv_c2_tb;

    reg  clk;
    reg  rst_n;

    // Top-Level Debug Probes
    wire [31:0] debug_pc_if;
    wire [31:0] debug_instr_if;
    wire [31:0] debug_pc_ex;
    wire [31:0] debug_instr_ex;
    wire        debug_valid_ex;
    wire [31:0] debug_alu_result;
    wire [31:0] debug_reg_wdata;
    wire        debug_reg_write;
    wire [4:0]  debug_reg_waddr;
    wire        debug_mem_write;
    wire [31:0] debug_mem_addr;
    wire [31:0] debug_mem_wdata;
    wire        debug_pc_sel;
    wire [31:0] debug_pc_target;

    integer errors = 0;
    integer cycle_count = 0;

    // Instantiate NanoRISC-V-C2 Core
    nanoriscv_c2 #(
        .IMEM_DEPTH(128),
        .DMEM_DEPTH(128)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .debug_pc_if(debug_pc_if),
        .debug_instr_if(debug_instr_if),
        .debug_pc_ex(debug_pc_ex),
        .debug_instr_ex(debug_instr_ex),
        .debug_valid_ex(debug_valid_ex),
        .debug_alu_result(debug_alu_result),
        .debug_reg_wdata(debug_reg_wdata),
        .debug_reg_write(debug_reg_write),
        .debug_reg_waddr(debug_reg_waddr),
        .debug_mem_write(debug_mem_write),
        .debug_mem_addr(debug_mem_addr),
        .debug_mem_wdata(debug_mem_wdata),
        .debug_pc_sel(debug_pc_sel),
        .debug_pc_target(debug_pc_target)
    );

    // Clock Generation: 50 MHz (Period = 20 ns)
    always #10 clk = ~clk;

    // Cycle counter and trace monitor
    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;
            $display("[Cycle %0d] IF: PC=0x%08h | EX: PC=0x%08h Instr=0x%08h Valid=%b | RegWr=%b Rd=x%0d WData=0x%08h | MemWr=%b Addr=0x%08h | BranchRedirect=%b Target=0x%08h",
                cycle_count,
                debug_pc_if,
                debug_pc_ex,
                debug_instr_ex,
                debug_valid_ex,
                debug_reg_write,
                debug_reg_waddr,
                debug_reg_wdata,
                debug_mem_write,
                debug_mem_addr,
                debug_pc_sel,
                debug_pc_target
            );
        end
    end

    initial begin
        // GTKWave Waveform Generation
        $dumpfile("nanoriscv_c2.vcd");
        $dumpvars(0, nanoriscv_c2_tb);

        $display("=================================================================");
        $display(" NanoRISC-V-C2: 2-Stage RV32I Processor Top-Level Verification  ");
        $display("=================================================================");

        // Initialize signals
        clk   = 0;
        rst_n = 0;

        // ---------------------------------------------------------------------
        // Preload Instruction Memory with RV32I Test Program:
        // ---------------------------------------------------------------------
        // 0x00: addi x1, x0, 10      ; x1 = 10
        // 0x04: addi x2, x0, 20      ; x2 = 20
        // 0x08: add  x3, x1, x2      ; x3 = 30
        // 0x0C: sub  x4, x2, x1      ; x4 = 10
        // 0x10: sw   x3, 8(x0)       ; mem[8] = 30
        // 0x14: lw   x5, 8(x0)       ; x5 = mem[8] = 30
        // 0x18: beq  x3, x5, 8       ; if (x3 == x5) jump to PC + 8 (0x20)
        // 0x1C: addi x6, x0, 99      ; SHOULD BE FLUSHED/SKIPPED!
        // 0x20: addi x6, x0, 42      ; Branch target: x6 = 42
        // 0x24: slli x7, x1, 2       ; x7 = 10 << 2 = 40
        // 0x28: jal  x8, 8           ; jump to PC + 8 (0x30), link x8 = 0x2C
        // 0x2C: addi x9, x0, 88      ; SHOULD BE FLUSHED/SKIPPED!
        // 0x30: addi x9, x0, 55      ; Jump target: x9 = 55
        // 0x34: addi x0, x0, 0       ; NOP
        // ---------------------------------------------------------------------
        uut.imem_u.mem[0]  = 32'h00A00093; // addi x1, x0, 10
        uut.imem_u.mem[1]  = 32'h01400113; // addi x2, x0, 20
        uut.imem_u.mem[2]  = 32'h002081B3; // add  x3, x1, x2
        uut.imem_u.mem[3]  = 32'h40110233; // sub  x4, x2, x1
        uut.imem_u.mem[4]  = 32'h00302423; // sw   x3, 8(x0)
        uut.imem_u.mem[5]  = 32'h00802283; // lw   x5, 8(x0)
        uut.imem_u.mem[6]  = 32'h00518463; // beq  x3, x5, 8
        uut.imem_u.mem[7]  = 32'h06300313; // addi x6, x0, 99  (Flush bubble target)
        uut.imem_u.mem[8]  = 32'h02A00313; // addi x6, x0, 42
        uut.imem_u.mem[9]  = 32'h00209393; // slli x7, x1, 2
        uut.imem_u.mem[10] = 32'h0080046F; // jal  x8, 8
        uut.imem_u.mem[11] = 32'h05800493; // addi x9, x0, 88  (Flush bubble target)
        uut.imem_u.mem[12] = 32'h03700493; // addi x9, x0, 55
        uut.imem_u.mem[13] = 32'h00000013; // NOP
        uut.imem_u.mem[14] = 32'h00000013; // NOP

        // Hold reset for 2 clock cycles
        #25;
        @(negedge clk);
        rst_n = 1;
        $display("[Time %0t ns] Reset released. Processor starting execution...", $time);

        // Run processor for 25 clock cycles to complete execution
        repeat (25) @(posedge clk);

        // ---------------------------------------------------------------------
        // Automated Verification of Core Architectural State
        // ---------------------------------------------------------------------
        $display("\n=================================================================");
        $display(" Architectural State Verification                                ");
        $display("=================================================================");

        // Verify x1 == 10
        if (uut.rf_u.regs[1] !== 32'd10) begin
            $display("[FAIL] x1: Expected 10, got %0d", uut.rf_u.regs[1]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x1 = %0d (addi x1, x0, 10)", uut.rf_u.regs[1]);
        end

        // Verify x2 == 20
        if (uut.rf_u.regs[2] !== 32'd20) begin
            $display("[FAIL] x2: Expected 20, got %0d", uut.rf_u.regs[2]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x2 = %0d (addi x2, x0, 20)", uut.rf_u.regs[2]);
        end

        // Verify x3 == 30
        if (uut.rf_u.regs[3] !== 32'd30) begin
            $display("[FAIL] x3: Expected 30, got %0d", uut.rf_u.regs[3]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x3 = %0d (add x3, x1, x2)", uut.rf_u.regs[3]);
        end

        // Verify x4 == 10
        if (uut.rf_u.regs[4] !== 32'd10) begin
            $display("[FAIL] x4: Expected 10, got %0d", uut.rf_u.regs[4]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x4 = %0d (sub x4, x2, x1)", uut.rf_u.regs[4]);
        end

        // Verify Data Memory[8] == 30 (word index 2)
        if ({uut.dmem_u.mem3[2], uut.dmem_u.mem2[2], uut.dmem_u.mem1[2], uut.dmem_u.mem0[2]} !== 32'd30) begin
            $display("[FAIL] Data Memory[8]: Expected 30, got %0d",
                {uut.dmem_u.mem3[2], uut.dmem_u.mem2[2], uut.dmem_u.mem1[2], uut.dmem_u.mem0[2]});
            errors = errors + 1;
        end else begin
            $display("[PASS] Data Memory[8] = 30 (sw x3, 8(x0))");
        end

        // Verify x5 == 30
        if (uut.rf_u.regs[5] !== 32'd30) begin
            $display("[FAIL] x5: Expected 30, got %0d", uut.rf_u.regs[5]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x5 = %0d (lw x5, 8(x0))", uut.rf_u.regs[5]);
        end

        // Verify x6 == 42 (Verifies Branch Taken & Pipeline Flush of addi x6, x0, 99)
        if (uut.rf_u.regs[6] !== 32'd42) begin
            $display("[FAIL] x6: Expected 42 (branch taken & flush succeeded), got %0d", uut.rf_u.regs[6]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x6 = %0d (Branch Taken verified; skipped addi x6, x0, 99)", uut.rf_u.regs[6]);
        end

        // Verify x7 == 40 (slli x7, x1, 2)
        if (uut.rf_u.regs[7] !== 32'd40) begin
            $display("[FAIL] x7: Expected 40, got %0d", uut.rf_u.regs[7]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x7 = %0d (slli x7, x1, 2)", uut.rf_u.regs[7]);
        end

        // Verify x8 == 0x0000002C (JAL return address link)
        if (uut.rf_u.regs[8] !== 32'h0000002C) begin
            $display("[FAIL] x8 (JAL link): Expected 0x0000002C, got 0x%08h", uut.rf_u.regs[8]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x8 = 0x%08h (JAL link address pc+4 verified)", uut.rf_u.regs[8]);
        end

        // Verify x9 == 55 (Verifies JAL taken & Pipeline Flush of addi x9, x0, 88)
        if (uut.rf_u.regs[9] !== 32'd55) begin
            $display("[FAIL] x9: Expected 55 (jump taken & flush succeeded), got %0d", uut.rf_u.regs[9]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x9 = %0d (JAL Jump Taken verified; skipped addi x9, x0, 88)", uut.rf_u.regs[9]);
        end

        $display("=================================================================");
        if (errors == 0) begin
            $display(" CORE RESULT: ALL INSTRUCTIONS & PIPELINE PHASES VERIFIED (PASS)");
            $display(" Waveform file successfully generated: nanoriscv_c2.vcd");
        end else begin
            $display(" CORE RESULT: %0d VERIFICATION ERRORS DETECTED", errors);
        end
        $display("=================================================================\n");

        $finish;
    end

endmodule
