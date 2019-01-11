`timescale 10ns / 1ns

`define DATA_WIDTH 32

module ALU(
    input  wire [`DATA_WIDTH - 1:0] A,
    input  wire [`DATA_WIDTH - 1:0] B,
    input  wire [              3:0] ALUop,
    input  wire                     is_signed,
    output reg                      Overflow,
    output reg                      CarryOut,
    output reg                      Zero,
    output reg  [`DATA_WIDTH - 1:0] Result
  );
    reg temp;
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

    always @(*) begin
      case(ALUop)
        AND: begin
              Result = A & B;
              {Overflow,CarryOut,Zero,temp} = 'd0;
             end

        OR:  begin
              Result = A | B;
              {Overflow,CarryOut,Zero,temp} = 'd0;
             end

        ADD:  begin
               {CarryOut,Result} = {A[31],A} + {B[31],B};

               if((CarryOut != Result[31]) && (is_signed == 1))
                   Overflow = 1'b1;
               else 
                   Overflow = 1'b0;

               {CarryOut,Zero,temp} = 'd0;
              end    
                  
        SUB:  begin
               {CarryOut,Result} = {A[31],A} - {B[31],B};
              
               if((CarryOut != Result[31]) && (is_signed == 1))
                   Overflow = 1'b1;
               else 
                   Overflow = 1'b0;    

               {CarryOut,Zero,temp} = 'd0;
              end

        SIGNED_SLT :  begin   //signed
                    if (A[`DATA_WIDTH - 2:0] < B[`DATA_WIDTH - 2:0]) 
                       temp = 1;
                    else 
                       temp = 0;
                    if(~A[`DATA_WIDTH - 1] && B[`DATA_WIDTH - 1])
                        Result = 0;
                    else  begin
                      if(A[`DATA_WIDTH - 1] && ~B[`DATA_WIDTH - 1])
                        Result = 1;
                      else
                        Result = temp;                      
                    end
                    {CarryOut,Zero,Overflow,temp} = 0;             
                  end
      
        LF_16   : begin
                  Result = {B[15:0],16'd0};
                  {Overflow,CarryOut,Zero,temp} = 'd0;
                  end    

        UNSIGNED_SLT :  begin
                  Result = A < B ? 32'd1 : 32'd0;
                  {Overflow,CarryOut,Zero,temp} = 'd0;
                  end      

        SLL    :  begin // sll
                  Result = B << (A[4:0]);
                  {Overflow,CarryOut,Zero,temp} = 'd0;
                  end    

        NOR    :  begin
                  Result = ~(A | B);
                  {Overflow,CarryOut,Zero,temp} = 'd0;
                  end 

        XOR    :  begin
                  Result = A ^ B;
                  {Overflow,CarryOut,Zero,temp} = 'd0;
                  end  

        SRA    :  begin
                  Result = $signed(B) >>> A[4:0];
                  {Overflow,CarryOut,Zero,temp} = 'd0;
                  end  

        SRL    :  begin
                  Result = B >> A[4:0];
                  {Overflow,CarryOut,Zero,temp} = 'd0;
                  end
                    
        default : begin      
                  {Overflow,CarryOut,Zero,temp,Result} = 'd0;                       
                  end
      endcase
    end

endmodule // ALU
