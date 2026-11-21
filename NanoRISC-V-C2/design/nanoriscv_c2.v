`timescale 1ns / 1ps

module nanoriscv_c2 #(
    parameter IMEM_DEPTH = 1024,
    parameter DMEM_DEPTH = 1024 
)(
    input  wire        clk,       
    input  wire        rst_n,      

    output wire [31:0] debug_pc_if,     
    output wire [31:0] debug_instr_if,  
    output wire [31:0] debug_pc_ex,      
    output wire [31:0] debug_instr_ex,  
    output wire        debug_valid_ex,  
    output wire [31:0] debug_alu_result, 
    output wire [31:0] debug_reg_wdata,   
    output wire        debug_reg_write,  
    output wire [4:0]  debug_reg_waddr,  
    output wire        debug_mem_write,  
    output wire [31:0] debug_mem_addr,   
    output wire [31:0] debug_mem_wdata,  
    output wire        debug_pc_sel,    
    output wire [31:0] debug_pc_target  
);

    wire [31:0] pc_if;
    wire [31:0] pc_next;
    wire [31:0] instr_if;

    assign pc_next = debug_pc_sel ? debug_pc_target : (pc_if + 32'd4);

    program_counter pc_u (
        .clk(clk),
        .rst_n(rst_n),
        .pc_write(1'b1), 
        .pc_next(pc_next),
        .pc(pc_if)
    );

    instruction_memory #(
        .MEM_DEPTH(IMEM_DEPTH)
    ) imem_u (
        .addr(pc_if),
        .instr(instr_if)
    );

    wire [31:0] pc_ex;
    wire [31:0] instr_ex;
    wire        valid_ex;

    pipe_reg pipe_u (
        .clk(clk),
        .rst_n(rst_n),
        .flush(debug_pc_sel),
        .stall(1'b0),
        .pc_in(pc_if),
        .instr_in(instr_if),
        .valid_in(rst_n),
        .pc_out(pc_ex),
        .instr_out(instr_ex),
        .valid_out(valid_ex)
    );

    wire [6:0] opcode = instr_ex[6:0];
    wire [4:0] rd     = instr_ex[11:7];
    wire [2:0] funct3 = instr_ex[14:12];
    wire [4:0] rs1    = instr_ex[19:15];
    wire [4:0] rs2    = instr_ex[24:20];
    wire [6:0] funct7 = instr_ex[31:25];

    wire       raw_reg_write;
    wire       raw_mem_read;
    wire       raw_mem_write;
    wire [1:0] mem_to_reg;
    wire       alu_src_a;
    wire       alu_src_b;
    wire [3:0] alu_ctrl;
    wire       raw_branch;
    wire       raw_jump;
    wire       is_jalr;
    wire [2:0] imm_src;

    control_unit ctrl_u (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(raw_reg_write),
        .mem_read(raw_mem_read),
        .mem_write(raw_mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .alu_ctrl(alu_ctrl),
        .branch(raw_branch),
        .jump(raw_jump),
        .is_jalr(is_jalr),
        .imm_src(imm_src)
    );

    wire reg_write = raw_reg_write & valid_ex;
    wire mem_read  = raw_mem_read  & valid_ex;
    wire mem_write = raw_mem_write & valid_ex;
    wire branch    = raw_branch    & valid_ex;
    wire jump      = raw_jump      & valid_ex;

    wire [31:0] imm;
    imm_gen imm_u (
        .instr(instr_ex),
        .imm_src(imm_src),
        .imm(imm)
    );

    wire [31:0] rdata1;
    wire [31:0] rdata2;
    reg  [31:0] reg_wdata;

    register_file rf_u (
        .clk(clk),
        .rst_n(rst_n),
        .we(reg_write),
        .raddr1(rs1),
        .raddr2(rs2),
        .waddr(rd),
        .wdata(reg_wdata),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );

    wire [31:0] alu_a = alu_src_a ? pc_ex : rdata1;
    wire [31:0] alu_b = alu_src_b ? imm   : rdata2;

    wire [31:0] alu_result;
    wire        alu_zero;

    alu alu_u (
        .a(alu_a),
        .b(alu_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(alu_zero)
    );

    wire        pc_sel;
    wire [31:0] pc_target;

    branch_unit bu_u (
        .branch(branch),
        .jump(jump),
        .is_jalr(is_jalr),
        .funct3(funct3),
        .rdata1(rdata1),
        .rdata2(rdata2),
        .pc(pc_ex),
        .imm(imm),
        .pc_sel(pc_sel),
        .pc_target(pc_target)
    );

    wire [31:0] mem_rdata;

    data_memory #(
        .MEM_DEPTH(DMEM_DEPTH)
    ) dmem_u (
        .clk(clk),
        .rst_n(rst_n),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .funct3(funct3),
        .addr(alu_result),
        .wdata(rdata2),
        .rdata(mem_rdata)
    );

    always @(*) begin
        case (mem_to_reg)
            2'b00: reg_wdata = alu_result;        
            2'b01: reg_wdata = mem_rdata;        
            2'b10: reg_wdata = pc_ex + 32'd4;    
            default: reg_wdata = alu_result;
        endcase
    end

    assign debug_pc_if      = pc_if;
    assign debug_instr_if   = instr_if;
    assign debug_pc_ex      = pc_ex;
    assign debug_instr_ex   = instr_ex;
    assign debug_valid_ex   = valid_ex;
    assign debug_alu_result = alu_result;
    assign debug_reg_wdata  = reg_wdata;
    assign debug_reg_write  = reg_write;
    assign debug_reg_waddr  = rd;
    assign debug_mem_write  = mem_write;
    assign debug_mem_addr   = alu_result;
    assign debug_mem_wdata  = rdata2;
    assign debug_pc_sel     = pc_sel;
    assign debug_pc_target  = pc_target;

endmodule
