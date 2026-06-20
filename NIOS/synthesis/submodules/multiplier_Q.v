module multiplier_Q (
    input  signed [31:0] dataa,
    input  signed [31:0] datab,
    output signed [31:0] result
);
    wire signed [63:0] mid_prod;
    assign mid_prod = dataa * datab;
    assign result = mid_prod[47:16];
endmodule
