`timescale 1ns / 1ps

module branch_unit (
    input  wire        branch,    
    input  wire        jump,      
    input  wire        is_jalr,   
    input  wire [2:0]  funct3,    
    input  wire [31:0] rdata1,   
    input  wire [31:0] rdata2,     
    input  wire [31:0] pc,         
    input  wire [31:0] imm,       
    output wire        pc_sel,     
    output wire [31:0] pc_target   
);

    reg condition_met;

    always @(*) begin
        case (funct3)
            3'b000: condition_met = (rdata1 == rdata2);                          
            3'b001: condition_met = (rdata1 != rdata2);                         
            3'b100: condition_met = ($signed(rdata1) < $signed(rdata2));       
            3'b101: condition_met = ($signed(rdata1) >= $signed(rdata2));       
            3'b110: condition_met = (rdata1 < rdata2);                         
            3'b111: condition_met = (rdata1 >= rdata2);                        
            default: condition_met = 1'b0;
        endcase
    end

    
    assign pc_sel = jump | (branch & condition_met);


    wire [31:0] jalr_target       = (rdata1 + imm) & 32'hFFFFFFFE;
    wire [31:0] branch_jal_target = pc + imm;

    assign pc_target = is_jalr ? jalr_target : branch_jal_target;

endmodule
