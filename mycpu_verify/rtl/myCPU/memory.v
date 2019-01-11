

module memory(
    input  wire                       clk,
    input  wire                     reset,
    // control signals transfering from EX stage
    input  wire             MemEn_EX_MEM,
    input  wire          MemToReg_EX_MEM,
    input  wire  [ 3:0]  MemWrite_EX_MEM,
    input  wire  [ 3:0]  RegWrite_EX_MEM,
    input  wire  [ 1:0]      MFHL_EX_MEM, //new
    // data passing from EX stage
    input  wire  [ 4:0]  RegWaddr_EX_MEM,
    input  wire  [31:0] ALUResult_EX_MEM,
    input  wire  [31:0]  MemWdata_EX_MEM,
    input  wire  [31:0]        PC_EX_MEM,
    // interaction with the data_sram
    output wire  [31:0]      MemWdata_MEM,
    output wire                 MemEn_MEM,
    output wire  [ 3:0]      MemWrite_MEM,
    output wire  [31:0]    data_sram_addr,
    // output control signals to WB stage
    output reg            MemToReg_MEM_WB,
    output reg   [ 3:0]   RegWrite_MEM_WB,
    output reg   [ 1:0]       MFHL_MEM_WB, //new
    // output data to WB stage
    output reg   [ 4:0]   RegWaddr_MEM_WB,
    output reg   [31:0]  ALUResult_MEM_WB,
    output reg   [31:0]         PC_MEM_WB,
//    output wire  [31:0]   MemRdata_MEM_WB
    output wire  [31:0]     ALUResult_MEM   
    //Bypass
  );

// interaction of signals and data with data_sram
    assign MemEn_MEM      =     MemEn_EX_MEM;
    assign MemWrite_MEM   =  MemWrite_EX_MEM;
    assign data_sram_addr = ALUResult_EX_MEM;
    assign MemWdata_MEM   =  MemWdata_EX_MEM;

    assign ALUResult_MEM  = ALUResult_EX_MEM;

    // output data to WB stage
    always @(posedge clk)
    if (~reset) 
    begin
        PC_MEM_WB        <=        PC_EX_MEM;
        RegWaddr_MEM_WB  <=  RegWaddr_EX_MEM;
        MemToReg_MEM_WB  <=  MemToReg_EX_MEM;
        RegWrite_MEM_WB  <=  RegWrite_EX_MEM;
        ALUResult_MEM_WB <= ALUResult_EX_MEM;
        //new
        MFHL_MEM_WB      <=      MFHL_EX_MEM;
    end
    else
        {PC_MEM_WB, RegWaddr_MEM_WB, MemToReg_MEM_WB, RegWrite_MEM_WB, ALUResult_MEM_WB, MFHL_MEM_WB} <= 'd0;


endmodule //memory_stage
