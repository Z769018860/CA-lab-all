
module writeback(
    input wire                       clk,
    input wire                     reset,
    // control signals passing from MEM stage
    input wire           MemToReg_MEM_WB,
    input wire  [ 3:0]   RegWrite_MEM_WB,
    input wire  [ 1:0]       MFHL_MEM_WB,
    // control from EX
    input  wire [ 1:0]       MFHL_ID_EX,
    // data passing from MEM stage
    input wire  [ 4:0]   RegWaddr_MEM_WB,
    input wire  [31:0]  ALUResult_MEM_WB,
    input wire  [31:0]         PC_MEM_WB,
    input wire  [31:0]   MemRdata_MEM_WB,
    input wire  [31:0]         HI_MEM_WB,
    input wire  [31:0]         LO_MEM_WB,
    // data that will be used to write back to Register files
    // or be used as debug signals
    output wire [ 4:0]       RegWaddr_WB,
    output wire [31:0]       RegWdata_WB,
    output wire [ 3:0]       RegWrite_WB,
    output wire [31:0]             PC_WB
);
    wire        MemToReg_WB;
    wire  [31:0]  HI_LO_out;;

    assign HI_LO_out = {32{MFHL_MEM_WB[1]}} & HI_MEM_WB |
                       {32{MFHL_MEM_WB[0]}} & LO_MEM_WB;  //2-1 MUX


    assign       PC_WB =       PC_MEM_WB;
    assign RegWaddr_WB = RegWaddr_MEM_WB;
    assign MemToReg_WB = MemToReg_MEM_WB;
    assign RegWrite_WB = RegWrite_MEM_WB;
    assign RegWdata_WB = |MFHL_MEM_WB ? HI_LO_out : (MemToReg_WB ? MemRdata_MEM_WB : ALUResult_MEM_WB);

endmodule //writeback_stage
