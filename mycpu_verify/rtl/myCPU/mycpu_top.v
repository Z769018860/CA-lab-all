`timescale 10ns / 1ns
`define IF    6'b000001
`define IW    6'b000010
`define DE_EX 6'b000100
`define LD    6'b001000
`define ST    6'b010000
`define WB    6'b100000

module mycpu_top(
    input  wire        clk,
    input  wire        resetn,            //low active

    output wire        inst_sram_en,
    output wire [ 3:0] inst_sram_wen,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,

    output wire        data_sram_en,
    output wire [ 3:0] data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,

    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_wen,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

parameter ADDR = 32'hbfc00000;

reg reset;
always @(posedge clk) reset <= ~resetn;

wire         JSrc;
wire [ 1:0] PCSrc;

wire [31:0] seq_pc;
reg [31:0] nextpc;
reg  [31:0] pc;
wire [ 5:0] op;
wire [ 4:0] rs;
wire [ 4:0] rt;
wire [ 4:0] rd;
wire [ 4:0] sa;
wire [ 5:0] func;
wire [15:0] imm;
wire [25:0] jDEx;
wire [63:0] op_d;
wire [63:0] func_d;
wire [31:0] rs_d;
wire [31:0] rt_d;
wire [31:0] rd_d;
wire [31:0] sa_d;
wire [31:0] inst;

wire inst_addu;
wire inst_subu;
wire inst_slt;
wire inst_sltu;
wire inst_and;
wire inst_or;
wire inst_xor;
wire inst_nor;
wire inst_sll;
wire inst_srl;
wire inst_sra;
wire inst_addiu;
wire inst_lui;
wire inst_lw;
wire inst_sw;
wire inst_beq;
wire inst_bne;
wire inst_jal;
wire inst_jr;
//第一阶段19条指令

wire src1_is_sa;
wire src1_is_pc;
wire src2_is_imm;
wire src2_is_8;
wire res_from_mem;
wire dst_is_r31;
wire dst_is_rt;
wire gr_we;
wire mem_we;
wire rf_we;
wire alu_result_zero;
wire branch;

wire [ 4:0] RegRaddr1;
wire [ 4:0] RegRaddr2;
wire [31:0] RegRdata1;
wire [31:0] RegRdata2;

wire [31:0]          PC_IF_DE;
wire [31:0]    PC_add_4_IF_DE;
wire [31:0]        Inst_IF_DE;

wire                  PCWrite;
wire                  IRWrite;

wire [31:0]       J_target_DE;
wire [31:0]      JR_target_DE;
wire [31:0]      Br_target_DE;
wire [31:0]       PC_add_4_DE;

wire [ 1:0]     RegRdata1_src;
wire [ 1:0]     RegRdata2_src;

wire               rs_R;
wire               rt_R;
wire             DE_EX_Stall;

wire [31:0]         PC_DE_EX;
wire [31:0]   PC_add_4_DE_EX;
wire [ 1:0]     RegDst_DE_EX;
wire [ 1:0]    ALUSrcA_DE_EX;
wire [ 1:0]    ALUSrcB_DE_EX;
wire [ 3:0]      ALUop_DE_EX;
wire [ 3:0]   RegWrite_DE_EX;
wire [ 3:0]   MemWrite_DE_EX;
wire             MemEn_DE_EX;
wire          MemToReg_DE_EX;
wire [ 1:0]       MULT_DE_EX; 
wire [ 1:0]        DIV_DE_EX; 
wire [ 1:0]       MFHL_DE_EX; 
wire [ 1:0]       MTHL_DE_EX; 

wire [ 4:0]   RegWaddr_DE_EX;
wire [31:0]     ALUResult_EX;
wire [31:0]     ALUResult_MEM;

wire [31:0]  RegRdata1_DE_EX;
wire [31:0]  RegRdata2_DE_EX;
wire [31:0]         Sa_DE_EX;
wire [31:0]  SgnExtend_DE_EX;
wire [31:0]    ZExtend_DE_EX;

wire            MemEn_EX_MEM;
wire         MemToReg_EX_MEM;
wire [ 3:0]  MemWrite_EX_MEM;
wire [ 3:0]  RegWrite_EX_MEM;
wire [ 4:0]  RegWaddr_EX_MEM;
wire [ 1:0]      MULT_EX_MEM; //mul
wire [ 1:0]      MFHL_EX_MEM; //mul
wire [ 1:0]      MTHL_EX_MEM; //mul
wire [31:0] ALUResult_EX_MEM;
wire [31:0]  MemWdata_EX_MEM;
wire [31:0]        PC_EX_MEM;
wire [31:0] RegRdata1_EX_MEM; //mul

wire          MemToReg_MEM_WB;
wire [ 3:0]   RegWrite_MEM_WB;
wire [ 4:0]   RegWaddr_MEM_WB;
wire [ 1:0]       MFHL_MEM_WB; //mul


wire [31:0]  ALUResult_MEM_WB;
wire [31:0]         PC_MEM_WB;
wire [31:0]             PC_WB;
wire [31:0]       RegWdata_WB;
wire [ 4:0]       RegWaddr_WB;
wire [ 3:0]       RegWrite_WB;


wire [63:0]  MULT_Result;
wire [31:0]  DIV_quotient;
wire [31:0]  DIV_remainder;
wire DIV_Busy;
wire DIV_Done;



wire [31:0] HI_in;
wire [31:0] LO_in;
wire [ 1:0] HILO_Write;
reg  [31:0] HI;
reg  [31:0] LO;
// HILO IO

//assign seq_pc = pc + 4;
//assign nextpc = inst_jal ? {pc[31:28], jDEx, 2'b0} :
//                inst_jr  ? rf_rdata1 :
//                branch   ? (seq_pc + {{14{imm[15]}}, imm[15:0], 2'b0}) :
//                           seq_pc;
//assign alu_result_zero = ~(|alu_result[31:0]);
//assign branch = (inst_beq & alu_result_zero) | (inst_bne & !alu_result_zero);
    
    wire [31:0] Jump_addr, inst_addr;
    assign Jump_addr = JSrc ? JR_target_DE   : J_target_DE; 
    assign inst_sram_addr = PCWrite ? inst_addr : nextpc;
  
    reg [31:0] PC;
    always @(posedge clk) begin
        if(reset) begin
            PC      <= ADDR;
            nextpc <= ADDR;
        end
        else if(PCWrite) begin
            PC      <= inst_addr+4;
            nextpc <= inst_addr;
        end
        else begin
            PC      <= PC;
            nextpc <= nextpc;
        end
    end
     //多位选择器
    MUX_4_32 PCS_MUX(
        .Src1   (         PC),
        .Src2   (  Jump_addr),
        .Src3   (    Br_target_DE),
        .Src4   (      32'd0),
        .op     (      PCSrc),
        .Result (  inst_addr)
    );
    //计算下一个PC
/*
always @(posedge clk)
begin
    if(reset)
        pc <= 32'hbfc00000;
    else if(multi_pc)
        pc <= nextpc;
    else
        pc <= pc;
end
*/
assign inst_sram_en = 1'b1;
assign inst_sram_wen = 4'b0;
//assign inst_sram_addr = pc;
assign inst_sram_wdata = 32'b0;

assign inst = inst_sram_rdata;
assign op   = inst[31:26];
assign rs   = inst[25:21];
assign rt   = inst[20:16];
assign rd   = inst[15:11];
assign sa   = inst[10: 6];
assign func = inst[ 5: 0];
assign imm  = inst[15: 0];
assign jDEx = inst[25: 0];

decoder_6_64 u_dec0(.in(op  ), .out(op_d  ));
decoder_6_64 u_dec1(.in(func), .out(func_d));
decoder_5_32 u_dec2(.in(rs  ), .out(rs_d  ));
decoder_5_32 u_dec3(.in(rt  ), .out(rt_d  ));
decoder_5_32 u_dec4(.in(rd  ), .out(rd_d  ));
decoder_5_32 u_dec5(.in(sa  ), .out(sa_d  ));

assign inst_addu  = op_d[6'h00] & func_d[6'h21] & sa_d[5'h00];
assign inst_subu  = op_d[6'h00] & func_d[6'h23] & sa_d[5'h00];
assign inst_slt   = op_d[6'h00] & func_d[6'h2a] & sa_d[5'h00];
assign inst_sltu  = op_d[6'h00] & func_d[6'h2b] & sa_d[5'h00];
assign inst_and   = op_d[6'h00] & func_d[6'h24] & sa_d[5'h00];
assign inst_or    = op_d[6'h00] & func_d[6'h25] & sa_d[5'h00];
assign inst_xor   = op_d[6'h00] & func_d[6'h26] & sa_d[5'h00];
assign inst_nor   = op_d[6'h00] & func_d[6'h27] & sa_d[5'h00];
assign inst_sll   = op_d[6'h00] & func_d[6'h00] & rs_d[5'h00];
assign inst_srl   = op_d[6'h00] & func_d[6'h02] & rs_d[5'h00];
assign inst_sra   = op_d[6'h00] & func_d[6'h03] & rs_d[5'h00];
assign inst_addiu = op_d[6'h09];
assign inst_lui   = op_d[6'h0f] & rs_d[5'h00];
assign inst_lw    = op_d[6'h23];
assign inst_sw    = op_d[6'h2b];
assign inst_beq   = op_d[6'h04];
assign inst_bne   = op_d[6'h05];
assign inst_jal   = op_d[6'h03];
assign inst_jr    = op_d[6'h00] & func_d[6'h08] & rt_d[5'h00] & rd_d[5'h00] & sa_d[5'h00];
//初始19条指令,通过译码

assign src1_is_sa   = inst_sll | inst_srl | inst_sra;
assign src1_is_pc   = inst_jal;
assign src2_is_imm  = inst_lui | inst_lw  | inst_sw  | inst_addiu;
assign src2_is_8    = inst_jal;
assign dst_is_r31   = inst_jal;
assign dst_is_rt    = inst_lui | inst_lw  | inst_addiu;
assign gr_we        = ~inst_sw & ~inst_beq & ~inst_bne & ~inst_jr;
assign res_from_mem = inst_lw;
assign mem_we       = inst_sw;

//---regfile
//assign rf_waddr     = dst_is_r31 ? 5'd31 :
//                      dst_is_rt  ? rt    :
//					               rd;
//assign rf_raddr1    = rs;
//assign rf_raddr2    = rt;
//assign rf_wdata     = res_from_mem ? data_sram_rdata : alu_result;
//assign rf_we        = gr_we & multi_rf;

//---alu
/*assign alu_src1     = src1_is_sa ? {27'b0, sa} :
                      src1_is_pc ? pc :
                                   rf_rdata1;
assign alu_src2     = src2_is_8   ? 8 :
                      src2_is_imm ? {{16{imm[15]}}, imm} :
                                    rf_rdata2;
assign alu_op[ 0] = inst_addu | inst_addiu | inst_lw | inst_sw | inst_jal;
assign alu_op[ 1] = inst_subu | inst_beq | inst_bne;
assign alu_op[ 2] = inst_slt;
assign alu_op[ 3] = inst_sltu;
assign alu_op[ 4] = inst_and;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or;
assign alu_op[ 7] = inst_xor;
assign alu_op[ 8] = inst_sll;
assign alu_op[ 9] = inst_srl;
assign alu_op[10] = inst_sra;
assign alu_op[11] = inst_lui;*/

//---datamem
//assign data_sram_en    = (res_from_mem & multi_load) | (mem_we & multi_store);
//assign data_sram_wen   = {4{mem_we & multi_store}};
//assign data_sram_addr  = alu_result;
//assign data_sram_wdata = rf_rdata2;
//alu
//    u_alu(
//        .alu_control (alu_op     ),
//        .alu_src1    (alu_src1   ),
//        .alu_src2    (alu_src2   ),
//        .alu_result  (alu_result )
//    );
//---debug
//assign debug_wb_pc       = PC_WB;
//assign debug_wb_rf_wen   = {4{rf_we}};
//assign debug_wb_rf_wnum  = rf_waddr;
//assign debug_wb_rf_wdata = rf_wdata;

//---Multicycle
/*reg [5:0] current_state;
reg [5:0] next_state;
wire multi_pc;
wire multi_inst;
wire multi_load;
wire multi_store;
wire multi_rf;

always @(posedge clk or posedge resetn)
begin
    if(!resetn)
        current_state <= `IF;
    else
        current_state <= next_state;
