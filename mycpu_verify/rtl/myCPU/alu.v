`timescale 10 ns / 1 ns

`define DATA_WIDTH 32

module alu(
	input [`DATA_WIDTH - 1:0] A,
	input [`DATA_WIDTH - 1:0] B,
	input [3:0] ALUop,
	output reg Overflow,
	output reg CarryOut,
	output reg Zero,
	output reg [`DATA_WIDTH - 1:0] Result,
	output [`DATA_WIDTH - 1:0] Xor
);
/*
wire [31:0]b;
wire [31:0]AS;
wire [31:0]slt;
wire overflow;
wire carryout;
wire btemp;
assign {btemp,b}= ~B + 32'b1;
assign {temp,AS[30:0]} = A[30:0] + ((ALUop[2]==1'b0) ? B[30:0]: b[30:0]);
assign {carryout,AS[31]} = A[31] + ((ALUop[2]==1'b0) ? B[31]: b[31]) + temp;
assign overflow = carryout ^ temp;
assign slt = (AS[31] ^ (overflow ^ (B==32'h80000000))) ? 32'b1: 32'b0;
assign Zero = (Result==32'b0)? 1'b1 : 1'b0;
assign Xor = A ^ B;
*/
    parameter [3:0] 
        AND          = 4'b0000,
        OR           = 4'b0001,
        ADD          = 4'b0010,
        LF_16        = 4'b0011,
        UNSIGNED_SLT = 4'b0100,
        SLL          = 4'b0101,
        SUB          = 4'b0110,
        SIGNED_SLT   = 4'b0111,
        NOR          = 4'b1001,
        XOR          = 4'b1010,
        SRA          = 4'b1011,
        SRL          = 4'b1100;

    reg [`DATA_WIDTH - 1:0] C, d, t, BF, z;
    reg [7:0] D, T; 
    reg temp;
    always @(*)
    begin
    case(ALUop)
      AND     :   begin
                  Result = A & B;
                  {Overflow,CarryOut,Zero,C,d,t,z,BF,temp,D,T} = 'd0;
                  end
      OR      :   begin
                  Result = A | B;
                  {Overflow,CarryOut,Zero,C,d,t,z,BF,temp,D,T} = 'd0;
                  end
      ADD     :   begin
                  d = A & B;
                  t = A ^ B;            
           
                  D[0] = d[3] ^ (t[3] & d[2]) ^ (t[3] & t[2] & d[1]) ^ (t[3] & t[2] & t[1] & d[0]);
                  T[0] = t[3] & t[2] & t[1] & t[0];
                  D[1] = d[7] ^ (t[7] & d[6]) ^ (t[7] & t[6] & d[5]) ^ (t[7] & t[6] & t[5] & d[4]);
                  T[1] = t[7] & t[6] & t[5] & t[4];                
                  D[2] = d[11] ^ (t[11] & d[10]) ^ (t[11] & t[10] & d[9]) ^ (t[11] & t[10] & t[9] & d[8]);
                  T[2] = t[11] & t[10] & t[9] & t[8];                
                  D[3] = d[15] ^ (t[15] & d[14]) ^ (t[15] & t[14] & d[13]) ^ (t[15] & t[14] & t[13] & d[12]);
                  T[3] = t[15] & t[14] & t[13] & t[12];   
                  D[4] = d[19] ^ (t[19] & d[18]) ^ (t[19] & t[18] & d[17]) ^ (t[19] & t[18] & t[17] & d[16]);
                  T[4] = t[19] & t[18] & t[17] & t[16];
                  D[5] = d[23] ^ (t[23] & d[22]) ^ (t[23] & t[22] & d[21]) ^ (t[23] & t[22] & t[21] & d[20]);
                  T[5] = t[23] & t[22] & t[21] & t[20];
                  D[6] = d[27] ^ (t[27] & d[26]) ^ (t[27] & t[26] & d[25]) ^ (t[27] & t[26] & t[25] & d[24]);
                  T[6] = t[27] & t[26] & t[25] & t[24];      
                  D[7] = d[31] ^ (t[31] & d[30]) ^ (t[31] & t[30] & d[29]) ^ (t[31] & t[30] & t[29] & d[28]);
                  T[7] = t[31] & t[30] & t[29] & t[28];    
                        
                                             
                  C[0] = d[0];
                  C[1] = d[1] ^ (t[1] & d[0]);
                  C[2] = d[2] ^ (t[2] & d[1]) ^ (t[2] & t[1] & d[0]);
                  
              
                  C[3] = D[0];
                  C[7] = D[1] ^ (T[1] & D[0]); 
                  C[11] = D[2] ^ (T[2] & D[1]) ^ (T[2] & T[1] & D[0]);   
                  C[15] = D[3] ^ (T[3] & D[2]) ^ (T[3] & T[2] & D[1]) ^ (T[3] & T[2] & T[1] & D[0]);                             
                                 

                  C[4] = d[4] ^ (t[4] & C[3]);
                  C[5] = d[5] ^ (t[5] & d[4]) ^ (t[5] & t[4] & C[3]);
                  C[6] = d[6] ^ (t[6] & d[5]) ^ (t[6] & t[5] & d[4]) ^ (t[6] & t[5] & t[4] & C[3]);
                 
                  

                  C[8] = d[8] ^ (t[8] & C[7]);
                  C[9] = d[9] ^ (t[9] & d[8]) ^ (t[9] & t[8] & C[7]);
                  C[10] = d[10] ^ (t[10] & d[9]) ^ (t[10] & t[9] & d[8]) ^ (t[10] & t[9] & t[8] & C[7]);
                  
                      
                  C[12] = d[12] ^ (t[12] & C[11]);
                  C[13] = d[13] ^ (t[13] & d[12]) ^ (t[13] & t[12] & C[11]);
                  C[14] = d[14] ^ (t[14] & d[13]) ^ (t[14] & t[13] & d[12]) ^ (t[14] & t[13] & t[12] & C[11]);
                     
                  
                      
                  C[16] = d[16] ^ (t[16] & C[15]);
                  C[17] = d[17] ^ (t[17] & d[16]) ^ (t[17] & t[16] & C[15]);
                  C[18] = d[18] ^ (t[18] & d[17]) ^ (t[18] & t[17] & d[16]) ^ (t[18] & t[17] & t[16] & C[15]);
                  
                 
                  C[19] = D[4] ^ (T[4] & C[15]);    
                  C[23] = D[5] ^ (T[5] & D[4]) ^ (T[5] & T[4] & C[15]);  
                  C[27] = D[6] ^ (T[6] & D[5]) ^ (T[6] & T[5] & D[4]) ^ (T[6] & T[5] & T[4] & C[15]);   
                  C[31] = D[7] ^ (T[7] & D[6]) ^ (T[7] & T[6] & D[5]) ^ (T[7] & T[6] & T[5] & D[4]) ^ (T[7] & T[6] & T[5] & T[4] & C[15]);
                                              
   

                  C[20] = d[20] ^ (t[20] & C[19]);
                  C[21] = d[21] ^ (t[21] & d[20]) ^ (t[21] & t[20] & C[19]);
                  C[22] = d[22] ^ (t[22] & d[21]) ^ (t[22] & t[21] & d[20]) ^ (t[22] & t[21] & t[20] & C[19]);
               
                

                  C[24] = d[24] ^ (t[24] & C[23]);
                  C[25] = d[25] ^ (t[25] & d[24]) ^ (t[25] & t[24] & C[23]);
                  C[26] = d[26] ^ (t[26] & d[25]) ^ (t[26] & t[25] & d[24]) ^ (t[26] & t[25] & t[24] & C[23]);
                
                    

                  C[28] = d[28] ^ (t[28] & C[27]);
                  C[29] = d[29] ^ (t[29] & d[28]) ^ (t[29] & t[28] & C[27]);
                  C[30] = d[30] ^ (t[30] & d[29]) ^ (t[30] & t[29] & d[28]) ^ (t[30] & t[29] & t[28] & C[27]);
                
             
                  Zero = ~(Result || 0);
                  Result[31:1] = A[31:1] ^ B[31:1] ^ C[30:0];
                  Result[0] = A[0] ^ B[0];
                  Overflow = (A[31] & B[31] & ~Result[31]) | (~A[31] & ~B[31] & Result[31]); 
                  CarryOut = C[31]; 
         
                  BF = 32'd0;
                  temp = 32'd0;
                  end    
                
      SUB     :   begin

                  BF = ~B + 32'h0000_0001;
                  d = A & BF;
                  t = A ^ BF;
          
                  D[0] = d[3] ^ (t[3] & d[2]) ^ (t[3] & t[2] & d[1]) ^ (t[3] & t[2] & t[1] & d[0]);
                  T[0] = t[3] & t[2] & t[1] & t[0];
                  D[1] = d[7] ^ (t[7] & d[6]) ^ (t[7] & t[6] & d[5]) ^ (t[7] & t[6] & t[5] & d[4]);
                  T[1] = t[7] & t[6] & t[5] & t[4];                
                  D[2] = d[11] ^ (t[11] & d[10]) ^ (t[11] & t[10] & d[9]) ^ (t[11] & t[10] & t[9] & d[8]);
                  T[2] = t[11] & t[10] & t[9] & t[8];                
                  D[3] = d[15] ^ (t[15] & d[14]) ^ (t[15] & t[14] & d[13]) ^ (t[15] & t[14] & t[13] & d[12]);
                  T[3] = t[15] & t[14] & t[13] & t[12];   
                  D[4] = d[19] ^ (t[19] & d[18]) ^ (t[19] & t[18] & d[17]) ^ (t[19] & t[18] & t[17] & d[16]);
                  T[4] = t[19] & t[18] & t[17] & t[16];
                  D[5] = d[23] ^ (t[23] & d[22]) ^ (t[23] & t[22] & d[21]) ^ (t[23] & t[22] & t[21] & d[20]);
                  T[5] = t[23] & t[22] & t[21] & t[20];
                  D[6] = d[27] ^ (t[27] & d[26]) ^ (t[27] & t[26] & d[25]) ^ (t[27] & t[26] & t[25] & d[24]);
                  T[6] = t[27] & t[26] & t[25] & t[24];      
                  D[7] = d[31] ^ (t[31] & d[30]) ^ (t[31] & t[30] & d[29]) ^ (t[31] & t[30] & t[29] & d[28]);
                  T[7] = t[31] & t[30] & t[29] & t[28];    
                        
                                             
                  C[0] = d[0];
                  C[1] = d[1] ^ (t[1] & d[0]);
                  C[2] = d[2] ^ (t[2] & d[1]) ^ (t[2] & t[1] & d[0]);
                
                  C[3] = D[0];
                  C[7] = D[1] ^ (T[1] & D[0]); 
                  C[11] = D[2] ^ (T[2] & D[1]) ^ (T[2] & T[1] & D[0]);   
                  C[15] = D[3] ^ (T[3] & D[2]) ^ (T[3] & T[2] & D[1]) ^ (T[3] & T[2] & T[1] & D[0]);                             

                  C[4] = d[4] ^ (t[4] & C[3]);
                  C[5] = d[5] ^ (t[5] & d[4]) ^ (t[5] & t[4] & C[3]);
                  C[6] = d[6] ^ (t[6] & d[5]) ^ (t[6] & t[5] & d[4]) ^ (t[6] & t[5] & t[4] & C[3]);
               
                

                  C[8] = d[8] ^ (t[8] & C[7]);
                  C[9] = d[9] ^ (t[9] & d[8]) ^ (t[9] & t[8] & C[7]);
                  C[10] = d[10] ^ (t[10] & d[9]) ^ (t[10] & t[9] & d[8]) ^ (t[10] & t[9] & t[8] & C[7]);
                
                    

                  C[12] = d[12] ^ (t[12] & C[11]);
                  C[13] = d[13] ^ (t[13] & d[12]) ^ (t[13] & t[12] & C[11]);
                  C[14] = d[14] ^ (t[14] & d[13]) ^ (t[14] & t[13] & d[12]) ^ (t[14] & t[13] & t[12] & C[11]);

                

                  C[16] = d[16] ^ (t[16] & C[15]);
                  C[17] = d[17] ^ (t[17] & d[16]) ^ (t[17] & t[16] & C[15]);
                  C[18] = d[18] ^ (t[18] & d[17]) ^ (t[18] & t[17] & d[16]) ^ (t[18] & t[17] & t[16] & C[15]);
                
               
                  C[19] = D[4] ^ (T[4] & C[15]);    
                  C[23] = D[5] ^ (T[5] & D[4]) ^ (T[5] & T[4] & C[15]);  
                  C[27] = D[6] ^ (T[6] & D[5]) ^ (T[6] & T[5] & D[4]) ^ (T[6] & T[5] & T[4] & C[15]);   
                  C[31] = D[7] ^ (T[7] & D[6]) ^ (T[7] & T[6] & D[5]) ^ (T[7] & T[6] & T[5] & D[4]) ^ (T[7] & T[6] & T[5] & T[4] & C[15]);


                  C[20] = d[20] ^ (t[20] & C[19]);
                  C[21] = d[21] ^ (t[21] & d[20]) ^ (t[21] & t[20] & C[19]);
                  C[22] = d[22] ^ (t[22] & d[21]) ^ (t[22] & t[21] & d[20]) ^ (t[22] & t[21] & t[20] & C[19]);
               
                

                  C[24] = d[24] ^ (t[24] & C[23]);
                  C[25] = d[25] ^ (t[25] & d[24]) ^ (t[25] & t[24] & C[23]);
                  C[26] = d[26] ^ (t[26] & d[25]) ^ (t[26] & t[25] & d[24]) ^ (t[26] & t[25] & t[24] & C[23]);
                
                    

                  C[28] = d[28] ^ (t[28] & C[27]);
                  C[29] = d[29] ^ (t[29] & d[28]) ^ (t[29] & t[28] & C[27]);
                  C[30] = d[30] ^ (t[30] & d[29]) ^ (t[30] & t[29] & d[28]) ^ (t[30] & t[29] & t[28] & C[27]);

                  Result[31:1] = A[31:1] ^ BF[31:1] ^ C[30:0];
                  Result[0] = A[0] ^ BF[0];
                  
                  CarryOut = ~C[31] && B;
                  
                  Overflow = (A[31] & ~B[31] & ~Result[31]) | (~A[31] & B[31] & Result[31]);
                       
                  Zero = ~(Result || 0);
                
                  temp = 32'd0;      
                end
                
                
                
    SIGNED_SLT :begin                                              //signed
                CarryOut = 0;
                Zero = 0;
                Overflow = 0;
                if (A[`DATA_WIDTH - 2:0] < B[`DATA_WIDTH - 2:0]) 
                   temp = 1;
                else 
                   temp = 0;
                if(~A[`DATA_WIDTH - 1] && B[`DATA_WIDTH - 1])
                    Result = 0;
                else
                if(A[`DATA_WIDTH - 1] && ~B[`DATA_WIDTH - 1])
                    Result = 1;
                else
                    Result = temp;
                
                C = 32'd0;
                d = 32'd0;
                t = 32'd0;
                z = 32'd0;
                BF = 32'd0;
                D = 8'd0;
                T = 8'd0;                
                end
    
    LF_16   :   begin
                Result = {B[15:0],16'd0};
                {Overflow,CarryOut,Zero,C,d,t,z,BF,temp,D,T} = 'd0;
                end  

    UNSIGNED_SLT :  begin
                Result = A < B ? 32'd1 : 32'd0;
                {Overflow,CarryOut,Zero,C,d,t,z,BF,temp,D,T} = 'd0;
                end    

    SLL    :    begin // sll
                Result = B << (A[4:0]);
                {Overflow,CarryOut,Zero,C,d,t,z,BF,temp,D,T} = 'd0;
                end         
    NOR    :    begin
                Result = ~(A | B);
                {Overflow,CarryOut,Zero,C,d,t,z,BF,temp,D,T} = 'd0;
                end 
    XOR    :    begin
                Result = A ^ B;
                {Overflow,CarryOut,Zero,C,d,t,z,BF,temp,D,T} = 'd0;
                end    
    SRA    :    begin
                Result = $signed(B) >>> A[4:0];
                {Overflow,CarryOut,Zero,C,d,t,z,BF,temp,D,T} = 'd0;
                end  
    SRL    :    begin
                Result = B >> A[4:0];
                {Overflow,CarryOut,Zero,C,d,t,z,BF,temp,D,T} = 'd0;
                end
    default :   begin      
                Zero = 1;
                {Overflow,CarryOut,Zero,C,d,t,z,BF,temp,D,T,Result} = 'd0;                       
                end
    endcase
    end

endmodule
