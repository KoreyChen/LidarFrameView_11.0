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
output [9:0]  wrusedw;     	//д������
input         frameclk;	      //����֡���� 
wire   [9:0]  rdusedw;     	//��������

//���ڲ������
wire bps_start;	//���յ����ݺ󣬲�����ʱ�������ź���λ
wire clk_bps;		   // clk_bps_r�ߵ�ƽΪ��������λ���м������,ͬʱҲ��Ϊ�������ݵ����ݸı�� 
reg  TxSendEN_Reg;      //���ƴ��ڷ���ʹ�ܼĴ���
reg  [7:0] SerialSendData_Reg;  //������Ҫ���͵����ݼĴ���
reg [2:0] FrameCount;   //����֡�ۼƼĴ���

//--------   ��ȡ FIFO    -------//
output wire  rdempty;	 //���ձ��
output wire  rdfull;     //�������
wire  [7:0] fifo_data;   //FIFO ����
reg   rdclk_reg;         //��ʱ��
reg   rdreq_reg;         //������
wire  fifo_clear;
reg   fifo_clear_reg;

wire send_complete;

reg SerialSendbtn1; //�����ز���ǰ״̬
reg SerialSendbtn2; //�����ز���֮ǰ״̬
wire SerialSendPosedgeFalg;

reg btn1; //�����ز���ǰ״̬
reg btn2; //�����ز���֮ǰ״̬
reg btnOne1;
reg btnOne2;
wire PosedgeFalg;
wire PosedgeFalgOne;
reg  SendOneFrameFlag;

reg [2:0] serialState;              //���ڷ���֡״̬��
parameter serialState_Start = 0;    //��ʼ�ж�
parameter serialState_Head  = 1;    //����֡ͷ
parameter serialState_CMD   = 2;    //����������
parameter serialState_Data  = 3;    //��������
parameter serialState_End   = 4;    //����֡β
parameter serialState_Stop  = 5;    //���ͽ���

reg [10:0] serialSendCount;         //֡�����ܸ����ۼ���
                                    //֡��ʽ����
parameter  SD1 = 8'h7B;             //֡ͷ {
parameter  SD2 = 8'h28;             //    ��
parameter  SD3 = 8'h31;             //     1
parameter  SD4 = 8'h30;             //     0
parameter  SD5 = 8'h32;             //     2
parameter  SD6 = 8'h34;             //     4
                                    //    ����  ��1024����
parameter  SD7 = 8'h29;             //     )
parameter  SD8 = 8'h7D;             //֡β }

reg [2:0] sendDelayCount;           //������ʱ���������
reg nextStateFlag;                  //������һ��״̬�ı�� 

assign	PosedgeFalg = btn1&(~btn2);
assign	PosedgeFalgOne = btnOne1 & (~btnOne2);
assign SerialSendPosedgeFalg = SerialSendbtn1 & (~SerialSendbtn2); //��������Ч
assign fifo_clear = fifo_clear_reg;


//*********** ���ڲ������� ***********//
//-----------     TX      ----------//												
speed_select	speed_tx(	
							.clk(clk),	//������ѡ��ģ��
							.rst_n(rst_n),
							.bps_start(bps_start),
							.clk_bps(clk_bps)
						);
						
uart_tx    my_uart_tx (
				.clk(clk),                       //����ʱ�� 50MHz 
				.rst_n(rst_n),                   //��λ�ź�
				.tx_data(SerialSendData_Reg),               //��Ҫ���͵�����  8bit
				.tx_int(TxSendEN_Reg),                 //���� �����ź�  �͵�ƽ��Ч
				.rs232_tx(rs232_tx),             //����TX����
				.clk_bps(clk_bps),               //clk_bps_r�ߵ�ƽΪ��������λ���м������,ͬʱҲ��Ϊ�������ݵ����ݸı��
				.bps_start(bps_start),           //���ջ���Ҫ�������ݣ�������ʱ�������ź���λ
				.send_complete(send_complete)    //������ɱ�־λ �߱�ʾ�ѷ������  �ͱ�ʾ���ڷ���
			);		
			
//********* ��Э�鷢�Ͳ��� ************//	
//------  ��¼SerialSendʹ�ܱ�� ------//
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