end

always @*
begin
    case(current_state)
    `IF:
        next_state <= `IW;
    `IW:
        next_state <= `DE_EX;
    `DE_EX:
        next_state <= inst_lw ? `LD :
                      inst_sw ? `ST :
                      (inst_beq | inst_bne)  ? `IF : //?JR
                                   `WB ; 
    `ST:
        next_state <= `IF;
    `LD:
        next_state <= `WB;
    `WB:
        next_state <= `IF;
    default:
        next_state <= `IF;
    endcase
end
//多周期状态转换
*/

fetch 
    fe_stage(
    .clk               (              clk), // I  1
    .reset             (            reset), // I  1
    .IRWrite           (          IRWrite), // I  1
    .nextpc            (           nextpc), // I 32
    .inst_sram_en      (     inst_sram_en), // O  1
    .inst_sram_rdata   (  inst_sram_rdata), // I 32
    .PC_IF_DE          (         PC_IF_DE), // O 32
    .PC_add_4_IF_DE    (   PC_add_4_IF_DE), // O 32
    .Inst_IF_DE        (       Inst_IF_DE)  // O 32
  );


decode 
    DE_stage(
    .clk               (              clk), // I  1
    .reset             (            reset), // I  1
    .Inst_IF_DE        (       Inst_IF_DE), // I 32
    .PC_IF_DE          (         PC_IF_DE), // I 32
    .PC_add_4_IF_DE    (   PC_add_4_IF_DE), // I 32
    .RegRaddr1_DE      (        RegRaddr1), // O  5
    .RegRaddr2_DE      (        RegRaddr2), // O  5
    .RegRdata1_DE      (        RegRdata1), // I 32
    .RegRdata2_DE      (        RegRdata2), // I 32
    .ALUResult_EX      (     ALUResult_EX), // I 32 Bypass
    .ALUResult_MEM     (    ALUResult_MEM), // I 32 Bypass
    .RegWdata_WB       (      RegWdata_WB), // I 32 Bypass
    .MULT_Result       (      MULT_Result), // I 64 Bypass new
    .HI                (           HI), // I 32 Bypass new
    .LO                (           LO), // I 32 Bypass new
    .MFHL_DE_EX_1      (      MFHL_DE_EX), // I  2 Bypass new
    .MFHL_EX_MEM       (     MFHL_EX_MEM), // I  2 Bypass new
    .MFHL_MEM_WB       (      MFHL_MEM_WB), // I  2 Bypass new
    .MULT_EX_MEM       (     MULT_EX_MEM), // I  2 Bypass new
    .RegRdata1_src     (    RegRdata1_src), // I  2 Bypass
    .RegRdata2_src     (    RegRdata2_src), // I  2 Bypass
    .DE_EX_Stall       (     DE_EX_Stall), // I  1 Stall
    .DIV_Done          (         DIV_Done), // I  1 Stall
    .JSrc              (             JSrc), // O  1
    .PCSrc             (            PCSrc), // O  2
    .J_target_DE       (      J_target_DE), // O 32
    .JR_target_DE      (     JR_target_DE), // O 32
    .Br_target_DE      (     Br_target_DE), // O 32
//    .RegDst_DE_EX     (    RegDst_DE_EX), // O  2
    .ALUSrcA_DE_EX    (   ALUSrcA_DE_EX), // O  2
    .ALUSrcB_DE_EX    (   ALUSrcB_DE_EX), // O  2
    .ALUop_DE_EX      (     ALUop_DE_EX), // O  4
    .RegWrite_DE_EX   (  RegWrite_DE_EX), // O  4
    .MemWrite_DE_EX   (  MemWrite_DE_EX), // O  4
    .MemEn_DE_EX      (     MemEn_DE_EX), // O  1
    .MemToReg_DE_EX   (  MemToReg_DE_EX), // O  1
    .MULT_DE_EX       (      MULT_DE_EX), // O  2 new
    .DIV_DE_EX        (       DIV_DE_EX), // O  2 new
    .MFHL_DE_EX       (      MFHL_DE_EX), // O  2 new
    .MTHL_DE_EX       (      MTHL_DE_EX), // O  2 new
//    .Rt_DE_EX         (        Rt_DE_EX), // O  5
//    .Rd_DE_EX         (        Rd_DE_EX), // O  5
    .RegWaddr_DE_EX   (  RegWaddr_DE_EX), // O  5
    .PC_add_4_DE_EX   (  PC_add_4_DE_EX), // O 32
    .PC_DE_EX         (        PC_DE_EX), // O 32
    .RegRdata1_DE_EX  ( RegRdata1_DE_EX), // O 32
    .RegRdata2_DE_EX  ( RegRdata2_DE_EX), // O 32
    .Sa_DE_EX         (        Sa_DE_EX), // O 32
    .SgnExtend_DE_EX  ( SgnExtend_DE_EX), // O 32
    .ZExtend_DE_EX    (   ZExtend_DE_EX), // O 32

    .rs_R_DE     (       rs_R),
    .rt_R_DE     (       rt_R)
  );


execute 
    EX_stage(
    .clk               (              clk), // I  1
    .reset            (              reset), // I  1
    .PC_add_4_DE_EX   (  PC_add_4_DE_EX), // I 32
    .PC_DE_EX         (        PC_DE_EX), // I 32
    .RegRdata1_DE_EX  ( RegRdata1_DE_EX), // I 32
    .RegRdata2_DE_EX  ( RegRdata2_DE_EX), // I 32
    .Sa_DE_EX         (        Sa_DE_EX), // I 32
    .SgnExtend_DE_EX  ( SgnExtend_DE_EX), // I 32
    .ZExtend_DE_EX    (   ZExtend_DE_EX), // I 32
    .RegWaddr_DE_EX   (  RegWaddr_DE_EX), // I  5
    .MemEn_DE_EX      (     MemEn_DE_EX), // I  1
    .MemToReg_DE_EX   (  MemToReg_DE_EX), // I  1
    .ALUSrcA_DE_EX    (   ALUSrcA_DE_EX), // I  2
    .ALUSrcB_DE_EX    (   ALUSrcB_DE_EX), // I  2
    .ALUop_DE_EX      (     ALUop_DE_EX), // I  4
    .MemWrite_DE_EX   (  MemWrite_DE_EX), // I  4
    .RegWrite_DE_EX   (  RegWrite_DE_EX), // I  4
    .MULT_DE_EX       (      MULT_DE_EX), // I  2 new
    .MFHL_DE_EX       (      MFHL_DE_EX), // I  2 new
    .MTHL_DE_EX       (      MTHL_DE_EX), // I  2 new
    .MemEn_EX_MEM     (    MemEn_EX_MEM), // O  1
    .MemToReg_EX_MEM  ( MemToReg_EX_MEM), // O  1
    .MemWrite_EX_MEM  ( MemWrite_EX_MEM), // O  4
    .RegWrite_EX_MEM  ( RegWrite_EX_MEM), // O  4
    .MULT_EX_MEM      (     MULT_EX_MEM), // O  2 new
    .MFHL_EX_MEM      (     MFHL_EX_MEM), // O  2 new
    .MTHL_EX_MEM      (     MTHL_EX_MEM), // O  2 new
    .RegWaddr_EX_MEM  ( RegWaddr_EX_MEM), // O  5
    .ALUResult_EX_MEM (ALUResult_EX_MEM), // O 32
    .MemWdata_EX_MEM  ( MemWdata_EX_MEM), // O 32
    .PC_EX_MEM        (       PC_EX_MEM), // O 32
    .RegRdata1_EX_MEM (RegRdata1_EX_MEM), // O 32 new
    .ALUResult_EX     (    ALUResult_EX)  // O 32
    );


