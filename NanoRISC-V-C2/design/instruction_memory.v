`timescale 1ns / 1ps

module instruction_memory #(
    parameter MEM_DEPTH = 1024
)(
    input  wire [31:0] addr,  
    output wire [31:0] instr   
);

    reg [31:0] mem [0:MEM_DEPTH-1];

    wire [29:0] word_addr = addr[31:2];

    assign instr = (word_addr < MEM_DEPTH) ? mem[word_addr] : 32'h00000013;

    integer i;
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem[i] = 32'h00000013;
        end
    end

endmodule
