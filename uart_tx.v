module uart_tx(
				clk,          //����ʱ�� 50MHz 
				rst_n,        //��λ�ź�
				tx_data,      //��Ҫ���͵�����  8bit
				tx_int,       //���� �����ź�
				rs232_tx,     //����TX����
				clk_bps,      //clk_bps_r�ߵ�ƽΪ��������λ���м������,ͬʱҲ��Ϊ�������ݵ����ݸı��
				bps_start,    //���ջ���Ҫ�������ݣ�������ʱ�������ź���λ
				send_complete //������ɱ�־λ �߱�ʾ�ѷ������  �ͱ�ʾ���ڷ���
			);

input clk;			// 50MHz��ʱ��
input rst_n;		//�͵�ƽ��λ�ź�
input clk_bps;		// clk_bps_r�ߵ�ƽΪ��������λ���м������,ͬʱҲ��Ϊ�������ݵ����ݸı��
input[7:0] tx_data;	//�������ݼĴ���
input tx_int;		//���������ж��ź�,���յ������ڼ�ʼ��Ϊ�ߵ�ƽ,�ڸ�ģ�������������½������������ڷ�������
output rs232_tx;	// RS232���������ź�
output bps_start;	//���ջ���Ҫ�������ݣ�������ʱ�������ź���λ
output reg send_complete;
//---------------------------------------------------------
reg tx_int0,tx_int1,tx_int2;	//tx_int�źżĴ�������׽�½����˲���
wire neg_tx_int;	// tx_int�½��ر�־λ

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

assign neg_tx_int =  ~tx_int1 & tx_int2;	//��׽���½��غ�neg_tx_int���߱���һ����ʱ������

//---------------------------------------------------------
reg [7:0] tx_data_t;	//���������ݵļĴ���
//---------------------------------------------------------
reg bps_start_r;
reg tx_en;	//��������ʹ���źţ�����Ч
reg[3:0] num;

always @ (posedge clk or negedge rst_n) 
begin
	if(!rst_n) begin
			bps_start_r <= 1'bz;
			tx_en <= 1'b0;
			tx_data_t <= 8'd0;
			send_complete <= 1;
		end
	else if(neg_tx_int) begin	//����������ϣ�׼���ѽ��յ������ݷ���ȥ
			bps_start_r <= 1'b1;
			tx_data_t <= tx_data;	//�ѽ��յ������ݴ��뷢�����ݼĴ���
			tx_en <= 1'b1;		//���뷢������״̬��
			send_complete <= 1'b0;
		end
	else if(num==4'd11) begin	//���ݷ�����ɣ���λ
			//bps_start_r <= 1'b0;
			//tx_en <= 1'b0;
			//send_complete <= 1'b1;
		end
	else if(num==4'd12) begin	//���ݷ�����ɣ���λ
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
						4'd0: rs232_tx_r <= 1'b0; 	//������ʼλ
						4'd1: rs232_tx_r <= tx_data_t[0];	//����bit0
						4'd2: rs232_tx_r <= tx_data_t[1];	//����bit1
						4'd3: rs232_tx_r <= tx_data_t[2];	//����bit2
						4'd4: rs232_tx_r <= tx_data_t[3];	//����bit3
						4'd5: rs232_tx_r <= tx_data_t[4];	//����bit4
						4'd6: rs232_tx_r <= tx_data_t[5];	//����bit5
						4'd7: rs232_tx_r <= tx_data_t[6];	//����bit6
						4'd8: rs232_tx_r <= tx_data_t[7];	//����bit7
						4'd9: rs232_tx_r <= 1'b1;	//���ͽ���λ
					 	default: rs232_tx_r <= 1'b1;
						endcase
				end
			else if(num==4'd12) num <= 4'd0;	//��λ
		end
end

assign rs232_tx = rs232_tx_r;

endmodule


