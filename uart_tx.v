module uart_tx(
				clk,          //基础时钟 50MHz 
				rst_n,        //复位信号
				tx_data,      //需要发送的数据  8bit
				tx_int,       //发送 触发信号
				rs232_tx,     //串口TX引脚
				clk_bps,      //clk_bps_r高电平为接收数据位的中间采样点,同时也作为发送数据的数据改变点
				bps_start,    //接收或者要发送数据，波特率时钟启动信号置位
				send_complete //发送完成标志位 高表示已发送完成  低表示正在发送
			);

input clk;			// 50MHz主时钟
input rst_n;		//低电平复位信号
input clk_bps;		// clk_bps_r高电平为接收数据位的中间采样点,同时也作为发送数据的数据改变点
input[7:0] tx_data;	//发送数据寄存器
input tx_int;		//发送数据中断信号,接收到数据期间始终为高电平,在该模块中利用它的下降沿来启动串口发送数据
output rs232_tx;	// RS232发送数据信号
output bps_start;	//接收或者要发送数据，波特率时钟启动信号置位
output reg send_complete;
//---------------------------------------------------------
reg tx_int0,tx_int1,tx_int2;	//tx_int信号寄存器，捕捉下降沿滤波用
wire neg_tx_int;	// tx_int下降沿标志位

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
			tx_int0 <= 1'b0;
			tx_int1 <= 1'b0;
			tx_int2 <= 1'b0;
		end
	else begin
			tx_int0 <= tx_int;
			tx_int1 <= tx_int0;
			tx_int2 <= tx_int1;
		end
end

assign neg_tx_int =  ~tx_int1 & tx_int2;	//捕捉到下降沿后，neg_tx_int拉高保持一个主时钟周期

//---------------------------------------------------------
reg [7:0] tx_data_t;	//待发送数据的寄存器
//---------------------------------------------------------
reg bps_start_r;
reg tx_en;	//发送数据使能信号，高有效
reg[3:0] num;

always @ (posedge clk or negedge rst_n) 
begin
	if(!rst_n) begin
			bps_start_r <= 1'bz;
			tx_en <= 1'b0;
			tx_data_t <= 8'd0;
			send_complete <= 1;
		end
	else if(neg_tx_int) begin	//接收数据完毕，准备把接收到的数据发回去
			bps_start_r <= 1'b1;
			tx_data_t <= tx_data;	//把接收到的数据存入发送数据寄存器
			tx_en <= 1'b1;		//进入发送数据状态中
			send_complete <= 1'b0;
		end
	else if(num==4'd11) begin	//数据发送完成，复位
			//bps_start_r <= 1'b0;
			//tx_en <= 1'b0;
			//send_complete <= 1'b1;
		end
	else if(num==4'd12) begin	//数据发送完成，复位
			bps_start_r <= 1'b0;
			tx_en <= 1'b0;
			send_complete <= 1'b1;
		end
		
		
end

assign bps_start = bps_start_r;

//---------------------------------------------------------
reg rs232_tx_r;

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
			num <= 4'd0;
			rs232_tx_r <= 1'b1;
		end
	else if(tx_en) begin
			if(clk_bps)	begin
					num <= num+1'b1;
					case (num)
						4'd0: rs232_tx_r <= 1'b0; 	//发送起始位
						4'd1: rs232_tx_r <= tx_data_t[0];	//发送bit0
						4'd2: rs232_tx_r <= tx_data_t[1];	//发送bit1
						4'd3: rs232_tx_r <= tx_data_t[2];	//发送bit2
						4'd4: rs232_tx_r <= tx_data_t[3];	//发送bit3
						4'd5: rs232_tx_r <= tx_data_t[4];	//发送bit4
						4'd6: rs232_tx_r <= tx_data_t[5];	//发送bit5
						4'd7: rs232_tx_r <= tx_data_t[6];	//发送bit6
						4'd8: rs232_tx_r <= tx_data_t[7];	//发送bit7
						4'd9: rs232_tx_r <= 1'b1;	//发送结束位
					 	default: rs232_tx_r <= 1'b1;
						endcase
				end
			else if(num==4'd12) num <= 4'd0;	//复位
		end
end

assign rs232_tx = rs232_tx_r;

endmodule


