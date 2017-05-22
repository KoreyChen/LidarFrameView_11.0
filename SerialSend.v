//`timescale 1ns / 1ps

module SerialSend(
clk,        		   //模块时钟 50MHz
rst_n,               //模块复位
rs232_tx,	         //232 TX引脚
serialsend_flag,     //按协议发送数据标记为  
//Buffer操作相关 
data,        			//要输入Buffer的数据
wrclk,      			//写入时钟
wrreq,      			//写入请求
wrempty,    			//写入buffer空标志
wrfull,     			//写入buffer满标志
wrusedw,     			//写入数量
rdempty,	            //读空标记
rdfull,              //读满标记
frameclk             //数据帧计数,这个信号必须在写数据之前发出，上升沿有效
);

input clk;			            // 50MHz主时钟
input rst_n;		            // 低电平复位信号
//input wire rs232_rx;		   // RS232接收数据信号
output wire rs232_tx;	      //	RS232发送数据信号
input wire serialsend_flag;   // 按协议发送数据标记  
reg        SerialSendEN_REG;  // 按协议发送数据使能标记寄存器

//Buffer操作相关 
input [7:0]   data;       		//要输入Buffer的数据
input         wrclk;      	   //写入时钟
input         wrreq;      	   //写入请求
output        wrempty;    	   //写入buffer空标志
output        wrfull;     	   //写入buffer满标志
output [9:0] wrusedw;     	//写入数量
input         frameclk;	      //数据帧计数 

//串口操作相关
wire bps_start;	//接收到数据后，波特率时钟启动信号置位
wire clk_bps;		   // clk_bps_r高电平为接收数据位的中间采样点,同时也作为发送数据的数据改变点 
reg  [7:0] Tx_data;
wire [7:0] Tx_data_t;
wire Tx_flag;
wire TxDataClk;

//协议发送部分
reg [11:0] count;       //发送数量计数
reg [1:0]  SateCount;   //发送状态计数
parameter  SD1 = 8'h7B; //帧头 {
parameter  SD2 = 8'h28; //    （
parameter  SD3 = 8'h31; //     1
parameter  SD4 = 8'h30; //     0
parameter  SD5 = 8'h32; //     2
parameter  SD6 = 8'h34; //     4
                        //    数据  （1024个）
parameter  SD7 = 8'h29; //     )
parameter  SD8 = 8'h7D; //帧尾 }

parameter  S1 =  2'b00; //发送帧头状态
parameter  S2 =  2'b01; //发送数据状态
parameter  S3 =  2'b10; //发送帧尾状态

wire TxSendEN;          //控制串口发送使能信号
reg  TxSendEN_Reg;      //控制串口发送使能寄存器
reg  [7:0] SerialSendData_Reg;  //串口需要发送的数据寄存器
	
reg [1:0] sendcount;    //发送FIFO计数，当 00 时判断如果处于S2阶段，就读取一个FIFO的数，当为01时如果置高发送状态，置高发送，10时关闭fifo，11时置低发送状态
parameter COUNT_S1 = 2'b00; 
parameter COUNT_S2 = 2'b01;
parameter COUNT_S3 = 2'b10;
parameter COUNT_S4 = 2'b11;

reg fifoReadFlag;       //需要进行Fifo读取标志
reg fifoReadReady;      //Fifo读取准备好标志
reg S3_flag;            //用于当rdempty = 1时无法发送 帧尾的尴尬

reg [2:0] FrameCount;   //数据帧累计寄存器


//****  例化FIFO读取数据的延时时间  ****//
//wire   rstFifoTtime;
//reg    rstFifoTtime_reg;
//assign rstFifoTtime = rstFifoTtime_reg;
//output wire   rdFifoTimeflag;

//--------   读取 FIFO    -------//
output wire  rdempty;	 //读空标记
output wire  rdfull;     //读满标记
wire  rdclk;   	       //读时钟
wire  rdreq;   	       //读请求
wire  [7:0] fifo_data;   //FIFO 数据
reg   rdclk_reg;         //读时钟
reg   rdreq_reg;         //读请求
wire  fifo_clear;
reg   fifo_clear_reg;

wire send_complete;

//*********** 串口操作部分 ***********//
//-----------     TX      ----------//												
speed_select		speed_tx(	
							.clk(clk),	//波特率选择模块
							.rst_n(rst_n),
							.bps_start(bps_start),
							.clk_bps(clk_bps)
						);
						
