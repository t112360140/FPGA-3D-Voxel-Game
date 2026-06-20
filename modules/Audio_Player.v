module Audio_Player (
    input  wire        audio_sample_clk, 
    input  wire        rst_n,

    input  wire [2:0]  master_vol,

    input  wire        play,
    input  wire        stop,
    input  wire [1:0]  song_sel,
    output reg         playing,
    output wire [1:0]  playing_song,

    output signed [15:0] player_wave_l,
    output signed [15:0] player_wave_r,

    output wire [15:0] rom_addr,
    input  wire [63:0] rom_data
);

    reg [5:0]  clk_to_1ms_cnt;
    wire       tick_1ms = (clk_to_1ms_cnt == 6'd47); 

    reg [2:0]  state;
    localparam ST_IDLE  = 3'd0,
               ST_FETCH = 3'd1,  
               ST_WAIT  = 3'd2,  
               ST_LOAD  = 3'd3,  
               ST_PLAY  = 3'd4;
    
    reg [8:0] local_addr;   // one song 512 words (9bit addr)
    reg [1:0] song_sel_reg;
    assign rom_addr = {song_sel_reg, local_addr};
    assign playing_song = song_sel_reg;

    reg [14:0] duration;
    reg [6:0]  n1, n2, n3, n4;

    wire [15:0] freq1 = note_to_step(n1);
    wire [15:0] freq2 = note_to_step(n2);
    wire [15:0] freq3 = note_to_step(n3);
    wire [15:0] freq4 = note_to_step(n4);
    reg  [15:0] phase1, phase2, phase3, phase4;

    reg [6:0] prev_n1, prev_n2, prev_n3, prev_n4;
    reg ch1_on, ch2_on, ch3_on, ch4_on;
    reg [23:0] env1, env2, env3, env4;

    wire signed [15:0] player_wave;
    assign player_wave_r = player_wave;
    assign player_wave_l = player_wave;

    wire signed [15:0] amp1 = {3'b000, env1[23:11]};
    wire signed [15:0] amp2 = {3'b000, env2[23:11]};
    wire signed [15:0] amp3 = {3'b000, env3[23:11]};
    wire signed [15:0] amp4 = {3'b000, env4[23:11]};

    wire signed [15:0] wave1 = (phase1[15]) ? amp1 : -amp1;
    wire signed [15:0] wave2 = (phase2[15]) ? amp2 : -amp2;
    wire signed [15:0] wave3 = (phase3[15]) ? amp3 : -amp3;
    wire signed [15:0] wave4 = (phase4[15]) ? amp4 : -amp4;

    wire signed [15:0] next_wave = wave1 + wave2 + wave3 + wave4;

    reg signed [15:0] filtered_wave;
    always @(posedge audio_sample_clk) begin
        if (!rst_n) begin
            filtered_wave <= 0;
        end else begin
            // 簡單的一階低通濾波器： 舊值 + (新值 - 舊值) * 衰減係數
            // >>> 2 代表切斷頻率較高 (聲音較亮)； >>> 3 代表切斷頻率較低 (聲音較悶/柔和)
            filtered_wave <= filtered_wave + ((next_wave - filtered_wave) >>> 3);
        end
    end

    wire signed [23:0] louder_wave = ($signed(filtered_wave) <<< 2) >>> (3'd7 - master_vol); 
    reg signed [15:0] safe_wave;
    always @(*) begin
        if (louder_wave > 24'sd32767) begin
            safe_wave = 16'sd32767;
        end else if (louder_wave < -24'sd32768) begin
            safe_wave = -16'sd32768;
        end else begin
            safe_wave = louder_wave[15:0];
        end
    end
    assign player_wave = (playing) ? safe_wave : 16'sd0;

    always @(posedge audio_sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            local_addr     <= 0;
            song_sel_reg   <= 0;
            state          <= ST_IDLE;
            clk_to_1ms_cnt <= 0;
            phase1 <= 0; phase2 <= 0; phase3 <= 0; phase4 <= 0;
            prev_n1 <= 0; prev_n2 <= 0; prev_n3 <= 0; prev_n4 <= 0;
            ch1_on <= 0; ch2_on <= 0; ch3_on <= 0; ch4_on <= 0;
            env1 <= 0; env2 <= 0; env3 <= 0; env4 <= 0;
            playing <= 0;
        end else begin
            if (stop) begin
                state      <= ST_IDLE;
                local_addr <= 0;
                song_sel_reg <= 0;
                env1 <= 0; env2 <= 0; env3 <= 0; env4 <= 0;
                ch1_on <= 0; ch2_on <= 0; ch3_on <= 0; ch4_on <= 0;
                playing <= 0;
            end else begin
                if (state != ST_IDLE) begin
                    if (tick_1ms) clk_to_1ms_cnt <= 0;
                    else          clk_to_1ms_cnt <= clk_to_1ms_cnt + 1'b1;
                end else begin
                    clk_to_1ms_cnt <= 0;
                end

                case (state)
                    ST_IDLE: begin
                        playing <= 0;
                        if (play) begin
                            state <= ST_FETCH;

                            playing <= 1;
                            song_sel_reg <= song_sel;
                        end
                    end

                    ST_FETCH: state <= ST_WAIT;
                    ST_WAIT:  state <= ST_LOAD;
                    ST_LOAD: begin
                        if (rom_data[63] == 1'b0) begin
                            local_addr <= 0;
                            song_sel_reg <= 0;
                            state    <= ST_IDLE;
                        end else begin
                            duration <= rom_data[62:48];
                            
                            // --- Channel 1 ---
                            if (rom_data[47:41] != 0) begin
                                n1 <= rom_data[47:41]; 
                                ch1_on <= 1'b1;        
                                if (rom_data[47:41] != prev_n1) env1 <= {rom_data[40:36], 19'd0}; 
                            end else ch1_on <= 1'b0;        
                            prev_n1 <= rom_data[47:41];

                            // --- Channel 2 ---
                            if (rom_data[35:29] != 0) begin
                                n2 <= rom_data[35:29];
                                ch2_on <= 1'b1;
                                if (rom_data[35:29] != prev_n2) env2 <= {rom_data[28:24], 19'd0};
                            end else ch2_on <= 1'b0;
                            prev_n2 <= rom_data[35:29];

                            // --- Channel 3 ---
                            if (rom_data[23:17] != 0) begin
                                n3 <= rom_data[23:17];
                                ch3_on <= 1'b1;
                                if (rom_data[23:17] != prev_n3) env3 <= {rom_data[16:12], 19'd0};
                            end else ch3_on <= 1'b0;
                            prev_n3 <= rom_data[23:17];

                            // --- Channel 4 ---
                            if (rom_data[11:5] != 0) begin
                                n4 <= rom_data[11:5];
                                ch4_on <= 1'b1;
                                if (rom_data[11:5] != prev_n4) env4 <= {rom_data[4:0], 19'd0};
                            end else ch4_on <= 1'b0;
                            prev_n4 <= rom_data[11:5];

                            state <= ST_PLAY;
                        end
                    end
                    ST_PLAY: begin
                        if (tick_1ms) begin
                            if (duration == 0) begin
                                local_addr <= local_addr + 1'b1;
                                state    <= ST_FETCH;
                            end else begin
                                duration <= duration - 1'b1;
                            end
                        end
                    end
                endcase

                // --- 智慧衰減：按著時慢降(>>10)，放開時快收(>>6) ---
                if (tick_1ms) begin
                    if (env1 > 0) env1 <= env1 - (ch1_on ? (env1 >> 10) : (env1 >> 6)) - 1'b1;
                    if (env2 > 0) env2 <= env2 - (ch2_on ? (env2 >> 10) : (env2 >> 6)) - 1'b1;
                    if (env3 > 0) env3 <= env3 - (ch3_on ? (env3 >> 10) : (env3 >> 6)) - 1'b1;
                    if (env4 > 0) env4 <= env4 - (ch4_on ? (env4 >> 10) : (env4 >> 6)) - 1'b1;
                end

                phase1 <= phase1 + freq1;
                phase2 <= phase2 + freq2;
                phase3 <= phase3 + freq3;
                phase4 <= phase4 + freq4;
            end
        end
    end


    function [15:0] note_to_step(input [6:0] note);
        case (note)
            7'd00: note_to_step = 16'd0000; // 靜音
            7'h01: note_to_step = 16'h000B;
            7'h02: note_to_step = 16'h000C;
            7'h03: note_to_step = 16'h000D;
            7'h04: note_to_step = 16'h000E;
            7'h05: note_to_step = 16'h000E;
            7'h06: note_to_step = 16'h000F;
            7'h07: note_to_step = 16'h0010;
            7'h08: note_to_step = 16'h0011;
            7'h09: note_to_step = 16'h0012;
            7'h0A: note_to_step = 16'h0013;
            7'h0B: note_to_step = 16'h0015;
            7'h0C: note_to_step = 16'h0016;
            7'h0D: note_to_step = 16'h0017;
            7'h0E: note_to_step = 16'h0019;
            7'h0F: note_to_step = 16'h001A;
            7'h10: note_to_step = 16'h001C;
            7'h11: note_to_step = 16'h001D;
            7'h12: note_to_step = 16'h001F;
            7'h13: note_to_step = 16'h0021;
            7'h14: note_to_step = 16'h0023;
            7'h15: note_to_step = 16'h0025;
            7'h16: note_to_step = 16'h0027;
            7'h17: note_to_step = 16'h002A;
            7'h18: note_to_step = 16'h002C;
            7'h19: note_to_step = 16'h002F;
            7'h1A: note_to_step = 16'h0032;
            7'h1B: note_to_step = 16'h0035;
            7'h1C: note_to_step = 16'h0038;
            7'h1D: note_to_step = 16'h003B;
            7'h1E: note_to_step = 16'h003F;
            7'h1F: note_to_step = 16'h0042;
            7'h20: note_to_step = 16'h0046;
            7'h21: note_to_step = 16'h004B;
            7'h22: note_to_step = 16'h004F;
            7'h23: note_to_step = 16'h0054;
            7'h24: note_to_step = 16'h0059;
            7'h25: note_to_step = 16'h005E;
            7'h26: note_to_step = 16'h0064;
            7'h27: note_to_step = 16'h006A;
            7'h28: note_to_step = 16'h0070;
            7'h29: note_to_step = 16'h0077;
            7'h2A: note_to_step = 16'h007E;
            7'h2B: note_to_step = 16'h0085;
            7'h2C: note_to_step = 16'h008D;
            7'h2D: note_to_step = 16'h0096;
            7'h2E: note_to_step = 16'h009F;
            7'h2F: note_to_step = 16'h00A8;
            7'h30: note_to_step = 16'h00B2;
            7'h31: note_to_step = 16'h00BD;
            7'h32: note_to_step = 16'h00C8;
            7'h33: note_to_step = 16'h00D4;
            7'h34: note_to_step = 16'h00E1;
            7'h35: note_to_step = 16'h00EE;
            7'h36: note_to_step = 16'h00FC;
            7'h37: note_to_step = 16'h010B;
            7'h38: note_to_step = 16'h011B;
            7'h39: note_to_step = 16'h012C;
            7'h3A: note_to_step = 16'h013E;
            7'h3B: note_to_step = 16'h0151;
            7'h3C: note_to_step = 16'h0165;
            7'h3D: note_to_step = 16'h017A;
            7'h3E: note_to_step = 16'h0190;
            7'h3F: note_to_step = 16'h01A8;
            7'h40: note_to_step = 16'h01C2;
            7'h41: note_to_step = 16'h01DC;
            7'h42: note_to_step = 16'h01F9;
            7'h43: note_to_step = 16'h0217;
            7'h44: note_to_step = 16'h0237;
            7'h45: note_to_step = 16'h0258;
            7'h46: note_to_step = 16'h027C;
            7'h47: note_to_step = 16'h02A2;
            7'h48: note_to_step = 16'h02CA;
            7'h49: note_to_step = 16'h02F4;
            7'h4A: note_to_step = 16'h0321;
            7'h4B: note_to_step = 16'h0351;
            7'h4C: note_to_step = 16'h0384;
            7'h4D: note_to_step = 16'h03B9;
            7'h4E: note_to_step = 16'h03F2;
            7'h4F: note_to_step = 16'h042E;
            7'h50: note_to_step = 16'h046E;
            7'h51: note_to_step = 16'h04B1;
            7'h52: note_to_step = 16'h04F8;
            7'h53: note_to_step = 16'h0544;
            7'h54: note_to_step = 16'h0594;
            7'h55: note_to_step = 16'h05E9;
            7'h56: note_to_step = 16'h0643;
            7'h57: note_to_step = 16'h06A3;
            7'h58: note_to_step = 16'h0708;
            7'h59: note_to_step = 16'h0773;
            7'h5A: note_to_step = 16'h07E4;
            7'h5B: note_to_step = 16'h085C;
            7'h5C: note_to_step = 16'h08DC;
            7'h5D: note_to_step = 16'h0962;
            7'h5E: note_to_step = 16'h09F1;
            7'h5F: note_to_step = 16'h0A89;
            7'h60: note_to_step = 16'h0B29;
            7'h61: note_to_step = 16'h0BD3;
            7'h62: note_to_step = 16'h0C87;
            7'h63: note_to_step = 16'h0D46;
            7'h64: note_to_step = 16'h0E10;
            7'h65: note_to_step = 16'h0EE6;
            7'h66: note_to_step = 16'h0FC9;
            7'h67: note_to_step = 16'h10B9;
            7'h68: note_to_step = 16'h11B8;
            7'h69: note_to_step = 16'h12C5;
            7'h6A: note_to_step = 16'h13E3;
            7'h6B: note_to_step = 16'h1512;
            7'h6C: note_to_step = 16'h1653;
            7'h6D: note_to_step = 16'h17A7;
            7'h6E: note_to_step = 16'h190F;
            7'h6F: note_to_step = 16'h1A8C;
            7'h70: note_to_step = 16'h1C20;
            7'h71: note_to_step = 16'h1DCD;
            7'h72: note_to_step = 16'h1F92;
            7'h73: note_to_step = 16'h2173;
            7'h74: note_to_step = 16'h2370;
            7'h75: note_to_step = 16'h258B;
            7'h76: note_to_step = 16'h27C7;
            7'h77: note_to_step = 16'h2A25;
            7'h78: note_to_step = 16'h2CA6;
            7'h79: note_to_step = 16'h2F4E;
            7'h7A: note_to_step = 16'h321E;
            7'h7B: note_to_step = 16'h3519;
            7'h7C: note_to_step = 16'h3841;
            7'h7D: note_to_step = 16'h3B9A;
            7'h7E: note_to_step = 16'h3F25;
            7'h7F: note_to_step = 16'h42E6;
            default: note_to_step = 16'h0000;
        endcase
    endfunction

endmodule

