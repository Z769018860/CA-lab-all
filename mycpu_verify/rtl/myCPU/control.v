`timescale 10ns / 1ns

`define op_addiu 6'b001001

`define op_lw    6'b100011

`define op_sw    6'b101011

`define op_bne   6'b000101

`define op_beq   6'b000100

`define op_nop   6'b000000

//basic

`define func_addu  6'b100001

`define func_move  6'b000000

`define op_j       6'b000010

`define func_jal   6'b000011

`define func_jr    6'b001000 

`define op_lui     6'b001111

`define func_sll   6'b000000

`define op_slti    6'b001010

`define func_sltiu 6'b001011

`define func_subu  6'b100011

//medium

`define func_and   6'b100100

`define op_andi    6'b001100

`define op_bgez    6'b000001

`define op_blez    6'b000110

`define op_bltz    6'b000001

`define func_jalr  6'b001001

`define op_lb      6'b100000

`define op_lbu     6'b100100

`define op_lh      6'b100001

`define op_lhu     6'b100101

`define op_lwl     6'b100010

`define op_lwr     6'b100110

`define func_movn  6'b001011

`define func_movz  6'b001010

`define func_nor   6'b100111

`define func_or    6'b100101

`define op_ori     6'b001101

`define op_sb      6'b101000

`define op_sh      6'b101001

`define func_sllv  6'b000100

`define func_sltu  6'b101011

`define func_sra   6'b000011

`define func_srav  6'b000111

`define func_srl   6'b000010

`define func_srlv  6'b000110

`define op_swl     6'b101011

`define op_swr     6'b101110

`define func_xor   6'b100110

`define op_xori    6'b001110

