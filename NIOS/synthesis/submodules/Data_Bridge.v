module Data_Bridge (
    input clk,
    input rst,

    input  wire [7:0]  avs_s1_address,
    input  wire [31:0] avs_s1_writedata,
    input  wire        avs_s1_write,

    output reg  [31:0] out_px, out_py, out_pvy, out_pz,
    output reg  [31:0] dirX0, dirY0, dirZ0,
    output reg  [31:0] dirXdx, dirYdx, dirZdx,
    output reg  [31:0] dirXdy, dirYdy, dirZdy,
    output reg signed  [15:0] skyLine,
    output reg         underWater,

    output reg         faceBlock,
    output reg  [15:0] faceBlock_x, faceBlock_y, faceBlock_z
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_px <= 32'd0; out_py <= 32'd0; out_pvy <= 32'd0; out_pz <= 32'd0;
            dirX0 <= 32'd0; dirY0 <= 32'd0; dirZ0 <= 32'd0;
            dirXdx <= 32'd0; dirYdx <= 32'd0; dirZdx <= 32'd0;
            dirXdy <= 32'd0; dirYdy <= 32'd0; dirZdy <= 32'd0;
            skyLine <= 16'd0;
            underWater <= 1'd0;
            faceBlock <= 1'd0;
            faceBlock_x <= 1'd0; faceBlock_y <= 1'd0; faceBlock_z <= 1'd0;
        end else begin
            if (avs_s1_write) begin
                case (avs_s1_address)
                    8'd0:  out_px      <= avs_s1_writedata;
                    8'd1:  out_py      <= avs_s1_writedata;
                    8'd2:  out_pvy     <= avs_s1_writedata;
                    8'd3:  out_pz      <= avs_s1_writedata;
                    8'd4:  dirX0       <= avs_s1_writedata;
                    8'd5:  dirY0       <= avs_s1_writedata;
                    8'd6:  dirZ0       <= avs_s1_writedata;
                    8'd7:  dirXdx      <= avs_s1_writedata;
                    8'd8:  dirYdx      <= avs_s1_writedata;
                    8'd9:  dirZdx      <= avs_s1_writedata;
                    8'd10: dirXdy      <= avs_s1_writedata;
                    8'd11: dirYdy      <= avs_s1_writedata;
                    8'd12: dirZdy      <= avs_s1_writedata;
                    8'd13: skyLine     <= avs_s1_writedata[15:0];
                    8'd14: underWater  <= avs_s1_writedata[0];
                    
                    8'd15: faceBlock   <= avs_s1_writedata[0];
                    8'd16: faceBlock_x <= avs_s1_writedata[15:0];
                    8'd17: faceBlock_y <= avs_s1_writedata[15:0];
                    8'd18: faceBlock_z <= avs_s1_writedata[15:0];
                    default: ;
                endcase
            end
        end
    end

endmodule
