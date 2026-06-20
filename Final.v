module Final (
    input CLOCK_50,

    input[17:0] SW,
    input [3:0] KEY,

    input PS2_CLK,
    input PS2_DAT,
    input PS2_CLK2,
    input PS2_DAT2,

    output SD_CLK, SD_CMD,
    input SD_WP_N,
    inout [3:0] SD_DAT,

    output [8:0]  LEDG,
    output [17:0] LEDR,
    
    output [6:0] HEX0, output [6:0] HEX1, output [6:0] HEX2, output [6:0] HEX3,
    output [6:0] HEX4, output [6:0] HEX5, output [6:0] HEX6, output [6:0] HEX7,
    
    output LCD_ON, LCD_BLON, LCD_RW, LCD_EN, LCD_RS,
    inout [7:0] LCD_DATA,
     
    output [19:0] SRAM_ADDR,
    output SRAM_CE_N, SRAM_OE_N, SRAM_WE_N, SRAM_UB_N, SRAM_LB_N,
    inout [15:0] SRAM_DQ,
    
    output [7:0] VGA_B, output [7:0] VGA_G, output [7:0] VGA_R, 
    output VGA_BLANK_N, VGA_CLK, VGA_HS, VGA_SYNC_N, VGA_VS,

    input  AUD_BCLK,
    input  AUD_DACLRCK,
    output AUD_DACDAT,
    output AUD_XCKs,

    inout I2C_SCLK, I2C_SDAT,
    inout EEP_I2C_SCLK, EEP_I2C_SDAT
);
    wire rst_n_r0;
    reset_delay u_r0(.iCLK(CLOCK_50), .rst(1'b1), .oRESET(rst_n_r0));
    wire rst_n = rst_n_r0 & locked & KEY[3];
    
    // ====================
    // CLK GEN
    // ====================
    wire CLK_100MHz;
    wire CLK_25MHz;
    wire CLK_18_432MHz;
    wire locked;

    CLOCK_DIV u_clk_div(
        .areset(~rst_n_r0),
        .inclk0(CLOCK_50),
        .c0(CLK_100MHz),
        .c1(CLK_25MHz),
        .c2(CLK_18_432MHz),
        .locked(locked)
    );

    wire CLK_20Hz;
    pulse_gen #(.DIV_VALUE(5_000_000)) u_clk_20hz_gen(.clk(CLK_100MHz), .rst_n(rst_n), .tick(CLK_20Hz));

    wire CLK_1KHz;
    pulse_gen #(.DIV_VALUE(100_000)) u_clk_1khz_gen(.clk(CLK_100MHz), .rst_n(rst_n), .tick(CLK_1KHz));

    wire CLK_1Hz;
    pulse_gen #(.DIV_VALUE(100_000_000)) u_clk_1hz_gen(.clk(CLK_100MHz), .rst_n(rst_n), .tick(CLK_1Hz));

    wire [31:0] millis;
    Timer u_millis(.clk(CLK_100MHz), .tick(CLK_1KHz), .rst_n(rst_n), .timer(millis));

    // ====================
    // LCD
    // ====================

    assign LCD_ON   = 1'b1;
    assign LCD_BLON = 1'b1;
    wire [255:0] lcd_msg;

    lcd_messages u_lcd_msg(
        .iMSG(lcd_msg),

        .iCLK(CLOCK_50),
        .iRST_N(rst_n),
        .LCD_DATA(LCD_DATA),
        .LCD_RW(LCD_RW),
        .LCD_EN(LCD_EN),
        .LCD_RS(LCD_RS)
    );
    
    // ====================
    // HEX
    // ====================
    
    wire [31:0] seg_value;
    wire [7:0] seg_enable;
    wire [7:0] seg_neg;

    SEG_messages u_seg(
        seg_value, seg_enable, seg_neg,
        HEX0, HEX1, HEX2, HEX3,
        HEX4, HEX5, HEX6, HEX7
    );

    // ====================
    // PS/2 Keyboard
    // ====================

    wire ps2_k_pressed, ps2_k_released;
    wire [7:0] ps2_k_data;
    wire ps_2_extended, ps2_k_valid;

    PS2_Driver u_ps2_key(
        .clk(CLOCK_50),
        .rst_n(rst_n),

        .PS_CLK(PS2_CLK),
        .PS_DAT(PS2_DAT),

        .pressed(ps2_k_pressed),
        .released(ps2_k_released),
        .extended(ps_2_extended),
        .data(ps2_k_data),
        .valid(ps2_k_valid)
    );

    wire [9:0]  move_ctrl;
    wire [1:0]  action_keys;
    wire [7:0]  block_select;

    wire [63:0] pressed_key;

    wire [7:0]  state_key;

    PS2_Messages u_ps2_key_msg(
        .clk(CLOCK_50),
        .rst_n(rst_n),

        .pressed(ps2_k_pressed),
        .released(ps2_k_released),
        .extended(ps_2_extended),
        .data(ps2_k_data),
        .valid(ps2_k_valid),

        .move_ctrl(move_ctrl),
        .action_keys(action_keys),
        .block_select(block_select),
        .pressed_key(pressed_key),
        .state_key(state_key)
    );
    
    // ====================
    // VGA
    // ====================

    VGA_controller u_vga(
        .clk(CLK_100MHz),
        .vga_clk(CLK_25MHz),
        .rst(~rst_n),

        .layer_3D_index(~vram_index),
        .layer_3D_rd_addr(vram_rd_addr),
        .layer_3D_rd_data(vram_rd_data),
        
        .layer_text_rd_addr(vram_text_addr),
        .layer_text_rd_data(vram_text_data),
        .layer_font_rd_addr(font_rom_addr),
        .layer_font_rd_data(font_rom_data),

        .VGA_B(VGA_B),
        .VGA_G(VGA_G),
        .VGA_R(VGA_R),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_CLK(VGA_CLK),
        .VGA_HS(VGA_HS),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_VS(VGA_VS)
    );

    // ====================
    // RAM (VRAM)
    // ====================

    wire [15:0]     vram_wr_addr;
    wire [7:0]      vram_wr_data;
    wire            vram_wr_en;
    
    wire [15:0]     vram_rd_addr;
    wire [7:0]      vram_rd_data;

    wire [15:0]     vram_addr_nios;
    wire [7:0]      vram_data_nios=vram_rd_data;

    wire [15:0]     vram_output_addr=(1'b0)?vram_addr_nios:vram_rd_addr;

    M9K_RAM #(.RAM_SIZE(160*120*2)) u_vram(
        .clk(CLK_100MHz),
        .wr_data(vram_wr_data),
        .wr_addr(vram_wr_addr),
        .wr_en(vram_wr_en),

        .rd_addr(vram_output_addr),
        .rd_data(vram_rd_data)
    );

    // ====================
    // Audio
    // ====================

    wire signed [15:0] sfx_wave_l;
    wire signed [15:0] sfx_wave_r;
    wire               audio_48khz_tick;

    assign AUD_XCKs = CLK_18_432MHz;

    Audio_Controller u_audio_ctrl (
        .clk             (CLK_100MHz),
        .rst_n           (rst_n),
        
        .player_wave_l   (sfx_wave_l),
        .player_wave_r   (sfx_wave_r),
        .audio_sample_clk(audio_48khz_tick),
        
        .AUD_BCLK        (AUD_BCLK),
        .AUD_DACLRCK     (AUD_DACLRCK),
        .AUD_DACDAT      (AUD_DACDAT),
        .I2C_SCLK        (I2C_SCLK),
        .I2C_SDAT        (I2C_SDAT),

        .i2c_error       ()
    );

    wire [15:0] bgm_rom_addr;
    wire [63:0] bgm_rom_data;
    wire [7:0]  bgm_ctrl, bgm_state;
    wire [2:0]  bmg_vol;
    wire [5:0]  playing_song;
    Audio_Player u_audio_player(
        .audio_sample_clk (audio_48khz_tick),
        .rst_n            (rst_n),

        .master_vol       (bmg_vol),

        .play             (bgm_ctrl[7]),
        .stop             (bgm_ctrl[6]),
        .song_sel         (bgm_ctrl[5:0]),
        .playing          (bgm_state[0]),
        .playing_song     (playing_song),

        // .master_vol       (SW[17:15]),

        // .play             (~KEY[0]),
        // .stop             (~KEY[1]),
        // .song_sel         (SW[1:0]),
        // .playing          (LEDG[8]),
        
        .player_wave_l    (sfx_wave_l),
        .player_wave_r    (sfx_wave_r),

        .rom_addr         (bgm_rom_addr),
        .rom_data         (bgm_rom_data)
    );

    // ====================
    // CPU
    // ====================

    wire        sram_ray_req;
    wire [19:0] sram_ray_addr;      
    wire        sram_ray_grant;
    
    wire [15:0] sram_rd_data;

    wire [7:0] progress;

    wire [8:0] vga_clear;

    wire [31:0] play_X, play_Y, play_Z, play_view_Y;
    wire [31:0] dirX0, dirY0, dirZ0;
    wire [31:0] dirXdx, dirYdx, dirZdx;
    wire [31:0] dirXdy, dirYdy, dirZdy;

    wire [15:0] sky_line;
    wire view_under_water;

    wire faceBlock;
    wire [15:0] faceBlock_x, faceBlock_y, faceBlock_z;

    wire [11:0] inv_delta_rom_addr;
    wire [31:0] inv_delta_rom_data;

    wire [8:0]  cos_table_rom_addr;
    wire [15:0] cos_table_rom_data;
    
    wire [6:0]  block_info_rom_addr;
    wire [7:0]  block_info_rom_data;
    
    wire [6:0]  vram_text_addr;
    wire [7:0]  vram_text_data;

    wire [6:0]  font_rom_addr;
    wire [63:0] font_rom_data;

    wire [7:0]  texture_rom_1_addr;
    wire [7:0]  texture_rom_1_data;
    wire [7:0]  texture_rom_2_addr;
    wire [7:0]  texture_rom_2_data;

    wire [7:0]  mode_state;

    wire sd_mount=1'b1;

    wire SD_SPI_CS;
    wire SD_SPI_SCLK;
    wire SD_SPI_MOSI;
    wire SD_SPI_MISO;

    assign SD_CLK = SD_SPI_SCLK;
    assign SD_DAT[3] = SD_SPI_CS;
    assign SD_CMD = SD_SPI_MOSI;
    assign SD_SPI_MISO = SD_DAT[0];
    assign SD_DAT[0] = 1'bz;
    assign SD_DAT[1] = 1'bz;
    assign SD_DAT[2] = 1'bz;

    wire [31:0] seed;

    NIOS u_cpu (
        .clk_clk                       (CLK_100MHz),
        .reset_reset_n                 (rst_n),

        .tick_export                   (CLK_20Hz),
        .millis_export                 (millis),

        .sram_sram_pin_ADDR            (SRAM_ADDR),
        .sram_sram_pin_DQ              (SRAM_DQ),
        .sram_sram_pin_CE_N            (SRAM_CE_N),
        .sram_sram_pin_OE_N            (SRAM_OE_N),
        .sram_sram_pin_WE_N            (SRAM_WE_N),
        .sram_sram_pin_UB_N            (SRAM_UB_N),
        .sram_sram_pin_LB_N            (SRAM_LB_N),

        .sd_spi_MISO                   (SD_SPI_MISO),
        .sd_spi_MOSI                   (SD_SPI_MOSI),
        .sd_spi_SCLK                   (SD_SPI_SCLK),
        .sd_spi_SS_n                   (SD_SPI_CS),

        .sram_verilog_pin_ray_req      (sram_ray_req),
        .sram_verilog_pin_ray_addr     (sram_ray_addr),
        .sram_verilog_pin_ray_grant    (sram_ray_grant),
        .sram_verilog_pin_sram_rd_data (sram_rd_data),

        .progress_export               (progress),

        .bridge_out_px                 (play_X),
        .bridge_out_py                 (play_Y),
        .bridge_out_pvy                (play_view_Y),
        .bridge_out_pz                 (play_Z),
        .bridge_dirX0                  (dirX0),
        .bridge_dirY0                  (dirY0),
        .bridge_dirZ0                  (dirZ0),
        .bridge_dirXdx                 (dirXdx),
        .bridge_dirYdx                 (dirYdx),
        .bridge_dirZdx                 (dirZdx),
        .bridge_dirXdy                 (dirXdy),
        .bridge_dirYdy                 (dirYdy),
        .bridge_dirZdy                 (dirZdy),
        .bridge_skyLine                (sky_line),
        .bridge_underWater             (view_under_water),
        .bridge_faceBlock              (faceBlock),
        .bridge_faceBlock_x            (faceBlock_x),
        .bridge_faceBlock_y            (faceBlock_y),
        .bridge_faceBlock_z            (faceBlock_z),

        .inv_delta_rom_address         (inv_delta_rom_addr),
        .inv_delta_rom_chipselect      (1'b1),
        .inv_delta_rom_clken           (1'b1),
        .inv_delta_rom_write           (1'b0),
        .inv_delta_rom_readdata        (inv_delta_rom_data),
        .inv_delta_rom_writedata       (32'd0),
        .inv_delta_rom_byteenable      (4'b1111),

        .cos_table_rom_address         (cos_table_rom_addr),
        .cos_table_rom_chipselect      (1'b1),
        .cos_table_rom_clken           (1'b1),
        .cos_table_rom_write           (1'b0),
        .cos_table_rom_readdata        (cos_table_rom_data),
        .cos_table_rom_writedata       (32'd0),
        .cos_table_rom_byteenable      (4'b1111),

        .block_info_rom_address        (block_info_rom_addr),
        .block_info_rom_chipselect     (1'b1),
        .block_info_rom_clken          (1'b1),
        .block_info_rom_write          (1'b0),
        .block_info_rom_readdata       (block_info_rom_data),
        .block_info_rom_writedata      (1'b1),

        .texture_rom_1_address         (texture_rom_1_addr),
        .texture_rom_1_chipselect      (1'b1),
        .texture_rom_1_clken           (1'b1),
        .texture_rom_1_write           (1'b0),
        .texture_rom_1_readdata        (texture_rom_1_data),
        .texture_rom_1_writedata       (1'b1),

        .texture_rom_2_address         (texture_rom_2_addr),
        .texture_rom_2_chipselect      (1'b1),
        .texture_rom_2_clken           (1'b1),
        .texture_rom_2_write           (1'b0),
        .texture_rom_2_readdata        (texture_rom_2_data),
        .texture_rom_2_writedata       (1'b1),

        .vga_text_ram_address          (vram_text_addr),
        .vga_text_ram_chipselect       (1'b1),
        .vga_text_ram_clken            (1'b1),
        .vga_text_ram_write            (1'b0),
        .vga_text_ram_readdata         (vram_text_data),
        .vga_text_ram_writedata        (1'b1),

        .font_rom_address              (font_rom_addr),
        .font_rom_chipselect           (1'b1),
        .font_rom_clken                (1'b1),
        .font_rom_write                (1'b0),
        .font_rom_readdata             (font_rom_data),
        .font_rom_writedata            (1'b1),

        .bgm_rom_address               (bgm_rom_addr),
        .bgm_rom_chipselect            (1'b1),
        .bgm_rom_clken                 (1'b1),
        .bgm_rom_write                 (1'b0),
        .bgm_rom_readdata              (bgm_rom_data),
        .bgm_rom_writedata             (1'b1),

        .vram_addr_export              (vram_addr_nios),
        .vram_data_export              (vram_data_nios),
        
        .move_ctrl_export              (move_ctrl),
        .action_keys_export            (action_keys),
        .block_select_export           (block_select),

        .key_1_export                  (pressed_key[31:0]),
        .key_2_export                  (pressed_key[63:32]),
        .state_key_export              (state_key),

        .vga_clear_export              (vga_clear),

        .mode_export                   (mode_state),

        .sd_mount_export               (sd_mount),

        .seed_export                   (seed),

        .bgm_ctrl_export               (bgm_ctrl),
        .bgm_state_export              (bgm_state)
    );
    
    // ====================
    // RAY
    // ====================

    wire       vram_index;
    wire [7:0] fps;

    Ray_Module u_ray(
        .clk(CLK_100MHz),
        .rst(rst_n),

        .clear(vga_clear[8]),
        .clear_color(vga_clear[7:0]),

        .vram_index(vram_index),

        .vram_wr_en(vram_wr_en),
        .vram_wr_addr(vram_wr_addr),
        .vram_wr_data(vram_wr_data),
        
        .sram_req(sram_ray_req),
        .sram_addr(sram_ray_addr),
        .sram_grant(sram_ray_grant),
        .sram_rd_data(sram_rd_data),

        .inv_delta_addr(inv_delta_rom_addr),
        .inv_delta_data(inv_delta_rom_data),
        
        .block_info_addr(block_info_rom_addr),
        .block_info_data(block_info_rom_data),
        
        .texture_addr(texture_rom_1_addr),
        .texture_data(texture_rom_1_data),

        .px(play_X),
        .py(play_view_Y),
        .pz(play_Z),
        .dirX0(dirX0),
        .dirY0(dirY0),
        .dirZ0(dirZ0),
        .dirXdx(dirXdx),
        .dirYdx(dirYdx),
        .dirZdx(dirZdx),
        .dirXdy(dirXdy),
        .dirYdy(dirYdy),
        .dirZdy(dirZdy),

        .sky_line(sky_line),
        .through_block(view_under_water),
        
        .faceBlock(faceBlock),
        .faceBlock_x(faceBlock_x),
        .faceBlock_y(faceBlock_y),
        .faceBlock_z(faceBlock_z),

        .fps_fresh(CLK_1Hz),
        .fps(fps)
    );

    // ====================
    // IO Controller
    // ====================

    IO_Cotroller u_io_ctrl(
        .clk(CLK_100MHz),
        .rst_n(rst_n),

        .SW(SW),
        .KEY(KEY[2:0]),

        .mode(mode_state),
        .progress(progress),
        .fps(fps),

        .seed(seed),

        .px(play_X[23:16]), .py(play_Y[23:16]), .pz(play_Z[23:16]),
        .block_select(block_select),

        .lcd_msg(lcd_msg),
        .LEDR(LEDR),
        .LEDG(LEDG[7:0]),

        .seg_value(seg_value),
        .seg_enable(seg_enable),
        .seg_neg(seg_neg),

        .song_sel(playing_song),
        .bmg_vol(bmg_vol),

        .eep_write        (eep_cmd_write),
        .eep_read         (eep_cmd_read),
        .eep_addr         (eep_mem_addr),
        .eep_writedata    (eep_write_data),
        .eep_readdata     (eep_read_data),
        .eep_datavalid    (eep_data_valid),
        .eep_ready        (eep_ready)
    );

    wire        eep_cmd_write;
    wire        eep_cmd_read;
    wire [11:0] eep_mem_addr;
    wire [31:0] eep_write_data;
    wire [31:0] eep_read_data;
    wire        eep_data_valid;
    wire        eep_ready;
    EEPROM_Manager #(.CLK_FREQ(100_000_000)) u_eeprom(
        .clk(CLK_100MHz),
        .rst_n(rst_n),

        .cmd_write(eep_cmd_write),
        .cmd_read(eep_cmd_read),
        .mem_addr(eep_mem_addr),
        .write_data(eep_write_data),
        .read_data(eep_read_data),
        .data_valid(eep_data_valid),
        .ready(eep_ready),

        .SCLK(EEP_I2C_SCLK),
        .SDAT(EEP_I2C_SDAT)
    );

endmodule