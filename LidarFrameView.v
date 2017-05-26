module LidarFrameView
(
clk,        		   
rst_n,               
rs232_tx,	      
startPoint,
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
DAC_CLK,
DAC_SYNC,
DAC_DIN
);

input  clk;       		   
input  rst_n;             
input [7:0] AD_data;
input startPoint;
output rs232_tx;	      
output AD_clk;
output AD_OE;
output CCD_clk;
output CCD_rst;
output CCD_sht;
output CCD_data;
output CCD_M0;
output CCD_M1;
output CCD_RM;

wire  serialsend_flag;      

wire  [7:0]data;        	 
wire  wrclk;      			 
wire  wrreq;      			 
wire  wrempty;    			 
wire  wrfull;     			 
wire  [9:0] wrusedw;     	 
wire  rdempty;	            
wire  rdfull;              
wire  frameclk;             


wire sample_clk;
wire [8:0] frame_number;
wire enable;
wire  [25:0] timeSet; 
wire  [8:0] resolution; 

assign enable=1;
assign timeSet = 22000;
assign resolution = 10;
assign serialsend_flag = 1;



output DAC_CLK;
output DAC_SYNC;
output DAC_DIN;


reg st;
reg [7:0] countcount;
reg flag;
always @(posedge clk or negedge rst_n )
begin
	if(!rst_n)
	begin
		st <= 0;
		countcount <= 0;
		flag <= 0;
	end
	else
	begin
	case(flag)
	1'b0:
	begin
		countcount <= countcount +1;
		if(countcount >= 8'd250)
		begin
			st <= 1;
			flag <= 1;
		end
	end
	1'b1:
	begin
		
	end
	endcase
	end
end



SamplingControl SamplingControl_inst
(
.clk(clk),
.n_rst(rst_n),
.timeSet(timeSet),
.resolution(resolution),
.startPoint(startPoint),
.enable(enable),
.sample_clk(sample_clk),
.frame_number(frame_number)
);

CCD_ADC_Control  CCD_ADC_Control_inst 
(
.clk(clk),
.n_rst(rst_n),
.AD_data(AD_data),

.AD_clk(AD_clk),
.AD_OE(AD_OE),
.CCD_clk(CCD_clk),
.CCD_rst(CCD_rst),
.CCD_sht(CCD_sht),
.CCD_data(CCD_data),
.CCD_M0(CCD_M0),
.CCD_M1(CCD_M1),
.CCD_RM(CCD_RM),

.serialsend_flag(),     //按协议发送数据标记为 
//Buffer操作相关 
.data(data),        	//要输入Buffer的数据
.wrclk(wrclk),      	//写入时钟
.wrreq(wrreq),      	//写入请求
.wrempty(),    			//写入buffer空标志
.wrfull(),     			//写入buffer满标志
.wrusedw(),     		//写入数量
.rdempty(),	            //读空标记
.rdfull(),              //读满标记
.frameclk(frameclk)     //数据帧计数,这个信号必须在写数据之前发出，上升沿有效
);

//----------   SerialSend --------//
SerialSend SerialSend_inst(
.clk(clk),        		             //模块时钟 50MHz
.rst_n(rst_n),                       //模块复位
.rs232_tx(rs232_tx),	             //232 TX引脚
.serialsend_flag(serialsend_flag),   //按协议发送数据标记为  
//Buffer操作相关 
.data(data),                         //要输入Buffer的数据
.wrclk(wrclk),      	             //写入时钟
.wrreq(wrreq),      		         //写入请求
.wrempty(wrempty),    			     //写入buffer空标志
.wrfull(wrfull),     			     //写入buffer满标志
.wrusedw(wrusedw),     			     //写入数量
.rdempty(rdempty),	                 //读空标记
.rdfull(rdfull),                     //读满标记
.frameclk(frameclk )                 //数据帧计数,这个信号必须在写数据之前发出，上升沿有效
);

dac7512 dac7512_inst(
.clk(clk),
.rst_n(rst_n),
.sclk(DAC_CLK),
.sync(DAC_SYNC),
.din(DAC_DIN)
);

endmodule


