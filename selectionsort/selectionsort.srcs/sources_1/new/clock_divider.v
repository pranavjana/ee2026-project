`timescale 1ns / 1ps
module clock_divider(
    input clk,
    input [31:0] m,
    output reg slow_clock
);
    reg [31:0] count = 0;
    
    always @(posedge clk) begin
        if (count == m) begin
            count <= 0;
            slow_clock <= ~slow_clock;
        end else begin
            count <= count + 1;
        end
    end
endmodule