memory 
    mem_stage(
    .clk               (              clk), // I  1
    .reset             (            reset), // I  1
    .MemEn_EX_MEM     (    MemEn_EX_MEM), // I  1
    .MemToReg_EX_MEM  ( MemToReg_EX_MEM), // I  1
    .MemWrite_EX_MEM  ( MemWrite_EX_MEM), // I  4
    .RegWrite_EX_MEM  ( RegWrite_EX_MEM), // I  4
    .RegWaddr_EX_MEM  ( RegWaddr_EX_MEM), // I  5
    .ALUResult_EX_MEM (ALUResult_EX_MEM), // I 32
    .MemWdata_EX_MEM  ( MemWdata_EX_MEM), // I 32
    .PC_EX_MEM        (       PC_EX_MEM), // I 32
    .MFHL_EX_MEM      (     MFHL_EX_MEM), // I  2 new
    .MemEn_MEM         (     data_sram_en), // O  1
    .MemWrite_MEM      (    data_sram_wen), // O  4
    .data_sram_addr    (   data_sram_addr), // O 32
//    .data_sram_rdata   (  data_sram_rdata), // I 32
    .MemWdata_MEM      (  data_sram_wdata), // O 32
    .MemToReg_MEM_WB   (  MemToReg_MEM_WB), // O  1
    .RegWrite_MEM_WB   (  RegWrite_MEM_WB), // O  4
    .RegWaddr_MEM_WB   (  RegWaddr_MEM_WB), // O  5
    .ALUResult_MEM_WB  ( ALUResult_MEM_WB), // O 32
    .PC_MEM_WB         (        PC_MEM_WB), // O 32
    .MFHL_MEM_WB       (      MFHL_MEM_WB), // O  2 new
//    .MemRdata_MEM_WB   (  MemRdata_MEM_WB)  // O 32
    .ALUResult_MEM     (    ALUResult_MEM)
  );


