`define MEM_ARID 4'd1
`define INST_ARID 4'd0


module mycpu_top(
    input              clk,
    input              resetn, 
    input       [ 5:0] int,
    // read address channel
    output      [ 3:0] cpu_arid,         // M->S 
    output      [31:0] cpu_araddr,       // M->S 
    output      [ 7:0] cpu_arlen,        // M->S 
    output      [ 2:0] cpu_arsize,       // M->S 
    output      [ 1:0] cpu_arburst,      // M->S 
    output      [ 1:0] cpu_arlock,       // M->S 
    output      [ 3:0] cpu_arcache,      // M->S 
    output      [ 2:0] cpu_arprot,       // M->S 
    output             cpu_arvalid,      // M->S 
    input              cpu_arready,      // S->M 
    // read data channel
    input       [ 3:0] cpu_rid,          // S->M 
    input       [31:0] cpu_rdata,        // S->M 
    input       [ 1:0] cpu_rresp,        // S->M 
    input              cpu_rlast,        // S->M 
    input              cpu_rvalid,       // S->M 
    output             cpu_rready,       // M->S
    // write address channel 
    output      [ 3:0] cpu_awid,         // M->S
    output      [31:0] cpu_awaddr,       // M->S
    output      [ 7:0] cpu_awlen,        // M->S
    output      [ 2:0] cpu_awsize,       // M->S
    output      [ 1:0] cpu_awburst,      // M->S
    output      [ 1:0] cpu_awlock,       // M->S
    output      [ 3:0] cpu_awcache,      // M->S
    output      [ 2:0] cpu_awprot,       // M->S
    output             cpu_awvalid,      // M->S
    input              cpu_awready,      // S->M
    // write data channel
    output      [ 3:0] cpu_wid,          // M->S
    output      [31:0] cpu_wdata,        // M->S
    output      [ 3:0] cpu_wstrb,        // M->S
    output             cpu_wlast,        // M->S
    output             cpu_wvalid,       // M->S
    input              cpu_wready,       // S->M
    // write response channel
    input       [ 3:0] cpu_bid,          // S->M 
    input       [ 1:0] cpu_bresp,        // S->M 
    input              cpu_bvalid,       // S->M 
    output             cpu_bready        // M->S 

    // debug signals

   ,output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_wen,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
 
  );
parameter ADDR = 32'hbfc00000;
parameter except_addr = 32'hbfc00380; //new 例外处理入口地址

// we only need an inst ROM now
//assign inst_sram_wen   = 4'b0;
//assign inst_sram_wdata = 32'b0;

reg   rst;
always @(posedge clk) rst <= ~resetn;
wire                     JSrc;
wire [ 1:0]             PCSrc;

wire [ 4:0]         RegRaddr1;
wire [ 4:0]         RegRaddr2;
wire [31:0]         RegRdata1;
wire [31:0]         RegRdata2;

wire                   DSI_DE;
wire                DSI_IF_DE;

reg [31:0]           nextpc;
wire [31:0]          PC_IF_DE;
wire [31:0]    PC_add_4_IF_DE;
wire            PC_AdEL_IF_DE;
reg                  PC_AdEL;
wire [31:0]          IR_IF_DE;

wire                  PCWrite;
wire                  IRWrite;

wire [31:0]       J_target_DE;
wire [31:0]      JR_target_DE;
wire [31:0]      Br_target_DE;
wire [31:0]       PC_add_4_DE;

wire [ 1:0]     RegRdata1_src;
wire [ 1:0]     RegRdata2_src;

wire               is_rs_read;
wire               is_rt_read;
wire             DE_EX_Stall;

wire [31:0]         PC_DE_EX;
wire [31:0]   PC_add_4_DE_EX;
wire [ 1:0]     RegDst_DE_EX;
wire [ 1:0]    ALUSrcA_DE_EX;
wire [ 1:0]    ALUSrcB_DE_EX;
wire [ 3:0]      ALUop_DE_EX;
wire [ 3:0]   RegWrite_DE_EX;
wire [ 3:0]   MemWrite_DE_EX;
wire         is_signed_DE_EX;
wire             MemEn_DE_EX;
wire          MemToReg_DE_EX;
wire [ 1:0]       MULT_DE_EX;
wire [ 1:0]        DIV_DE_EX;
wire [ 1:0]       MFHL_DE_EX;
wire [ 1:0]       MTHL_DE_EX;
wire                LB_DE_EX; 
wire               LBU_DE_EX; 
wire                LH_DE_EX; 
wire               LHU_DE_EX; 
wire [ 1:0]         LW_DE_EX; 
wire [ 1:0]         SW_DE_EX; 
wire                SB_DE_EX; 
wire                SH_DE_EX; 

wire [ 4:0]   RegWaddr_DE_EX;
wire [31:0]     ALUResult_EX;
wire [31:0]     ALUResult_MEM;

wire [ 1:0]           DIV_EX;
wire [ 1:0]          MULT_EX;

wire [31:0]  RegRdata1_DE_EX;
wire [31:0]  RegRdata2_DE_EX;
wire [31:0]         Sa_DE_EX;
wire [31:0]  SgnExtend_DE_EX;
wire [31:0]    ZExtend_DE_EX;

wire            MemEn_EX_MEM;
wire         MemToReg_EX_MEM;
wire [ 3:0]  MemWrite_EX_MEM;
wire [ 3:0]  RegWrite_EX_MEM;
wire [ 3:0]      RegWrite_EX;
wire [ 4:0]  RegWaddr_EX_MEM;
wire [ 1:0]      MULT_EX_MEM;
wire [ 1:0]      MFHL_EX_MEM;
wire [ 1:0]      MTHL_EX_MEM;
wire               LB_EX_MEM; 
wire              LBU_EX_MEM; 
wire               LH_EX_MEM; 
wire              LHU_EX_MEM; 
wire [ 1:0]        LW_EX_MEM; 
wire [31:0] ALUResult_EX_MEM;
wire [31:0]  MemWdata_EX_MEM;
wire [31:0]        PC_EX_MEM;
wire [31:0] RegRdata1_EX_MEM;
wire [31:0] RegRdata2_EX_MEM;
wire [ 1:0]   s_vaddr_EX_MEM;
wire [ 2:0]    s_size_EX_MEM;

wire [ 1:0]          MULT_MEM;
wire [ 1:0]          MTHL_MEM;

wire          MemToReg_MEM_WB;
wire [ 3:0]   RegWrite_MEM_WB;
wire [ 4:0]   RegWaddr_MEM_WB;
wire [ 1:0]       MFHL_MEM_WB;
wire                LB_MEM_WB; 
wire               LBU_MEM_WB; 
wire                LH_MEM_WB; 
wire               LHU_MEM_WB; 
wire [ 1:0]         LW_MEM_WB; 


