module VGA_controller(
    input wire         clk,          // 系統 50MHz 時脈
    input wire         vga_clk,      // 來自 square_gen 的實體 25MHz 方波
    input wire         rst,          // 高電平有效的重設

    input wire         layer_3D_index,   // 雙緩衝區選擇
    output wire [15:0] layer_3D_rd_addr, // 輸出給 M9K 的讀取位址
    input  wire [7:0]  layer_3D_rd_data, // 來自 M9K 的 8-bit 顏色資料 (RRRGGGBB)

    output wire [6:0]  layer_text_rd_addr,
    input  wire [7:0]  layer_text_rd_data,
    output wire [6:0]  layer_font_rd_addr,
    input  wire [63:0] layer_font_rd_data,

    // DE2-115 實體 VGA 腳位
    output reg  [7:0]  VGA_B,
    output reg  [7:0]  VGA_G,
    output reg  [7:0]  VGA_R, 
    output reg         VGA_BLANK_N,  
    output wire        VGA_CLK,
    output reg         VGA_HS,
    output wire        VGA_SYNC_N,
    output reg         VGA_VS
);
    localparam  VGA_H = 16'd120,
                VGA_W = 16'd160;
    
    // 640x480 @ 60Hz 標準時序參數
    localparam H_ACTIVE = 11'd640, H_FRONT = 11'd16, H_SYNC = 11'd96, H_TOTAL = 11'd800;
    localparam V_ACTIVE = 11'd480, V_FRONT = 11'd10, V_SYNC = 11'd2,  V_TOTAL = 11'd525;

    reg [10:0] h_count;
    reg [10:0] v_count;

    reg sync_layer_3D_index;

    // 實體控制引腳綁定
    // 【進階技巧】將輸出給螢幕的時脈反轉，確保外部 DAC 晶片在資料最穩定的 mid-cycle 進行採樣
    assign VGA_CLK    = ~vga_clk; 
    assign VGA_SYNC_N = 1'b0;

    // 水平與垂直像素計數器
    always @(posedge vga_clk or posedge rst) begin
        if (rst) begin
            h_count <= 11'd0;
            v_count <= 11'd0;
            sync_layer_3D_index <= layer_3D_index;
        end else begin
            if (h_count < H_TOTAL - 1) begin
                h_count <= h_count + 1'b1;
            end else begin
                h_count <= 11'd0;
                if (v_count < V_TOTAL - 1) begin
                    v_count <= v_count + 1'b1;
                end else begin
                    v_count <= 11'd0;
                    sync_layer_3D_index <= layer_3D_index;
                end
            end
        end
    end

    // 宣告一個組合邏輯的即時顯示區域訊號
    wire blank_n_comb = (h_count < H_ACTIVE) && (v_count < V_ACTIVE);

    // 160x120 放大四倍定址邏輯
    wire [7:0] layer_3D_x_raw = h_count[9:2];
    wire [7:0] layer_3D_x = (layer_3D_x_raw >= VGA_W) ? VGA_W-1 : layer_3D_x_raw;
    wire [6:0] layer_3D_y = v_count[9:2];
    assign layer_3D_rd_addr = (sync_layer_3D_index ? (VGA_H*VGA_W) : 16'd0) + (layer_3D_y * VGA_W) + layer_3D_x;
    

    wire [7:0] layer_text_x = h_count[9:3];
    wire [6:0] layer_text_y = v_count[9:3];
    wire text_active = (layer_text_x >= 7'd2 && layer_text_x < 7'd80) && (layer_text_y >= 6'd2 && layer_text_y < 6'd58);

    wire [6:0] active_x = layer_text_x - 7'd2;
    wire [5:0] active_y = layer_text_y - 6'd2;

    wire [3:0] char_x = active_x[6:3];
    wire [2:0] char_y = active_y[5:3];
    wire [2:0] font_x = active_x[2:0];
    wire [2:0] font_y = active_y[2:0];

    assign layer_text_rd_addr = (char_y << 3) + char_y + char_y + char_x;        // y*10+x
    assign layer_font_rd_addr = (layer_text_rd_data - " ");


    reg        blank_n_delay_1, blank_n_delay_2;
    reg        hs_delay_1, hs_delay_2;
    reg        vs_delay_1, vs_delay_2;
    reg [7:0]  layer_3D_rd_data_delay_1;

    reg text_active_d1, text_active_d2;
    reg [2:0] font_x_d1, font_x_d2;
    reg [2:0] font_y_d1, font_y_d2;

    wire text_pixel = layer_font_rd_data[{~font_y_d1, ~font_x_d1}];

    // 同步控制訊號
    always @(posedge vga_clk or posedge rst) begin
        if (rst) begin
            blank_n_delay_1 <= 1'b0; blank_n_delay_2 <= 1'b0;
            hs_delay_1 <= 1'b1; hs_delay_2 <= 1'b1;
            vs_delay_1 <= 1'b1; vs_delay_2 <= 1'b1;
            layer_3D_rd_data_delay_1 <= 8'd0;
            
            text_active_d1 <= 1'b0; text_active_d2 <= 1'b0;
            font_x_d1 <= 3'd0; font_x_d2 <= 3'd0;
            font_y_d1 <= 3'd0; font_y_d2 <= 3'd0;
        end else begin
            hs_delay_1 <= ~((h_count >= H_ACTIVE + H_FRONT) && (h_count < H_ACTIVE + H_FRONT + H_SYNC));
            hs_delay_2 <= hs_delay_1;
            vs_delay_1 <= ~((v_count >= V_ACTIVE + V_FRONT) && (v_count < V_ACTIVE + V_FRONT + V_SYNC));
            vs_delay_2 <= vs_delay_1;
            blank_n_delay_1 <= blank_n_comb; 
            blank_n_delay_2 <= blank_n_delay_1;
            
            layer_3D_rd_data_delay_1 <= layer_3D_rd_data;

            // Pipeline 文字座標
            text_active_d1 <= text_active; 
            text_active_d2 <= text_active_d1;
            font_x_d1 <= font_x; 
            font_x_d2 <= font_x_d1;
            font_y_d1 <= font_y; 
            font_y_d2 <= font_y_d1;
        end
    end

    always @(posedge vga_clk) begin
        VGA_HS      <= hs_delay_2;
        VGA_VS      <= vs_delay_2;
        VGA_BLANK_N <= blank_n_delay_2;
    end

    always @(posedge vga_clk) begin
        if (blank_n_delay_2) begin
            if(text_active_d1 && text_pixel) begin
                VGA_R <= 8'hFF;
                VGA_G <= 8'hFF;
                VGA_B <= 8'hFF;
            end else begin
                // 使用延遲過一拍的 3D 資料
                VGA_R <= {layer_3D_rd_data_delay_1[7:5], 5'b0};
                VGA_G <= {layer_3D_rd_data_delay_1[4:2], 5'b0};
                VGA_B <= {layer_3D_rd_data_delay_1[1:0], 6'b0};
            end 
        end else begin
            VGA_R <= 8'd0;
            VGA_G <= 8'd0;
            VGA_B <= 8'd0;
        end
    end

endmodule