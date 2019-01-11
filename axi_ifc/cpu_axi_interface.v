module cpu_axi_interface (
    input wire         clk          ,
    input wire         resetn       ,

    //inst sram-like
    input  wire        inst_req     ,
    input  wire        inst_wr      ,
    input  wire [ 1:0] inst_size    ,
    input  wire [31:0] inst_addr    ,
    input  wire [31:0] inst_wdata   ,
    output reg  [31:0] inst_rdata   ,
    output wire        inst_addr_ok ,
    output wire        inst_data_ok ,

    //data sram-like
    input  wire        data_req     ,
    input  wire        data_wr      ,
    input  wire [ 1:0] data_size    ,
    input  wire [31:0] data_addr    ,
    input  wire [31:0] data_wdata   ,
    output reg  [31:0] data_rdata   ,
    output wire        data_addr_ok ,
    output wire        data_data_ok ,

    //axi
    //ar
    output wire [ 3:0] arid         ,
    output wire [31:0] araddr       ,
    output wire [ 7:0] arlen        ,
    output wire [ 2:0] arsize       ,
    output wire [ 1:0] arburst      ,
    output wire [ 1:0] arlock       ,
    output wire [ 3:0] arcache      ,
    output wire [ 2:0] arprot       ,
    output wire        arvalid      ,
    input  wire        arready      ,
    //r
    input  wire [ 3:0] rid          ,
    input  wire [31:0] rdata        ,
    input  wire [ 1:0] rresp        ,
    input  wire        rlast        ,
    input  wire        rvalid       ,
    output wire        rready       ,
    //aw
    output wire [ 3:0] awid         ,
    output wire [31:0] awaddr       ,
    output wire [ 7:0] awlen        ,
    output wire [ 2:0] awsize       ,
    output wire [ 1:0] awburst      ,
    output wire [ 1:0] awlock       ,
    output wire [ 3:0] awcache      ,
    output wire [ 2:0] awprot       ,
    output wire        awvalid      ,
    input  wire        awready      ,
    //w
    output wire [ 3:0] wid          ,
    output wire [31:0] wdata        ,
    output reg  [ 3:0] wstrb        ,
    output wire        wlast        ,
    output wire        wvalid       ,
    input  wire        wready       ,
    //b
    input  wire [ 3:0] bid          ,
    input  wire [ 1:0] bresp        ,
    input  wire        bvalid       ,
    output wire        bready
);

reg  [ 1:0] r_status; // 0-free 1-read_req 2-reading 3-read_fin
reg         r_from;   // 0-inst 1-data
reg  [ 1:0] r_size;
reg  [31:0] r_addr;

reg  [ 1:0] w_status; // 0-free 1-write_req 2-writing 3-write_fin
reg         w_from;   // 0-inst 1-data
reg  [ 1:0] w_size;
reg  [31:0] w_addr;
reg  [31:0] w_data;

reg         wr_haz;
reg         rw_haz;
reg         arvalid_en;
reg         awvalid_en;
reg         wvalid_en;