writeback 
    wb_stage(
    .clk               (              clk), // I  1
    .reset             (              reset), // I  1
    .MemToReg_MEM_WB   (  MemToReg_MEM_WB), // I  1
    .RegWrite_MEM_WB   (  RegWrite_MEM_WB), // I  4
    .MFHL_MEM_WB       (      MFHL_MEM_WB), // I  2 new
    .RegWaddr_MEM_WB   (  RegWaddr_MEM_WB), // I  5
    .ALUResult_MEM_WB  ( ALUResult_MEM_WB), // I 32
    .MemRdata_MEM_WB   (  data_sram_rdata), // I 32
    .PC_MEM_WB         (        PC_MEM_WB), // I 32
    .HI_MEM_WB         (           HI), // I 32 new
    .LO_MEM_WB         (           LO), // I 32 new
    .RegWdata_WB       (      RegWdata_WB), // O 32
    .RegWaddr_WB       (      RegWaddr_WB), // O  5
    .RegWrite_WB       (      RegWrite_WB), // O  4
    .PC_WB             (            PC_WB)  // O 32
);

bypass 
    bypass_unit(
    .clk                (              clk),
    .reset              (              reset),
    // input IR recognize signals from Control Unit
    .rs_R         (       rs_R),
    .rt_R         (       rt_R),
    // Judge whether the instruction is LW
    .MemToReg_DE_EX    (  MemToReg_DE_EX),
    .MemToReg_EX_MEM   ( MemToReg_EX_MEM),
    .MemToReg_MEM_WB    (  MemToReg_MEM_WB),
    // Reg Write address in afterward stage
    .RegWaddr_EX_MEM   ( RegWaddr_EX_MEM),
    .RegWaddr_MEM_WB    (  RegWaddr_MEM_WB),
    .RegWaddr_DE_EX    (  RegWaddr_DE_EX),
    // Reg read address in DE stage
    .rs_DE              (Inst_IF_DE[25:21]),
    .rt_DE              (Inst_IF_DE[20:16]),
    // Reg write data in afterward stage
    .RegWrite_DE_EX    (  RegWrite_DE_EX),
    .RegWrite_EX_MEM   ( RegWrite_EX_MEM),
    .RegWrite_MEM_WB    (  RegWrite_MEM_WB),

    .DIV_Busy           (         DIV_Busy),
    .DIV                (      |DIV_DE_EX),
    // output the stall signals
    .PCWrite            (          PCWrite),
    .IRWrite            (          IRWrite),
    .DE_EX_Stall       (     DE_EX_Stall),
    // output the real read data in DE stage
    .RegRdata1_src      (    RegRdata1_src),
    .RegRdata2_src      (    RegRdata2_src)
);
//旁路模块，处理相关问题

