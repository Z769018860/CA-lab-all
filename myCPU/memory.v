
module memory(
    input  wire                       clk,
    input  wire                       rst,
    // control signals transfering from EXE stage
    input  wire             MemEn_EX_MEM,
    input  wire          MemToReg_EX_MEM,
    input  wire  [ 3:0]  MemWrite_EX_MEM,
    input  wire  [ 3:0]  RegWrite_EX_MEM,
    input  wire  [ 1:0]      MFHL_EX_MEM,
    input  wire                LB_EX_MEM, 
    input  wire               LBU_EX_MEM, 
    input  wire                LH_EX_MEM, 
    input  wire               LHU_EX_MEM, 
    input  wire  [ 1:0]        LW_EX_MEM, 
    // data passing from EXE stage
    input  wire  [ 4:0]  RegWaddr_EX_MEM,
    input  wire  [31:0] ALUResult_EX_MEM,
    input  wire  [31:0]  MemWdata_EX_MEM,
    input  wire  [31:0] RegRdata2_EX_MEM, 
    input  wire  [31:0]        PC_EX_MEM,
    input  wire  [ 1:0]   s_vaddr_EX_MEM,
    input  wire  [ 2:0]    s_size_EX_MEM,

    input        [ 1:0]      MULT_EX_MEM,
    input        [ 1:0]      MTHL_EX_MEM,
    output       [ 1:0]          MULT_MEM,
    output       [ 1:0]          MTHL_MEM,
    


/*    // interaction with the data_sram
    output wire  [31:0]      MemWdata_MEM,
    output wire                 MemEn_MEM,
    output wire  [ 3:0]      MemWrite_MEM,
    output wire  [31:0]    data_sram_addr,
*/

    // output control signals to WB stage
    output reg            MemToReg_MEM_WB,
    output reg   [ 3:0]   RegWrite_MEM_WB,
    output reg   [ 1:0]       MFHL_MEM_WB,
    output reg                  LB_MEM_WB,
    output reg                 LBU_MEM_WB,
    output reg                  LH_MEM_WB,
    output reg                 LHU_MEM_WB,
    output reg   [ 1:0]         LW_MEM_WB,

    // output data to WB stage
    output reg   [ 4:0]   RegWaddr_MEM_WB,
    output reg   [31:0]  ALUResult_MEM_WB,
    output reg   [31:0]  RegRdata2_MEM_WB,
    output reg   [31:0]         PC_MEM_WB,
    output reg   [31:0]   MemRdata_MEM_WB,

    output wire  [31:0]        Bypass_MEM,  //Bypass
    
    input  wire  [31:0] cp0Rdata_EX_MEM,
    input  wire             mfc0_EX_MEM,
    output reg   [31:0]  cp0Rdata_MEM_WB,
    output reg               mfc0_MEM_WB,

    input                      wb_allowin,
    input                exe_to_mem_valid,
    output                    mem_allowin,
    output                mem_to_wb_valid,

    output reg   [ 1:0]        data_r_req,
    output reg               do_req_raddr,

    input        [31:0]     mem_axi_rdata,
    input                   mem_axi_rvalid,
    input        [ 3:0]     mem_axi_rid,
    output                  mem_axi_rready,

    output       [ 3:0]     mem_axi_arid,
    output       [31:0]     mem_axi_araddr,
    output       [ 2:0]     mem_axi_arsize,
    input                   mem_axi_arready,
    output                  mem_axi_arvalid,

    output       [ 3:0]     mem_axi_awid,
    output       [31:0]     mem_axi_awaddr,
    output       [ 2:0]     mem_axi_awsize,
    output                  mem_axi_awvalid,
    input                   mem_axi_awready,

    output       [ 3:0]     mem_axi_wid,
    output       [31:0]     mem_axi_wdata,
    output       [ 3:0]     mem_axi_wstrb,
    output                  mem_axi_wvalid,
    input                   mem_axi_wready,

    output                  mem_axi_bready,
    input        [ 3:0]     mem_axi_bid,
    input                   mem_axi_bvalid,

    input        [ 3:0]     cpu_arid,

    output                  mem_read_req,

    output      mem_stage_valid
);
    
    wire mem_ready_go;
    reg mem_valid;
    
    wire read_req;
    wire write_req;
    
    wire arvalid;
    wire arready;

    wire [3:0] rid;    
    reg  rready;
    wire rvalid;   
     
    reg  awvalid;
    wire awready;
    

    reg  wvalid;
    wire wready;

    
    wire bvalid;
    wire bready;
    wire [3:0] bid;
    
    reg [1:0] data_w_req;
    
    reg [0:3] do_req_waddr;
    reg [0:3] do_req_wdata;
    wire [0:3] do_req_waddr_pos;  
    wire [0:3] do_req_wdata_pos;      
    
    reg r_addr_rcv;

    reg [0:3] w_addr_rcv;
    reg [0:3] w_data_rcv;
    

    reg [1:0] data_in_ready [0:3];
    
    wire r_data_back;
    wire [0:3] w_data_back;

    reg [32:0] do_waddr_r [0:3];
    reg [ 3:0] do_dsize_r [0:3];

    wire [4:0] write_id_n;
    wire pot_hazard;
    
    wire data_w_req_pos;               
    wire data_r_req_pos;

    wire r_addr_rcv_pos;    
    wire [0:3] data_in_ready_pos;               
    
    reg [2:0] do_write_id;

    wire arid;
    assign arid =  cpu_arid;
    
    
    assign mem_ready_go    =  (data_r_req==2'd0&&!read_req&&data_w_req==2'd0&&!write_req) || //No memw or memr
                              (data_r_req==2'd2&&r_data_back) ||                             //memrdata returns
                              (data_w_req==2'd2&&(|data_in_ready_pos));                      //memwrite, addr and data all in
    assign mem_allowin     = !mem_valid || mem_ready_go && wb_allowin;
    assign mem_to_wb_valid = mem_valid && mem_ready_go;
    
    always @ (posedge clk) begin
        if (rst) begin
            mem_valid <= 1'b0;
        end
        else if (mem_allowin) begin
            mem_valid <= exe_to_mem_valid;
        end
    end
    
    assign mem_stage_valid = mem_valid;
    
//Select awid, wid
    assign write_id_n = do_waddr_r[0][32]==1'b0 ? 4'd0 :
                        do_waddr_r[1][32]==1'b0 ? 4'd1 :
                        do_waddr_r[2][32]==1'b0 ? 4'd2 :
                        do_waddr_r[3][32]==1'b0 ? 4'd3 : 4'd4;

    always @ (posedge clk) begin
        if (rst) begin
            do_write_id <= 3'd0;
        end
        else
        if (data_w_req_pos) begin
            do_write_id <= write_id_n;
        end
    end

//Potential hazard between previous store and current write;
    assign pot_hazard = mem_axi_araddr==(do_waddr_r[0][31:0]&32'hfffffffc) && do_waddr_r[0][32] ||
                        mem_axi_araddr==(do_waddr_r[1][31:0]&32'hfffffffc) && do_waddr_r[1][32] ||
                        mem_axi_araddr==(do_waddr_r[2][31:0]&32'hfffffffc) && do_waddr_r[2][32] ||
                        mem_axi_araddr==(do_waddr_r[3][31:0]&32'hfffffffc) && do_waddr_r[3][32] ;


    // interaction of signals and data with data_sram

    assign Bypass_MEM      =      mfc0_EX_MEM ? 
                              cp0Rdata_EX_MEM : ALUResult_EX_MEM;

    assign mem_axi_wid     = do_write_id;
    assign mem_axi_wstrb   = MemWrite_EX_MEM;
    assign mem_axi_wdata   = MemWdata_EX_MEM;
    assign mem_axi_wvalid  = wvalid && mem_valid;
    assign wready = mem_axi_wready;

    assign mem_axi_awid    = do_write_id;
    assign mem_axi_awvalid = awvalid && mem_valid;
    assign mem_axi_awaddr  = {ALUResult_EX_MEM[31:2],s_vaddr_EX_MEM};
    assign mem_axi_awsize  =  s_size_EX_MEM;/*根据SW,SB,SH,SWL,SWR来改*/
    assign awready = mem_axi_awready;
    

    assign mem_axi_arid    = 4'd1;
    assign mem_axi_araddr  = {ALUResult_EX_MEM[31:2],2'b00};
    assign mem_axi_arsize  = (|LW_EX_MEM)|
                               LH_EX_MEM | LHU_EX_MEM |
                               LB_EX_MEM | LBU_EX_MEM ? 3'b010 : 3'b00; /*根据LW,LB,LH来改*/
    assign mem_axi_arvalid = arvalid && mem_valid;
    assign arready = mem_axi_arready;
    assign arvalid = do_req_raddr;



    assign rvalid = mem_axi_rvalid;
    assign rid    = mem_axi_rid;

    assign mem_axi_rready = rready;


    assign bid = mem_axi_bid;
    assign bvalid = mem_axi_bvalid;
    


    
    assign mem_axi_bready = bready;


    always @ (posedge clk) begin
        if (rst) begin
            { 
                 PC_MEM_WB,  RegWaddr_MEM_WB, MemToReg_MEM_WB, RegWrite_MEM_WB, 
          ALUResult_MEM_WB, RegRdata2_MEM_WB, cp0Rdata_MEM_WB,     MFHL_MEM_WB, 
                 LB_MEM_WB,       LBU_MEM_WB,       LH_MEM_WB,      LHU_MEM_WB,
                 LW_MEM_WB,      mfc0_MEM_WB, MemRdata_MEM_WB
            } <= 'd0;
        end
        else if (mem_to_wb_valid && wb_allowin) begin
            PC_MEM_WB        <=        PC_EX_MEM;
            RegWaddr_MEM_WB  <=  RegWaddr_EX_MEM;
            MemToReg_MEM_WB  <=  MemToReg_EX_MEM;
            RegWrite_MEM_WB  <=  RegWrite_EX_MEM;
            ALUResult_MEM_WB <= ALUResult_EX_MEM;
            RegRdata2_MEM_WB <= RegRdata2_EX_MEM;
            cp0Rdata_MEM_WB  <=  cp0Rdata_EX_MEM;
            MFHL_MEM_WB      <=      MFHL_EX_MEM;
            LB_MEM_WB        <=        LB_EX_MEM;
            LBU_MEM_WB       <=       LBU_EX_MEM;
            LH_MEM_WB        <=        LH_EX_MEM;
            LHU_MEM_WB       <=       LHU_EX_MEM;
            LW_MEM_WB        <=        LW_EX_MEM;
            mfc0_MEM_WB      <=      mfc0_EX_MEM;
            MemRdata_MEM_WB  <=     mem_axi_rdata;
        end
    end

    assign MULT_MEM = MULT_EX_MEM & {2{mem_valid}};
    assign MTHL_MEM = MTHL_EX_MEM & {2{mem_valid}};

    assign mem_read_req = read_req;

    assign write_req = |MemWrite_EX_MEM && mem_valid;
    assign read_req  =  MemEn_EX_MEM && ~(|MemWrite_EX_MEM) && mem_valid;
    always @(posedge clk) 
    begin
        //若表满，则不能发写请求
        data_w_req  <=  rst ? 2'd0 :
                        data_w_req==2'd0 ? 
                            (write_req ? 
                                (write_id_n!=4'd4 ? 2'd2 : 2'd1) 
                            : data_w_req)
                        :   (data_w_req==2'd1   ? 
                            (write_id_n!=4'd4   ? 2'd2 : data_w_req)
                        :   (|data_in_ready_pos ? 2'd0 : data_w_req));
      
        //有潜在的相关可能，则不能发读请求
        data_r_req  <=  rst ? 2'd0 :
                        data_r_req==2'd0 ? 
                            read_req ? 
                                !pot_hazard ? 2'd2 : 2'd1
                            : data_r_req
                        :data_r_req==2'd1 ?
                            !pot_hazard ? 2'd2 : data_r_req
                        :r_data_back ? 2'd0 : data_r_req;
    end

    always @ (posedge clk) begin
        
    end

    always @ (posedge clk) begin
        if (rst) begin
            do_waddr_r[0] <= 33'd0;
            do_waddr_r[1] <= 33'd0;
            do_waddr_r[2] <= 33'd0;
            do_waddr_r[3] <= 33'd0;

            do_dsize_r[0] <= 3'd0;
            do_dsize_r[1] <= 3'd0;
            do_dsize_r[2] <= 3'd0;
            do_dsize_r[3] <= 3'd0;
        end
        else
        if (data_w_req_pos) begin
            if (write_id_n==4'd0) begin
                if (bvalid&&bready) begin
                    if (bid==4'd1) do_waddr_r[1] <= 33'd0;
                    if (bid==4'd2) do_waddr_r[2] <= 33'd0;
                    if (bid==4'd3) do_waddr_r[3] <= 33'd0;
                end   
                do_waddr_r[0] <= {1'b1,mem_axi_awaddr};
                do_dsize_r[0] <= mem_axi_awsize;
            end
            if (write_id_n==4'd1) begin
                if (bvalid&&bready) begin
                    if (bid==4'd0) do_waddr_r[0] <= 33'd0;
                    if (bid==4'd2) do_waddr_r[2] <= 33'd0;
                    if (bid==4'd3) do_waddr_r[3] <= 33'd0;
                end
                do_waddr_r[1] <= {1'b1,mem_axi_awaddr};
                do_dsize_r[1] <= mem_axi_awsize;
            end
            if (write_id_n==4'd2) begin
                if (bvalid&&bready) begin
                    if (bid==4'd0) do_waddr_r[0] <= 33'd0;
                    if (bid==4'd1) do_waddr_r[1] <= 33'd0;
                    if (bid==4'd3) do_waddr_r[3] <= 33'd0;
                end
                do_waddr_r[2] <= {1'b1,mem_axi_awaddr};
                do_dsize_r[2] <= mem_axi_awsize;
            end
            if (write_id_n==4'd3) begin
                if (bvalid&&bready) begin
                    if (bid==4'd0) do_waddr_r[0] <= 33'd0;
                    if (bid==4'd1) do_waddr_r[1] <= 33'd0;
                    if (bid==4'd2) do_waddr_r[2] <= 33'd0;
                end
                do_waddr_r[3] <= {1'b1,mem_axi_awaddr};
                do_dsize_r[3] <= mem_axi_awsize;
            end
        end
        else if (bvalid&&bready) begin
            if (bid==4'd0) do_waddr_r[0] <= 33'd0;
            if (bid==4'd1) do_waddr_r[1] <= 33'd0;
            if (bid==4'd2) do_waddr_r[2] <= 33'd0;
            if (bid==4'd3) do_waddr_r[3] <= 33'd0;            
        end
    end

    always @ (posedge clk) begin
        do_req_raddr    <= rst               ? 1'b0 :
                           data_r_req_pos    ? 1'b1 :
                           r_addr_rcv_pos    ? 1'b0 : do_req_raddr;
    end

    always @(posedge clk) begin
        r_addr_rcv <= rst                          ? 1'b0 :
                      arvalid&&arready&&arid==4'd1 ? 1'b1 :
                      r_data_back                  ? 1'b0 : r_addr_rcv;
        rready     <= rst              ? 1'b0 :
                      r_addr_rcv_pos   ? 1'b1 :
                      r_data_back      ? 1'b0 : rready;
    end
    assign r_data_back = r_addr_rcv && (rvalid && rready && rid==4'd1);


    assign w_data_back[0] = (w_addr_rcv[0]&&w_data_rcv[0]) && (bvalid && bready && bid==4'd0);
    assign w_data_back[1] = (w_addr_rcv[1]&&w_data_rcv[1]) && (bvalid && bready && bid==4'd1);
    assign w_data_back[2] = (w_addr_rcv[2]&&w_data_rcv[2]) && (bvalid && bready && bid==4'd2);
    assign w_data_back[3] = (w_addr_rcv[3]&&w_data_rcv[3]) && (bvalid && bready && bid==4'd3);
    
    
    always @ (posedge clk) begin
        if (rst) begin
            do_req_waddr[0]  <= 1'b0;
            do_req_waddr[1]  <= 1'b0;
            do_req_waddr[2]  <= 1'b0;
            do_req_waddr[3]  <= 1'b0;

            do_req_wdata[0]  <= 1'b0;
            do_req_wdata[1]  <= 1'b0;
            do_req_wdata[2]  <= 1'b0;
            do_req_wdata[3]  <= 1'b0;

            data_in_ready[0] <= 2'b00;
            data_in_ready[1] <= 2'b00;
            data_in_ready[2] <= 2'b00;
            data_in_ready[3] <= 2'b00;
        end
        else begin
            if (data_w_req_pos) begin
                if (write_id_n==3'd0) begin
                    do_req_waddr[0] <= 1'b1;
                    do_req_wdata[0] <= 1'b1;
                end
                if (write_id_n==3'd1) begin
                    do_req_waddr[1] <= 1'b1;
                    do_req_wdata[1] <= 1'b1;
                end
                if (write_id_n==3'd2) begin
                    do_req_waddr[2] <= 1'b1;
                    do_req_wdata[2] <= 1'b1;
                end
                if (write_id_n==3'd3) begin
                    do_req_waddr[3] <= 1'b1;
                    do_req_wdata[3] <= 1'b1;
                end
            end
            else begin
                if (data_in_ready_pos[0]) begin
                    do_req_waddr[0] <= 1'b0;
                    do_req_wdata[0] <= 1'b0;
                end
                if (data_in_ready_pos[1]) begin
                    do_req_waddr[1] <= 1'b0;
                    do_req_wdata[1] <= 1'b0;
                end
                if (data_in_ready_pos[2]) begin
                    do_req_waddr[2] <= 1'b0;
                    do_req_wdata[2] <= 1'b0;
                end
                if (data_in_ready_pos[3]) begin
                    do_req_waddr[3] <= 1'b0;
                    do_req_wdata[3] <= 1'b0;
                end
            end
            if (do_write_id==3'd0) begin
                if (awvalid&&awready && wvalid&&wready) begin
                    data_in_ready[0] <= 2'b11;
                end
                else if (awvalid&&awready) begin
                    data_in_ready[0] <= data_in_ready[0] + 2'b01;
                end
                else if (wvalid&&wready) begin
                    data_in_ready[0] <= data_in_ready[0] + 2'b10;
                end
            end
            if (w_data_back[0]) begin
                data_in_ready[0] <= 2'b00;
            end

            if (do_write_id==3'd1) begin
                if (awvalid&&awready && wvalid&&wready) begin
                    data_in_ready[1] <= 2'b11;
                end
                else if (awvalid&&awready) begin
                    data_in_ready[1] <= data_in_ready[1] + 2'b01;
                end
                else if (wvalid&&wready) begin
                    data_in_ready[1] <= data_in_ready[1] + 2'b10;
                end
            end
            if (w_data_back[1]) begin
                data_in_ready[1] <= 2'b00;
            end

            if (do_write_id==3'd2) begin
                if (awvalid&&awready && wvalid&&wready) begin
                    data_in_ready[2] <= 2'b11;
                end
                else if (awvalid&&awready) begin
                    data_in_ready[2] <= data_in_ready[2] + 2'b01;
                end
                else if (wvalid&&wready) begin
                    data_in_ready[2] <= data_in_ready[2] + 2'b10;
                end
            end
            if (w_data_back[2]) begin
                data_in_ready[2] <= 2'b00;
            end

            if (do_write_id==3'd3) begin
                if (awvalid&&awready && wvalid&&wready) begin
                    data_in_ready[3] <= 2'b11;
                end
                else if (awvalid&&awready) begin
                    data_in_ready[3] <= data_in_ready[3] + 2'b01;
                end
                else if (wvalid&&wready) begin
                    data_in_ready[3] <= data_in_ready[3] + 2'b10;
                end
            end
            if (w_data_back[3]) begin
                data_in_ready[3] <= 2'b00;
            end

        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            awvalid <= 1'b0;
            wvalid  <= 1'b0;
        end
        else begin
            if (|do_req_waddr_pos) begin
                awvalid <= 1'b1;
            end
            else if (awready) begin
                awvalid <= 1'b0;
            end

            if (|do_req_wdata_pos) begin
                wvalid <= 1'b1;
            end
            else if (wready) begin
                wvalid <= 1'b0;
            end
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            w_addr_rcv[0] <= 1'b0;
            w_addr_rcv[1] <= 1'b0;
            w_addr_rcv[2] <= 1'b0;
            w_addr_rcv[3] <= 1'b0;
            
            w_data_rcv[0] <= 1'b0;
            w_data_rcv[1] <= 1'b0;
            w_data_rcv[2] <= 1'b0;
            w_data_rcv[3] <= 1'b0;
        end
        else begin
            if (awvalid&&awready) begin
                if (do_write_id==3'd0) begin
                    w_addr_rcv[0] <= 1'b1;
                end
                if (do_write_id==3'd1) begin
                    w_addr_rcv[1] <= 1'b1;
                end
                if (do_write_id==3'd2) begin
                    w_addr_rcv[2] <= 1'b1;
                end
                if (do_write_id==3'd3) begin
                    w_addr_rcv[3] <= 1'b1;
                end
            end

            if (wvalid&&wready) begin
                if (do_write_id==3'd0) begin
                    w_data_rcv[0] <= 1'b1;
                end
                if (do_write_id==3'd1) begin
                    w_data_rcv[1] <= 1'b1;
                end
                if (do_write_id==3'd2) begin
                    w_data_rcv[2] <= 1'b1;
                end
                if (do_write_id==3'd3) begin
                    w_data_rcv[3] <= 1'b1;
                end
            end

            if (w_data_back[0]) begin
                w_addr_rcv[0] <= 1'b0;
                w_data_rcv[0] <= 1'b0;
            end
            if (w_data_back[1]) begin
                w_addr_rcv[1] <= 1'b0;
                w_data_rcv[1] <= 1'b0;
            end
            if (w_data_back[2]) begin
                w_addr_rcv[2] <= 1'b0;
                w_data_rcv[2] <= 1'b0;
            end
            if (w_data_back[3]) begin
                w_addr_rcv[3] <= 1'b0;
                w_data_rcv[3] <= 1'b0;
            end
        end
    end

    assign bready = 1'b1;



    assign data_w_req_pos = data_w_req==2'd0 && write_req && write_id_n!=4'd4 ||
                            data_w_req==2'd1 && write_id_n!=4'd4;
    assign data_r_req_pos = data_r_req==2'd0 && read_req && !pot_hazard ||
                            data_r_req==2'd1 && !pot_hazard;

    assign r_addr_rcv_pos = !r_addr_rcv && arvalid&&arready&&arid==4'd1;


    assign data_in_ready_pos[0] = data_in_ready[0]==2'd1 && wvalid&&wready   || 
                                  data_in_ready[0]==2'd2 && awvalid&&awready ||
                                  data_in_ready[0]==2'd0 && awvalid&&awready && wvalid&&wready;
    assign data_in_ready_pos[1] = data_in_ready[1]==2'd1 && wvalid&&wready   || 
                                  data_in_ready[1]==2'd2 && awvalid&&awready ||
                                  data_in_ready[1]==2'd0 && awvalid&&awready && wvalid&&wready;
    assign data_in_ready_pos[2] = data_in_ready[2]==2'd1 && wvalid&&wready   || 
                                  data_in_ready[2]==2'd2 && awvalid&&awready ||
                                  data_in_ready[2]==2'd0 && awvalid&&awready && wvalid&&wready;
    assign data_in_ready_pos[3] = data_in_ready[3]==2'd1 && wvalid&&wready   || 
                                  data_in_ready[3]==2'd2 && awvalid&&awready ||
                                  data_in_ready[3]==2'd0 && awvalid&&awready && wvalid&&wready;


    assign do_req_waddr_pos[0]  = !do_req_waddr[0] && data_w_req_pos && write_id_n==3'd0;
    assign do_req_waddr_pos[1]  = !do_req_waddr[1] && data_w_req_pos && write_id_n==3'd1;
    assign do_req_waddr_pos[2]  = !do_req_waddr[2] && data_w_req_pos && write_id_n==3'd2;
    assign do_req_waddr_pos[3]  = !do_req_waddr[3] && data_w_req_pos && write_id_n==3'd3;

    assign do_req_wdata_pos[0]  = !do_req_wdata[0] && data_w_req_pos && write_id_n==3'd0;
    assign do_req_wdata_pos[1]  = !do_req_wdata[1] && data_w_req_pos && write_id_n==3'd1;
    assign do_req_wdata_pos[2]  = !do_req_wdata[2] && data_w_req_pos && write_id_n==3'd2;
    assign do_req_wdata_pos[3]  = !do_req_wdata[3] && data_w_req_pos && write_id_n==3'd3;



endmodule //memory_stage

