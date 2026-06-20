module multiplier (
    input  signed [31:0] dataa,
    input  signed [31:0] datab,
    output signed [31:0] result
);
    assign result = dataa * datab;
endmodule
