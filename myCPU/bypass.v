
`timescale 10ns / 1ns
module bypass(
    input  wire        clk,
    input  wire        rst,
    // input IR recognize signals from Control Unit
    input  wire        is_rs_read,
    input  wire        is_rt_read,
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

    input  wire DIV_Busy,
    input  wire DIV,
    
    input  wire ex_int_handle,
    // output the stall signals
    output wire        PCWrite,
    output wire        IRWrite,
    output wire        DE_EX_Stall,
    // output the real read data in DE stage
    output wire [ 1:0] RegRdata1_src,
    output wire [ 1:0] RegRdata2_src,
  //AXI NEW
    input   is_j_or_b,

    input   de_valid,
    input   wb_valid,
    input   exe_valid,
    input   mem_valid
  );

    wire [ 4:0] rs_read, rt_read;
    assign rs_read = (is_rs_read) ? rs_DE : 5'd0;
    assign rt_read = (is_rt_read) ? rt_DE : 5'd0;


    wire Haz_DE_EX_rs, Haz_DE_EX_rt,
         Haz_DE_MEM_rs, Haz_DE_MEM_rt,
         Haz_DE_WB_rs,  Haz_DE_WB_rt;

    assign Haz_DE_EX_rs = (((|RegWaddr_DE_EX) & (|rs_read)) & ((&(rs_read^~RegWaddr_DE_EX)) & (|RegWrite_DE_EX))) & exe_valid&(de_valid|is_j_or_b) ;
    assign Haz_DE_EX_rt = (((|RegWaddr_DE_EX) & (|rt_read)) & ((&(rt_read^~RegWaddr_DE_EX)) & (|RegWrite_DE_EX))) & exe_valid&(de_valid|is_j_or_b);

    assign Haz_DE_MEM_rs = ((|RegWaddr_EX_MEM) & (|rs_read)) & ((&(rs_read^~RegWaddr_EX_MEM)) & (|RegWrite_EX_MEM)) & mem_valid&(de_valid|is_j_or_b);
    assign Haz_DE_MEM_rt = ((|RegWaddr_EX_MEM) & (|rt_read)) & ((&(rt_read^~RegWaddr_EX_MEM)) & (|RegWrite_EX_MEM)) & mem_valid&(de_valid|is_j_or_b);

    assign Haz_DE_WB_rs  = ((|RegWaddr_MEM_WB) & (|rs_read)) & ((&(rs_read^~RegWaddr_MEM_WB)) & (|RegWrite_MEM_WB)) & wb_valid&(de_valid|is_j_or_b);
    assign Haz_DE_WB_rt  = ((|RegWaddr_MEM_WB) & (|rt_read)) & ((&(rt_read^~RegWaddr_MEM_WB)) & (|RegWrite_MEM_WB)) & wb_valid&(de_valid|is_j_or_b);

    assign RegRdata1_src = Haz_DE_EX_rs ? 2'b01 :
                          (Haz_DE_MEM_rs ? 2'b10 :
                          (Haz_DE_WB_rs  ? 2'b11 : 2'b00));
    assign RegRdata2_src = Haz_DE_EX_rt ? 2'b01 :
                          (Haz_DE_MEM_rt ? 2'b10 :
                          (Haz_DE_WB_rt  ? 2'b11 : 2'b00));

    assign DE_EX_Stall = ((((Haz_DE_EX_rt |  Haz_DE_EX_rs) & MemToReg_DE_EX)  |
                          (( Haz_DE_MEM_rt & ~Haz_DE_EX_rt) | (Haz_DE_MEM_rs & ~Haz_DE_EX_rs) & MemToReg_EX_MEM)) |
                          (( Haz_DE_WB_rt & ~Haz_DE_EX_rt & ~Haz_DE_MEM_rt | Haz_DE_WB_rs & ~Haz_DE_EX_rs & ~Haz_DE_MEM_rs) & MemToReg_MEM_WB |
                            DIV_Busy  & DIV))
                            & (~ex_int_handle & ~rst);


    assign PCWrite = ~DE_EX_Stall;
    assign IRWrite = ~(DE_EX_Stall);
    
endmodule // Bypass Unit
