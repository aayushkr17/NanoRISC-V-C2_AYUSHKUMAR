`timescale 1ns / 1ps

module nanoriscv_c2_tb;

    reg  clk;
    reg  rst_n;

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

  
    always #10 clk = ~clk;
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
        
        $dumpfile("nanoriscv_c2.vcd");
        $dumpvars(0, nanoriscv_c2_tb);

        $display("=================================================================");
        $display(" NanoRISC-V-C2: 2-Stage RV32I Processor Top-Level Verification  ");
        $display("=================================================================");

       
        clk   = 0;
        rst_n = 0;

        uut.imem_u.mem[0]  = 32'h00A00093;
        uut.imem_u.mem[1]  = 32'h01400113;
        uut.imem_u.mem[2]  = 32'h002081B3;
        uut.imem_u.mem[3]  = 32'h40110233;
        uut.imem_u.mem[4]  = 32'h00302423;
        uut.imem_u.mem[5]  = 32'h00802283; 
        uut.imem_u.mem[6]  = 32'h00518463; 
        uut.imem_u.mem[7]  = 32'h06300313; 
        uut.imem_u.mem[8]  = 32'h02A00313; 
        uut.imem_u.mem[9]  = 32'h00209393; 
        uut.imem_u.mem[10] = 32'h0080046F; 
        uut.imem_u.mem[11] = 32'h05800493; 
        uut.imem_u.mem[12] = 32'h03700493; 
        uut.imem_u.mem[13] = 32'h00000013;
        uut.imem_u.mem[14] = 32'h00000013;

      
        #25;
        @(negedge clk);
        rst_n = 1;
        $display("[Time %0t ns] Reset released. Processor starting execution...", $time);
 
        repeat (25) @(posedge clk);

        $display("\n=================================================================");
        $display(" Architectural State Verification                                ");
        $display("=================================================================");

        if (uut.rf_u.regs[1] !== 32'd10) begin
            $display("[FAIL] x1: Expected 10, got %0d", uut.rf_u.regs[1]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x1 = %0d (addi x1, x0, 10)", uut.rf_u.regs[1]);
        end

        if (uut.rf_u.regs[2] !== 32'd20) begin
            $display("[FAIL] x2: Expected 20, got %0d", uut.rf_u.regs[2]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x2 = %0d (addi x2, x0, 20)", uut.rf_u.regs[2]);
        end

        if (uut.rf_u.regs[3] !== 32'd30) begin
            $display("[FAIL] x3: Expected 30, got %0d", uut.rf_u.regs[3]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x3 = %0d (add x3, x1, x2)", uut.rf_u.regs[3]);
        end

        if (uut.rf_u.regs[4] !== 32'd10) begin
            $display("[FAIL] x4: Expected 10, got %0d", uut.rf_u.regs[4]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x4 = %0d (sub x4, x2, x1)", uut.rf_u.regs[4]);
        end

        if ({uut.dmem_u.mem3[2], uut.dmem_u.mem2[2], uut.dmem_u.mem1[2], uut.dmem_u.mem0[2]} !== 32'd30) begin
            $display("[FAIL] Data Memory[8]: Expected 30, got %0d",
                {uut.dmem_u.mem3[2], uut.dmem_u.mem2[2], uut.dmem_u.mem1[2], uut.dmem_u.mem0[2]});
            errors = errors + 1;
        end else begin
            $display("[PASS] Data Memory[8] = 30 (sw x3, 8(x0))");
        end

        if (uut.rf_u.regs[5] !== 32'd30) begin
            $display("[FAIL] x5: Expected 30, got %0d", uut.rf_u.regs[5]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x5 = %0d (lw x5, 8(x0))", uut.rf_u.regs[5]);
        end

       
        if (uut.rf_u.regs[6] !== 32'd42) begin
            $display("[FAIL] x6: Expected 42 (branch taken & flush succeeded), got %0d", uut.rf_u.regs[6]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x6 = %0d (Branch Taken verified; skipped addi x6, x0, 99)", uut.rf_u.regs[6]);
        end

        if (uut.rf_u.regs[7] !== 32'd40) begin
            $display("[FAIL] x7: Expected 40, got %0d", uut.rf_u.regs[7]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x7 = %0d (slli x7, x1, 2)", uut.rf_u.regs[7]);
        end

        if (uut.rf_u.regs[8] !== 32'h0000002C) begin
            $display("[FAIL] x8 (JAL link): Expected 0x0000002C, got 0x%08h", uut.rf_u.regs[8]);
            errors = errors + 1;
        end else begin
            $display("[PASS] x8 = 0x%08h (JAL link address pc+4 verified)", uut.rf_u.regs[8]);
        end

      
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
