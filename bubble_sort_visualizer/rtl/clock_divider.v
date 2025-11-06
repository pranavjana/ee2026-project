`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Clock Divider Module for OLED Bubble Sort Visualizer
// Generates multiple clock signals from 100 MHz input:
//   - 6.25 MHz clock for OLED Display module
//   - 1 Hz pulse for bubble sort operations
//////////////////////////////////////////////////////////////////////////////////

module clock_divider(
    input wire clk_100mhz,     // 100 MHz input clock
    input wire rst,            // Active high reset
    output reg clk_6p25mhz,    // 6.25 MHz clock for OLED
    output reg clk_1hz_pulse   // 1 Hz pulse for sort operations
);

    // Counter for 6.25 MHz clock (divide by 16: 100MHz / 16 = 6.25MHz)
    reg [3:0] counter_6p25mhz;

    // Counter for 1 Hz pulse (divide by 100,000,000)
    // Need 27 bits to count to 100,000,000 (2^27 = 134,217,728)
    reg [26:0] counter_1hz;

    // 6.25 MHz clock generation (divide 100 MHz by 16)
    always @(posedge clk_100mhz or posedge rst) begin
        if (rst) begin
            counter_6p25mhz <= 0;
            clk_6p25mhz <= 0;
        end else begin
            if (counter_6p25mhz == 4'd7) begin
                counter_6p25mhz <= 0;
                clk_6p25mhz <= ~clk_6p25mhz;  // Toggle every 8 cycles = 6.25 MHz
            end else begin
                counter_6p25mhz <= counter_6p25mhz + 1;
            end
        end
    end

    // 1 Hz pulse generation (100,000,000 cycles = 1 second)
    // Generates a single-cycle pulse every second
    always @(posedge clk_100mhz or posedge rst) begin
        if (rst) begin
            counter_1hz <= 0;
            clk_1hz_pulse <= 0;
        end else begin
            if (counter_1hz == 27'd99_999_999) begin
                counter_1hz <= 0;
                clk_1hz_pulse <= 1;  // Single cycle pulse
            end else begin
                counter_1hz <= counter_1hz + 1;
                clk_1hz_pulse <= 0;
            end
        end
    end

endmodule
