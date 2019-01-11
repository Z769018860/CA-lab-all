module divider(
    input   wire            div_clk,
    input   wire            rst,
    input   wire   [31:0]   x,
    input   wire   [31:0]   y,
    input   wire            div,
    input   wire            div_signed,
    output  wire   [31:0]   s,
    output  wire   [31:0]   r,
    output  wire            busy,
    output  wire            Done
    );

reg [5:0] count;

// wire [32:0] _x;
// wire [32:0] _y;

wire sign_x;
wire sign_y;
wire [31:0] abs_x;
wire [31:0] abs_y;
assign sign_x = div_signed & x[31];
assign sign_y = div_signed & y[31];
assign abs_x = sign_x ? ~x+1 : x;
assign abs_y = sign_y ? ~y+1 : y;

wire [63:0] abs_x_63;
wire [63:0] abs_y_63;
assign abs_x_63 = {32'd0, abs_x};
assign abs_y_63 = {1'b0, abs_y, 31'd0};

reg [63:0] rmdr;
reg [31:0] q;
wire [63:0] next_rmdr;
wire [31:0] next_q;

always @(posedge div_clk) begin
    if (rst || Done) begin
        rmdr <= 64'd0;
        count <= 6'd0;
        q <= 32'd0;
    end
    else if (div==1 && count== 0) begin
        rmdr <= abs_x_63;
        count <= count + 1;
        q <= q;
    end
    else if(div==1 ) begin
        rmdr <= next_rmdr;
        count <= count + 1;
        q <= next_q;
    end
end

wire [63:0] diff;
wire [63:0] r_64;
assign diff = rmdr - abs_y_63;
assign next_rmdr = diff[63] ? ({rmdr[62:0], 1'b0}) : ({diff[62:0], 1'b0});
assign r_64 = diff[63] ? (rmdr[63:0]) : (diff[63:0]) ;
assign next_q = {q[30:0], ~diff[63]};

assign Done = (count == 6'd32);
assign busy = ~Done&div;

assign s = {32{ ~sign_x & ~sign_y | sign_x&sign_y }} & next_q
          |{32{ sign_x & ~sign_y | ~sign_x & sign_y }} & (~next_q + 1);
assign r = {32{ ~sign_x }} & r_64[62:31]
          |{32{ sign_x }} & (~r_64[62:31] + 1);


endmodule