uart_tx    my_uart_tx (
				.clk(clk),                       //基础时钟 50MHz 
				.rst_n(rst_n),                   //复位信号
				.tx_data(SerialSendData_Reg),               //需要发送的数据  8bit
				.tx_int(TxSendEN),                 //发送 触发信号  低电平有效
				.rs232_tx(rs232_tx),             //串口TX引脚
				.clk_bps(clk_bps),               //clk_bps_r高电平为接收数据位的中间采样点,同时也作为发送数据的数据改变点
				.bps_start(bps_start),           //接收或者要发送数据，波特率时钟启动信号置位
				.send_complete(send_complete)    //发送完成标志位 高表示已发送完成  低表示正在发送
			);		
	

//-----------------------------------//

//********  例化数据发送的速度  ********//	 
//这个速度要小于波特率发送的速度,TX发送完成标志位添加后，就不需要这个了
parameter      TXDATA_CNT_NUM = 1500;	
timer    		my_timer_tx(
					.rst_n_in(rst_n),
					.clk_in(clk),				
					.out(TxDataClk),
					.timer(TXDATA_CNT_NUM)
					);
//--------------------------------//					
		

//********* 按协议发送部分 ************//	
//reg [7:0] Test;
assign TxSendEN=TxSendEN_Reg;

//------  记录SerialSend使能标记 ------//
always @(posedge clk or negedge rst_n )
begin
		if(!rst_n)
			SerialSendEN_REG  <= 1'b0;
		else
			SerialSendEN_REG <= serialsend_flag;
end

