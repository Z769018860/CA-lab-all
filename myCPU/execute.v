
`timescale 10ns / 1ns
module execute(
    input  wire                      clk,
    input  wire                      rst, 
    // data transferring from ID stage
    input  wire [31:0]   PC_add_4_DE_EX,
    input  wire [31:0]         PC_DE_EX,
    input  wire [31:0]  RegRdata1_DE_EX,
    input  wire [31:0]  RegRdata2_DE_EX,
    input  wire [31:0]         Sa_DE_EX,
    input  wire [31:0]  SgnExtend_DE_EX,
    input  wire [31:0]    ZExtend_DE_EX,
    input  wire [ 4:0]   RegWaddr_DE_EX,
    input  wire               DSI_DE_EX,
    input  wire [ 3:0]    Exc_vec_DE_EX, // new -> exception vector
    input  wire         cp0_Write_DE_EX,    

    input                    eret_DE_EX,


    // control signals passing from ID stage
    input  wire             MemEn_DE_EX,
    input  wire         is_signed_DE_EX,
    input  wire          MemToReg_DE_EX,
    input  wire [ 1:0]    ALUSrcA_DE_EX,
    input  wire [ 1:0]    ALUSrcB_DE_EX,
    input  wire [ 3:0]      ALUop_DE_EX,
    input  wire [ 3:0]   MemWrite_DE_EX,
    input  wire [ 3:0]   RegWrite_DE_EX,
    input  wire [ 1:0]       MULT_DE_EX,
    input       [ 1:0]        DIV_DE_EX,
    input  wire [ 1:0]       MFHL_DE_EX,
    input  wire [ 1:0]       MTHL_DE_EX,

    input  wire                LB_DE_EX,
    input  wire               LBU_DE_EX,
    input  wire                LH_DE_EX,
    input  wire               LHU_DE_EX,
    input  wire [ 1:0]         LW_DE_EX,
    input  wire [ 1:0]         SW_DE_EX,
    input  wire                SB_DE_EX,
    input  wire                SH_DE_EX,



    output      [ 1:0]           DIV_EX,
    output      [ 1:0]          MULT_EX,

    // control signals passing to MEM stage
    output reg             MemEn_EX_MEM,
    output reg          MemToReg_EX_MEM,
    output reg  [ 3:0]  MemWrite_EX_MEM,
    output reg  [ 3:0]  RegWrite_EX_MEM,
    output reg  [ 1:0]      MULT_EX_MEM,
    output reg  [ 1:0]      MFHL_EX_MEM,
    output reg  [ 1:0]      MTHL_EX_MEM,
    output reg                LB_EX_MEM,
    output reg               LBU_EX_MEM,
    output reg                LH_EX_MEM,
    output reg               LHU_EX_MEM,
    output reg  [ 1:0]        LW_EX_MEM,

    // data passing to MEM stage
    output reg  [ 4:0]  RegWaddr_EX_MEM,
    output reg  [31:0] ALUResult_EX_MEM,
    output reg  [31:0]  MemWdata_EX_MEM,
    output reg  [31:0]        PC_EX_MEM,
    output reg  [31:0] RegRdata1_EX_MEM,
    output reg  [31:0] RegRdata2_EX_MEM,

    output reg  [ 1:0]   s_vaddr_EX_MEM,
    output reg  [ 2:0]    s_size_EX_MEM,

    output wire [31:0]        Bypass_EX, // Bypass
    input  wire [ 4:0]         Rd_DE_EX,
    input  wire              mfc0_DE_EX,

    output reg  [31:0]  cp0Rdata_EX_MEM,
    output reg              mfc0_EX_MEM,

    output                 cp0_Write_EX,
    output wire [31:0]      Exc_BadVaddr,   
    output wire [31:0]      Exc_EPC ,
    output wire             Exc_BD,
    output wire [ 6:0]      Exc_Vec,
    input  wire [31:0]      cp0Rdata_EX,
    
    input  wire             ex_int_handle,
    output reg              ex_int_handling,
    output reg              eret_handling,
    
    input                   mem_allowin,
    input               de_to_exe_valid,
    output                  exe_allowin,
    output             exe_to_mem_valid,

    output             exe_stage_valid,
    input              DE_EX_Stall,

    output                 exe_ready_go,
    input       [31:0]     epc_value,
    input       [31:0]            PC

);
    reg exe_valid;

    assign exe_ready_go     = !(ex_int_handle&&PC!=32'hbfc00380);
    assign exe_allowin      = !exe_valid || exe_ready_go && mem_allowin;
    assign exe_to_mem_valid = exe_valid && exe_ready_go;

    always @ (posedge clk) begin
        if (rst) begin
            exe_valid <= 1'b0;
        end
        else if (exe_allowin) begin
            exe_valid <= de_to_exe_valid;
        end
    end

    assign exe_stage_valid = exe_valid;
    
    wire        AdEL_EX,AdES_EX;
    wire        ACarryOut,AOverflow,AZero;     
    wire [31:0] ALUA,ALUB;
    wire [ 4:0] RegWaddr_EX;
    wire [31:0] ALUResult_EX,BadVaddr_EX;

    wire [ 3:0] MemWrite_Final;
//    wire [ 3:0] RegWrite_Final;

    wire [31:0] MemWdata;

    wire [ 1:0] vaddr_final;
    wire [ 2:0] s_size;
    
    assign cp0_Write_EX = cp0_Write_DE_EX & ~(ex_int_handling|eret_handling);
    assign MULT_EX      = MULT_DE_EX      & {2{~(ex_int_handling|eret_handling)}};
    assign DIV_EX       = DIV_DE_EX       & {2{~(ex_int_handling|eret_handling)}};

    // Exception Signals
    assign BadVaddr_EX = ALUResult_EX & {32{AdEL_EX|AdES_EX}};
    // Exc_vec_DE_EX[3]: PC_AdEL
    // Exc_vec_DE_EX[2]: Reserved Instruction
    // Exc_vec_DE_EX[1]: syscall
    // Exc_vec_DE_EX[0]: breakpoint
    assign Exc_BadVaddr = Exc_vec_DE_EX[3] ? PC_DE_EX : BadVaddr_EX; // if PC is wrong
    assign Exc_EPC      = DSI_DE_EX ? PC_DE_EX - 32'd4: PC_DE_EX;

    // Exc_vector[7]: interrupt
    // Exc_vector[6]: PC_AdEL
    // Exc_vector[5]: Reserved Instruction
    // Exc_vector[4]: OverFlow
    // Exc_vector[3]: syscall
    // Exc_vector[2]: breakpoint
    // Exc_vector[1]: AdEL
    // Exc_vector[0]: AdES
    assign Exc_Vec      = {Exc_vec_DE_EX[3:2], AOverflow,
                           Exc_vec_DE_EX[1:0], AdEL_EX,AdES_EX};

    assign RegWaddr_EX = RegWaddr_DE_EX;

    assign Bypass_EX = mfc0_DE_EX ? cp0Rdata_EX : ALUResult_EX;
    
    assign Exc_BD = DSI_DE_EX;


    always @ (posedge clk) begin
        if (rst) begin
            ex_int_handling <= 1'b0;
              eret_handling <= 1'b0;
        end
        else begin
            if (PC_DE_EX==32'hbfc00380) begin
                ex_int_handling <= 1'b0;
            end
            else if (ex_int_handle) begin
                ex_int_handling <= 1'b1;
            end

            if (PC_DE_EX==epc_value) begin
                eret_handling <= 1'b0;
            end
            else if (eret_DE_EX) begin
                eret_handling <= 1'b1;
            end
        end
    end


    wire   exe_control_invalid;
    assign exe_control_invalid = ex_int_handling&PC_DE_EX!=32'hbfc00380 | eret_handling&PC_DE_EX!=epc_value;


    always @ (posedge clk) begin
        if (rst) begin
            {    MemEn_EX_MEM,  MemToReg_EX_MEM,  MemWrite_EX_MEM, RegWrite_EX_MEM, 
              RegWaddr_EX_MEM,      MULT_EX_MEM,      MFHL_EX_MEM,     MTHL_EX_MEM, 
                    LB_EX_MEM,       LBU_EX_MEM,        LH_EX_MEM,      LHU_EX_MEM, 
                    LW_EX_MEM,      mfc0_EX_MEM, ALUResult_EX_MEM, MemWdata_EX_MEM,
                    PC_EX_MEM, RegRdata1_EX_MEM, RegRdata2_EX_MEM, cp0Rdata_EX_MEM,
                    s_vaddr_EX_MEM, s_size_EX_MEM
            } <= 'd0;
        end
        else if (exe_to_mem_valid && mem_allowin) begin
                // control signals passing to MEM stage
            MemWrite_EX_MEM  <=   MemWrite_Final & {4{~(exe_control_invalid)}};
               MemEn_EX_MEM  <=     MemEn_DE_EX &    ~(exe_control_invalid);
            MemToReg_EX_MEM  <=  MemToReg_DE_EX &    ~(exe_control_invalid);
            RegWrite_EX_MEM  <=  RegWrite_DE_EX & {4{~(exe_control_invalid)}};
                MULT_EX_MEM  <=      MULT_DE_EX & {2{~(exe_control_invalid)}};
                MFHL_EX_MEM  <=      MFHL_DE_EX & {2{~(exe_control_invalid)}};
                MTHL_EX_MEM  <=      MTHL_DE_EX & {2{~(exe_control_invalid)}};
                  LB_EX_MEM  <=        LB_DE_EX &    ~(exe_control_invalid);
                 LBU_EX_MEM  <=       LBU_DE_EX &    ~(exe_control_invalid);
                  LH_EX_MEM  <=        LH_DE_EX &    ~(exe_control_invalid);
                 LHU_EX_MEM  <=       LHU_DE_EX &    ~(exe_control_invalid);
                  LW_EX_MEM  <=        LW_DE_EX & {2{~(exe_control_invalid)}};
                mfc0_EX_MEM  <=      mfc0_DE_EX &    ~(exe_control_invalid);
            // data passing to MEM stage
            RegWaddr_EX_MEM  <=     RegWaddr_EX;
           ALUResult_EX_MEM  <=    ALUResult_EX;
            MemWdata_EX_MEM  <=         MemWdata;
                  PC_EX_MEM  <=        PC_DE_EX;
           RegRdata1_EX_MEM  <= RegRdata1_DE_EX;
           RegRdata2_EX_MEM  <= RegRdata2_DE_EX;
            cp0Rdata_EX_MEM  <=     cp0Rdata_EX; //cp0Rdata_DE_EX;
             s_vaddr_EX_MEM  <=      vaddr_final;
              s_size_EX_MEM  <=           s_size;
        end
    end

    MUX_4_32 ALUA_MUX(
        .Src1   (RegRdata1_DE_EX),
        .Src2   ( PC_add_4_DE_EX),
        .Src3   (       Sa_DE_EX),
        .Src4   (           32'd0),
        .op     (  ALUSrcA_DE_EX),
        .Result (            ALUA)
    );

    MUX_4_32 ALUB_MUX(
        .Src1   (RegRdata2_DE_EX),
        .Src2   (SgnExtend_DE_EX),
        .Src3   (           32'd4),
        .Src4   (  ZExtend_DE_EX),
        .op     (  ALUSrcB_DE_EX),
        .Result (            ALUB)
    );

    ALU ALU(
         .A         (            ALUA),
         .B         (            ALUB),
         .is_signed (is_signed_DE_EX),
         .ALUop     (    ALUop_DE_EX),
         .Overflow  (       AOverflow),
         .CarryOut  (       ACarryOut),
         .Zero      (           AZero),
         .Result    (   ALUResult_EX)
    );

    MemWrite_Sel MemW (
         .MemWrite_DE_EX (    MemWrite_DE_EX),
         .SB_DE_EX       (          SB_DE_EX),
         .SH_DE_EX       (          SH_DE_EX),
         .SW_DE_EX       (          SW_DE_EX),
         .vaddr           ( ALUResult_EX[1:0]),
         .MemWrite        (     MemWrite_Final)
    );

    Store_sel Store (
         .vaddr        (  ALUResult_EX[1:0]),
         .SW           (           SW_DE_EX),
         .SB           (           SB_DE_EX),
         .SH           (           SH_DE_EX),
         .Rt_read_data (    RegRdata2_DE_EX),
         .MemWdata     (            MemWdata),
         .vaddr_final  (         vaddr_final),
         .s_size       (              s_size)
    );

    Addr_error ADELS(
         .is_lh        (LH_DE_EX|LHU_DE_EX),  
         .is_lw        (          &LW_DE_EX),
         .is_sh        (           SH_DE_EX),
         .is_sw        (          &SW_DE_EX),
         .address      (  ALUResult_EX[1:0]),
         .AdEL_EX     (            AdEL_EX),
         .AdES_EX     (            AdES_EX)
    );

endmodule //EXcute_stage
