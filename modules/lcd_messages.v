module lcd_messages(
    input iCLK, iRST_N,

    input [255:0] iMSG,
    
    // LCD 實體介面
    output [7:0] LCD_DATA,
    output LCD_RW, LCD_EN, LCD_RS
);

	// 內部狀態機與計數器
	reg [5:0] LUT_INDEX;
	reg [8:0] LUT_DATA;
	reg [5:0] mLCD_ST;
	reg [17:0] mDLY;
	reg mLCD_Start;
	reg[7:0] mLCD_DATA;
	reg mLCD_RS;
	wire mLCD_Done;

	parameter LUT_SIZE = 38; // 5(初始化) + 16(第一行) + 1(換行) + 16(第二行)

	// 控制 LCD 狀態機
	always@(posedge iCLK or negedge iRST_N) begin
		 if(!iRST_N) begin
			  LUT_INDEX <= 0;
			  mLCD_ST   <= 0;
			  mDLY      <= 0;
			  mLCD_Start<= 0;
			  mLCD_DATA <= 0;
			  mLCD_RS   <= 0;
		 end else begin
			  if(LUT_INDEX < LUT_SIZE) begin
					case(mLCD_ST)
					0: begin
							  mLCD_DATA <= LUT_DATA[7:0];
							  mLCD_RS   <= LUT_DATA[8];
							  mLCD_Start<= 1;
							  mLCD_ST   <= 1;
						 end
					1: begin
							  if(mLCD_Done) begin
									mLCD_Start <= 0;
									mLCD_ST    <= 2;
							  end
						 end
					2: begin
							  if(mDLY < 18'h3FFFE)
									mDLY <= mDLY + 1'b1;
							  else begin
									mDLY <= 0;
									mLCD_ST <= 3;
							  end
						 end
					3: begin
							  LUT_INDEX <= LUT_INDEX + 1'b1;
							  mLCD_ST   <= 0;
						 end
					endcase
			  end else if(refresh == 1) begin
					// 【關鍵修改】: 不要回到 0，回到 4 (Set DDRAM address 0x00)。
					// 跳過前 3 個初始化指令(包含會導致閃爍的清空螢幕 0x01)，直接把游標移回開頭重新覆蓋文字
					LUT_INDEX <= 4; 
			  end else begin
					// 確保在不刷新的時候，狀態機保持在一個安全狀態，不觸發新的 Start
					mLCD_Start <= 0; 
			  end
		 end
	end

	// 畫面刷新計數器 (約 0.1 秒刷新一次)
	reg [23:0] counter;
	reg refresh;
	always@(posedge iCLK) begin
		 if(counter == 24'h4C4B40) begin 
			  refresh <= 1;
			  counter <= 0;
		 end else begin
			  counter <= counter + 1;
			  refresh <= 0;
		 end
	end

	// 將傳入的 256 bits 切割並填入查表
	always@(*) begin
		 case(LUT_INDEX)
		 // 初始化指令 (只在剛通電時執行一次)
		 // 【修改2】將所有的 <= 改成 = 
		 0: LUT_DATA = 9'h038;
		 1: LUT_DATA = 9'h00C;
		 2: LUT_DATA = 9'h001; // 清除螢幕 (0x01)
		 3: LUT_DATA = 9'h006;
		 // 每次刷新從這裡開始
		 4: LUT_DATA = 9'h080; // 設定游標回第一行開頭
		 // 第一行 (Line 1): 截取 [255:128]
		 5:  LUT_DATA = {1'b1, iMSG[255:248]};
		 6:  LUT_DATA = {1'b1, iMSG[247:240]};
		 7:  LUT_DATA = {1'b1, iMSG[239:232]};
		 8:  LUT_DATA = {1'b1, iMSG[231:224]};
		 9:  LUT_DATA = {1'b1, iMSG[223:216]};
		 10: LUT_DATA = {1'b1, iMSG[215:208]};
		 11: LUT_DATA = {1'b1, iMSG[207:200]};
		 12: LUT_DATA = {1'b1, iMSG[199:192]};
		 13: LUT_DATA = {1'b1, iMSG[191:184]};
		 14: LUT_DATA = {1'b1, iMSG[183:176]};
		 15: LUT_DATA = {1'b1, iMSG[175:168]};
		 16: LUT_DATA = {1'b1, iMSG[167:160]};
		 17: LUT_DATA = {1'b1, iMSG[159:152]};
		 18: LUT_DATA = {1'b1, iMSG[151:144]};
		 19: LUT_DATA = {1'b1, iMSG[143:136]};
		 20: LUT_DATA = {1'b1, iMSG[135:128]};
		 // 換行指令
		 21: LUT_DATA = 9'h0C0; // 設定游標到第二行開頭
		 // 第二行 (Line 2): 截取 [127:0]
		 22: LUT_DATA = {1'b1, iMSG[127:120]};
		 23: LUT_DATA = {1'b1, iMSG[119:112]};
		 24: LUT_DATA = {1'b1, iMSG[111:104]};
		 25: LUT_DATA = {1'b1, iMSG[103:96]};
		 26: LUT_DATA = {1'b1, iMSG[95:88]};
		 27: LUT_DATA = {1'b1, iMSG[87:80]};
		 28: LUT_DATA = {1'b1, iMSG[79:72]};
		 29: LUT_DATA = {1'b1, iMSG[71:64]};
		 30: LUT_DATA = {1'b1, iMSG[63:56]};
		 31: LUT_DATA = {1'b1, iMSG[55:48]};
		 32: LUT_DATA = {1'b1, iMSG[47:40]};
		 33: LUT_DATA = {1'b1, iMSG[39:32]};
		 34: LUT_DATA = {1'b1, iMSG[31:24]};
		 35: LUT_DATA = {1'b1, iMSG[23:16]};
		 36: LUT_DATA = {1'b1, iMSG[15:8]};
		 37: LUT_DATA = {1'b1, iMSG[7:0]};
		 // 【修改3】給定明確的預設值，避免產生未知狀態(x)
		 default: LUT_DATA = 9'h000; 
		 endcase
	end

	// 呼叫底層控制器
	lcd_controller u0(
		 .iDATA(mLCD_DATA),
		 .iRS(mLCD_RS),
		 .iStart(mLCD_Start),
		 .oDone(mLCD_Done),
		 .iCLK(iCLK),
		 .iRST_N(iRST_N),
		 .LCD_DATA(LCD_DATA),
		 .LCD_RW(LCD_RW),
		 .LCD_EN(LCD_EN),
		 .LCD_RS(LCD_RS)
	);

endmodule