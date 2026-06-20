module Timer(
	input             clk,
	input             tick,
	input             rst_n,
	output reg [31:0] timer
);
	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) timer<=0;
		else if(tick) timer<=timer+1;
	end
	
endmodule
