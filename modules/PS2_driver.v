// https://wiki.osdev.org/PS/2
// https://wiki.osdev.org/PS/2_Keyboard
// https://users.utcluj.ro/~baruch/sie/labor/PS2/Scan_Codes_Set_2.htm

module PS2_Driver(
    input clk,
    input rst_n,
    
    input PS_CLK,
    input PS_DAT,

    output reg pressed, 
    output reg released,
    output reg extended,
    output reg [7:0] data,
    output reg valid
);

    reg [2:0] ps_clk_s;
    reg [1:0] ps_dat_s;

    wire negedge_ps_clk = !ps_clk_s[1] && ps_clk_s[2];
    wire ps_data_safe = ps_dat_s[1];

    reg [3:0] count;
    reg [7:0] get_data;
    reg parity;
    reg is_extended;
    reg is_break;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ps_clk_s <= 3'b111;
            ps_dat_s <= 2'b11;
            count <= 4'd0;
            parity <= 1'b0;
            pressed <= 1'b0;
            released <= 1'b0;
            valid <= 1'b0;
            is_break <= 1'b0;
            extended <= 1'b0;
            is_extended <= 1'b0;
            data <= 8'd0;
            get_data <= 8'd0;
        end else begin
            ps_clk_s <= {ps_clk_s[1:0], PS_CLK};
            ps_dat_s <= {ps_dat_s[0], PS_DAT};

            pressed <= 1'b0;
            released <= 1'b0;
            valid <= 1'b0;

            if (negedge_ps_clk) begin
                if (count == 4'd0) begin
                    if (!ps_data_safe) begin 
                        count <= 4'd1;
                        get_data <= 8'd0;
                        parity <= 1'b0;
                    end
                end else if (count == 4'd9) begin
                    // Parity bit
                    parity <= parity ^ ps_data_safe;
                    count <= 4'd10;
                end else if (count == 4'd10) begin
                    // Stop bit
                    count <= 4'd0;
                    if (parity && ps_data_safe) begin 
                        data <= get_data;
                        
                        if (get_data == 8'hE0) begin
                            is_extended <= 1'b1;
                        end else if (get_data == 8'hF0) begin
                            is_break <= 1'b1;
                        end else begin
                            if (is_break) begin
                                released <= 1'b1;
                                is_break <= 1'b0;
                            end else begin
                                pressed <= 1'b1;
                            end
                            extended <= is_extended;
                            is_extended <= 1'b0;
                            
                            valid <= 1'b1;
                        end
                    end
                end else begin
                    // Data bits (count 1~8)
                    get_data <= {ps_data_safe, get_data[7:1]};
                    parity <= parity ^ ps_data_safe;
                    count <= count + 4'd1;
                end
            end
        end
    end
    
endmodule