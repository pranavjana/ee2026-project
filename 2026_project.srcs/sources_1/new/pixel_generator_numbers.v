`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Pixel Generator with Numbers and Smooth Swap Animation
// Displays 6 numbers (array values) on OLED with sliding swap animation
//////////////////////////////////////////////////////////////////////////////////

module pixel_generator(
    input wire [13:0] pixel_index,        // Pixel index (0 to 6143 for 96*64)
    input wire [7:0] array0,              // Array element 0
    input wire [7:0] array1,              // Array element 1
    input wire [7:0] array2,              // Array element 2
    input wire [7:0] array3,              // Array element 3
    input wire [7:0] array4,              // Array element 4
    input wire [7:0] array5,              // Array element 5
    input wire [2:0] compare_idx1,        // First index being compared
    input wire [2:0] compare_idx2,        // Second index being compared
    input wire swap_flag,                 // High during swap
    input wire [4:0] anim_progress,       // Animation progress (0-15)
    input wire sorting,                   // High when sorting active
    input wire done,                      // High when sort complete
    output reg [15:0] pixel_data          // RGB565 pixel output
);

    // OLED dimensions
    localparam WIDTH = 96;
    localparam HEIGHT = 64;

    // Number positioning
    localparam NUM_WIDTH = 16;   // Width of each number slot
    localparam NUM_HEIGHT = 16;  // Height of each number
    localparam NUM_Y_POS = 24;   // Y position for numbers (centered vertically)

    // RGB565 color definitions
    localparam [15:0] COLOR_BLACK      = 16'h0000;
    localparam [15:0] COLOR_WHITE      = 16'hFFFF;
    localparam [15:0] COLOR_YELLOW     = 16'hFFE0;  // Being compared
    localparam [15:0] COLOR_RED        = 16'hF800;  // Being swapped
    localparam [15:0] COLOR_GREEN      = 16'h07E0;  // Sorted/done

    // Calculate current pixel coordinates from pixel_index
    wire [6:0] x = pixel_index % WIDTH;   // 0-95
    wire [5:0] y = pixel_index / WIDTH;   // 0-63

    // During swap animation, interpolate positions
    // anim_progress goes from 0-15 over the swap duration
    // We need to render BOTH swapping numbers at interpolated positions

    wire is_swapping = swap_flag;
    wire [6:0] swap_offset = (anim_progress * NUM_WIDTH) >> 4;  // 0 to NUM_WIDTH over animation

    // Check if current pixel could be part of either swapping number
    reg [6:0] render_x;  // Adjusted X position for rendering
    reg [2:0] render_slot;  // Which slot to render
    reg [7:0] render_value;  // Value to render

    // Determine what to render at this pixel
    always @(*) begin
        render_x = x;
        render_slot = x / NUM_WIDTH;

        if (is_swapping && ((render_slot == compare_idx1) || (render_slot == compare_idx2))) begin
            // During swap, adjust rendering position
            if (render_slot == compare_idx1) begin
                // First element slides RIGHT
                render_x = x - swap_offset;
            end else begin // compare_idx2
                // Second element slides LEFT
                render_x = x + swap_offset;
            end
        end
    end

    // Recalculate slot based on adjusted position
    wire [2:0] num_slot = render_x / NUM_WIDTH;
    wire [4:0] x_in_slot = render_x % NUM_WIDTH;

    // Are we in the number display region?
    wire in_num_region = (y >= NUM_Y_POS) && (y < (NUM_Y_POS + NUM_HEIGHT));

    // Select the value for this slot
    reg [7:0] slot_value;
    always @(*) begin
        case (num_slot)
            3'd0: slot_value = array0;
            3'd1: slot_value = array1;
            3'd2: slot_value = array2;
            3'd3: slot_value = array3;
            3'd4: slot_value = array4;
            3'd5: slot_value = array5;
            default: slot_value = 8'd0;
        endcase
    end

    // Extract hundreds, tens, ones digits
    wire [3:0] hundreds = slot_value / 100;
    wire [3:0] tens = (slot_value / 10) % 10;
    wire [3:0] ones = slot_value % 10;

    // Simple 5x7 font for digits (only show tens and ones, skip hundreds if 0)
    // Each digit is 5 pixels wide, 7 pixels tall
    function digit_pixel;
        input [3:0] digit;
        input [2:0] px;  // x position within digit (0-4)
        input [2:0] py;  // y position within digit (0-6)
        reg [34:0] pattern;  // 5x7 = 35 bits
        begin
            case (digit)
                4'd0: pattern = 35'b01110_10001_10011_10101_11001_10001_01110;
                4'd1: pattern = 35'b00100_01100_00100_00100_00100_00100_01110;
                4'd2: pattern = 35'b01110_10001_00001_00010_00100_01000_11111;
                4'd3: pattern = 35'b11111_00010_00100_00010_00001_10001_01110;
                4'd4: pattern = 35'b00010_00110_01010_10010_11111_00010_00010;
                4'd5: pattern = 35'b11111_10000_11110_00001_00001_10001_01110;
                4'd6: pattern = 35'b00110_01000_10000_11110_10001_10001_01110;
                4'd7: pattern = 35'b11111_00001_00010_00100_01000_01000_01000;
                4'd8: pattern = 35'b01110_10001_10001_01110_10001_10001_01110;
                4'd9: pattern = 35'b01110_10001_10001_01111_00001_00010_01100;
                default: pattern = 35'b00000_00000_00000_00000_00000_00000_00000;
            endcase
            digit_pixel = pattern[py * 5 + px];
        end
    endfunction

    // Determine number color based on state
    reg [15:0] num_color;
    always @(*) begin
        if (done) begin
            num_color = COLOR_GREEN;
        end else if (swap_flag && ((num_slot == compare_idx1) || (num_slot == compare_idx2))) begin
            num_color = COLOR_RED;
        end else if (sorting && ((num_slot == compare_idx1) || (num_slot == compare_idx2))) begin
            num_color = COLOR_YELLOW;
        end else begin
            num_color = COLOR_WHITE;
        end
    end

    // Render the number
    reg show_pixel;
    wire [5:0] y_in_num = y - NUM_Y_POS;

    always @(*) begin
        pixel_data = COLOR_BLACK;
        show_pixel = 0;

        if (in_num_region && (num_slot < 6)) begin
            // Center the digits within the slot (16 pixels wide)
            // Two digits: 5+1+5 = 11 pixels, centered = offset 2-3
            if (x_in_slot >= 3 && x_in_slot < 14 && y_in_num < 7) begin
                // Show tens digit (positions 3-7)
                if (x_in_slot >= 3 && x_in_slot < 8) begin
                    show_pixel = digit_pixel(tens, x_in_slot - 3, y_in_num[2:0]);
                end
                // Show ones digit (positions 9-13)
                else if (x_in_slot >= 9 && x_in_slot < 14) begin
                    show_pixel = digit_pixel(ones, x_in_slot - 9, y_in_num[2:0]);
                end
            end

            if (show_pixel)
                pixel_data = num_color;
        end

        // Draw status line at bottom
        if (y == 60) begin
            if (done && x >= 32 && x < 64)
                pixel_data = COLOR_GREEN;
            else if (sorting && x >= 32 && x < 64)
                pixel_data = COLOR_YELLOW;
        end
    end

endmodule
