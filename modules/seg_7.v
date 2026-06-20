module seg_7(
	input [3:0] in,
	input enable,
	input neg,
	output wire [6:0] out
);
	reg [7:0] sout_t=0;
	always@(*) begin
		if(enable) begin
			if(neg) sout_t = 8'b10111111;
			else begin
				case(in)
					4'h0: sout_t = 8'b11000000;
					4'h1: sout_t = 8'b11111001;
					4'h2: sout_t = 8'b10100100;
					4'h3: sout_t = 8'b10110000;
					4'h4: sout_t = 8'b10011001;
					4'h5: sout_t = 8'b10010010;
					4'h6: sout_t = 8'b10000010;
					4'h7: sout_t = 8'b11111000;
					4'h8: sout_t = 8'b10000000;
					4'h9: sout_t = 8'b10010000;
					4'ha: sout_t = 8'b10011111;
					4'hb: sout_t = 8'b10000011;
					4'hc: sout_t = 8'b11000110;
					4'hd: sout_t = 8'b10100001;
					4'he: sout_t = 8'b10000110;
					4'hf: sout_t = 8'b10001110;
					default: sout_t = 8'b11111111;
				endcase
			end
		end else sout_t = 8'b11111111;
	end
	
	assign out=sout_t[6:0];
endmodule