always @(posedge clk) begin
    if(!resetn) begin
        r_status     <= 2'd0;
        r_from       <= 1'b0;
        r_size       <= 2'd0;
        r_addr       <= 32'd0;
        arvalid_en   <= 1'b0;
        wr_haz    <= 1'b0;

    end else begin
        if(r_status == 2'b00) begin
            if(data_req && !data_wr) begin
                r_status     <= 2'b01;
                r_from       <= 1'b1;
            end else if(inst_req && !inst_wr) begin
                r_status     <= 2'b01;
                r_from       <= 1'b0;
            end

        end else if(r_status == 2'b01) begin
            if(r_from && data_addr_ok && !arvalid_en) begin
                r_size       <= data_size;
                r_addr       <= data_addr;
                arvalid_en   <= 1'b1;
                wr_haz    <= ^w_status && data_addr[31:2] == w_addr[31:2];
            end else if(!r_from && inst_addr_ok && !arvalid_en) begin
                r_size       <= inst_size;
                r_addr       <= inst_addr;
                arvalid_en   <= 1'b1;
                wr_haz    <= ^w_status && inst_addr[31:2] == w_addr[31:2];
            end
            if(r_from && wr_haz) begin
                wr_haz    <= ^w_status;
            end else if(!r_from && wr_haz) begin
                wr_haz    <= ^w_status;
            end
            if(arvalid && arready) begin
                arvalid_en   <= 1'b0;
                r_status     <= 2'b10;
            end

        end else if(r_status == 2'b10) begin
            if(rvalid && r_from) begin
                r_status     <= 2'b11;
                data_rdata   <= rdata;
            end else if(rvalid && !r_from) begin
                r_status     <= 2'b11;
                inst_rdata   <= rdata;
            end

        end else if(r_status == 2'b11) begin
            r_status         <= 2'b00;
        end
    end
end

always @(posedge clk) begin
    if(!resetn) begin
        w_status     <= 2'd0;
        w_from       <= 1'b0;
        w_size       <= 2'd0;
        w_addr       <= 32'd0;
        w_data       <= 32'd0;
        awvalid_en   <= 1'b0;
        wvalid_en    <= 1'b0;
        rw_haz    <= 1'b0;

    end else begin
        if(w_status == 2'b00) begin
            if(data_req && data_wr) begin
                w_status     <= 2'b01;
                w_from       <= 1'b1;
            end else if(inst_req && inst_wr) begin
                w_status     <= 2'b01;
                w_from       <= 1'b0;
            end

        end else if(w_status == 2'b01) begin
            if(w_from && data_addr_ok && !awvalid_en && !wvalid_en) begin
                w_size       <= data_size;
                w_addr       <= data_addr;
                w_data       <= data_wdata;
                awvalid_en   <= 1'b1;
                wvalid_en    <= 1'b1;
                rw_haz    <= ^r_status && data_addr[31:2] == r_addr[31:2];
            end else if(!w_from && inst_addr_ok && !awvalid_en && !wvalid_en) begin
                w_size       <= inst_size;
                w_addr       <= inst_addr;
                w_data       <= inst_wdata;
                awvalid_en   <= 1'b1;
                wvalid_en    <= 1'b1;
                rw_haz    <= ^r_status && inst_addr[31:2] == r_addr[31:2];
            end
            if(w_from && rw_haz) begin
                rw_haz    <= ^r_status;
            end else if(!w_from && rw_haz) begin
                rw_haz    <= ^r_status;
            end
            if(awvalid && awready) begin
                awvalid_en   <= 1'b0;
            end
            if(wvalid && wready) begin
                wvalid_en    <= 1'b0;
            end
            if((awvalid && awready && wvalid && wready) || (awvalid && awready && !wvalid) || (wvalid && wready && !awvalid)) begin
                w_status     <= 2'b10;
            end

        end else if(w_status == 2'b10) begin
            if(bvalid && w_from) begin
                w_status     <= 2'b11;
            end else if(bvalid && !w_from) begin
                w_status     <= 2'b11;
            end

        end else if(w_status == 2'b11) begin
            w_status         <= 2'b00;
        end
    end
end

always @(*) begin
    case({w_size, w_addr[1:0]})
    4'b00_00: wstrb = 4'b0001;
    4'b00_01: wstrb = 4'b0010;
    4'b00_10: wstrb = 4'b0100;
    4'b00_11: wstrb = 4'b1000;
    4'b01_00: wstrb = 4'b0011;
    4'b01_10: wstrb = 4'b1100;
    4'b10_00: wstrb = 4'b1111;
    default : wstrb = 4'b0000;
    endcase
end

assign inst_addr_ok = (r_status == 2'b01 && r_from == 1'b0 && arvalid == 1'b0 && !wr_haz) ||
                      (w_status == 2'b01 && w_from == 1'b0 && awvalid == 1'b0 && wvalid == 1'b0 && !rw_haz);

assign inst_data_ok = (r_status == 2'b11 && r_from == 1'b0) ||
                      (w_status == 2'b11 && w_from == 1'b0) ;

assign data_addr_ok = (r_status == 2'b01 && r_from == 1'b1 && arvalid == 1'b0 && !wr_haz) ||
                      (w_status == 2'b01 && w_from == 1'b1 && awvalid == 1'b0 && wvalid == 1'b0 && !rw_haz);

assign data_data_ok = (r_status == 2'b11 && r_from == 1'b1) ||
                      (w_status == 2'b11 && w_from == 1'b1) ;

assign araddr  = r_addr;
assign arsize  = {1'b0, r_size};
assign arvalid = arvalid_en && !wr_haz;
assign rready  = (r_status == 2'b10);

assign awaddr  = w_addr;
assign awsize  = {1'b0, w_size};
assign wdata   = w_data;
assign awvalid = awvalid_en && !rw_haz;
assign wvalid  = wvalid_en  && !rw_haz;
assign bready  = (w_status == 2'b10);

assign arid    = 4'd0 ;
assign arlen   = 8'd0 ;
assign arburst = 2'b01;
assign arlock  = 2'd0 ;
assign arcache = 4'd0 ;
assign arprot  = 3'd0 ;

assign awid    = 4'd0 ;
assign awlen   = 8'd0 ;
assign awburst = 2'b01;
assign awlock  = 2'd0 ;
assign awcache = 4'd0 ;
assign awprot  = 3'd0 ;

assign wid     = 4'd0 ;
assign wlast   = 1'b1 ;

endmodule
