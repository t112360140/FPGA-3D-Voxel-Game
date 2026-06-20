`define TO_FIXED(val)  ((val) * 65536.0)

module Ray_Module(
    input clk,
    input rst,

    input       clear,
    input [7:0] clear_color,

    output reg vram_index,

    output reg         vram_wr_en,
    output reg  [15:0] vram_wr_addr,
    output reg  [7:0]  vram_wr_data,
    
    output wire        sram_req,
    output wire [19:0] sram_addr,
    input              sram_grant,
    input       [15:0] sram_rd_data,

    output wire [11:0] inv_delta_addr,
    input       [31:0] inv_delta_data,

    output wire [6:0]  block_info_addr,
    input       [7:0]  block_info_data,

    output wire [7:0]  texture_addr,
    input       [7:0]  texture_data,

    input signed [31:0] px, py, pz,
    input signed [31:0] dirX0, dirY0, dirZ0,
    input signed [31:0] dirXdx, dirYdx, dirZdx,
    input signed [31:0] dirXdy, dirYdy, dirZdy,
    input signed [15:0] sky_line,
    input        through_block,
    
    input faceBlock,
    input [15:0] faceBlock_x, faceBlock_y, faceBlock_z,

    input            fps_fresh,
    output reg [7:0] fps
);
    localparam  VGA_H = 8'd120,
                VGA_W = 8'd160;

    reg [7:0] height, width;
    reg signed [31:0] dirX, dirY, dirZ;
    reg signed [31:0] row_start_dirX, row_start_dirY, row_start_dirZ;
    reg signed [31:0] shade_dirX, shade_dirY, shade_dirZ;

    reg signed [31:0] reg_dirXdx, reg_dirYdx, reg_dirZdx;
    reg signed [31:0] reg_dirXdy, reg_dirYdy, reg_dirZdy;

    reg signed [31:0] latched_px, latched_py, latched_pz;

    reg         start_ray;
    wire        ray_done;
    wire [7:0]  core_hit;
    wire [2:0]  core_hitSide;
    wire signed [15:0] core_mapX, core_mapY, core_mapZ;
    wire [31:0] core_deltaX, core_deltaY, core_deltaZ;
    wire        core_stepX, core_stepY, core_stepZ;

    reg         start_shade;
    wire        shade_done;
    wire [7:0]  shaded_color;

    reg         ray_pulsed;
    reg         shade_pulsed;

    reg [2:0] shade_tex_attr_offset;
    always @(*) begin
        if (core_hitSide == 3'd1) begin
            if (core_stepY)
                shade_tex_attr_offset = 3'b000;
            else
                shade_tex_attr_offset = 3'b010;
        end else begin
            shade_tex_attr_offset = 3'b001;
        end
    end
    wire [6:0] core_block_info_addr;
    assign block_info_addr = (sched_state == S_SHADE) ? 
                            { core_hit[3:0], shade_tex_attr_offset } : 
                            core_block_info_addr;
    
    reg clear_reg;
    reg [7:0] clear_color_reg;

    reg [7:0] frame_counter;

    // 主狀態機
    reg [2:0] sched_state;
    localparam  S_IDLE   = 3'd0,
                S_RAY    = 3'd1,
                S_SHADE  = 3'd2,
                S_WRITE  = 3'd3;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            sched_state     <= S_IDLE;
            height          <= 8'd0;
            width           <= 8'd0;
            vram_wr_en      <= 1'b0;
            vram_index      <= 1'b0;
            start_ray       <= 1'b0;
            start_shade     <= 1'b0;
            ray_pulsed      <= 1'b0;
            shade_pulsed    <= 1'b0;
            clear_reg       <= 1'b0;
            clear_color_reg <= 8'h00;

            fps             <= 8'd0;
            frame_counter   <= 8'd0;
        end else begin
            vram_wr_en  <= 1'b0; 
            start_ray   <= 1'b0;
            start_shade <= 1'b0;

            if(fps_fresh) begin
                fps <= frame_counter;
                frame_counter <= 8'd0;
            end

            case (sched_state)
                S_IDLE: begin
                    height <= 8'd0;
                    width  <= 8'd0;
                    dirX   <= dirX0; dirY <= dirY0; dirZ <= dirZ0;
                    row_start_dirX <= dirX0; row_start_dirY <= dirY0; row_start_dirZ <= dirZ0;
                    reg_dirXdx <= dirXdx; reg_dirYdx <= dirYdx; reg_dirZdx <= dirZdx;
                    reg_dirXdy <= dirXdy; reg_dirYdy <= dirYdy; reg_dirZdy <= dirZdy;
                    latched_px <= px;
                    latched_py <= py;
                    latched_pz <= pz;
                    ray_pulsed     <= 1'b0;
                    shade_pulsed   <= 1'b0;

                    clear_reg <= clear;
                    clear_color_reg <=clear_color;
                    if(clear) sched_state <= S_WRITE;
                    else sched_state <= S_RAY;
                end

                S_RAY: begin
                    if (!ray_pulsed) begin
                        start_ray  <= 1'b1; // 喚醒 DDA 引擎
                        ray_pulsed <= 1'b1;
                    end else begin
                        start_ray  <= 1'b0;

                        if (ray_done) begin
                            ray_pulsed  <= 1'b0;

                            shade_dirX  <= dirX;
                            shade_dirY  <= dirY;
                            shade_dirZ  <= dirZ;

                            sched_state <= S_SHADE;
                        end
                    end
                end

                S_SHADE: begin
                    if (!shade_pulsed) begin
                        start_shade  <= 1'b1; // 喚醒著色引擎
                        shade_pulsed <= 1'b1;
                    end else begin
                        start_shade  <= 1'b0;

                        if (shade_done) begin
                            shade_pulsed <= 1'b0; 
                            sched_state  <= S_WRITE;
                        end
                    end
                end

                S_WRITE: begin
                    vram_wr_en   <= 1'b1;
                    vram_wr_addr <= (vram_index ? (VGA_H*VGA_W) : 16'd0) + (height * VGA_W) + width;
                    if(clear_reg) vram_wr_data <= clear_color_reg;
                    else          vram_wr_data <= (height==(VGA_H>>1) && width==(VGA_W>>1))?8'hFF:shaded_color;

                    // 純加法格點更新，0次乘法！
                    if (width == VGA_W - 1) begin
                        width <= 8'd0;
                        if (height == VGA_H - 1) begin
                            height      <= 8'd0;
                            vram_index  <= !vram_index;
                            sched_state <= S_IDLE;

                            frame_counter <= frame_counter+1;
                        end else begin
                            height <= height + 1'b1;
                            row_start_dirX <= row_start_dirX + reg_dirXdy;
                            row_start_dirY <= row_start_dirY + reg_dirYdy;
                            row_start_dirZ <= row_start_dirZ + reg_dirZdy;
                            
                            dirX <= row_start_dirX + reg_dirXdy;
                            dirY <= row_start_dirY + reg_dirYdy;
                            dirZ <= row_start_dirZ + reg_dirZdy;
                            if(!clear_reg) sched_state <= S_RAY;
                        end
                    end else begin
                        width <= width + 1'b1;
                        dirX  <= dirX + reg_dirXdx;
                        dirY  <= dirY + reg_dirYdx;
                        dirZ  <= dirZ + reg_dirZdx;
                        if(!clear_reg) sched_state <= S_RAY;
                    end
                end
                default: sched_state <= S_IDLE;
            endcase
        end
    end

    // 實體化 DDA
    Raycast_Core u_core (
        .clk(clk), .rst(rst), .start_ray(start_ray),
        .px(latched_px), .py(latched_py), .pz(latched_pz), .dirX(dirX), .dirY(dirY), .dirZ(dirZ),
        .sram_req(sram_req), .sram_addr(sram_addr), .sram_grant(sram_grant), .sram_rd_data(sram_rd_data),
        .inv_delta_addr(inv_delta_addr), .inv_delta_data(inv_delta_data),
        .block_info_addr(core_block_info_addr), .block_info_data(block_info_data), .through_block(through_block),
        .ray_done(ray_done), .hit(core_hit), .hitSide(core_hitSide),
        .out_mapX(core_mapX), .out_mapY(core_mapY), .out_mapZ(core_mapZ),
        .out_deltaDistX(core_deltaX), .out_deltaDistY(core_deltaY), .out_deltaDistZ(core_deltaZ),
        .out_stepX(core_stepX), .out_stepY(core_stepY), .out_stepZ(core_stepZ)
    );

    // 實體化著色
    Pixel_Shader u_shader (
        .clk(clk), .rst(rst), .start_shade(start_shade),
        .hit(core_hit), .hitSide(core_hitSide),
        .mapX(core_mapX), .mapY(core_mapY), .mapZ(core_mapZ),
        .px(latched_px), .py(latched_py), .pz(latched_pz), .dirX(shade_dirX), .dirY(shade_dirY), .dirZ(shade_dirZ),
        .deltaDistX(core_deltaX), .deltaDistY(core_deltaY), .deltaDistZ(core_deltaZ),
        .stepX(core_stepX), .stepY(core_stepY), .stepZ(core_stepZ),
        .height(height), .sky_line(sky_line),
        .shade_done(shade_done), .pixelColor(shaded_color),
        .through_block(through_block), .tex_offset(block_info_data[3:0]),
        .texture_addr(texture_addr), .texture_data(texture_data),
        .faceBlock(faceBlock),
        .faceBlock_x(faceBlock_x), .faceBlock_y(faceBlock_y), .faceBlock_z(faceBlock_z)
    );

endmodule