`timescale 1ns / 1ps
module clock_divider_1ms(
    input clk,
    output reg clk_1ms
);
    reg [16:0] counter = 0;
    
    always @(posedge clk) begin
        if (counter == 17'd49999) begin
            counter <= 0;
            clk_1ms <= ~clk_1ms;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule