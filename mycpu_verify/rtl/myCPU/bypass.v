module bypass(
    input  wire        clk,
    input  wire        reset,
    // input IR recognize signals from Control Unit
    input  wire        rs_R,
    input  wire        rt_R,
    // Judge whether the instruction is LW
    input  wire        MemToReg_DE_EX,
    input  wire        MemToReg_EX_MEM,
    input  wire        MemToReg_MEM_WB,
    // Reg Write address in afterward stage
    input  wire [ 4:0] RegWaddr_EX_MEM,
    input  wire [ 4:0] RegWaddr_MEM_WB,
    input  wire [ 4:0] RegWaddr_DE_EX,
    // Reg read address in DE stage
    input  wire [ 3:0] RegWrite_DE_EX,
    input  wire [ 3:0] RegWrite_EX_MEM,
    input  wire [ 3:0] RegWrite_MEM_WB,

    input  wire [ 4:0] rs_DE,
    input  wire [ 4:0] rt_DE,
    //div sign
    input  wire DIV_Busy,
    input  wire DIV,
    // output the stall signals延迟信号
    output wire        PCWrite,
    output wire        IRWrite,
    output wire        DE_EX_Stall,
    // output the real read data in DE stage
    output wire [ 1:0] RegRdata1_src,
    output wire [ 1:0] RegRdata2_src
  );

    wire [4:0] rs_read = (rs_R) ? rs_DE : 5'd0;
    wire [4:0] rt_read = (rt_R) ? rt_DE : 5'd0;


  //  wire DE_EX_rs_HAZ, DE_EX_rt_HAZ,
   //      DE_MEM_rs_HAZ, DE_MEM_rt_HAZ,
   //      DE_WB_rs_HAZ,  DE_WB_rt_HAZ;

    wire DE_EX_rs_HAZ = (|rs_read) & (&(rs_read^~RegWaddr_DE_EX)) &  (|RegWaddr_DE_EX) &(|RegWrite_DE_EX);
    wire DE_EX_rt_HAZ = (|rt_read) & (&(rt_read^~RegWaddr_DE_EX)) &  (|RegWaddr_DE_EX) &  (|RegWrite_DE_EX);

    wire DE_MEM_rs_HAZ = (|rs_read) & (&(rs_read^~RegWaddr_EX_MEM)) & (|RegWaddr_EX_MEM) &  (|RegWrite_EX_MEM);
    wire DE_MEM_rt_HAZ = (|rt_read) & (&(rt_read^~RegWaddr_EX_MEM)) & (|RegWaddr_EX_MEM) &  (|RegWrite_EX_MEM);

    wire DE_WB_rs_HAZ  = (|rs_read) & (&(rs_read^~RegWaddr_MEM_WB)) & (|RegWaddr_MEM_WB) &  (|RegWrite_MEM_WB);
    wire DE_WB_rt_HAZ  = (|rt_read) & (&(rt_read^~RegWaddr_MEM_WB)) & (|RegWaddr_MEM_WB) &  (|RegWrite_MEM_WB);

    assign RegRdata1_src = DE_EX_rs_HAZ ? 2'b01 :
                          (DE_MEM_rs_HAZ ? 2'b10 :
                          (DE_WB_rs_HAZ  ? 2'b11 : 2'b00));
    assign RegRdata2_src = DE_EX_rt_HAZ ? 2'b01 :
                          (DE_MEM_rt_HAZ ? 2'b10 :
                          (DE_WB_rt_HAZ  ? 2'b11 : 2'b00));

    assign DE_EX_Stall = ((DE_EX_rt_HAZ |  DE_EX_rs_HAZ) & MemToReg_DE_EX)
                        | (((DE_MEM_rt_HAZ & ~DE_EX_rt_HAZ) |
                            (DE_MEM_rs_HAZ & ~DE_EX_rs_HAZ))
                        & MemToReg_EX_MEM)
                        | DIV_Busy 
                        & DIV;


    assign PCWrite = ~DE_EX_Stall;
    assign IRWrite = ~DE_EX_Stall;

endmodule
