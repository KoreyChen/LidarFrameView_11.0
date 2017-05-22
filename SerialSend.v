//`timescale 1ns / 1ps

module SerialSend(
clk,        		   //ģ��ʱ�� 50MHz
rst_n,               //ģ�鸴λ
rs232_tx,	         //232 TX����
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

input clk;			            // 50MHz��ʱ��
input rst_n;		            // �͵�ƽ��λ�ź�
//input wire rs232_rx;		   // RS232���������ź�
output wire rs232_tx;	      //	RS232���������ź�
input wire serialsend_flag;   // ��Э�鷢�����ݱ��  
reg        SerialSendEN_REG;  // ��Э�鷢������ʹ�ܱ�ǼĴ���

//Buffer������� 
input [7:0]   data;       		//Ҫ����Buffer������
input         wrclk;      	   //д��ʱ��
input         wrreq;      	   //д������
output        wrempty;    	   //д��buffer�ձ�־
output        wrfull;     	   //д��buffer����־
output [9:0] wrusedw;     	//д������
input         frameclk;	      //����֡���� 

//���ڲ������
wire bps_start;	//���յ����ݺ󣬲�����ʱ�������ź���λ
wire clk_bps;		   // clk_bps_r�ߵ�ƽΪ��������λ���м������,ͬʱҲ��Ϊ�������ݵ����ݸı�� 
reg  [7:0] Tx_data;
wire [7:0] Tx_data_t;
wire Tx_flag;
wire TxDataClk;

//Э�鷢�Ͳ���
reg [11:0] count;       //������������
reg [1:0]  SateCount;   //����״̬����
parameter  SD1 = 8'h7B; //֡ͷ {
parameter  SD2 = 8'h28; //    ��
parameter  SD3 = 8'h31; //     1
parameter  SD4 = 8'h30; //     0
parameter  SD5 = 8'h32; //     2
parameter  SD6 = 8'h34; //     4
                        //    ����  ��1024����
parameter  SD7 = 8'h29; //     )
parameter  SD8 = 8'h7D; //֡β }

parameter  S1 =  2'b00; //����֡ͷ״̬
parameter  S2 =  2'b01; //��������״̬
parameter  S3 =  2'b10; //����֡β״̬

wire TxSendEN;          //���ƴ��ڷ���ʹ���ź�
reg  TxSendEN_Reg;      //���ƴ��ڷ���ʹ�ܼĴ���
reg  [7:0] SerialSendData_Reg;  //������Ҫ���͵����ݼĴ���
	
reg [1:0] sendcount;    //����FIFO�������� 00 ʱ�ж��������S2�׶Σ��Ͷ�ȡһ��FIFO��������Ϊ01ʱ����ø߷���״̬���ø߷��ͣ�10ʱ�ر�fifo��11ʱ�õͷ���״̬
parameter COUNT_S1 = 2'b00; 
parameter COUNT_S2 = 2'b01;
parameter COUNT_S3 = 2'b10;
parameter COUNT_S4 = 2'b11;

reg fifoReadFlag;       //��Ҫ����Fifo��ȡ��־
reg fifoReadReady;      //Fifo��ȡ׼���ñ�־
reg S3_flag;            //���ڵ�rdempty = 1ʱ�޷����� ֡β������

reg [2:0] FrameCount;   //����֡�ۼƼĴ���


//****  ����FIFO��ȡ���ݵ���ʱʱ��  ****//
//wire   rstFifoTtime;
//reg    rstFifoTtime_reg;
//assign rstFifoTtime = rstFifoTtime_reg;
//output wire   rdFifoTimeflag;

//--------   ��ȡ FIFO    -------//
output wire  rdempty;	 //���ձ��
output wire  rdfull;     //�������
wire  rdclk;   	       //��ʱ��
wire  rdreq;   	       //������
wire  [7:0] fifo_data;   //FIFO ����
reg   rdclk_reg;         //��ʱ��
reg   rdreq_reg;         //������
wire  fifo_clear;
reg   fifo_clear_reg;

wire send_complete;

//*********** ���ڲ������� ***********//
//-----------     TX      ----------//												
speed_select		speed_tx(	
							.clk(clk),	//������ѡ��ģ��
							.rst_n(rst_n),
							.bps_start(bps_start),
							.clk_bps(clk_bps)
						);
						
uart_tx    my_uart_tx (
				.clk(clk),                       //����ʱ�� 50MHz 
				.rst_n(rst_n),                   //��λ�ź�
				.tx_data(SerialSendData_Reg),               //��Ҫ���͵�����  8bit
				.tx_int(TxSendEN),                 //���� �����ź�  �͵�ƽ��Ч
				.rs232_tx(rs232_tx),             //����TX����
				.clk_bps(clk_bps),               //clk_bps_r�ߵ�ƽΪ��������λ���м������,ͬʱҲ��Ϊ�������ݵ����ݸı��
				.bps_start(bps_start),           //���ջ���Ҫ�������ݣ�������ʱ�������ź���λ
				.send_complete(send_complete)    //������ɱ�־λ �߱�ʾ�ѷ������  �ͱ�ʾ���ڷ���
			);		
	

//-----------------------------------//

//********  �������ݷ��͵��ٶ�  ********//	 
//����ٶ�ҪС�ڲ����ʷ��͵��ٶ�,TX������ɱ�־λ��Ӻ󣬾Ͳ���Ҫ�����
parameter      TXDATA_CNT_NUM = 1500;	
timer    		my_timer_tx(
					.rst_n_in(rst_n),
					.clk_in(clk),				
					.out(TxDataClk),
					.timer(TXDATA_CNT_NUM)
					);
//--------------------------------//					
		

//********* ��Э�鷢�Ͳ��� ************//	
//reg [7:0] Test;
assign TxSendEN=TxSendEN_Reg;

//------  ��¼SerialSendʹ�ܱ�� ------//
always @(posedge clk or negedge rst_n )
begin
		if(!rst_n)
			SerialSendEN_REG  <= 1'b0;
		else
			SerialSendEN_REG <= serialsend_flag;
end

reg btn1; //�����ز���ǰ״̬
reg btn2; //�����ز���֮ǰ״̬
reg btnOne1;
reg btnOne2;
wire PosedgeFalg;
wire PosedgeFalgOne;
reg  SendOneFrameFlag;
assign	PosedgeFalg = btn1&(~btn2);
assign	PosedgeFalgOne = btnOne1 & (~btnOne2);
//------  ��¼frameclk ֡���� ------//
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
				if((PosedgeFalgOne)&&(FrameCount > 1'b0))//������һ֡�ͼ���һ��
					FrameCount <= FrameCount - 1'b1;
			end
		end
end

reg SendControlFlag;


//---------  Э�鷢�Ϳ���ģ��   -------//
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
				//���Ʒ���ǿ��ʹ�ܣ��ر�
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
				COUNT_S1:  //��ȡFIFOֵ
					begin
						rdclk_reg <= 1'b1;   //�򿪶�ʱ��
						if(fifoReadFlag==1'b1)// �ж��Ƿ���Ҫ��FIFO�����Ϊ�վ͵ȴ�
						begin
									if(rdempty==1'b1)//�ж�FIFO�Ƿ�Ϊ��
										begin
										rdreq_reg <= 1'b0;   //�رն�����
										if(S3_flag == 1'b1)
											sendcount <= COUNT_S2;
										else
											sendcount <= COUNT_S1;
										end
									else
										begin
											rdreq_reg <= 1'b1;   //�򿪶�����
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
								S1:  //����֡ͷ
								begin
									SendOneFrameFlag <= 1'b0; //������һ֡�������
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
										//����TX ����
										TxSendEN_Reg <= 1'b1;
										count <= count + 1'b1; 
									end
								end 
								S2:    //��������
								begin  //����ADC����  û�п�����ʼ����
									if(count>12'd5)
									begin
										if(fifoReadReady==1'b1) //�жϵ�FIFO����һ��byteʱ�ŷ���
										begin
											SerialSendData_Reg <= fifo_data;
		//									Test <= Test +1'b1;
		//									SerialSendData_Reg <= Test;
											//����TX ����
											TxSendEN_Reg <= 1'b1;
											count <= count + 1'b1; 
											fifoReadReady<=1'b0;
											if(count>=12'd1029)   //��������������ͬһ��begin�������ԣ�count +1  Ҫ����Ƚ� count>=12'd1029,������1029
												begin
													SateCount <= S3;
													fifoReadFlag <= 1'b0;
													rdreq_reg <= 1'b0;   //�رն�����
													S3_flag <= 1'b1;
												end
											else
												fifoReadFlag <= 1'b1;
										end
									end
								end
								S3:  //����֡β
								begin
									case(count)
										12'd1030:  SerialSendData_Reg <= SD7;
										12'd1031:  SerialSendData_Reg <= SD8;
									endcase	
									//����TX ����
									TxSendEN_Reg <= 1'b1;
									count <= count + 1'b1; 
									if(count>=12'd1031)
										begin
											count <= 0;
											S3_flag <= 1'b0;
											SendOneFrameFlag <= 1'b1; //������һ֡�����λ
											SateCount <= S1;
										end
								end
								endcase	
							end
							sendcount <= COUNT_S3;
						end
				COUNT_S3:
					begin
					rdclk_reg <= 1'b0;   //�رն�ʱ��
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

//*********  FIFO ���� ***********//
//--------  ���FIFO -------------//
always @(posedge clk or negedge rst_n )
begin
		//ģ�鸴λʱ���
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
//----------  ����FIFO  ----------//
senddcfifo	SendFifo_inst (
   .aclr ( fifo_clear ),    //��ղ���
   .data ( data ),          //Ҫ����Buffer������
   .rdclk ( rdclk ),        //��ʱ��
   .rdreq ( rdreq ),        //������
   .wrclk ( wrclk ),        //д��ʱ��
   .wrreq ( wrreq ),        //д������	
   .q ( fifo_data ),        //FIFO ����
   .rdempty ( rdempty ),    //������
   .rdfull (  rdfull ),     //�������
   .rdusedw (   ),
   .wrempty ( wrempty ),    //д��buffer�ձ�־
   .wrfull ( wrfull ),      //д��buffer����־
   .wrusedw ( wrusedw )     //д������	
	);
//-------------------------------//

endmodule

