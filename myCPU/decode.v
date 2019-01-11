
`timescale 10ns / 1ns
module decode(
    input  wire                     clk,
    input  wire                     rst,
    // data passing from IF stage
    input  wire [31:0]       Inst_IF_DE,
    input  wire [31:0]         PC_IF_DE,
    input  wire [31:0]   PC_add_4_IF_DE,
    input  wire           PC_AdEL_IF_DE,  // new   
    input  wire               DSI_IF_DE,  // delay slot instruction tag 
    // interaction with the Register files
    output wire [ 4:0]     RegRaddr1_DE,
    output wire [ 4:0]     RegRaddr2_DE,
    input  wire [31:0]     RegRdata1_DE,
    input  wire [31:0]     RegRdata2_DE,
    // siganls input from execute stage
    input  wire        ex_int_handle_DE,
    //input  wire [31:0]      cp0Rdata_DE,
    // control signals passing to Bypass unit
    input  wire [31:0]       Bypass_EX,
    input  wire [31:0]       Bypass_MEM,
    input  wire [31:0]      RegWdata_WB,
    input  wire [63:0]      MULT_Result,
    input  wire [31:0]               HI,
    input  wire [31:0]               LO,
    // regdata passed back
    input  wire [ 1:0]     MFHL_DE_EX_1,
    input  wire [ 1:0]     MFHL_EX_MEM,
    input  wire [ 1:0]     MFHL_MEM_WB,
    input  wire [ 1:0]     MULT_EX_MEM,

    input  wire [ 1:0]     RegRdata1_src,
    input  wire [ 1:0]     RegRdata2_src,
    input  wire             DE_EX_Stall,
    input  wire             DIV_Done,
    // control signals from bypass module
    output wire                    JSrc,
    output wire [ 1:0]            PCSrc,
    // data passing to PC calculate module
    output wire [31:0]      J_target_DE,
    output wire [31:0]     JR_target_DE,
    output wire [31:0]     Br_target_DE,
    // control signals passing to EXE stage
    output reg  [ 1:0]   ALUSrcA_DE_EX,
    output reg  [ 1:0]   ALUSrcB_DE_EX,
    output reg  [ 3:0]     ALUop_DE_EX,
    output reg  [ 3:0]  RegWrite_DE_EX,
    output reg  [ 3:0]  MemWrite_DE_EX,
    output reg             MemEn_DE_EX,
    output reg          MemToReg_DE_EX,
    output reg  [ 1:0]      MULT_DE_EX,
    output reg  [ 1:0]       DIV_DE_EX,
    output reg  [ 1:0]      MFHL_DE_EX,
    output reg  [ 1:0]      MTHL_DE_EX,
    output reg                LB_DE_EX,  
    output reg               LBU_DE_EX,  
    output reg                LH_DE_EX,  
    output reg               LHU_DE_EX,  
    output reg  [ 1:0]        LW_DE_EX,  
    output reg  [ 1:0]        SW_DE_EX,  
    output reg                SB_DE_EX,  
    output reg                SH_DE_EX,  
    output reg              mfc0_DE_EX,
    output reg         cp0_Write_DE_EX,  // NEW
    output reg         is_signed_DE_EX,  // new
    output reg               DSI_DE_EX,  // delay slot instruction
    output reg              eret_DE_EX,
    // Exception vecter achieved in decode stage
    // Exc_vec_DE_EX[3]: PC_AdEL
    // Exc_vec_DE_EX[2]: Reserved Instruction
    // Exc_vec_DE_EX[1]: syscall
    // Exc_vec_DE_EX[0]: breakpoint
    output reg  [ 3:0]   Exc_vec_DE_EX,  
    // data transfering to EXE stage
    output reg  [ 4:0]        Rd_DE_EX,
    output reg  [ 4:0]  RegWaddr_DE_EX,
    output reg  [31:0]  PC_add_4_DE_EX,
    output reg  [31:0]        PC_DE_EX,
    output reg  [31:0] RegRdata1_DE_EX,
    output reg  [31:0] RegRdata2_DE_EX,
    output reg  [31:0]        Sa_DE_EX,
    output reg  [31:0] SgnExtend_DE_EX,
    output reg  [31:0]   ZExtend_DE_EX,

    
  //  output reg  [31:0]  cp0Rdata_DE_EX,

    output            is_j_or_br_DE,
    output            is_rs_read_DE,
    output            is_rt_read_DE,

    input             ex_int_handling,
    input             eret_handling,
 
    output              de_to_exe_valid,   
    output               decode_allowin,
    input                   exe_allowin,
    input                fe_to_de_valid,

    output               exe_refresh,
    output               decode_stage_valid
  );

    reg  decode_valid;
    wire decode_ready_go;

    assign decode_ready_go = !DE_EX_Stall;
    assign decode_allowin = !decode_valid || exe_allowin && decode_ready_go;
    assign de_to_exe_valid = decode_valid&&decode_ready_go;

    always @ (posedge clk) begin
        if (rst) begin
            decode_valid <= 1'b0;
        end
        else if (decode_allowin) begin
            decode_valid <= fe_to_de_valid;
        end
    end
    assign decode_stage_valid = decode_valid;

    assign exe_refresh = de_to_exe_valid&&exe_allowin;

    wire                    eret_DE; 
    wire                  cp0_Write;
    wire              BranchCond_DE;
//    wire                    Zero_DE;
    wire                MemToReg_DE;
    wire                    JSrc_DE;
    wire                   MemEn_DE;
    wire [ 1:0]          ALUSrcA_DE;
    wire [ 1:0]          ALUSrcB_DE;
    wire [ 1:0]           RegDst_DE;
    wire [ 1:0]            PCSrc_DE;
    wire [ 3:0]            ALUop_DE;
    wire [ 3:0]         MemWrite_DE;
    wire [ 3:0]         RegWrite_DE;
    wire [31:0]        SgnExtend_DE;
    wire [31:0]          ZExtend_DE;
    wire [31:0]    SgnExtend_LF2_DE;
    wire [31:0]         PC_add_4_DE;
    wire [31:0]               Sa_DE;
    wire [31:0]               PC_DE;
    wire [ 4:0]         RegWaddr_DE;
    wire [ 5:0]           B_Type_DE;
    wire [ 1:0]             MULT_DE;
    wire [ 1:0]              DIV_DE;
    wire [ 1:0]             MFHL_DE;
    wire [ 1:0]             MTHL_DE;
    wire                      LB_DE;
    wire                     LBU_DE;
    wire                      LH_DE;
    wire                     LHU_DE;
    wire [ 1:0]               LW_DE;
    wire [ 1:0]               SW_DE;
    wire                      SB_DE;
    wire                      SH_DE;
    wire                    mfc0_DE;
    wire               is_signed_DE; // p4 new
    wire                      RI_DE;
    wire                     sys_DE;
    wire                      bp_DE;
    wire [31:0]  RegRdata1_Final_DE;
    wire [31:0]  RegRdata2_Final_DE;
    wire [ 3:0]          Exc_vec_DE;


    wire [ 4:0]  rs,rt,sa,rd;

    wire [31:0]  DE_EX_data;
    wire [31:0] EX_MEM_data;
    wire [31:0]  MEM_WB_data;
    

    assign Exc_vec_DE = {PC_AdEL_IF_DE,RI_DE,sys_DE,bp_DE};

    assign rs = Inst_IF_DE[25:21];
    assign rt = Inst_IF_DE[20:16];
    assign rd = Inst_IF_DE[15:11];
    assign sa = Inst_IF_DE[10: 6];
    // interaction with Register files
    // tell read address to Register files
    assign RegRaddr1_DE = Inst_IF_DE[25:21];
    assign RegRaddr2_DE = Inst_IF_DE[20:16];
    // datapath
    assign     SgnExtend_DE = {{16{Inst_IF_DE[15]}},Inst_IF_DE[15:0]};
    assign       ZExtend_DE = {{16'd0},Inst_IF_DE[15:0]};
    assign            Sa_DE = {{27{1'b0}}, Inst_IF_DE[10: 6]};
    assign SgnExtend_LF2_DE = SgnExtend_DE << 2;
    // signals passing to PC calculate module
    assign  JSrc =  JSrc_DE & ~(ex_int_handling|eret_handling);
    assign PCSrc = PCSrc_DE & {2{~(ex_int_handling|eret_handling)}};
    // data passing to PC calculate module
    assign  J_target_DE = {{PC_IF_DE[31:28]},{Inst_IF_DE[25:0]},{2'b00}};
    assign JR_target_DE = RegRdata1_Final_DE;
    assign Br_target_DE = PC_add_4_DE + SgnExtend_LF2_DE;
    assign        PC_DE = PC_IF_DE;
    assign  PC_add_4_DE = PC_add_4_IF_DE;

    always @ (posedge clk) begin
        if (rst) begin
            {  
                 MemEn_DE_EX,  MemToReg_DE_EX,     ALUop_DE_EX, RegWrite_DE_EX, 
              MemWrite_DE_EX,   ALUSrcA_DE_EX,   ALUSrcB_DE_EX,     MULT_DE_EX, 
                   DIV_DE_EX,      MFHL_DE_EX,      MTHL_DE_EX,       LB_DE_EX,
                   LBU_DE_EX,        LH_DE_EX,       LHU_DE_EX,       LW_DE_EX, 
                    SW_DE_EX,        SB_DE_EX,        SH_DE_EX,     mfc0_DE_EX,
              RegWaddr_DE_EX,        Sa_DE_EX,        PC_DE_EX, PC_add_4_DE_EX, 
             RegRdata1_DE_EX, RegRdata2_DE_EX, SgnExtend_DE_EX,  ZExtend_DE_EX, 
             is_signed_DE_EX,       DSI_DE_EX,   Exc_vec_DE_EX,     eret_DE_EX,
                    Rd_DE_EX, cp0_Write_DE_EX
            } <= 'd0;
        end
        else begin
            if (de_to_exe_valid&&exe_allowin) begin
                  // control signals passing to EXE stage
                  MemEn_DE_EX  <=           MemEn_DE;
               MemToReg_DE_EX  <=        MemToReg_DE;
                  ALUop_DE_EX  <=           ALUop_DE;
               RegWrite_DE_EX  <=        RegWrite_DE;
               MemWrite_DE_EX  <=        MemWrite_DE;
                ALUSrcA_DE_EX  <=         ALUSrcA_DE;
                ALUSrcB_DE_EX  <=         ALUSrcB_DE;
                   MULT_DE_EX  <=            MULT_DE;
                    DIV_DE_EX  <=             DIV_DE;
                   MFHL_DE_EX  <=            MFHL_DE;
                   MTHL_DE_EX  <=            MTHL_DE;
                     LB_DE_EX  <=              LB_DE;
                    LBU_DE_EX  <=             LBU_DE;
                     LH_DE_EX  <=              LH_DE;
                    LHU_DE_EX  <=             LHU_DE;
                     LW_DE_EX  <=              LW_DE;
                     SW_DE_EX  <=              SW_DE;
                     SB_DE_EX  <=              SB_DE;
                     SH_DE_EX  <=              SH_DE;
                   mfc0_DE_EX  <=            mfc0_DE;
              is_signed_DE_EX  <=       is_signed_DE;
                Exc_vec_DE_EX  <=         Exc_vec_DE;
              cp0_Write_DE_EX  <=          cp0_Write;
                    // delay slot 
                    DSI_DE_EX  <=          DSI_IF_DE;
                   eret_DE_EX  <=            eret_DE;
              // data transfering to EXE stage
                     Rd_DE_EX  <=                 rd;
               RegWaddr_DE_EX  <=        RegWaddr_DE;
                     Sa_DE_EX  <=              Sa_DE;
                     PC_DE_EX  <=           PC_IF_DE;
               PC_add_4_DE_EX  <=     PC_add_4_IF_DE;
              RegRdata1_DE_EX  <= RegRdata1_Final_DE;
              RegRdata2_DE_EX  <= RegRdata2_Final_DE;
              SgnExtend_DE_EX  <=       SgnExtend_DE;
                ZExtend_DE_EX  <=         ZExtend_DE;
              // cp0Rdata_DE_EX  <=        cp0Rdata_DE;
            end
        end
    end

    branch Branch_Cond(
        .A           ( RegRdata1_Final_DE),
        .B           ( RegRdata2_Final_DE),
        .B_Type      (          B_Type_DE),
        .Cond        (      BranchCond_DE)
    );
    control Control(
        .rst         (                rst),
        .BranchCond  (      BranchCond_DE),
        .op          (  Inst_IF_DE[31:26]),
        .func        (  Inst_IF_DE[ 5: 0]),
        .rs          (  Inst_IF_DE[25:21]),
        .rt          (                 rt),
        .MemEn       (           MemEn_DE),
        .JSrc        (            JSrc_DE),
        .MemToReg    (        MemToReg_DE),
        .ALUop       (           ALUop_DE),
        .PCSrc       (           PCSrc_DE),
        .RegDst      (          RegDst_DE),
        .RegWrite    (        RegWrite_DE),
        .MemWrite    (        MemWrite_DE),
        .ALUSrcA     (         ALUSrcA_DE),
        .ALUSrcB     (         ALUSrcB_DE),
        .is_rs_read  (      is_rs_read_DE),
        .is_rt_read  (      is_rt_read_DE),
        .B_Type      (          B_Type_DE),
        .MULT        (            MULT_DE),
        .DIV         (             DIV_DE),
        .MFHL        (            MFHL_DE),
        .MTHL        (            MTHL_DE),
        .LB          (              LB_DE),
        .LBU         (             LBU_DE),
        .LH          (              LH_DE),
        .LHU         (             LHU_DE),
        .LW          (              LW_DE),
        .SW          (              SW_DE),
        .SB          (              SB_DE),
        .SH          (              SH_DE),
        .mfc0        (            mfc0_DE),
//        .trap        (            trap_DE),
        .eret        (            eret_DE),
        .cp0_Write   (          cp0_Write),
        .is_signed   (       is_signed_DE),
        .ri          (              RI_DE),
        .is_j_or_br  (      is_j_or_br_DE),
        .sys         (             sys_DE),
        .bp          (              bp_DE)
    );
    MUX_4_32 RegRdata1_MUX(
        .Src1        (       RegRdata1_DE),
        .Src2        (        DE_EX_data),
        .Src3        (       EX_MEM_data),
        .Src4        (        MEM_WB_data),
        .op          (      RegRdata1_src),
        .Result      ( RegRdata1_Final_DE)
    );
    MUX_4_32 RegRdata2_MUX(
        .Src1        (       RegRdata2_DE),
        .Src2        (        DE_EX_data),
        .Src3        (       EX_MEM_data),
        .Src4        (        MEM_WB_data),
        .op          (      RegRdata2_src),
        .Result      ( RegRdata2_Final_DE)
    );
    MUX_3_5 RegWaddr_MUX(
        .Src1        (                 rt),
        .Src2        (                 rd),
        .Src3        (           5'b11111),
        .op          (          RegDst_DE),
        .Result      (        RegWaddr_DE)
    );
  wire [31:0] MULT_HI_LO = {32{MFHL_DE_EX_1[1]}}  & MULT_Result[63:32] | 
                           {32{MFHL_DE_EX_1[0]}}  & MULT_Result[31: 0] ;
  wire [31:0]  EX_HI_LO = {32{MFHL_DE_EX_1[1]}}  &         HI         | 
                           {32{MFHL_DE_EX_1[0]}}  &         LO         ;
  wire [31:0]  MEM_HI_LO = {32{MFHL_EX_MEM[1]}}   &         HI         | 
                           {32{MFHL_EX_MEM[0]}}   &         LO         ;
  wire [31:0]   WB_HI_LO = {32{MFHL_MEM_WB[1]}}    &         HI         |
                           {32{MFHL_MEM_WB[0]}}    &         LO         ;

  assign DE_EX_data  =  |MFHL_DE_EX  ? (MULT_EX_MEM ? MULT_HI_LO : EX_HI_LO) : Bypass_EX;
  assign EX_MEM_data =  |MFHL_EX_MEM ? MEM_HI_LO : Bypass_MEM;
  assign MEM_WB_data  =  |MFHL_MEM_WB  ?  WB_HI_LO : RegWdata_WB;

endmodule // decode_stage
