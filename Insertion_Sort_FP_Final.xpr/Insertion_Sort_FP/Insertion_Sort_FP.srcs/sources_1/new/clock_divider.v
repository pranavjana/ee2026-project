`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.10.2025 23:57:50
// Design Name: 
// Module Name: clock_divider
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clock_divider(
    input clk,
    input [31:0] m,
    output reg divided_clk
);
    reg [31:0] count = 0;
    
    always @(posedge clk) begin
        count <= count + 1;
        if (count >= (m-1)) begin
            count <= 0;
            divided_clk <= ~divided_clk;
        end
    end
endmodule