reg_file RegFile(
    .clk               (              clk), // I  1
    .rst             (            reset), // I  1
    .waddr             (      RegWaddr_WB), // I  5
    .raddr1            (        RegRaddr1), // I  5
    .raddr2            (        RegRaddr2), // I  5
    .wen               (      RegWrite_WB), // I  4
    .wdata             (      RegWdata_WB), // I 32
    .rdata1            (        RegRdata1), // O 32
    .rdata2            (        RegRdata2)  // O 32
);
//乘法器，booth华莱士树算法
multiplyer mul(
    .x          (RegRdata1_DE_EX),
    .y          (RegRdata2_DE_EX),
    .mul_clk    (clk),
    .resetn     (resetn),
    .mul_signed (MULT_DE_EX[0]&~MULT_DE_EX[1]),
    .result     (MULT_Result)
);
//除法器，迭代算法
divider div(
    .clk                (clk),//I  1
    .reset              (reset),//I  1
    .x                  (RegRdata1_DE_EX),//I  32
    .y                  (RegRdata2_DE_EX),//I  32
    .div                (|DIV_DE_EX),//I  1
    .div_signed         (DIV_DE_EX[0]&~DIV_DE_EX[1]),//I  1
    .result_q           (DIV_quotient),//O  32
    .result_r           (DIV_remainder),//O  32
    .busy               (DIV_Busy),//O  1
    .done               (DIV_Done)//O  1
);

