`timescale 10 ns / 1 ns

`define DATA_WIDTH0 32
`define ADDR_WIDTH0 5

module reg_file(
	input clk,
	input rst,
	input [`ADDR_WIDTH0 - 1:0] waddr,
	input [`ADDR_WIDTH0 - 1:0] raddr1,
	input [`ADDR_WIDTH0 - 1:0] raddr2,
	input [               3:0] wen,
	input [`DATA_WIDTH0 - 1:0] wdata,
	output [`DATA_WIDTH0 - 1:0] rdata1,
	output [`DATA_WIDTH0 - 1:0] rdata2
);
	reg [`DATA_WIDTH0-1:0] sram_32 [`DATA_WIDTH0-1:0];
	integer i;
	always @(posedge clk)
	begin
		if (rst==1'b1)
		begin
            	sram_32[0] <= 0;
		end
		else
		begin
			if (wen!=4'b0000&& waddr!=0)
				sram_32[waddr] <= wdata;
		end
	end
	assign rdata1 = sram_32[raddr1];
	assign rdata2 = sram_32[raddr2];

	// TODO: Please add your logic code here

endmodule