reg btn1; //上升沿捕获当前状态
reg btn2; //上升沿捕获之前状态
reg btnOne1;
reg btnOne2;
wire PosedgeFalg;
wire PosedgeFalgOne;
reg  SendOneFrameFlag;
assign	PosedgeFalg = btn1&(~btn2);
assign	PosedgeFalgOne = btnOne1 & (~btnOne2);
//------  记录frameclk 帧计数 ------//
always @(posedge clk or negedge rst_n )
begin
		if(!rst_n)
			begin
				FrameCount  <= 1'b0;
				btn1 <= 1'b0;
				btn2 <= 1'b0;
				btnOne1  <= 1'b0;
				btnOne2  <= 1'b0;
			end
		else
		begin
			btn1 <= frameclk;
			btn2 <= btn1;
			btnOne1  <= SendOneFrameFlag;
			btnOne2  <= btnOne1;
			if(PosedgeFalg)
				FrameCount <= FrameCount + 1'b1;
			else
			begin
				if((PosedgeFalgOne)&&(FrameCount > 1'b0))//发送完一帧就减少一个
					FrameCount <= FrameCount - 1'b1;
			end
		end
end

reg SendControlFlag;


//---------  协议发送控制模块   -------//
always @(posedge clk or negedge rst_n )
begin	
		if(!rst_n)
			begin
				count <= 0;
				SateCount <= S1;
//				Test<=0;
				sendcount <= COUNT_S1;
				fifoReadFlag <= 0;
				fifoReadReady <= 0;
				S3_flag <= 0;
				SendOneFrameFlag <=0;
				SendControlFlag <= 0;
				TxSendEN_Reg <= 1'b1;
			end
		else  
			begin
				//控制发送强制使能，关闭
				if((!SerialSendEN_REG)||(FrameCount == 3'b0))
				begin
						count <= 0;
						SateCount <= S1;
						sendcount <= COUNT_S1;
						fifoReadFlag <= 0;
						fifoReadReady <= 0;
						S3_flag <= 0;
						SendControlFlag <= 0;
				end
				else
					SendControlFlag <= 1'b1;
				
				case(sendcount)
				COUNT_S1:  //读取FIFO值
					begin
						rdclk_reg <= 1'b1;   //打开读时钟
						if(fifoReadFlag==1'b1)// 判断是否需要读FIFO，如果为空就等待
						begin
									if(rdempty==1'b1)//判断FIFO是否为空
										begin
										rdreq_reg <= 1'b0;   //关闭读请求
										if(S3_flag == 1'b1)
											sendcount <= COUNT_S2;
										else
											sendcount <= COUNT_S1;
										end
									else
										begin
											rdreq_reg <= 1'b1;   //打开读请求
											fifoReadReady <= 1'b1; 
											fifoReadFlag <= 1'b0;
											sendcount <= COUNT_S2;
										end
						end
						else
							sendcount <= COUNT_S2;
					end
				COUNT_S2:
					begin
						if(SendControlFlag)
						begin
							case(SateCount)
								S1:  //发送帧头
								begin
									SendOneFrameFlag <= 1'b0; //发送完一帧标记清零
									case(count)
										12'd0:  SerialSendData_Reg <= SD1;
										12'd1:  SerialSendData_Reg <= SD2;
										12'd2:  SerialSendData_Reg <= SD3;
										12'd3:  SerialSendData_Reg <= SD4;
										12'd4:  SerialSendData_Reg <= SD5;
										12'd5:  begin 
												  SerialSendData_Reg <= SD6;
												  fifoReadFlag <= 1'b1;
												  
												  SateCount <= S2;
												  end
									endcase
									if(send_complete)
										begin
										//控制TX 发送
										TxSendEN_Reg <= 1'b1;
										count <= count + 1'b1; 
									end
								end 
								S2:    //发送数据
								begin  //控制ADC采样  没有控制起始采样
									if(count>12'd5)
									begin
										if(fifoReadReady==1'b1) //判断当FIFO读出一个byte时才发送
										begin
											SerialSendData_Reg <= fifo_data;
		//									Test <= Test +1'b1;
		//									SerialSendData_Reg <= Test;
											//控制TX 发送
											TxSendEN_Reg <= 1'b1;
											count <= count + 1'b1; 
											fifoReadReady<=1'b0;
											if(count>=12'd1029)   //在这里由于是在同一个begin里面所以，count +1  要慢与比较 count>=12'd1029,所以是1029
												begin
													SateCount <= S3;
													fifoReadFlag <= 1'b0;
													rdreq_reg <= 1'b0;   //关闭读请求
													S3_flag <= 1'b1;
												end
											else
												fifoReadFlag <= 1'b1;
										end
									end
								end
								S3:  //发送帧尾
								begin
									case(count)
										12'd1030:  SerialSendData_Reg <= SD7;
										12'd1031:  SerialSendData_Reg <= SD8;
									endcase	
									//控制TX 发送
									TxSendEN_Reg <= 1'b1;
									count <= count + 1'b1; 
									if(count>=12'd1031)
										begin
											count <= 0;
											S3_flag <= 1'b0;
											SendOneFrameFlag <= 1'b1; //发送完一帧标记置位
											SateCount <= S1;
										end
								end
								endcase	
							end
							sendcount <= COUNT_S3;
						end
				COUNT_S3:
					begin
					rdclk_reg <= 1'b0;   //关闭读时钟
					sendcount <= COUNT_S4;
					end
				COUNT_S4:
					begin
					TxSendEN_Reg <= 1'b1;
					sendcount <= COUNT_S1;	
					end
				endcase
		 end
	
end	
//--------------------------------//

//*********  FIFO 操作 ***********//
//--------  清空FIFO -------------//
always @(posedge clk or negedge rst_n )
begin
		//模块复位时清空
		if(!rst_n)
			fifo_clear_reg  <= 1'b1;
		else
			fifo_clear_reg  <= 1'b0;	
end
assign fifo_clear = fifo_clear_reg;
//-------------------------------//
assign rdclk = rdclk_reg;
assign rdreq = rdreq_reg;
//-------------------------------//
//----------  例化FIFO  ----------//
senddcfifo	SendFifo_inst (
   .aclr ( fifo_clear ),    //清空操作
   .data ( data ),          //要输入Buffer的数据
   .rdclk ( rdclk ),        //读时钟
   .rdreq ( rdreq ),        //读请求
   .wrclk ( wrclk ),        //写入时钟
   .wrreq ( wrreq ),        //写入请求	
   .q ( fifo_data ),        //FIFO 数据
   .rdempty ( rdempty ),    //读完标记
   .rdfull (  rdfull ),     //读满标记
   .rdusedw (   ),
   .wrempty ( wrempty ),    //写入buffer空标志
   .wrfull ( wrfull ),      //写入buffer满标志
   .wrusedw ( wrusedw )     //写入数量	
	);
//-------------------------------//

endmodule

