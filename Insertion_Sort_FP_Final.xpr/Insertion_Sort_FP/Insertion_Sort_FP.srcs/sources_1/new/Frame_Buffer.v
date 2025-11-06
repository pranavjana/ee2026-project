`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.10.2025 22:22:32
// Design Name: 
// Module Name: Frame_Buffer
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


//==============================================================================
// Frame_Buffer.v - Dual-Port Block RAM for Screen Storage
//==============================================================================
// Stores the complete 96x64 pixel screen (6144 pixels) with 16-bit color depth.
// Dual-port configuration allows simultaneous writing (from renderer) and
// reading (to OLED driver) without conflicts.
//==============================================================================

//==============================================================================
// Frame_Buffer.v - Fixed Version with Guaranteed Initialization
//==============================================================================

module Frame_Buffer(
    input clk,                  // System clock
    input wr_en,                // Write enable
    input [12:0] wr_addr,       // Write address (0 to 6143)
    input [15:0] wr_data,       // Write data (16-bit RGB565 color)
    input [12:0] rd_addr,       // Read address (0 to 6143)
    output reg [15:0] rd_data   // Read data (16-bit RGB565 color)
);

    //==========================================================================
    // Frame Buffer Memory - Initialize to BLACK
    //==========================================================================
    reg [15:0] buffer_memory [0:6143];
    
    //==========================================================================
    // Write Port
    //==========================================================================
    always @(posedge clk) begin
        if (wr_en) begin
            buffer_memory[wr_addr] <= wr_data;
        end
    end
    
    //==========================================================================
    // Read Port
    //==========================================================================
    always @(posedge clk) begin
        rd_data <= buffer_memory[rd_addr];
    end
    
    //==========================================================================
    // Initialize ALL memory to black (16'h0000)
    //==========================================================================
    integer i;
    initial begin
        for (i = 0; i < 6144; i = i + 1) begin
            buffer_memory[i] = 16'h0000;
        end
    end

endmodule
