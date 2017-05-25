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
output [9:0]  wrusedw;     	//写入数量
input         frameclk;	      //数据帧计数 
wire   [9:0]  rdusedw;     	//读入数量

//串口操作相关
wire bps_start;	//接收到数据后，波特率时钟启动信号置位
wire clk_bps;		   // clk_bps_r高电平为接收数据位的中间采样点,同时也作为发送数据的数据改变点 
reg  TxSendEN_Reg;      //控制串口发送使能寄存器
reg  [7:0] SerialSendData_Reg;  //串口需要发送的数据寄存器
reg [2:0] FrameCount;   //数据帧累计寄存器

//--------   读取 FIFO    -------//
output wire  rdempty;	 //读空标记
output wire  rdfull;     //读满标记
wire  [7:0] fifo_data;   //FIFO 数据
reg   rdclk_reg;         //读时钟
reg   rdreq_reg;         //读请求
wire  fifo_clear;
reg   fifo_clear_reg;

wire send_complete;

reg SerialSendbtn1; //上升沿捕获当前状态
reg SerialSendbtn2; //上升沿捕获之前状态
wire SerialSendPosedgeFalg;

reg btn1; //上升沿捕获当前状态
reg btn2; //上升沿捕获之前状态
reg btnOne1;
reg btnOne2;
wire PosedgeFalg;
wire PosedgeFalgOne;
reg  SendOneFrameFlag;

reg [2:0] serialState;              //串口发送帧状态机
parameter serialState_Start = 0;    //起始判断
parameter serialState_Head  = 1;    //发送帧头
parameter serialState_CMD   = 2;    //发送命令字
parameter serialState_Data  = 3;    //发送数据
parameter serialState_End   = 4;    //发送帧尾
parameter serialState_Stop  = 5;    //发送结束

reg [10:0] serialSendCount;         //帧发送总个数累加器
                                    //帧格式定义
parameter  SD1 = 8'h7B;             //帧头 {
parameter  SD2 = 8'h28;             //    （
parameter  SD3 = 8'h31;             //     1
parameter  SD4 = 8'h30;             //     0
parameter  SD5 = 8'h32;             //     2
parameter  SD6 = 8'h34;             //     4
                                    //    数据  （1024个）
parameter  SD7 = 8'h29;             //     )
parameter  SD8 = 8'h7D;             //帧尾 }

reg [2:0] sendDelayCount;           //发送延时输出计数器
reg nextStateFlag;                  //进入下一个状态的标记 

assign	PosedgeFalg = btn1&(~btn2);
assign	PosedgeFalgOne = btnOne1 & (~btnOne2);
assign SerialSendPosedgeFalg = SerialSendbtn1 & (~SerialSendbtn2); //上升沿有效
assign fifo_clear = fifo_clear_reg;


//*********** 串口操作部分 ***********//
//-----------     TX      ----------//												
speed_select	speed_tx(	
							.clk(clk),	//波特率选择模块
							.rst_n(rst_n),
							.bps_start(bps_start),
							.clk_bps(clk_bps)
						);
						
uart_tx    my_uart_tx (
				.clk(clk),                       //基础时钟 50MHz 
				.rst_n(rst_n),                   //复位信号
				.tx_data(SerialSendData_Reg),               //需要发送的数据  8bit
				.tx_int(TxSendEN_Reg),                 //发送 触发信号  低电平有效
				.rs232_tx(rs232_tx),             //串口TX引脚
				.clk_bps(clk_bps),               //clk_bps_r高电平为接收数据位的中间采样点,同时也作为发送数据的数据改变点
				.bps_start(bps_start),           //接收或者要发送数据，波特率时钟启动信号置位
				.send_complete(send_complete)    //发送完成标志位 高表示已发送完成  低表示正在发送
			);		
			
//********* 按协议发送部分 ************//	
//------  记录SerialSend使能标记 ------//
always @(posedge clk or negedge rst_n )
begin
		if(!rst_n)
		begin
			SerialSendEN_REG  <= 1'b0;
			SerialSendbtn2 <= 0;
			SerialSendbtn1 <= 0;
		end
		else
		begin
			SerialSendbtn1 <= serialsend_flag;
			SerialSendbtn2 <= SerialSendbtn1;
			if(SerialSendPosedgeFalg)
				SerialSendEN_REG <= 1'b1;

		end
end

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

