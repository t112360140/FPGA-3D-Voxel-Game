module IO_Cotroller (
    input clk,
    input rst_n,

    input [17:0] SW,
    input [2:0]  KEY,

    input [7:0] mode,
    input [7:0] progress,

    input  wire [1:0] song_sel,
    output reg  [2:0] bmg_vol,

    input [7:0] fps,

    output reg [31:0] seed,

    input [7:0] px, py ,pz,
    input [7:0] block_select,

    output [255:0] lcd_msg,

    output reg  [17:0] LEDR,
    output wire [7:0]  LEDG,

    output wire [31:0] seg_value,
    output reg  [7:0] seg_enable,
    output reg  [7:0] seg_neg,

    output reg        eep_write,
    output reg        eep_read,
    output reg [11:0] eep_addr,
    output reg [31:0] eep_writedata,
    input      [31:0] eep_readdata,
    input             eep_datavalid,
    input             eep_ready
);
    localparam  IDLE     = 8'd0,
                MENU     = 8'd1,
                MAP_SAVE = 8'd2,
                MAP_LOAD = 8'd3,
                MAP_GEN  = 8'd4,
                GAME     = 8'd5,
                STOP     = 8'd6;

    integer i, j;

    reg [127:0] LCD_LINE [1:0];
    assign lcd_msg = {LCD_LINE[0], LCD_LINE[1]};

    reg [3:0] HEX [7:0];
    assign seg_value = {HEX[0], HEX[1], HEX[2], HEX[3], HEX[4], HEX[5], HEX[6], HEX[7]};


    wire [11:0] px_bcd, py_bcd, pz_bcd;
    bin2bcd u_b2b_x(.bin(px), .bcd(px_bcd));
    bin2bcd u_b2b_y(.bin(py), .bcd(py_bcd));
    bin2bcd u_b2b_z(.bin(pz), .bcd(pz_bcd));
    wire [23:0] px_ascii = {
        (px_bcd[11:8] == 0)?" ":px_bcd[11:8]+"0",
        (px_bcd[11:8] == 0 && px_bcd[7:4] == 0)?" ":px_bcd[7:4]+"0",
        px_bcd[3:0]+"0"
    };
    wire [23:0] py_ascii = {
        (py_bcd[11:8] == 0)?" ":py_bcd[11:8]+"0",
        (py_bcd[11:8] == 0 && py_bcd[7:4] == 0)?" ":py_bcd[7:4]+"0",
        py_bcd[3:0]+"0"
    };
    wire [23:0] pz_ascii = {
        (pz_bcd[11:8] == 0)?" ":pz_bcd[11:8]+"0",
        (pz_bcd[11:8] == 0 && pz_bcd[7:4] == 0)?" ":pz_bcd[7:4]+"0",
        pz_bcd[3:0]+"0"
    };

    reg [7:0] progress_led;
    assign LEDG = (vol_change!=0) ?
            {bmg_vol_led[0], bmg_vol_led[1], bmg_vol_led[2], bmg_vol_led[3], bmg_vol_led[4], bmg_vol_led[5], bmg_vol_led[6], bmg_vol_led[7]}
            : progress_led;

    always@(*) begin
        LCD_LINE[0] = "                ";
        LCD_LINE[1] = "                ";
        progress_led = 8'd0;
        LEDR = 18'd0;
        seed = 32'd0;
        case(mode)
            IDLE, MENU: begin
                LCD_LINE[0] = "   MINECRAFT!   ";
                LCD_LINE[1] = " Dev: 112360140 ";
            end
            MAP_GEN: begin
                LCD_LINE[0] = " MAP GENERATED. ";
                LCD_LINE[1] = "PROG: [        ]";
                for (i = 0; i < 8; i = i + 1) begin
                    LCD_LINE[1][(64 - i*8) +: 8] = progress[i] ? "=" : " ";
                end
                progress_led = progress;
                LEDR = SW;
                seed[17:0] = SW;
            end
            MAP_SAVE: begin
                LCD_LINE[0] = " MAP SAVE.      ";
                LCD_LINE[1] = "PROG: [        ]";
                for (i = 0; i < 8; i = i + 1) begin
                    LCD_LINE[1][(64 - i*8) +: 8] = progress[i] ? "=" : " ";
                end
                progress_led = progress;
            end
            MAP_LOAD: begin
                LCD_LINE[0] = " MAP LOAD.      ";
                LCD_LINE[1] = "PROG: [        ]";
                for (i = 0; i < 8; i = i + 1) begin
                    LCD_LINE[1][(64 - i*8) +: 8] = progress[i] ? "=" : " ";
                end
                progress_led = progress;
            end
            GAME: begin
                LCD_LINE[0] = {"POS: ",px_ascii,",",py_ascii,",",pz_ascii};
                LCD_LINE[1][127:64] = " Block: ";
                
                case(block_select)
                    8'd01: LCD_LINE[1][63:0] = " STONE  ";
                    8'd02: LCD_LINE[1][63:0] = " GRASS  ";
                    8'd03: LCD_LINE[1][63:0] = "  DIRT  ";
                    8'd04: LCD_LINE[1][63:0] = "  LOG   ";
                    8'd05: LCD_LINE[1][63:0] = " LEAVES ";
                    8'd06: LCD_LINE[1][63:0] = " WATER  ";
                    default: LCD_LINE[1][63:0] = "        ";
                endcase
            end
            STOP: begin
                LCD_LINE[0] = "    GAME STOP   ";
                LCD_LINE[1] = "                ";
            end
            default: begin
                LCD_LINE[0] = "      HAHA!     ";
                LCD_LINE[1] = "  You Find Me!  ";
            end
        endcase
    end

    wire [11:0] fps_bcd;
    bin2bcd u_b2b_fps(.bin(fps), .bcd(fps_bcd));

    always@(*) begin
        for (j = 0; j < 8; j = j + 1)
            HEX[j] = 4'd0;
        seg_enable = 8'h00;
        seg_neg = 8'h00;
        case(mode)
            GAME: begin
                seg_enable = {
                    ((song_sel!=2'b00)?2'b11:2'b00),
                    2'b00,
                    !(fps_bcd[11:8]==4'd0),
                    !(fps_bcd[11:8]==4'd0 && fps_bcd[7:4]==4'd0),
                    2'b11
                };
                HEX[0] = 4'hF;
                HEX[1] = fps_bcd[3:0];
                HEX[2] = fps_bcd[7:4];
                HEX[3] = fps_bcd[11:8];
                HEX[6] = song_sel;
                HEX[7] = 4'h5;
            end
        endcase
    end

    reg  [2:0]  last_key;
    reg  [31:0] vol_change;
    wire [8:0]  bmg_vol_led=(1<<(bmg_vol+1))-1;
    // reg  [1:0]  eep_ls_vol;
    // reg eep_vol_get;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            last_key <= 3'b111;
            vol_change <= 32'd0;
            bmg_vol <= 3'd4;
            // eep_ls_vol <= 2'b10;
        end else begin
            // if(eep_vol_get) begin
            //     bmg_vol <= eep_readdata[2:0];
            // end else begin
            //     if(eep_ready && eep_ls_vol!=2'b00) eep_ls_vol <= 2'b00;
            //     else begin
            if(!KEY[0] && last_key[0]) begin
                if(bmg_vol<3'b111) bmg_vol <= bmg_vol+1;
                // eep_ls_vol <= 2'b01;
            end
            if(!KEY[1] && last_key[1]) begin
                if(bmg_vol>3'b000) bmg_vol <= bmg_vol-1;
                // eep_ls_vol <= 2'b01;
            end
            //     end
            // end

            if(!KEY[0] || !KEY[1] /*|| eep_vol_get*/) vol_change <= 32'd50_000_000;
            else if(vol_change>0) vol_change <= vol_change-1;

            last_key <= KEY;
        end
    end

    // localparam  EEP_IDLE      = 4'd0,
    //             EEP_WRITE     = 4'd1,
    //             EEP_READ      = 4'd2,
    //             EEP_READ_WAIT = 4'd3;

    // reg [3:0] eep_state;
    // reg [3:0] eep_read_i;
    // always@(posedge clk or negedge rst_n) begin
    //     if(!rst_n) begin
    //         eep_state   <= EEP_IDLE;
    //         eep_read_i  <= 4'd0;
    //         eep_write   <= 1'b0;
    //         eep_read    <= 1'b0;
    //         eep_vol_get <= 1'b0;
    //     end else begin
    //         eep_write   <= 1'b0;
    //         eep_read    <= 1'b0;
    //         eep_vol_get <= 1'b0;
    //         case(eep_state)
    //             EEP_IDLE: begin
    //                 if(eep_ls_vol[0]) begin
    //                     eep_addr <= 12'd0;
    //                     eep_write <= 1'b1;
    //                     eep_writedata <= bmg_vol;
    //                 end else if(eep_ls_vol[1]) begin
    //                     eep_addr <= 12'd0;
    //                     eep_read <= 1'b1;
    //                     eep_read_i <= 4'd1;

    //                     eep_state <= EEP_READ;
    //                 end
    //             end
    //             EEP_WRITE: begin
    //                 if(eep_ready) eep_state <= EEP_IDLE;
    //             end
    //             EEP_READ: begin
    //                 if(eep_ready) eep_state <= EEP_READ_WAIT;
    //             end
    //             EEP_READ_WAIT: begin
    //                 if(eep_datavalid) begin
    //                     if(eep_read_i == 4'd1)
    //                         eep_vol_get <= 1'b1;
                        
    //                     eep_state <= EEP_IDLE;
    //                 end
    //             end
    //             default: eep_state <= EEP_IDLE;
    //         endcase
    //     end
    // end

endmodule