wire [31:0]  ALUResult_MEM_WB;
wire [31:0]  RegRdata2_MEM_WB;
wire [31:0]         PC_MEM_WB;
wire [31:0]             PC_WB;
wire [31:0]       RegWdata_WB;
wire [ 4:0]       RegWaddr_WB;
wire [ 3:0]       RegWrite_WB;
wire [31:0]   MemRdata_MEM_WB;

wire [31:0] RegWdata_Bypass_WB;


wire [63:0]  MULT_Result     ;
wire [31:0]  DIV_quotient    ;
wire [31:0]  DIV_remainder   ;
wire DIV_Busy                ;
wire DIV_Done            ;



wire [31:0] HI_in            ;
wire [31:0] LO_in            ;
wire [ 1:0] HILO_Write       ;
reg [31:0] HI          ;
reg [31:0] LO           ;
// HILO IO

wire [ 4:0] CP0Raddr         ;
wire [31:0] CP0Rdata         ;
wire [ 4:0] CP0Waddr         ;
wire [31:0] CP0Wdata         ;
wire        CP0Write         ;
wire [31:0]      epc         ;
// CP0Reg IO

wire [ 4:0] rd               ;
wire [31:0] RegRdata2_Final  ;

wire [31:0] cp0Rdata_EX_MEM ;
wire [31:0] cp0Rdata_MEM_WB  ;
wire           mfc0_DE_EX   ;
wire           mfc0_EX_MEM  ;
wire           mfc0_MEM_WB   ;

wire [31:0] Bypass_EX       ;
wire [31:0] Bypass_MEM       ;

wire [31:0] Exc_BadVaddr     ;
wire [31:0] Exc_EPC          ;
wire [ 5:0] Exc_Cause        ;

wire        ex_int_handle    ;
wire        ex_int_handling  ;
wire        eret_handle      ;
wire        eret_handling    ;
wire        DSI_DE_EX       ;                
wire        eret_DE_EX      ;                 
wire        cp0_Write_DE_EX ;                      
wire        Exc_BD           ;            
wire [ 6:0] Exc_Vec          ;
wire [ 4:0] Rd_DE_EX        ;
wire [ 3:0] Exc_vec_DE_EX   ;

reg [31:0]  PC_buffer       ;
wire PC_refresh              ;

wire [ 1:0] data_r_req       ;               
wire do_req_raddr            ;           
wire mem_read_req;    

reg [31:0] PC               ;
wire [31:0] mem_axi_rdata    ;                 
wire        mem_axi_rvalid   ;                 
wire [ 3:0] mem_axi_rid      ;                 
wire        mem_axi_rready   ;                 
wire [ 3:0] mem_axi_arid     ;                 
wire [31:0] mem_axi_araddr   ;                 
wire [ 2:0] mem_axi_arsize   ;                 
wire        mem_axi_arready  ;                 
wire        mem_axi_arvalid  ;                 
wire [ 3:0] mem_axi_awid     ;                 
wire [31:0] mem_axi_awaddr   ;                 
wire [ 2:0] mem_axi_awsize   ;                 
wire        mem_axi_awvalid  ;                 
wire        mem_axi_awready  ;                 
wire [ 3:0] mem_axi_wid      ;                 
wire [31:0] mem_axi_wdata    ;                 
wire [ 3:0] mem_axi_wstrb    ;                 
wire        mem_axi_wvalid   ;                 
wire        mem_axi_wready   ;                 
wire        mem_axi_bready   ;                 
wire [ 3:0] mem_axi_bid      ;                 
wire        mem_axi_bvalid   ;   
wire [ 1:0] mem_axi_bresp    ;
wire        fetch_axi_rready ;           
wire        fetch_axi_rvalid ;           
wire        fetch_axi_rdata  ;           
wire [ 3:0] fetch_axi_rid    ;           
wire        fetch_axi_arready;           
wire        fetch_axi_arvalid;           
wire [ 2:0] fetch_axi_arsize ;           
wire        fetch_axi_arid   ;           
wire        decode_allowin   ;    

wire        exe_allowin;
wire        mem_allowin;
wire        wb_allowin;
                     
wire        fe_to_de_valid;
wire        de_to_exe_valid;
wire        exe_to_mem_valid;
wire        mem_to_wb_valid;

wire        de_valid;
wire        exe_valid;
wire        mem_valid;
wire        wb_valid;

wire        exe_refresh;
wire        exe_ready_go;

wire        IR_buffer_valid;

