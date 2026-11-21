`timescale 1ns / 1ps

module data_memory #(
    parameter MEM_DEPTH = 1024 
    input  wire        clk,       
    input  wire        rst_n,     
    input  wire        mem_read,   
    input  wire        mem_write, 
    input  wire [2:0]  funct3,    
    input  wire [31:0] addr,     
    input  wire [31:0] wdata,    
    output reg  [31:0] rdata    
);
    reg [7:0] mem0 [0:MEM_DEPTH-1]; 
    reg [7:0] mem1 [0:MEM_DEPTH-1]; 
    reg [7:0] mem2 [0:MEM_DEPTH-1]; 
    reg [7:0] mem3 [0:MEM_DEPTH-1]; 

    wire [29:0] word_idx    = addr[31:2];
    wire [1:0]  byte_offset = addr[1:0];

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < MEM_DEPTH; i = i + 1) begin
                mem0[i] <= 8'h00;
                mem1[i] <= 8'h00;
                mem2[i] <= 8'h00;
                mem3[i] <= 8'h00;
            end
        end else if (mem_write && (word_idx < MEM_DEPTH)) begin
            case (funct3)
                3'b000: begin 
                    case (byte_offset)
                        2'b00: mem0[word_idx] <= wdata[7:0];
                        2'b01: mem1[word_idx] <= wdata[7:0];
                        2'b10: mem2[word_idx] <= wdata[7:0];
                        2'b11: mem3[word_idx] <= wdata[7:0];
                    endcase
                end

                3'b001: begin 
                    if (byte_offset[1] == 1'b0) begin
                        mem0[word_idx] <= wdata[7:0];
                        mem1[word_idx] <= wdata[15:8];
                    end else begin
                        mem2[word_idx] <= wdata[7:0];
                        mem3[word_idx] <= wdata[15:8];
                    end
                end

                3'b010: begin
                    mem0[word_idx] <= wdata[7:0];
                    mem1[word_idx] <= wdata[15:8];
                    mem2[word_idx] <= wdata[23:16];
                    mem3[word_idx] <= wdata[31:24];
                end

                default: ;
            endcase
        end
    end

    wire [7:0] b0 = (word_idx < MEM_DEPTH) ? mem0[word_idx] : 8'h00;
    wire [7:0] b1 = (word_idx < MEM_DEPTH) ? mem1[word_idx] : 8'h00;
    wire [7:0] b2 = (word_idx < MEM_DEPTH) ? mem2[word_idx] : 8'h00;
    wire [7:0] b3 = (word_idx < MEM_DEPTH) ? mem3[word_idx] : 8'h00;

    always @(*) begin
        if (!mem_read) begin
            rdata = 32'h00000000;
        end else begin
            case (funct3)
                3'b000: begin 
                    case (byte_offset)
                        2'b00: rdata = {{24{b0[7]}}, b0};
                        2'b01: rdata = {{24{b1[7]}}, b1};
                        2'b10: rdata = {{24{b2[7]}}, b2};
                        2'b11: rdata = {{24{b3[7]}}, b3};
                    endcase
                end

                3'b001: begin 
                    if (byte_offset[1] == 1'b0)
                        rdata = {{16{b1[7]}}, b1, b0};
                    else
                        rdata = {{16{b3[7]}}, b3, b2};
                end

                3'b010: begin
                    rdata = {b3, b2, b1, b0};
                end

                3'b100: begin
                    case (byte_offset)
                        2'b00: rdata = {24'h000000, b0};
                        2'b01: rdata = {24'h000000, b1};
                        2'b10: rdata = {24'h000000, b2};
                        2'b11: rdata = {24'h000000, b3};
                    endcase
                end

                3'b101: begin 
                    if (byte_offset[1] == 1'b0)
                        rdata = {16'h0000, b1, b0};
                    else
                        rdata = {16'h0000, b3, b2};
                end

                default: rdata = 32'h00000000;
            endcase
        end
    end

endmodule
