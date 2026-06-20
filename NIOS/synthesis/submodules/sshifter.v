module sshifter (
    input signed [31:0] dataa,
    input        [31:0] datab,
    output       [31:0] result
);
    assign result = datab[5]?(dataa>>>datab[4:0]):(dataa<<<datab[4:0]);
endmodule
