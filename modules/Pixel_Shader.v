module Pixel_Shader(
    input clk,
    input rst,
    input start_shade,

    input [7:0]  hit,
    input [2:0]  hitSide,
    input signed [15:0] mapX, mapY, mapZ,
    input signed [31:0] px, py, pz,
    input signed [31:0] dirX, dirY, dirZ,
    input [31:0] deltaDistX, deltaDistY, deltaDistZ,
    input               stepX, stepY, stepZ,
    input signed [7:0]  height,
    input signed [15:0] sky_line,

    output reg          shade_done,
    output reg [7:0]    pixelColor,

    output wire [7:0]   texture_addr,
    input       [7:0]   texture_data,

    input [3:0] tex_offset,
    input       through_block,
    
    input faceBlock,
    input [15:0] faceBlock_x, faceBlock_y, faceBlock_z
);
    localparam FRAC_BITS = 16;

    reg [2:0] state;
    localparam  ST_IDLE           = 3'd0,
                ST_DIST           = 3'd1,
                ST_TEX_WAIT0      = 3'd2,
                ST_TEX_COORD      = 3'd3,
                ST_TEX_REAL_COORD = 3'd4,
                ST_TEX_WAIT       = 3'd5,
                ST_COLOR          = 3'd6;

    reg signed [31:0] perpWallDist;
    reg [7:0]  texture_addr_reg;
    assign texture_addr = texture_addr_reg;

    wire signed [31:0] mapX_32 = $signed(mapX);
    wire signed [31:0] mapY_32 = $signed(mapY);
    wire signed [31:0] mapZ_32 = $signed(mapZ);

    reg  signed [31:0] mul_a, mul_b;
    wire signed [31:0] mul_out;
    multiplier_Q u_shader_mul (.dataa(mul_a), .datab(mul_b), .result(mul_out));

    reg  signed [31:0] exact_mul_a_x, exact_mul_a_y, exact_mul_a_z;
    reg  signed [31:0] exact_mul_b_x, exact_mul_b_y, exact_mul_b_z;
    wire signed [31:0] exact_mul_out_x, exact_mul_out_y, exact_mul_out_z;

    reg signed [31:0] exact_x_reg, exact_y_reg, exact_z_reg;

    multiplier_Q u_exact_mul_x (.dataa(exact_mul_a_x), .datab(exact_mul_b_x), .result(exact_mul_out_x));
    multiplier_Q u_exact_mul_y (.dataa(exact_mul_a_y), .datab(exact_mul_b_y), .result(exact_mul_out_y));
    multiplier_Q u_exact_mul_z (.dataa(exact_mul_a_z), .datab(exact_mul_b_z), .result(exact_mul_out_z));

    reg [7:0] v_litColor;    
    reg [7:0] v_finalColor;  

    wire [3:0] texU, texV;
    assign texU = texture_addr_reg[1:0];
    assign texV = texture_addr_reg[3:2];

    always @(*) begin
        if (hit == 0) begin
            v_litColor = (height > sky_line) ? 8'b000_001_11 : 8'b000_001_10;
        end else if(faceBlock &&
            ((texU==4'd0||texU==4'd3)&&(texV==4'd0||texV==4'd3))&&
            faceBlock_x == mapX && faceBlock_y == mapY && faceBlock_z == mapZ ) begin
            v_litColor = 8'hFF;
        end else begin
            if (hitSide == 3'd0) begin
                v_litColor = {1'b0, texture_data[7:6], 1'b0, texture_data[4:3], 1'b0, texture_data[1]};
            end else if (hitSide == 3'd2) begin
                v_litColor = {2'b00, texture_data[7], 2'b00, texture_data[4], 1'b0, texture_data[1]}; 
            end else begin
                v_litColor = texture_data; 
            end
        end
    end

    always @(*) begin
        if (through_block) begin
            v_finalColor[7:5] = {1'b0, v_litColor[7:6]}; 
            v_finalColor[4:2] = {1'b0, v_litColor[4:3]}; 
            v_finalColor[1:0] = (v_litColor[1:0] == 2'b11) ? 2'b11 : (v_litColor[1:0] + 1'b1); 
        end else begin
            v_finalColor = v_litColor; 
        end
    end

    reg signed [31:0] sub_side0, sub_side1, sub_side2;
    
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sub_side0 <= 32'd0;
            sub_side1 <= 32'd0;
            sub_side2 <= 32'd0;
        end else begin
            sub_side0 <= (dirX > 0) ? ((mapX_32 << FRAC_BITS) - px) : (px - (mapX_32 << FRAC_BITS) - 32'sd65536);
            sub_side1 <= (dirY > 0) ? ((mapY_32 << FRAC_BITS) - py) : (py - (mapY_32 << FRAC_BITS) - 32'sd65536);
            sub_side2 <= (dirZ > 0) ? ((mapZ_32 << FRAC_BITS) - pz) : (pz - (mapZ_32 << FRAC_BITS) - 32'sd65536);
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state            <= ST_IDLE;
            shade_done       <= 1'b0;
            pixelColor       <= 8'd0;
            perpWallDist     <= 32'd0;
            texture_addr_reg <= 8'd0;
        end else begin
            shade_done <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (start_shade) begin
                        if (hit == 0) begin
                            state <= ST_COLOR; 
                        end else begin
                            if (hitSide == 3'd0) begin
                                if (dirX > 0) mul_a <= (mapX_32 << FRAC_BITS) - px;
                                else          mul_a <= px - (mapX_32 << FRAC_BITS) - 32'sd65536;
                                mul_b <= $signed(deltaDistX); 
                            end else if (hitSide == 3'd1) begin
                                if (dirY > 0) mul_a <= (mapY_32 << FRAC_BITS) - py;
                                else          mul_a <= py - (mapY_32 << FRAC_BITS) - 32'sd65536;
                                mul_b <= $signed(deltaDistY);
                            end else begin
                                if (dirZ > 0) mul_a <= (mapZ_32 << FRAC_BITS) - pz;
                                else          mul_a <= pz - (mapZ_32 << FRAC_BITS) - 32'sd65536;
                                mul_b <= $signed(deltaDistZ);
                            end
                            state <= ST_DIST;
                        end
                    end
                end

                ST_DIST: begin
                    perpWallDist <= mul_out;
                    
                    state <= ST_TEX_WAIT0;
                end

                ST_TEX_WAIT0: begin
                    exact_mul_a_x <= perpWallDist; exact_mul_b_x <= dirX;
                    exact_mul_a_y <= perpWallDist; exact_mul_b_y <= dirY;
                    exact_mul_a_z <= perpWallDist; exact_mul_b_z <= dirZ;
                    
                    state <= ST_TEX_COORD;
                end

                ST_TEX_COORD: begin
                    exact_x_reg <= px + exact_mul_out_x;
                    exact_y_reg <= py + exact_mul_out_y;
                    exact_z_reg <= pz + exact_mul_out_z;
                    
                    state <= ST_TEX_REAL_COORD;
                end

                ST_TEX_REAL_COORD: begin 
                    if (hitSide == 3'd0) begin
                        texture_addr_reg[1:0] <= exact_z_reg[15:14];
                        texture_addr_reg[3:2] <= 2'd3 - exact_y_reg[15:14];
                    end else if (hitSide == 3'd1) begin
                        texture_addr_reg[1:0] <= exact_x_reg[15:14];
                        texture_addr_reg[3:2] <= 2'd3 - exact_z_reg[15:14];
                    end else begin
                        texture_addr_reg[1:0] <= exact_x_reg[15:14];
                        texture_addr_reg[3:2] <= 2'd3 - exact_y_reg[15:14];
                    end
                    texture_addr_reg[7:4] <= tex_offset;
                    state <= ST_TEX_WAIT;
                end

                ST_TEX_WAIT: state <= ST_COLOR;
                ST_COLOR: begin
                    pixelColor <= v_finalColor; 
                    shade_done <= 1'b1;
                    state      <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule