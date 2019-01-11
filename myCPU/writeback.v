

module writeback(
    input wire                       clk,
    input wire                       rst,
    // control signals passing from MEM stage
    input wire           MemToReg_MEM_WB,
    input wire  [ 3:0]   RegWrite_MEM_WB,
    input wire  [ 1:0]       MFHL_MEM_WB,
    input wire                 LB_MEM_WB, //new
    input wire                LBU_MEM_WB, //new
    input wire                 LH_MEM_WB, //new
    input wire                LHU_MEM_WB, //new
    input wire  [ 1:0]         LW_MEM_WB, //new

    // control from EX
    input  wire [ 1:0]       MFHL_DE_EX,
    // data passing from MEM stage
    input wire  [ 4:0]   RegWaddr_MEM_WB,
    input wire  [31:0]  ALUResult_MEM_WB,
    input wire  [31:0]  RegRdata2_MEM_WB, //new
    input wire  [31:0]         PC_MEM_WB,
    input wire  [31:0]   MemRdata_MEM_WB,
    input wire  [31:0]         HI_MEM_WB,
    input wire  [31:0]         LO_MEM_WB,
    // data that will be used to write back to Register files
    // or be used as debug signals
    output wire [ 4:0]       RegWaddr_WB,
    output wire [31:0]       RegWdata_WB,
    output wire [31:0]       RegWdata_Bypass_WB,
    output wire [ 3:0]       RegWrite_WB,
    output wire [31:0]             PC_WB,
    input  wire [31:0]   cp0Rdata_MEM_WB, //new
    input  wire              mfc0_MEM_WB,  //new
//AXI NEW
   output                    wb_allowin,
    input                mem_to_wb_valid,
    output                wb_stage_valid
);
reg wb_valid;
wire wb_ready_go;


assign wb_ready_go = 1'b1;
assign wb_allowin = !wb_valid || wb_ready_go;

always @ (posedge clk) begin
    if (rst) begin
        wb_valid <= 1'b0;
    end
    else if (wb_allowin) begin
        wb_valid <= mem_to_wb_valid;
    end
end
    assign wb_stage_valid = wb_valid;
   
   
    wire        MemToReg_WB;
    
    wire  [31:0]  HI_LO_out;
        
    wire  [31:0] MemRdata_Final;
    
    assign HI_LO_out = { 32{wb_valid}} & 
                       ({32{MFHL_MEM_WB[1]}} & HI_MEM_WB |
                        {32{MFHL_MEM_WB[0]}} & LO_MEM_WB );  //2-1 MUX
     
    
    assign       PC_WB =       PC_MEM_WB;// & {32{wb_valid}};
    assign RegWaddr_WB = RegWaddr_MEM_WB & { 5{wb_valid}};
    assign MemToReg_WB = MemToReg_MEM_WB &     wb_valid  ;
    assign RegWrite_WB = RegWrite_MEM_WB & { 4{wb_valid}};
    assign RegWdata_WB = {32{wb_valid}} &
                         (|MFHL_MEM_WB ?      HI_LO_out  : 
                          (MemToReg_WB ? MemRdata_Final  : 
                          (mfc0_MEM_WB ? cp0Rdata_MEM_WB : ALUResult_MEM_WB)));

    assign RegWdata_Bypass_WB = 
                                (|MFHL_MEM_WB ?       HI_LO_out :
                                 (MemToReg_WB ?  MemRdata_Final :
                                 (mfc0_MEM_WB ? cp0Rdata_MEM_WB :ALUResult_MEM_WB)));





    RegWdata_Sel RegWdata (
          .MemRdata (       MemRdata_MEM_WB),
          .Rt_data  (      RegRdata2_MEM_WB),
          .LW       (             LW_MEM_WB),
          .vaddr    ( ALUResult_MEM_WB[1:0]),
          .LB       (             LB_MEM_WB),
          .LBU      (            LBU_MEM_WB),
          .LH       (             LH_MEM_WB),
          .LHU      (            LHU_MEM_WB),
          .RegWdata (        MemRdata_Final)
    );

endmodule //writeback_stage

