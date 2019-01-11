
module decode(
    input  wire                     clk,
    input  wire                   reset,
    // data passing from IF stage
    input  wire [31:0]       Inst_IF_DE,
    input  wire [31:0]         PC_IF_DE,
    input  wire [31:0]   PC_add_4_IF_DE,
    // interaction with the Register files
    output wire [ 4:0]     RegRaddr1_DE,
    output wire [ 4:0]     RegRaddr2_DE,
    input  wire [31:0]     RegRdata1_DE,
    input  wire [31:0]     RegRdata2_DE,
    // control signals passing to
    // PC caculate module
    input  wire [31:0]     ALUResult_EX,
    input  wire [31:0]     ALUResult_MEM,
    input  wire [31:0]       RegWdata_WB,
    //mul div
    input  wire [63:0]       MULT_Result,
    input  wire [31:0]                HI,
    input  wire [31:0]                LO,
    // regdata passed back
    input  wire [ 1:0]     MFHL_DE_EX_1,
    input  wire [ 1:0]     MFHL_EX_MEM,
    input  wire [ 1:0]     MFHL_MEM_WB,
    input  wire [ 1:0]     MULT_EX_MEM,
    //new
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
    // control signals passing to EX stage
//    output reg  [ 1:0]    RegDst_DE_EX,
    output reg  [ 1:0]   ALUSrcA_DE_EX,
    output reg  [ 1:0]   ALUSrcB_DE_EX,
    output reg  [ 3:0]     ALUop_DE_EX,
    output reg  [ 3:0]  RegWrite_DE_EX,
    output reg  [ 3:0]  MemWrite_DE_EX,
    output reg             MemEn_DE_EX,
    output reg          MemToReg_DE_EX,
    output reg  [ 1:0]      MULT_DE_EX, //new
    output reg  [ 1:0]       DIV_DE_EX, //new
    output reg  [ 1:0]      MFHL_DE_EX, //new
    output reg  [ 1:0]      MTHL_DE_EX, //new
    // data transfering to EX stage
//    output reg  [ 4:0]        Rt_DE_EX,
//    output reg  [ 4:0]        Rd_DE_EX,
    output reg  [ 4:0]  RegWaddr_DE_EX,
    output reg  [31:0]  PC_add_4_DE_EX,
    output reg  [31:0]        PC_DE_EX,
    output reg  [31:0] RegRdata1_DE_EX,
    output reg  [31:0] RegRdata2_DE_EX,
    output reg  [31:0]        Sa_DE_EX,
    output reg  [31:0] SgnExtend_DE_EX,
    output reg  [31:0]   ZExtend_DE_EX,

    output wire           rs_R_DE,
    output wire           rt_R_DE
  );

	wire           BranchCond_DE;
    wire                 Zero_DE;
    wire             MemToReg_DE;
    wire                 JSrc_DE;
    wire                MemEn_DE;
    wire [ 1:0]       ALUSrcA_DE;
    wire [ 1:0]       ALUSrcB_DE;
    wire [ 1:0]        RegDst_DE;
    wire [ 1:0]         PCSrc_DE;
    wire [ 3:0]         ALUop_DE;
    wire [ 3:0]      MemWrite_DE;
    wire [ 3:0]      RegWrite_DE;
    wire [31:0]     SgnExtend_DE;
    wire [31:0]       ZExtend_DE;
    wire [31:0] SgnExtend_LF2_DE;
    wire [31:0]      PC_add_4_DE;
    wire [31:0]            Sa_DE;
    wire [31:0]            PC_DE;
    wire [ 4:0]      RegWaddr_DE;
    wire [ 5:0]        B_Type_DE;
    wire [ 1:0]          MULT_DE; //new
    wire [ 1:0]           DIV_DE; //new
    wire [ 1:0]          MFHL_DE; //new
    wire [ 1:0]          MTHL_DE; //new
    // temp, intend to remember easily

    wire [31:0]  RegRdata1_F_DE;
    wire [31:0]  RegRdata2_F_DE;
    // Bypassed regdata

    wire [ 4:0]       rs,rt,rd,sa;
    
    wire [31:0] DE_EX_data; 
    wire [31:0] EX_MEM_data;
    wire [31:0] MEM_WB_data;
     
    assign rs = Inst_IF_DE[25:21];
    assign rt = Inst_IF_DE[20:16];
    assign rd = Inst_IF_DE[15:11];
    assign sa = Inst_IF_DE[10: 6];
    // interaction with Register files
    // tell read address to Register files
    assign RegRaddr1_DE = Inst_IF_DE[25:21];
    assign RegRaddr2_DE = Inst_IF_DE[20:16];
    // datapath
    assign SgnExtend_DE     = {{16{Inst_IF_DE[15]}},Inst_IF_DE[15:0]};
    assign   ZExtend_DE     = {{16'd0},Inst_IF_DE[15:0]};
    assign Sa_DE            = {{27{1'b0}}, Inst_IF_DE[10: 6]};
    assign SgnExtend_LF2_DE = SgnExtend_DE << 2;
    // signals passing to PC calculate module
    assign JSrc  =  JSrc_DE;
    assign PCSrc = PCSrc_DE;
    // data passing to PC calculate module
    assign  PC_add_4_DE = PC_add_4_IF_DE;
    assign  J_target_DE = {{PC_IF_DE[31:28]},{Inst_IF_DE[25:0]},{2'b00}};
    assign JR_target_DE =   RegRdata1_F_DE;
    assign        PC_DE =       PC_add_4_IF_DE;

    Adder Branch_addr_Adder(
        .A         (      PC_add_4_DE),
        .B         ( SgnExtend_LF2_DE),
        .Result    (     Br_target_DE)
    );

    always @(posedge clk) 
    begin
        if (reset) 
        begin
        {MemEn_DE_EX, MemToReg_DE_EX, ALUop_DE_EX, RegWrite_DE_EX, MemWrite_DE_EX, ALUSrcA_DE_EX, ALUSrcB_DE_EX, MULT_DE_EX, DIV_DE_EX, MFHL_DE_EX, MTHL_DE_EX,
         RegWaddr_DE_EX, Sa_DE_EX, PC_DE_EX, PC_add_4_DE_EX, RegRdata1_DE_EX, RegRdata2_DE_EX, SgnExtend_DE_EX, ZExtend_DE_EX} <= 'd0;
        end
        else
        if (~DE_EX_Stall) 
        begin
        // control signals passing to EX stage
            MemEn_DE_EX    <=    MemEn_DE;
            MemToReg_DE_EX <= MemToReg_DE;
            ALUop_DE_EX    <=    ALUop_DE;
            RegWrite_DE_EX <= RegWrite_DE;
            MemWrite_DE_EX <= MemWrite_DE;
            ALUSrcA_DE_EX  <=  ALUSrcA_DE;
            ALUSrcB_DE_EX  <=  ALUSrcB_DE;
        /////////////////////////////////
           MULT_DE_EX  <=     MULT_DE;
            DIV_DE_EX  <=      DIV_DE;
           MFHL_DE_EX  <=     MFHL_DE;
           MTHL_DE_EX  <=     MTHL_DE;
        /////////////////////////////////////////
            RegWaddr_DE_EX  <=          RegWaddr_DE;
            Sa_DE_EX        <=                Sa_DE;
            PC_DE_EX        <=             PC_IF_DE;
            PC_add_4_DE_EX  <=       PC_add_4_IF_DE;
            RegRdata1_DE_EX <=   RegRdata1_F_DE;
            RegRdata2_DE_EX <=   RegRdata2_F_DE;
            SgnExtend_DE_EX <=         SgnExtend_DE;
            ZExtend_DE_EX <=           ZExtend_DE;
        end
        else if (~(|DIV_DE_EX))
            {MemEn_DE_EX, MemToReg_DE_EX, ALUop_DE_EX, RegWrite_DE_EX, MemWrite_DE_EX, ALUSrcA_DE_EX, ALUSrcB_DE_EX, MULT_DE_EX, DIV_DE_EX, MFHL_DE_EX, MTHL_DE_EX,
            RegWaddr_DE_EX, Sa_DE_EX, PC_DE_EX, PC_add_4_DE_EX, RegRdata1_DE_EX, RegRdata2_DE_EX, SgnExtend_DE_EX, ZExtend_DE_EX} <= 'd0;
        else if (~DIV_Done) 
        begin
            {MemEn_DE_EX, MemToReg_DE_EX, ALUop_DE_EX, RegWrite_DE_EX, MemWrite_DE_EX, ALUSrcA_DE_EX, ALUSrcB_DE_EX, MULT_DE_EX, MFHL_DE_EX, MTHL_DE_EX,
            RegWaddr_DE_EX, Sa_DE_EX, PC_DE_EX, PC_add_4_DE_EX, SgnExtend_DE_EX, ZExtend_DE_EX} <= 'd0;
            DIV_DE_EX <= DIV_DE_EX;
            RegRdata1_DE_EX <= RegRdata1_DE_EX;
            RegRdata2_DE_EX <= RegRdata2_DE_EX;
        end
    end

    branch Branch_Cond(
        .A         (     RegRdata1_F_DE),
        .B         (     RegRdata2_F_DE),
        .B_Type    (           B_Type_DE),
        .Cond      (          BranchCond_DE)
    );
    control Control(
        .reset      (          reset),
        .BranchCond(    BranchCond_DE),
        .op        (Inst_IF_DE[31:26]),
        .func      (Inst_IF_DE[ 5: 0]),
        .rt        (               rt),
        .MemEn     (         MemEn_DE),
        .JSrc      (          JSrc_DE),
        .MemToReg  (      MemToReg_DE),
        .ALUop     (         ALUop_DE),
        .PCSrc     (         PCSrc_DE),
        .RegDst    (        RegDst_DE),
        .RegWrite  (      RegWrite_DE),
        .MemWrite  (      MemWrite_DE),
        .ALUSrcA   (       ALUSrcA_DE),
        .ALUSrcB   (       ALUSrcB_DE),
        .rs_R(    rs_R_DE),
        .rt_R(    rt_R_DE),
        .B_Type    (        B_Type_DE),
        .MULT      (          MULT_DE), //new
        .DIV       (           DIV_DE), //new
        .MFHL      (          MFHL_DE), //new
        .MTHL      (          MTHL_DE)  //new
    );
    MUX_4_32 RegRdata1_MUX(
        .Src1      (RegRdata1_DE),
        .Src2      (DE_EX_data),
        .Src3      (EX_MEM_data),
        .Src4      (MEM_WB_data),
        .op        (RegRdata1_src),
        .Result    (RegRdata1_F_DE)
    );
    MUX_4_32 RegRdata2_MUX(
        .Src1      (RegRdata2_DE),
        .Src2      (DE_EX_data),
        .Src3      (EX_MEM_data),
        .Src4      (MEM_WB_data),
        .op        (RegRdata2_src),
        .Result    (RegRdata2_F_DE)
    );
    MUX_3_5 RegWaddr_MUX(
        .Src1   (           rt),
        .Src2   (           rd),
        .Src3   (     5'b11111),
        .op     (    RegDst_DE),
        .Result (  RegWaddr_DE)
    );
wire [31:0] MULT_HI_LO = {32{MFHL_DE_EX_1[1]}}  & MULT_Result[63:32] | {32{MFHL_DE_EX_1[0]}}  & MULT_Result[31:0];
wire [31:0]  EX_HI_LO = {32{MFHL_DE_EX_1[1]}}  & HI                 | {32{MFHL_DE_EX_1[0]}}  & LO;
wire [31:0]  MEM_HI_LO = {32{MFHL_EX_MEM[1]}}   & HI                 | {32{MFHL_EX_MEM[0]}}   & LO;
wire [31:0]   WB_HI_LO = {32{MFHL_MEM_WB[1]}}    & HI                 | {32{MFHL_MEM_WB[0]}}    & LO;
assign DE_EX_data  =  |MFHL_DE_EX  ? (MULT_EX_MEM ? MULT_HI_LO : EX_HI_LO) : ALUResult_EX;
assign EX_MEM_data =  |MFHL_EX_MEM ? MEM_HI_LO : ALUResult_MEM;
assign MEM_WB_data  =  |MFHL_MEM_WB  ?  WB_HI_LO : RegWdata_WB;

endmodule //decode_stage


