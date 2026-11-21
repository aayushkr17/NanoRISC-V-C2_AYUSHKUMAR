`timescale 1ns / 1ps

module register_file (
    input  wire        clk,       
    input  wire        rst_n,     
    input  wire [4:0]  raddr2,    
    input  wire [4:0]  waddr,   
    input  wire [31:0] wdata,   
    output wire [31:0] rdata1,    
    output wire [31:0] rdata2   
);

    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'h00000000;
            end
        end else if (we && (waddr != 5'd0)) begin
            regs[waddr] <= wdata;
        end
    end

    assign rdata1 = (raddr1 == 5'd0) ? 32'h00000000 :
                    (we && (waddr == raddr1)) ? wdata :
                    regs[raddr1];

    assign rdata2 = (raddr2 == 5'd0) ? 32'h00000000 :
                    (we && (waddr == raddr2)) ? wdata :
                    regs[raddr2];

endmodule
