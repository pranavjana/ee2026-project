`timescale 1ns / 1ps

module display_generator_comb(
    input enable,
    input [12:0] pixel_index,
    input show_swap_info,
    input [17:0] array_flat,
    input [2:0] current_i,
    input [2:0] current_j,
    input [2:0] min_idx,
    input sorting_active,
    input [1:0] state_type,
    input [2:0] intro_state,
    input [2:0] anim_offset,
    input sort_complete,
    input tutorial_mode,
    input [3:0] tutorial_state,
    input [2:0] selected_box,
    input [17:0] tutorial_array,
    input [11:0] tutorial_timer,
    input [5:0] box_confirmed,
    input [2:0] test_cursor_pos,
    input [2:0] test_unsorted_idx,
    input test_selecting_swap,
    input [1:0] wrong_attempt_count,
    input [7:0] comparison_count,
    input [7:0] swap_count,
     input [2:0] user_min_selected, 
     input [2:0] tutorial_progress,
    output reg [15:0] pixel_data
);

    // Unpack arrays
    wire [2:0] array [0:5];
    assign array[0] = array_flat[2:0];
    assign array[1] = array_flat[5:3];
    assign array[2] = array_flat[8:6];
    assign array[3] = array_flat[11:9];
    assign array[4] = array_flat[14:12];
    assign array[5] = array_flat[17:15];
    
    wire [2:0] tut_array [0:5];
    assign tut_array[0] = tutorial_array[2:0];
    assign tut_array[1] = tutorial_array[5:3];
    assign tut_array[2] = tutorial_array[8:6];
    assign tut_array[3] = tutorial_array[11:9];
    assign tut_array[4] = tutorial_array[14:12];
    assign tut_array[5] = tutorial_array[17:15];

    // Colors
    localparam [15:0] BLACK  = 16'h0000;
    localparam [15:0] WHITE  = 16'hFFFF;
    localparam [15:0] GREEN  = 16'h07E0;
    localparam [15:0] YELLOW = 16'hFFE0;
    localparam [15:0] RED    = 16'hF800;
    localparam [15:0] BLUE   = 16'h001F;
    localparam [15:0] CYAN   = 16'h07FF;
    localparam [15:0] MAGENTA = 16'hF81F;
    localparam [15:0] DARK_BLUE = 16'h0010;
    localparam [15:0] DARK_GREEN = 16'h0200;
    localparam [15:0] DARK_RED = 16'h4000;
    localparam [15:0] BRIGHT_GREEN = 16'h07E0;
    localparam [15:0] ORANGE = 16'hFD20;
    
    // Gradient colors
        localparam [15:0] LIGHT_BLUE_TOP = 16'hADFF;    // Light blue (top)
        localparam [15:0] LIGHT_BLUE_MID = 16'h86FF;    // Medium light blue
        localparam [15:0] LIGHT_BLUE_BOT = 16'h5EDF;    // Darker light blue (bottom)
        
        localparam [15:0] LIGHT_ORANGE_TOP = 16'hFED8;  // Very light yellow (top)
        localparam [15:0] LIGHT_ORANGE_MID = 16'hFED8;  // Light orange-yellow
        localparam [15:0] LIGHT_ORANGE_BOT = 16'hFD94;  // Light orange (bottom)
    
    // Coordinates
    wire [6:0] x = pixel_index % 96;
    wire [5:0] y = pixel_index / 96;
    
    // Box layout
    localparam BOX_WIDTH = 15;
    localparam BOX_HEIGHT = 15;
    localparam BOX_SPACING = 16;
    localparam BOX_OFFSET = 0;
    localparam START_Y = 30;
    localparam TUT_START_Y = 24;
    localparam TEST_START_Y = 30;
    
    // Background effects
    wire [6:0] star_x1 = (tutorial_timer[5:0] + x) % 96;
    wire [5:0] star_y1 = (tutorial_timer[6:1] + y) % 64;
    wire is_star1 = ((star_x1 ^ star_y1) == 6'd0) && (tutorial_timer[3:0] > 4'd8);
    
    wire [6:0] star_x2 = (tutorial_timer[6:1] + x + 32) % 96;
    wire [5:0] star_y2 = (tutorial_timer[5:0] + y + 16) % 64;
    wire is_star2 = ((star_x2 ^ star_y2) == 6'd7) && (tutorial_timer[2:0] > 3'd4);
    
    wire [6:0] star_x3 = (tutorial_timer[7:2] + x + 64) % 96;
    wire [5:0] star_y3 = (tutorial_timer[4:0] + y + 48) % 64;
    wire is_star3 = ((star_x3 ^ star_y3) == 6'd15) && (tutorial_timer[4:0] > 5'd16);
    
    wire [7:0] wave_pattern = (x + tutorial_timer[7:3]) ^ (y + tutorial_timer[6:2]);
    wire is_wave_bright = wave_pattern[7:5] == 3'b111;
    wire is_wave_med = wave_pattern[7:5] == 3'b110;
    wire is_wave_dark = wave_pattern[7:5] == 3'b101;
    
    wire is_border_top = (y < 2);
    wire is_border_bottom = (y >= 62);
    wire is_border_left = (x < 2);
    wire is_border_right = (x >= 94);
    wire is_border = is_border_top || is_border_bottom || is_border_left || is_border_right;
    wire border_pulse = tutorial_timer[8:6] > 3'd4;
    
    wire is_corner = ((x < 5 && y < 5) || (x >= 91 && y < 5) || 
                      (x < 5 && y >= 59) || (x >= 91 && y >= 59));
    wire corner_sparkle = (x[1:0] == tutorial_timer[3:2]) && (y[1:0] == tutorial_timer[5:4]);
    
    wire [7:0] twinkle_seed = x[5:0] ^ y[4:0] ^ tutorial_timer[7:0];
    wire is_twinkle = (twinkle_seed[7:5] == 3'b101) && (tutorial_timer[2:0] == 3'b111);
    
   // Floating objects for tutorial pages - smooth vertical motion
    wire [6:0] float_offset_slow = tutorial_timer[11:5];  // Much slower counter
    
    // Floating circles (bottom left area) - gentle up/down motion
    wire [6:0] circle1_x = 15;  // Fixed x position
    wire [5:0] circle1_base_y = 50;
    wire [3:0] circle1_wave = (tutorial_timer[10:7] < 8) ? tutorial_timer[10:7] : (15 - tutorial_timer[10:7]);
    wire [5:0] circle1_y = circle1_base_y + circle1_wave[2:0];
    wire [6:0] circle1_dx = (x > circle1_x) ? (x - circle1_x) : (circle1_x - x);
    wire [5:0] circle1_dy = (y > circle1_y) ? (y - circle1_y) : (circle1_y - y);
    wire is_circle_float1 = (circle1_dx < 4) && (circle1_dy < 4) && ((circle1_dx + circle1_dy) < 5);
    
    // Floating star (bottom right area) - gentle up/down motion
    wire [6:0] star_float_x = 75;  // Fixed x position
    wire [5:0] star_base_y = 52;
    wire [3:0] star_wave = (tutorial_timer[11:8] < 8) ? tutorial_timer[11:8] : (15 - tutorial_timer[11:8]);
    wire [5:0] star_float_y = star_base_y + star_wave[2:0];
    wire signed [7:0] star_dx = x - star_float_x;
    wire signed [5:0] star_dy = y - star_float_y;
    wire is_star_center = (star_dx >= -1 && star_dx <= 1) && (star_dy >= -2 && star_dy <= 2);
    wire is_star_horiz = (star_dx >= -3 && star_dx <= 3) && (star_dy >= -1 && star_dy <= 1);
    wire is_star_float = is_star_center || is_star_horiz;
    
    // Floating square (bottom center) - gentle up/down motion
    wire [6:0] square_x = 45;  // Fixed x position
    wire [5:0] square_base_y = 53;
    wire [3:0] square_wave = (tutorial_timer[10:7] < 8) ? (8 - tutorial_timer[10:7]) : (tutorial_timer[10:7] - 7);
    wire [5:0] square_y = square_base_y + square_wave[2:0];
    wire is_square_float = (x >= square_x && x < square_x + 5) && 
                           (y >= square_y && y < square_y + 5) &&
                           ((x == square_x) || (x == square_x + 4) || 
                            (y == square_y) || (y == square_y + 4));
    
    // Floating triangle (bottom left-center) - gentle up/down motion
    wire [6:0] tri_x = 28;  // Fixed x position
    wire [5:0] tri_base_y = 54;
    wire [3:0] tri_wave = (tutorial_timer[11:8] < 8) ? (8 - tutorial_timer[11:8]) : (tutorial_timer[11:8] - 7);
    wire [5:0] tri_y = tri_base_y + tri_wave[2:0];
    wire signed [7:0] tri_dx = x - tri_x;
    wire signed [5:0] tri_dy = y - tri_y;
    wire is_tri_top = (tri_dy == 0) && (tri_dx >= -1 && tri_dx <= 1);
    wire is_tri_mid = (tri_dy == 1) && (tri_dx >= -2 && tri_dx <= 2);
    wire is_tri_bot = (tri_dy == 2) && (tri_dx >= -3 && tri_dx <= 3);
    wire is_triangle_float = is_tri_top || is_tri_mid || is_tri_bot;
    
    // BEGIN page blinking and explosion animation
    wire begin_blink = tutorial_timer[4];  // Blinks every ~0.5 seconds
    
    // Explosion animation - radiating circles and particles
    wire [6:0] explosion_center_x = 48;
    wire [5:0] explosion_center_y = 32;
    
    // Calculate distance from center for explosion
    wire [6:0] exp_dx = (x > explosion_center_x) ? (x - explosion_center_x) : (explosion_center_x - x);
    wire [5:0] exp_dy = (y > explosion_center_y) ? (y - explosion_center_y) : (explosion_center_y - y);
    wire [7:0] exp_dist = exp_dx + exp_dy;
    
    // Expanding circles based on timer
    wire [7:0] exp_radius1 = tutorial_timer[6:0];
    wire [7:0] exp_radius2 = (tutorial_timer[6:0] > 15) ? (tutorial_timer[6:0] - 15) : 0;
    wire [7:0] exp_radius3 = (tutorial_timer[6:0] > 30) ? (tutorial_timer[6:0] - 30) : 0;
    
    wire is_exp_circle1 = (exp_dist >= exp_radius1) && (exp_dist < exp_radius1 + 2) && (exp_radius1 > 0);
    wire is_exp_circle2 = (exp_dist >= exp_radius2) && (exp_dist < exp_radius2 + 2) && (exp_radius2 > 0);
    wire is_exp_circle3 = (exp_dist >= exp_radius3) && (exp_dist < exp_radius3 + 2) && (exp_radius3 > 0);
    
    // Explosion particles (8 directions)
    wire [6:0] particle_offset = tutorial_timer[5:0];
    
    // Particle 1 - right
    wire [6:0] p1_x = explosion_center_x + particle_offset;
    wire [5:0] p1_y = explosion_center_y;
    wire is_particle1 = (x >= p1_x && x < p1_x + 2) && (y >= p1_y && y < p1_y + 2);
    
    // Particle 2 - left
    wire [6:0] p2_x = (explosion_center_x > particle_offset) ? (explosion_center_x - particle_offset) : 0;
    wire [5:0] p2_y = explosion_center_y;
    wire is_particle2 = (x >= p2_x && x < p2_x + 2) && (y >= p2_y && y < p2_y + 2);
    
    // Particle 3 - down
    wire [6:0] p3_x = explosion_center_x;
    wire [5:0] p3_y = explosion_center_y + particle_offset[4:0];
    wire is_particle3 = (x >= p3_x && x < p3_x + 2) && (y >= p3_y && y < p3_y + 2);
    
    // Particle 4 - up
    wire [6:0] p4_x = explosion_center_x;
    wire [5:0] p4_y = (explosion_center_y > particle_offset[4:0]) ? (explosion_center_y - particle_offset[4:0]) : 0;
    wire is_particle4 = (x >= p4_x && x < p4_x + 2) && (y >= p4_y && y < p4_y + 2);
    
    // Particle 5 - diagonal down-right
    wire [6:0] p5_x = explosion_center_x + particle_offset[5:1];
    wire [5:0] p5_y = explosion_center_y + particle_offset[4:0];
    wire is_particle5 = (x >= p5_x && x < p5_x + 2) && (y >= p5_y && y < p5_y + 2);
    
    // Particle 6 - diagonal up-left
    wire [6:0] p6_x = (explosion_center_x > particle_offset[5:1]) ? (explosion_center_x - particle_offset[5:1]) : 0;
    wire [5:0] p6_y = (explosion_center_y > particle_offset[4:0]) ? (explosion_center_y - particle_offset[4:0]) : 0;
    wire is_particle6 = (x >= p6_x && x < p6_x + 2) && (y >= p6_y && y < p6_y + 2);
    
    // Particle 7 - diagonal down-left
    wire [6:0] p7_x = (explosion_center_x > particle_offset[5:1]) ? (explosion_center_x - particle_offset[5:1]) : 0;
    wire [5:0] p7_y = explosion_center_y + particle_offset[4:0];
    wire is_particle7 = (x >= p7_x && x < p7_x + 2) && (y >= p7_y && y < p7_y + 2);
    
    // Particle 8 - diagonal up-right
    wire [6:0] p8_x = explosion_center_x + particle_offset[5:1];
    wire [5:0] p8_y = (explosion_center_y > particle_offset[4:0]) ? (explosion_center_y - particle_offset[4:0]) : 0;
    wire is_particle8 = (x >= p8_x && x < p8_x + 2) && (y >= p8_y && y < p8_y + 2);
    
    wire is_explosion_particle = is_particle1 || is_particle2 || is_particle3 || is_particle4 ||
                                  is_particle5 || is_particle6 || is_particle7 || is_particle8;
    
    wire is_explosion_effect = is_exp_circle1 || is_exp_circle2 || is_exp_circle3 || is_explosion_particle;
    
    // Flash effect for explosion
    wire explosion_flash = (tutorial_timer[3:0] < 8);
    
    reg [15:0] background_color;
    always @(*) begin
        if (is_star1 || is_star2 || is_star3) begin
            background_color = WHITE;
        end else if (is_corner && corner_sparkle) begin
            background_color = CYAN;
        end else if (is_twinkle) begin
            background_color = YELLOW;
        end else if (is_wave_bright) begin
            background_color = DARK_BLUE;
        end else if (is_wave_med) begin
            background_color = DARK_GREEN;
        end else if (is_wave_dark) begin
            background_color = DARK_RED;
        end else if (is_border && border_pulse) begin
            background_color = MAGENTA;
        end else begin
            background_color = BLACK;
        end
    end
    
    // ========== ENHANCED CELEBRATION EFFECTS FOR WELL DONE ==========
    wire [6:0] confetti_x1 = (tutorial_timer[6:0] + x + 10) % 96;
    wire [5:0] confetti_y1 = (tutorial_timer[5:0] + y) % 64;
    wire is_confetti1 = ((confetti_x1 ^ confetti_y1) == 6'd0);
    
    wire [6:0] confetti_x2 = (tutorial_timer[7:1] + x + 30) % 96;
    wire [5:0] confetti_y2 = (tutorial_timer[6:1] + y + 20) % 64;
    wire is_confetti2 = ((confetti_x2 ^ confetti_y2) == 6'd7);
    
    wire [6:0] confetti_x3 = (tutorial_timer[5:0] + x + 50) % 96;
    wire [5:0] confetti_y3 = (tutorial_timer[7:2] + y + 40) % 64;
    wire is_confetti3 = ((confetti_x3 ^ confetti_y3) == 6'd15);
    
    wire [6:0] confetti_x4 = (tutorial_timer[8:2] + x + 70) % 96;
    wire [5:0] confetti_y4 = (tutorial_timer[4:0] + y + 10) % 64;
    wire is_confetti4 = ((confetti_x4 ^ confetti_y4) == 6'd3);
    
    wire [7:0] sparkle_seed = x[5:0] ^ y[4:0] ^ tutorial_timer[7:0];
    wire is_sparkle1 = (sparkle_seed[7:5] == 3'b101) && (tutorial_timer[2:0] > 3'd4);
    wire is_sparkle2 = (sparkle_seed[7:5] == 3'b110) && (tutorial_timer[3:1] > 3'd5);
    wire is_sparkle3 = (sparkle_seed[7:4] == 4'b1100) && (tutorial_timer[1:0] == 2'b11);
    
    wire [7:0] rainbow_pattern = (x + tutorial_timer[7:2]) ^ (y + tutorial_timer[6:1]);
    wire is_rainbow_r = rainbow_pattern[7:5] == 3'b100;
    wire is_rainbow_y = rainbow_pattern[7:5] == 3'b101;
    wire is_rainbow_g = rainbow_pattern[7:5] == 3'b110;
    wire is_rainbow_c = rainbow_pattern[7:5] == 3'b111;
    
    wire is_border_top_wd = (y < 3);
    wire is_border_bottom_wd = (y >= 61);
    wire is_border_left_wd = (x < 3);
    wire is_border_right_wd = (x >= 93);
    wire is_border_wd = is_border_top_wd || is_border_bottom_wd || is_border_left_wd || is_border_right_wd;
    wire border_pulse_wd = tutorial_timer[7:5] > 3'd3;
    wire [1:0] border_color_sel = tutorial_timer[9:8];
    
    wire is_star_wd1 = ((x[3:0] == tutorial_timer[3:0]) && (y[3:0] == tutorial_timer[7:4]));
    wire is_star_wd2 = ((x[4:1] == tutorial_timer[7:4]) && (y[4:1] == tutorial_timer[3:0]));
    wire is_star_wd3 = ((x[2:0] == tutorial_timer[5:3]) && (y[2:0] == tutorial_timer[8:6]));
    
    wire [6:0] dx = (x > 48) ? (x - 48) : (48 - x);
    wire [5:0] dy = (y > 32) ? (y - 32) : (32 - y);
    wire [7:0] dist = dx + dy;
    wire is_circle1 = ((dist + tutorial_timer[5:2]) % 16) < 2;
    wire is_circle2 = ((dist + tutorial_timer[7:4]) % 20) < 2;
    
    wire [7:0] diag1 = x + y + tutorial_timer[6:0];
    wire [7:0] diag2 = x + (64-y) + tutorial_timer[6:0];
    wire is_beam1 = (diag1[7:4] == 4'b0101);
    wire is_beam2 = (diag2[7:4] == 4'b1010);
    wire in_failed_text;
    
    // Text renderers
    wire in_intro_text;
    intro_text_renderer intro_text(
        .x(x),
        .y(y),
        .intro_state(intro_state),
        .anim_offset(anim_offset),
        .is_text(in_intro_text)
    );
    
    wire in_tutorial_text;
    tutorial_text_renderer tut_text(
        .x(x),
        .y(y),
        .tutorial_state(tutorial_state),
        .is_text(in_tutorial_text)
    );
    
    failed_text_renderer failed_text(
        .x(x),
        .y(y),
        .is_text(in_failed_text)
    );
    wire in_begin_text;
    begin_text_renderer begin_text(
        .x(x),
        .y(y),
        .blink_on(begin_blink),
        .is_text(in_begin_text)
    );
    
    wire in_input_num_text;
    input_num_text_renderer input_num_text(
        .x(x),
        .y(y),
        .is_text(in_input_num_text)
    );
    
    wire in_correct_text;
    correct_text_renderer correct_text(
        .x(x),
        .y(y),
        .is_text(in_correct_text)
    );
    
    wire in_wrong_text;
    wrong_text_renderer wrong_text(
        .x(x),
        .y(y),
        .is_text(in_wrong_text)
    );
    
    wire in_well_done_text;
    well_done_text_renderer well_done_text(
        .x(x),
        .y(y),
        .is_text(in_well_done_text)
    );
    
    wire in_test_cursor;
    cursor_renderer test_cursor(
        .x(x),
        .y(y),
        .cursor_pos(test_cursor_pos),
        .start_y(TEST_START_Y),
        .is_cursor(in_test_cursor)
    );
    
    //wire in_swap_text;
   // wire show_no_swap = (state_type == 2'd2) && (current_i == min_idx);
    
    // *** FIX: Get the actual VALUES from the array instead of using indices ***
    //wire [2:0] swap_value_from = array[current_i];  // Value at current position
    //wire [2:0] swap_value_to = array[min_idx];      // Value at minimum position
    
    //swap_text_renderer swap_text(
      //  .x(x),
       // .y(y),
      //  .pos1(swap_value_to),      // *** CHANGED: Pass minimum VALUE ***
     //   .pos2(swap_value_from),    // *** CHANGED: Pass current VALUE ***
      //  .show_no_swap(show_no_swap),
      //  .is_text(in_swap_text)
  //  );
    
    // Tutorial selection indicator
    wire [6:0] indicator_x_center = selected_box * BOX_SPACING + (BOX_SPACING / 2);
    wire [5:0] indicator_y = TUT_START_Y + BOX_HEIGHT + 2;
    wire signed [7:0] indicator_x_offset = x - indicator_x_center;
    
//    function is_indicator_pixel;
//        input signed [7:0] x_off;
//        input [5:0] y_pos;
//        begin
//            if (y == y_pos) begin
//                is_indicator_pixel = (x_off >= -2) && (x_off <= 2);
//            end else if (y == y_pos + 1) begin
//                is_indicator_pixel = (x_off >= -1) && (x_off <= 1);
//            end else if (y == y_pos + 2) begin
//                is_indicator_pixel = (x_off == 0);
//            end else begin
//                is_indicator_pixel = 0;
//            end
//        end
//    endfunction

function is_indicator_pixel;
    input signed [7:0] x_off;
    input [5:0] y_pos;
    begin
        if (y == y_pos) begin
            is_indicator_pixel = (x_off >= -2) && (x_off <= 2);
        end else if (y == y_pos + 1) begin
            is_indicator_pixel = (x_off >= -2) && (x_off <= 2);
        end else if (y == y_pos + 2) begin
            is_indicator_pixel = (x_off >= -1) && (x_off <= 1);
        end else if (y == y_pos + 3) begin
            is_indicator_pixel = (x_off == 0);
        end else begin
            is_indicator_pixel = 0;
        end
    end
endfunction
    
    wire is_selection_indicator = is_indicator_pixel(indicator_x_offset, indicator_y);
    
    // Gradient background functions
    function [15:0] get_blue_gradient;
        input [5:0] y_pos;
        begin
            if (y_pos < 21)
                get_blue_gradient = LIGHT_BLUE_TOP;
            else if (y_pos < 43)
                get_blue_gradient = LIGHT_BLUE_MID;
            else
                get_blue_gradient = LIGHT_BLUE_BOT;
        end
    endfunction
    
    function [15:0] get_orange_gradient;
        input [5:0] y_pos;
        begin
            if (y_pos < 21)
                get_orange_gradient = LIGHT_ORANGE_TOP;
            else if (y_pos < 43)
                get_orange_gradient = LIGHT_ORANGE_MID;
            else
                get_orange_gradient = LIGHT_ORANGE_BOT;
        end
    endfunction
    
    // Number rendering
    function in_digit;
        input [2:0] digit;
        input [3:0] x_pos;
        input [5:0] y_pos;
        reg [14:0] pattern;
        begin
            case (digit)
                3'd0: pattern = 15'b111_101_101_101_111;
                3'd1: pattern = 15'b010_110_010_010_111;
                3'd2: pattern = 15'b111_001_111_100_111;
                3'd3: pattern = 15'b111_001_111_001_111;
                3'd4: pattern = 15'b101_101_111_001_001;
                3'd5: pattern = 15'b111_100_111_001_111;
                3'd6: pattern = 15'b111_100_111_101_111;
                3'd7: pattern = 15'b111_001_001_001_001;
                default: pattern = 15'b000_000_000_000_000;
            endcase
            in_digit = (x_pos < 3 && y_pos < 5) ? pattern[14 - (y_pos * 3 + x_pos)] : 1'b0;
        end
    endfunction
    
    // Progress display "X / 6" at top left
    function is_progress_pixel;
        input [6:0] x_coord;
        input [5:0] y_coord;
        input [2:0] progress;
        reg [14:0] digit_pattern;
        reg [2:0] char_x, char_y;
        begin
            is_progress_pixel = 0;
            
            // Display at position (4, 2) - top left
            if (y_coord >= 6'd2 && y_coord < 6'd7) begin
                char_y = y_coord - 2;
                
                // First digit (progress value) at x=4
                if (x_coord >= 7'd4 && x_coord < 7'd7) begin
                    char_x = x_coord - 4;
                    case (progress)
                        3'd0: digit_pattern = 15'b111_101_101_101_111;
                        3'd1: digit_pattern = 15'b010_110_010_010_111;
                        3'd2: digit_pattern = 15'b111_001_111_100_111;
                        3'd3: digit_pattern = 15'b111_001_111_001_111;
                        3'd4: digit_pattern = 15'b101_101_111_001_001;
                        3'd5: digit_pattern = 15'b111_100_111_001_111;
                        3'd6: digit_pattern = 15'b111_100_111_101_111;
                        default: digit_pattern = 15'b000_000_000_000_000;
                    endcase
                    is_progress_pixel = digit_pattern[14 - (char_y * 3 + char_x)];
                end
                // Space at x=7
                // "/" at x=8-10
                else if (x_coord >= 7'd8 && x_coord < 7'd11) begin
                    char_x = x_coord - 8;
                    // Pattern for "/"
                    case (char_y)
                        3'd0: is_progress_pixel = (char_x == 2);
                        3'd1: is_progress_pixel = (char_x == 2);
                        3'd2: is_progress_pixel = (char_x == 1);
                        3'd3: is_progress_pixel = (char_x == 1);
                        3'd4: is_progress_pixel = (char_x == 0);
                        default: is_progress_pixel = 0;
                    endcase
                end
                // Space at x=11
                // "6" at x=12-14
                else if (x_coord >= 7'd12 && x_coord < 7'd15) begin
                    char_x = x_coord - 12;
                    digit_pattern = 15'b111_100_111_101_111; // Pattern for 6
                    is_progress_pixel = digit_pattern[14 - (char_y * 3 + char_x)];
                end
            end
        end
    endfunction
    
    // Attempts counter display "ATT: X/3" at top right
    // Attempts counter display "ATT: X/3" at top right
    function is_attempts_pixel;
        input [6:0] x_coord;
        input [5:0] y_coord;
        input [1:0] wrong_count;  // 0-3
        reg [14:0] digit_pattern;
        reg [2:0] char_x, char_y;
        begin
            is_attempts_pixel = 0;
            
            // Display at position (58, 2) - top right corner
            if (y_coord >= 6'd2 && y_coord < 6'd7) begin
                char_y = y_coord - 2;
                
                // "A" at x=58-60
                if (x_coord >= 7'd58 && x_coord < 7'd61) begin
                    char_x = x_coord - 58;
                    digit_pattern = 15'b010_101_111_101_101; // A
                    is_attempts_pixel = digit_pattern[14 - (char_y * 3 + char_x)];
                end
                // "T" at x=61-63
                else if (x_coord >= 7'd61 && x_coord < 7'd64) begin
                    char_x = x_coord - 61;
                    digit_pattern = 15'b111_010_010_010_010; // T
                    is_attempts_pixel = digit_pattern[14 - (char_y * 3 + char_x)];
                end
                // "T" at x=64-66
                else if (x_coord >= 7'd64 && x_coord < 7'd67) begin
                    char_x = x_coord - 64;
                    digit_pattern = 15'b111_010_010_010_010; // T
                    is_attempts_pixel = digit_pattern[14 - (char_y * 3 + char_x)];
                end
                // ":" at x=67-69
                else if (x_coord >= 7'd67 && x_coord < 7'd70) begin
                    char_x = x_coord - 67;
                    digit_pattern = 15'b000_010_000_010_000; // :
                    is_attempts_pixel = digit_pattern[14 - (char_y * 3 + char_x)];
                end
                // Space at x=70
                // Wrong count digit at x=71-73
                else if (x_coord >= 7'd71 && x_coord < 7'd74) begin
                    char_x = x_coord - 71;
                    case (wrong_count)
                        2'd0: digit_pattern = 15'b111_101_101_101_111; // 0
                        2'd1: digit_pattern = 15'b010_110_010_010_111; // 1
                        2'd2: digit_pattern = 15'b111_001_111_100_111; // 2
                        2'd3: digit_pattern = 15'b111_001_111_001_111; // 3
                        default: digit_pattern = 15'b000_000_000_000_000;
                    endcase
                    is_attempts_pixel = digit_pattern[14 - (char_y * 3 + char_x)];
                end
                // "/" at x=74-76 - FIXED VERSION
                else if (x_coord >= 7'd74 && x_coord < 7'd77) begin
                    char_x = x_coord - 74;
                    // Properly render "/" diagonally
                    if (char_y == 3'd0 && char_x == 2'd2) is_attempts_pixel = 1;
                    else if (char_y == 3'd1 && char_x == 2'd1) is_attempts_pixel = 1;
                    else if (char_y == 3'd2 && char_x == 2'd1) is_attempts_pixel = 1;
                    else if (char_y == 3'd3 && char_x == 2'd0) is_attempts_pixel = 1;
                    else if (char_y == 3'd4 && char_x == 2'd0) is_attempts_pixel = 1;
                    else is_attempts_pixel = 0;
                end
                // "3" at x=77-79 - FIXED VERSION
                else if (x_coord >= 7'd77 && x_coord < 7'd80) begin
                    char_x = x_coord - 77;
                    case (char_y)
                        3'd0: is_attempts_pixel = (char_x == 0 || char_x == 1 || char_x == 2); // Top line
                        3'd1: is_attempts_pixel = (char_x == 2);                                 // Right side
                        3'd2: is_attempts_pixel = (char_x == 0 || char_x == 1 || char_x == 2); // Middle line
                        3'd3: is_attempts_pixel = (char_x == 2);                                 // Right side
                        3'd4: is_attempts_pixel = (char_x == 0 || char_x == 1 || char_x == 2); // Bottom line
                        default: is_attempts_pixel = 0;
                    endcase
                end
            end
        end
    endfunction
    
    // Demo mode boxes
    wire in_box_row = (y >= START_Y) && (y < START_Y + BOX_HEIGHT);
    wire [3:0] box_slot = x / BOX_SPACING;
    wire [2:0] box_index = box_slot[2:0];
    wire [3:0] x_in_slot = x % BOX_SPACING;
    wire [3:0] local_x = x_in_slot - BOX_OFFSET;
    wire [5:0] local_y = y - START_Y;
    wire in_box = in_box_row && (box_slot <= 3'd5) && 
                  (x_in_slot >= BOX_OFFSET) && (x_in_slot < BOX_OFFSET + BOX_WIDTH);
    wire is_tutorial_attempts;
    wire [3:0] num_x = local_x - 6;
    wire [5:0] num_y = local_y - 5;
    wire is_number = in_digit(array[box_index], num_x, num_y);
    wire is_border_box = (local_x == 0) || (local_x == BOX_WIDTH-1) || 
                         (local_y == 0) || (local_y == BOX_HEIGHT-1);
    
    // Tutorial input boxes
    wire tut_in_box_row = (y >= TUT_START_Y) && (y < TUT_START_Y + BOX_HEIGHT);
    wire [3:0] tut_box_slot = x / BOX_SPACING;
    wire [2:0] tut_box_index = tut_box_slot[2:0];
    wire [3:0] tut_x_in_slot = x % BOX_SPACING;
    wire [3:0] tut_local_x = tut_x_in_slot - BOX_OFFSET;
    wire [5:0] tut_local_y = y - TUT_START_Y;
    wire tut_in_box = tut_in_box_row && (tut_box_slot <= 3'd5) && 
                      (tut_x_in_slot >= BOX_OFFSET) && (tut_x_in_slot < BOX_OFFSET + BOX_WIDTH);
    
    wire [3:0] tut_num_x = tut_local_x - 6;
    wire [5:0] tut_num_y = tut_local_y - 5;
    wire tut_is_number = in_digit(tut_array[tut_box_index], tut_num_x, tut_num_y);
    wire tut_is_border = (tut_local_x == 0) || (tut_local_x == BOX_WIDTH-1) || 
                         (tut_local_y == 0) || (tut_local_y == BOX_HEIGHT-1);
    wire is_selected = (tut_box_index == selected_box);
    wire is_confirmed = box_confirmed[tut_box_index];
    
    // Test mode boxes
    wire test_in_box_row = (y >= TEST_START_Y) && (y < TEST_START_Y + BOX_HEIGHT);
    wire [3:0] test_box_slot = x / BOX_SPACING;
    wire [2:0] test_box_index = test_box_slot[2:0];
    wire [3:0] test_x_in_slot = x % BOX_SPACING;
    wire [3:0] test_local_x = test_x_in_slot - BOX_OFFSET;
    wire [5:0] test_local_y = y - TEST_START_Y;
    wire test_in_box = test_in_box_row && (test_box_slot <= 3'd5) && 
                       (test_x_in_slot >= BOX_OFFSET) && (test_x_in_slot < BOX_OFFSET + BOX_WIDTH);
    
    wire [3:0] test_num_x = test_local_x - 6;
    wire [5:0] test_num_y = test_local_y - 5;
    wire test_is_number = in_digit(tut_array[test_box_index], test_num_x, test_num_y);
    wire test_is_border = (test_local_x == 0) || (test_local_x == BOX_WIDTH-1) || 
                          (test_local_y == 0) || (test_local_y == BOX_HEIGHT-1);
    
    reg [15:0] test_box_color;
    always @* begin
        if (test_box_index < test_unsorted_idx) begin
            test_box_color = GREEN;
        end else if (test_box_index == test_unsorted_idx) begin
            test_box_color = YELLOW;
        end else begin
            test_box_color = BLUE;
        end
    end
    
    // Arrow rendering
    wire show_arrow = (state_type == 2'd1) && intro_state == 3'd3;
    
    // ========== MINIMUM DISPLAY LOGIC (CENTERED 5x7) ==========
    // Extract current minimum value
    wire [2:0] min_value = array[min_idx];
    
    // Status text function - 5x7 font, centered
    // Status text function - 5x7 font, centered
    // NEW: Function to display swap information - "SWAP : X <-> Y"
    function is_swap_pixel;
        input [6:0] x_coord;
        input [5:0] y_coord;
        input [2:0] swap_val_1;
        input [2:0] swap_val_2;
        reg [34:0] letter_S, letter_W, letter_A, letter_P, letter_colon, letter_arrow_left, letter_arrow_right, letter_dash;
        reg [2:0] char_x, char_y;
        begin
            // Letter definitions (5x7)
            letter_S = 35'b01110_10001_10000_01110_00001_10001_01110;
            letter_W = 35'b10001_10001_10001_10101_10101_01010_01010;
            letter_A = 35'b01110_10001_10001_11111_10001_10001_10001;
            letter_P = 35'b11110_10001_10001_11110_10000_10000_10000;
            letter_colon = 35'b00000_00100_00000_00000_00000_00100_00000;
            letter_arrow_left = 35'b00010_00110_01110_11110_01110_00110_00010;
            letter_dash = 35'b00000_00000_00000_11111_00000_00000_00000;
            letter_arrow_right = 35'b01000_01100_01110_01111_01110_01100_01000;
            
            is_swap_pixel = 0;
            
            if (y_coord >= 6'd10 && y_coord < 6'd17) begin
                char_y = y_coord - 10;
                
                // Display "SWAP : X <-> Y" - ADJUSTED LEFT BY 6 PIXELS
                // S at x=18 (was 24)
                if (x_coord >= 7'd18 && x_coord < 7'd23) begin
                    char_x = x_coord - 18;
                    is_swap_pixel = letter_S[34 - (char_y * 5 + char_x)];
                end
                // W at x=24 (was 30)
                else if (x_coord >= 7'd24 && x_coord < 7'd29) begin
                    char_x = x_coord - 24;
                    is_swap_pixel = letter_W[34 - (char_y * 5 + char_x)];
                end
                // A at x=30 (was 36)
                else if (x_coord >= 7'd30 && x_coord < 7'd35) begin
                    char_x = x_coord - 30;
                    is_swap_pixel = letter_A[34 - (char_y * 5 + char_x)];
                end
                // P at x=36 (was 42)
                else if (x_coord >= 7'd36 && x_coord < 7'd41) begin
                    char_x = x_coord - 36;
                    is_swap_pixel = letter_P[34 - (char_y * 5 + char_x)];
                end
                // : at x=43 (was 49)
                else if (x_coord >= 7'd43 && x_coord < 7'd48) begin
                    char_x = x_coord - 43;
                    is_swap_pixel = letter_colon[34 - (char_y * 5 + char_x)];
                end
                // First number at x=50 (was 56)
                else if (x_coord >= 7'd50 && x_coord < 7'd55) begin
                    char_x = x_coord - 50;
                    case (swap_val_1)
                        3'd0: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 0 || char_x == 4 || char_x == 1 || char_x == 2 || char_x == 3);
                                3'd1: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd2: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd3: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd4: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd5: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd6: is_swap_pixel = (char_x == 0 || char_x == 4 || char_x == 1 || char_x == 2 || char_x == 3);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        3'd1: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 2 || char_x == 1);
                                3'd1: is_swap_pixel = (char_x == 2 || char_x == 1);
                                3'd2: is_swap_pixel = (char_x == 2);
                                3'd3: is_swap_pixel = (char_x == 2);
                                3'd4: is_swap_pixel = (char_x == 2);
                                3'd5: is_swap_pixel = (char_x == 2);
                                3'd6: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        3'd2: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd1: is_swap_pixel = (char_x == 4);
                                3'd2: is_swap_pixel = (char_x == 4);
                                3'd3: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd4: is_swap_pixel = (char_x == 0);
                                3'd5: is_swap_pixel = (char_x == 0);
                                3'd6: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        3'd3: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd1: is_swap_pixel = (char_x == 4);
                                3'd2: is_swap_pixel = (char_x == 4);
                                3'd3: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd4: is_swap_pixel = (char_x == 4);
                                3'd5: is_swap_pixel = (char_x == 4);
                                3'd6: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        3'd4: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd1: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd2: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd3: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd4: is_swap_pixel = (char_x == 4);
                                3'd5: is_swap_pixel = (char_x == 4);
                                3'd6: is_swap_pixel = (char_x == 4);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        3'd5: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd1: is_swap_pixel = (char_x == 0);
                                3'd2: is_swap_pixel = (char_x == 0);
                                3'd3: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd4: is_swap_pixel = (char_x == 4);
                                3'd5: is_swap_pixel = (char_x == 4);
                                3'd6: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        3'd6: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd1: is_swap_pixel = (char_x == 0);
                                3'd2: is_swap_pixel = (char_x == 0);
                                3'd3: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd4: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd5: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd6: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        3'd7: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd1: is_swap_pixel = (char_x == 4);
                                3'd2: is_swap_pixel = (char_x == 4);
                                3'd3: is_swap_pixel = (char_x == 4);
                                3'd4: is_swap_pixel = (char_x == 4);
                                3'd5: is_swap_pixel = (char_x == 4);
                                3'd6: is_swap_pixel = (char_x == 4);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        default: is_swap_pixel = 0;
                    endcase
                end
                // "<->" at x=57-67 (was 63-73)
                else if (x_coord >= 7'd57 && x_coord < 7'd62) begin
                    char_x = x_coord - 57;
                    is_swap_pixel = letter_arrow_left[34 - (char_y * 5 + char_x)];
                end
                else if (x_coord >= 7'd62 && x_coord < 7'd67) begin
                    char_x = x_coord - 62;
                    is_swap_pixel = letter_arrow_right[34 - (char_y * 5 + char_x)];
                end
                // Second number at x=69 (was 75)
                else if (x_coord >= 7'd69 && x_coord < 7'd74) begin
                    char_x = x_coord - 69;
                    case (swap_val_2)
                        3'd0: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 0 || char_x == 4 || char_x == 1 || char_x == 2 || char_x == 3);
                                3'd1: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd2: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd3: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd4: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd5: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd6: is_swap_pixel = (char_x == 0 || char_x == 4 || char_x == 1 || char_x == 2 || char_x == 3);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        3'd1: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 2 || char_x == 1);
                                3'd1: is_swap_pixel = (char_x == 2 || char_x == 1);
                                3'd2: is_swap_pixel = (char_x == 2);
                                3'd3: is_swap_pixel = (char_x == 2);
                                3'd4: is_swap_pixel = (char_x == 2);
                                3'd5: is_swap_pixel = (char_x == 2);
                                3'd6: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        3'd2: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd1: is_swap_pixel = (char_x == 4);
                                3'd2: is_swap_pixel = (char_x == 4);
                                3'd3: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd4: is_swap_pixel = (char_x == 0);
                                3'd5: is_swap_pixel = (char_x == 0);
                                3'd6: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        3'd3: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd1: is_swap_pixel = (char_x == 4);
                                3'd2: is_swap_pixel = (char_x == 4);
                                3'd3: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd4: is_swap_pixel = (char_x == 4);
                                3'd5: is_swap_pixel = (char_x == 4);
                                3'd6: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        3'd4: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd1: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd2: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd3: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd4: is_swap_pixel = (char_x == 4);
                                3'd5: is_swap_pixel = (char_x == 4);
                                3'd6: is_swap_pixel = (char_x == 4);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        3'd5: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd1: is_swap_pixel = (char_x == 0);
                                3'd2: is_swap_pixel = (char_x == 0);
                                3'd3: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd4: is_swap_pixel = (char_x == 4);
                                3'd5: is_swap_pixel = (char_x == 4);
                                3'd6: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        3'd6: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd1: is_swap_pixel = (char_x == 0);
                                3'd2: is_swap_pixel = (char_x == 0);
                                3'd3: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd4: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd5: is_swap_pixel = (char_x == 0 || char_x == 4);
                                3'd6: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        3'd7: begin
                            case (char_y)
                                3'd0: is_swap_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                3'd1: is_swap_pixel = (char_x == 4);
                                3'd2: is_swap_pixel = (char_x == 4);
                                3'd3: is_swap_pixel = (char_x == 4);
                                3'd4: is_swap_pixel = (char_x == 4);
                                3'd5: is_swap_pixel = (char_x == 4);
                                3'd6: is_swap_pixel = (char_x == 4);
                                default: is_swap_pixel = 0;
                            endcase
                        end
                        default: is_swap_pixel = 0;
                    endcase
                end
            end
        end
    endfunction
    
    // NEW: Function to display "SWAP : NO"
   function is_no_swap_pixel;
        input [6:0] x_coord;
        input [5:0] y_coord;
        reg [34:0] letter_S, letter_W, letter_A, letter_P, letter_colon, letter_N, letter_O;
        reg [2:0] char_x, char_y;
        begin
            // Letter definitions (5x7)
            letter_S = 35'b01110_10001_10000_01110_00001_10001_01110;
            letter_W = 35'b10001_10001_10001_10101_10101_01010_01010;
            letter_A = 35'b01110_10001_10001_11111_10001_10001_10001;
            letter_P = 35'b11110_10001_10001_11110_10000_10000_10000;
            letter_colon = 35'b00000_00100_00000_00000_00000_00100_00000;
            letter_N = 35'b10001_11001_10101_10011_10001_10001_10001;
            letter_O = 35'b01110_10001_10001_10001_10001_10001_01110;
            
            is_no_swap_pixel = 0;
            
            if (y_coord >= 6'd10 && y_coord < 6'd17) begin
                char_y = y_coord - 10;
                
                // Display "SWAP : NO" - ADJUSTED LEFT BY 6 PIXELS
                // S at x=24 (was 30)
                if (x_coord >= 7'd24 && x_coord < 7'd29) begin
                    char_x = x_coord - 24;
                    is_no_swap_pixel = letter_S[34 - (char_y * 5 + char_x)];
                end
                // W at x=30 (was 36)
                else if (x_coord >= 7'd30 && x_coord < 7'd35) begin
                    char_x = x_coord - 30;
                    is_no_swap_pixel = letter_W[34 - (char_y * 5 + char_x)];
                end
                // A at x=36 (was 42)
                else if (x_coord >= 7'd36 && x_coord < 7'd41) begin
                    char_x = x_coord - 36;
                    is_no_swap_pixel = letter_A[34 - (char_y * 5 + char_x)];
                end
                // P at x=42 (was 48)
                else if (x_coord >= 7'd42 && x_coord < 7'd47) begin
                    char_x = x_coord - 42;
                    is_no_swap_pixel = letter_P[34 - (char_y * 5 + char_x)];
                end
                // : at x=49 (was 55)
                else if (x_coord >= 7'd49 && x_coord < 7'd54) begin
                    char_x = x_coord - 49;
                    is_no_swap_pixel = letter_colon[34 - (char_y * 5 + char_x)];
                end
                // N at x=56 (was 62)
                else if (x_coord >= 7'd56 && x_coord < 7'd61) begin
                    char_x = x_coord - 56;
                    is_no_swap_pixel = letter_N[34 - (char_y * 5 + char_x)];
                end
                // O at x=62 (was 68)
                else if (x_coord >= 7'd62 && x_coord < 7'd67) begin
                    char_x = x_coord - 62;
                    is_no_swap_pixel = letter_O[34 - (char_y * 5 + char_x)];
                end
            end
        end
    endfunction
    
    // Status text function - 5x7 font, centered - displays "MIN : X" or "MINIMUM : X"
    function is_status_pixel;
        input [6:0] x_coord;
        input [5:0] y_coord;
        input show_done;
        input [2:0] minimum_val;
        input show_number;
        input use_short_text;  // 1 for "MIN :", 0 for "MINIMUM :"
        reg [34:0] letter_M, letter_I, letter_N, letter_U, letter_colon, letter_D, letter_O, letter_E, letter_exclaim;
        reg [2:0] char_x, char_y;
        begin
            // Letter definitions (5x7)
            letter_M = 35'b10001_11011_10101_10001_10001_10001_10001;
            letter_I = 35'b01110_00100_00100_00100_00100_00100_01110;
            letter_N = 35'b10001_11001_10101_10011_10001_10001_10001;
            letter_U = 35'b10001_10001_10001_10001_10001_10001_01110;
            letter_colon = 35'b00000_00100_00000_00000_00000_00100_00000;
            letter_D = 35'b11110_10011_10001_10001_10001_10011_11110;
            letter_O = 35'b01110_10001_10001_10001_10001_10001_01110;
            letter_E = 35'b11111_10000_10000_11110_10000_10000_11111;
            letter_exclaim = 35'b00100_00100_00100_00100_00100_00000_00100;
            
            is_status_pixel = 0;
            
            if (y_coord >= 6'd10 && y_coord < 6'd17) begin
                char_y = y_coord - 10;
                
                if (show_done) begin
                    // Display "DONE!" - centered
                    // 5 letters * 5 wide + 4 spaces * 1 = 29 pixels
                    // Start at (96-29)/2 = 33
                    if (x_coord >= 7'd34 && x_coord < 7'd39) begin
                        char_x = x_coord - 34;
                        is_status_pixel = letter_D[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd40 && x_coord < 7'd45) begin
                        char_x = x_coord - 40;
                        is_status_pixel = letter_O[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd46 && x_coord < 7'd51) begin
                        char_x = x_coord - 46;
                        is_status_pixel = letter_N[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd52 && x_coord < 7'd57) begin
                        char_x = x_coord - 52;
                        is_status_pixel = letter_E[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd58 && x_coord < 7'd63) begin
                        char_x = x_coord - 58;
                        is_status_pixel = letter_exclaim[34 - (char_y * 5 + char_x)];
                    end
                end else if (use_short_text) begin
                    // Display "MIN : X" - centered
                    // 3 letters * 5 wide + 4 spaces + 5 wide colon + 2 spaces + 5 wide digit = 33 pixels
                    // Start at (96-33)/2 = 31
                    if (x_coord >= 7'd31 && x_coord < 7'd36) begin
                        char_x = x_coord - 31;
                        is_status_pixel = letter_M[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd37 && x_coord < 7'd42) begin
                        char_x = x_coord - 37;
                        is_status_pixel = letter_I[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd43 && x_coord < 7'd48) begin
                        char_x = x_coord - 43;
                        is_status_pixel = letter_N[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd50 && x_coord < 7'd55) begin
                        char_x = x_coord - 50;
                        is_status_pixel = letter_colon[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd57 && x_coord < 7'd62 && show_number) begin
                        // Display the minimum number (5x7 digit)
                        char_x = x_coord - 57;
                        case (minimum_val)
                            3'd0: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 0 || char_x == 4 || char_x == 1 || char_x == 2 || char_x == 3);
                                    3'd1: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd2: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd3: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd4: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd5: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd6: is_status_pixel = (char_x == 0 || char_x == 4 || char_x == 1 || char_x == 2 || char_x == 3);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            3'd1: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 2 || char_x == 1);
                                    3'd1: is_status_pixel = (char_x == 2 || char_x == 1);
                                    3'd2: is_status_pixel = (char_x == 2);
                                    3'd3: is_status_pixel = (char_x == 2);
                                    3'd4: is_status_pixel = (char_x == 2);
                                    3'd5: is_status_pixel = (char_x == 2);
                                    3'd6: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            3'd2: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd1: is_status_pixel = (char_x == 4);
                                    3'd2: is_status_pixel = (char_x == 4);
                                    3'd3: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd4: is_status_pixel = (char_x == 0);
                                    3'd5: is_status_pixel = (char_x == 0);
                                    3'd6: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            3'd3: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd1: is_status_pixel = (char_x == 4);
                                    3'd2: is_status_pixel = (char_x == 4);
                                    3'd3: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd4: is_status_pixel = (char_x == 4);
                                    3'd5: is_status_pixel = (char_x == 4);
                                    3'd6: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            3'd4: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd1: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd2: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd3: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd4: is_status_pixel = (char_x == 4);
                                    3'd5: is_status_pixel = (char_x == 4);
                                    3'd6: is_status_pixel = (char_x == 4);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            3'd5: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd1: is_status_pixel = (char_x == 0);
                                    3'd2: is_status_pixel = (char_x == 0);
                                    3'd3: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd4: is_status_pixel = (char_x == 4);
                                    3'd5: is_status_pixel = (char_x == 4);
                                    3'd6: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            3'd6: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd1: is_status_pixel = (char_x == 0);
                                    3'd2: is_status_pixel = (char_x == 0);
                                    3'd3: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd4: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd5: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd6: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            3'd7: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd1: is_status_pixel = (char_x == 4);
                                    3'd2: is_status_pixel = (char_x == 4);
                                    3'd3: is_status_pixel = (char_x == 4);
                                    3'd4: is_status_pixel = (char_x == 4);
                                    3'd5: is_status_pixel = (char_x == 4);
                                    3'd6: is_status_pixel = (char_x == 4);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            default: is_status_pixel = 0;
                        endcase
                    end
                end else begin
                    // Display "MINIMUM : X" - centered (existing code)
                    if (x_coord >= 7'd24 && x_coord < 7'd29) begin
                        char_x = x_coord - 24;
                        is_status_pixel = letter_M[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd32 && x_coord < 7'd37) begin
                        char_x = x_coord - 32;
                        is_status_pixel = letter_I[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd38 && x_coord < 7'd43) begin
                        char_x = x_coord - 38;
                        is_status_pixel = letter_N[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd44 && x_coord < 7'd49) begin
                        char_x = x_coord - 44;
                        is_status_pixel = letter_I[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd50 && x_coord < 7'd55) begin
                        char_x = x_coord - 50;
                        is_status_pixel = letter_M[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd56 && x_coord < 7'd61) begin
                        char_x = x_coord - 56;
                        is_status_pixel = letter_U[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd62 && x_coord < 7'd67) begin
                        char_x = x_coord - 62;
                        is_status_pixel = letter_M[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd69 && x_coord < 7'd74) begin
                        char_x = x_coord - 69;
                        is_status_pixel = letter_colon[34 - (char_y * 5 + char_x)];
                    end else if (x_coord >= 7'd76 && x_coord < 7'd81 && show_number) begin
                        char_x = x_coord - 76;
                        // Same digit patterns as above
                        case (minimum_val)
                            3'd0: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 0 || char_x == 4 || char_x == 1 || char_x == 2 || char_x == 3);
                                    3'd1: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd2: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd3: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd4: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd5: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd6: is_status_pixel = (char_x == 0 || char_x == 4 || char_x == 1 || char_x == 2 || char_x == 3);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            3'd1: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 2 || char_x == 1);
                                    3'd1: is_status_pixel = (char_x == 2 || char_x == 1);
                                    3'd2: is_status_pixel = (char_x == 2);
                                    3'd3: is_status_pixel = (char_x == 2);
                                    3'd4: is_status_pixel = (char_x == 2);
                                    3'd5: is_status_pixel = (char_x == 2);
                                    3'd6: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            3'd2: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd1: is_status_pixel = (char_x == 4);
                                    3'd2: is_status_pixel = (char_x == 4);
                                    3'd3: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd4: is_status_pixel = (char_x == 0);
                                    3'd5: is_status_pixel = (char_x == 0);
                                    3'd6: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            3'd3: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd1: is_status_pixel = (char_x == 4);
                                    3'd2: is_status_pixel = (char_x == 4);
                                    3'd3: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd4: is_status_pixel = (char_x == 4);
                                    3'd5: is_status_pixel = (char_x == 4);
                                    3'd6: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            3'd4: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd1: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd2: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd3: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd4: is_status_pixel = (char_x == 4);
                                    3'd5: is_status_pixel = (char_x == 4);
                                    3'd6: is_status_pixel = (char_x == 4);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            3'd5: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd1: is_status_pixel = (char_x == 0);
                                    3'd2: is_status_pixel = (char_x == 0);
                                    3'd3: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd4: is_status_pixel = (char_x == 4);
                                    3'd5: is_status_pixel = (char_x == 4);
                                    3'd6: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            3'd6: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd1: is_status_pixel = (char_x == 0);
                                    3'd2: is_status_pixel = (char_x == 0);
                                    3'd3: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd4: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd5: is_status_pixel = (char_x == 0 || char_x == 4);
                                    3'd6: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            3'd7: begin
                                case (char_y)
                                    3'd0: is_status_pixel = (char_x == 0 || char_x == 1 || char_x == 2 || char_x == 3 || char_x == 4);
                                    3'd1: is_status_pixel = (char_x == 4);
                                    3'd2: is_status_pixel = (char_x == 4);
                                    3'd3: is_status_pixel = (char_x == 4);
                                    3'd4: is_status_pixel = (char_x == 4);
                                    3'd5: is_status_pixel = (char_x == 4);
                                    3'd6: is_status_pixel = (char_x == 4);
                                    default: is_status_pixel = 0;
                                endcase
                            end
                            default: is_status_pixel = 0;
                        endcase
                    end
                end
            end
        end
    endfunction
    
    // Status display logic - at the top of the always @(*) block in demo mode
    // Status display logic - at the top of the always @(*) block in demo mode
    wire show_status_text = (intro_state == 3'd3) && !show_swap_info;  // Show MIN when not showing swap
    wire show_swap_display = show_swap_info && (intro_state == 3'd3);
    wire needs_swap = (current_i != min_idx);
    
    // *** IMPORTANT: Define these BEFORE is_swap_display ***
    wire [2:0] swap_value_from = array[current_i];  // Value at current position
    wire [2:0] swap_value_to = array[min_idx];      // Value at minimum position
    
    wire is_swap_display = show_swap_display && 
                           (needs_swap ? is_swap_pixel(x, y, swap_value_to, swap_value_from) : 
                                        is_no_swap_pixel(x, y));
    wire is_status_text = show_status_text && is_status_pixel(x, y, sort_complete, min_value, 1'b1, 1'b1);
    
    // Tutorial minimum display - show "MINIMUM :" always during test, but NOT during CORRECT/WRONG feedback
    wire show_tutorial_min = tutorial_mode && 
                              (tutorial_state == 4'd8 || tutorial_state == 4'd9);  // Only show during FIND_MIN and SELECT_SWAP
    wire show_tutorial_number = tutorial_mode && 
                                 (tutorial_state == 4'd9);  // Only show number after user selects
    wire [2:0] tutorial_min_value = tut_array[user_min_selected];
    wire is_tutorial_min_text = show_tutorial_min && is_status_pixel(x, y, 1'b0, tutorial_min_value, show_tutorial_number, 1'b1);
    
    // NEW: Progress display for tutorial mode
    wire show_tutorial_progress = tutorial_mode && 
                                   (tutorial_state >= 4'd7 && tutorial_state <= 4'd11);
    wire is_tutorial_progress = show_tutorial_progress && is_progress_pixel(x, y, tutorial_progress);
    
    wire [6:0] arrow_center_x = min_idx * BOX_SPACING + (BOX_SPACING / 2);
    wire [6:0] arrow_y_start = START_Y - 10;
    wire [6:0] arrow_y_end = arrow_y_start + 9;
    
    wire in_arrow_y_range = (y >= arrow_y_start) && (y < arrow_y_end);
    wire signed [7:0] arrow_x_offset = x - arrow_center_x;
    wire [3:0] arrow_local_y = y - arrow_y_start;
    
    function is_arrow_pixel;
        input signed [7:0] x_off;
        input [3:0] y_level;
        begin
            case (y_level)
                4'd0: is_arrow_pixel = (x_off >= -1) && (x_off <= 1);
                4'd1: is_arrow_pixel = (x_off >= -1) && (x_off <= 1);
                4'd2: is_arrow_pixel = (x_off >= -1) && (x_off <= 1);
                4'd3: is_arrow_pixel = (x_off >= -1) && (x_off <= 1);
                4'd4: is_arrow_pixel = (x_off >= -1) && (x_off <= 1);
                4'd5: is_arrow_pixel = (x_off >= -1) && (x_off <= 1);
                4'd6: is_arrow_pixel = (x_off >= -3) && (x_off <= 3);
                4'd7: is_arrow_pixel = (x_off >= -2) && (x_off <= 2);
                4'd8: is_arrow_pixel = (x_off >= -1) && (x_off <= 1);
                default: is_arrow_pixel = 1'b0;
            endcase
        end
    endfunction
    
    wire is_arrow = show_arrow && in_arrow_y_range && 
                    is_arrow_pixel(arrow_x_offset, arrow_local_y);
    
    reg [15:0] box_color;
    always @* begin
        if (state_type == 2'd3) begin
            box_color = GREEN;
        end else if (box_index < current_i) begin
            box_color = GREEN;
        end else if (box_index == current_j && state_type == 2'd1) begin
            box_color = YELLOW;
        end else if (box_index == min_idx && (state_type == 2'd1 || state_type == 2'd2)) begin
            box_color = RED;
        end else begin
            box_color = BLUE;
        end
    end
    
    // WELL DONE celebration wires (declare before always block)
    wire [3:0] text_pulse = tutorial_timer[9:6];
    wire text_bright = (text_pulse > 4'd7);
    wire [7:0] gentle_sparkle_seed = x[5:0] ^ y[4:0] ^ tutorial_timer[9:2];
    wire is_gentle_sparkle = (gentle_sparkle_seed[7:4] == 4'b1111) && (tutorial_timer[5:3] == 3'b111);
    wire [6:0] slow_star_x1 = (x + tutorial_timer[10:4]) % 96;
    wire [5:0] slow_star_y1 = (y + tutorial_timer[9:3]) % 64;
    wire is_slow_star1 = ((slow_star_x1[4:0] == 5'd15) && (slow_star_y1[4:0] == 5'd15));
    wire [6:0] slow_star_x2 = (x + 48 + tutorial_timer[10:4]) % 96;
    wire [5:0] slow_star_y2 = (y + 32 + tutorial_timer[9:3]) % 64;
    wire is_slow_star2 = ((slow_star_x2[4:0] == 5'd15) && (slow_star_y2[4:0] == 5'd15));
    wire [7:0] gentle_wave = (x + tutorial_timer[8:2]) ^ (y + tutorial_timer[7:1]);
    wire is_gentle_wave = (gentle_wave[7:5] == 3'b111) && (gentle_wave[3:0] > 4'd12);
    wire near_box = test_in_box && ((test_local_x <= 2) || (test_local_x >= BOX_WIDTH-3) || (test_local_y <= 2) || (test_local_y >= BOX_HEIGHT-3));
    wire is_gentle_border = (y < 2) || (y >= 62) || (x < 2) || (x >= 94);
    wire gentle_border_pulse = tutorial_timer[8:6] > 3'd5;
    reg [15:0] calm_bg_color;
    // MAIN OUTPUT LOGIC
    always @(*) begin
        if (!enable) begin
            pixel_data = BLACK;
        end else if (tutorial_mode) begin
            if (tutorial_state <= 4'd4) begin
                if (tutorial_state == 4'd4) begin
                    if (in_tutorial_text) begin
                        pixel_data = WHITE;
                    end else begin
                        pixel_data = background_color;
                    end
                end else begin
                    pixel_data = in_tutorial_text ? WHITE : BLACK;
                end
            end else if (tutorial_state == 4'd5) begin
                if (in_input_num_text) begin
                    pixel_data = BLACK;
                end else if (is_selection_indicator) begin
                    pixel_data = DARK_RED;
                end else if (tut_in_box) begin
                    if (tut_is_number) begin
                        pixel_data = WHITE;
                    end else if (tut_is_border) begin
                        pixel_data = WHITE;
                    end else begin
                        if (is_confirmed) begin
                            pixel_data = BRIGHT_GREEN;
                        end else begin
                            pixel_data = BLACK;
                        end
                    end
                     end else if (is_circle_float1) begin
                           pixel_data = CYAN;
                       end else if (is_star_float) begin
                           pixel_data = YELLOW;
                       end else if (is_square_float) begin
                           pixel_data = WHITE;
                       end else if (is_triangle_float) begin
                           pixel_data = MAGENTA;
                end else begin
                    pixel_data = get_blue_gradient(y);
                end
           end else if (tutorial_state == 4'd6) begin
                    // Check if we're in explosion phase (tutorial_timer indicates this)
                    if (tutorial_timer > 12'd240) begin  // After 4 seconds of blinking, show explosion
                        if (is_explosion_effect) begin
                            if (is_exp_circle1) pixel_data = RED;
                            else if (is_exp_circle2) pixel_data = ORANGE;
                            else if (is_exp_circle3) pixel_data = YELLOW;
                            else pixel_data = WHITE;
                        end else if (explosion_flash) begin
                            pixel_data = YELLOW;
                        end else begin
                            pixel_data = BLACK;
                        end
                    end else begin
                        // Blinking BEGIN text for first 4 seconds
                        pixel_data = in_begin_text ? WHITE : BLACK;
                    end
                
            end else if (tutorial_state == 4'd7 || tutorial_state == 4'd8 || 
                                                            tutorial_state == 4'd9) begin
                        if (is_tutorial_progress) begin  // NEW: Add progress display first
                            pixel_data = CYAN;
                         end else if (is_attempts_pixel(x, y, wrong_attempt_count)) begin  // ADD THIS
                                    pixel_data = DARK_GREEN;  // Show attempts counter in yellow
                        end else if (is_tutorial_min_text) begin
                            pixel_data = BLACK;
                        end else if (in_test_cursor) begin
                            pixel_data = DARK_RED;
                        end else if (test_in_box) begin
                            if (test_is_number) begin
                                pixel_data = BLACK;
                            end else if (test_is_border) begin
                                pixel_data = WHITE;
                            end else begin
                                pixel_data = test_box_color;
                            end
                        end else if (is_circle_float1) begin
                            pixel_data = ORANGE;
                        end else if (is_star_float) begin
                            pixel_data = YELLOW;
                        end else if (is_square_float) begin
                            pixel_data = WHITE;
                        end else if (is_triangle_float) begin
                            pixel_data = RED;
                        end else begin
                            pixel_data = get_orange_gradient(y);
                        end
                
            end else if (tutorial_state == 4'd10) begin
                             if (is_tutorial_progress) begin  // NEW
                   pixel_data = CYAN;
                            end else if (in_correct_text) begin
                                pixel_data = GREEN;
                            end else if (test_in_box) begin
                                if (test_is_number) begin
                                    pixel_data = BLACK;
                                end else if (test_is_border) begin
                                    pixel_data = BLACK;
                                end else begin
                                    pixel_data = test_box_color;
                                end
                            end else begin
                                pixel_data = BLACK;
                            end
                
           end else if (tutorial_state == 4'd11) begin
                                if (is_tutorial_progress) begin  // NEW
                   pixel_data = CYAN;
                   end else if (is_attempts_pixel(x, y, wrong_attempt_count)) begin  // ADD THIS
                           pixel_data = DARK_RED;  // Orange during wrong feedback to draw attention
                                end else if (in_wrong_text) begin
                                    pixel_data = RED;
                                end else if (test_in_box) begin
                                    if (test_is_number) begin
                                        pixel_data = BLACK;
                                    end else if (test_is_border) begin
                                        pixel_data = BLACK;
                                    end else begin
                                        pixel_data = test_box_color;
                                    end
                                end else begin
                                    pixel_data = BLACK;
                                end
                                
                                end else if (tutorial_state == 4'd13) begin  // TUTORIAL_FAILED - NEW
                                    if (in_failed_text) begin
                                        pixel_data = RED;  // Display FAILED in RED
                                    end else if (test_in_box) begin
                                        if (test_is_number) begin
                                            pixel_data = BLACK;
                                        end else if (test_is_border) begin
                                            pixel_data = BLACK;
                                        end else begin
                                            pixel_data = test_box_color;
                                        end
                                    end else begin
                                        pixel_data = BLACK;
                                    end
                
            end else if (tutorial_state == 4'd12) begin
                                    // ========== CALM CELEBRATION FOR WELL DONE ==========
                                    
                                    // Gentle gradient background (soft pastel blue to green)
                                    if (y < 21) begin
                                        calm_bg_color = 16'hAEFF;  // Soft light blue
                                    end else if (y < 42) begin
                                        calm_bg_color = 16'h9FFD;  // Light cyan
                                    end else begin
                                        calm_bg_color = 16'h8FDB;  // Soft green-cyan
                                    end
                                    
                                    // Render priority
                                    if (in_well_done_text) begin
                                        // Pulsing WELL DONE text between green and bright green
                                        pixel_data = text_bright ? 16'h07E0 : 16'h57EA;  // GREEN to BRIGHT_GREEN
                                    end else if (test_in_box) begin
                                        if (test_is_number) begin
                                            pixel_data = WHITE;
                                        end else if (test_is_border) begin
                                            pixel_data = 16'h07E0;  // Green border
                                        end else if (near_box) begin
                                            pixel_data = 16'h57EA;  // Soft bright green glow near edges
                                        end else begin
                                            pixel_data = 16'h2FE7;  // Soft green fill
                                        end
                                    end else if (is_gentle_sparkle) begin
                                        pixel_data = 16'hFFFF;  // White sparkles
                                    end else if (is_slow_star1 || is_slow_star2) begin
                                        pixel_data = 16'hFFE0;  // Yellow stars
                                    end else if (is_gentle_wave) begin
                                        pixel_data = 16'hDFFF;  // Very light cyan wave
                                    end else if (is_gentle_border && gentle_border_pulse) begin
                                        pixel_data = 16'h07FF;  // Soft cyan border
                                    end else if (is_circle_float1) begin
                                        pixel_data = 16'hFED8;  // Soft yellow circle
                                    end else if (is_star_float) begin
                                        pixel_data = 16'hFFE0;  // Yellow floating star
                                    end else if (is_square_float) begin
                                        pixel_data = 16'hDFFF;  // Light cyan square
                                    end else if (is_triangle_float) begin
                                        pixel_data = 16'hFEBA;  // Soft orange triangle
                                    end else begin
                                        pixel_data = calm_bg_color;  // Gradient background
                                    end
                                end else begin
                                    pixel_data = BLACK;
                                end                      
            
         end else if (intro_state < 3'd3) begin
                                           pixel_data = in_intro_text ? WHITE : BLACK;
                                       end else begin
                                           // Demo mode rendering - FIXED: Check swap display FIRST
                                           if (is_swap_display) begin
                                               pixel_data = CYAN;  // Cyan color for swap text
                                           end else if (is_status_text) begin
                                               pixel_data = sort_complete ? GREEN : WHITE;
                                           end else if (is_arrow) begin
                                               pixel_data = WHITE;
                                           end else if (in_box) begin
                      // Normal rendering - no animation
                      if (is_number)
                          pixel_data = WHITE;
                      else if (is_border_box)
                          pixel_data = WHITE;
                      else
                          pixel_data = box_color;
                  end else begin
                      pixel_data = BLACK;
                  end
              end
              end

endmodule


//// ========== CURSOR RENDERER ==========
//module cursor_renderer(
//    input [6:0] x,
//    input [5:0] y,
//    input [2:0] cursor_pos,
//    input [5:0] start_y,
//    output reg is_cursor
//);
//    localparam BOX_SPACING = 16;
//    localparam BOX_HEIGHT = 15;
    
//    wire [6:0] cursor_x_center = cursor_pos * BOX_SPACING + (BOX_SPACING / 2);
//    wire [5:0] cursor_y = start_y + BOX_HEIGHT + 2;
//    wire signed [7:0] cursor_x_offset = x - cursor_x_center;
    
//    always @(*) begin
//        is_cursor = 0;
//        if (y == cursor_y) begin
//            is_cursor = (cursor_x_offset >= -2) && (cursor_x_offset <= 2);
//        end else if (y == cursor_y + 1) begin
//            is_cursor = (cursor_x_offset >= -1) && (cursor_x_offset <= 1);
//        end else if (y == cursor_y + 2) begin
//            is_cursor = (cursor_x_offset == 0);
//        end
//    end
//endmodule

// ========== CURSOR RENDERER ==========
module cursor_renderer(
    input [6:0] x,
    input [5:0] y,
    input [2:0] cursor_pos,
    input [5:0] start_y,
    output reg is_cursor
);
    localparam BOX_SPACING = 16;
    localparam BOX_HEIGHT = 15;
    
    wire [6:0] cursor_x_center = cursor_pos * BOX_SPACING + (BOX_SPACING / 2);
    wire [5:0] cursor_y = start_y + BOX_HEIGHT + 2;
    wire signed [7:0] cursor_x_offset = x - cursor_x_center;
    
    always @(*) begin
        is_cursor = 0;
        // Row 0 - widest part (5 pixels wide)
        if (y == cursor_y) begin
            is_cursor = (cursor_x_offset >= -2) && (cursor_x_offset <= 2);
        end 
        // Row 1 (5 pixels wide)
        else if (y == cursor_y + 1) begin
            is_cursor = (cursor_x_offset >= -2) && (cursor_x_offset <= 2);
        end 
        // Row 2 (3 pixels wide)
        else if (y == cursor_y + 2) begin
            is_cursor = (cursor_x_offset >= -1) && (cursor_x_offset <= 1);
        end 
        // Row 3 - arrow tip (1 pixel)
        else if (y == cursor_y + 3) begin
            is_cursor = (cursor_x_offset == 0);
        end
    end
endmodule

// ========== CORRECT TEXT RENDERER ==========
module correct_text_renderer(
    input [6:0] x,
    input [5:0] y,
    output reg is_text
);
    function [34:0] get_letter;
        input [7:0] char;
        begin
            case (char)
                "C": get_letter = 35'b01110_10001_10000_10000_10000_10001_01110;
                "O": get_letter = 35'b01110_10001_10001_10001_10001_10001_01110;
                "R": get_letter = 35'b11110_10001_10001_11110_10100_10010_10001;
                "E": get_letter = 35'b11111_10000_10000_11110_10000_10000_11111;
                "T": get_letter = 35'b11111_00100_00100_00100_00100_00100_00100;
                "!": get_letter = 35'b00100_00100_00100_00100_00100_00000_00100;
                default: get_letter = 35'b00000_00000_00000_00000_00000_00000_00000;
            endcase
        end
    endfunction
    
    function is_in_letter;
        input [7:0] char;
        input [6:0] x_start;
        input [6:0] x_coord;
        input [5:0] y_coord;
        input [5:0] y_start;
        reg [34:0] pattern;
        reg [2:0] local_x;
        reg [2:0] local_y;
        begin
            is_in_letter = 0;
            if (x_coord >= x_start && x_coord < x_start + 5 && 
                y_coord >= y_start && y_coord < y_start + 7) begin
                local_x = x_coord - x_start;
                local_y = y_coord - y_start;
                pattern = get_letter(char);
                is_in_letter = pattern[34 - (local_y * 5 + local_x)];
            end
        end
    endfunction
    
    localparam WORD_Y = 10;
    
    always @(*) begin
        is_text = 0;
        if (y >= WORD_Y && y < WORD_Y + 7) begin
            if (x >= 24 && x < 29) is_text = is_in_letter("C", 24, x, y, WORD_Y);
            else if (x >= 30 && x < 35) is_text = is_in_letter("O", 30, x, y, WORD_Y);
            else if (x >= 36 && x < 41) is_text = is_in_letter("R", 36, x, y, WORD_Y);
            else if (x >= 42 && x < 47) is_text = is_in_letter("R", 42, x, y, WORD_Y);
            else if (x >= 48 && x < 53) is_text = is_in_letter("E", 48, x, y, WORD_Y);
            else if (x >= 54 && x < 59) is_text = is_in_letter("C", 54, x, y, WORD_Y);
            else if (x >= 60 && x < 65) is_text = is_in_letter("T", 60, x, y, WORD_Y);
            else if (x >= 66 && x < 71) is_text = is_in_letter("!", 66, x, y, WORD_Y);
        end
    end
endmodule


// ========== WRONG TEXT RENDERER ==========
module wrong_text_renderer(
    input [6:0] x,
    input [5:0] y,
    output reg is_text
);
    function [34:0] get_letter;
        input [7:0] char;
        begin
            case (char)
                "W": get_letter = 35'b10001_10001_10001_10101_10101_01010_01010;
                "R": get_letter = 35'b11110_10001_10001_11110_10100_10010_10001;
                "O": get_letter = 35'b01110_10001_10001_10001_10001_10001_01110;
                "N": get_letter = 35'b10001_11001_10101_10011_10001_10001_10001;
                "G": get_letter = 35'b01110_10001_10000_10111_10001_10001_01110;
                "!": get_letter = 35'b00100_00100_00100_00100_00100_00000_00100;
                default: get_letter = 35'b00000_00000_00000_00000_00000_00000_00000;
            endcase
        end
    endfunction
    
    function is_in_letter;
        input [7:0] char;
        input [6:0] x_start;
        input [6:0] x_coord;
        input [5:0] y_coord;
        input [5:0] y_start;
        reg [34:0] pattern;
        reg [2:0] local_x;
        reg [2:0] local_y;
        begin
            is_in_letter = 0;
            if (x_coord >= x_start && x_coord < x_start + 5 && 
                y_coord >= y_start && y_coord < y_start + 7) begin
                local_x = x_coord - x_start;
                local_y = y_coord - y_start;
                pattern = get_letter(char);
                is_in_letter = pattern[34 - (local_y * 5 + local_x)];
            end
        end
    endfunction
    
    localparam WORD_Y = 10;
    
    always @(*) begin
        is_text = 0;
        if (y >= WORD_Y && y < WORD_Y + 7) begin
            if (x >= 30 && x < 35) is_text = is_in_letter("W", 30, x, y, WORD_Y);
            else if (x >= 36 && x < 41) is_text = is_in_letter("R", 36, x, y, WORD_Y);
            else if (x >= 42 && x < 47) is_text = is_in_letter("O", 42, x, y, WORD_Y);
            else if (x >= 48 && x < 53) is_text = is_in_letter("N", 48, x, y, WORD_Y);
            else if (x >= 54 && x < 59) is_text = is_in_letter("G", 54, x, y, WORD_Y);
            else if (x >= 60 && x < 65) is_text = is_in_letter("!", 60, x, y, WORD_Y);
        end
    end
endmodule

// ========== FAILED TEXT RENDERER ==========
module failed_text_renderer(
    input [6:0] x,
    input [5:0] y,
    output reg is_text
);
    function [34:0] get_letter;
        input [7:0] char;
        begin
            case (char)
                "F": get_letter = 35'b11111_10000_10000_11110_10000_10000_10000;
                "A": get_letter = 35'b01110_10001_10001_11111_10001_10001_10001;
                "I": get_letter = 35'b01110_00100_00100_00100_00100_00100_01110;
                "L": get_letter = 35'b10000_10000_10000_10000_10000_10000_11111;
                "E": get_letter = 35'b11111_10000_10000_11110_10000_10000_11111;
                "D": get_letter = 35'b11110_10011_10001_10001_10001_10011_11110;
                "!": get_letter = 35'b00100_00100_00100_00100_00100_00000_00100;
                default: get_letter = 35'b00000_00000_00000_00000_00000_00000_00000;
            endcase
        end
    endfunction
    
    function is_in_letter;
        input [7:0] char;
        input [6:0] x_start;
        input [6:0] x_coord;
        input [5:0] y_coord;
        input [5:0] y_start;
        reg [34:0] pattern;
        reg [2:0] local_x;
        reg [2:0] local_y;
        begin
            is_in_letter = 0;
            if (x_coord >= x_start && x_coord < x_start + 5 && 
                y_coord >= y_start && y_coord < y_start + 7) begin
                local_x = x_coord - x_start;
                local_y = y_coord - y_start;
                pattern = get_letter(char);
                is_in_letter = pattern[34 - (local_y * 5 + local_x)];
            end
        end
    endfunction
    
    localparam WORD_Y = 10;
    
    always @(*) begin
        is_text = 0;
        if (y >= WORD_Y && y < WORD_Y + 7) begin
            if (x >= 27 && x < 32) is_text = is_in_letter("F", 27, x, y, WORD_Y);
            else if (x >= 33 && x < 38) is_text = is_in_letter("A", 33, x, y, WORD_Y);
            else if (x >= 39 && x < 44) is_text = is_in_letter("I", 39, x, y, WORD_Y);
            else if (x >= 45 && x < 50) is_text = is_in_letter("L", 45, x, y, WORD_Y);
            else if (x >= 51 && x < 56) is_text = is_in_letter("E", 51, x, y, WORD_Y);
            else if (x >= 57 && x < 62) is_text = is_in_letter("D", 57, x, y, WORD_Y);
            else if (x >= 63 && x < 68) is_text = is_in_letter("!", 63, x, y, WORD_Y);
        end
    end
endmodule

// ========== WELL DONE TEXT RENDERER ==========
module well_done_text_renderer(
    input [6:0] x,
    input [5:0] y,
    output reg is_text
);
    function [34:0] get_letter;
        input [7:0] char;
        begin
            case (char)
                "W": get_letter = 35'b10001_10001_10001_10101_10101_01010_01010;
                "E": get_letter = 35'b11111_10000_10000_11110_10000_10000_11111;
                "L": get_letter = 35'b10000_10000_10000_10000_10000_10000_11111;
                "D": get_letter = 35'b11110_10001_10001_10001_10001_10001_11110;
                "O": get_letter = 35'b01110_10001_10001_10001_10001_10001_01110;
                "N": get_letter = 35'b10001_11001_10101_10011_10001_10001_10001;
                "!": get_letter = 35'b00100_00100_00100_00100_00100_00000_00100;
                " ": get_letter = 35'b00000_00000_00000_00000_00000_00000_00000;
                default: get_letter = 35'b00000_00000_00000_00000_00000_00000_00000;
            endcase
        end
    endfunction
    
    function is_in_letter;
        input [7:0] char;
        input [6:0] x_start;
        input [6:0] x_coord;
        input [5:0] y_coord;
        input [5:0] y_start;
        reg [34:0] pattern;
        reg [2:0] local_x;
        reg [2:0] local_y;
        begin
            is_in_letter = 0;
            if (x_coord >= x_start && x_coord < x_start + 5 && 
                y_coord >= y_start && y_coord < y_start + 7) begin
                local_x = x_coord - x_start;
                local_y = y_coord - y_start;
                pattern = get_letter(char);
                is_in_letter = pattern[34 - (local_y * 5 + local_x)];
            end
        end
    endfunction
    
    localparam WORD_Y = 12;
    
    always @(*) begin
        is_text = 0;
        if (y >= WORD_Y && y < WORD_Y + 7) begin
            if (x >= 18 && x < 23) is_text = is_in_letter("W", 18, x, y, WORD_Y);
            else if (x >= 24 && x < 29) is_text = is_in_letter("E", 24, x, y, WORD_Y);
            else if (x >= 30 && x < 35) is_text = is_in_letter("L", 30, x, y, WORD_Y);
            else if (x >= 36 && x < 41) is_text = is_in_letter("L", 36, x, y, WORD_Y);
            else if (x >= 42 && x < 47) is_text = is_in_letter(" ", 42, x, y, WORD_Y);
            else if (x >= 48 && x < 53) is_text = is_in_letter("D", 48, x, y, WORD_Y);
            else if (x >= 54 && x < 59) is_text = is_in_letter("O", 54, x, y, WORD_Y);
            else if (x >= 60 && x < 65) is_text = is_in_letter("N", 60, x, y, WORD_Y);
            else if (x >= 66 && x < 71) is_text = is_in_letter("E", 66, x, y, WORD_Y);
            else if (x >= 72 && x < 77) is_text = is_in_letter("!", 72, x, y, WORD_Y);
        end
    end
endmodule


// ========== INPUT NUM TEXT RENDERER ==========
module input_num_text_renderer(
    input [6:0] x,
    input [5:0] y,
    output reg is_text
);
    function [34:0] get_letter;
        input [7:0] char;
        begin
            case (char)
                "I": get_letter = 35'b01110_00100_00100_00100_00100_00100_01110;
                "N": get_letter = 35'b10001_11001_10101_10011_10001_10001_10001;
                "P": get_letter = 35'b11110_10001_10001_11110_10000_10000_10000;
                "U": get_letter = 35'b10001_10001_10001_10001_10001_10001_01110;
                "T": get_letter = 35'b11111_00100_00100_00100_00100_00100_00100;
                "M": get_letter = 35'b10001_11011_10101_10001_10001_10001_10001;
                " ": get_letter = 35'b00000_00000_00000_00000_00000_00000_00000;
                default: get_letter = 35'b00000_00000_00000_00000_00000_00000_00000;
            endcase
        end
    endfunction
    
    function is_in_letter;
        input [7:0] char;
        input [6:0] x_start;
        input [6:0] x;
        input [5:0] y;
        input [5:0] y_start;
        reg [34:0] pattern;
        reg [2:0] local_x;
        reg [2:0] local_y;
        begin
            is_in_letter = 0;
            if (x >= x_start && x < x_start + 5 && y >= y_start && y < y_start + 7) begin
                local_x = x - x_start;
                local_y = y - y_start;
                pattern = get_letter(char);
                is_in_letter = pattern[34 - (local_y * 5 + local_x)];
            end
        end
    endfunction
    
    localparam WORD_Y = 10;
    
    always @(*) begin
        is_text = 0;
        if (y >= WORD_Y && y < WORD_Y + 7) begin
            if (x >= 21 && x < 26) is_text = is_in_letter("I", 21, x, y, WORD_Y);
            else if (x >= 27 && x < 32) is_text = is_in_letter("N", 27, x, y, WORD_Y);
            else if (x >= 33 && x < 38) is_text = is_in_letter("P", 33, x, y, WORD_Y);
            else if (x >= 39 && x < 44) is_text = is_in_letter("U", 39, x, y, WORD_Y);
            else if (x >= 45 && x < 50) is_text = is_in_letter("T", 45, x, y, WORD_Y);
            else if (x >= 51 && x < 56) is_text = is_in_letter(" ", 51, x, y, WORD_Y);
            else if (x >= 57 && x < 62) is_text = is_in_letter("N", 57, x, y, WORD_Y);
            else if (x >= 63 && x < 68) is_text = is_in_letter("U", 63, x, y, WORD_Y);
            else if (x >= 69 && x < 74) is_text = is_in_letter("M", 69, x, y, WORD_Y);
        end
    end
endmodule


// ========== BEGIN TEXT RENDERER ==========
module begin_text_renderer(
    input [6:0] x,
    input [5:0] y,
    input blink_on,
    output reg is_text
);
    function [34:0] get_letter;
        input [7:0] char;
        begin
            case (char)
                "B": get_letter = 35'b11110_10001_11110_10001_10001_10001_11110;
                "E": get_letter = 35'b11111_10000_10000_11110_10000_10000_11111;
                "G": get_letter = 35'b01110_10001_10000_10111_10001_10001_01110;
                "I": get_letter = 35'b01110_00100_00100_00100_00100_00100_01110;
                "N": get_letter = 35'b10001_11001_10101_10011_10001_10001_10001;
                default: get_letter = 35'b00000_00000_00000_00000_00000_00000_00000;
            endcase
        end
    endfunction
    
    function is_in_letter;
        input [7:0] char;
        input [6:0] x_start;
        input [6:0] x;
        input [5:0] y;
        input [5:0] y_start;
        reg [34:0] pattern;
        reg [2:0] local_x;
        reg [2:0] local_y;
        begin
            is_in_letter = 0;
            if (x >= x_start && x < x_start + 5 && y >= y_start && y < y_start + 7) begin
                local_x = x - x_start;
                local_y = y - y_start;
                pattern = get_letter(char);
                is_in_letter = pattern[34 - (local_y * 5 + local_x)];
            end
        end
    endfunction
    
    localparam WORD_Y = 28;
    
    always @(*) begin
        is_text = 0;
        if (blink_on && y >= WORD_Y && y < WORD_Y + 7) begin
            if (x >= 33 && x < 38) is_text = is_in_letter("B", 33, x, y, WORD_Y);
            else if (x >= 39 && x < 44) is_text = is_in_letter("E", 39, x, y, WORD_Y);
            else if (x >= 45 && x < 50) is_text = is_in_letter("G", 45, x, y, WORD_Y);
            else if (x >= 51 && x < 56) is_text = is_in_letter("I", 51, x, y, WORD_Y);
            else if (x >= 57 && x < 62) is_text = is_in_letter("N", 57, x, y, WORD_Y);
        end
    end
endmodule


// ========== TUTORIAL TEXT RENDERER ==========
module tutorial_text_renderer(
    input [6:0] x,
    input [5:0] y,
    input [3:0] tutorial_state,
    output reg is_text
);
    function [34:0] get_letter;
        input [7:0] char;
        begin
            case (char)
                "W": get_letter = 35'b10001_10001_10001_10101_10101_01010_01010;
                "E": get_letter = 35'b11111_10000_10000_11110_10000_10000_11111;
                "L": get_letter = 35'b10000_10000_10000_10000_10000_10000_11111;
                "C": get_letter = 35'b01110_10001_10000_10000_10000_10001_01110;
                "O": get_letter = 35'b01110_10001_10001_10001_10001_10001_01110;
                "M": get_letter = 35'b10001_11011_10101_10001_10001_10001_10001;
                "T": get_letter = 35'b11111_00100_00100_00100_00100_00100_00100;
                "U": get_letter = 35'b10001_10001_10001_10001_10001_10001_01110;
                "R": get_letter = 35'b11110_10001_10001_11110_10100_10010_10001;
                "I": get_letter = 35'b01110_00100_00100_00100_00100_00100_01110;
                "A": get_letter = 35'b01110_10001_10001_11111_10001_10001_10001;
                "D": get_letter = 35'b11110_10001_10001_10001_10001_10001_11110;
                default: get_letter = 35'b00000_00000_00000_00000_00000_00000_00000;
            endcase
        end
    endfunction
    
    function is_in_letter;
        input [7:0] char;
        input [6:0] x_start;
        input [6:0] x;
        input [5:0] y;
        input [5:0] y_start;
        reg [34:0] pattern;
        reg [2:0] local_x;
        reg [2:0] local_y;
        begin
            is_in_letter = 0;
            if (x >= x_start && x < x_start + 5 && y >= y_start && y < y_start + 7) begin
                local_x = x - x_start;
                local_y = y - y_start;
                pattern = get_letter(char);
                is_in_letter = pattern[34 - (local_y * 5 + local_x)];
            end
        end
    endfunction
    
    localparam WORD_Y = 28;
    
    always @(*) begin
        is_text = 0;
        
        case (tutorial_state)
            4'd0: begin  // WELCOME
                if (y >= WORD_Y && y < WORD_Y + 7) begin
                    if (x >= 27 && x < 32) is_text = is_in_letter("W", 27, x, y, WORD_Y);
                    else if (x >= 33 && x < 38) is_text = is_in_letter("E", 33, x, y, WORD_Y);
                    else if (x >= 39 && x < 44) is_text = is_in_letter("L", 39, x, y, WORD_Y);
                    else if (x >= 45 && x < 50) is_text = is_in_letter("C", 45, x, y, WORD_Y);
                    else if (x >= 51 && x < 56) is_text = is_in_letter("O", 51, x, y, WORD_Y);
                    else if (x >= 57 && x < 62) is_text = is_in_letter("M", 57, x, y, WORD_Y);
                    else if (x >= 63 && x < 68) is_text = is_in_letter("E", 63, x, y, WORD_Y);
                end
            end
            
            4'd1: begin  // TO
                if (y >= WORD_Y && y < WORD_Y + 7) begin
                    if (x >= 42 && x < 47) is_text = is_in_letter("T", 42, x, y, WORD_Y);
                    else if (x >= 48 && x < 53) is_text = is_in_letter("O", 48, x, y, WORD_Y);
                end
            end
            
            4'd2: begin  // TUTORIAL
                if (y >= WORD_Y && y < WORD_Y + 7) begin
                    if (x >= 24 && x < 29) is_text = is_in_letter("T", 24, x, y, WORD_Y);
                    else if (x >= 30 && x < 35) is_text = is_in_letter("U", 30, x, y, WORD_Y);
                    else if (x >= 36 && x < 41) is_text = is_in_letter("T", 36, x, y, WORD_Y);
                    else if (x >= 42 && x < 47) is_text = is_in_letter("O", 42, x, y, WORD_Y);
                    else if (x >= 48 && x < 53) is_text = is_in_letter("R", 48, x, y, WORD_Y);
                    else if (x >= 54 && x < 59) is_text = is_in_letter("I", 54, x, y, WORD_Y);
                    else if (x >= 60 && x < 65) is_text = is_in_letter("A", 60, x, y, WORD_Y);
                    else if (x >= 66 && x < 71) is_text = is_in_letter("L", 66, x, y, WORD_Y);
                end
            end
            
            4'd3: begin  // MODE
                if (y >= WORD_Y && y < WORD_Y + 7) begin
                    if (x >= 36 && x < 41) is_text = is_in_letter("M", 36, x, y, WORD_Y);
                    else if (x >= 42 && x < 47) is_text = is_in_letter("O", 42, x, y, WORD_Y);
                    else if (x >= 48 && x < 53) is_text = is_in_letter("D", 48, x, y, WORD_Y);
                    else if (x >= 54 && x < 59) is_text = is_in_letter("E", 54, x, y, WORD_Y);
                end
            end
            
            4'd4: begin  // ALL STACKED
                if (y >= 10 && y < 17) begin
                    if (x >= 27 && x < 32) is_text = is_in_letter("W", 27, x, y, 10);
                    else if (x >= 33 && x < 38) is_text = is_in_letter("E", 33, x, y, 10);
                    else if (x >= 39 && x < 44) is_text = is_in_letter("L", 39, x, y, 10);
                    else if (x >= 45 && x < 50) is_text = is_in_letter("C", 45, x, y, 10);
                    else if (x >= 51 && x < 56) is_text = is_in_letter("O", 51, x, y, 10);
                    else if (x >= 57 && x < 62) is_text = is_in_letter("M", 57, x, y, 10);
                    else if (x >= 63 && x < 68) is_text = is_in_letter("E", 63, x, y, 10);
                end
                else if (y >= 22 && y < 29) begin
                    if (x >= 42 && x < 47) is_text = is_in_letter("T", 42, x, y, 22);
                    else if (x >= 48 && x < 53) is_text = is_in_letter("O", 48, x, y, 22);
                end
                else if (y >= 34 && y < 41) begin
                    if (x >= 24 && x < 29) is_text = is_in_letter("T", 24, x, y, 34);
                    else if (x >= 30 && x < 35) is_text = is_in_letter("U", 30, x, y, 34);
                    else if (x >= 36 && x < 41) is_text = is_in_letter("T", 36, x, y, 34);
                    else if (x >= 42 && x < 47) is_text = is_in_letter("O", 42, x, y, 34);
                    else if (x >= 48 && x < 53) is_text = is_in_letter("R", 48, x, y, 34);
                    else if (x >= 54 && x < 59) is_text = is_in_letter("I", 54, x, y, 34);
                    else if (x >= 60 && x < 65) is_text = is_in_letter("A", 60, x, y, 34);
                    else if (x >= 66 && x < 71) is_text = is_in_letter("L", 66, x, y, 34);
                end
                else if (y >= 46 && y < 53) begin
                    if (x >= 36 && x < 41) is_text = is_in_letter("M", 36, x, y, 46);
                    else if (x >= 42 && x < 47) is_text = is_in_letter("O", 42, x, y, 46);
                    else if (x >= 48 && x < 53) is_text = is_in_letter("D", 48, x, y, 46);
                    else if (x >= 54 && x < 59) is_text = is_in_letter("E", 54, x, y, 46);
                end
            end
        endcase
    end
endmodule


// ========== INTRO TEXT RENDERER ==========
module intro_text_renderer(
    input [6:0] x,
    input [5:0] y,
    input [2:0] intro_state,
    input [2:0] anim_offset,
    output reg is_text
);
    function [69:0] get_big_letter;
        input [7:0] letter;
        begin
            case (letter)
                "S": get_big_letter = 70'b0111110_1100011_1100000_0111100_0000011_1100011_0111110_0000000_0000000_0000000;
                "E": get_big_letter = 70'b1111111_1100000_1100000_1111110_1100000_1100000_1111111_0000000_0000000_0000000;
                "L": get_big_letter = 70'b1100000_1100000_1100000_1100000_1100000_1100000_1111111_0000000_0000000_0000000;
                "C": get_big_letter = 70'b0111110_1100011_1100000_1100000_1100000_1100011_0111110_0000000_0000000_0000000;
                "T": get_big_letter = 70'b1111111_0011000_0011000_0011000_0011000_0011000_0011000_0000000_0000000_0000000;
                "I": get_big_letter = 70'b1111111_0011000_0011000_0011000_0011000_0011000_1111111_0000000_0000000_0000000;
                "O": get_big_letter = 70'b0111110_1100011_1100011_1100011_1100011_1100011_0111110_0000000_0000000_0000000;
                "N": get_big_letter = 70'b1100011_1110011_1111011_1111111_1101111_1100111_1100011_0000000_0000000_0000000;
                "R": get_big_letter = 70'b1111110_1100011_1100011_1111110_1101100_1100110_1100011_0000000_0000000_0000000;
                default: get_big_letter = 70'b0000000_0000000_0000000_0000000_0000000_0000000_0000000_0000000_0000000_0000000;
            endcase
        end
    endfunction
    
    function get_small_pixel;
        input [7:0] letter;
        input [1:0] px;
        input [2:0] py;
        reg [2:0] row_data;
        begin
            case (letter)
                "U": begin
                    case (py)
                        3'd0: row_data = 3'b101;
                        3'd1: row_data = 3'b101;
                        3'd2: row_data = 3'b101;
                        3'd3: row_data = 3'b101;
                        3'd4: row_data = 3'b111;
                    endcase
                end
                "P": begin
                    case (py)
                        3'd0: row_data = 3'b110;
                        3'd1: row_data = 3'b101;
                        3'd2: row_data = 3'b110;
                        3'd3: row_data = 3'b100;
                        3'd4: row_data = 3'b100;
                    endcase
                end
                "T": begin
                    case (py)
                        3'd0: row_data = 3'b111;
                        3'd1: row_data = 3'b010;
                        3'd2: row_data = 3'b010;
                        3'd3: row_data = 3'b010;
                        3'd4: row_data = 3'b010;
                    endcase
                end
                "B": begin
                    case (py)
                        3'd0: row_data = 3'b110;
                        3'd1: row_data = 3'b101;
                        3'd2: row_data = 3'b110;
                        3'd3: row_data = 3'b101;
                        3'd4: row_data = 3'b110;
                    endcase
                end
                "O": begin
                    case (py)
                        3'd0: row_data = 3'b111;
                        3'd1: row_data = 3'b101;
                        3'd2: row_data = 3'b101;
                        3'd3: row_data = 3'b101;
                        3'd4: row_data = 3'b111;
                    endcase
                end
                "N": begin
                    case (py)
                        3'd0: row_data = 3'b101;
                        3'd1: row_data = 3'b111;
                        3'd2: row_data = 3'b111;
                        3'd3: row_data = 3'b101;
                        3'd4: row_data = 3'b101;
                    endcase
                end
                "F": begin
                    case (py)
                        3'd0: row_data = 3'b111;
                        3'd1: row_data = 3'b100;
                        3'd2: row_data = 3'b110;
                        3'd3: row_data = 3'b100;
                        3'd4: row_data = 3'b100;
                    endcase
                end
                "D": begin
                    case (py)
                        3'd0: row_data = 3'b110;
                        3'd1: row_data = 3'b101;
                        3'd2: row_data = 3'b101;
                        3'd3: row_data = 3'b101;
                        3'd4: row_data = 3'b110;
                    endcase
                end
                "E": begin
                    case (py)
                        3'd0: row_data = 3'b111;
                        3'd1: row_data = 3'b100;
                        3'd2: row_data = 3'b110;
                        3'd3: row_data = 3'b100;
                        3'd4: row_data = 3'b111;
                    endcase
                end
                "M": begin
                    case (py)
                        3'd0: row_data = 3'b101;
                        3'd1: row_data = 3'b111;
                        3'd2: row_data = 3'b101;
                        3'd3: row_data = 3'b101;
                        3'd4: row_data = 3'b101;
                    endcase
                end
                "S": begin
                    case (py)
                        3'd0: row_data = 3'b111;
                        3'd1: row_data = 3'b100;
                        3'd2: row_data = 3'b111;
                        3'd3: row_data = 3'b001;
                        3'd4: row_data = 3'b111;
                    endcase
                end
                "W": begin
                    case (py)
                        3'd0: row_data = 3'b101;
                        3'd1: row_data = 3'b101;
                        3'd2: row_data = 3'b101;
                        3'd3: row_data = 3'b111;
                        3'd4: row_data = 3'b101;
                    endcase
                end
                "1": begin
                    case (py)
                        3'd0: row_data = 3'b010;
                        3'd1: row_data = 3'b110;
                        3'd2: row_data = 3'b010;
                        3'd3: row_data = 3'b010;
                        3'd4: row_data = 3'b111;
                    endcase
                end
                "0": begin
                    case (py)
                        3'd0: row_data = 3'b111;
                        3'd1: row_data = 3'b101;
                        3'd2: row_data = 3'b101;
                        3'd3: row_data = 3'b101;
                        3'd4: row_data = 3'b111;
                    endcase
                end
                "I": begin
                    case (py)
                        3'd0: row_data = 3'b111;
                        3'd1: row_data = 3'b010;
                        3'd2: row_data = 3'b010;
                        3'd3: row_data = 3'b010;
                        3'd4: row_data = 3'b111;
                    endcase
                end
                "A": begin
                    case (py)
                        3'd0: row_data = 3'b010;
                        3'd1: row_data = 3'b101;
                        3'd2: row_data = 3'b111;
                        3'd3: row_data = 3'b101;
                        3'd4: row_data = 3'b101;
                    endcase
                end
                "L": begin
                    case (py)
                        3'd0: row_data = 3'b100;
                        3'd1: row_data = 3'b100;
                        3'd2: row_data = 3'b100;
                        3'd3: row_data = 3'b100;
                        3'd4: row_data = 3'b111;
                    endcase
                end
                "R": begin
                    case (py)
                        3'd0: row_data = 3'b110;
                        3'd1: row_data = 3'b101;
                        3'd2: row_data = 3'b110;
                        3'd3: row_data = 3'b101;
                        3'd4: row_data = 3'b101;
                    endcase
                end
                " ": begin
                    row_data = 3'b000;
                end
                default: begin
                    row_data = 3'b000;
                end
            endcase
            
            get_small_pixel = row_data[2 - px];
        end
    endfunction
    
    localparam LETTER_WIDTH = 8;
    localparam SMALL_WIDTH = 4;
    
    localparam SELECTION_Y = 12;
    localparam SELECTION_X_START = 12;
    
    localparam SORT_Y = 24;
    localparam SORT_X_START = 32;
    
    localparam SMALL_TEXT_START_Y = 40;
    
    wire in_selection_area, in_sort_area, in_small_text1_area, in_small_text2_area;
    wire [4:0] letter_idx_sel, letter_idx_sort, letter_idx_small1, letter_idx_small2;
    wire [2:0] local_x_sel, local_x_sort;
    wire [1:0] local_x_small1, local_x_small2;
    wire [3:0] local_y_big;
    wire [2:0] local_y_small1, local_y_small2;
    reg [69:0] big_letter_pattern;
    reg [7:0] current_letter;
    
    wire [5:0] animated_y1 = SMALL_TEXT_START_Y + anim_offset;
    wire [5:0] animated_y2 = SMALL_TEXT_START_Y + 8 + anim_offset;
    
    localparam TEXT1_X_START = 12;
    localparam TEXT2_X_START = 14;
    
    assign in_selection_area = (y >= SELECTION_Y) && (y < SELECTION_Y + 10) &&
                               (x >= SELECTION_X_START) && (x < SELECTION_X_START + 9*LETTER_WIDTH);
    
    assign in_sort_area = (y >= SORT_Y) && (y < SORT_Y + 10) &&
                          (x >= SORT_X_START) && (x < SORT_X_START + 4*LETTER_WIDTH);
    
    assign in_small_text1_area = (y >= animated_y1) && (y < animated_y1 + 5) &&
                                  (x >= TEXT1_X_START) && (x < TEXT1_X_START + 18*SMALL_WIDTH);
    
    assign in_small_text2_area = (y >= animated_y2) && (y < animated_y2 + 5) &&
                                  (x >= TEXT2_X_START) && (x < TEXT2_X_START + 17*SMALL_WIDTH);
    
    assign letter_idx_sel = (x - SELECTION_X_START) / LETTER_WIDTH;
    assign letter_idx_sort = (x - SORT_X_START) / LETTER_WIDTH;
    assign letter_idx_small1 = (x - TEXT1_X_START) / SMALL_WIDTH;
    assign letter_idx_small2 = (x - TEXT2_X_START) / SMALL_WIDTH;
    
    assign local_x_sel = (x - SELECTION_X_START) % LETTER_WIDTH;
    assign local_x_sort = (x - SORT_X_START) % LETTER_WIDTH;
    assign local_x_small1 = (x - TEXT1_X_START) % SMALL_WIDTH;
    assign local_x_small2 = (x - TEXT2_X_START) % SMALL_WIDTH;
    
    assign local_y_big = y - SELECTION_Y;
    assign local_y_small1 = y - animated_y1;
    assign local_y_small2 = y - animated_y2;
    
    always @* begin
        is_text = 0;
        big_letter_pattern = 70'b0;
        current_letter = " ";
        
        if (in_selection_area && intro_state <= 3'd2) begin
            case (letter_idx_sel)
                5'd0: big_letter_pattern = get_big_letter("S");
                5'd1: big_letter_pattern = get_big_letter("E");
                5'd2: big_letter_pattern = get_big_letter("L");
                5'd3: big_letter_pattern = get_big_letter("E");
                5'd4: big_letter_pattern = get_big_letter("C");
                5'd5: big_letter_pattern = get_big_letter("T");
                5'd6: big_letter_pattern = get_big_letter("I");
                5'd7: big_letter_pattern = get_big_letter("O");
                5'd8: big_letter_pattern = get_big_letter("N");
                default: big_letter_pattern = 70'b0;
            endcase
            
            if (local_x_sel < 7 && local_y_big < 10)
                is_text = big_letter_pattern[69 - (local_y_big * 7 + local_x_sel)];
        end
        else if (in_sort_area && (intro_state == 3'd1 || intro_state == 3'd2)) begin
            case (letter_idx_sort)
                5'd0: big_letter_pattern = get_big_letter("S");
                5'd1: big_letter_pattern = get_big_letter("O");
                5'd2: big_letter_pattern = get_big_letter("R");
                5'd3: big_letter_pattern = get_big_letter("T");
                default: big_letter_pattern = 70'b0;
            endcase
            
            if (local_x_sort < 7 && (y - SORT_Y) < 10)
                is_text = big_letter_pattern[69 - ((y - SORT_Y) * 7 + local_x_sort)];
        end
        else if (in_small_text1_area && intro_state == 3'd2) begin
            case (letter_idx_small1)
                5'd0: current_letter = "U";
                5'd1: current_letter = "P";
                5'd2: current_letter = " ";
                5'd3: current_letter = "B";
                5'd4: current_letter = "U";
                5'd5: current_letter = "T";
                5'd6: current_letter = "T";
                5'd7: current_letter = "O";
                5'd8: current_letter = "N";
                5'd9: current_letter = " ";
                5'd10: current_letter = "F";
                5'd11: current_letter = "O";
                5'd12: current_letter = "R";
                5'd13: current_letter = " ";
                5'd14: current_letter = "D";
                5'd15: current_letter = "E";
                5'd16: current_letter = "M";
                5'd17: current_letter = "O";
                default: current_letter = " ";
            endcase
            
            if (local_x_small1 < 3 && local_y_small1 < 5)
                is_text = get_small_pixel(current_letter, local_x_small1, local_y_small1);
        end
        else if (in_small_text2_area && intro_state == 3'd2) begin
            case (letter_idx_small2)
                5'd0: current_letter = "S";
                5'd1: current_letter = "W";
                5'd2: current_letter = "1";
                5'd3: current_letter = "0";
                5'd4: current_letter = " ";
                5'd5: current_letter = "F";
                5'd6: current_letter = "O";
                5'd7: current_letter = "R";
                5'd8: current_letter = " ";
                5'd9: current_letter = "T";
                5'd10: current_letter = "U";
                5'd11: current_letter = "T";
                5'd12: current_letter = "O";
                5'd13: current_letter = "R";
                5'd14: current_letter = "I";
                5'd15: current_letter = "A";
                5'd16: current_letter = "L";
                default: current_letter = " ";
            endcase
            
            if (local_x_small2 < 3 && local_y_small2 < 5)
                is_text = get_small_pixel(current_letter, local_x_small2, local_y_small2);
        end
    end
endmodule