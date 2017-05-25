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

serialsend_flag,     //��Э�鷢�����ݱ��Ϊ  
//Buffer������� 
data,        			//Ҫ����Buffer������
wrclk,      			//д��ʱ��
wrreq,      			//д������
wrempty,    			//д��buffer�ձ�־
wrfull,     			//д��buffer����־
wrusedw,     			//д������
rdempty,	            //���ձ��
rdfull,              //�������
frameclk             //����֡����,����źű�����д����֮ǰ��������������Ч

);

input  clk; //�ⲿʱ������
input  n_rst;//����λ�ź�

input  [7:0] AD_data;//ADC TLC5510 ������IO 8bit
output reg AD_clk;//ADC TLC5510 ��ʱ��
output reg AD_OE;//ADC TLC5510 ��ʹ��
output reg CCD_clk;//CCD ELIS1024 �� ʱ��
output reg CCD_rst;//CCD ELIS1024 ��  ��λ�ź�
output reg CCD_sht;//CCD ELIS1024 �� ��������
output reg CCD_data;//CCD ELIS1024 �� �������ʹ��IO
output CCD_M0;//CCD ELIS1024 �� �ֱ�������IO 0
output CCD_M1;//CCD ELIS1024 �� �ֱ�������IO 1
output CCD_RM;//CCD ELIS1024 �� ģʽ����IO 

output reg serialsend_flag;   // ��Э�鷢�����ݱ��  

//Buffer������� 
output reg  [7:0] data;       		//Ҫ����Buffer������
output reg   wrclk;      	   //д��ʱ��
output reg   wrreq;      	   //д������

input        wrempty;    	   //д��buffer�ձ�־
input        wrfull;     	   //д��buffer����־
input  rdempty;	 //���ձ��
input  rdfull;     //�������

input [10:0] wrusedw;     	//д������
output  reg  frameclk;	      //����֡���� 

//��ʱ��
parameter TimeReset       =     1000 ;
parameter TimeSetClk      =     50  ; //������ڵĳ���
parameter TimeIntegration =     8000 ;
parameter TimeADCDelay    =     20  ;  //���������С�� TimeSetClk -1
reg   [25:0]  timercount;

//״̬��
reg [1:0]  MainState;  //��״̬
parameter  State1_Reset       = 2'b00 ;
parameter  State2_Integration = 2'b01 ;
parameter  State3_DataOut     = 2'b10 ;
parameter  State4             = 2'b11 ;
//��״̬  ��λ��RST SHT �ø� ����������ʱ������>  �õ�   ͬʱCLKҲҪ����
//��ɸ�λ���������ʱ�俪��
reg [1:0] RestState ;
parameter RestState_S1 = 2'b00;
parameter RestState_S2 = 2'b01;
parameter RestState_S3 = 2'b10;
parameter RestState_S4 = 2'b11;
//��״̬  ���֣���ʱ--> һ��CLK ����>DATA�ø� --> DATA�õ�
//��ɻ��ֽ��������ݲɼ���ʼ��ת��
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
//��״̬  ����: 4��������  4���ֽ⶯��
reg [1:0] DataOutState;
parameter DataOutState_S1 = 2'b00;
parameter DataOutState_S2 = 2'b01;
parameter DataOutState_S3 = 2'b10;
parameter DataOutState_S4 = 2'b11;
reg [11:0] DataCount;


//����CCD����ģʽ
assign CCD_M0 = 0;
assign CCD_M1 = 0;
assign CCD_RM = 0;


//����״̬  ��λ�����֡�����
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
			wrclk  <= 1'b0; //д��ʱ��
			wrreq  <= 1'b0;      			//д������
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
							AD_OE  <= 1'b1;  //ADC��λ
							frameclk <= 1'b1;	
							RestState <= RestState_S2;
						end
						RestState_S2:
						begin
						if(timercount>=TimeReset-1) //��ʱ��λ��ʱ�䳤��
							begin
								CCD_clk  <= 1'b0;
								RestState <= RestState_S3;
							end
						end
						RestState_S3:
						begin
							CCD_rst <= 1'b0;
							AD_OE  <=0 ;  //ADC��λ
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
							if(timercount>=TimeIntegration-1) //��ʱ���ֵ�ʱ�䳤�� 
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
							if(timercount>=TimeSetClk-1) //��ʱCLK��ʱ�䳤��
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
							if(timercount>=TimeSetClk-1) //��ʱCLK��ʱ�䳤��
							begin
								CCD_clk <= 1'b1;
								timercount  <= 0;
								IntegState <= IntegState_S6;
							end						
						end
						IntegState_S6:
						begin
							if(timercount>=TimeSetClk-1) //��ʱCLK��ʱ�䳤��
							begin
								CCD_clk <= 1'b0;
								CCD_data <=  1'b0;
								timercount  <= 0;
								IntegState <= IntegState_S7;
							end	
						end
						IntegState_S7:
						begin
							if(timercount>=TimeSetClk-1) //��ʱCLK��ʱ�䳤��
							begin
								CCD_clk <= 1'b1;
								timercount  <= 0;
								IntegState <= IntegState_S8;
								MainState <= State3_DataOut;
								wrreq <= 1'b1;      			//д������
								frameclk <=  1'b0;
								serialsend_flag  <=  1'b1;
							end	
						end
						IntegState_S8:
						begin
							//��
						end
						endcase
				end			
		State3_DataOut:
				begin 
						case (DataOutState)
						DataOutState_S1: //�ߵ�ƽ �ɼ�ADCֵ
						begin
							if(timercount>=TimeSetClk-1) //��ʱCLK��ʱ�䳤��
							begin
								CCD_clk <= 1'b0;
								DataCount <= DataCount + 1'b1;
								timercount  <= 0;
								DataOutState <= DataOutState_S2;
							end
							if(timercount == TimeADCDelay) //ADC����CLK������
									begin
										AD_clk <= 1'b1;
										wrclk  <= 1'b0; //д��ʱ��
									end
							//CCD_clk <= 1'b1;
							//���ADC���β���ֵ
							//test = ~test;
							//++++++++++++++++++++++++++++
						end
						DataOutState_S2: //�½���
						begin
						
							if(timercount>=TimeSetClk-1) //��ʱCLK��ʱ�䳤��
							begin
								CCD_clk <= 1'b1;
								timercount  <= 0;
								DataOutState <= DataOutState_S1;
							end
							else if(timercount == TimeADCDelay ) //ADC����CLK������
									begin
										AD_clk <= 1'b0;
										data <= AD_data;
										//data <= data + 1;//����
									end
									else	if(timercount == TimeADCDelay +1 ) //ADC����CLK������
											begin
												wrclk  <= 1'b1; //д��ʱ��
											end
							if(DataCount == 12'd1024)  //�ж��Ƿ�ɼ����
							begin
								CCD_clk <= 1'b0;
								CCD_sht <= 1'b0;
								CCD_rst <= 1'b0;
								AD_clk <= 1'b0;
								wrclk  <= 1'b0; //д��ʱ��
								wrreq  <= 1'b0;      			//д������
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


////��״̬  ��λ��RST SHT �ø� ����������ʱ������>  �õ�   ͬʱCLKҲҪ����
////��ɸ�λ���������ʱ�俪��
//
//task ELIS1024_RESET;
//
//endtask
//
//
////��״̬  ���֣���ʱ--> һ��CLK ����>DATA�ø� --> DATA�õ�
////��ɻ��ֽ��������ݲɼ���ʼ��ת��
//
//task ELIS1024_INTEGRATION;
//
//endtask
//
////��״̬  ����: 4��������  4���ֽ⶯��
//task ELIS1024_DATAOUT;
//
//endtask
//



endmodule




