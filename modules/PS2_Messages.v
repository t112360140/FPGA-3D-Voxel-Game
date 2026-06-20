module PS2_Messages(
    input clk,
    input rst_n,

    input pressed, 
    input released,
    input extended,
    input [7:0] data,
    input valid,

    output reg [63:0]  pressed_key,
    
    output     [9:0]  move_ctrl,
    output     [1:0]  action_keys,
    output reg [7:0]  block_select,

    output     [7:0]  state_key
);

    assign move_ctrl   = {
        pressed_key[39], // 9: Control (RUN)
        pressed_key[38], // 8: Space (JUMP)
        pressed_key[43], // 7: Right Arrow
        pressed_key[41], // 6: Left Arrows
        pressed_key[44], // 5: Down Arrow
        pressed_key[42], // 4: Up Arrow
        pressed_key[13], // 3: D Key
        pressed_key[10], // 2: A Key
        pressed_key[28], // 1: S Key
        pressed_key[32]  // 0: W Key
    };
    assign action_keys = {pressed_key[14], pressed_key[26]}; // 14:E(PLACE), 26:Q(BREAK)

    assign state_key = {7'd0, pressed_key[36]};

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            block_select <= 8'd1;
        end else begin
            if(pressed_key[1]) block_select <= 8'd1;
            else if(pressed_key[2]) block_select <= 8'd2;
            else if(pressed_key[3]) block_select <= 8'd3;
            else if(pressed_key[4]) block_select <= 8'd4;
            else if(pressed_key[5]) block_select <= 8'd5;
            else if(pressed_key[6]) block_select <= 8'd6;
        end
    end

    reg [5:0] key_index;

    always@(*) begin
        key_index = 6'd63;
        case({extended, data})
            9'h045: //  0: 0
                key_index =  0;
            9'h016: //  1: 1
                key_index =  1;
            9'h01E: //  2: 2
                key_index =  2;
            9'h026: //  3: 3
                key_index =  3;
            9'h025: //  4: 4
                key_index =  4;
            9'h02E: //  5: 5
                key_index =  5;
            9'h036: //  6: 6
                key_index =  6;
            9'h03D: //  7: 7
                key_index =  7;
            9'h03E: //  8: 8
                key_index =  8;
            9'h046: //  9: 9
                key_index =  9;
            9'h01C: // 10: A
                key_index = 10;
            9'h032: // 11: B
                key_index = 11;
            9'h021: // 12: C
                key_index = 12;
            9'h023: // 13: D
                key_index = 13;
            9'h024: // 14: E
                key_index = 14;
            9'h02B: // 15: F
                key_index = 15;
            9'h034: // 16: G
                key_index = 16;
            9'h033: // 17: H
                key_index = 17;
            9'h043: // 18: I
                key_index = 18;
            9'h03B: // 19: J
                key_index = 19;
            9'h042: // 20: K
                key_index = 20;
            9'h04B: // 21: L
                key_index = 21;
            9'h03A: // 22: M
                key_index = 22;
            9'h031: // 23: N
                key_index = 23;
            9'h044: // 24: O
                key_index = 24;
            9'h04D: // 25: P
                key_index = 25;
            9'h015: // 26: Q
                key_index = 26;
            9'h02D: // 27: R
                key_index = 27;
            9'h01B: // 28: S
                key_index = 28;
            9'h02C: // 29: T
                key_index = 29;
            9'h03C: // 30: U
                key_index = 30;
            9'h02A: // 31: V
                key_index = 31;
            9'h01D: // 32: W
                key_index = 32;
            9'h022: // 33: X
                key_index = 33;
            9'h035: // 34: Y
                key_index = 34;
            9'h01A: // 35: Z
                key_index = 35;
            9'h076: // 36: Esc
                key_index = 36;
            9'h05A: // 37: Enter
                key_index = 37;
            9'h029: // 38: Space
                key_index = 38;
            9'h014: // 39: Control
                key_index = 39;
            9'h012: // 40: Shift
                key_index = 40;
            9'h16B: // 41: Left Arrow
                key_index = 41;
            9'h175: // 42: Up Arrow
                key_index = 42;
            9'h174: // 43: Right Arrow
                key_index = 43;
            9'h172: // 44: Down Arrow
                key_index = 44;
        endcase
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pressed_key <= 64'd0;
        end else begin
            if(valid && key_index!=6'd63) begin
                pressed_key[key_index] <= pressed;
            end
        end
    end
	
endmodule
