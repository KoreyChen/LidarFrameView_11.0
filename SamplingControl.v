module SamplingControl(
clk,
n_rst,
timeSet,
resolution,
startPoint,
enable,

sample_clk,
frame_number
);

input  clk; //�ⲿʱ������  50 Mhz
input  n_rst;//����λ�ź�
input  [25:0] timeSet; //����������� 26λ ���67 108 863
input  [8:0] resolution;//�ֱ������� ,���360   1
input  startPoint;//���������������������ź�
input  enable; //����ʹ���ź�

output sample_clk;//����ADC��CCD�ɼ�һ֡���ݣ���������Ч
output reg [8:0] frame_number;//֡���� (0~359)


//���ݳ�ʼ��
reg [8:0]  resolutionSet_reg; //�ֱ����趨��������ȷ����תһȦ�ж���֡����
reg [25:0] timeSet_reg;
reg iniok_reg;//��ʼ����־λ
reg one_check;


//֡��ʱ��
reg   [25:0]  timercount;
reg   sample_clk_reg;
reg   [8:0] frameCount;
reg   SendLastClk_flag;
//������ʼλ��������
reg startPoint_reg ; 
reg bt1;
reg bt2;
reg posedge_reg;
always @(posedge clk or negedge n_rst)
begin
	if(!n_rst)
	begin
		bt1 <= 0;
		bt2 <= 0;
		startPoint_reg <=0;
		posedge_reg <=0;
	end
	else
	begin
		bt1 <= startPoint;
		bt2 <= bt1;
		posedge_reg <= (!bt1)&bt2; //������
		if(posedge_reg)
			startPoint_reg <= 1;
	end
end

assign sample_clk = sample_clk_reg;

//���ݳ�ʼ��
always @(posedge clk or negedge n_rst)
begin
	if(!n_rst)
	begin
		resolutionSet_reg <= 0;
		iniok_reg <= 1'b0;
		timeSet_reg <= 0;
		one_check <= 0;
	end
	else if((enable)&&(!one_check))
			begin
				resolutionSet_reg <= resolution;	
				timeSet_reg <= (timeSet>>1);
				iniok_reg <= 1'b1;
				one_check <= 1'b1;
			end
end

//֡��ʱ��
reg state;
reg clk_out_reg;

always @(posedge clk or negedge n_rst)
begin
	if(!n_rst)
   begin  
		timercount <= 0;
		sample_clk_reg <= 0;
		frameCount <= 0;
		SendLastClk_flag <= 0;
		frame_number <= 0;
		state <= 0;
		clk_out_reg <= 0;
	end
   else
	begin
	   case(state)
		1'b0:
			begin
				if((startPoint_reg)&&(iniok_reg))
					begin
					frame_number <= 0;	
					sample_clk_reg <= 1;
					state <= 1;
					frameCount = 1;
					end
			end
		1'b1:
			 begin
					if(frameCount <= resolutionSet_reg ) //֡��û������
					begin
						if(timercount >= timeSet_reg-1) //��ʱ
						begin
							timercount <= 0;
							
							if(!sample_clk_reg)
							begin
									frame_number <= frameCount;
									frameCount <= frameCount + 1;
							end
							clk_out_reg <= 1;
						end
						else
							timercount <= timercount + 1;
					end
					else
					begin
						if(timercount >= timeSet_reg-1) //����ʱ���һ��ʱ����������
						begin
							SendLastClk_flag <= 1;
							if(SendLastClk_flag)
							begin
								frame_number <= 0;
							end
							timercount <= 0;
							sample_clk_reg <= 0;
						end
						else
							timercount <= timercount + 1;
					end
					if(clk_out_reg) //��֤frame_number ����sample_clk_reg һ����Ƶ���� ���
					begin
						sample_clk_reg <= ~sample_clk_reg;
						clk_out_reg <= 0;	
					end
			 end
		endcase
	end
end

endmodule

