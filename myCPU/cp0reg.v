
`define DATA_WIDTH 32
`define ADDR_WIDTH 5

`timescale 10ns / 1ns

module cp0reg(
    input                      clk,
    input                      rst,
    input                      wen,
    input                      eret,
    input                      Exc_BD,
    input  [              5:0] int,
    input  [              6:0] Exc_Vec, //Exception type
    input  [`ADDR_WIDTH - 1:0] waddr,
    input  [`ADDR_WIDTH - 1:0] raddr,
    input  [`DATA_WIDTH - 1:0] wdata,
    input  [`DATA_WIDTH - 1:0] epc_in,  
    input  [`DATA_WIDTH - 1:0] Exc_BadVaddr,
    output [`DATA_WIDTH - 1:0] rdata,
    output [`DATA_WIDTH - 1:0] epc_value,
    output                     ex_int_handle,
    output                     eret_handle,

    input                      exe_ready_go,
    input                      exe_refresh
);
    // BadVAddr     reg: 8, sel: 0
    reg  [31:0] badvaddr;
    wire [31:0] badvaddr_value;
    assign badvaddr_value = badvaddr;
    // Count        reg: 9, sel: 0
    reg         cycle;
    reg  [31:0] count;
    wire [31:0] count_value;
    assign count_value = count;
    // Compare      reg: 11, sel: 0
    reg  [31:0] compare;
    wire [31:0] compare_value;
    assign compare_value = compare;
    wire count_cmp_eq = (count_value == compare_value) ? 1'b1 : 1'b0;

    // Status       reg: 12, sel: 0
    wire        status_CU3   = 1'b0;
    wire        status_CU2   = 1'b0;
    wire        status_CU1   = 1'b0;
    wire        status_CU0   = 1'b0;
    wire        status_RP    = 1'b0;
    wire        status_FR    = 1'b0;
    wire        status_RE    = 1'b0;
    wire        status_MX    = 1'b0;
    wire        status_BEV   = 1'b1;
    wire        status_TS    = 1'b0;
    wire        status_SR    = 1'b0;
    wire        status_NMI   = 1'b0;
    wire        status_ASE   = 1'b0;
    reg         status_IM7;
    reg         status_IM6;
    reg         status_IM5;
    reg         status_IM4;
    reg         status_IM3;
    reg         status_IM2;
    reg         status_IM1;
    reg         status_IM0;
    wire [ 1:0] status_KSU   = 2'b00;
    wire        status_ERL   = 1'b0;
    reg         status_EXL;
    reg         status_IE;

    wire [31:0] status_value;
    assign status_value = {status_CU3, status_CU2, status_CU1, status_CU0,
                           status_RP,  status_FR,  status_RE,  status_MX,  
                    1'b0,  status_BEV, status_TS,  status_SR,  status_NMI, status_ASE, 
                    2'd0,  status_IM7, status_IM6, status_IM5, status_IM4, status_IM3,
                           status_IM2, status_IM1, status_IM0, 3'd0,       status_KSU,
                           status_ERL, status_EXL, status_IE };

    // Cause        reg: 13, sel: 0
    reg         cause_BD;
    reg         cause_TI;
    // wire [1:0]  cause_CE     = 2'd0;
    // wire        cause_DC     = 1'b0;
    // wire        cause_PCI    = 1'b0;
    // wire        cause_IV     = 1'b0;
    // wire        cause_WP     = 1'b0;
    // wire        cause_FDCI   = 1'b0;
    reg         cause_IP7;
    reg         cause_IP6;
    reg         cause_IP5;
    reg         cause_IP4;
    reg         cause_IP3;
    reg         cause_IP2;
    reg         cause_IP1;
    reg         cause_IP0;
    reg  [4:0]  cause_ExcCode;

    wire [31:0] cause_value;
    wire [ 4:0]ExcCode;
    assign cause_value = {cause_BD,  cause_TI, 14'd0, cause_IP7, cause_IP6, 
                          cause_IP5, cause_IP4,       cause_IP3, cause_IP2,
                          cause_IP1, cause_IP0, 1'b0, cause_ExcCode, 2'd0};
    assign ExcCode     =  (Exc_Vec[6]) ? 5'h4 :        // PC_AdEL
                          (Exc_Vec[5]) ? 5'ha :        // Reserved Instruction
                          (Exc_Vec[4]) ? 5'hc :        // OverFlow
                          (Exc_Vec[3]) ? 5'h8 :        // syscall
                          (Exc_Vec[2]) ? 5'h9 :        // breakpoint
                          (Exc_Vec[1]) ? 5'h4 :        // AdEL
                          (Exc_Vec[0]) ? 5'h5 : 5'hf;  // AdES;
    // EPC          reg: 14, sel: 0
    reg  [31:0] epc;

    assign epc_value = epc;

    wire [7:0] int_vec;
    wire int_pending = |int_vec & status_IE;
    wire exc_pending = |Exc_Vec;
    
    wire int_handle;
    wire ex_handle;
