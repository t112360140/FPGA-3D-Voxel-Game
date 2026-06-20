module lfsr_gen (
    input  wire        clk,     // 時脈
    input  wire        rst_n,   // 負觸發重設
    input  wire        en,      // 致能訊號（呼叫一次 rand() 的意思）
    output wire [31:0] rand_out // 立即回傳當前數值
);

    reg [31:0] state;

    // 立即回傳當前暫存器的值 (輸出目前的狀態)
    assign rand_out = state;

    // 在時脈邊緣更新下一個狀態 (儲存起來)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 32'hAC0140EC;
        end else if (en) begin
            // Galois LFSR 邏輯
            if (state[0]) state <= (state >> 1) ^ 32'h80000057;
            else state <= (state >> 1);
        end
    end

endmodule