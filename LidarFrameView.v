module LidarFrameView
(
clk,        		   //ģ��ʱ�� 50MHz
rst_n,               //ģ�鸴λ
rs232_tx,	         //232 TX����
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
);

input  clk;       		   //ģ��ʱ�� 50MHz
input  rst_n;            //ģ�鸴λ
input [7:0] AD_data;
input startPoint;
output rs232_tx;	      //232 TX����
output AD_clk;
output AD_OE;
output CCD_clk;
output CCD_rst;
output CCD_sht;
output CCD_data;
output CCD_M0;
output CCD_M1;
output CCD_RM;

wire  serialsend_flag;     //��Э�鷢�����ݱ���Ϊ  
//Buffer�������� 
wire  [7:0]data;        			//Ҫ����Buffer������
wire  wrclk;      			//д��ʱ��
wire  wrreq;      			//д������
wire  wrempty;    			//д��buffer�ձ�־
wire  wrfull;     			//д��buffer����־
wire  [9:0] wrusedw;     			//д�����wire  rdempty;	            //��ձ���wire  rdfull;              //��������
wire  frameclk;             //����֡����,�����źű�����д����֮ǰ��������������Ч


wire sample_clk;
wire [8:0] frame_number;
wire enable;
wire  [25:0] timeSet; //������������ 26λ ����67 108 863
wire  [8:0] resolution;//�ֱ������� ,����360   1

assign enable=1;
assign timeSet = 22000;
assign resolution = 10;
assign serialsend_flag = 1;


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

.serialsend_flag(),     //��Э�鷢�����ݱ���Ϊ  
//Buffer�������� 
.data(data),        			//Ҫ����Buffer������
.wrclk(wrclk),      			//д��ʱ��
.wrreq(wrreq),      			//д������
.wrempty(),    			//д��buffer�ձ�־
.wrfull(),     			//д��buffer����־
.wrusedw(),     			//д�����.rdempty(),	            //��ձ���.rdfull(),              //��������
.frameclk(frameclk)             //����֡����,�����źű�����д����֮ǰ��������������Ч

);

//----------   ����SerialSend --------//
SerialSend SerialSend_inst(
.clk(clk),        		   //ģ��ʱ�� 50MHz
.rst_n(rst_n),//ģ�鸴λ
.rs232_tx(rs232_tx),	      //232 TX����
.serialsend_flag(serialsend_flag),     //��Э�鷢�����ݱ���
//Buffer�������� 
.data(data),      //Ҫ����Buffer������
.wrclk(wrclk),      	//д��ʱ��
.wrreq(wrreq),      		//д������
.wrempty(wrempty),    			   //д��buffer�ձ�־
.wrfull(wrfull),     			   //д��buffer����־
.wrusedw(wrusedw),     			   //д�����.rdempty(rdempty),	               //��ձ���.rdfull(rdfull),                 //��������
.frameclk(frameclk )        //����֡����,�����źű�����д����֮ǰ��������������Ч

);















endmodule