/*    reg timer_int_flag;
    always @ (posedge clk)
        if(rst)
            timer_int_flag <= 'd0;
        else if (~timer_int_flag && count_cmp_eq)
            timer_int_flag <= 'd1;
        else timer_int_flag <= 'd0;*/
    assign ex_int_handle = ~status_EXL & (int_pending | exc_pending);
    assign int_handle = ~status_EXL & int_pending;
    assign ex_handle  = ~status_EXL & exc_pending;
 
    reg wait_for_epc;
    reg wait_for_epc_r;

    always @(posedge clk) begin
      if (~status_EXL) begin
        if (|int_vec && status_IE) begin
          cause_ExcCode <= 5'd0;
        end
        else if (|Exc_Vec) begin
          cause_ExcCode <= ExcCode;
          cause_BD      <= Exc_BD;
          if (Exc_Vec[6] | Exc_Vec[1] | Exc_Vec[0])
            badvaddr <= Exc_BadVaddr;
        end
      end

      // BadVAddr     reg: 8, sel: 0
      if(rst) begin
        badvaddr <= 32'd0;
      end

      // Count        reg: 9, sel: 0
      if(rst) begin
        cycle <= 1'b0;
        count <= 32'd0;
      end
      else if(wen && waddr==5'd9) begin
        count <= wdata;
        cycle <= 1'b0;
      end
      else begin
        cycle <= ~cycle;
        if(cycle)
          count <= count + 1'b1;
      end

      if (rst)
        compare <= 32'h0;
      else if (wen && waddr == 5'd11)
        compare <= wdata[31:0];
      
      // Status       reg: 12, sel: 0
      if (rst) begin
        status_IM7   <= 1'b0;
        status_IM6   <= 1'b0;
        status_IM5   <= 1'b0;
        status_IM4   <= 1'b0;
        status_IM3   <= 1'b0;
        status_IM2   <= 1'b0;
        status_IM1   <= 1'b0;
        status_IM0   <= 1'b0;
        status_EXL   <= 1'b0;
        status_IE    <= 1'b0;
      end
      else begin
        if (eret && exe_ready_go) 
          status_EXL <= 1'b0;
        else if ((exc_pending || int_pending) && exe_ready_go)
          status_EXL <= 1'b1;
        else if (wen && waddr == 5'd12)
          status_EXL <= wdata[1];

        if (wen && waddr == 5'd12) begin
          status_IM7 <= wdata[ 15];
          status_IM6 <= wdata[ 14];
          status_IM5 <= wdata[ 13];
          status_IM4 <= wdata[ 12];
          status_IM3 <= wdata[ 11];
          status_IM2 <= wdata[ 10];
          status_IM1 <= wdata[  9];
          status_IM0 <= wdata[  8];
          status_IE  <= wdata[  0];
        end
      end
      // Cause        reg: 13, sel: 0
      if (rst) begin
        cause_TI <= 1'b0;
      end
      else if (wen && waddr==5'd11) begin //compare_wen
        cause_TI <= 1'b0;
      end
      else if (count_cmp_eq) begin
        cause_TI <= 1'b1;
      end

      if (rst) begin
        cause_BD      <= 1'b0;
        cause_IP7     <= 1'b0;
        cause_IP6     <= 1'b0;
        cause_IP5     <= 1'b0;
        cause_IP4     <= 1'b0;
        cause_IP3     <= 1'b0;
        cause_IP2     <= 1'b0;
        cause_IP1     <= 1'b0;
        cause_IP0     <= 1'b0;
        cause_ExcCode <= 5'h1f;
      end
      else begin
        if (wen && waddr == 5'd13) begin
          cause_IP1  <= wdata[ 9];
          cause_IP0  <= wdata[ 8];
        end
        cause_IP7    <= int[5] | cause_TI; //cause_TI;
        cause_IP6    <= int[4];
        cause_IP5    <= int[3];
        cause_IP4    <= int[2];
        cause_IP3    <= int[1];
        cause_IP2    <= int[0];
      end
      // EPC          reg: 14, sel: 0
      if (rst) begin
          epc <= 32'd0;
      end
      else begin
      if (wait_for_epc_neg || ex_handle&&exe_ready_go) begin
          epc <= epc_in;
      end
      else if (wen && waddr == 5'd14)
          epc <= wdata[31:0];
      end
    end

    always @ (posedge clk) begin
        if (rst) begin
            wait_for_epc <= 1'b0;
        end
        else begin
            if (int_handle)
                wait_for_epc <= 1'b1;
            else if (wait_for_epc&&exe_refresh)
                wait_for_epc <= 1'b0;
        end
    end


    always @ (posedge clk) begin
        if (rst) begin
            wait_for_epc_r <= 1'b0;
        end
        else begin
            wait_for_epc_r <= wait_for_epc;
        end
    end

    assign wait_for_epc_neg = ~wait_for_epc & wait_for_epc_r;

    assign rdata = {32{&(~(raddr ^ 5'b01000))}}  & badvaddr_value |
                   {32{&(~(raddr ^ 5'b01001))}}  &    count_value |
                   {32{&(~(raddr ^ 5'b01011))}}  &  compare_value |
                   {32{&(~(raddr ^ 5'b01100))}}  &   status_value |
                   {32{&(~(raddr ^ 5'b01101))}}  &    cause_value |
                   {32{&(~(raddr ^ 5'b01110))}}  &      epc_value ;
    assign int_vec = {(int[5] | cause_TI) & status_IM7,
                       int[4]             & status_IM6,
                       int[3]             & status_IM5,
                       int[2]             & status_IM4,
                       int[1]             & status_IM3,
                       int[0]             & status_IM2,
                      cause_IP1           & status_IM1,
                      cause_IP0           & status_IM0};
               
    assign eret_handle = eret; 
               
endmodule  // CP0 register files