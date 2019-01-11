`timescale 10ns / 1ns

module fetch(
    input  wire        clk,
    input  wire        rst,
    // delay slot tag
    input  wire        DSI_DE, // delay slot instruction tag
    // data passing from the PC calculate module
    input  wire        IRWrite,
    // For Stall
 //   input  wire [31:0] PC_next,
    input  wire        PC_AdEL,
    // interaction with inst_sram
    
    input  [31:0]        PC_buffer,
    // data transfering to ID stage
    output reg  [31:0]       PC_IF_DE,           //fetch_stage pc
    output reg  [31:0] PC_add_4_IF_DE,
    output      [31:0]       IR_IF_DE,           //instr code sent from fetch_stage
    // signal passing to ID stage
    output reg          PC_AdEL_IF_DE,
    output reg              DSI_IF_DE,

    input       [ 1:0] data_r_req,               //Doing data read request
//   input              do_req_raddr,             //Request for raddr


    output             fetch_axi_rready ,
    input              fetch_axi_rvalid ,
    input       [31:0] fetch_axi_rdata  ,
    input       [ 3:0] fetch_axi_rid    ,

    input              fetch_axi_arready,
//    output             fetch_axi_arvalid,

    input              decode_allowin,
    output             fe_to_de_valid,

    output             IR_buffer_valid
  );
    parameter reset_addr = 32'hbfc00000;


    reg [32:0] IR_buffer;
    reg [31:0] IR;
    wire fetch_allowin;
    wire fetch_ready_go;
    
    
    assign IR_IF_DE = IR;

    assign fetch_axi_rready = decode_allowin || data_r_req!=2'd0; //IRWrite should be included in decode_allowin
    
    wire fetch_valid;

    
    assign IR_buffer_valid = IR_buffer[32];

    assign fetch_valid = fetch_ready_go;
    assign fetch_ready_go = fetch_axi_rvalid && fetch_axi_rid==4'd0 && data_r_req==2'd0 || IR_buffer_valid;
    assign fe_to_de_valid = fetch_valid && fetch_ready_go; 



    always @(posedge clk) begin // rdata 
        if (rst) begin
          IR             <= 32'd0;
          IR_buffer      <= 33'd0;
          PC_IF_DE       <= 32'd0;
          PC_add_4_IF_DE <= 32'd0;
          PC_AdEL_IF_DE  <=  1'd0;
          DSI_IF_DE      <=  1'd0;
        end
        else if (!IR_buffer_valid) begin
            if (fetch_axi_rready&&fetch_axi_rvalid) begin
                if (data_r_req==2'd0) begin
                    if (fetch_axi_rid==4'd0) begin
                        IR             <= fetch_axi_rdata;
                        PC_IF_DE       <= PC_buffer;
                        PC_add_4_IF_DE <= PC_buffer + 32'd4;
                        PC_AdEL_IF_DE  <= PC_AdEL;
                        DSI_IF_DE      <= DSI_DE;
                    end
                end
                else begin
                    if (fetch_axi_rid==4'd0) begin
                        IR_buffer <= {1'b1,fetch_axi_rdata};
                    end
                    //else mem_rdata returns, jobs done in mem_stage
                end
            end
        end
        else begin
            if (decode_allowin&&IRWrite) begin
                IR             <= IR_buffer;
                IR_buffer      <= 33'd0;
                PC_IF_DE       <= PC_buffer;
                PC_add_4_IF_DE <= PC_buffer + 32'd4;
                PC_AdEL_IF_DE  <= PC_AdEL;
                DSI_IF_DE      <= DSI_DE;
            end
        end
    end


endmodule //fetch_stage