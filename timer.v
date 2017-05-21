module timer
(
      clk_in,
      rst_n_in,
      out,
		timer
);

input clk_in;
input rst_n_in;
output out;
input [24:0] timer;

reg   [24:0]  timercount;

 
//parameter       CNT_NUM = 10000;

always @(posedge clk_in or negedge rst_n_in)
begin
	if(!rst_n_in)
		timercount <= 1;
	else
		timercount <= timer;
end
 
reg     [23:0]  cnt;
reg             clk_div;
 
always @(posedge clk_in or negedge rst_n_in)
begin
	if(!rst_n_in)
            begin
				cnt <= 24'd0;
				clk_div <= 1;
	    end
        else
            begin
		if(cnt>=timercount-1)
                    begin
			cnt <= 24'd0;
			clk_div <= ~clk_div;
		    end
                else
                        cnt <= cnt + 1;
	    end
end
 
assign out = clk_div;
 
endmodule


