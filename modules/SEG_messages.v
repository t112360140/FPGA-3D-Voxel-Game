module SEG_messages(
    input [31:0] seg_value,
    input [7:0] seg_enable,
    input [7:0] seg_neg,

    output [6:0] HEX0, output [6:0] HEX1, output [6:0] HEX2, output [6:0] HEX3,
    output [6:0] HEX4, output [6:0] HEX5, output [6:0] HEX6, output [6:0] HEX7
);
    wire [3:0] seg_value_ [7:0];
    assign seg_value_[0] = seg_value[31:28];
    assign seg_value_[1] = seg_value[27:24];
    assign seg_value_[2] = seg_value[23:20];
    assign seg_value_[3] = seg_value[19:16];
    assign seg_value_[4] = seg_value[15:12];
    assign seg_value_[5] = seg_value[11:8];
    assign seg_value_[6] = seg_value[7:4];
    assign seg_value_[7] = seg_value[3:0];

    seg_7 u_seg_7_0(.in(seg_value_[0]), .enable(seg_enable[0]), .neg(seg_neg[0]), .out(HEX0));
    seg_7 u_seg_7_1(.in(seg_value_[1]), .enable(seg_enable[1]), .neg(seg_neg[1]), .out(HEX1));
    seg_7 u_seg_7_2(.in(seg_value_[2]), .enable(seg_enable[2]), .neg(seg_neg[2]), .out(HEX2));
    seg_7 u_seg_7_3(.in(seg_value_[3]), .enable(seg_enable[3]), .neg(seg_neg[3]), .out(HEX3));
    seg_7 u_seg_7_4(.in(seg_value_[4]), .enable(seg_enable[4]), .neg(seg_neg[4]), .out(HEX4));
    seg_7 u_seg_7_5(.in(seg_value_[5]), .enable(seg_enable[5]), .neg(seg_neg[5]), .out(HEX5));
    seg_7 u_seg_7_6(.in(seg_value_[6]), .enable(seg_enable[6]), .neg(seg_neg[6]), .out(HEX6));
    seg_7 u_seg_7_7(.in(seg_value_[7]), .enable(seg_enable[7]), .neg(seg_neg[7]), .out(HEX7));
    
endmodule