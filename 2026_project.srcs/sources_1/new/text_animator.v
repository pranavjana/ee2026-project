`timescale 1ns / 1ps

// Text animator for smooth up/down movement - VERY GENTLE
module text_animator(
    input clk_1ms,
    input reset,
    input enable,
    output reg [2:0] offset  // 0-1 pixels vertical offset (extremely gentle)
);
    reg [7:0] counter = 0;  // 0-99 for ~4 second cycle
    reg direction = 0;  // 0 = moving down, 1 = moving up
    
    always @(posedge clk_1ms or posedge reset) begin
        if (reset || !enable) begin
            counter <= 0;
            direction <= 0;
            offset <= 0;
        end else begin
            // Count up to 99 then down to 0 for VERY slow, gentle motion
            if (direction == 0) begin  // moving down
                if (counter == 99) begin
                    direction <= 1;
                end else begin
                    counter <= counter + 1;
                end
            end else begin  // moving up
                if (counter == 0) begin
                    direction <= 0;
                end else begin
                    counter <= counter - 1;
                end
            end
            
            // Map counter (0-99) to offset (0-1 pixels) - EXTREMELY gentle
            // Only 2 positions: 0 and 1
            offset <= (counter >= 50) ? 3'd1 : 3'd0;
        end
    end
endmodule