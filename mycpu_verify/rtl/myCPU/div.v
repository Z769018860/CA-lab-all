module divider(
    input   wire            clk,
    input   wire            reset,
    input   wire   [31:0]   x,
    input   wire   [31:0]   y,
    input   wire            div,//除法模块运行使能
    input   wire            div_signed,
    output  wire   [31:0]   result_q,
    output  wire   [31:0]   result_r,
    output  wire            busy,
    output  wire            done
    );

    reg [5:0] count;//位数计算器

    wire sign_x;
    wire sign_y;
    wire [31:0] re_x;
    wire [31:0] re_y;

    wire [63:0] diff;
    wire [63:0] r_64;
    
    assign sign_x = div_signed & x[31];
    assign sign_y = div_signed & y[31];
    assign re_x = sign_x ? ~x+1 : x;
    assign re_y = sign_y ? ~y+1 : y;

    wire [63:0] re_x_63;
    wire [63:0] re_y_63;
    
    assign re_x_63 = {32'd0, re_x};
    assign re_y_63 = {1'b0, re_y, 31'd0};

    reg [63:0] rmdr;
    reg [31:0] q;
    wire [63:0] next_rmdr;
    wire [31:0] next_q;

always @(posedge clk) 
begin
    if (reset || done) 
    begin
        rmdr <= 64'd0;
        count <= 6'd0;
        q <= 32'd0;
    end
    else if(div==1 ) 
    begin
        if (count == 0)
        begin
            rmdr <= re_x_63;
            count <= count + 1;
            q <= q;
        end
        else
        begin
            rmdr <= next_rmdr;
            count <= count + 1;
            q <= next_q;
        end
    end
end

    assign diff = rmdr - re_y_63;
    assign next_rmdr = diff[63] ? ({rmdr[62:0], 1'b0}) : ({diff[62:0], 1'b0});
    assign r_64 = diff[63] ? (rmdr[63:0]) : (diff[63:0]) ;
    assign next_q = {q[30:0], ~diff[63]};

    assign done = (count == 6'd32);
    assign busy = ~done&div;//是否按成除法还是正在进行

    assign result_q = {32{ ~sign_x & ~sign_y | sign_x&sign_y }} & next_q
            |{32{ sign_x & ~sign_y | ~sign_x & sign_y }} & (~next_q + 1);
    assign result_r = {32{ ~sign_x }} & r_64[62:31]
            |{32{ sign_x }} & (~r_64[62:31] + 1);


endmodule
