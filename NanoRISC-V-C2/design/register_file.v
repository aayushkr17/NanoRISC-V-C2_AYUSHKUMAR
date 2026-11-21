// =============================================================================
// File: register_file.v
// Module: register_file
// Project: NanoRISC-V-C2 (2-Stage RV32I Core)
// Description: 32 x 32-bit Register File for RV32I.
//              - Register x0 is hardwired to zero (read returns 0, writes ignored).
//              - Dual asynchronous read ports (rdata1, rdata2).
//              - Single synchronous write port (wdata on posedge clk with we).
//              - Transparent write-forwarding for simultaneous read/write to
//                the same register within the same cycle.
// =============================================================================

`timescale 1ns / 1ps

module register_file (
    input  wire        clk,       // Clock
    input  wire        rst_n,     // Active-low asynchronous reset
    input  wire        we,        // Write enable
    input  wire [4:0]  raddr1,    // Read register address 1 (rs1)
    input  wire [4:0]  raddr2,    // Read register address 2 (rs2)
    input  wire [4:0]  waddr,     // Write register address (rd)
    input  wire [31:0] wdata,     // Write data
    output wire [31:0] rdata1,    // Read data 1
    output wire [31:0] rdata2     // Read data 2
);

    reg [31:0] regs [0:31];
    integer i;

    // Synchronous write port with asynchronous reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'h00000000;
            end
        end else if (we && (waddr != 5'd0)) begin
            regs[waddr] <= wdata;
        end
    end

    // Asynchronous read ports with x0 hardwired to 0 and transparent bypass
    assign rdata1 = (raddr1 == 5'd0) ? 32'h00000000 :
                    (we && (waddr == raddr1)) ? wdata :
                    regs[raddr1];

    assign rdata2 = (raddr2 == 5'd0) ? 32'h00000000 :
                    (we && (waddr == raddr2)) ? wdata :
                    regs[raddr2];

endmodule
