`define DATA_SIZE 32

module mul32(
        input  clk,
        input  rst,
        input  [  `DATA_SIZE-1:0] a,
        input  [  `DATA_SIZE-1:0] b,
        output [2*`DATA_SIZE-1:0] c,
        output done
);
        parameter Init=0,Ready=1,Acc=2,Done=3;
        
        reg [5:0]index_i;
        reg [`DATA_SIZE:0]z;
        reg [`DATA_SIZE:0]x_c;
        reg [`DATA_SIZE:0]x;
        reg [`DATA_SIZE:0]y;
        reg finished;
        reg [1:0]current_state,next_state;
        
always @(posedge clk or negedge rst)
        if (!rst)
                current_state<=Init;
        else 
                current_state<=next_state;

always @(current_state or index_i)
        case (current_state )
        Init        :
                begin
                        next_state=Ready;
                end
        Ready:
                begin
                        next_state=Acc;
                end
        Acc        :
                begin
                        if(index_i==6'h1f)
//                        if(index_i==6'h20)
                                begin
                                        next_state=Done;
                                end
                end
        endcase

always @(current_state or index_i)
        case (current_state)
        Init:
                begin
                        finished=0;
                end
        Ready:
                begin
                        x={a[`DATA_SIZE-1],a[`DATA_SIZE-1:0]};
                        x_c=~{a[`DATA_SIZE-1],a[`DATA_SIZE-1:0]}+1;
                        y[`DATA_SIZE:0]={b[`DATA_SIZE-1:0],1'b0};
                        z=0;
                        //$display("x=%b,x_c=%b,y=%b,z=%b",x,x_c,y,z);
                end
        Acc:
                begin
                        case (y[1:0])                        
                        2'b01:
                                begin
                                        //$display("case 01");
                                        //$display("Before:z=%b,y=%b",z,y);
                                        z=z+x;
                                        {z[`DATA_SIZE:0],y[`DATA_SIZE:0]}={z[`DATA_SIZE],z[`DATA_SIZE:0],y[`DATA_SIZE:1]};
                                        //$display("After:z=%b,y=%b",z,y);                                        
                                end
                        2'b10:
                                begin
                                        //$display("case 10");
                                        //$display("Before:z=%b,y=%b",z,y);
                                        z=z+x_c;
                                        {z[`DATA_SIZE:0],y[`DATA_SIZE:0]}={z[`DATA_SIZE],z[`DATA_SIZE:0],y[`DATA_SIZE:1]};
                                        //$display("After:z=%b,y=%b",z,y);                                                
                                end
                        default:
                                begin
                                        //$display("case 00 or 11");
                                        //$display("Before:z=%b,y=%b",z,y);
                                        {z[`DATA_SIZE:0],y[`DATA_SIZE:0]}={z[`DATA_SIZE],z[`DATA_SIZE:0],y[`DATA_SIZE:1]};        
                                        //$display("After:z=%b,y=%b",z,y);        
                                end                        
                        endcase        
                        //$display("z=%b,y=%b",z,y);                        
                end
        default:
                begin
                        finished=1;
                        //$display("c=%b",c);
                end
        endcase

always @(posedge clk)
        if (current_state==Acc)
                index_i<=index_i+1;
        else 
                index_i<=0;
                
        assign done=finished;
        assign c[`DATA_SIZE*2-1:0]={z[`DATA_SIZE-1:0],y[`DATA_SIZE:1]};
endmodule
