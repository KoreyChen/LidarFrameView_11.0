module CCD_ADC_Control(
clk,
n_rst,
AD_data,

AD_clk,
AD_OE,
CCD_clk,
CCD_rst,
CCD_sht,
CCD_data,
CCD_M0,
CCD_M1,
CCD_RM,

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

input  clk; //外部时钟输入
input  n_rst;//主复位信号

input  [7:0] AD_data;//ADC TLC5510 的数据IO 8bit
output reg AD_clk;//ADC TLC5510 的时钟
output reg AD_OE;//ADC TLC5510 的使能
output reg CCD_clk;//CCD ELIS1024 的 时钟
output reg CCD_rst;//CCD ELIS1024 的  复位信号
output reg CCD_sht;//CCD ELIS1024 的 采样保持
output reg CCD_data;//CCD ELIS1024 的 数据输出使能IO
output CCD_M0;//CCD ELIS1024 的 分辨率配置IO 0
output CCD_M1;//CCD ELIS1024 的 分辨率配置IO 1
output CCD_RM;//CCD ELIS1024 的 模式配置IO 

output reg serialsend_flag;   // 按协议发送数据标记  

//Buffer操作相关 
output reg  [7:0] data;       		//要输入Buffer的数据
output reg   wrclk;      	   //写入时钟
output reg   wrreq;      	   //写入请求

input        wrempty;    	   //写入buffer空标志
input        wrfull;     	   //写入buffer满标志
input  rdempty;	 //读空标记
input  rdfull;     //读满标记

input [10:0] wrusedw;     	//写入数量
output  reg  frameclk;	      //数据帧计数 

//定时器
parameter TimeReset       =     1000 ;
parameter TimeSetClk      =     50  ; //半个周期的长度
parameter TimeIntegration =     8000 ;
parameter TimeADCDelay    =     20  ;  //这个数必须小于 TimeSetClk -1
reg   [25:0]  timercount;

//状态机
reg [1:0]  MainState;  //主状态
parameter  State1_Reset       = 2'b00 ;
parameter  State2_Integration = 2'b01 ;
parameter  State3_DataOut     = 2'b10 ;
parameter  State4             = 2'b11 ;
//分状态  复位：RST SHT 置高 ————延时———>  置低   同时CLK也要动作
//完成复位功能与积分时间开启
reg [1:0] RestState ;
parameter RestState_S1 = 2'b00;
parameter RestState_S2 = 2'b01;
parameter RestState_S3 = 2'b10;
parameter RestState_S4 = 2'b11;
//分状态  积分：延时--> 一个CLK ——>DATA置高 --> DATA置低
//完成积分结束到数据采集开始的转换
reg [2:0] IntegState;
parameter IntegState_S1 = 3'b000;
parameter IntegState_S2 = 3'b001;
parameter IntegState_S3 = 3'b010;
parameter IntegState_S4 = 3'b011;
parameter IntegState_S5 = 3'b100;
parameter IntegState_S6 = 3'b101;
parameter IntegState_S7 = 3'b110;
parameter IntegState_S8 = 3'b111;
reg [11:0] IntegCount;
//分状态  采样: 4个分周期  4步分解动作
reg [1:0] DataOutState;
parameter DataOutState_S1 = 2'b00;
parameter DataOutState_S2 = 2'b01;
parameter DataOutState_S3 = 2'b10;
parameter DataOutState_S4 = 2'b11;
reg [11:0] DataCount;


//设置CCD工作模式
assign CCD_M0 = 0;
assign CCD_M1 = 0;
assign CCD_RM = 0;


//过程状态  复位、积分、采样
always @(posedge clk or negedge n_rst )
begin
	if(!n_rst)
		begin
			timercount  <= 0;
			
			MainState <= State1_Reset;
			CCD_clk  <= 1'b0;
			CCD_data <= 1'b0;
			//
			RestState <= RestState_S1;
			CCD_rst <= 1'b0;
			CCD_sht <= 1'b0;
			IntegCount <= 0;
			//
			IntegState <= IntegState_S1;
			DataCount <= 0;
			DataOutState <= DataOutState_S1;
			//
			AD_clk <=0 ;
			AD_OE  <=0 ;
			wrclk  <= 1'b0; //写入时钟
			wrreq  <= 1'b0;      			//写入请求
			data <= 0;
			frameclk <= 0;
			serialsend_flag  <= 0;
			//
		end
	else
	begin
		timercount <= timercount + 1;
		case(MainState)
		State1_Reset:
				begin 
					case (RestState)
						RestState_S1:
						begin
							CCD_clk  <= 1'b1;
							CCD_rst <= 1'b1;
							CCD_sht <= 1'b1;	
							AD_OE  <= 1'b1;  //ADC复位
							frameclk <= 1'b1;	
							RestState <= RestState_S2;
						end
						RestState_S2:
						begin
						if(timercount>=TimeReset-1) //计时复位的时间长度
							begin
								CCD_clk  <= 1'b0;
								RestState <= RestState_S3;
							end
						end
						RestState_S3:
						begin
							CCD_rst <= 1'b0;
							AD_OE  <=0 ;  //ADC复位
							timercount  <= 0;
							RestState <= RestState_S4;
							MainState <= State2_Integration;
						end
						RestState_S4:
						begin

						end
					endcase
				end
		State2_Integration:
				begin 
						case(IntegState)
						IntegState_S1:
						begin
							if(timercount>=TimeIntegration-1) //计时积分的时间长度 
							begin
								CCD_sht <= 1'b0;
								timercount  <= 0;
								IntegState <= IntegState_S2;
							end
						end
						IntegState_S2:
						begin
								CCD_clk <= 1'b1;
								timercount  <= 0;
								IntegState <= IntegState_S3;
						end
						IntegState_S3:
						begin
							if(timercount>=TimeSetClk-1) //计时CLK的时间长度
							begin
								CCD_clk <= 1'b0;
								timercount  <= 0;
								IntegState <= IntegState_S4;
							end
						end
						IntegState_S4:
						begin
								CCD_data <=  1'b1;
								timercount  <= 0;
								IntegState <= IntegState_S5;
						end
						IntegState_S5:
						begin
							if(timercount>=TimeSetClk-1) //计时CLK的时间长度
							begin
								CCD_clk <= 1'b1;
								timercount  <= 0;
								IntegState <= IntegState_S6;
							end						
						end
						IntegState_S6:
						begin
							if(timercount>=TimeSetClk-1) //计时CLK的时间长度
							begin
								CCD_clk <= 1'b0;
								CCD_data <=  1'b0;
								timercount  <= 0;
								IntegState <= IntegState_S7;
							end	
						end
						IntegState_S7:
						begin
							if(timercount>=TimeSetClk-1) //计时CLK的时间长度
							begin
								CCD_clk <= 1'b1;
								timercount  <= 0;
								IntegState <= IntegState_S8;
								MainState <= State3_DataOut;
								wrreq <= 1'b1;      			//写入请求
								frameclk <=  1'b0;
								serialsend_flag  <=  1'b1;
							end	
						end
						IntegState_S8:
						begin
							//空
						end
						endcase
				end			
		State3_DataOut:
				begin 
						case (DataOutState)
						DataOutState_S1: //高电平 采集ADC值
						begin
							if(timercount>=TimeSetClk-1) //计时CLK的时间长度
							begin
								CCD_clk <= 1'b0;
								DataCount <= DataCount + 1'b1;
								timercount  <= 0;
								DataOutState <= DataOutState_S2;
							end
							if(timercount == TimeADCDelay) //ADC采样CLK上升沿
									begin
										AD_clk <= 1'b1;
										wrclk  <= 1'b0; //写入时钟
									end
							//CCD_clk <= 1'b1;
							//添加ADC单次采样值
							//test = ~test;
							//++++++++++++++++++++++++++++
						end
						DataOutState_S2: //下降沿
						begin
						
							if(timercount>=TimeSetClk-1) //计时CLK的时间长度
							begin
								CCD_clk <= 1'b1;
								timercount  <= 0;
								DataOutState <= DataOutState_S1;
							end
							else if(timercount == TimeADCDelay ) //ADC采样CLK上升沿
									begin
										AD_clk <= 1'b0;
										data <= AD_data;
										//data <= data + 1;//测试
									end
									else	if(timercount == TimeADCDelay +1 ) //ADC采样CLK上升沿
											begin
												wrclk  <= 1'b1; //写入时钟
											end
							if(DataCount == 12'd1024)  //判断是否采集完成
							begin
								CCD_clk <= 1'b0;
								CCD_sht <= 1'b0;
								CCD_rst <= 1'b0;
								AD_clk <= 1'b0;
								wrclk  <= 1'b0; //写入时钟
								wrreq  <= 1'b0;      			//写入请求
								data <= 0;
								serialsend_flag  <=  1'b0;
								MainState <= State4;
							end
						end
						endcase
				end
		State4:
				begin
					
				end			
		endcase
	end
end


////分状态  复位：RST SHT 置高 ————延时———>  置低   同时CLK也要动作
////完成复位功能与积分时间开启
//
//task ELIS1024_RESET;
//
//endtask
//
//
////分状态  积分：延时--> 一个CLK ——>DATA置高 --> DATA置低
////完成积分结束到数据采集开始的转换
//
//task ELIS1024_INTEGRATION;
//
//endtask
//
////分状态  采样: 4个分周期  4步分解动作
//task ELIS1024_DATAOUT;
//
//endtask
//



endmodule