wire        j_or_b_DE;

    
    //reg PC_AdEL_r;
    wire [31:0] Jump_addr, inst_addr, PC_mux;
    assign Jump_addr = JSrc ? JR_target_DE   : J_target_DE; 
    assign inst_addr = ex_int_handle  ? except_addr : 
                                eret_handle  ? epc         : PC_mux;//new 判断如果是例外中断就到例外处理入口地�?，如果是eret就到epc否则正常pc

    always @(posedge clk) begin
        if (rst) begin
            PC          <= ADDR;
            nextpc     <= ADDR + 32'd4;
            PC_buffer   <= 'd0;
            PC_AdEL     <= 'd0;
        end
        else if (PC_refresh) begin
            PC          <= inst_addr;               //To axi_araddr
            nextpc     <= inst_addr + 32'd4;       //To PC_mux For next value of PC
            PC_buffer   <= PC;                      //Wait to write into PC_IF_DE
            PC_AdEL     <= |PC[1:0] ? 1'b1 : 1'b0;  //For PC address excpetion
        end
        else begin
            nextpc     <= nextpc;
            PC          <= PC;
            PC_buffer   <= PC_buffer;
            PC_AdEL     <= PC_AdEL  ;
        end
    end
     //多位选择�?
    MUX_4_32 PCS_MUX(
        .Src1   (         nextpc),
        .Src2   (  Jump_addr),
        .Src3   (    Br_target_DE),
        .Src4   (      32'd0),
        .op     (      PCSrc),
        .Result (  PC_mux)//new 
    );
    //计算下一个PC


fetch fe_stage(
    .clk               (              clk), // I  1
    .rst               (              rst), // I  1
    .DSI_DE            (           DSI_DE), // I  1
    .IRWrite           (          IRWrite), // I  1
    .PC_AdEL           (          PC_AdEL), // I  1 
    .PC_IF_DE          (         PC_IF_DE), // O 32
    .PC_add_4_IF_DE    (   PC_add_4_IF_DE), // O 32
    .IR_IF_DE          (         IR_IF_DE), // O 32
    .PC_buffer         (        PC_buffer), // I 32
    .PC_AdEL_IF_DE     (    PC_AdEL_IF_DE), // O  1
    .DSI_IF_DE         (        DSI_IF_DE), // O  1
   
    .data_r_req        (       data_r_req), // I  2      
             
    .fetch_axi_rready  (fetch_axi_rready ), // O  1
    .fetch_axi_rvalid  (      cpu_rvalid ), // I  1
    .fetch_axi_rdata   (      cpu_rdata  ), // I 32       
    .fetch_axi_rid     (      cpu_rid    ), // I  4            
    .fetch_axi_arready (      cpu_arready), // I  1    

    .fe_to_de_valid    (   fe_to_de_valid), // O  1
    .decode_allowin    (decode_allowin   ), // I  1         

    .IR_buffer_valid   (  IR_buffer_valid)
  );


decode de_stage(
    .clk               (               clk), // I  1
    .rst               (               rst), // I  1
    .Inst_IF_DE        (          IR_IF_DE), // I 32
    .PC_IF_DE          (          PC_IF_DE), // I 32
    .PC_add_4_IF_DE    (    PC_add_4_IF_DE), // I 32
    .DSI_IF_DE         (         DSI_IF_DE), // I  1   new delay slot instruction tag
    .PC_AdEL_IF_DE     (     PC_AdEL_IF_DE), // I  1   new
    
    .ex_int_handle_DE  (     ex_int_handle), // I  1

    .RegRaddr1_DE      (         RegRaddr1), // O  5
    .RegRaddr2_DE      (         RegRaddr2), // O  5
    .RegRdata1_DE      (         RegRdata1), // I 32
    .RegRdata2_DE      (         RegRdata2), // I 32

    .Bypass_EX        (        Bypass_EX), // I 32 Bypass
    .Bypass_MEM        (        Bypass_MEM), // I 32 Bypass
    .RegWdata_WB       (RegWdata_Bypass_WB), // I 32 Bypass
    .MULT_Result       (       MULT_Result), // I 64 Bypass
    .HI                (            HI), // I 32 Bypass
    .LO                (            LO), // I 32 Bypass
    .MFHL_DE_EX_1     (       MFHL_DE_EX), // I  2 Bypass
    .MFHL_EX_MEM      (      MFHL_EX_MEM), // I  2 Bypass
    .MFHL_MEM_WB       (       MFHL_MEM_WB), // I  2 Bypass
    .MULT_EX_MEM      (      MULT_EX_MEM), // I  2 Bypass
    .RegRdata1_src     (     RegRdata1_src), // I  2 Bypass
    .RegRdata2_src     (     RegRdata2_src), // I  2 Bypass
    .DE_EX_Stall      (      DE_EX_Stall), // I  1 Stall
    .DIV_Done      (      DIV_Done), // I  1 Stall



    .JSrc              (              JSrc), // O  1
    .PCSrc             (             PCSrc), // O  2
    .J_target_DE       (       J_target_DE), // O 32
    .JR_target_DE      (      JR_target_DE), // O 32
    .Br_target_DE      (      Br_target_DE), // O 32

    .ALUSrcA_DE_EX    (    ALUSrcA_DE_EX), // O  2
    .ALUSrcB_DE_EX    (    ALUSrcB_DE_EX), // O  2
    .ALUop_DE_EX      (      ALUop_DE_EX), // O  4
    .RegWrite_DE_EX   (   RegWrite_DE_EX), // O  4
    .MemWrite_DE_EX   (   MemWrite_DE_EX), // O  4
    .MemEn_DE_EX      (      MemEn_DE_EX), // O  1
    .MemToReg_DE_EX   (   MemToReg_DE_EX), // O  1
    .is_signed_DE_EX  (  is_signed_DE_EX), // O  1  help ALU to judge Overflow
    .MULT_DE_EX       (       MULT_DE_EX), // O  2
    .DIV_DE_EX        (        DIV_DE_EX), // O  2
    .MFHL_DE_EX       (       MFHL_DE_EX), // O  2
    .MTHL_DE_EX       (       MTHL_DE_EX), // O  2
    .LB_DE_EX         (         LB_DE_EX), // O  1 
    .LBU_DE_EX        (        LBU_DE_EX), // O  1 
    .LH_DE_EX         (         LH_DE_EX), // O  1 
    .LHU_DE_EX        (        LHU_DE_EX), // O  1 
    .LW_DE_EX         (         LW_DE_EX), // O  2 
    .SW_DE_EX         (         SW_DE_EX), // O  2 
    .SB_DE_EX         (         SB_DE_EX), // O  1 
    .SH_DE_EX         (         SH_DE_EX), // O  1 
    .DSI_DE_EX        (        DSI_DE_EX), // O  1 delay slot instruction tag
    .eret_DE_EX       (       eret_DE_EX), // O  1 NEW   
    .Rd_DE_EX         (         Rd_DE_EX), // O  5 NEW
    .Exc_vec_DE_EX    (    Exc_vec_DE_EX), // I  4 NEW
    .RegWaddr_DE_EX   (   RegWaddr_DE_EX), // O  5
    .PC_add_4_DE_EX   (   PC_add_4_DE_EX), // O 32
    .PC_DE_EX         (         PC_DE_EX), // O 32
    .RegRdata1_DE_EX  (  RegRdata1_DE_EX), // O 32
    .RegRdata2_DE_EX  (  RegRdata2_DE_EX), // O 32
    .Sa_DE_EX         (         Sa_DE_EX), // O 32
    .SgnExtend_DE_EX  (  SgnExtend_DE_EX), // O 32
    .ZExtend_DE_EX    (    ZExtend_DE_EX), // O 32
    .cp0_Write_DE_EX  (  cp0_Write_DE_EX), // O  1
    .mfc0_DE_EX       (       mfc0_DE_EX), // O  1

    .is_rs_read_DE     (        is_rs_read), // O  1
    .is_rt_read_DE     (        is_rt_read), // O  1

    .is_j_or_br_DE     (            DSI_DE), // O  1 NEW

    .ex_int_handling   (   ex_int_handling),
    .eret_handling     (     eret_handling),

    .de_to_exe_valid   (   de_to_exe_valid), // O  1
    .decode_allowin    (    decode_allowin), // O  1
    .fe_to_de_valid    (    fe_to_de_valid), // I  1
    .exe_allowin       (       exe_allowin), // I  1      

    .exe_refresh       (       exe_refresh),
    .decode_stage_valid(          de_valid)
  );


execute exe_stage
        (
            .clk               (clk),
            .rst               (rst),
            .PC_add_4_DE_EX   (PC_add_4_DE_EX),
            .PC_DE_EX         (PC_DE_EX),
            .RegRdata1_DE_EX  (RegRdata1_DE_EX),
            .RegRdata2_DE_EX  (RegRdata2_DE_EX),
            .Sa_DE_EX         (Sa_DE_EX),
            .SgnExtend_DE_EX  (SgnExtend_DE_EX),
            .ZExtend_DE_EX    (ZExtend_DE_EX),
            .RegWaddr_DE_EX   (RegWaddr_DE_EX),
            .DSI_DE_EX        (DSI_DE_EX),
            .Exc_vec_DE_EX    (Exc_vec_DE_EX),
            .cp0_Write_DE_EX  (cp0_Write_DE_EX),
            .MemEn_DE_EX      (MemEn_DE_EX),
            .is_signed_DE_EX  (is_signed_DE_EX),
            .MemToReg_DE_EX   (MemToReg_DE_EX),
            .ALUSrcA_DE_EX    (ALUSrcA_DE_EX),
            .ALUSrcB_DE_EX    (ALUSrcB_DE_EX),
            .ALUop_DE_EX      (ALUop_DE_EX),
            .MemWrite_DE_EX   (MemWrite_DE_EX),
            .RegWrite_DE_EX   (RegWrite_DE_EX),
            .DIV_DE_EX        (DIV_DE_EX),
            .MULT_DE_EX       (MULT_DE_EX),
            .MFHL_DE_EX       (MFHL_DE_EX),
            .MTHL_DE_EX       (MTHL_DE_EX),
            .LB_DE_EX         (LB_DE_EX),
            .LBU_DE_EX        (LBU_DE_EX),
            .LH_DE_EX         (LH_DE_EX),
            .LHU_DE_EX        (LHU_DE_EX),
            .LW_DE_EX         (LW_DE_EX),
            .SW_DE_EX         (SW_DE_EX),
            .SB_DE_EX         (SB_DE_EX),
            .SH_DE_EX         (SH_DE_EX),
            .MemEn_EX_MEM     (MemEn_EX_MEM),
            .MemToReg_EX_MEM  (MemToReg_EX_MEM),
            .MemWrite_EX_MEM  (MemWrite_EX_MEM),
            .RegWrite_EX_MEM  (RegWrite_EX_MEM),
            .MULT_EX_MEM      (MULT_EX_MEM),
            .MFHL_EX_MEM      (MFHL_EX_MEM),
            .MTHL_EX_MEM      (MTHL_EX_MEM),
            .LB_EX_MEM        (LB_EX_MEM),
            .LBU_EX_MEM       (LBU_EX_MEM),
            .LH_EX_MEM        (LH_EX_MEM),
            .LHU_EX_MEM       (LHU_EX_MEM),
            .LW_EX_MEM        (LW_EX_MEM),
            .RegWaddr_EX_MEM  (RegWaddr_EX_MEM),
            .ALUResult_EX_MEM (ALUResult_EX_MEM),
            .MemWdata_EX_MEM  (MemWdata_EX_MEM),
            .PC_EX_MEM        (PC_EX_MEM),
            .RegRdata1_EX_MEM (RegRdata1_EX_MEM),
            .RegRdata2_EX_MEM (RegRdata2_EX_MEM),
            .s_vaddr_EX_MEM   (s_vaddr_EX_MEM),
            .s_size_EX_MEM    (s_size_EX_MEM),
            .Bypass_EX        (Bypass_EX),
            .Rd_DE_EX         (Rd_DE_EX),
            .mfc0_DE_EX       (mfc0_DE_EX),
            .cp0Rdata_EX_MEM  (cp0Rdata_EX_MEM),
            .mfc0_EX_MEM      (mfc0_EX_MEM),
            .Exc_BadVaddr      (Exc_BadVaddr),
            .Exc_EPC           (Exc_EPC),
            .Exc_BD            (Exc_BD),
            .Exc_Vec           (Exc_Vec),
            .cp0Rdata_EX      (CP0Rdata),
            .ex_int_handle     (ex_int_handle),
            .ex_int_handling   (ex_int_handling),
            .eret_handling     (eret_handling),
            .mem_allowin       (mem_allowin),
            .de_to_exe_valid   (de_to_exe_valid),
            .exe_allowin       (exe_allowin),
            .exe_to_mem_valid  (exe_to_mem_valid),

            .cp0_Write_EX     (CP0Write),
            .exe_ready_go      (exe_ready_go),

            .exe_stage_valid   (exe_valid),
            .DE_EX_Stall      (DE_EX_Stall),

            .DIV_EX           (DIV_EX),
            .MULT_EX          (MULT_EX),

            .eret_DE_EX       (eret_DE_EX),

            .epc_value         (epc),
            .PC                (PC)
        );

memory mem_stage
        (
            .clk               (clk),
            .rst               (rst),
            .MemEn_EX_MEM     (MemEn_EX_MEM),
            .MemToReg_EX_MEM  (MemToReg_EX_MEM),
            .MemWrite_EX_MEM  (MemWrite_EX_MEM),
            .RegWrite_EX_MEM  (RegWrite_EX_MEM),
            .MFHL_EX_MEM      (MFHL_EX_MEM),
            .LB_EX_MEM        (LB_EX_MEM),
            .LBU_EX_MEM       (LBU_EX_MEM),
            .LH_EX_MEM        (LH_EX_MEM),
            .LHU_EX_MEM       (LHU_EX_MEM),
            .LW_EX_MEM        (LW_EX_MEM),
            .RegWaddr_EX_MEM  (RegWaddr_EX_MEM),
            .ALUResult_EX_MEM (ALUResult_EX_MEM),
            .MemWdata_EX_MEM  (MemWdata_EX_MEM),
            .RegRdata2_EX_MEM (RegRdata2_EX_MEM),
            .PC_EX_MEM        (PC_EX_MEM),
            .s_vaddr_EX_MEM   (s_vaddr_EX_MEM),
            .s_size_EX_MEM    (s_size_EX_MEM),

            .MULT_EX_MEM      (MULT_EX_MEM),
            .MTHL_EX_MEM      (MTHL_EX_MEM),
            .MULT_MEM          (MULT_MEM),
            .MTHL_MEM          (MTHL_MEM),

            .MemToReg_MEM_WB   (MemToReg_MEM_WB),
            .RegWrite_MEM_WB   (RegWrite_MEM_WB),
            .MFHL_MEM_WB       (MFHL_MEM_WB),
            .LB_MEM_WB         (LB_MEM_WB),
            .LBU_MEM_WB        (LBU_MEM_WB),
            .LH_MEM_WB         (LH_MEM_WB),
            .LHU_MEM_WB        (LHU_MEM_WB),
            .LW_MEM_WB         (LW_MEM_WB),
            .RegWaddr_MEM_WB   (RegWaddr_MEM_WB),
            .ALUResult_MEM_WB  (ALUResult_MEM_WB),
            .RegRdata2_MEM_WB  (RegRdata2_MEM_WB),
            .PC_MEM_WB         (PC_MEM_WB),
            .MemRdata_MEM_WB   (MemRdata_MEM_WB),
            .Bypass_MEM        (Bypass_MEM),
            .cp0Rdata_EX_MEM  (cp0Rdata_EX_MEM),
            .mfc0_EX_MEM      (mfc0_EX_MEM),
            .cp0Rdata_MEM_WB   (cp0Rdata_MEM_WB),
            .mfc0_MEM_WB       (mfc0_MEM_WB),
            .wb_allowin        (wb_allowin),
            .exe_to_mem_valid  (exe_to_mem_valid),
            .mem_allowin       (mem_allowin),
            .mem_to_wb_valid   (mem_to_wb_valid),
            .data_r_req        (data_r_req),
            .do_req_raddr      (do_req_raddr),
            .mem_axi_rdata     (mem_axi_rdata),
            .mem_axi_rvalid    (mem_axi_rvalid),
            .mem_axi_rid       (mem_axi_rid),
            .mem_axi_rready    (mem_axi_rready),
            .mem_axi_arid      (mem_axi_arid),
            .mem_axi_araddr    (mem_axi_araddr),
            .mem_axi_arsize    (mem_axi_arsize),
            .mem_axi_arready   (mem_axi_arready),
            .mem_axi_arvalid   (mem_axi_arvalid),
            .mem_axi_awid      (mem_axi_awid),
            .mem_axi_awaddr    (mem_axi_awaddr),
            .mem_axi_awsize    (mem_axi_awsize),
            .mem_axi_awvalid   (mem_axi_awvalid),
            .mem_axi_awready   (mem_axi_awready),
            .mem_axi_wid       (mem_axi_wid),
            .mem_axi_wdata     (mem_axi_wdata),
            .mem_axi_wstrb     (mem_axi_wstrb),
            .mem_axi_wvalid    (mem_axi_wvalid),
            .mem_axi_wready    (mem_axi_wready),
            .mem_axi_bready    (mem_axi_bready),
            .mem_axi_bid       (mem_axi_bid),
            .mem_axi_bvalid    (mem_axi_bvalid),

            .cpu_arid          (cpu_arid),
            .mem_read_req      (mem_read_req),

            .mem_stage_valid   (mem_valid)
        );


writeback wb_stage(
    .clk               (              clk), // I  1
    .rst               (              rst), // I  1
    .MemToReg_MEM_WB   (  MemToReg_MEM_WB), // I  1
    .RegWrite_MEM_WB   (  RegWrite_MEM_WB), // I  4
    .MFHL_MEM_WB       (      MFHL_MEM_WB), // I  2
    .LB_MEM_WB         (        LB_MEM_WB), // I  1 
    .LBU_MEM_WB        (       LBU_MEM_WB), // I  1 
    .LH_MEM_WB         (        LH_MEM_WB), // I  1 
    .LHU_MEM_WB        (       LHU_MEM_WB), // I  1 
    .LW_MEM_WB         (        LW_MEM_WB), // I  2 
    .RegWaddr_MEM_WB   (  RegWaddr_MEM_WB), // I  5
    .ALUResult_MEM_WB  ( ALUResult_MEM_WB), // I 32
    .RegRdata2_MEM_WB  ( RegRdata2_MEM_WB), // I 32
    .MemRdata_MEM_WB   (  MemRdata_MEM_WB), // I 32
    .PC_MEM_WB         (        PC_MEM_WB), // I 32
    .HI_MEM_WB         (           HI), // I 32
    .LO_MEM_WB         (           LO), // I 32
    .RegWdata_WB       (      RegWdata_WB), // O 32
    .RegWdata_Bypass_WB(RegWdata_Bypass_WB),
    .RegWaddr_WB       (      RegWaddr_WB), // O  5
    .RegWrite_WB       (      RegWrite_WB), // O  4
    .PC_WB             (            PC_WB), // O 32
    
    .cp0Rdata_MEM_WB   (  cp0Rdata_MEM_WB), // I 32
    .mfc0_MEM_WB       (      mfc0_MEM_WB), // I  1

    .mem_to_wb_valid   (  mem_to_wb_valid), // I  1
    .wb_allowin        (       wb_allowin), // O  1
    .wb_stage_valid    (         wb_valid)  
);

bypass bypass_unit(
    .clk                (              clk),
    .rst                (              rst),
    // input IR recognize signals from Control Unit
    .is_rs_read         (       is_rs_read),
    .is_rt_read         (       is_rt_read),
    // Judge whether the instruction is LW
    .MemToReg_DE_EX    (  MemToReg_DE_EX),
    .MemToReg_EX_MEM   ( MemToReg_EX_MEM),
    .MemToReg_MEM_WB    (  MemToReg_MEM_WB),
    // Reg Write address in afterward stage
    .RegWaddr_EX_MEM   ( RegWaddr_EX_MEM),
    .RegWaddr_MEM_WB    (  RegWaddr_MEM_WB),
    .RegWaddr_DE_EX    (  RegWaddr_DE_EX),
    // Reg read address in ID stage
    .rs_DE              (  IR_IF_DE[25:21]),
    .rt_DE              (  IR_IF_DE[20:16]),
    // Reg write data in afterward stage
    .RegWrite_DE_EX    (  RegWrite_DE_EX),
    .RegWrite_EX_MEM   ( RegWrite_EX_MEM),
    .RegWrite_MEM_WB    (  RegWrite_MEM_WB),
    
    .DIV_Busy           (         DIV_Busy),
    .DIV                (      |DIV_DE_EX),
    
    .ex_int_handle      (    ex_int_handle),
    // output the stall signals
    .PCWrite            (          PCWrite),
    .IRWrite            (          IRWrite),
    .DE_EX_Stall       (     DE_EX_Stall),
    // output the real read data in ID stage
    .RegRdata1_src      (    RegRdata1_src),
    .RegRdata2_src      (    RegRdata2_src),

    .de_valid           (         de_valid),
    .wb_valid           (         wb_valid),
    .exe_valid          (        exe_valid),
    .mem_valid          (        mem_valid),
    
    .is_j_or_b          (           DSI_DE)
);

reg_file RegFile(
    .clk               (              clk), // I  1
    .rst               (              rst), // I  1
    .waddr             (      RegWaddr_WB), // I  5
    .raddr1            (        RegRaddr1), // I  5
    .raddr2            (        RegRaddr2), // I  5
    .wen               (      RegWrite_WB), // I  4
    .wdata             (      RegWdata_WB), // I 32
    .rdata1            (        RegRdata1), // O 32
    .rdata2            (        RegRdata2)  // O 32
);

cp0reg cp0(
    .clk               (              clk), // I  1
    .rst               (              rst), // I  1
    .eret              (      eret_DE_EX), // I  1
    .int               (            int), // I  6
    .Exc_BD            (           Exc_BD), // I  1
    .Exc_Vec           (          Exc_Vec), // I  7
    .waddr             (         CP0Waddr), // I  5
    .raddr             (         CP0Raddr), // I  5
    .wen               (        CP0Write), // I  1
    .wdata             (         CP0Wdata), // I 32
    .epc_in            (          Exc_EPC), // I 32
    .Exc_BadVaddr      (     Exc_BadVaddr), // I 32
    .rdata             (         CP0Rdata), // O 32
    .epc_value         (              epc), // O 32
    .ex_int_handle     (    ex_int_handle), // O  1
    .eret_handle       (      eret_handle), // O  1
//
    .exe_ready_go      (     exe_ready_go),
    .exe_refresh       (      exe_refresh)  // I  1

);

multiplyer mul(
    .x          (RegRdata1_DE_EX),
    .y          (RegRdata2_DE_EX),
    .mul_clk    (clk),
    .resetn     (resetn),
    .mul_signed (MULT_EX[0]&~MULT_EX[1]),
    .result     (MULT_Result)
);

divider div(
    .div_clk        (clk),
    .rst        (rst),
    .x   (RegRdata1_DE_EX),
    .y   (RegRdata2_DE_EX),
    .div        (|DIV_EX),
    .div_signed (DIV_EX[0]&~DIV_EX[1]),
    .s  (DIV_quotient),
    .r  (DIV_remainder),
    .busy       (DIV_Busy),
    .Done   (DIV_Done)
);

assign HI_in = |MULT_MEM    ? MULT_Result[63:32] :
                MTHL_EX_MEM[1] ? RegRdata1_EX_MEM  :
                DIV_Done    ? DIV_remainder      : 'd0;
assign LO_in = |MULT_MEM    ? MULT_Result[31: 0] :
                MTHL_EX_MEM[0] ? RegRdata1_EX_MEM  :
                DIV_Done    ? DIV_quotient       : 'd0;
assign HILO_Write[1] = |MULT_MEM | DIV_Done | MTHL_EX_MEM[1];
assign HILO_Write[0] = |MULT_MEM | DIV_Done | MTHL_EX_MEM[0];

always @ (posedge clk) 
begin
        if (rst) 
        begin
            HI <= 32'd0;
            LO <= 32'd0;
        end
        else 
        begin
            if (HILO_Write[1]) HI <= HI_in;
            else               HI <= HI;
            if (HILO_Write[0]) LO <= LO_in;
            else               LO <= LO;
        end
end

assign CP0Waddr = Rd_DE_EX;
assign CP0Wdata = RegRdata2_DE_EX;
assign CP0Raddr = Rd_DE_EX;

assign debug_wb_pc       = PC_WB;
assign debug_wb_rf_wen   = RegWrite_WB;
assign debug_wb_rf_wnum  = RegWaddr_WB;
assign debug_wb_rf_wdata = RegWdata_WB;


reg  arvalid_r;
reg  first_fetch;
reg  [31:0] do_araddr;
reg  [ 3:0] do_arid;
reg  [ 2:0] do_arsize;
reg  [ 1:0] do_r_req;
//reg  do_arvalid;
wire [ 3:0] do_r_req_pos;



assign cpu_arid     =  do_arid;
assign cpu_araddr   =  do_araddr;
assign cpu_arlen    =  8'd0;
assign cpu_arsize   =  do_arsize;
assign cpu_arburst  =  2'd1;
assign cpu_arlock   =  2'd0;
assign cpu_arcache  =  4'd0;
assign cpu_arprot   =  3'd0;
assign cpu_arvalid  =  |do_r_req;

assign mem_axi_arready = cpu_arready;
assign fetch_axi_arready = cpu_arready;

assign mem_axi_rid = cpu_rid;
assign fetch_axi_rid = cpu_rid;

assign mem_axi_rdata = cpu_rdata;
assign fetch_axi_rdata = cpu_rdata;

assign mem_axi_rvalid = cpu_rvalid;
assign fetch_axi_rvalid = cpu_rvalid;

assign cpu_rready   =  fetch_axi_rready || mem_axi_rready;
assign cpu_awid     =  mem_axi_awid;
assign cpu_awaddr   =  mem_axi_awaddr;
assign cpu_awlen    =  8'd0;
assign cpu_awsize   =  mem_axi_awsize;
assign cpu_awburst  =  2'd1;
assign cpu_awlock   =  2'd0;
assign cpu_awcache  =  2'd0;
assign cpu_awprot   =  4'd0;
assign cpu_awvalid  =  mem_axi_awvalid;
assign mem_axi_awready = cpu_awready;
assign cpu_wid      =  mem_axi_wid;
assign cpu_wdata    =  mem_axi_wdata;
assign cpu_wstrb    =  mem_axi_wstrb;
assign cpu_wlast    =  1'd1;
assign cpu_wvalid   =  mem_axi_wvalid;
assign mem_axi_wready = cpu_wready;
assign mem_axi_bid   = cpu_bid;
assign mem_axi_bresp = cpu_bresp;
assign mem_axi_bvalid = cpu_bvalid;
assign cpu_bready   =  mem_axi_bready;

assign PC_refresh = cpu_arvalid && cpu_arready && cpu_arid==4'd0;

always @(posedge clk) begin   // arvalid_r only deals with inst
  if (rst) begin 
    arvalid_r   <= 1'b0;
    first_fetch <= 1'b1;
  end
  else if (cpu_arready&&cpu_arvalid&&cpu_arid==4'd0) begin 
    arvalid_r   <= 1'b0;
    first_fetch <= 1'b0;
  end
  else if (cpu_rready&&cpu_rvalid&&cpu_rid==4'd0) begin
    arvalid_r   <= 1'b1;
    first_fetch <= 1'b0;
  end
end


always @ (posedge clk) begin
    if (rst) begin
        do_r_req <= 2'd0;
    end
    else begin
        if (do_r_req==2'd0) begin
            if (first_fetch) begin
                do_r_req <= 2'd1;
            end
            else if (do_req_raddr) begin
                do_r_req <= 2'd3;
            end
            else if (arvalid_r&&(data_r_req!=2'd2||data_r_req!=2'd1)&&!IR_buffer_valid&&!DE_EX_Stall) begin
                do_r_req <= 2'd2;
            end
        end
        else begin
            if (do_r_req==2'd1||do_r_req==2'd2) begin
                if (cpu_arready&&cpu_arid==4'd0) begin
                    do_r_req <= 2'd0;
                end
            end
            if (do_r_req==2'd3) begin
                if (cpu_arready&&cpu_arid==4'd1) begin
                    do_r_req <= 2'd0;
                end
            end
        end
    end
end

assign do_r_req_pos[0] = 1'b0;
assign do_r_req_pos[1] = do_r_req==2'd0 && first_fetch;
assign do_r_req_pos[2] = do_r_req==2'd0 && !DE_EX_Stall && arvalid_r&&(data_r_req!=2'd2||data_r_req!=2'd1)&&!IR_buffer_valid;
assign do_r_req_pos[3] = do_r_req==2'd0 && do_req_raddr;


always @ (posedge clk) begin
    if (rst) begin
        do_arid   <= 'd0;
        do_arsize <= 'd0;
        do_araddr <= 'd0;
    end
    else begin
        if (do_r_req_pos[1]||do_r_req_pos[2]) begin
            do_arid   <= `INST_ARID;
            do_arsize <= 3'd2;
            do_araddr <= {PC[31:2],2'd0};
        end
        if (do_r_req_pos[3]) begin
            do_arid   <= `MEM_ARID;
            do_arsize <= mem_axi_arsize;
            do_araddr <= mem_axi_araddr;
        end
    end
end

endmodule //mytop

//////////////////////////////////////////////////////////
//Three input MUX of five bits
module MUX_3_5(
    input  [4:0] Src1,
    input  [4:0] Src2,
    input  [4:0] Src3,
    input  [1:0] op,
    output [4:0] Result
);
    wire [4:0] and1, and2, and3, op1, op1x, op0, op0x;

	  assign op1  = {5{ op[1]}};
    assign op1x = {5{~op[1]}};
    assign op0  = {5{ op[0]}};
    assign op0x = {5{~op[0]}};
    assign and1 = Src1   & op1x & op0x;
    assign and2 = Src2   & op1x & op0;
    assign and3 = Src3   & op1  & op0x;

    assign Result = and1 | and2 | and3;
endmodule

module MUX_4_32(
    input  [31:0] Src1,
    input  [31:0] Src2,
    input  [31:0] Src3,
    input  [31:0] Src4,
    input  [ 1:0] op,
    output [31:0] Result
);
    wire [31:0] and1, and2, and3, and4, op1, op1x, op0, op0x;

    assign op1  = {32{ op[1]}};
    assign op1x = {32{~op[1]}};
    assign op0  = {32{ op[0]}};
    assign op0x = {32{~op[0]}};
    assign and1 = Src1   & op1x & op0x;
    assign and2 = Src2   & op1x & op0;
    assign and3 = Src3   & op1  & op0x;
    assign and4 = Src4   & op1  & op0;

    assign Result = (and1 | and2) | (and3 | and4);

endmodule

module RegWdata_Sel(
    input  [31:0] MemRdata,
    input  [31:0]  Rt_data,
    input  [ 1:0]       LW,
    input  [ 1:0]    vaddr,
    input               LB,
    input              LBU,
    input               LH,
    input              LHU,
    output [31:0] RegWdata
);
    wire [31:0] LWL_data, LWR_data;
    wire [3:0] v;
    wire LWL, LWR;
    wire [7:0]  LB_data;
    wire [15:0] LH_data;

    assign LWL =  LW[1] & ~LW[0];
    assign LWR = ~LW[1] &  LW[0];

    assign v[3] =  vaddr[1] &  vaddr[0];
    assign v[2] =  vaddr[1] & ~vaddr[0];
    assign v[1] = ~vaddr[1] &  vaddr[0];
    assign v[0] = ~vaddr[1] & ~vaddr[0];

    assign LWL_data = ({32{v[0]}} & {MemRdata[ 7:0],Rt_data[23:0]} | {32{v[1]}} & {MemRdata[15:0],Rt_data[15:0]}) |
                      ({32{v[2]}} & {MemRdata[23:0],Rt_data[ 7:0]} | {32{v[3]}} & MemRdata);

    assign LWR_data = ({32{v[3]}} & {Rt_data[31: 8],MemRdata[31:24]} | {32{v[2]}} & {Rt_data[31:16],MemRdata[31:16]}) |
                      ({32{v[1]}} & {Rt_data[31:24],MemRdata[31: 8]} | {32{v[0]}} & MemRdata);
                      
    assign LB_data = ({8{v[0]}} & MemRdata[ 7: 0] | {8{v[1]}} & MemRdata[15: 8]) |
                     ({8{v[2]}} & MemRdata[23:16] | {8{v[3]}} & MemRdata[31:24]) ;
                    
    assign LH_data = {16{v[0]}} & MemRdata[15: 0] |
                     {16{v[2]}} & MemRdata[31:16] ; //no exceptions

    assign RegWdata = (({32{&LW}} & MemRdata | {32{ LB}} & {{24{LB_data[7]}},  LB_data}) | ({32{LBU}} & {24'd0,LB_data} | {32{ LH}} & {{16{LH_data[15]}}, LH_data})) |
                      (({32{LHU}} & {16'd0,LH_data} | {32{LWL}} & LWL_data) |  {32{LWR}} & LWR_data) ;
endmodule

module Adder(
    input  [31:0] A,
    input  [31:0] B,
    output [31:0] Result
  );
    ALU adder(
        .A      (      A),
        .B      (      B),
        .ALUop  (4'b0010),   //ADD
        .Result ( Result)
    );
endmodule
module MemWrite_Sel(
    input  [3:0] MemWrite_DE_EX,
    input  [1:0]       SW_DE_EX,
    input              SB_DE_EX,
    input              SH_DE_EX,
    input  [1:0]           vaddr,
    output [3:0]        MemWrite
);
    wire [3:0] MemW_L, MemW_R, MemW_SB, MemW_SH;
    wire [3:0] v;

    assign MemW_L[3] = &vaddr;
    assign MemW_L[2] = vaddr[1];
    assign MemW_L[1] = |vaddr;
    assign MemW_L[0] = 1'b1;

    assign MemW_R[3] = 1'b1;
    assign MemW_R[2] = ~(&vaddr);
    assign MemW_R[1] = ~vaddr[1];
    assign MemW_R[0] = ~(|vaddr);

    assign v[3] =  vaddr[1] &  vaddr[0];
    assign v[2] =  vaddr[1] & ~vaddr[0];
    assign v[1] = ~vaddr[1] &  vaddr[0];
    assign v[0] = ~vaddr[1] & ~vaddr[0];

    assign MemW_SB = ({4{v[0]}} & 4'b0001 | {4{v[1]}} & 4'b0010) |
                     ({4{v[2]}} & 4'b0100 | {4{v[3]}} & 4'b1000) ;

    assign MemW_SH = ({4{v[0]}} & 4'b0011) | ({4{v[2]}} & 4'b1100);

//Generated directly from the truth table

    assign MemWrite = ( SW_DE_EX[1] &~SW_DE_EX[0]) ? MemW_L ://10
                      (~SW_DE_EX[1] & SW_DE_EX[0]) ? MemW_R ://01
                      ( SW_DE_EX[1] & SW_DE_EX[0]) ? MemWrite_DE_EX ://11
                       SB_DE_EX           ? MemW_SB :
                       SH_DE_EX           ? MemW_SH : MemWrite_DE_EX;
endmodule

module Store_sel(
    input  wire [ 1:0] vaddr,
    input  wire [ 1:0] SW,
    input  wire        SB,
    input  wire        SH,
    input  wire [31:0] Rt_read_data,
    output wire [31:0] MemWdata,
    output wire [ 1:0] vaddr_final,
    output wire [ 2:0] s_size
  );
  wire swr = SW[0] & ~SW[1];
  wire swl = SW[1] & ~SW[0];
  wire sw  = &SW;

  wire [3:0] v;

  wire [1:0] swl_vaddr, swr_vaddr;
  wire [2:0] size_l, size_r;

  wire [31:0] swr_1,swr_2,swr_3,swr_4,swr_data;
  wire [31:0] swl_1,swl_2,swl_3,swl_4,swl_data;
  wire [31:0] sb_data, sh_data;

  assign v[3] =  vaddr[1] &  vaddr[0];
  assign v[2] =  vaddr[1] & ~vaddr[0];
  assign v[1] = ~vaddr[1] &  vaddr[0];
  assign v[0] = ~vaddr[1] & ~vaddr[0];

  assign swl_1 = {24'd0,Rt_read_data[31:24]};
  assign swl_2 = {16'd0,Rt_read_data[31:16]};
  assign swl_3 = { 8'd0,Rt_read_data[31: 8]};
  assign swl_4 = Rt_read_data;

  assign swl_vaddr = 2'b00;
  assign size_l = |vaddr ? {1'b0,vaddr} : 3'b010; //So ugly

  assign swl_data = (({32{v[0]}} & swl_1) | ({32{v[1]}} & swl_2)) |
                    (({32{v[2]}} & swl_3) | ({32{v[3]}} & swl_4)) ;

  assign swr_1 =  Rt_read_data;
  assign swr_2 = {Rt_read_data[23:0], 8'd0};
  assign swr_3 = {Rt_read_data[15:0],16'd0};
  assign swr_4 = {Rt_read_data[ 7:0],24'd0};

  assign swr_vaddr = v[1] ? 2'b00 : vaddr;
  assign size_r = &(~vaddr) ? 3'b010 : ~vaddr; //So ugly

  assign swr_data = (({32{v[0]}} & swr_1) | ({32{v[1]}} & swr_2)) |
                    (({32{v[2]}} & swr_3) | ({32{v[3]}} & swr_4)) ;

  assign sb_data = ({32{v[0]}} & {24'd0,Rt_read_data[7:0]      } |
                    {32{v[1]}} & {16'd0,Rt_read_data[7:0], 8'd0}  )
                                          |
                   ({32{v[2]}} & { 8'd0,Rt_read_data[7:0],16'd0} |
                    {32{v[3]}} & {      Rt_read_data[7:0],24'd0}  ) ;

  assign sh_data = {32{v[0]}} & {16'd0,Rt_read_data[15:0]      } |
                   {32{v[2]}} & {      Rt_read_data[15:0],16'd0} ;

  assign MemWdata = (({32{sw }} & Rt_read_data) |
                     ({32{swl}} & swl_data    ))  |
                    (({32{swr}} & swr_data    ) |
                     ({32{SB }} & sb_data     ))  |
                     ({32{SH }} & sh_data     ) ;
  assign vaddr_final = {2{sw }} & vaddr     |
                       {2{SH }} & vaddr     | 
                       {2{SB }} & vaddr     |
                       {2{swl}} & swl_vaddr |
                       {2{swr}} & swr_vaddr ;
  assign s_size = {3{sw }} & 3'b010 |
                  {3{SB }} & 3'b000 |
                  {3{SH }} & 3'b001 |
                  {3{swl}} & size_l |
                  {3{swr}} & size_r ; 
endmodule // Store_sel

module Addr_error(
    input  wire        is_lh   ,  
    input  wire        is_lw   ,
    input  wire        is_sh   ,
    input  wire        is_sw   ,
    input  wire [ 1:0] address ,
    output wire        AdEL_EX,
    output wire        AdES_EX
  );
  wire   AdEL_LH, AdEL_LW, AdES_SH, AdES_SW;
  assign AdEL_LH = address[0] & is_lh;
  assign AdEL_LW = (|address) & is_lw;

  assign AdES_SH = address[0] & is_sh;
  assign AdES_SW = (|address) & is_sw;

  assign AdEL_EX = AdEL_LH | AdEL_LW;
  assign AdES_EX = AdES_SH | AdES_SW;

endmodule // Addr_error

module branch(
    input [31:0] A,
    input [31:0] B,
    input [ 5:0] B_Type,   //blt ble bgt bge beq bne
    output       Cond
);
	wire zero, ge, gt, le, lt;
    assign zero = ~(|(A - B));
    assign ge = ~A[31];
    assign gt = ~A[31] &    |A[30:0];
    assign le =  A[31] | (&(~A[31:0]));
    assign lt =  A[31];

    assign Cond = ((B_Type[0] & ~zero | B_Type[1] & zero) | (B_Type[2] & ge | B_Type[3] & gt)) | (B_Type[4] & le | B_Type[5] & lt);


endmodule