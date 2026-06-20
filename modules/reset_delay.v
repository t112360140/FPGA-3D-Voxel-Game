module reset_delay(
    input  iCLK,
    input rst,
    output reg oRESET
);
    reg [19:0] Cont = 0;
    always @(posedge iCLK or negedge rst) begin
        if(!rst) begin
            Cont = 0;
        end else if (Cont != 20'hFFFFF) begin
            Cont   <= Cont + 1'b1;
            oRESET <= 1'b0;
        end else begin
            oRESET <= 1'b1;
        end
    end
endmodule