//串口序列发送
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		serialState <= 0;
		serialSendCount <= 0;
		TxSendEN_Reg <= 1; //串口发送中断为下降沿触发，这里复位为高电平
		sendDelayCount <= 0;
		nextStateFlag <=0;
		rdclk_reg <=0;
		rdreq_reg <=0;
	end
	else
	begin
		case(serialState)
			serialState_Start: //检测是否开始发送
			begin
				//串行发送使能上升沿有效且捕获到的帧个数不为零时开始发送。
				if((SerialSendEN_REG == 2'b1)&&(FrameCount != 3'b0)) 
				begin
					serialState  <= serialState_Head;
					SendOneFrameFlag <= 0;
				end
			end
			serialState_Head:  //发送帧头
			begin
				if((sendDelayCount == 0 )&&(send_complete))
				begin
					 //填充帧头字符
					case(serialSendCount)
						11'd0:  SerialSendData_Reg <= SD1;
						11'd1:  SerialSendData_Reg <= SD2;
						11'd2:  SerialSendData_Reg <= SD3;
						11'd3:  SerialSendData_Reg <= SD4;
						11'd4:  SerialSendData_Reg <= SD5;				
						11'd5:  begin
								SerialSendData_Reg <= SD6;		
								nextStateFlag <= 1;
								rdreq_reg <= 1;  //释放FIFO中首字符为0的尴尬 
								rdclk_reg <= 1; 
								end
					endcase
					sendDelayCount <= 1;//进入下一步
				end
				else if(sendDelayCount == 1) //进入中断下降沿触发
				begin
					//延时一个时钟周期后使能一个串口发送中断信号
					//当串口处于空闲时发送数据
						TxSendEN_Reg <= 0;
						serialSendCount <= serialSendCount +1;
						sendDelayCount <= 2;
				end
				else if(sendDelayCount >= 2)//进入中断下降沿复位，等待5个周期
				begin
					sendDelayCount <= sendDelayCount +1;
					if(sendDelayCount > 6)
					begin
						TxSendEN_Reg <= 1; //发送中断复位
						sendDelayCount <= 0;
						if(nextStateFlag) //判断是否应该进入命令字发送阶段
						begin
							serialState <= serialState_CMD;
							nextStateFlag <= 0;
							rdclk_reg <= 0; 
						end
					end
				end
			end
			serialState_CMD://此功能保留，待加入，可加入数据帧号码等
			begin
				serialState <= serialState_Data; //进入数据发送阶段
			end
			serialState_Data:
			begin
				//判断fifo是否为空
				if(!wrempty)//当串口处于空闲时发送数据 
				begin
					//从fifo中读出数据
					case(sendDelayCount)
					3'd0:	begin 
								if(send_complete)
								begin
									rdreq_reg <= 1; 
									sendDelayCount <= 1;
								end
							end
					3'd1:	begin  
								rdclk_reg <= 1; 
								sendDelayCount <= 2; 
							end
					3'd2:	begin
								SerialSendData_Reg <= fifo_data;
								sendDelayCount <= 3; 
							end
					3'd3:	begin
								rdclk_reg <= 0;
								TxSendEN_Reg <= 0;
								serialSendCount <= serialSendCount +1;
								sendDelayCount <= 4; 
							end
					3'd7:	begin
							TxSendEN_Reg <= 1;
							sendDelayCount <= 0; 
							if(serialSendCount>=11'd1029)   //在这里由于是在同一个begin里面所以，count +1  要慢与比较 count>=12'd1029,所以是1029
								begin
									serialState <= serialState_End;
									rdreq_reg <= 0; //关闭读请求 
								end
							end
					default:sendDelayCount <= sendDelayCount + 1;
					endcase
				end				
			end
			serialState_End:
			begin
				SendOneFrameFlag <= 1; 
				if((sendDelayCount == 0 )&&(send_complete))
				begin
					 //填充帧头字符
					case(serialSendCount)
						11'd1030:   SerialSendData_Reg <= SD7;
						12'd1031:  	begin
									SerialSendData_Reg <= SD8;		
									nextStateFlag <= 1;
									end
					endcase
					sendDelayCount <= 1;//进入下一步
				end
				else if(sendDelayCount == 1) //进入中断下降沿触发
				begin
					//延时一个时钟周期后使能一个串口发送中断信号
					//当串口处于空闲时发送数据
						TxSendEN_Reg <= 0;
						serialSendCount <= serialSendCount +1;
						sendDelayCount <= 2;
				end
				else if(sendDelayCount >= 2)//进入中断下降沿复位，等待5个周期
				begin
					sendDelayCount <= sendDelayCount +1;
					if(sendDelayCount > 6)
					begin
						TxSendEN_Reg <= 1; //发送中断复位
						sendDelayCount <= 0;
						if(nextStateFlag) //判断是否应该进入命令字发送阶段
						begin
							serialState <= serialState_Stop;
							nextStateFlag <= 0;
							SendOneFrameFlag <= 0; 
						end
					end
				end
			end
			serialState_Stop:
			begin
			end
		endcase
	end
end
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
//-------------------------------//
//----------  例化FIFO  ----------//
senddcfifo	SendFifo_inst (
   .aclr ( fifo_clear ),    //清空操作
   .data ( data ),          //要输入Buffer的数据
   .rdclk ( rdclk_reg ),        //读时钟
   .rdreq ( rdreq_reg ),        //读请求
   .wrclk ( wrclk ),        //写入时钟
   .wrreq ( wrreq ),        //写入请求	
   .q ( fifo_data ),        //FIFO 数据
   .rdempty ( rdempty ),    //读完标记
   .rdfull (  rdfull ),     //读满标记
   .rdusedw ( rdusedw  ),
   .wrempty ( wrempty ),    //写入buffer空标志
   .wrfull ( wrfull ),      //写入buffer满标志
   .wrusedw ( wrusedw )     //写入数量	
	);
//-------------------------------//

endmodule