//HILO part

assign HI_in = |MULT_EX_MEM    ? MULT_Result[63:32] :
                MTHL_EX_MEM[1] ? RegRdata1_EX_MEM  :
                DIV_Done    ? DIV_remainder      : 'd0;
assign LO_in = |MULT_EX_MEM    ? MULT_Result[31: 0] :
                MTHL_EX_MEM[0] ? RegRdata1_EX_MEM  :
                DIV_Done    ? DIV_quotient       : 'd0;
assign HILO_Write[1] = |MULT_EX_MEM | DIV_Done | MTHL_EX_MEM[1];
assign HILO_Write[0] = |MULT_EX_MEM | DIV_Done | MTHL_EX_MEM[0];

always @ (posedge clk) 
begin
        if (reset) 
        begin
            HI <= 32'd0;
            LO <= 32'd0;
        end
        else 
        begin
            if (HILO_Write[1]) HI <= HI_in;
            else               HI <= HI;
            if (HILO_Write[0]) LO <= LO_in;
            else               LO <= LO;
        end
end

assign debug_wb_pc       = PC_WB;
assign debug_wb_rf_wen   = RegWrite_WB;
assign debug_wb_rf_wnum  = RegWaddr_WB;
assign debug_wb_rf_wdata = RegWdata_WB;
//debug信号，均为写回级
endmodule //mycpu_top

//两个选择器模块
module MUX_4_32(
    input  [31:0] Src1,
    input  [31:0] Src2,
    input  [31:0] Src3,
    input  [31:0] Src4,
    input  [ 1:0] op,
    output [31:0] Result
);
    wire [31:0] and1, and2, and3, and4, op1, op1x, op0, op0x;

    assign op1  = {32{ op[1]}};
    assign op1x = {32{~op[1]}};
    assign op0  = {32{ op[0]}};
    assign op0x = {32{~op[0]}};
    assign and1 = Src1   & op1x & op0x;
    assign and2 = Src2   & op1x & op0;
    assign and3 = Src3   & op1  & op0x;
    assign and4 = Src4   & op1  & op0;

    assign Result = and1 | and2 | and3 | and4;

endmodule

module MUX_3_5(
    input  [4:0] Src1,
    input  [4:0] Src2,
    input  [4:0] Src3,
    input  [1:0] op,
    output [4:0] Result
);
    wire [4:0] and1, and2, and3, op1, op1x, op0, op0x;

	  assign op1  = {5{ op[1]}};
    assign op1x = {5{~op[1]}};
    assign op0  = {5{ op[0]}};
    assign op0x = {5{~op[0]}};
    assign and1 = Src1   & op1x & op0x;
    assign and2 = Src2   & op1x & op0;
    assign and3 = Src3   & op1  & op0x;

    assign Result = and1 | and2 | and3;
endmodule

module branch(
    input [31:0] A,
    input [31:0] B,
    input [ 5:0] B_Type,   //blt ble bgt bge beq bne
    output       Cond
);
	wire zero, ge, gt, le, lt;
    alu Zero(
        .A     (      A),
        .B     (      B),
        .ALUop (4'b0110),   //SUB
        .Zero  (   zero)
    );
    assign ge = ~A[31];
    assign gt = ~A[31] &    |A[30:0];
    assign le =  A[31] | (&(~A[31:0]));
    assign lt =  A[31];

    assign Cond = B_Type[0] & ~zero |
                  B_Type[1] &  zero |
                  B_Type[2] &    ge |
                  B_Type[3] &    gt |
                  B_Type[4] &    le |
                  B_Type[5] &    lt;

endmodule