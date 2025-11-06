`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.10.2025 22:22:32
// Design Name: 
// Module Name: Clock_Generator
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


module Clock_Generator(
    input clk_100mhz,       // 100MHz input clock
    input reset,            // Synchronous reset
    output reg ce_1mhz,     // 1MHz clock enable pulse
    output reg ce_30hz,     // 30Hz clock enable pulse
    output reg ce_2hz       // 2Hz clock enable pulse
);

    //==========================================================================
    // Counter bit widths calculation
    //==========================================================================
    // For 1MHz: 100MHz / 1MHz = 100 cycles (need 7 bits for count to 99)
    // For 30Hz: 100MHz / 30Hz = 3,333,333 cycles (need 22 bits)
    // For 2Hz: 100MHz / 2Hz = 50,000,000 cycles (need 26 bits)
    
    //==========================================================================
    // 1MHz Clock Enable Generation
    //==========================================================================
    reg [6:0] counter_1mhz;     // Counter for 1MHz (0 to 99)
    
    always @(posedge clk_100mhz) begin
        if (reset) begin
            counter_1mhz <= 0;
            ce_1mhz <= 0;
        end
        else begin
            if (counter_1mhz == 99) begin
                counter_1mhz <= 0;
                ce_1mhz <= 1;       // Pulse high for one cycle every 100 cycles
            end
            else begin
                counter_1mhz <= counter_1mhz + 1;
                ce_1mhz <= 0;
            end
        end
    end
    
    //==========================================================================
    // 30Hz Clock Enable Generation
    //==========================================================================
    reg [21:0] counter_30hz;    // Counter for 30Hz (0 to 3,333,332)
    
    always @(posedge clk_100mhz) begin
        if (reset) begin
            counter_30hz <= 0;
            ce_30hz <= 0;
        end
        else begin
            if (counter_30hz == 3333332) begin
                counter_30hz <= 0;
                ce_30hz <= 1;       // Pulse high once every ~33.33ms
            end
            else begin
                counter_30hz <= counter_30hz + 1;
                ce_30hz <= 0;
            end
        end
    end
    
    //==========================================================================
    // 2Hz Clock Enable Generation
    //==========================================================================
    reg [25:0] counter_2hz;     // Counter for 2Hz (0 to 49,999,999)
    
    always @(posedge clk_100mhz) begin
        if (reset) begin
            counter_2hz <= 0;
            ce_2hz <= 0;
        end
        else begin
            if (counter_2hz == 49999999) begin
                counter_2hz <= 0;
                ce_2hz <= 1;        // Pulse high once every 500ms
            end
            else begin
                counter_2hz <= counter_2hz + 1;
                ce_2hz <= 0;
            end
        end
    end

endmodule
