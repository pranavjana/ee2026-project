`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Simple Pixel Generator - Numbers Only (No Bars)
// Displays 6 numbers representing array values
//////////////////////////////////////////////////////////////////////////////////

module pixel_generator(
    input wire [13:0] pixel_index,
    input wire [7:0] array0, array1, array2, array3, array4, array5,
    input wire [2:0] compare_idx1, compare_idx2,
    input wire swap_flag,
    input wire [5:0] anim_progress,    // Animation progress (0-59 within each phase)
    input wire [1:0] anim_phase,       // Animation phase (0-3)
    input wire sorting,
    input wire done,
    output reg [15:0] pixel_data
);

    localparam WIDTH = 96;
    localparam HEIGHT = 64;

    // Display specifications
    localparam BOX_WIDTH = 14;      // Box width including border
    localparam BOX_HEIGHT = 10;     // Box height including border
    localparam BOX_SPACING = 2;     // Horizontal spacing between boxes
    localparam NUM_WIDTH = 6;       // Number width (was 5, now 6)
    localparam NUM_HEIGHT = 8;      // Number height (was 7, now 8)
    localparam BOX_TOTAL = BOX_WIDTH + BOX_SPACING;  // 16 pixels per box slot

    // Center array horizontally on display
    // Total width needed: 6 boxes * 14 pixels + 5 spacings * 2 pixels = 84 + 10 = 94 pixels
    // But using BOX_TOTAL: 6 boxes * 16 = 96 pixels (last spacing included)
    // We want: 6 * 14 + 5 * 2 = 94 pixels
    // Centering offset: (96 - 94) / 2 = 1 pixel
    localparam ARRAY_WIDTH = 6 * BOX_WIDTH + 5 * BOX_SPACING;  // 94 pixels
    localparam ARRAY_X_OFFSET = (WIDTH - ARRAY_WIDTH) / 2;      // 1 pixel offset

    // RGB565 colors
    localparam [15:0] BLACK  = 16'h0000;
    localparam [15:0] WHITE  = 16'hFFFF;
    localparam [15:0] YELLOW = 16'hFFE0;
    localparam [15:0] RED    = 16'hF800;
    localparam [15:0] GREEN  = 16'h07E0;
    localparam [15:0] BLUE   = 16'h001F;  // Pure blue

    wire [6:0] x = pixel_index % WIDTH;
    wire [5:0] y = pixel_index / WIDTH;

    // Background dot pattern generation
    wire background_dot;
    wire [15:0] background_pixel_color;

    // Create dot pattern - dots every 8 pixels in both X and Y
    // Dots appear where x_coordinate[2:0] == 0 AND y_coordinate[2:0] == 0
    // Positions: (0,0), (8,0), (16,0), (8,8), (16,8), etc.
    assign background_dot = (x[2:0] == 3'b000) && (y[2:0] == 3'b000);

    // Background color: blue dots on black background
    assign background_pixel_color = background_dot ? BLUE : BLACK;

    // Variables for rendering (will be set in the rendering loop)
    reg [7:0] value;
    reg [3:0] digit;

    // 6x8 font bitmap (48 bits per character)
    function digit_pixel;
        input [3:0] digit;
        input [2:0] px, py;  // px: 0-5, py: 0-7
        reg [47:0] font;
        reg [2:0] flipped_py;
        begin
            flipped_py = 7 - py;  // Flip vertically for 8 rows
            case (digit)
                0: font = 48'b011100_100010_100010_100010_100010_100010_100010_011100;
                1: font = 48'b001000_011000_001000_001000_001000_001000_001000_011100;
                2: font = 48'b011100_100010_000010_000100_001000_010000_100000_111110;
                3: font = 48'b111110_000010_000100_001000_000100_000010_100010_011100;
                4: font = 48'b000100_001100_010100_100100_111110_000100_000100_000100;
                5: font = 48'b111110_100000_100000_111100_000010_000010_100010_011100;
                6: font = 48'b001100_010000_100000_111100_100010_100010_100010_011100;
                7: font = 48'b111110_000010_000100_001000_010000_010000_010000_010000;
                8: font = 48'b011100_100010_100010_011100_100010_100010_100010_011100;
                9: font = 48'b011100_100010_100010_100010_011110_000010_000100_011000;
                default: font = 0;
            endcase
            digit_pixel = font[flipped_py * 6 + (5 - px)];  // Flip horizontally (6 pixels wide)
        end
    endfunction

    //=========================================================================
    // Letter ROM for "BUBBLE SORT!" (5×7 font)
    //=========================================================================
    reg [34:0] letter_rom [0:25];  // A-Z

    initial begin
        // B = 1
        letter_rom[1]  = 35'b11110_10001_10001_11110_10001_10001_11110;
        // E = 4
        letter_rom[4]  = 35'b11111_10000_10000_11110_10000_10000_11111;
        // L = 11
        letter_rom[11] = 35'b10000_10000_10000_10000_10000_10000_11111;
        // O = 14
        letter_rom[14] = 35'b01110_10001_10001_10001_10001_10001_01110;
        // R = 17
        letter_rom[17] = 35'b11110_10001_10001_11110_10100_10010_10001;
        // S = 18
        letter_rom[18] = 35'b01111_10000_10000_01110_00001_00001_11110;
        // T = 19
        letter_rom[19] = 35'b11111_00100_00100_00100_00100_00100_00100;
        // U = 20
        letter_rom[20] = 35'b10001_10001_10001_10001_10001_10001_01110;
    end

    // Get letter pixel (same as tutorial mode)
    function get_letter_pixel;
        input [4:0] letter_index;  // B=1, U=20, B=1, B=1, L=11, E=4, etc
        input [2:0] char_x;
        input [2:0] char_y;
        reg [4:0] row_data;
        begin
            row_data = letter_rom[letter_index][34 - char_y * 5 -: 5];
            get_letter_pixel = row_data[4 - char_x];  // Match tutorial mode exactly
        end
    endfunction

    // Render boxes with borders and centered numbers
    reg [15:0] color;
    reg show_pixel;
    reg is_border;
    reg [3:0] x_in_box;
    reg [5:0] y_in_box;
    reg [3:0] num_x_start;
    reg [3:0] num_y_start;
    reg box_active;

    // Variables for "BUBBLE SORT!" text rendering
    reg [1:0] bounce_offset;  // Bounce offset for text animation (0-3)
    reg [3:0] char_idx;  // Which character (0-11) in "BUBBLE SORT!"
    reg [2:0] char_x, char_y;
    reg [4:0] letter_code;  // Letter index (A=0, B=1, ..., Z=25)
    reg show_letter;

    // Box vertical positioning (centered on screen)
    localparam BOX_Y_START = (HEIGHT - BOX_HEIGHT) / 2;  // ~27
    localparam BOX_Y_END = BOX_Y_START + BOX_HEIGHT;     // ~37

    // Text rendering parameters for "BUBBLE SORT!" message
    localparam TEXT_WIDTH = 60;  // 12 chars × 5 pixels
    localparam TEXT_X_START = (WIDTH - TEXT_WIDTH) / 2;  // Center horizontally
    localparam TEXT_Y_BASE = BOX_Y_START + BOX_HEIGHT + 4;  // Below boxes with spacing
    localparam CHAR_HEIGHT = 7;  // 5×7 font

    // Animation parameters
    localparam ANIM_UP_DISTANCE = 16;    // How far up to move in phase 0
    localparam ANIM_FRAMES_PER_PHASE = 30; // Frames per animation phase (must match FSM)
    // Scaling: anim_progress goes 0-29, we want offset 0-16 pixels

    // Pre-calculated box positions for each box (with animation offsets applied)
    reg [7:0] box_x_pos [0:5];  // X position of each box
    reg [6:0] box_y_pos [0:5];  // Y position of each box
    integer k;

    // Calculate box positions with animation offsets
    // Scale anim_progress (0-29) to match BOX_TOTAL (16 pixels)
    // At the last few frames, clamp to exactly BOX_TOTAL for smooth transitions
    wire [9:0] scaled_calc = (anim_progress * 17) >> 5;  // Calculate scaled value (30 frames -> 16 pixels)
    wire [5:0] scaled_progress = (anim_progress >= 28) ? BOX_TOTAL : scaled_calc[5:0];

    always @(*) begin
        // Initialize all boxes to their default positions
        for (k = 0; k < 6; k = k + 1) begin
            box_x_pos[k] = ARRAY_X_OFFSET + k * BOX_TOTAL;
            box_y_pos[k] = BOX_Y_START;
        end

        // Apply animation offsets when swapping - maintaining continuity between phases
        if (swap_flag) begin
            case (anim_phase)
                2'b00: begin  // Phase 0: compare_idx1 moves UP (from 0 to ANIM_UP_DISTANCE)
                    box_y_pos[compare_idx1] = BOX_Y_START - scaled_progress;
                    // X position stays at original (already set in initialization)
                end

                2'b01: begin  // Phase 1: compare_idx1 stays UP, compare_idx2 moves LEFT
                    box_y_pos[compare_idx1] = BOX_Y_START - ANIM_UP_DISTANCE;  // Keep fully elevated
                    box_x_pos[compare_idx1] = ARRAY_X_OFFSET + compare_idx1 * BOX_TOTAL;  // Explicitly maintain X
                    box_x_pos[compare_idx2] = (ARRAY_X_OFFSET + compare_idx2 * BOX_TOTAL) - scaled_progress;  // Move left 0->16
                end

                2'b10: begin  // Phase 2: compare_idx1 moves RIGHT (still elevated), compare_idx2 stays LEFT
                    box_y_pos[compare_idx1] = BOX_Y_START - ANIM_UP_DISTANCE;  // Keep fully elevated
                    box_x_pos[compare_idx1] = (ARRAY_X_OFFSET + compare_idx1 * BOX_TOTAL) + scaled_progress;  // Move right 0->16
                    box_x_pos[compare_idx2] = (ARRAY_X_OFFSET + compare_idx2 * BOX_TOTAL) - BOX_TOTAL;  // Stay at final left position
                end

                2'b11: begin  // Phase 3: compare_idx1 moves DOWN to final position
                    box_x_pos[compare_idx1] = (ARRAY_X_OFFSET + compare_idx1 * BOX_TOTAL) + BOX_TOTAL;  // Keep at final right position
                    box_y_pos[compare_idx1] = (BOX_Y_START - ANIM_UP_DISTANCE) + scaled_progress;  // Move down 0->16
                    box_x_pos[compare_idx2] = (ARRAY_X_OFFSET + compare_idx2 * BOX_TOTAL) - BOX_TOTAL;  // Stay at final left position
                end
            endcase
        end
    end

    // Render all boxes using pre-calculated positions
    // Use explicit checks instead of loop for better synthesis
    always @(*) begin
        pixel_data = background_pixel_color;
        show_pixel = 0;
        is_border = 0;
        box_active = 0;
        value = 0;
        digit = 0;
        color = WHITE;
        x_in_box = 0;
        y_in_box = 0;
        num_x_start = 1 + 3;
        num_y_start = 1;

        // Text rendering variable initialization
        bounce_offset = 0;
        char_idx = 0;
        char_x = 0;
        char_y = 0;
        letter_code = 0;
        show_letter = 0;

        // Check each box explicitly (check in reverse order so box 0 has highest priority)
        // Box 5
        if (x >= box_x_pos[5] && x < (box_x_pos[5] + BOX_WIDTH) &&
            y >= box_y_pos[5] && y < (box_y_pos[5] + BOX_HEIGHT)) begin
            value = array5;
            digit = (value < 10) ? value[3:0] : (value % 10);
            color = done ? GREEN : (swap_flag && ((5 == compare_idx1) || (5 == compare_idx2))) ? RED :
                    (sorting && ((5 == compare_idx1) || (5 == compare_idx2))) ? YELLOW : WHITE;
            x_in_box = x - box_x_pos[5];
            y_in_box = y - box_y_pos[5];
            if (x_in_box >= num_x_start && x_in_box < (num_x_start + NUM_WIDTH) &&
                y_in_box >= num_y_start && y_in_box < (num_y_start + NUM_HEIGHT)) begin
                show_pixel = digit_pixel(digit, x_in_box - num_x_start, y_in_box - num_y_start);
            end
            pixel_data = show_pixel ? BLACK : color;
        end
        // Box 4
        else if (x >= box_x_pos[4] && x < (box_x_pos[4] + BOX_WIDTH) &&
                 y >= box_y_pos[4] && y < (box_y_pos[4] + BOX_HEIGHT)) begin
            value = array4;
            digit = (value < 10) ? value[3:0] : (value % 10);
            color = done ? GREEN : (swap_flag && ((4 == compare_idx1) || (4 == compare_idx2))) ? RED :
                    (sorting && ((4 == compare_idx1) || (4 == compare_idx2))) ? YELLOW : WHITE;
            x_in_box = x - box_x_pos[4];
            y_in_box = y - box_y_pos[4];
            if (x_in_box >= num_x_start && x_in_box < (num_x_start + NUM_WIDTH) &&
                y_in_box >= num_y_start && y_in_box < (num_y_start + NUM_HEIGHT)) begin
                show_pixel = digit_pixel(digit, x_in_box - num_x_start, y_in_box - num_y_start);
            end
            pixel_data = show_pixel ? BLACK : color;
        end
        // Box 3
        else if (x >= box_x_pos[3] && x < (box_x_pos[3] + BOX_WIDTH) &&
                 y >= box_y_pos[3] && y < (box_y_pos[3] + BOX_HEIGHT)) begin
            value = array3;
            digit = (value < 10) ? value[3:0] : (value % 10);
            color = done ? GREEN : (swap_flag && ((3 == compare_idx1) || (3 == compare_idx2))) ? RED :
                    (sorting && ((3 == compare_idx1) || (3 == compare_idx2))) ? YELLOW : WHITE;
            x_in_box = x - box_x_pos[3];
            y_in_box = y - box_y_pos[3];
            if (x_in_box >= num_x_start && x_in_box < (num_x_start + NUM_WIDTH) &&
                y_in_box >= num_y_start && y_in_box < (num_y_start + NUM_HEIGHT)) begin
                show_pixel = digit_pixel(digit, x_in_box - num_x_start, y_in_box - num_y_start);
            end
            pixel_data = show_pixel ? BLACK : color;
        end
        // Box 2
        else if (x >= box_x_pos[2] && x < (box_x_pos[2] + BOX_WIDTH) &&
                 y >= box_y_pos[2] && y < (box_y_pos[2] + BOX_HEIGHT)) begin
            value = array2;
            digit = (value < 10) ? value[3:0] : (value % 10);
            color = done ? GREEN : (swap_flag && ((2 == compare_idx1) || (2 == compare_idx2))) ? RED :
                    (sorting && ((2 == compare_idx1) || (2 == compare_idx2))) ? YELLOW : WHITE;
            x_in_box = x - box_x_pos[2];
            y_in_box = y - box_y_pos[2];
            if (x_in_box >= num_x_start && x_in_box < (num_x_start + NUM_WIDTH) &&
                y_in_box >= num_y_start && y_in_box < (num_y_start + NUM_HEIGHT)) begin
                show_pixel = digit_pixel(digit, x_in_box - num_x_start, y_in_box - num_y_start);
            end
            pixel_data = show_pixel ? BLACK : color;
        end
        // Box 1
        else if (x >= box_x_pos[1] && x < (box_x_pos[1] + BOX_WIDTH) &&
                 y >= box_y_pos[1] && y < (box_y_pos[1] + BOX_HEIGHT)) begin
            value = array1;
            digit = (value < 10) ? value[3:0] : (value % 10);
            color = done ? GREEN : (swap_flag && ((1 == compare_idx1) || (1 == compare_idx2))) ? RED :
                    (sorting && ((1 == compare_idx1) || (1 == compare_idx2))) ? YELLOW : WHITE;
            x_in_box = x - box_x_pos[1];
            y_in_box = y - box_y_pos[1];
            if (x_in_box >= num_x_start && x_in_box < (num_x_start + NUM_WIDTH) &&
                y_in_box >= num_y_start && y_in_box < (num_y_start + NUM_HEIGHT)) begin
                show_pixel = digit_pixel(digit, x_in_box - num_x_start, y_in_box - num_y_start);
            end
            pixel_data = show_pixel ? BLACK : color;
        end
        // Box 0
        else if (x >= box_x_pos[0] && x < (box_x_pos[0] + BOX_WIDTH) &&
                 y >= box_y_pos[0] && y < (box_y_pos[0] + BOX_HEIGHT)) begin
            value = array0;
            digit = (value < 10) ? value[3:0] : (value % 10);
            color = done ? GREEN : (swap_flag && ((0 == compare_idx1) || (0 == compare_idx2))) ? RED :
                    (sorting && ((0 == compare_idx1) || (0 == compare_idx2))) ? YELLOW : WHITE;
            x_in_box = x - box_x_pos[0];
            y_in_box = y - box_y_pos[0];
            if (x_in_box >= num_x_start && x_in_box < (num_x_start + NUM_WIDTH) &&
                y_in_box >= num_y_start && y_in_box < (num_y_start + NUM_HEIGHT)) begin
                show_pixel = digit_pixel(digit, x_in_box - num_x_start, y_in_box - num_y_start);
            end
            pixel_data = show_pixel ? BLACK : color;
        end

        // Render "BUBBLE SORT!" text when done (hard-coded coords like tutorial mode)
        else if (done && y >= 41 && y <= 47) begin
            char_y = y - 41;

            // B U B B L E   S O R T !
            if (x >= 12 && x <= 16) begin
                // 'B'
                char_x = x - 12;
                show_letter = get_letter_pixel(1, char_x, char_y);
                if (show_letter) pixel_data = YELLOW;
            end
            else if (x >= 18 && x <= 22) begin
                // 'U'
                char_x = x - 18;
                show_letter = get_letter_pixel(20, char_x, char_y);
                if (show_letter) pixel_data = YELLOW;
            end
            else if (x >= 24 && x <= 28) begin
                // 'B'
                char_x = x - 24;
                show_letter = get_letter_pixel(1, char_x, char_y);
                if (show_letter) pixel_data = YELLOW;
            end
            else if (x >= 30 && x <= 34) begin
                // 'B'
                char_x = x - 30;
                show_letter = get_letter_pixel(1, char_x, char_y);
                if (show_letter) pixel_data = YELLOW;
            end
            else if (x >= 36 && x <= 40) begin
                // 'L'
                char_x = x - 36;
                show_letter = get_letter_pixel(11, char_x, char_y);
                if (show_letter) pixel_data = YELLOW;
            end
            else if (x >= 42 && x <= 46) begin
                // 'E'
                char_x = x - 42;
                show_letter = get_letter_pixel(4, char_x, char_y);
                if (show_letter) pixel_data = YELLOW;
            end
            // Space at 48-53
            else if (x >= 54 && x <= 58) begin
                // 'S'
                char_x = x - 54;
                show_letter = get_letter_pixel(18, char_x, char_y);
                if (show_letter) pixel_data = YELLOW;
            end
            else if (x >= 60 && x <= 64) begin
                // 'O'
                char_x = x - 60;
                show_letter = get_letter_pixel(14, char_x, char_y);
                if (show_letter) pixel_data = YELLOW;
            end
            else if (x >= 66 && x <= 70) begin
                // 'R'
                char_x = x - 66;
                show_letter = get_letter_pixel(17, char_x, char_y);
                if (show_letter) pixel_data = YELLOW;
            end
            else if (x >= 72 && x <= 76) begin
                // 'T'
                char_x = x - 72;
                show_letter = get_letter_pixel(19, char_x, char_y);
                if (show_letter) pixel_data = YELLOW;
            end
            else if (x >= 78 && x <= 79) begin
                // '!'
                if (char_y < 5 || char_y == 6) begin
                    pixel_data = YELLOW;
                end
            end
        end
    end

endmodule