//advanced
`define op_special 6'b000000

module control(
    input  wire       reset,
    input  wire       BranchCond,
    input  wire [4:0] rt,
    input  wire [5:0] op,
    input  wire [5:0] func,
    output wire       MemEn,
    output wire       JSrc,
    output wire       MemToReg,
    output wire       rs_R,
    output wire       rt_R,
    output wire [1:0] PCSrc,
    output wire [1:0] RegDst,
    output wire [1:0] ALUSrcA,
    output wire [1:0] ALUSrcB,
    output wire [3:0] ALUop,
    output wire [3:0] RegWrite,
    output wire [3:0] MemWrite,
    output wire [5:0] B_Type,
    output wire [1:0] MULT,
    output wire [1:0] DIV,
    output wire [1:0] MFHL,
    output wire [1:0] MTHL
  );

wire is_branch;

wire inst_lw     = (op == 6'b100011);
wire inst_sw     = (op == 6'b101011);
wire inst_addiu  = (op == 6'b001001);
wire inst_beq    = (op == 6'b000100);
wire inst_bne    = (op == 6'b000101);
wire inst_j      = (op == 6'b000010);
wire inst_jal    = (op == 6'b000011);
wire inst_slti   = (op == 6'b001010);
wire inst_sltiu  = (op == 6'b001011);
wire inst_lui    = (op == 6'b001111);
wire inst_jr     = (op == 6'd0) && (func == 6'b001000);
wire inst_sll    = (op == 6'd0) && (func == 6'b000000);
wire inst_or     = (op == 6'd0) && (func == 6'b100101);
wire inst_slt    = (op == 6'd0) && (func == 6'b101010);
wire inst_addu   = (op == 6'd0) && (func == 6'b100001);

wire inst_addi   = (op == 6'b001000);
wire inst_andi   = (op == 6'b001100);
wire inst_ori    = (op == 6'b001101);
wire inst_xori   = (op == 6'b001110);
wire inst_add    = (op == 6'd0) && (func == 6'b100000);
wire inst_sub    = (op == 6'd0) && (func == 6'b100010);
wire inst_subu   = (op == 6'd0) && (func == 6'b100011);
wire inst_sltu   = (op == 6'd0) && (func == 6'b101011);
wire inst_and    = (op == 6'd0) && (func == 6'b100100);
wire inst_nor    = (op == 6'd0) && (func == 6'b100111);
wire inst_xor    = (op == 6'd0) && (func == 6'b100110);
wire inst_sllv   = (op == 6'd0) && (func == 6'b000100);
wire inst_sra    = (op == 6'd0) && (func == 6'b000011);
wire inst_srav   = (op == 6'd0) && (func == 6'b000111);
wire inst_srl    = (op == 6'd0) && (func == 6'b000010);
wire inst_srlv   = (op == 6'd0) && (func == 6'b000110);

wire inst_div    = (op == 6'd0) && (func == 6'b011010);
wire inst_divu   = (op == 6'd0) && (func == 6'b011011);
wire inst_mult   = (op == 6'd0) && (func == 6'b011000);
wire inst_multu  = (op == 6'd0) && (func == 6'b011001);
wire inst_mfhi   = (op == 6'd0) && (func == 6'b010000);
wire inst_mflo   = (op == 6'd0) && (func == 6'b010010);
wire inst_mthi   = (op == 6'd0) && (func == 6'b010001);
wire inst_mtlo   = (op == 6'd0) && (func == 6'b010011);//八个乘除法指令
wire inst_jalr   = (op == 6'd0) && (func == 6'b001001);
wire inst_bgtz   = (op == 6'b000111) && (rt == 5'd0);
wire inst_blez   = (op == 6'b000110) && (rt == 5'd0);
wire inst_bltz   = (op == 6'd1) && (rt == 5'd0);
wire inst_bgez   = (op == 6'd1) && (rt == 5'b00001);
wire inst_bltzal = (op == 6'd1) && (rt == 5'b10000);
wire inst_bgezal = (op == 6'd1) && (rt == 5'b10001);


assign MemToReg   = ~reset &   inst_lw;
assign JSrc       = ~reset &  (inst_jr   | inst_jalr );
assign MemEn      = ~reset &  (inst_sw   | inst_lw   );
assign rs_R = ~reset & ~(inst_j    | inst_jal  );
assign rt_R = ~reset & ~(inst_addi | inst_addiu | inst_slti | inst_sltiu |
                             inst_andi | inst_lui   | inst_ori  | inst_xori  |
                             inst_j    | inst_jal   | inst_lw   | inst_jalr  );

assign is_branch  = inst_bne | inst_blez | inst_bgez | inst_bgezal
                  | inst_beq | inst_bltz | inst_bgtz | inst_bltzal;

assign PCSrc[1]   = ~reset & (is_branch   & BranchCond );
assign PCSrc[0]   = ~reset & (inst_jal    | inst_j     | inst_jr  | inst_jalr );

assign ALUSrcA[1] = ~reset & (inst_sll    | inst_sra   | inst_srl   );
assign ALUSrcA[0] = ~reset & (inst_jal    | inst_jalr  | inst_bltzal|
                            inst_bgezal );

assign ALUSrcB[1] = ~reset & (inst_jal    | inst_ori   | inst_xori   |
                            inst_andi   | inst_jalr  | inst_bgezal |
                            inst_bltzal );
assign ALUSrcB[0] = ~reset & (inst_lw     | inst_sw    | inst_addiu  |
                            inst_slti   | inst_sltiu | inst_lui    |
                            inst_addi   | inst_andi  | inst_ori    |
                            inst_xori   );

assign RegDst[1]  = ~reset & (inst_jal    | inst_bgezal | inst_bltzal );
assign RegDst[0]  = ~reset & (inst_addu   | inst_or     | inst_slt    |
                            inst_sll    | inst_add    | inst_sub    |
                            inst_subu   | inst_sltu   | inst_and    |
                            inst_nor    | inst_xor    | inst_sllv   |
                            inst_sra    | inst_srav   | inst_srl    |
                            inst_srlv   | inst_jalr   | inst_mult   |
                            inst_multu  | inst_div    | inst_divu   |
                            inst_mfhi   | inst_mflo   );

assign RegWrite = {4{~reset & (inst_lw     | inst_addiu  | inst_slti  |
                             inst_sltiu  | inst_lui    | inst_addu  |
                             inst_or     | inst_slt    | inst_sll   |
                             inst_jal    | inst_addi   | inst_andi  |
                             inst_ori    | inst_xori   | inst_add   |
                             inst_sub    | inst_subu   | inst_sltu  |
                             inst_and    | inst_nor    | inst_xor   |
                             inst_sllv   | inst_sra    | inst_srav  |
                             inst_srl    | inst_srlv   | inst_jalr  |
                             inst_bltzal | inst_bgezal | inst_mfhi  |
                             inst_mflo   )}};
assign MemWrite = {4{~reset &  inst_sw}};

// ALUop control signal
assign ALUop[3] = ~reset & (inst_xori | inst_nor  | inst_xor  |
                          inst_sra  | inst_srav | inst_srl  |
                          inst_srlv );

assign ALUop[2] = ~reset & (inst_slti | inst_slt  | inst_sltiu |
                          inst_sll  | inst_sub  | inst_sltu  |
                          inst_sllv | inst_srl  | inst_srlv  |
                          inst_subu);

assign ALUop[1] = ~reset & (inst_lw     | inst_sw   | inst_addiu  |
                          inst_slti   | inst_slt  | inst_lui    |
                          inst_jal    | inst_addu | inst_addi   |
                          inst_xori   | inst_add  | inst_sub    |
                          inst_xor    | inst_sra  | inst_srav   |
                          inst_subu   | inst_jalr | inst_bgezal |
                          inst_bltzal );

assign ALUop[0] = ~reset & (inst_slti  | inst_slt  | inst_or    |
                          inst_lui   | inst_sll  | inst_ori   |
                          inst_nor   | inst_sllv | inst_sra   |
                          inst_srav  );

assign B_Type[0] = inst_bne;
assign B_Type[1] = inst_beq;
assign B_Type[2] = inst_bgez | inst_bgezal;
assign B_Type[3] = inst_bgtz;
assign B_Type[4] = inst_blez;
assign B_Type[5] = inst_bltz | inst_bltzal;

assign MULT[0] = inst_mult;
assign MULT[1] = inst_multu;//两位是为了判断是有符号乘法还是无符号乘法

assign DIV[0] = inst_div;
assign DIV[1] = inst_divu;

assign MFHL[0] = inst_mflo;
assign MFHL[1] = inst_mfhi;

assign MTHL[0] = inst_mtlo;
assign MTHL[1] = inst_mthi;
//乘除的八条指令
endmodule
