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

    // Background color: BLUE dots on black background
    assign background_pixel_color = background_dot ? BLUE : BLACK;

    // Adjust x coordinate for centered array
    wire [6:0] x_adjusted = (x >= ARRAY_X_OFFSET && x < ARRAY_X_OFFSET + ARRAY_WIDTH) ?
                             (x - ARRAY_X_OFFSET) : 7'd127;  // Out of bounds if not in array

    // Determine which box slot (0-5) using adjusted x
    wire [2:0] slot = x_adjusted / BOX_TOTAL;
    wire [4:0] x_in_slot = x_adjusted % BOX_TOTAL;

    // Get value for current slot
    reg [7:0] value;
    always @(*) begin
        case (slot)
            0: value = array0;
            1: value = array1;
            2: value = array2;
            3: value = array3;
            4: value = array4;
            5: value = array5;
            default: value = 0;
        endcase
    end

    // For single digits, just take modulo 10 and ensure valid (0-9)
    wire [3:0] digit = (value < 10) ? value[3:0] : (value % 10);

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

    // Color selection
    reg [15:0] color;
    always @(*) begin
        if (done)
            color = GREEN;
        else if (swap_flag && ((slot == compare_idx1) || (slot == compare_idx2)))
            color = RED;
        else if (sorting && ((slot == compare_idx1) || (slot == compare_idx2)))
            color = YELLOW;
        else
            color = WHITE;
    end

    // Render boxes with borders and centered numbers
    reg show_pixel;
    reg is_border;
    reg [3:0] x_in_box;
    reg [5:0] y_in_box;
    reg [3:0] num_x_start;
    reg [3:0] num_y_start;
    reg box_active;

    // Box vertical positioning (centered on screen)
    localparam BOX_Y_START = (HEIGHT - BOX_HEIGHT) / 2;  // ~27
    localparam BOX_Y_END = BOX_Y_START + BOX_HEIGHT;     // ~37

    always @(*) begin
        pixel_data = BLACK;
        show_pixel = 0;
        is_border = 0;
        box_active = 0;

        // Check if we're in a valid box slot and within box bounds
        if (slot < 6 && x_in_slot < BOX_WIDTH && y >= BOX_Y_START && y < BOX_Y_END) begin
            box_active = 1;
            // Calculate position within box
            x_in_box = x_in_slot;
            y_in_box = y - BOX_Y_START;

            // Entire box filled with state color
            // Calculate number position for rendering
            num_x_start = 1 + 3;  // 1 (border) + 3 (centering)
            num_y_start = 1;      // 1 (border)

            if (x_in_box >= num_x_start && x_in_box < num_x_start + NUM_WIDTH &&
                y_in_box >= num_y_start && y_in_box < num_y_start + NUM_HEIGHT) begin
                show_pixel = digit_pixel(digit, x_in_box - num_x_start, y_in_box - num_y_start);
            end

            if (show_pixel)
                pixel_data = BLACK;  // Number in black
            else
                pixel_data = color;  // Box filled with state color (WHITE/YELLOW/RED/GREEN)
        end else begin
            // Pixel priority system: show background dots when no box is active
            pixel_data = background_pixel_color;
        end
    end

endmodule
