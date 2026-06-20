module bin2bcd (
    input      [7:0]  bin,  // 8-bit binary input (0 to 255)
    output reg [11:0] bcd   // 12-bit BCD output (3 digits: Hundreds, Tens, Ones)
);

    integer i;
    reg [19:0] scratchpad; // Combined width: 12 BCD bits + 8 Binary bits

    always @(*) begin
        // Step 1: Initialize scratchpad with 0s in BCD and the input binary value
        scratchpad = {12'b0, bin};
        
        // Step 2: Loop 8 times (once for each binary bit)
        for (i = 0; i < 8; i = i + 1) begin
            
            // Check and add 3 to any BCD nibble that is >= 5
            // This adjustment must happen BEFORE the final shift of the iteration
            if (scratchpad[11:8] >= 5) 
                scratchpad[11:8] = scratchpad[11:8] + 4'd3;
                
            if (scratchpad[15:12] >= 5) 
                scratchpad[15:12] = scratchpad[15:12] + 4'd3;
                
            if (scratchpad[19:16] >= 5) 
                scratchpad[19:16] = scratchpad[19:16] + 4'd3;
            
            // Step 3: Shift left by 1 bit
            scratchpad = scratchpad << 1;
        end
        
        // Output the resulting BCD portion
        bcd = scratchpad[19:8];
    end

endmodule
