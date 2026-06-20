module M9K_RAM #(
    parameter RAM_SIZE = 2**16
)(
    input clk,
    // 寫入埠
    input [7:0] wr_data,
    input [15:0] wr_addr,
    input wr_en,

    // 讀取埠
    input [15:0] rd_addr,
    output reg [7:0] rd_data
);
    // 宣告記憶體陣列
    reg [7:0] mem [0:RAM_SIZE-1];

    // 同步讀寫邏輯
    always @(posedge clk) begin
        if (wr_en)
            mem[wr_addr] <= wr_data;
        rd_data <= mem[rd_addr];
    end
endmodule