//�������з���
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)
	begin
		serialState <= 0;
		serialSendCount <= 0;
		TxSendEN_Reg <= 1; //���ڷ����ж�Ϊ�½��ش��������︴λΪ�ߵ�ƽ
		sendDelayCount <= 0;
		nextStateFlag <=0;
		rdclk_reg <=0;
		rdreq_reg <=0;
	end
	else
	begin
		case(serialState)
			serialState_Start: //����Ƿ�ʼ����
			begin
				//���з���ʹ����������Ч�Ҳ��񵽵�֡������Ϊ��ʱ��ʼ���͡�
				if((SerialSendEN_REG == 2'b1)&&(FrameCount != 3'b0)) 
				begin
					serialState  <= serialState_Head;
					SendOneFrameFlag <= 0;
				end
			end
			serialState_Head:  //����֡ͷ
			begin
				if((sendDelayCount == 0 )&&(send_complete))
				begin
					 //���֡ͷ�ַ�
					case(serialSendCount)
						11'd0:  SerialSendData_Reg <= SD1;
						11'd1:  SerialSendData_Reg <= SD2;
						11'd2:  SerialSendData_Reg <= SD3;
						11'd3:  SerialSendData_Reg <= SD4;
						11'd4:  SerialSendData_Reg <= SD5;				
						11'd5:  begin
								SerialSendData_Reg <= SD6;		
								nextStateFlag <= 1;
								rdreq_reg <= 1;  //�ͷ�FIFO�����ַ�Ϊ0������ 
								rdclk_reg <= 1; 
								end
					endcase
					sendDelayCount <= 1;//������һ��
				end
				else if(sendDelayCount == 1) //�����ж��½��ش���
				begin
					//��ʱһ��ʱ�����ں�ʹ��һ�����ڷ����ж��ź�
					//�����ڴ��ڿ���ʱ��������
						TxSendEN_Reg <= 0;
						serialSendCount <= serialSendCount +1;
						sendDelayCount <= 2;
				end
				else if(sendDelayCount >= 2)//�����ж��½��ظ�λ���ȴ�5������
				begin
					sendDelayCount <= sendDelayCount +1;
					if(sendDelayCount > 6)
					begin
						TxSendEN_Reg <= 1; //�����жϸ�λ
						sendDelayCount <= 0;
						if(nextStateFlag) //�ж��Ƿ�Ӧ�ý��������ַ��ͽ׶�
						begin
							serialState <= serialState_CMD;
							nextStateFlag <= 0;
							rdclk_reg <= 0; 
						end
					end
				end
			end
			serialState_CMD://�˹��ܱ����������룬�ɼ�������֡�����
			begin
				serialState <= serialState_Data; //�������ݷ��ͽ׶�
			end
			serialState_Data:
			begin
				//�ж�fifo�Ƿ�Ϊ��
				if(!wrempty)//�����ڴ��ڿ���ʱ�������� 
				begin
					//��fifo�ж�������
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
							if(serialSendCount>=11'd1029)   //��������������ͬһ��begin�������ԣ�count +1  Ҫ����Ƚ� count>=12'd1029,������1029
								begin
									serialState <= serialState_End;
									rdreq_reg <= 0; //�رն����� 
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
					 //���֡ͷ�ַ�
					case(serialSendCount)
						11'd1030:   SerialSendData_Reg <= SD7;
						12'd1031:  	begin
									SerialSendData_Reg <= SD8;		
									nextStateFlag <= 1;
									end
					endcase
					sendDelayCount <= 1;//������һ��
				end
				else if(sendDelayCount == 1) //�����ж��½��ش���
				begin
					//��ʱһ��ʱ�����ں�ʹ��һ�����ڷ����ж��ź�
					//�����ڴ��ڿ���ʱ��������
						TxSendEN_Reg <= 0;
						serialSendCount <= serialSendCount +1;
						sendDelayCount <= 2;
				end
				else if(sendDelayCount >= 2)//�����ж��½��ظ�λ���ȴ�5������
				begin
					sendDelayCount <= sendDelayCount +1;
					if(sendDelayCount > 6)
					begin
						TxSendEN_Reg <= 1; //�����жϸ�λ
						sendDelayCount <= 0;
						if(nextStateFlag) //�ж��Ƿ�Ӧ�ý��������ַ��ͽ׶�
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
//-------------------------------//
//----------  ����FIFO  ----------//
senddcfifo	SendFifo_inst (
   .aclr ( fifo_clear ),    //��ղ���
   .data ( data ),          //Ҫ����Buffer������
   .rdclk ( rdclk_reg ),        //��ʱ��
   .rdreq ( rdreq_reg ),        //������
   .wrclk ( wrclk ),        //д��ʱ��
   .wrreq ( wrreq ),        //д������	
   .q ( fifo_data ),        //FIFO ����
   .rdempty ( rdempty ),    //������
   .rdfull (  rdfull ),     //�������
   .rdusedw ( rdusedw  ),
   .wrempty ( wrempty ),    //д��buffer�ձ�־
   .wrfull ( wrfull ),      //д��buffer����־
   .wrusedw ( wrusedw )     //д������	
	);
//-------------------------------//

endmodule

