`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Pixel Generator for OLED Bubble Sort Visualization
// Generates 16-bit RGB565 pixel data for 96x64 OLED display
// Displays 6 bars representing array values with highlighting
//
// RGB565 Format: RRRRR GGGGGG BBBBB
// Display Layout: 6 bars, each 14 pixels wide + 2 pixel spacing = 96 pixels
// Bar heights scaled from array values (0-255) to display height (0-60)
//////////////////////////////////////////////////////////////////////////////////

module pixel_generator(
    input wire [13:0] pixel_index,        // Pixel index (0 to 6143 for 96*64)
    input wire [7:0] array [0:5],         // Array values to visualize
    input wire [2:0] compare_idx1,        // First index being compared
    input wire [2:0] compare_idx2,        // Second index being compared
    input wire swap_flag,                 // High during swap
    input wire sorting,                   // High when sorting active
    input wire done,                      // High when sort complete
    output reg [15:0] pixel_data          // RGB565 pixel output
);

    // OLED dimensions
    localparam WIDTH = 96;
    localparam HEIGHT = 64;

    // Bar dimensions
    localparam BAR_WIDTH = 14;
    localparam BAR_SPACING = 2;
    localparam BAR_TOTAL = BAR_WIDTH + BAR_SPACING;  // 16 pixels per bar slot

    // Display area for bars (leave 4 pixels at bottom for status)
    localparam BAR_HEIGHT_MAX = 60;

    // RGB565 color definitions
    localparam [15:0] COLOR_BLACK      = 16'h0000;
    localparam [15:0] COLOR_BLUE       = 16'h001F;  // Normal bars
    localparam [15:0] COLOR_YELLOW     = 16'hFFE0;  // Being compared
    localparam [15:0] COLOR_RED        = 16'hF800;  // Being swapped
    localparam [15:0] COLOR_GREEN      = 16'h07E0;  // Sorted/done
    localparam [15:0] COLOR_WHITE      = 16'hFFFF;  // Text/border
    localparam [15:0] COLOR_DARK_GRAY  = 16'h39E7;  // Background elements

    // Calculate current pixel coordinates from pixel_index
    wire [6:0] x = pixel_index % WIDTH;   // 0-95
    wire [5:0] y = pixel_index / WIDTH;   // 0-63

    // Determine which bar this pixel belongs to (0-5)
    wire [2:0] bar_num = x / BAR_TOTAL;

    // Position within the bar slot
    wire [3:0] x_in_slot = x % BAR_TOTAL;

    // Is this pixel in a bar (not in spacing)?
    wire in_bar = (x_in_slot < BAR_WIDTH) && (bar_num < 6);

    // Calculate bar height for this bar number (scale 0-255 to 0-60)
    wire [7:0] bar_value = array[bar_num];
    wire [5:0] bar_height = (bar_value * BAR_HEIGHT_MAX) / 255;

    // Calculate y position from bottom (0 at bottom, 63 at top)
    wire [5:0] y_from_bottom = BAR_HEIGHT_MAX - y;

    // Is this pixel part of the bar (filled portion)?
    wire in_bar_filled = in_bar && (y_from_bottom < bar_height);

    // Determine bar color based on state
    reg [15:0] bar_color;

    always @(*) begin
        if (done) begin
            // All bars green when done
            bar_color = COLOR_GREEN;
        end else if (swap_flag && ((bar_num == compare_idx1) || (bar_num == compare_idx2))) begin
            // Red when being swapped
            bar_color = COLOR_RED;
        end else if (sorting && ((bar_num == compare_idx1) || (bar_num == compare_idx2))) begin
            // Yellow when being compared
            bar_color = COLOR_YELLOW;
        end else begin
            // Blue for normal state
            bar_color = COLOR_BLUE;
        end
    end

    // Generate pixel data
    always @(*) begin
        // Default to black background
        pixel_data = COLOR_BLACK;

        // Bar region (top 60 rows)
        if (y < BAR_HEIGHT_MAX) begin
            if (in_bar_filled) begin
                pixel_data = bar_color;
            end else if (in_bar && (y_from_bottom == bar_height) && (bar_height > 0)) begin
                // Draw white top edge of bar
                pixel_data = COLOR_WHITE;
            end
        end
        // Status indicator region (bottom 4 rows)
        else begin
            if (done) begin
                // Draw "DONE" indicator - simple line pattern
                if (y == 61 && x >= 32 && x < 64)
                    pixel_data = COLOR_GREEN;
            end else if (sorting) begin
                // Draw "SORT" indicator - simple line pattern
                if (y == 61 && x >= 32 && x < 64)
                    pixel_data = COLOR_YELLOW;
            end else begin
                // Draw "IDLE" indicator
                if (y == 61 && x >= 40 && x < 56)
                    pixel_data = COLOR_DARK_GRAY;
            end
        end

        // Draw baseline at y=60
        if (y == BAR_HEIGHT_MAX) begin
            pixel_data = COLOR_WHITE;
        end
    end

endmodule
