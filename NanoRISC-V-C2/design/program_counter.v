`timescale 1ns / 1ps

module program_counter (
    input  wire        clk,     
    input  wire        rst_n,   
    input  wire        pc_write,
    input  wire [31:0] pc_next,  
    output reg  [31:0] pc    
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'h00000000;
        end else if (pc_write) begin
            pc <= pc_next;
        end
    end

endmodule
