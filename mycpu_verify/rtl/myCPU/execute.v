

module execute(
    input  wire        clk,
    input  wire        reset,
    // data transfering from DE stage
    input  wire [31:0]   PC_add_4_DE_EX,
    input  wire [31:0]         PC_DE_EX,
    input  wire [31:0]  RegRdata1_DE_EX,
    input  wire [31:0]  RegRdata2_DE_EX,
    input  wire [31:0]         Sa_DE_EX,
    input  wire [31:0]  SgnExtend_DE_EX,
    input  wire [31:0]    ZExtend_DE_EX,
    input  wire [ 4:0]   RegWaddr_DE_EX,
    // control signals passing from DE stage
    input  wire             MemEn_DE_EX,
    input  wire          MemToReg_DE_EX,
    input  wire [ 1:0]    ALUSrcA_DE_EX,
    input  wire [ 1:0]    ALUSrcB_DE_EX,
    input  wire [ 3:0]      ALUop_DE_EX,
    input  wire [ 3:0]   MemWrite_DE_EX,
    input  wire [ 3:0]   RegWrite_DE_EX,
    input  wire [ 1:0]       MULT_DE_EX, //new
    input  wire [ 1:0]       MFHL_DE_EX, //new
    input  wire [ 1:0]       MTHL_DE_EX, //new
    // control signals passing to MEM stage
    output reg             MemEn_EX_MEM,
    output reg          MemToReg_EX_MEM,
    output reg  [ 3:0]  MemWrite_EX_MEM,
    output reg  [ 3:0]  RegWrite_EX_MEM,
    output reg  [ 1:0]      MULT_EX_MEM, //new
    output reg  [ 1:0]      MFHL_EX_MEM, //new
    output reg  [ 1:0]      MTHL_EX_MEM, //new
    // data passing to MEM stage
    output reg  [ 4:0]  RegWaddr_EX_MEM,
    output reg  [31:0] ALUResult_EX_MEM,
    output reg  [31:0]  MemWdata_EX_MEM,
    output reg  [31:0]        PC_EX_MEM,
    output reg  [31:0] RegRdata1_EX_MEM, //new

    output wire [31:0] ALUResult_EX
);

    wire [31:0] ALUA,ALUB;
    wire [ 4:0] RegWaddr_EX;

    assign RegWaddr_EX = RegWaddr_DE_EX;



    always @(posedge clk)
    if (~reset) begin
        // control signals passing to MEM stage
        MemEn_EX_MEM     <= MemEn_DE_EX;
        MemToReg_EX_MEM  <= MemToReg_DE_EX;
        MemWrite_EX_MEM  <= MemWrite_DE_EX;
        RegWrite_EX_MEM  <= RegWrite_DE_EX;
        //MULT sign
            MULT_EX_MEM  <=     MULT_DE_EX;
            MFHL_EX_MEM  <=     MFHL_DE_EX;
            MTHL_EX_MEM  <=     MTHL_DE_EX;
        // data passing to MEM stage
        RegWaddr_EX_MEM  <= RegWaddr_EX;
        ALUResult_EX_MEM <= ALUResult_EX;
        MemWdata_EX_MEM  <= RegRdata2_DE_EX;
        PC_EX_MEM        <= PC_DE_EX;
        RegRdata1_EX_MEM <= RegRdata1_DE_EX;

    end
    else
        {MemEn_EX_MEM, MemToReg_EX_MEM, MemWrite_EX_MEM, RegWrite_EX_MEM, RegWaddr_EX_MEM, MULT_EX_MEM, MFHL_EX_MEM, MTHL_EX_MEM,
           ALUResult_EX_MEM, MemWdata_EX_MEM, PC_EX_MEM, RegRdata1_EX_MEM} <= 'd0;

    MUX_4_32 ALUA_MUX(
        .Src1   (RegRdata1_DE_EX),
        .Src2   ( PC_add_4_DE_EX),
        .Src3   (       Sa_DE_EX),
        .Src4   (           32'd0),
        .op     (  ALUSrcA_DE_EX),
        .Result (            ALUA)
    );
    MUX_4_32 ALUB_MUX(
        .Src1   (RegRdata2_DE_EX),
        .Src2   (SgnExtend_DE_EX),
        .Src3   (           32'd4),
        .Src4   (  ZExtend_DE_EX),
        .op     (  ALUSrcB_DE_EX),
        .Result (            ALUB)
    );
/*    MUX_3_5 RegWaddr_MUX(
        .Src1   (       Rt_DE_EX),
        .Src2   (       Rd_DE_EX),
        .Src3   (        5'b11111),
        .op     (   RegDst_DE_EX),
        .Result (    RegWaddr_EX)
    );*/
    alu ALU(
         .A        (         ALUA),
         .B        (         ALUB),
         .ALUop    ( ALUop_DE_EX),
        // .Overflow (    AOverflow),
        // .CarryOut (    ACarryOut),
        // .Zero     (        AZero),
         .Result   (ALUResult_EX)
    );

endmodule //execute_stage

