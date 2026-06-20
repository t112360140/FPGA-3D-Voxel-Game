module EEPROM_Manager#(
    parameter CLK_FREQ = 50_000_000
)(
    input         clk,
    input         rst_n,

    input         cmd_write,
    input         cmd_read,
    input  [11:0] mem_addr,
    input  [31:0] write_data,
    output [31:0] read_data,
    output reg    data_valid,
    output        ready,
	 
    inout         SCLK,
    inout         SDAT
);
    localparam [7:0] EEP_ADDR = 8'b10100000;
	
    reg [11:0] addr_reg;
    reg [31:0] data_write_reg_32; 
    reg [7:0]  data_write_byte;   
    wire [7:0] i2c_data_out;
	
    reg req_trans;
    wire valid_out;
    wire busy, nack;
    reg op_is_read;
	
    reg [1:0] byte_idx;
	
    i2c_master u_i2c_mas(
        .i_clk(clk),
        .reset_n(rst_n),
        .i_addr_w_rw(EEP_ADDR | op_is_read),
        .i_sub_addr({4'd0, addr_reg + (op_is_read ? 12'd0 : byte_idx)}),
        .i_sub_len(1'b1),
        .i_byte_len(op_is_read ? 24'd4 : 24'd1), 
        .i_data_write(data_write_byte),
        .req_trans(req_trans),
		
        .data_out(i2c_data_out),
        .valid_out(valid_out),
		
        .req_data_chunk(),
        .busy(busy),
        .nack(nack),
		
        .scl_o(SCLK),
        .sda_o(SDAT)
    );
	
    localparam DELAY_10MS_LIMIT = CLK_FREQ / 100;
    reg [23:0] delay_cnt;
	
    localparam [3:0] IDLE            = 4'd0,
                     WRITE_I2C       = 4'd1,
                     WAIT_WRITE_DONE = 4'd2,
                     WRITE_DELAY     = 4'd3,
                     READ_I2C        = 4'd4,
                     WAIT_READ_DONE  = 4'd5;
    reg [3:0] state;
    reg [31:0] read_data_reg;
    
    assign read_data = read_data_reg;
    assign ready     = (state == IDLE);
	
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_trans         <= 1'b0;
            addr_reg          <= 12'd0;
            data_write_reg_32 <= 32'd0;
            data_write_byte   <= 8'd0;
            op_is_read        <= 1'b0;
            delay_cnt         <= 24'd0;
            read_data_reg     <= 32'd0;
            data_valid        <= 1'b0;
            byte_idx          <= 2'd0;
            state             <= IDLE;
        end else begin
            data_valid <= 1'b0;
            case(state)
                IDLE: begin
                    if(cmd_write) begin
                        addr_reg          <= mem_addr;
                        data_write_reg_32 <= write_data;
                        op_is_read        <= 1'b0;
                        byte_idx          <= 2'd0;
                        state             <= WRITE_I2C;
                    end else if(cmd_read) begin
                        addr_reg          <= mem_addr;
                        op_is_read        <= 1'b1;
                        state             <= READ_I2C;
                    end
                end
                WRITE_I2C: begin
                    req_trans <= 1'b1;
                    case(byte_idx)
                        2'd0: data_write_byte <= data_write_reg_32[31:24];
                        2'd1: data_write_byte <= data_write_reg_32[23:16];
                        2'd2: data_write_byte <= data_write_reg_32[15:8];
                        2'd3: data_write_byte <= data_write_reg_32[7:0];
                    endcase
                    state <= WAIT_WRITE_DONE;
                end
                WAIT_WRITE_DONE: begin
                    req_trans <= 1'b0;
                    if(!busy && req_trans == 1'b0) begin
                        delay_cnt <= 24'd0;
                        state     <= WRITE_DELAY;
                    end
                end
                WRITE_DELAY: begin
                    if(delay_cnt >= DELAY_10MS_LIMIT - 1) begin
                        if(byte_idx == 2'd3) begin 
                            state <= IDLE;
                        end else begin
                            byte_idx <= byte_idx + 1'b1; 
                            state <= WRITE_I2C;
                        end
                    end else begin
                        delay_cnt <= delay_cnt + 1'b1;
                    end
                end
                READ_I2C: begin
                    req_trans <= 1'b1;
                    state     <= WAIT_READ_DONE;
                end
                WAIT_READ_DONE: begin
                    req_trans <= 1'b0;
                    if(valid_out) begin
                        read_data_reg <= {read_data_reg[23:0], i2c_data_out};
                    end
                    if(!busy && req_trans == 1'b0) begin
                        data_valid <= 1'b1;
                        state      <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule