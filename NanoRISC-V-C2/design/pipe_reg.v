`timescale 1ns / 1ps

module pipe_reg (
    input  wire        clk,        
    input  wire        rst_n,     
    input  wire        flush,    
    input  wire        stall,     
    input  wire [31:0] pc_in,
    input  wire [31:0] instr_in, 
    input  wire        valid_in,  
    output reg  [31:0] pc_out,  
    output reg  [31:0] instr_out,
    output reg         valid_out  
);

    localparam [31:0] NOP_INSTR = 32'h00000013;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out    <= 32'h00000000;
            instr_out <= NOP_INSTR;
            valid_out <= 1'b0;
        end else if (flush) begin
    
            pc_out    <= 32'h00000000;
            instr_out <= NOP_INSTR;
            valid_out <= 1'b0;
        end else if (!stall) begin
            pc_out    <= pc_in;
            instr_out <= instr_in;
            valid_out <= valid_in;
        end
    end

endmodule
