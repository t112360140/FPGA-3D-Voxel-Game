// 通用脈衝產生器 (Pulse Generator)

module pulse_gen #(
    parameter DIV_VALUE = 50_000_000
)(
    input  clk,
    input  rst_n,      // 建議加入 reset
    output reg tick    // 輸出一個週期的高電位脈衝
);
    reg [26:0] count=0;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            tick <= 0;
        end else if (count >= DIV_VALUE - 1) begin
            count <= 0;
            tick <= 1;
        end else begin
            count <= count + 1;
            tick <= 0;
        end
    end
endmodule