module SRAM_Controller (
    // 標準系統訊號
    input  wire        clk,
    input  wire        reset_n,

    // 實體 DE2-115 SRAM 腳位
    output reg  [19:0] SRAM_ADDR,
    inout  wire [15:0] SRAM_DQ,
    output wire        SRAM_CE_N,
    output reg         SRAM_OE_N,
    output reg         SRAM_WE_N,
    output reg         SRAM_UB_N,
    output reg         SRAM_LB_N,

    // Avalon-MM Slave 介面
    input  wire [19:0] avs_s1_address,
    input  wire [15:0] avs_s1_writedata,
    output wire [15:0] avs_s1_readdata,
    input  wire        avs_s1_read,
    input  wire        avs_s1_write,
    input  wire [1:0]  avs_s1_byteenable,
    output wire        avs_s1_waitrequest,

    // 客戶端 2: Raycaster 渲染器
    input  wire        ray_req, 
    input  wire [19:0] ray_addr,
    output wire        ray_grant,

    // 共同讀取輸出匯流排
    output reg  [15:0] sram_rd_data
);

    // 狀態定義
    localparam IDLE       = 3'd0,
               READ       = 3'd1,
               READ_WAIT  = 3'd2,
               WRITE      = 3'd3,
               READ_HOLD  = 3'd4,
               WRITE_HOLD = 3'd5; 

    reg [2:0] state;
    
    // 內部暫存
    reg [19:0] active_addr;
    reg [15:0] active_wr_data;
    reg        active_wr;
    reg [1:0]  active_be;
    reg [1:0]  current_master;

    reg grant;

    // 匯流排控制
    assign avs_s1_waitrequest = nios_req && !(current_master == 2'd1 && grant);
    assign avs_s1_readdata = sram_rd_data;
    assign SRAM_DQ   = (state == WRITE || state == WRITE_HOLD) ? active_wr_data : 16'bz;
    assign SRAM_CE_N = 1'b0; 

    assign ray_grant = current_master==2'd2 && grant;

    wire nios_req = avs_s1_read | avs_s1_write;

    always @(*) begin
        // 預設全拉高安全狀態
        SRAM_ADDR = active_addr;
        SRAM_OE_N = 1'b1;
        SRAM_WE_N = 1'b1;
        SRAM_UB_N = 1'b1;
        SRAM_LB_N = 1'b1;

        case (state)
            READ, READ_WAIT, READ_HOLD: begin
                SRAM_ADDR = active_addr;
                SRAM_OE_N = 1'b0;
                SRAM_WE_N = 1'b1;
                SRAM_UB_N = ~active_be[1];
                SRAM_LB_N = ~active_be[0];
            end
            WRITE, WRITE_HOLD: begin
                SRAM_ADDR = active_addr;
                SRAM_OE_N = 1'b1;
                SRAM_WE_N = 1'b0;
                SRAM_UB_N = ~active_be[1];
                SRAM_LB_N = ~active_be[0];
            end
            default: ;
        endcase
    end

    // 同步狀態機：只管狀態變更與資料鎖存
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state          <= IDLE;
            grant          <= 1'b0;
            sram_rd_data   <= 16'd0;
            current_master <= 2'd0;
            active_addr    <= 20'd0;
            active_wr_data <= 16'd0;
            active_be      <= 2'b00;
        end else begin
            grant <= 1'b0; 

            case (state)
                IDLE: begin
                    if (nios_req && !grant) begin
                        active_addr    <= avs_s1_address;
                        active_wr_data <= avs_s1_writedata;
                        active_be      <= avs_s1_byteenable;
                        current_master <= 2'd1;
                        state          <= avs_s1_write ? WRITE : READ;
                    end else if (ray_req && !grant) begin
                        active_addr    <= ray_addr;
                        active_wr_data <= 16'd0;
                        active_be      <= 2'b11;
                        current_master <= 2'd2;
                        state          <= READ;
                    end
                end

                READ:  state <= READ_WAIT;      // 位子送達
                READ_WAIT: state <= READ_HOLD;  // 等待資料
                READ_HOLD: begin                // 資料收到
                    sram_rd_data <= SRAM_DQ;

                    grant <= 1'b1;
                    state <= IDLE;
                end

                WRITE: state <= WRITE_HOLD;      // 位子、資料送達
                WRITE_HOLD: begin
                    grant <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule