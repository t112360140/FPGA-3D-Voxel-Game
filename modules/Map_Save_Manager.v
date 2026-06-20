module Map_Save_Manager(
	input clk,
    input rst_n,

    input get_exist,
    input save_map,
    input load_map,
    input remove_map,
    input [2:0] save_slot,

    output reg get_done, save_done, load_done, remove_done,
    output reg save_ok, load_ok,

    output reg [7:0] exist_slot,

    input     [15:0] save_status,
    output reg [7:0] save_ctrl
);

    reg [2:0] state;
    localparam  IDLE      = 3'd0,
                READ      = 3'd1,
                SAVE      = 3'd2,
                LOAD      = 3'd3,
                REMOVE    = 3'd4;

    reg last_ready;
    wire ready=save_status[8];
    wire ok=save_status[9];

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
            save_ctrl <= 8'd0;
            exist_slot <= 8'd0;
            last_ready <= ready;
            get_done <=1'b0; save_done <=1'b0; load_done <=1'b0; remove_done <=1'b0;
            save_ok <=1'b0; load_ok <=1'b0;
        end else begin
            save_ctrl <= 8'd0;
            last_ready <= ready;
            get_done <=1'b0; save_done <=1'b0; load_done <=1'b0; remove_done <=1'b0;
            case(state)
                IDLE: begin
                    if(get_exist) begin
                        save_ctrl <= {5'b01000, save_slot};
                        state <= READ;
                    end else if(save_map) begin
                        save_ctrl <= {5'b00100, save_slot};
                        state <= SAVE;
                    end else if(load_map) begin
                        save_ctrl <= {5'b00010, save_slot};
                        state <= LOAD;
                    end  else if(remove_map) begin
                        save_ctrl <= {5'b00001, save_slot};
                        state <= REMOVE;
                    end
                end
                READ: begin
                    if(ready && !last_ready) begin
                        exist_slot <= save_status[7:0];
                        get_done <=1'b1;
                        state <= IDLE;
                    end
                end
                SAVE: begin
                    if(ready && !last_ready) begin
                        exist_slot <= save_status[7:0];
                        save_done <=1'b1;
                        save_ok <= ok;
                        state <= IDLE;
                    end
                end
                LOAD: begin
                    if(ready && !last_ready) begin
                        load_done <=1'b1;
                        save_ok <= ok;
                        state <= IDLE;
                    end
                end
                REMOVE: begin
                    if(ready && !last_ready) begin
                        exist_slot <= save_status[7:0];
                        remove_done <=1'b1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
