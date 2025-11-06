`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/22/2025
// Design Name:
// Module Name: tutorial_pixel_generator
// Project Name: Bubble Sort Tutorial
// Target Devices: Basys 3 (Artix-7)
// Tool Versions:
// Description:
//   Pixel generator for bubble sort tutorial mode.
//   Renders array boxes, cursor, progress bar, feedback sprites, and text.
//
//   Display Layout (96×64 OLED):
//   Row 0-6:    Progress bar
//   Row 7-15:   Status text
//   Row 16-26:  Feedback area (checkmark/X)
//   Row 27-42:  Six 14×10 boxes with numbers
//   Row 43-52:  Instruction text
//   Row 53-63:  State info
//
// Dependencies: None
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module tutorial_pixel_generator(
    input wire [13:0] pixel_index,           // Current pixel (0 to 6143)
    input wire [7:0] array0,                 // Array element 0
    input wire [7:0] array1,                 // Array element 1
    input wire [7:0] array2,                 // Array element 2
    input wire [7:0] array3,                 // Array element 3
    input wire [7:0] array4,                 // Array element 4
    input wire [7:0] array5,                 // Array element 5
    input wire [2:0] cursor_pos,             // Cursor position
    input wire [2:0] compare_pos,            // Comparison position
    input wire [4:0] anim_frame,             // Animation frame
    input wire [6:0] progress_percent,       // Progress percentage
    input wire feedback_correct,             // Show green checkmark
    input wire feedback_incorrect,           // Show red X
    input wire is_sorted,                    // Array is sorted
    input wire [3:0] current_state,          // Current FSM state
    output reg [15:0] pixel_data             // RGB565 pixel color
);

    //=========================================================================
    // Internal array reconstruction
    //=========================================================================
    wire [7:0] array [0:5];
    assign array[0] = array0;
    assign array[1] = array1;
    assign array[2] = array2;
    assign array[3] = array3;
    assign array[4] = array4;
    assign array[5] = array5;

    //=========================================================================
    // Color Definitions (RGB565)
    //=========================================================================
    localparam [15:0]
        BLACK   = 16'h0000,
        WHITE   = 16'hFFFF,
        RED     = 16'hF800,
        GREEN   = 16'h07E0,
        BLUE    = 16'h001F,
        YELLOW  = 16'hFFE0,
        CYAN    = 16'h07FF,
        MAGENTA = 16'hF81F,
        ORANGE  = 16'hFC00,
        GRAY    = 16'h7BEF;

    //=========================================================================
    // Display Dimensions
    //=========================================================================
    localparam SCREEN_WIDTH = 96;
    localparam SCREEN_HEIGHT = 64;

    // Box dimensions
    localparam BOX_WIDTH = 14;
    localparam BOX_HEIGHT = 10;
    localparam BOX_SPACING = 2;
    localparam BOX_Y_START = 27;
    localparam BOX_X_START = 1;

    // Progress bar
    localparam PROGRESS_Y_START = 1;
    localparam PROGRESS_Y_END = 5;
    localparam PROGRESS_X_START = 2;
    localparam PROGRESS_X_END = 93;

    //=========================================================================
    // Pixel Coordinates
    //=========================================================================
    wire [6:0] pixel_x = pixel_index % SCREEN_WIDTH;
    wire [5:0] pixel_y = pixel_index / SCREEN_WIDTH;

    //=========================================================================
    // Character ROM (5×7 font for digits 0-7)
    //=========================================================================
    reg [34:0] char_rom [0:7];  // 5×7 = 35 bits per character

    initial begin
        // Character '0'
        char_rom[0] = 35'b01110_10001_10001_10001_10001_10001_01110;
        // Character '1'
        char_rom[1] = 35'b00100_01100_00100_00100_00100_00100_01110;
        // Character '2'
        char_rom[2] = 35'b01110_10001_00001_00010_00100_01000_11111;
        // Character '3'
        char_rom[3] = 35'b01110_10001_00001_00110_00001_10001_01110;
        // Character '4'
        char_rom[4] = 35'b00010_00110_01010_10010_11111_00010_00010;
        // Character '5'
        char_rom[5] = 35'b11111_10000_11110_00001_00001_10001_01110;
        // Character '6'
        char_rom[6] = 35'b00110_01000_10000_11110_10001_10001_01110;
        // Character '7'
        char_rom[7] = 35'b11111_00001_00010_00100_01000_01000_01000;
    end

    //=========================================================================
    // Letter ROM (5×7 font for letters - simplified)
    //=========================================================================
    reg [34:0] letter_rom [0:25];  // 5×7 = 35 bits per letter (A-Z)

    initial begin
        // 'A' = 0
        letter_rom[0]  = 35'b01110_10001_10001_11111_10001_10001_10001;
        // 'C' = 2
        letter_rom[2]  = 35'b01110_10001_10000_10000_10000_10001_01110;
        // 'E' = 4
        letter_rom[4]  = 35'b11111_10000_10000_11110_10000_10000_11111;
        // 'G' = 6
        letter_rom[6]  = 35'b01110_10001_10000_10111_10001_10001_01110;
        // 'I' = 8
        letter_rom[8]  = 35'b01110_00100_00100_00100_00100_00100_01110;
        // 'M' = 12
        letter_rom[12] = 35'b10001_11011_10101_10101_10001_10001_10001;
        // 'N' = 13
        letter_rom[13] = 35'b10001_11001_10101_10011_10001_10001_10001;
        // 'O' = 14
        letter_rom[14] = 35'b01110_10001_10001_10001_10001_10001_01110;
        // 'P' = 15
        letter_rom[15] = 35'b11110_10001_10001_11110_10000_10000_10000;
        // 'R' = 17
        letter_rom[17] = 35'b11110_10001_10001_11110_10100_10010_10001;
        // 'S' = 18
        letter_rom[18] = 35'b01111_10000_10000_01110_00001_00001_11110;
        // 'W' = 22
        letter_rom[22] = 35'b10001_10001_10001_10101_10101_11011_10001;
    end

    //=========================================================================
    // Checkmark Sprite (8×8)
    //=========================================================================
    reg [7:0] checkmark_sprite [0:7];

    initial begin
        checkmark_sprite[0] = 8'b00000000;
        checkmark_sprite[1] = 8'b00000001;
        checkmark_sprite[2] = 8'b00000011;
        checkmark_sprite[3] = 8'b10000110;
        checkmark_sprite[4] = 8'b11001100;
        checkmark_sprite[5] = 8'b01111000;
        checkmark_sprite[6] = 8'b00110000;
        checkmark_sprite[7] = 8'b00000000;
    end

    //=========================================================================
    // X Sprite (8×8)
    //=========================================================================
    reg [7:0] x_sprite [0:7];

    initial begin
        x_sprite[0] = 8'b10000001;
        x_sprite[1] = 8'b11000011;
        x_sprite[2] = 8'b01100110;
        x_sprite[3] = 8'b00111100;
        x_sprite[4] = 8'b00111100;
        x_sprite[5] = 8'b01100110;
        x_sprite[6] = 8'b11000011;
        x_sprite[7] = 8'b10000001;
    end

    //=========================================================================
    // Helper Functions
    //=========================================================================

    // Calculate box X position for element i
    function [6:0] get_box_x;
        input [2:0] i;
        begin
            get_box_x = BOX_X_START + i * (BOX_WIDTH + BOX_SPACING);
        end
    endfunction

    // Check if pixel is in box i
    function is_in_box;
        input [6:0] x;
        input [5:0] y;
        input [2:0] i;
        reg [6:0] box_x;
        begin
            box_x = get_box_x(i);
            is_in_box = (x >= box_x && x < box_x + BOX_WIDTH &&
                        y >= BOX_Y_START && y < BOX_Y_START + BOX_HEIGHT);
        end
    endfunction

    // Check if pixel is on box border
    function is_box_border;
        input [6:0] x;
        input [5:0] y;
        input [2:0] i;
        reg [6:0] box_x;
        begin
            box_x = get_box_x(i);
            is_box_border = (x >= box_x && x < box_x + BOX_WIDTH &&
                           y >= BOX_Y_START && y < BOX_Y_START + BOX_HEIGHT &&
                           (x == box_x || x == box_x + BOX_WIDTH - 1 ||
                            y == BOX_Y_START || y == BOX_Y_START + BOX_HEIGHT - 1));
        end
    endfunction

    // Get character pixel for digit
    function get_char_pixel;
        input [2:0] digit;
        input [2:0] char_x;
        input [2:0] char_y;
        reg [4:0] row_data;
        begin
            row_data = char_rom[digit][34 - char_y * 5 -: 5];
            get_char_pixel = row_data[4 - char_x];
        end
    endfunction

    // Get letter pixel (A-Z mapped to 0-25)
    function get_letter_pixel;
        input [4:0] letter_index;  // 0=A, 2=C, 4=E, etc.
        input [2:0] char_x;
        input [2:0] char_y;
        reg [4:0] row_data;
        begin
            row_data = letter_rom[letter_index][34 - char_y * 5 -: 5];
            get_letter_pixel = row_data[4 - char_x];
        end
    endfunction

    //=========================================================================
    // Main Pixel Generation Logic
    //=========================================================================
    integer i;
    reg [6:0] box_x;
    reg [6:0] box_inner_x;
    reg [5:0] box_inner_y;
    reg [2:0] char_x;
    reg [2:0] char_y;
    reg char_pixel;
    reg [15:0] box_color;
    reg [6:0] progress_width;
    reg in_feedback_area;
    reg [6:0] feedback_x;
    reg [5:0] feedback_y;
    reg [2:0] sprite_x;
    reg [2:0] sprite_y;
    reg sprite_pixel;
    reg [7:0] anim_offset_x;
    reg [6:0] swap_box_x;

    always @(*) begin
        // Default: black background
        pixel_data = BLACK;

        //=====================================================================
        // Progress Bar (Row 1-5)
        //=====================================================================
        if (pixel_y >= PROGRESS_Y_START && pixel_y <= PROGRESS_Y_END &&
            pixel_x >= PROGRESS_X_START && pixel_x <= PROGRESS_X_END) begin

            // Calculate progress bar filled width
            progress_width = ((PROGRESS_X_END - PROGRESS_X_START) * progress_percent) / 100;

            // Border
            if (pixel_y == PROGRESS_Y_START || pixel_y == PROGRESS_Y_END ||
                pixel_x == PROGRESS_X_START || pixel_x == PROGRESS_X_END) begin
                pixel_data = WHITE;
            end
            // Filled portion
            else if (pixel_x < PROGRESS_X_START + progress_width) begin
                pixel_data = GREEN;
            end
            // Empty portion
            else begin
                pixel_data = GRAY;
            end
        end

        //=====================================================================
        // Status Text (Row 7-15) - Simple state indicator
        //=====================================================================
        else if (pixel_y >= 8 && pixel_y <= 14 && pixel_x >= 30 && pixel_x <= 65) begin
            // Display state-dependent text using simple pixel patterns
            // For simplicity, just show colored bar indicating state
            case (current_state)
                4'd0, 4'd1: pixel_data = CYAN;     // Setup
                4'd2: pixel_data = YELLOW;          // Confirm
                4'd3, 4'd4, 4'd5: pixel_data = ORANGE; // Tutorial
                4'd6: pixel_data = RED;             // Swapping
                4'd7: pixel_data = feedback_correct ? GREEN : RED; // Feedback
                4'd9: pixel_data = MAGENTA;         // Complete
                default: pixel_data = BLUE;
            endcase
        end

        //=====================================================================
        // Feedback Sprites (Row 16-26) - Checkmark or X
        //=====================================================================
        in_feedback_area = (pixel_y >= 18 && pixel_y < 26 &&
                           pixel_x >= 44 && pixel_x < 52);

        if (in_feedback_area && (feedback_correct || feedback_incorrect)) begin
            sprite_x = pixel_x - 44;
            sprite_y = pixel_y - 18;

            if (feedback_correct) begin
                sprite_pixel = checkmark_sprite[sprite_y][7 - sprite_x];
                if (sprite_pixel) begin
                    pixel_data = GREEN;
                end
            end else if (feedback_incorrect) begin
                sprite_pixel = x_sprite[sprite_y][7 - sprite_x];
                if (sprite_pixel) begin
                    pixel_data = RED;
                end
            end
        end

        //=====================================================================
        // Array Boxes (Row 27-42)
        //=====================================================================
        if (pixel_y >= BOX_Y_START && pixel_y < BOX_Y_START + BOX_HEIGHT) begin
            for (i = 0; i < 6; i = i + 1) begin
                if (is_in_box(pixel_x, pixel_y, i)) begin
                    box_x = get_box_x(i);
                    box_inner_x = pixel_x - box_x;
                    box_inner_y = pixel_y - BOX_Y_START;

                    // Determine box color based on state
                    box_color = WHITE;

                    // Cursor highlight (CYAN) in setup mode
                    if ((current_state == 4'd1) && (i == cursor_pos)) begin
                        box_color = CYAN;
                    end
                    // Selected pair (YELLOW) in tutorial mode
                    else if ((current_state == 4'd3 || current_state == 4'd4 || current_state == 4'd5) &&
                            (i == cursor_pos || i == compare_pos)) begin
                        box_color = YELLOW;
                    end
                    // Swapping (RED) during animation
                    else if (current_state == 4'd6 &&
                            (i == cursor_pos || i == compare_pos)) begin
                        box_color = RED;
                    end
                    // Sorted elements (GREEN) - simple heuristic: rightmost elements
                    else if (is_sorted) begin
                        box_color = GREEN;
                    end

                    // Draw box border (3 pixels thick for cursor in setup)
                    if ((current_state == 4'd1) && (i == cursor_pos)) begin
                        // Thick border for cursor
                        if (box_inner_x < 2 || box_inner_x >= BOX_WIDTH - 2 ||
                            box_inner_y < 2 || box_inner_y >= BOX_HEIGHT - 2) begin
                            pixel_data = box_color;
                        end
                    end else begin
                        // Normal border (1 pixel)
                        if (is_box_border(pixel_x, pixel_y, i)) begin
                            pixel_data = box_color;
                        end
                    end

                    // Draw number inside box (centered)
                    // Character is 5×7, box is 14×10
                    // Center position: (14-5)/2 = 4.5 ≈ 4, (10-7)/2 = 1.5 ≈ 2
                    if (box_inner_x >= 4 && box_inner_x < 9 &&
                        box_inner_y >= 2 && box_inner_y < 9) begin

                        char_x = box_inner_x - 4;
                        char_y = box_inner_y - 2;
                        char_pixel = get_char_pixel(array[i][2:0], char_x, char_y);

                        if (char_pixel) begin
                            pixel_data = BLACK;  // Number in black
                        end else if (!is_box_border(pixel_x, pixel_y, i)) begin
                            // In setup mode (states 0,1,2), use WHITE background for all boxes
                            if (current_state <= 4'd2) begin
                                pixel_data = WHITE;
                            end else begin
                                pixel_data = box_color;  // Background color
                            end
                        end
                    end else if (!is_box_border(pixel_x, pixel_y, i)) begin
                        // Fill rest of box interior
                        if (current_state <= 4'd2) begin
                            pixel_data = WHITE;  // Setup mode: white background
                        end else begin
                            pixel_data = box_color;
                        end
                    end
                end
            end
        end

        //=====================================================================
        // Instruction Text (Row 43-52) - Shows "COMPARE: X Y" or "SWAPPING!"
        //=====================================================================
        else if (pixel_y >= 44 && pixel_y <= 52) begin
            if (current_state == 4'd6) begin
                // TUTORIAL_SWAP_ANIM - Display "SWAPPING!" in red
                // S W A P P I N G !
                // Positions: 10, 16, 22, 28, 34, 40, 46, 52, 58
                if (pixel_y >= 45 && pixel_y <= 51) begin
                    char_y = pixel_y - 45;
                    if (pixel_x >= 10 && pixel_x <= 14) begin
                        // 'S'
                        char_x = pixel_x - 10;
                        char_pixel = get_letter_pixel(18, char_x, char_y);
                        pixel_data = char_pixel ? WHITE : RED;
                    end
                    else if (pixel_x >= 16 && pixel_x <= 20) begin
                        // 'W'
                        char_x = pixel_x - 16;
                        char_pixel = get_letter_pixel(22, char_x, char_y);
                        pixel_data = char_pixel ? WHITE : RED;
                    end
                    else if (pixel_x >= 22 && pixel_x <= 26) begin
                        // 'A'
                        char_x = pixel_x - 22;
                        char_pixel = get_letter_pixel(0, char_x, char_y);
                        pixel_data = char_pixel ? WHITE : RED;
                    end
                    else if (pixel_x >= 28 && pixel_x <= 32) begin
                        // 'P'
                        char_x = pixel_x - 28;
                        char_pixel = get_letter_pixel(15, char_x, char_y);
                        pixel_data = char_pixel ? WHITE : RED;
                    end
                    else if (pixel_x >= 34 && pixel_x <= 38) begin
                        // 'P'
                        char_x = pixel_x - 34;
                        char_pixel = get_letter_pixel(15, char_x, char_y);
                        pixel_data = char_pixel ? WHITE : RED;
                    end
                    else if (pixel_x >= 40 && pixel_x <= 44) begin
                        // 'I'
                        char_x = pixel_x - 40;
                        char_pixel = get_letter_pixel(8, char_x, char_y);
                        pixel_data = char_pixel ? WHITE : RED;
                    end
                    else if (pixel_x >= 46 && pixel_x <= 50) begin
                        // 'N'
                        char_x = pixel_x - 46;
                        char_pixel = get_letter_pixel(13, char_x, char_y);
                        pixel_data = char_pixel ? WHITE : RED;
                    end
                    else if (pixel_x >= 52 && pixel_x <= 56) begin
                        // 'G'
                        char_x = pixel_x - 52;
                        char_pixel = get_letter_pixel(6, char_x, char_y);
                        pixel_data = char_pixel ? WHITE : RED;
                    end
                    else begin
                        pixel_data = RED;
                    end
                end else begin
                    pixel_data = RED;
                end
            end
            else if (current_state == 4'd3 || current_state == 4'd4 || current_state == 4'd5) begin
                // TUTORIAL_SELECT, TUTORIAL_COMPARE, TUTORIAL_AWAIT_SWAP
                // Display "COMPARE: X Y" (no background, just letters)
                if (pixel_y >= 45 && pixel_y <= 51) begin
                    char_y = pixel_y - 45;

                    // C O M P A R E :
                    if (pixel_x >= 2 && pixel_x <= 6) begin
                        // 'C'
                        char_x = pixel_x - 2;
                        char_pixel = get_letter_pixel(2, char_x, char_y);
                        if (char_pixel) pixel_data = WHITE;
                    end
                    else if (pixel_x >= 8 && pixel_x <= 12) begin
                        // 'O'
                        char_x = pixel_x - 8;
                        char_pixel = get_letter_pixel(14, char_x, char_y);
                        if (char_pixel) pixel_data = WHITE;
                    end
                    else if (pixel_x >= 14 && pixel_x <= 18) begin
                        // 'M'
                        char_x = pixel_x - 14;
                        char_pixel = get_letter_pixel(12, char_x, char_y);
                        if (char_pixel) pixel_data = WHITE;
                    end
                    else if (pixel_x >= 20 && pixel_x <= 24) begin
                        // 'P'
                        char_x = pixel_x - 20;
                        char_pixel = get_letter_pixel(15, char_x, char_y);
                        if (char_pixel) pixel_data = WHITE;
                    end
                    else if (pixel_x >= 26 && pixel_x <= 30) begin
                        // 'A'
                        char_x = pixel_x - 26;
                        char_pixel = get_letter_pixel(0, char_x, char_y);
                        if (char_pixel) pixel_data = WHITE;
                    end
                    else if (pixel_x >= 32 && pixel_x <= 36) begin
                        // 'R'
                        char_x = pixel_x - 32;
                        char_pixel = get_letter_pixel(17, char_x, char_y);
                        if (char_pixel) pixel_data = WHITE;
                    end
                    else if (pixel_x >= 38 && pixel_x <= 42) begin
                        // 'E'
                        char_x = pixel_x - 38;
                        char_pixel = get_letter_pixel(4, char_x, char_y);
                        if (char_pixel) pixel_data = WHITE;
                    end
                    else if (pixel_x >= 44 && pixel_x <= 45) begin
                        // ':'
                        if (char_y == 2 || char_y == 4) begin
                            pixel_data = WHITE;
                        end
                    end
                    // First number at x: 48-52
                    else if (pixel_x >= 48 && pixel_x <= 52) begin
                        char_x = pixel_x - 48;
                        char_pixel = get_char_pixel(array[cursor_pos][2:0], char_x, char_y);
                        if (char_pixel) pixel_data = YELLOW;
                    end
                    // Second number at x: 56-60
                    else if (pixel_x >= 56 && pixel_x <= 60) begin
                        char_x = pixel_x - 56;
                        char_pixel = get_char_pixel(array[compare_pos][2:0], char_x, char_y);
                        if (char_pixel) pixel_data = YELLOW;
                    end
                end
            end
        end

        //=====================================================================
        // Background Pattern (dots)
        //=====================================================================
        else if (pixel_data == BLACK) begin
            // Add subtle dot pattern to background
            if ((pixel_x % 8 == 0) && (pixel_y % 8 == 0)) begin
                pixel_data = BLUE;
            end
        end

        //=====================================================================
        // Swap Animation Effect
        //=====================================================================
        if (current_state == 4'd6 && anim_frame < 16) begin
            // Add visual effect during swap (could be enhanced)
            // For now, pulsate the swapping boxes
            if ((pixel_y >= BOX_Y_START && pixel_y < BOX_Y_START + BOX_HEIGHT) &&
                (is_in_box(pixel_x, pixel_y, cursor_pos) ||
                 is_in_box(pixel_x, pixel_y, compare_pos))) begin

                // Pulsate effect - alternate frames
                if (anim_frame % 2 == 0 && !is_box_border(pixel_x, pixel_y, cursor_pos) &&
                    !is_box_border(pixel_x, pixel_y, compare_pos)) begin
                    pixel_data = MAGENTA;  // Flash color
                end
            end
        end

        //=====================================================================
        // Celebration Animation (when sorted)
        //=====================================================================
        if (current_state == 4'd9) begin
            // Rainbow cycling through all boxes
            if (pixel_y >= BOX_Y_START && pixel_y < BOX_Y_START + BOX_HEIGHT) begin
                for (i = 0; i < 6; i = i + 1) begin
                    if (is_in_box(pixel_x, pixel_y, i)) begin
                        case ((anim_frame + i) % 6)
                            0: box_color = RED;
                            1: box_color = ORANGE;
                            2: box_color = YELLOW;
                            3: box_color = GREEN;
                            4: box_color = CYAN;
                            5: box_color = MAGENTA;
                            default: box_color = WHITE;
                        endcase

                        if (!is_box_border(pixel_x, pixel_y, i)) begin
                            pixel_data = box_color;
                        end
                    end
                end
            end
        end
    end

endmodule
