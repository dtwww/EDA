module test3(clk,signal,reset,data_code,success);
	input clk;
	input signal;
	input reset;
	
	reg [1:0] sig_tmp;  
   wire sig_up;  
   wire sig_down; 

   output [7:0] data_code; //8位数据码
   output success;      //成功标志,维持0.125ms的高电平  
	//output div_clk;
      
	parameter T9ms=10'd72;  
   parameter T4ms5=10'd36;  
   parameter Tms7=7'd5;      //0.75ms  
   parameter error=8'd2;      //0.25ms  
	
	//分频
	integer div_cnt;
	reg div_clk;

	always @(negedge clk) begin
		if(!reset) begin //清零
			div_cnt = 0;
			div_clk = 0;
		end
		
		else begin
			if(div_cnt<3124) div_cnt = div_cnt + 1; //6250分频
			else begin
				div_cnt = 0;
				div_clk = ~div_clk;
			end
		end
	end

	
   //捕捉红外信号的上下沿
   always @(negedge div_clk or negedge reset)  
   begin  
       if (!reset)  
       begin  
           sig_tmp <= 2'd0;  
       end  
       else  
       begin  
           sig_tmp[0] <= signal;  
           sig_tmp[1] <= sig_tmp[0];  
       end  
   end  
  
   assign sig_up = ~sig_tmp[1] & sig_tmp[0];   //上升沿为1  
   assign sig_down = sig_tmp[1] & ~sig_tmp[0]; //下降沿为1 
	
	reg suc;  
   reg [31:0] data;//提取出的32位数据,地址码,其反码,操作码,其反码  
   reg [9:0] cnt;  
   reg [3:0] step; //状态机,解析红外的处理状态  
   reg [7:0] i;    //引导码后的数据位计数  
	parameter IDLE = 4'd0;
	parameter START_9MS = 4'd1;
	parameter CHECK_START_9MS = 4'd2;
	parameter START_4MS = 4'd3;
	parameter CHECK_START_4MS = 4'd4;
	parameter START_CODE = 4'd5;
	parameter CHECK_START_CODE = 4'd6;
	parameter SUCCESS = 4'd7;
	parameter RETURN = 4'd8;
	     //上下沿的计数  
   always @(negedge div_clk or negedge reset)  
   begin  
       if (!reset)  
       begin  
           cnt <= 10'd0;  
           step <= 4'd0;  
           data <= 32'b0;  
           i <= 8'd0;  
           suc <= 1'b0;  
       end  
       else  
       begin  
           case (step)  
               IDLE :  //开始等待捕捉引导码的下降沿  
                   begin     
                       if (sig_down) //第一次下降沿,过滤掉第一个下降沿  
                       begin  
                           step <= step + 1'd1;  
                           cnt <= 10'd0;  
                       end  
                   end  
                          
               START_9MS :      //引导码下降沿后开始计数  
                   begin  
                       cnt <= cnt + 1'd1;  
                       if (sig_up)   //上升沿截止计数  
                           step <= step + 4'd1;  
                   end  
  
               CHECK_START_9MS :      //判断引导码的低电平合法性  
                   begin  
                       if (cnt <= (T9ms+error) && cnt >= (T9ms-error))//引导码的9ms高电平  
                       begin  
									//flag<=1;
                           step = step + 4'd1;  
                           cnt = 10'd0;  
                       end  
                       else 
							  begin
								//flag<=0;
                           step <= 4'd0; 
							  end 
                   end  
  
                START_4MS :      //引导码的上升沿开始计数至下降沿  
                    begin  
								//flag<=2;
                        cnt <= cnt + 1'd1;  
                        if (sig_down)  
                            step <= step + 4'd1;  
                    end  
  
                CHECK_START_4MS :      //判断引导码的高电平4.5ms  
                    begin  
                        if (cnt <= (T4ms5+error) && cnt >= (T4ms5-error))//引导码确认完成  
                        begin  
                            step <= step + 4'd1;  
                            i <= 8'd0;  
                        end  
                        else  
                            step <= 4'd0;  
                    end  
  
                START_CODE :      //引导码正确后开始提取数据  
                    begin  
                        if (sig_up)  
                        begin  
                            step <= step + 4'd1;  
                            cnt <= 10'd0;  
                        end  
                    end  
  
                CHECK_START_CODE :      //提取每个上升沿后0.75ms时的状态,为高是表示数据1,为低时表示数据0  
                    begin  
                        cnt <= cnt + 1'd1;  
                        if (cnt === Tms7)   //捕捉数据部分每个下降沿后0.75ms的值  
                        begin  
                            data[i] <= signal;  
                            i <= i + 8'd1;  
                            if (i==8'd31)   //所有数据提取完  
                                step <= step + 4'd1;  
                            else            //捕捉下个位的下降沿  
                                step <= 4'd5;  
                        end  
                    end  
  
                SUCCESS :      //提取完数据发送成功标志  
                    begin  
                        step <= step + 4'd1;  
                        suc <= 1'b1;  
                    end  
  
                RETURN :  
                    begin  
                        suc <= 1'b0;  
                        step <= 4'd0;  
                    end  
  
               default : ;  
           endcase  
       end  
   end  
  
   assign success = suc;  
   assign data_code = data[23:16];  
endmodule 