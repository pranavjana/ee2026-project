`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Welcome Screen Pixel Generator
// Displays user manual and navigation for sorting algorithm visualizer
//
// Display Layout (96×64 OLED):
//   Row 0-8:    "Welcome" title
//   Row 10-38:  Algorithm selection menu
//   Row 40-48:  Education mode info
//   Row 50-62:  Tutorial mode info
//////////////////////////////////////////////////////////////////////////////////

module welcome_screen_pixel_generator(
    input wire [13:0] pixel_index,      // Current pixel (0 to 6143)
    output reg [15:0] pixel_data        // RGB565 pixel color
);

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
        GRAY    = 16'h8410;

    //=========================================================================
    // Display Dimensions
    //=========================================================================
    localparam SCREEN_WIDTH = 96;
    localparam SCREEN_HEIGHT = 64;

    //=========================================================================
    // Pixel Coordinates
    //=========================================================================
    wire [6:0] pixel_x = pixel_index % SCREEN_WIDTH;
    wire [5:0] pixel_y = pixel_index / SCREEN_WIDTH;

    //=========================================================================
    // 5×7 Character ROM for Letters and Digits
    //=========================================================================
    reg [34:0] char_rom [0:35];  // 5×7 = 35 bits per character

    initial begin
        // Letters A-Z (indices 0-25)
        char_rom[0]  = 35'b01110_10001_10001_11111_10001_10001_10001; // A
        char_rom[1]  = 35'b11110_10001_10001_11110_10001_10001_11110; // B
        char_rom[2]  = 35'b01110_10001_10000_10000_10000_10001_01110; // C
        char_rom[3]  = 35'b11110_10001_10001_10001_10001_10001_11110; // D
        char_rom[4]  = 35'b11111_10000_10000_11110_10000_10000_11111; // E
        char_rom[5]  = 35'b11111_10000_10000_11110_10000_10000_10000; // F
        char_rom[6]  = 35'b01110_10001_10000_10111_10001_10001_01110; // G
        char_rom[7]  = 35'b10001_10001_10001_11111_10001_10001_10001; // H
        char_rom[8]  = 35'b01110_00100_00100_00100_00100_00100_01110; // I
        char_rom[9]  = 35'b00111_00001_00001_00001_00001_10001_01110; // J
        char_rom[10] = 35'b10001_10010_10100_11000_10100_10010_10001; // K
        char_rom[11] = 35'b10000_10000_10000_10000_10000_10000_11111; // L
        char_rom[12] = 35'b10001_11011_10101_10101_10001_10001_10001; // M
        char_rom[13] = 35'b10001_11001_10101_10011_10001_10001_10001; // N
        char_rom[14] = 35'b01110_10001_10001_10001_10001_10001_01110; // O
        char_rom[15] = 35'b11110_10001_10001_11110_10000_10000_10000; // P
        char_rom[16] = 35'b01110_10001_10001_10001_10101_10010_01101; // Q
        char_rom[17] = 35'b11110_10001_10001_11110_10100_10010_10001; // R
        char_rom[18] = 35'b01111_10000_10000_01110_00001_00001_11110; // S
        char_rom[19] = 35'b11111_00100_00100_00100_00100_00100_00100; // T
        char_rom[20] = 35'b10001_10001_10001_10001_10001_10001_01110; // U
        char_rom[21] = 35'b10001_10001_10001_10001_10001_01010_00100; // V
        char_rom[22] = 35'b10001_10001_10001_10101_10101_11011_10001; // W
        char_rom[23] = 35'b10001_10001_01010_00100_01010_10001_10001; // X
        char_rom[24] = 35'b10001_10001_01010_00100_00100_00100_00100; // Y
        char_rom[25] = 35'b11111_00001_00010_00100_01000_10000_11111; // Z

        // Digits 0-9 (indices 26-35)
        char_rom[26] = 35'b01110_10011_10101_11001_10001_10001_01110; // 0
        char_rom[27] = 35'b00100_01100_00100_00100_00100_00100_01110; // 1
        char_rom[28] = 35'b01110_10001_00001_00010_00100_01000_11111; // 2
        char_rom[29] = 35'b01110_10001_00001_00110_00001_10001_01110; // 3
        char_rom[30] = 35'b00010_00110_01010_10010_11111_00010_00010; // 4
        char_rom[31] = 35'b11111_10000_11110_00001_00001_10001_01110; // 5
        char_rom[32] = 35'b00110_01000_10000_11110_10001_10001_01110; // 6
        char_rom[33] = 35'b11111_00001_00010_00100_01000_01000_01000; // 7
        char_rom[34] = 35'b01110_10001_10001_01110_10001_10001_01110; // 8
        char_rom[35] = 35'b01110_10001_10001_01111_00001_00010_01100; // 9
    end

    //=========================================================================
    // Helper Function: Get Character Pixel
    //=========================================================================
    function get_char_pixel;
        input [5:0] char_index;  // 0-25 for A-Z, 26-35 for 0-9
        input [2:0] char_x;      // 0-4 (5 pixels wide)
        input [2:0] char_y;      // 0-6 (7 pixels tall)
        reg [4:0] row_data;
        begin
            if (char_index < 36 && char_x < 5 && char_y < 7) begin
                row_data = char_rom[char_index][34 - char_y * 5 -: 5];
                get_char_pixel = row_data[4 - char_x];
            end else begin
                get_char_pixel = 0;
            end
        end
    endfunction

    //=========================================================================
    // Helper Function: Draw String at Position
    //=========================================================================
    reg [2:0] str_char_x;
    reg [2:0] str_char_y;
    reg [5:0] str_char_index;
    reg str_pixel;

    //=========================================================================
    // Main Pixel Generation Logic
    //=========================================================================
    always @(*) begin
        // Default: black background with blue dots
        pixel_data = BLACK;

        // Background dot pattern (every 8 pixels)
        if ((pixel_x % 8 == 0) && (pixel_y % 8 == 0)) begin
            pixel_data = BLUE;
        end

        //=====================================================================
        // Title: "Welcome" (Row 2-8, Centered)
        //=====================================================================
        // W E L C O M E (7 chars × 5 pixels + 6 spaces = 41 pixels)
        // Centered: (96 - 41) / 2 = 27
        if (pixel_y >= 2 && pixel_y <= 8) begin
            str_char_y = pixel_y - 2;

            // W (22)
            if (pixel_x >= 27 && pixel_x <= 31) begin
                str_char_x = pixel_x - 27;
                str_pixel = get_char_pixel(22, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
            // E (4)
            else if (pixel_x >= 33 && pixel_x <= 37) begin
                str_char_x = pixel_x - 33;
                str_pixel = get_char_pixel(4, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
            // L (11)
            else if (pixel_x >= 39 && pixel_x <= 43) begin
                str_char_x = pixel_x - 39;
                str_pixel = get_char_pixel(11, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
            // C (2)
            else if (pixel_x >= 45 && pixel_x <= 49) begin
                str_char_x = pixel_x - 45;
                str_pixel = get_char_pixel(2, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
            // O (14)
            else if (pixel_x >= 51 && pixel_x <= 55) begin
                str_char_x = pixel_x - 51;
                str_pixel = get_char_pixel(14, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
            // M (12)
            else if (pixel_x >= 57 && pixel_x <= 61) begin
                str_char_x = pixel_x - 57;
                str_pixel = get_char_pixel(12, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
            // E (4)
            else if (pixel_x >= 63 && pixel_x <= 67) begin
                str_char_x = pixel_x - 63;
                str_pixel = get_char_pixel(4, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
        end

        //=====================================================================
        // Separator Line (Row 10)
        //=====================================================================
        if (pixel_y == 10 && pixel_x >= 10 && pixel_x <= 85) begin
            pixel_data = GRAY;
        end

        //=====================================================================
        // Algorithm Menu (Rows 12-38)
        //=====================================================================

        // "Bubble Sort (SW12)" - Row 13-19 - GREEN
        if (pixel_y >= 13 && pixel_y <= 19) begin
            str_char_y = pixel_y - 13;

            // B u b b l e  S o r t  ( S W 1 2 )
            // B (1) at x=6
            if (pixel_x >= 6 && pixel_x <= 10) begin
                str_char_x = pixel_x - 6;
                str_pixel = get_char_pixel(1, str_char_x, str_char_y);
                if (str_pixel) pixel_data = GREEN;
            end
            // u (20) at x=12
            else if (pixel_x >= 12 && pixel_x <= 16) begin
                str_char_x = pixel_x - 12;
                str_pixel = get_char_pixel(20, str_char_x, str_char_y);
                if (str_pixel) pixel_data = GREEN;
            end
            // b (1) at x=18
            else if (pixel_x >= 18 && pixel_x <= 22) begin
                str_char_x = pixel_x - 18;
                str_pixel = get_char_pixel(1, str_char_x, str_char_y);
                if (str_pixel) pixel_data = GREEN;
            end
            // b (1) at x=24
            else if (pixel_x >= 24 && pixel_x <= 28) begin
                str_char_x = pixel_x - 24;
                str_pixel = get_char_pixel(1, str_char_x, str_char_y);
                if (str_pixel) pixel_data = GREEN;
            end
            // l (11) at x=30
            else if (pixel_x >= 30 && pixel_x <= 34) begin
                str_char_x = pixel_x - 30;
                str_pixel = get_char_pixel(11, str_char_x, str_char_y);
                if (str_pixel) pixel_data = GREEN;
            end
            // e (4) at x=36
            else if (pixel_x >= 36 && pixel_x <= 40) begin
                str_char_x = pixel_x - 36;
                str_pixel = get_char_pixel(4, str_char_x, str_char_y);
                if (str_pixel) pixel_data = GREEN;
            end
            // ( at x=42-43
            else if (pixel_x >= 42 && pixel_x <= 43 && (str_char_y == 1 || str_char_y == 5)) begin
                pixel_data = WHITE;
            end
            // S (18) at x=44
            else if (pixel_x >= 44 && pixel_x <= 48) begin
                str_char_x = pixel_x - 44;
                str_pixel = get_char_pixel(18, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // W (22) at x=49
            else if (pixel_x >= 49 && pixel_x <= 53) begin
                str_char_x = pixel_x - 49;
                str_pixel = get_char_pixel(22, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // 1 (27) at x=54
            else if (pixel_x >= 54 && pixel_x <= 58) begin
                str_char_x = pixel_x - 54;
                str_pixel = get_char_pixel(27, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // 2 (28) at x=59
            else if (pixel_x >= 59 && pixel_x <= 63) begin
                str_char_x = pixel_x - 59;
                str_pixel = get_char_pixel(28, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // ) at x=64-65
            else if (pixel_x >= 64 && pixel_x <= 65 && (str_char_y == 1 || str_char_y == 5)) begin
                pixel_data = WHITE;
            end
        end

        // "Selection (SW13)" - Row 21-27 - CYAN
        if (pixel_y >= 21 && pixel_y <= 27) begin
            str_char_y = pixel_y - 21;

            // S e l e c t i o n  ( S W 1 3 )
            // S (18) at x=6
            if (pixel_x >= 6 && pixel_x <= 10) begin
                str_char_x = pixel_x - 6;
                str_pixel = get_char_pixel(18, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
            // e (4) at x=12
            else if (pixel_x >= 12 && pixel_x <= 16) begin
                str_char_x = pixel_x - 12;
                str_pixel = get_char_pixel(4, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
            // l (11) at x=18
            else if (pixel_x >= 18 && pixel_x <= 22) begin
                str_char_x = pixel_x - 18;
                str_pixel = get_char_pixel(11, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
            // e (4) at x=24
            else if (pixel_x >= 24 && pixel_x <= 28) begin
                str_char_x = pixel_x - 24;
                str_pixel = get_char_pixel(4, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
            // c (2) at x=30
            else if (pixel_x >= 30 && pixel_x <= 34) begin
                str_char_x = pixel_x - 30;
                str_pixel = get_char_pixel(2, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
            // t (19) at x=36
            else if (pixel_x >= 36 && pixel_x <= 40) begin
                str_char_x = pixel_x - 36;
                str_pixel = get_char_pixel(19, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
            // ( at x=42-43
            else if (pixel_x >= 42 && pixel_x <= 43 && (str_char_y == 1 || str_char_y == 5)) begin
                pixel_data = WHITE;
            end
            // S (18) at x=44
            else if (pixel_x >= 44 && pixel_x <= 48) begin
                str_char_x = pixel_x - 44;
                str_pixel = get_char_pixel(18, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // W (22) at x=49
            else if (pixel_x >= 49 && pixel_x <= 53) begin
                str_char_x = pixel_x - 49;
                str_pixel = get_char_pixel(22, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // 1 (27) at x=54
            else if (pixel_x >= 54 && pixel_x <= 58) begin
                str_char_x = pixel_x - 54;
                str_pixel = get_char_pixel(27, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // 3 (29) at x=59
            else if (pixel_x >= 59 && pixel_x <= 63) begin
                str_char_x = pixel_x - 59;
                str_pixel = get_char_pixel(29, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // ) at x=64-65
            else if (pixel_x >= 64 && pixel_x <= 65 && (str_char_y == 1 || str_char_y == 5)) begin
                pixel_data = WHITE;
            end
        end

        // "Insertion (SW14)" - Row 29-35 - MAGENTA
        if (pixel_y >= 29 && pixel_y <= 35) begin
            str_char_y = pixel_y - 29;

            // I n s e r t i o n  ( S W 1 4 )
            // I (8) at x=6
            if (pixel_x >= 6 && pixel_x <= 10) begin
                str_char_x = pixel_x - 6;
                str_pixel = get_char_pixel(8, str_char_x, str_char_y);
                if (str_pixel) pixel_data = MAGENTA;
            end
            // n (13) at x=12
            else if (pixel_x >= 12 && pixel_x <= 16) begin
                str_char_x = pixel_x - 12;
                str_pixel = get_char_pixel(13, str_char_x, str_char_y);
                if (str_pixel) pixel_data = MAGENTA;
            end
            // s (18) at x=18
            else if (pixel_x >= 18 && pixel_x <= 22) begin
                str_char_x = pixel_x - 18;
                str_pixel = get_char_pixel(18, str_char_x, str_char_y);
                if (str_pixel) pixel_data = MAGENTA;
            end
            // e (4) at x=24
            else if (pixel_x >= 24 && pixel_x <= 28) begin
                str_char_x = pixel_x - 24;
                str_pixel = get_char_pixel(4, str_char_x, str_char_y);
                if (str_pixel) pixel_data = MAGENTA;
            end
            // r (17) at x=30
            else if (pixel_x >= 30 && pixel_x <= 34) begin
                str_char_x = pixel_x - 30;
                str_pixel = get_char_pixel(17, str_char_x, str_char_y);
                if (str_pixel) pixel_data = MAGENTA;
            end
            // t (19) at x=36
            else if (pixel_x >= 36 && pixel_x <= 40) begin
                str_char_x = pixel_x - 36;
                str_pixel = get_char_pixel(19, str_char_x, str_char_y);
                if (str_pixel) pixel_data = MAGENTA;
            end
            // ( at x=42-43
            else if (pixel_x >= 42 && pixel_x <= 43 && (str_char_y == 1 || str_char_y == 5)) begin
                pixel_data = WHITE;
            end
            // S (18) at x=44
            else if (pixel_x >= 44 && pixel_x <= 48) begin
                str_char_x = pixel_x - 44;
                str_pixel = get_char_pixel(18, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // W (22) at x=49
            else if (pixel_x >= 49 && pixel_x <= 53) begin
                str_char_x = pixel_x - 49;
                str_pixel = get_char_pixel(22, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // 1 (27) at x=54
            else if (pixel_x >= 54 && pixel_x <= 58) begin
                str_char_x = pixel_x - 54;
                str_pixel = get_char_pixel(27, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // 4 (30) at x=59
            else if (pixel_x >= 59 && pixel_x <= 63) begin
                str_char_x = pixel_x - 59;
                str_pixel = get_char_pixel(30, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // ) at x=64-65
            else if (pixel_x >= 64 && pixel_x <= 65 && (str_char_y == 1 || str_char_y == 5)) begin
                pixel_data = WHITE;
            end
        end

        // "Merge Sort (SW15)" - Row 37-43 - ORANGE
        if (pixel_y >= 37 && pixel_y <= 43) begin
            str_char_y = pixel_y - 37;

            // M e r g e  ( S W 1 5 )
            // M (12) at x=6
            if (pixel_x >= 6 && pixel_x <= 10) begin
                str_char_x = pixel_x - 6;
                str_pixel = get_char_pixel(12, str_char_x, str_char_y);
                if (str_pixel) pixel_data = ORANGE;
            end
            // e (4) at x=12
            else if (pixel_x >= 12 && pixel_x <= 16) begin
                str_char_x = pixel_x - 12;
                str_pixel = get_char_pixel(4, str_char_x, str_char_y);
                if (str_pixel) pixel_data = ORANGE;
            end
            // r (17) at x=18
            else if (pixel_x >= 18 && pixel_x <= 22) begin
                str_char_x = pixel_x - 18;
                str_pixel = get_char_pixel(17, str_char_x, str_char_y);
                if (str_pixel) pixel_data = ORANGE;
            end
            // g (6) at x=24
            else if (pixel_x >= 24 && pixel_x <= 28) begin
                str_char_x = pixel_x - 24;
                str_pixel = get_char_pixel(6, str_char_x, str_char_y);
                if (str_pixel) pixel_data = ORANGE;
            end
            // e (4) at x=30
            else if (pixel_x >= 30 && pixel_x <= 34) begin
                str_char_x = pixel_x - 30;
                str_pixel = get_char_pixel(4, str_char_x, str_char_y);
                if (str_pixel) pixel_data = ORANGE;
            end
            // ( at x=36-37
            else if (pixel_x >= 36 && pixel_x <= 37 && (str_char_y == 1 || str_char_y == 5)) begin
                pixel_data = WHITE;
            end
            // S (18) at x=38
            else if (pixel_x >= 38 && pixel_x <= 42) begin
                str_char_x = pixel_x - 38;
                str_pixel = get_char_pixel(18, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // W (22) at x=43
            else if (pixel_x >= 43 && pixel_x <= 47) begin
                str_char_x = pixel_x - 43;
                str_pixel = get_char_pixel(22, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // 1 (27) at x=48
            else if (pixel_x >= 48 && pixel_x <= 52) begin
                str_char_x = pixel_x - 48;
                str_pixel = get_char_pixel(27, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // 5 (31) at x=53
            else if (pixel_x >= 53 && pixel_x <= 57) begin
                str_char_x = pixel_x - 53;
                str_pixel = get_char_pixel(31, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // ) at x=58-59
            else if (pixel_x >= 58 && pixel_x <= 59 && (str_char_y == 1 || str_char_y == 5)) begin
                pixel_data = WHITE;
            end
        end

        //=====================================================================
        // Separator Line (Row 45)
        //=====================================================================
        if (pixel_y == 45 && pixel_x >= 10 && pixel_x <= 85) begin
            pixel_data = GRAY;
        end

        //=====================================================================
        // Tutorial Mode Info (Rows 48-54)
        //=====================================================================
        // "Tutorial: SW10+Mode"
        if (pixel_y >= 48 && pixel_y <= 54) begin
            str_char_y = pixel_y - 48;

            // T u t o r i a l :  S W 1 0
            // T (19) at x=3
            if (pixel_x >= 3 && pixel_x <= 7) begin
                str_char_x = pixel_x - 3;
                str_pixel = get_char_pixel(19, str_char_x, str_char_y);
                if (str_pixel) pixel_data = WHITE;
            end
            // u (20) at x=8
            else if (pixel_x >= 8 && pixel_x <= 12) begin
                str_char_x = pixel_x - 8;
                str_pixel = get_char_pixel(20, str_char_x, str_char_y);
                if (str_pixel) pixel_data = WHITE;
            end
            // t (19) at x=13
            else if (pixel_x >= 13 && pixel_x <= 17) begin
                str_char_x = pixel_x - 13;
                str_pixel = get_char_pixel(19, str_char_x, str_char_y);
                if (str_pixel) pixel_data = WHITE;
            end
            // o (14) at x=18
            else if (pixel_x >= 18 && pixel_x <= 22) begin
                str_char_x = pixel_x - 18;
                str_pixel = get_char_pixel(14, str_char_x, str_char_y);
                if (str_pixel) pixel_data = WHITE;
            end
            // r (17) at x=23
            else if (pixel_x >= 23 && pixel_x <= 27) begin
                str_char_x = pixel_x - 23;
                str_pixel = get_char_pixel(17, str_char_x, str_char_y);
                if (str_pixel) pixel_data = WHITE;
            end
            // : at x=28-29
            else if (pixel_x >= 28 && pixel_x <= 29 && (str_char_y == 2 || str_char_y == 4)) begin
                pixel_data = WHITE;
            end
            // S (18) at x=31
            else if (pixel_x >= 31 && pixel_x <= 35) begin
                str_char_x = pixel_x - 31;
                str_pixel = get_char_pixel(18, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // W (22) at x=36
            else if (pixel_x >= 36 && pixel_x <= 40) begin
                str_char_x = pixel_x - 36;
                str_pixel = get_char_pixel(22, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // 1 (27) at x=41
            else if (pixel_x >= 41 && pixel_x <= 45) begin
                str_char_x = pixel_x - 41;
                str_pixel = get_char_pixel(27, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // 0 (26) at x=46
            else if (pixel_x >= 46 && pixel_x <= 50) begin
                str_char_x = pixel_x - 46;
                str_pixel = get_char_pixel(26, str_char_x, str_char_y);
                if (str_pixel) pixel_data = YELLOW;
            end
            // + at x=51-52
            else if (pixel_x >= 51 && pixel_x <= 52) begin
                if (str_char_y == 3 || (pixel_x == 51 && str_char_y >= 2 && str_char_y <= 4)) begin
                    pixel_data = WHITE;
                end
            end
            // M (12) at x=54
            else if (pixel_x >= 54 && pixel_x <= 58) begin
                str_char_x = pixel_x - 54;
                str_pixel = get_char_pixel(12, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
            // o (14) at x=59
            else if (pixel_x >= 59 && pixel_x <= 63) begin
                str_char_x = pixel_x - 59;
                str_pixel = get_char_pixel(14, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
            // d (3) at x=64
            else if (pixel_x >= 64 && pixel_x <= 68) begin
                str_char_x = pixel_x - 64;
                str_pixel = get_char_pixel(3, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
            // e (4) at x=69
            else if (pixel_x >= 69 && pixel_x <= 73) begin
                str_char_x = pixel_x - 69;
                str_pixel = get_char_pixel(4, str_char_x, str_char_y);
                if (str_pixel) pixel_data = CYAN;
            end
        end

        //=====================================================================
        // Button Info (Rows 57-63)
        //=====================================================================
        // "Buttons: U=Start C=Reset"
        if (pixel_y >= 57 && pixel_y <= 63) begin
            str_char_y = pixel_y - 57;

            // U = S t a r t  C = R e s e t
            // U (20) at x=8
            if (pixel_x >= 8 && pixel_x <= 12) begin
                str_char_x = pixel_x - 8;
                str_pixel = get_char_pixel(20, str_char_x, str_char_y);
                if (str_pixel) pixel_data = GREEN;
            end
            // = at x=13-14
            else if (pixel_x >= 13 && pixel_x <= 14 && (str_char_y == 2 || str_char_y == 4)) begin
                pixel_data = WHITE;
            end
            // S (18) at x=15
            else if (pixel_x >= 15 && pixel_x <= 19) begin
                str_char_x = pixel_x - 15;
                str_pixel = get_char_pixel(18, str_char_x, str_char_y);
                if (str_pixel) pixel_data = WHITE;
            end
            // t (19) at x=20
            else if (pixel_x >= 20 && pixel_x <= 24) begin
                str_char_x = pixel_x - 20;
                str_pixel = get_char_pixel(19, str_char_x, str_char_y);
                if (str_pixel) pixel_data = WHITE;
            end
            // a (0) at x=25
            else if (pixel_x >= 25 && pixel_x <= 29) begin
                str_char_x = pixel_x - 25;
                str_pixel = get_char_pixel(0, str_char_x, str_char_y);
                if (str_pixel) pixel_data = WHITE;
            end
            // r (17) at x=30
            else if (pixel_x >= 30 && pixel_x <= 34) begin
                str_char_x = pixel_x - 30;
                str_pixel = get_char_pixel(17, str_char_x, str_char_y);
                if (str_pixel) pixel_data = WHITE;
            end
            // t (19) at x=35
            else if (pixel_x >= 35 && pixel_x <= 39) begin
                str_char_x = pixel_x - 35;
                str_pixel = get_char_pixel(19, str_char_x, str_char_y);
                if (str_pixel) pixel_data = WHITE;
            end
            // C (2) at x=45
            else if (pixel_x >= 45 && pixel_x <= 49) begin
                str_char_x = pixel_x - 45;
                str_pixel = get_char_pixel(2, str_char_x, str_char_y);
                if (str_pixel) pixel_data = RED;
            end
            // = at x=50-51
            else if (pixel_x >= 50 && pixel_x <= 51 && (str_char_y == 2 || str_char_y == 4)) begin
                pixel_data = WHITE;
            end
            // R (17) at x=52
            else if (pixel_x >= 52 && pixel_x <= 56) begin
                str_char_x = pixel_x - 52;
                str_pixel = get_char_pixel(17, str_char_x, str_char_y);
                if (str_pixel) pixel_data = WHITE;
            end
            // e (4) at x=57
            else if (pixel_x >= 57 && pixel_x <= 61) begin
                str_char_x = pixel_x - 57;
                str_pixel = get_char_pixel(4, str_char_x, str_char_y);
                if (str_pixel) pixel_data = WHITE;
            end
            // s (18) at x=62
            else if (pixel_x >= 62 && pixel_x <= 66) begin
                str_char_x = pixel_x - 62;
                str_pixel = get_char_pixel(18, str_char_x, str_char_y);
                if (str_pixel) pixel_data = WHITE;
            end
            // e (4) at x=67
            else if (pixel_x >= 67 && pixel_x <= 71) begin
                str_char_x = pixel_x - 67;
                str_pixel = get_char_pixel(4, str_char_x, str_char_y);
                if (str_pixel) pixel_data = WHITE;
            end
            // t (19) at x=72
            else if (pixel_x >= 72 && pixel_x <= 76) begin
                str_char_x = pixel_x - 72;
                str_pixel = get_char_pixel(19, str_char_x, str_char_y);
                if (str_pixel) pixel_data = WHITE;
            end
        end
    end

endmodule
