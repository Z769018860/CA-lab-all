

module fetch(
    input  wire        clk,
    input  wire        reset,
    // data passing from the PC calculate module
    input  wire    IRWrite,
    // For Stall
    input  wire [31:0] nextpc,
    // interaction with inst_sram
    output wire        inst_sram_en,
    input  wire [31:0] inst_sram_rdata,
    // data transfering to DE stage
    output reg  [31:0]       PC_IF_DE,           //fetch_stage pc
    output reg  [31:0] PC_add_4_IF_DE,
    output reg  [31:0]     Inst_IF_DE            //instr code sent from fetch_stage
  );
    parameter ADDR = 32'hbfc00000;

    assign inst_sram_en = ~reset;

    always @ (posedge clk) 
    begin
      if(reset) 
      begin
          PC_IF_DE       <= ADDR;
          PC_add_4_IF_DE <= ADDR+4;
          Inst_IF_DE     <= 32'd0;
      end
      else if (IRWrite) 
      begin
          PC_IF_DE       <= nextpc;
          PC_add_4_IF_DE <= nextpc+4;
          Inst_IF_DE     <= inst_sram_rdata;
      end
      else begin
          PC_IF_DE       <= PC_IF_DE;
          PC_add_4_IF_DE <= PC_add_4_IF_DE;
          Inst_IF_DE     <= Inst_IF_DE;
      end
    end
    //改成了一个时钟周期
endmodule //fetch_stage

module Adder(
    input  [31:0] A,
    input  [31:0] B,
    output [31:0] Result
  );
    alu adder(
        .A      (      A),
        .B      (      B),
        .ALUop  (4'b0010),   //ADD
        .Result ( Result)
    );
endmodule
