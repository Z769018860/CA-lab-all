module multiplyer(
    input  [31:0] x,
    input  [31:0] y,
    input  mul_clk,
    input  resetn,
//    input  clken,
    input  mul_signed,
    output [63:0] result
);
reg [31:0] x_r;
reg [31:0] y_r;
reg          mul_signed_r;

always @(posedge mul_clk)
begin
    if (!resetn)
    begin
        x_r          <= 32'd0;
        y_r          <= 32'd0;
        mul_signed_r <= 1'b0;
    end
    else
    begin
        x_r          <= x;
        y_r          <= y;
        mul_signed_r <= mul_signed;
    end
end

wire signed [32:0] x_e;
wire signed [32:0] y_e;
assign x_e        = {mul_signed_r & x_r[31],x_r};
assign y_e        = {mul_signed_r & y_r[31],y_r};
assign result = x_e * y_e;

//wire [31:0] x_r = mul_signed ? (x[31] ? (~x + 32'b1) : x) : x;
//wire [31:0] y_r = mul_signed ? (y[31] ? (~y + 32'b1) : y) : y;
/*
mult_signed Signed_Muliplier(
    .CLK  (clk),
    .A    (x_r),
    .B    (y_r),
//    .SCLR (rst),
//    .CE   (clken),
    .P    (temp_signed_r)
);
*/
/*
mul32 mul32(
    .clk  (clk),
    .a    (x),
    .b    (y),
    .rst  (resetn),
    .c    (temp_signed_r)
);

assign result = temp_signed_r;
*/
endmodule
