module Audio_Controller (
    input  wire        clk,
    input  wire        rst_n,

    // 來自 Audio_Player 的並列 16-bit 振幅資料
    input  wire signed [15:0] player_wave_l,
    input  wire signed [15:0] player_wave_r,
    
    output wire        audio_sample_clk,

    input  wire        AUD_BCLK,         
    input  wire        AUD_DACLRCK,      
    output reg         AUD_DACDAT,       

    inout  wire        I2C_SCLK,
    inout  wire        I2C_SDAT,

    output reg         i2c_error
);

    // ============================================================================
    // 1. I2C 初始化狀態機區塊 (運作於 100MHz)
    // ============================================================================
    reg [3:0]  init_idx;
    reg [2:0]  i2c_state;  // 新增狀態，改為 3-bit               
    reg        i2c_req;
    wire       i2c_busy;
    wire       i2c_nack;
    
    reg [7:0]  ctrl_byte;                
    reg [7:0]  data_byte;                
    reg [15:0] delay_cnt;  // 晶片消化延遲計數器

    localparam ST_IDLE  = 3'd0,
               ST_START = 3'd1,
               ST_WAIT  = 3'd2,
               ST_DELAY = 3'd3, // 新增：等待晶片消化設定
               ST_DONE  = 3'd4;

    always @(*) begin
        case(init_idx)
            4'd0:  {ctrl_byte, data_byte} = {8'h1E, 8'h00}; // Reg 15: Reset
            4'd1:  {ctrl_byte, data_byte} = {8'h12, 8'h00}; // Reg 09: Inactive Interface
            4'd2:  {ctrl_byte, data_byte} = {8'h00, 8'h17}; // Reg 00: L Line In
            4'd3:  {ctrl_byte, data_byte} = {8'h02, 8'h17}; // Reg 01: R Line In
            4'd4:  {ctrl_byte, data_byte} = {8'h04, 8'h79}; // Reg 02: L HP Vol (修正：0dB 正常音量)
            4'd5:  {ctrl_byte, data_byte} = {8'h06, 8'h79}; // Reg 03: R HP Vol (修正：0dB 正常音量)
            4'd6:  {ctrl_byte, data_byte} = {8'h08, 8'h12}; // Reg 04: Analog Path (開啟 DAC，關閉 Mic)
            4'd7:  {ctrl_byte, data_byte} = {8'h0A, 8'h00}; // Reg 05: Digital Path 
            4'd8:  {ctrl_byte, data_byte} = {8'h0C, 8'h00}; // Reg 06: Power Down 
            4'd9:  {ctrl_byte, data_byte} = {8'h0E, 8'h42}; // Reg 07: 16-bit I2S Master
            4'd10: {ctrl_byte, data_byte} = {8'h10, 8'h02}; // Reg 08: Sampling (18.432M -> 48kHz)
            4'd11: {ctrl_byte, data_byte} = {8'h12, 8'h01}; // Reg 09: Active Interface!
            default: {ctrl_byte, data_byte} = {8'h00, 8'h00};
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i2c_state <= ST_IDLE;
            init_idx  <= 4'd0;
            i2c_req   <= 1'b0;
            delay_cnt <= 16'd0;
        end else begin
            case (i2c_state)
                ST_IDLE: begin
                    if (init_idx < 4'd12) i2c_state <= ST_START;
                    else                  i2c_state <= ST_DONE; 
                end
                
                ST_START: begin
                    if (!i2c_busy) begin
                        i2c_req   <= 1'b1;     
                        i2c_state <= ST_WAIT;
                    end
                end
                
                ST_WAIT: begin
                    if (i2c_busy) i2c_req <= 1'b0;       
                    
                    if (!i2c_busy && !i2c_req) begin
                        delay_cnt <= 16'd0;
                        i2c_state <= ST_DELAY;
                    end
                end

                ST_DELAY: begin
                    if (delay_cnt == 16'hFFFF) begin
                        init_idx  <= init_idx + 1'b1; 
                        i2c_state <= ST_IDLE;
                    end else begin
                        delay_cnt <= delay_cnt + 1'b1;
                    end
                end
                
                ST_DONE: i2c_req <= 1'b0;           
                default: i2c_state <= ST_IDLE;
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) i2c_error <= 1'b0;
        else if (i2c_nack) i2c_error <= 1'b1;
    end

    i2c_master u_i2c (
        .i_clk(clk),
        .reset_n(rst_n),
        .i_addr_w_rw({7'h1A, 1'b0}),          
        .i_sub_addr({8'h00, ctrl_byte}),      
        .i_sub_len(1'b0),                     
        .i_byte_len(24'd1),                   
        .i_data_write(data_byte),             
        .req_trans(i2c_req),                  
        .data_out(),                          
        .valid_out(),                         
        .scl_o(I2C_SCLK),                     
        .sda_o(I2C_SDAT),                     
        .req_data_chunk(),                    
        .busy(i2c_busy),                      
        .nack(i2c_nack)                               
    );

    // ============================================================================
    // 2. I2S 序列化發送器區塊 
    // ============================================================================
    reg [31:0] shift_reg;
    reg        last_lrck;

    assign audio_sample_clk = AUD_DACLRCK;

    always @(negedge AUD_BCLK or negedge rst_n) begin
        if (!rst_n) begin
            AUD_DACDAT <= 1'b0;
            shift_reg  <= 32'd0;
            last_lrck  <= 1'b0;
        end else begin
            last_lrck <= AUD_DACLRCK;
            
            if (AUD_DACLRCK != last_lrck) begin
                AUD_DACDAT <= AUD_DACLRCK ? player_wave_r[15] : player_wave_l[15];
                shift_reg  <= AUD_DACLRCK ? {player_wave_r[14:0], 17'd0} : {player_wave_l[14:0], 17'd0};
            end else begin
                AUD_DACDAT <= shift_reg[31];
                shift_reg  <= {shift_reg[30:0], 1'b0};
            end
        end
    end
endmodule