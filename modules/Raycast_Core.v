module Raycast_Core(
    input clk,
    input rst,
    input start_ray,

    input signed [31:0] px, py, pz,
    input signed [31:0] dirX, dirY, dirZ,

    // SRAM 介面
    output reg         sram_req,
    output reg  [19:0] sram_addr,
    input              sram_grant,
    input       [15:0] sram_rd_data,

    // 雙埠 ROM 介面
    output wire [11:0] inv_delta_addr,
    input       [31:0] inv_delta_data,

    // 材質快取介面
    output reg  [6:0]  block_info_addr,
    input       [7:0]  block_info_data,
    input              through_block,

    // 輸出的成果
    output reg         ray_done,
    output reg  [7:0]  hit,
    output reg  [2:0]  hitSide,
    output reg  signed [15:0] out_mapX, out_mapY, out_mapZ,
    output reg  [31:0] out_deltaDistX, out_deltaDistY, out_deltaDistZ,
    output reg                out_stepX, out_stepY, out_stepZ
);
    localparam  FRAC_BITS = 8'd16,
                SCALE     = 1 << 16,
                MAX_STEP  = 8'd24,
                WORLD_X   = 8'd128,
                WORLD_Y   = 8'd128,
                WORLD_Z   = 8'd128;

    reg [3:0] state;
    localparam  ST_IDLE         = 4'd0,   
                ST_WAIT_X       = 4'd1,   
                ST_FETCH_X      = 4'd2,   
                ST_WAIT_Y       = 4'd3,   
                ST_FETCH_Y      = 4'd4,   
                ST_WAIT_Z       = 4'd5,
                ST_FETCH_Z      = 4'd6,
                ST_GET_STEP     = 4'd7,  
                ST_START_RAY    = 4'd8,
                ST_WAIT_BLK     = 4'd9,
                ST_GET_BLK_WAIT = 4'd10,
                ST_GET_BLK      = 4'd11;

    reg [7:0] step;
    reg [31:0] deltaDistX, deltaDistY, deltaDistZ;
    reg signed [15:0] mapX, mapY, mapZ;
    reg               stepX, stepY, stepZ;
    reg [31:0] sideDistX, sideDistY, sideDistZ;

    wire signed [31:0] px_f = px & (SCALE-1);
    wire signed [31:0] py_f = py & (SCALE-1);
    wire signed [31:0] pz_f = pz & (SCALE-1);

    reg signed [15:0] n_mapX, n_mapY, n_mapZ;
    always @(*) begin
        n_mapX = mapX;
        n_mapY = mapY;
        n_mapZ = mapZ;
        if (sideDistX < sideDistY) begin
            if (sideDistX < sideDistZ) begin
                n_mapX = mapX + (stepX ? -1 : 1);
            end else begin
                n_mapZ = mapZ + (stepZ ? -1 : 1);
            end
        end else begin
            if (sideDistY < sideDistZ) begin
                n_mapY = mapY + (stepY ? -1 : 1);
            end else begin
                n_mapZ = mapZ + (stepZ ? -1 : 1);
            end
        end
    end
    wire [19:0] n_block_addr = {n_mapX[6:0], n_mapY[6:0], n_mapZ[6:1]};

    wire [19:0] block_addr = {mapX[6:0], mapY[6:0], mapZ[6:1]};
    reg         block_cached;
    reg  [19:0] block_cache_addr;
    reg  [15:0] block_cache;
    wire [7:0]  block_type = mapZ[0] ? block_cache[15:8] : block_cache[7:0];

    function [11:0] q16_q10;
        input signed [31:0] val;
        reg signed [31:0] abs_val;
        begin
            abs_val = (val < 0) ? -val : val;
            if (abs_val[31:18] != 14'd0) begin
                q16_q10 = 12'hFFF; 
            end else begin
                q16_q10 = abs_val[17:6];
            end
        end
    endfunction

    reg [11:0] inv_delta_addr_reg;
    assign inv_delta_addr = inv_delta_addr_reg;

    reg  signed [31:0] mul_a_x, mul_a_y, mul_a_z;
    reg  signed [31:0] mul_b_x, mul_b_y, mul_b_z;
    wire signed [31:0] mul_out_x, mul_out_y, mul_out_z;

    multiplier_Q u_mul_x (.dataa(mul_a_x), .datab(mul_b_x), .result(mul_out_x));
    multiplier_Q u_mul_y (.dataa(mul_a_y), .datab(mul_b_y), .result(mul_out_y));
    multiplier_Q u_mul_z (.dataa(mul_a_z), .datab(mul_b_z), .result(mul_out_z));

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state              <= ST_IDLE;
            block_cached       <= 1'b0;
            sram_req           <= 1'b0;
            ray_done           <= 1'b0;
            inv_delta_addr_reg <= 12'd0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (start_ray) begin
                        mapX <= px >>> FRAC_BITS;
                        mapY <= py >>> FRAC_BITS;
                        mapZ <= pz >>> FRAC_BITS;
                        stepX <= (dirX < 0);
                        stepY <= (dirY < 0);
                        stepZ <= (dirZ < 0);
                        hit <= 8'd0; hitSide <= 3'd0; step <= 8'd0;
                        
                        inv_delta_addr_reg <= q16_q10(dirX); // 請求 X
                        state <= ST_WAIT_X;
                    end
                    ray_done <= 1'b0;
                end

                ST_WAIT_X: state <= ST_FETCH_X;
                ST_FETCH_X: begin
                    deltaDistX <= inv_delta_data;
                    mul_b_x    <= inv_delta_data;
                    mul_a_x    <= (dirX < 0) ? px_f : (SCALE - px_f);
                    
                    inv_delta_addr_reg <= q16_q10(dirY); // 請求 Y
                    state <= ST_WAIT_Y;
                end

                ST_WAIT_Y: state <= ST_FETCH_Y;
                ST_FETCH_Y: begin
                    deltaDistY <= inv_delta_data;
                    mul_b_y    <= inv_delta_data;
                    mul_a_y    <= (dirY < 0) ? py_f : (SCALE - py_f);
                    
                    inv_delta_addr_reg <= q16_q10(dirZ); // 請求 Z
                    state <= ST_WAIT_Z;
                end

                ST_WAIT_Z: state <= ST_FETCH_Z;
                ST_FETCH_Z: begin
                    deltaDistZ <= inv_delta_data;
                    mul_b_z    <= inv_delta_data;
                    mul_a_z    <= (dirZ < 0) ? pz_f : (SCALE - pz_f);
                    
                    state <= ST_GET_STEP;
                end

                ST_GET_STEP: begin
                    // 給乘法器 1 個週期的運算時間
                    sideDistX <= mul_out_x;
                    sideDistY <= mul_out_y;
                    sideDistZ <= mul_out_z;
                    state     <= ST_START_RAY;
                end

                ST_START_RAY: begin
                    if (hit != 0 || step == MAX_STEP || 
                        mapX < 0 || mapX >= WORLD_X || mapY < 0 || mapY >= WORLD_Y || mapZ < 0 || mapZ >= WORLD_Z) begin
                        
                        out_mapX <= mapX; out_mapY <= mapY; out_mapZ <= mapZ;
                        out_deltaDistX <= deltaDistX; out_deltaDistY <= deltaDistY; out_deltaDistZ <= deltaDistZ;
                        out_stepX <= stepX; out_stepY <= stepY; out_stepZ <= stepZ;
                        ray_done <= 1'b1;

                        if (mapX < 0 || mapX >= WORLD_X || mapY < 0 || mapY >= WORLD_Y || mapZ < 0 || mapZ >= WORLD_Z)
                            hit <= 8'd0;

                        state    <= ST_IDLE;
                    end else begin
                        step <= step + 1'b1;
                        if (sideDistX < sideDistY) begin
                            if (sideDistX < sideDistZ) begin
                                sideDistX <= sideDistX + deltaDistX;
                                mapX      <= n_mapX;
                                hitSide   <= 3'd0;
                            end else begin
                                sideDistZ <= sideDistZ + deltaDistZ;
                                mapZ      <= n_mapZ;
                                hitSide   <= 3'd2;
                            end
                        end else begin
                            if (sideDistY < sideDistZ) begin
                                sideDistY <= sideDistY + deltaDistY;
                                mapY      <= n_mapY;
                                hitSide   <= 3'd1;
                            end else begin
                                sideDistZ <= sideDistZ + deltaDistZ;
                                mapZ      <= n_mapZ;
                                hitSide   <= 3'd2;
                            end
                        end

                        if (block_cached && block_cache_addr == n_block_addr) begin
                            block_info_addr <= { (n_mapZ[0] ? block_cache[11:8] : block_cache[3:0]), 3'b011 };
                            state <= ST_GET_BLK_WAIT;
                        end else begin
                            block_cached <= 1'b0;
                            sram_req  <= 1'b1;
                            sram_addr <= n_block_addr;
                            state     <= ST_WAIT_BLK;
                        end
                    end
                end

                ST_WAIT_BLK: begin
                    if (sram_grant) begin
                        sram_req         <= 1'b0;
                        block_cached     <= 1'b1;
                        block_cache_addr <= sram_addr;
                        block_cache      <= sram_rd_data;
                        block_info_addr <= { (mapZ[0] ? sram_rd_data[11:8] : sram_rd_data[3:0]), 3'b011 };
                        state            <= ST_GET_BLK_WAIT;
                    end
                end

                ST_GET_BLK_WAIT: begin
                    state <= ST_GET_BLK;
                end

                ST_GET_BLK: begin
                    hit <= (through_block && block_info_data) ? 8'd0 : block_type;
                    state <= ST_START_RAY;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule