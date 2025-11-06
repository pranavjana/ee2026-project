`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.10.2025 22:22:32
// Design Name: 
// Module Name: Oled_Renderer
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


module Oled_Renderer(
    input clk_100mhz,
    input ce_30hz,
    input ce_2hz,
    input system_enable,
    input [2:0] current_screen, // Represents 4 distinct states
    // Display timing signals (NEW - for synchronization)
    input frame_begin,
    input sending_pixels,
    // Education Inputs
    input [2:0] current_array_0, input [2:0] current_array_1, input [2:0] current_array_2,
    input [2:0] current_array_3, input [2:0] current_array_4, input [2:0] current_array_5,
    input [2:0] red_line_pos,
    input [2:0] compare_idx1, input [2:0] compare_idx2,
    input [2:0] swap_idx1, input [2:0] swap_idx2,
    input is_sorted_flag, input is_at_start_flag,
    // Tutorial Inputs
    input [2:0] tut_array_0, input [2:0] tut_array_1, input [2:0] tut_array_2,
    input [2:0] tut_array_3, input [2:0] tut_array_4, input [2:0] tut_array_5,
    input [2:0] cursor_pos,
    // Tutorial Sort Inputs
    input [2:0] tut_sort_array_0, input [2:0] tut_sort_array_1, input [2:0] tut_sort_array_2,
    input [2:0] tut_sort_array_3, input [2:0] tut_sort_array_4, input [2:0] tut_sort_array_5,
    input [2:0] tut_red_line_pos,
    input [2:0] tut_compare_idx1, input [2:0] tut_compare_idx2,
    input [2:0] tut_swap_idx1, input [2:0] tut_swap_idx2,
    input [2:0] hearts_remaining,
    input show_mistake,
    // Outputs
    output reg fb_wr_en,
    output reg [12:0] fb_wr_addr,
    output reg [15:0] fb_wr_data
);

    // --- Colors ---
    localparam COLOR_BLACK   = 16'h0000; localparam COLOR_WHITE = 16'hFFFF;
    localparam COLOR_RED     = 16'hF800; localparam COLOR_BLUE  = 16'h001F;
    localparam COLOR_YELLOW  = 16'hFFE0; localparam COLOR_GREEN = 16'h07E0;
    localparam COLOR_BROWN   = 16'hA145; localparam COLOR_GREEN2= 16'h06C0;

    // --- Distinct State Definitions (matching Main_FSM) ---
    localparam STATE_EDU_WELCOME     = 3'b000;
    localparam STATE_EDU_SORTING     = 3'b001;
    localparam STATE_TUT_WELCOME     = 3'b010;
    localparam STATE_TUT_INPUT       = 3'b011;
    localparam STATE_TUT_READY       = 3'b100;
    localparam STATE_TUT_SORTING     = 3'b101;
    localparam STATE_TUT_GAME_OVER   = 3'b110;
    localparam STATE_TUT_VICTORY     = 3'b111;

    // --- Rendering counter ---
    reg [12:0] addr_counter;

    // --- Renderer State Machine (NEW - prevents continuous re-writing) ---
    localparam RENDER_IDLE = 1'b0;
    localparam RENDER_ACTIVE = 1'b1;
    reg render_state;
    reg prev_frame_begin;  // Edge detection

    //==========================================================================
    // RENDER PIPELINE (Structure Unchanged)
    //==========================================================================
    reg [12:0] p0_addr; reg [6:0] p0_pixel_x; reg [5:0] p0_pixel_y;
    always @(posedge clk_100mhz) begin p0_addr <= addr_counter; p0_pixel_x <= addr_counter % 7'd96; p0_pixel_y <= addr_counter / 7'd96; end

    // --- Pipeline Stage 1 Registers ---
    reg [6:0] p1_char_code_4x6; reg [2:0] p1_char_row_4x6; reg [2:0] p1_char_col_4x6;
    reg [15:0] p1_title_color; reg p1_in_cloud; reg p1_in_tree; reg [15:0] p1_tree_color;
    reg p1_in_prompt_welcome; reg p1_in_title1; reg p1_in_title2; // Flags indicating pixel is in area
    reg p1_in_red_line; reg p1_in_box; reg [15:0] p1_box_color; reg p1_in_prompt_sort;
    reg p1_in_digit_area; reg p1_digit_pixel;
    reg p1_tut_box_highlight;
    reg p1_is_font_pixel; // Flag indicates if current pixel is part of *any* character
    // Tutorial Sort Visual Elements
    reg p1_in_heart_area; reg p1_heart_pixel;
    reg p1_in_red_x_area; reg p1_red_x_pixel;
    

    // --- Pipeline Stage 2 Registers ---
    reg [15:0] p2_fb_wr_data;

    //==========================================================================
    // ANIMATION STATE REGISTERS (Unchanged)
    //==========================================================================
    reg [6:0] cloud_x_offset; reg [1:0] tree_anim_frame; reg bounce_offset;
    always @(posedge clk_100mhz) begin if (!system_enable) begin cloud_x_offset <= 0; tree_anim_frame <= 0; bounce_offset <= 0; end else if (ce_2hz) begin cloud_x_offset <= (cloud_x_offset == 119) ? 0 : cloud_x_offset + 1; tree_anim_frame <= ~tree_anim_frame; bounce_offset <= ~bounce_offset; end end

    //==========================================================================
    // COMBINATIONAL LOGIC FOR STAGE 1 (Calculates inputs for Stage 1 Registers)
    //==========================================================================

    // --- Cloud & Tree Logic (Unchanged) ---
    wire in_cloud; wire cloud_pixel; wire in_tree; wire [15:0] tree_color;
    localparam CLOUD_WIDTH = 24; localparam CLOUD_SPACING = 30; localparam SCREEN_WIDTH = 96; localparam WRAP_WIDTH = 120; wire signed [7:0] cloud1_start_x = cloud_x_offset; wire signed [7:0] cloud2_start_x = cloud_x_offset + CLOUD_SPACING; wire signed [7:0] cloud3_start_x = cloud_x_offset + CLOUD_SPACING*2; wire signed [7:0] cloud4_start_x = cloud_x_offset + CLOUD_SPACING*3; wire in_cloud1_range = (p0_pixel_x >= cloud1_start_x && p0_pixel_x < cloud1_start_x + CLOUD_WIDTH) || (p0_pixel_x < (cloud1_start_x + CLOUD_WIDTH - WRAP_WIDTH)); wire in_cloud2_range = (p0_pixel_x >= cloud2_start_x && p0_pixel_x < cloud2_start_x + CLOUD_WIDTH) || (p0_pixel_x < (cloud2_start_x + CLOUD_WIDTH - WRAP_WIDTH)); wire in_cloud3_range = (p0_pixel_x >= cloud3_start_x && p0_pixel_x < cloud3_start_x + CLOUD_WIDTH) || (p0_pixel_x < (cloud3_start_x + CLOUD_WIDTH - WRAP_WIDTH)); wire in_cloud4_range = (p0_pixel_x >= cloud4_start_x && p0_pixel_x < cloud4_start_x + CLOUD_WIDTH) || (p0_pixel_x < (cloud4_start_x + CLOUD_WIDTH - WRAP_WIDTH)); wire in_cloud_y = (p0_pixel_y >= 5 && p0_pixel_y < 15); assign in_cloud = in_cloud_y && (in_cloud1_range || in_cloud2_range || in_cloud3_range || in_cloud4_range); wire [4:0] cloud_rel_x = in_cloud1_range ? ((p0_pixel_x >= cloud1_start_x) ? p0_pixel_x - cloud1_start_x : p0_pixel_x - (cloud1_start_x - WRAP_WIDTH)) : in_cloud2_range ? ((p0_pixel_x >= cloud2_start_x) ? p0_pixel_x - cloud2_start_x : p0_pixel_x - (cloud2_start_x - WRAP_WIDTH)) : in_cloud3_range ? ((p0_pixel_x >= cloud3_start_x) ? p0_pixel_x - cloud3_start_x : p0_pixel_x - (cloud3_start_x - WRAP_WIDTH)) : in_cloud4_range ? ((p0_pixel_x >= cloud4_start_x) ? p0_pixel_x - cloud4_start_x : p0_pixel_x - (cloud4_start_x - WRAP_WIDTH)) : 0; wire [3:0] cloud_rel_y = p0_pixel_y - 5; assign cloud_pixel = (cloud_rel_y == 0 && cloud_rel_x >= 5 && cloud_rel_x < 19) || (cloud_rel_y == 1 && cloud_rel_x >= 3 && cloud_rel_x < 22) || (cloud_rel_y == 2 && cloud_rel_x >= 2 && cloud_rel_x < 23) || (cloud_rel_y == 3 && cloud_rel_x >= 1 && cloud_rel_x < 24) || (cloud_rel_y == 4 && cloud_rel_x >= 0 && cloud_rel_x < 24) || (cloud_rel_y == 5 && cloud_rel_x >= 0 && cloud_rel_x < 23) || (cloud_rel_y == 6 && cloud_rel_x >= 2 && cloud_rel_x < 22) || (cloud_rel_y == 7 && cloud_rel_x >= 3 && cloud_rel_x < 20) || (cloud_rel_y == 8 && cloud_rel_x >= 5 && cloud_rel_x < 18) || (cloud_rel_y == 9 && cloud_rel_x >= 7 && cloud_rel_x < 15);
    wire in_left_tree = (p0_pixel_x >= 5 && p0_pixel_x < 15 && p0_pixel_y >= 49 && p0_pixel_y < 64); wire [3:0] left_tree_x = p0_pixel_x - 5; wire [3:0] left_tree_y = p0_pixel_y - 49; wire in_right_tree = (p0_pixel_x >= 81 && p0_pixel_x < 91 && p0_pixel_y >= 49 && p0_pixel_y < 64); wire [3:0] right_tree_x = p0_pixel_x - 81; wire [3:0] right_tree_y = p0_pixel_y - 49; assign in_tree = in_left_tree || in_right_tree; assign tree_color = (in_left_tree) ? ( (left_tree_x >= 4 && left_tree_x <= 5 && left_tree_y >= 10) ? COLOR_BROWN : ( (tree_anim_frame == 1) ? ((left_tree_x > 0) ? COLOR_GREEN : COLOR_GREEN2) : ((left_tree_x < 9) ? COLOR_GREEN : COLOR_GREEN2) ) ) : ( (right_tree_x >= 4 && right_tree_x <= 5 && right_tree_y >= 10) ? COLOR_BROWN : ( (tree_anim_frame == 1) ? ((right_tree_x > 0) ? COLOR_GREEN : COLOR_GREEN2) : ((right_tree_x < 9) ? COLOR_GREEN : COLOR_GREEN2) ) );

    // --- Intermediate signals calculated in combinational block ---
    reg in_title1_area, in_title2_area, in_prompt_welcome_area, in_prompt_sort_area;
    reg [4:0] char_idx_val; reg [2:0] char_col_val; reg [2:0] char_row_val;
    reg [15:0] title_color_val;
    reg in_red_line_val; reg in_box_val; reg [15:0] box_color_val;
    reg in_digit_area_val; reg digit_pixel_val; reg tut_box_highlight_val;
    reg [5:0] prompt_welcome_y_comb; reg [2:0] char_color_idx_comb;
    reg [2:0] box_num_comb; reg [6:0] red_line_x_comb;
    reg [5:0] prompt_sort_y_comb; reg in_prompt_L_area, in_prompt_R_area, in_prompt_U_area;
    reg [2:0] digit_to_show_comb; reg [34:0] digit_pattern_comb;
    reg [6:0] digit_x_comb; reg [5:0] digit_y_comb;
    reg [2:0] digit_col_comb; reg [2:0] digit_row_comb; reg [5:0] pattern_bit_comb;
    reg is_font_pixel_comb; // <-- ADDED intermediate calculation
    // Tutorial sort visual elements
    reg in_heart_area_comb; reg heart_pixel_comb;
    reg in_red_x_area_comb; reg red_x_pixel_comb;
    reg [6:0] red_x_x_comb;  // X position for red X

    // --- Font ROM Instantiation ---
    wire [3:0] font_pixel_row_4x6; reg [6:0] char_code_4x6_reg; // Input to ROM must be reg
    Font_ROM_4x6 font_rom_4x6 ( .char_code(char_code_4x6_reg), .row(p1_char_row_4x6), .pixel_row(font_pixel_row_4x6) );

    // --- Bold Font ROM for Education Mode ---
    wire [4:0] font_pixel_row_5x7_bold;
    reg [6:0] char_code_5x7_reg;
    Font_ROM_5x7_Bold font_rom_5x7_bold ( .char_code(char_code_5x7_reg), .row(p1_char_row_4x6), .pixel_row(font_pixel_row_5x7_bold) );

    // --- Font selection based on mode ---
    wire use_bold_font = (current_screen == STATE_EDU_WELCOME || current_screen == STATE_EDU_SORTING || current_screen == STATE_TUT_WELCOME);

    // --- Main Combinational Block for Stage 1 Calculations ---
    always @(*) begin
        // Defaults
        in_title1_area = 1'b0; in_title2_area = 1'b0; in_prompt_welcome_area = 1'b0;
        in_prompt_sort_area = 1'b0; char_idx_val = 0; char_col_val = 0; char_row_val = 0;
        title_color_val = COLOR_BLACK; in_red_line_val = 1'b0; in_box_val = 1'b0;
        box_color_val = COLOR_WHITE; in_digit_area_val = 1'b0; digit_pixel_val = 1'b0;
        tut_box_highlight_val = 1'b0; char_code_4x6_reg = 7'd0; char_code_5x7_reg = 7'd0;
        is_font_pixel_comb = 1'b0; // Default font pixel off
        in_heart_area_comb = 1'b0; heart_pixel_comb = 1'b0;
        in_red_x_area_comb = 1'b0; red_x_pixel_comb = 1'b0;
        red_x_x_comb = 7'd0;

        // Calculate common helper values
        prompt_welcome_y_comb = (bounce_offset) ? 6'd42 : 6'd43;
        prompt_sort_y_comb = (bounce_offset) ? 6'd50 : 6'd51;
        box_num_comb = (p0_pixel_x >= 7'd4 && p0_pixel_x < 7'd18) ? 3'd0 : (p0_pixel_x >= 7'd19 && p0_pixel_x < 7'd33) ? 3'd1 : (p0_pixel_x >= 7'd34 && p0_pixel_x < 7'd48) ? 3'd2 : (p0_pixel_x >= 7'd49 && p0_pixel_x < 7'd63) ? 3'd3 : (p0_pixel_x >= 7'd64 && p0_pixel_x < 7'd78) ? 3'd4 : (p0_pixel_x >= 7'd79 && p0_pixel_x < 7'd93) ? 3'd5 : 3'd7;
        in_box_val = (p0_pixel_y >= 6'd27 && p0_pixel_y < 6'd37) && (box_num_comb != 3'd7);

        // State-dependent calculations
        case(current_screen)
            STATE_EDU_WELCOME: begin
                // Redesigned clean layout - centered text, no clouds/trees
                // "Welcome to" - 10 chars × 6 pixels = 60 pixels wide, centered at x=18
                in_title1_area = (p0_pixel_y >= 12 && p0_pixel_y < 20) && (p0_pixel_x >= 18 && p0_pixel_x < 78);

                // "Insertion Sort" - 14 chars × 6 pixels = 84 pixels wide, centered at x=6
                in_title2_area = (p0_pixel_y >= 22 && p0_pixel_y < 30) && (p0_pixel_x >= 6 && p0_pixel_x < 90);

                // "C: Start" - 8 chars × 6 = 48 pixels, centered at x=24
                in_prompt_welcome_area = (p0_pixel_y >= 44 && p0_pixel_y < 52) && (p0_pixel_x >= 24 && p0_pixel_x < 72);

                char_idx_val = in_title1_area ? (p0_pixel_x - 18) / 6 :
                              (in_title2_area ? (p0_pixel_x - 6) / 6 :
                              (in_prompt_welcome_area ? ((p0_pixel_x - 24) / 6) : 0));

                char_col_val = in_title1_area ? ((p0_pixel_x - 18) % 6) :
                              (in_title2_area ? ((p0_pixel_x - 6) % 6) :
                              (in_prompt_welcome_area ? ((p0_pixel_x - 24) % 6) : 0));

                char_row_val = in_title1_area ? (p0_pixel_y - 12) :
                              (in_title2_area ? (p0_pixel_y - 22) :
                              (in_prompt_welcome_area ? (p0_pixel_y - 44) : 0));

                // "Welcome to" - W,e,l,c,o,m,e, ,t,o
                if (in_title1_area) begin
                    case (char_idx_val)
                        0: char_code_4x6_reg=7'd87;  // W
                        1: char_code_4x6_reg=7'd101; // e
                        2: char_code_4x6_reg=7'd108; // l
                        3: char_code_4x6_reg=7'd99;  // c
                        4: char_code_4x6_reg=7'd111; // o
                        5: char_code_4x6_reg=7'd109; // m
                        6: char_code_4x6_reg=7'd101; // e
                        7: char_code_4x6_reg=7'd32;  // space
                        8: char_code_4x6_reg=7'd116; // t
                        9: char_code_4x6_reg=7'd111; // o
                        default: char_code_4x6_reg=7'd32;
                    endcase
                end
                // "Insertion Sort" - I,n,s,e,r,t,i,o,n, ,S,o,r,t
                else if (in_title2_area) begin
                    case (char_idx_val)
                        0: char_code_4x6_reg=7'd73;  // I
                        1: char_code_4x6_reg=7'd110; // n
                        2: char_code_4x6_reg=7'd115; // s
                        3: char_code_4x6_reg=7'd101; // e
                        4: char_code_4x6_reg=7'd114; // r
                        5: char_code_4x6_reg=7'd116; // t
                        6: char_code_4x6_reg=7'd105; // i
                        7: char_code_4x6_reg=7'd111; // o
                        8: char_code_4x6_reg=7'd110; // n
                        9: char_code_4x6_reg=7'd32;  // space
                        10: char_code_4x6_reg=7'd83; // S
                        11: char_code_4x6_reg=7'd111;// o
                        12: char_code_4x6_reg=7'd114;// r
                        13: char_code_4x6_reg=7'd116;// t
                        default: char_code_4x6_reg=7'd32;
                    endcase
                end
                // "C: Start" - C,:, ,S,t,a,r,t (8 chars)
                else if (in_prompt_welcome_area) begin
                    case (char_idx_val)
                        0: char_code_4x6_reg=7'd67;  // C
                        1: char_code_4x6_reg=7'd58;  // :
                        2: char_code_4x6_reg=7'd32;  // space
                        3: char_code_4x6_reg=7'd83;  // S
                        4: char_code_4x6_reg=7'd116; // t
                        5: char_code_4x6_reg=7'd97;  // a
                        6: char_code_4x6_reg=7'd114; // r
                        7: char_code_4x6_reg=7'd116; // t
                        default: char_code_4x6_reg=7'd32;
                    endcase
                end
            end

            STATE_TUT_WELCOME: begin
                // Bold white text matching education mode style
                // "Insertion Sort" - 14 chars × 6 pixels = 84 pixels wide, centered at x=6
                in_title1_area = (p0_pixel_y >= 12 && p0_pixel_y < 20) && (p0_pixel_x >= 6 && p0_pixel_x < 90);

                // "Tutorial" - 8 chars × 6 pixels = 48 pixels wide, centered at x=24
                in_title2_area = (p0_pixel_y >= 22 && p0_pixel_y < 30) && (p0_pixel_x >= 24 && p0_pixel_x < 72);

                // "Press C: Start" - 14 chars × 6 pixels = 84 pixels wide, centered at x=6
                in_prompt_welcome_area = (p0_pixel_y >= 44 && p0_pixel_y < 52) && (p0_pixel_x >= 6 && p0_pixel_x < 90);

                char_idx_val = in_title1_area ? (p0_pixel_x - 6) / 6 :
                              (in_title2_area ? (p0_pixel_x - 24) / 6 :
                              (in_prompt_welcome_area ? (p0_pixel_x - 6) / 6 : 0));

                char_col_val = in_title1_area ? (p0_pixel_x - 6) % 6 :
                              (in_title2_area ? (p0_pixel_x - 24) % 6 :
                              (in_prompt_welcome_area ? (p0_pixel_x - 6) % 6 : 0));

                char_row_val = in_title1_area ? (p0_pixel_y - 12) :
                              (in_title2_area ? (p0_pixel_y - 22) :
                              (in_prompt_welcome_area ? (p0_pixel_y - 44) : 0));

                // "Insertion Sort" - I,n,s,e,r,t,i,o,n, ,S,o,r,t
                if (in_title1_area) begin
                    case (char_idx_val)
                        0: char_code_4x6_reg=7'd73;  // I
                        1: char_code_4x6_reg=7'd110; // n
                        2: char_code_4x6_reg=7'd115; // s
                        3: char_code_4x6_reg=7'd101; // e
                        4: char_code_4x6_reg=7'd114; // r
                        5: char_code_4x6_reg=7'd116; // t
                        6: char_code_4x6_reg=7'd105; // i
                        7: char_code_4x6_reg=7'd111; // o
                        8: char_code_4x6_reg=7'd110; // n
                        9: char_code_4x6_reg=7'd32;  // space
                        10: char_code_4x6_reg=7'd83; // S
                        11: char_code_4x6_reg=7'd111;// o
                        12: char_code_4x6_reg=7'd114;// r
                        13: char_code_4x6_reg=7'd116;// t
                        default: char_code_4x6_reg=7'd32;
                    endcase
                end
                // "Tutorial" - T,u,t,o,r,i,a,l
                else if (in_title2_area) begin
                    case (char_idx_val)
                        0: char_code_4x6_reg=7'd84;  // T
                        1: char_code_4x6_reg=7'd117; // u
                        2: char_code_4x6_reg=7'd116; // t
                        3: char_code_4x6_reg=7'd111; // o
                        4: char_code_4x6_reg=7'd114; // r
                        5: char_code_4x6_reg=7'd105; // i
                        6: char_code_4x6_reg=7'd97;  // a
                        7: char_code_4x6_reg=7'd108; // l
                        default: char_code_4x6_reg=7'd32;
                    endcase
                end
                // "Press C: Start" - P,r,e,s,s, ,C,:, ,S,t,a,r,t
                else if (in_prompt_welcome_area) begin
                    case (char_idx_val)
                        0: char_code_4x6_reg=7'd80;  // P
                        1: char_code_4x6_reg=7'd114; // r
                        2: char_code_4x6_reg=7'd101; // e
                        3: char_code_4x6_reg=7'd115; // s
                        4: char_code_4x6_reg=7'd115; // s
                        5: char_code_4x6_reg=7'd32;  // space
                        6: char_code_4x6_reg=7'd67;  // C
                        7: char_code_4x6_reg=7'd58;  // :
                        8: char_code_4x6_reg=7'd32;  // space
                        9: char_code_4x6_reg=7'd83;  // S
                        10: char_code_4x6_reg=7'd116;// t
                        11: char_code_4x6_reg=7'd97; // a
                        12: char_code_4x6_reg=7'd114;// r
                        13: char_code_4x6_reg=7'd116;// t
                        default: char_code_4x6_reg=7'd32;
                    endcase
                end
            end

            STATE_EDU_SORTING: begin
                red_line_x_comb = (red_line_pos == 3'd1) ? 7'd18 : (red_line_pos == 3'd2) ? 7'd33 : 
                                 (red_line_pos == 3'd3) ? 7'd48 : (red_line_pos == 3'd4) ? 7'd63 : 
                                 (red_line_pos == 3'd5) ? 7'd78 : 7'd93;
               in_red_line_val = (p0_pixel_x == red_line_x_comb) && (p0_pixel_y >= 6'd24 && p0_pixel_y < 6'd40);
                
                box_color_val = is_sorted_flag ? COLOR_GREEN : ((swap_idx1 == box_num_comb) || (swap_idx2 == box_num_comb)) ? COLOR_BLUE : ((compare_idx1 == box_num_comb) || (compare_idx2 == box_num_comb)) ? COLOR_YELLOW : COLOR_WHITE;
                digit_x_comb = p0_pixel_x - (4 + box_num_comb*15); digit_y_comb = p0_pixel_y - 27;
                in_digit_area_val = in_box_val && (digit_x_comb >= 4 && digit_x_comb < 9) && (digit_y_comb >= 2 && digit_y_comb < 9);
                case (box_num_comb) 0: digit_to_show_comb = current_array_0; 1: digit_to_show_comb = current_array_1; 2: digit_to_show_comb = current_array_2; 3: digit_to_show_comb = current_array_3; 4: digit_to_show_comb = current_array_4; 5: digit_to_show_comb = current_array_5; default: digit_to_show_comb = 0; endcase
                case (digit_to_show_comb) 0: digit_pattern_comb = { 5'b01110, 5'b10001, 5'b10011, 5'b10101, 5'b11001, 5'b10001, 5'b01110 }; 1: digit_pattern_comb = { 5'b00100, 5'b01100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b01110 }; 2: digit_pattern_comb = { 5'b01110, 5'b10001, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b11111 }; 3: digit_pattern_comb = { 5'b11111, 5'b00010, 5'b00100, 5'b00010, 5'b00001, 5'b10001, 5'b01110 }; 4: digit_pattern_comb = { 5'b00010, 5'b00110, 5'b01010, 5'b10010, 5'b11111, 5'b00010, 5'b00010 }; 5: digit_pattern_comb = { 5'b11111, 5'b10000, 5'b11110, 5'b00001, 5'b00001, 5'b10001, 5'b01110 }; default: digit_pattern_comb = 0; endcase
                digit_col_comb = digit_x_comb - 4; digit_row_comb = digit_y_comb - 2; pattern_bit_comb = 34 - (digit_row_comb * 5 + digit_col_comb);
                digit_pixel_val = digit_pattern_comb[pattern_bit_comb];
                
                prompt_sort_y_comb = 6'd52;  // Fixed position, no bounce for Education mode
                // Use 5-pixel spacing (4px font + 1px gap) for readable character spacing
                in_prompt_L_area = (p0_pixel_y >= prompt_sort_y_comb && p0_pixel_y < prompt_sort_y_comb + 6) &&
                                   (p0_pixel_x >= 2 && p0_pixel_x < 32);  // "L:Back" - 6 chars × 5 = 30 pixels (LEFT)
                in_prompt_R_area = !is_sorted_flag && (p0_pixel_y >= prompt_sort_y_comb && p0_pixel_y < prompt_sort_y_comb + 6) &&
                                   (p0_pixel_x >= 64 && p0_pixel_x < 94);  // "R:Next" - 6 chars × 5 = 30 pixels (RIGHT)
                in_prompt_U_area = is_sorted_flag && (p0_pixel_y >= prompt_sort_y_comb && p0_pixel_y < prompt_sort_y_comb + 6) &&
                                   (p0_pixel_x >= 49 && p0_pixel_x < 94);  // "U:Restart" - 9 chars × 5 = 45 pixels (RIGHT SIDE)
                in_prompt_sort_area = in_prompt_L_area || in_prompt_R_area || in_prompt_U_area;

                char_idx_val = in_prompt_L_area ? (p0_pixel_x - 2) / 5 :
                              (in_prompt_R_area ? (p0_pixel_x - 64) / 5 :
                              (in_prompt_U_area ? (p0_pixel_x - 49) / 5 : 0));
                char_col_val = in_prompt_L_area ? (p0_pixel_x - 2) % 5 :
                              (in_prompt_R_area ? (p0_pixel_x - 64) % 5 :
                              (in_prompt_U_area ? (p0_pixel_x - 49) % 5 : 0));
                char_row_val = in_prompt_sort_area ? (p0_pixel_y - prompt_sort_y_comb) : 0;
                
                // "L:Back" (no space after colon)
                if (in_prompt_L_area) begin
                    case (char_idx_val)
                        0: char_code_4x6_reg=7'd76;  // L
                        1: char_code_4x6_reg=7'd58;  // :
                        2: char_code_4x6_reg=7'd66;  // B
                        3: char_code_4x6_reg=7'd97;  // a
                        4: char_code_4x6_reg=7'd99;  // c
                        5: char_code_4x6_reg=7'd107; // k
                        default: char_code_4x6_reg=7'd32;
                    endcase
                end
                // "R:Next" (no space after colon)
                else if (in_prompt_R_area) begin
                    case (char_idx_val)
                        0: char_code_4x6_reg=7'd82;  // R
                        1: char_code_4x6_reg=7'd58;  // :
                        2: char_code_4x6_reg=7'd78;  // N
                        3: char_code_4x6_reg=7'd101; // e
                        4: char_code_4x6_reg=7'd120; // x
                        5: char_code_4x6_reg=7'd116; // t
                        default: char_code_4x6_reg=7'd32;
                    endcase
                end
                // "U:Restart" (no space after colon)
                else if (in_prompt_U_area) begin
                    case (char_idx_val)
                        0: char_code_4x6_reg=7'd85;  // U
                        1: char_code_4x6_reg=7'd58;  // :
                        2: char_code_4x6_reg=7'd82;  // R
                        3: char_code_4x6_reg=7'd101; // e
                        4: char_code_4x6_reg=7'd115; // s
                        5: char_code_4x6_reg=7'd116; // t
                        6: char_code_4x6_reg=7'd97;  // a
                        7: char_code_4x6_reg=7'd114; // r
                        8: char_code_4x6_reg=7'd116; // t
                        default: char_code_4x6_reg=7'd32;
                    endcase
                end
                else begin 
                    char_code_4x6_reg = 7'd0; 
                end
            end

            STATE_TUT_INPUT: begin
                tut_box_highlight_val = in_box_val && (box_num_comb == cursor_pos);
                box_color_val = tut_box_highlight_val ? COLOR_YELLOW : COLOR_WHITE;
                digit_x_comb = p0_pixel_x - (4 + box_num_comb*15); digit_y_comb = p0_pixel_y - 27;
                in_digit_area_val = in_box_val && (digit_x_comb >= 4 && digit_x_comb < 9) && (digit_y_comb >= 2 && digit_y_comb < 9);
                case (box_num_comb) 0: digit_to_show_comb = tut_array_0; 1: digit_to_show_comb = tut_array_1; 2: digit_to_show_comb = tut_array_2; 3: digit_to_show_comb = tut_array_3; 4: digit_to_show_comb = tut_array_4; 5: digit_to_show_comb = tut_array_5; default: digit_to_show_comb = 0; endcase
                case (digit_to_show_comb) 0: digit_pattern_comb = { 5'b01110, 5'b10001, 5'b10011, 5'b10101, 5'b11001, 5'b10001, 5'b01110 }; 1: digit_pattern_comb = { 5'b00100, 5'b01100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b01110 }; 2: digit_pattern_comb = { 5'b01110, 5'b10001, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b11111 }; 3: digit_pattern_comb = { 5'b11111, 5'b00010, 5'b00100, 5'b00010, 5'b00001, 5'b10001, 5'b01110 }; 4: digit_pattern_comb = { 5'b00010, 5'b00110, 5'b01010, 5'b10010, 5'b11111, 5'b00010, 5'b00010 }; 5: digit_pattern_comb = { 5'b11111, 5'b10000, 5'b11110, 5'b00001, 5'b00001, 5'b10001, 5'b01110 }; 6: digit_pattern_comb = { 5'b01111, 5'b10000, 5'b11110, 5'b10001, 5'b10001, 5'b10001, 5'b01110 }; 7: digit_pattern_comb = { 5'b11111, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b01000, 5'b01000 }; default: digit_pattern_comb = 0; endcase
                digit_col_comb = digit_x_comb - 4; digit_row_comb = digit_y_comb - 2; pattern_bit_comb = 34 - (digit_row_comb * 5 + digit_col_comb);
                digit_pixel_val = digit_pattern_comb[pattern_bit_comb];
            end
            
           STATE_TUT_READY: begin
                // "Ready to Sort?" screen - NO second line
                in_title1_area = (p0_pixel_y >= 26 && p0_pixel_y < 34) &&
                                 (p0_pixel_x >= 8 && p0_pixel_x <= 77);  // "Ready to Sort?" - 14 chars
                in_title2_area = 1'b0;  // Disabled - no second line

                prompt_welcome_y_comb = (bounce_offset) ? 6'd44 : 6'd45;
                in_prompt_welcome_area = (p0_pixel_y >= prompt_welcome_y_comb && p0_pixel_y < prompt_welcome_y_comb + 6) &&
                                        (p0_pixel_x >= 2 && p0_pixel_x <= 95);  // "Press btnC to start!" - 20 chars (fits!)

                char_idx_val = in_title1_area ? (p0_pixel_x - 8) / 5 :
                              (in_prompt_welcome_area ? (p0_pixel_x - 2) / 5 : 0);
                char_col_val = in_title1_area ? (p0_pixel_x - 8) % 5 :
                              (in_prompt_welcome_area ? (p0_pixel_x - 2) % 5 : 0);
                char_row_val = in_title1_area ? (p0_pixel_y - 26) : 
                              (in_prompt_welcome_area ? (p0_pixel_y - prompt_welcome_y_comb) : 0);
                
                char_color_idx_comb = char_idx_val % 6;
                title_color_val = (char_color_idx_comb == 0) ? COLOR_BLUE : 
                                  (char_color_idx_comb == 1) ? COLOR_RED : 
                                  (char_color_idx_comb == 2) ? COLOR_YELLOW : 
                                  (char_color_idx_comb == 3) ? COLOR_BLUE : 
                                  (char_color_idx_comb == 4) ? COLOR_GREEN : COLOR_RED;
                
                // "Ready to Sort?"
                if (in_title1_area) begin 
                    case (char_idx_val) 
                        0: char_code_4x6_reg=7'd82; 1: char_code_4x6_reg=7'd101; 2: char_code_4x6_reg=7'd97; 3: char_code_4x6_reg=7'd100; 
                        4: char_code_4x6_reg=7'd121; 5: char_code_4x6_reg=7'd32; 6: char_code_4x6_reg=7'd116; 7: char_code_4x6_reg=7'd111; 
                        8: char_code_4x6_reg=7'd32; 9: char_code_4x6_reg=7'd83; 10: char_code_4x6_reg=7'd111; 11: char_code_4x6_reg=7'd114; 
                        12: char_code_4x6_reg=7'd116; 13: char_code_4x6_reg=7'd63; 
                        default: char_code_4x6_reg=7'd32; 
                    endcase 
                end
                // "Press btnC to start!"
                else if (in_prompt_welcome_area) begin 
                    case (char_idx_val) 
                        0: char_code_4x6_reg=7'd80; 1: char_code_4x6_reg=7'd114; 2: char_code_4x6_reg=7'd101; 3: char_code_4x6_reg=7'd115; 
                        4: char_code_4x6_reg=7'd115; 5: char_code_4x6_reg=7'd32; 6: char_code_4x6_reg=7'd98; 7: char_code_4x6_reg=7'd116; 
                        8: char_code_4x6_reg=7'd110; 9: char_code_4x6_reg=7'd67; 10: char_code_4x6_reg=7'd32; 11: char_code_4x6_reg=7'd116; 
                        12: char_code_4x6_reg=7'd111; 13: char_code_4x6_reg=7'd32; 14: char_code_4x6_reg=7'd115; 15: char_code_4x6_reg=7'd116; 
                        16: char_code_4x6_reg=7'd97; 17: char_code_4x6_reg=7'd114; 18: char_code_4x6_reg=7'd116; 19: char_code_4x6_reg=7'd33; 
                        default: char_code_4x6_reg=7'd32; 
                    endcase 
                end
                else begin 
                    char_code_4x6_reg = 7'd0; 
                end
            end

            STATE_TUT_SORTING: begin
                // Similar to EDU_SORTING but with tutorial arrays and hearts
                red_line_x_comb = (tut_red_line_pos == 3'd1) ? 7'd18 : 
                                  (tut_red_line_pos == 3'd2) ? 7'd33 : 
                                  (tut_red_line_pos == 3'd3) ? 7'd48 : 
                                  (tut_red_line_pos == 3'd4) ? 7'd63 : 
                                  (tut_red_line_pos == 3'd5) ? 7'd78 : 7'd93;
                in_red_line_val = (p0_pixel_x == red_line_x_comb) && (p0_pixel_y >= 6'd24 && p0_pixel_y < 6'd40);
                
                // Box colors based on state (yellow=compare, blue=swap, white=normal)
                box_color_val = ((tut_swap_idx1 == box_num_comb) || (tut_swap_idx2 == box_num_comb)) ? COLOR_BLUE : 
                               ((tut_compare_idx1 == box_num_comb) || (tut_compare_idx2 == box_num_comb)) ? COLOR_YELLOW : 
                               COLOR_WHITE;
                
                // Digit rendering in boxes
                digit_x_comb = p0_pixel_x - (4 + box_num_comb*15); 
                digit_y_comb = p0_pixel_y - 27;
                in_digit_area_val = in_box_val && (digit_x_comb >= 4 && digit_x_comb < 9) && (digit_y_comb >= 2 && digit_y_comb < 9);
                
                case (box_num_comb) 
                    0: digit_to_show_comb = tut_sort_array_0; 1: digit_to_show_comb = tut_sort_array_1; 
                    2: digit_to_show_comb = tut_sort_array_2; 3: digit_to_show_comb = tut_sort_array_3; 
                    4: digit_to_show_comb = tut_sort_array_4; 5: digit_to_show_comb = tut_sort_array_5; 
                    default: digit_to_show_comb = 0; 
                endcase
                
                case (digit_to_show_comb)
                    0: digit_pattern_comb = { 5'b01110, 5'b10001, 5'b10011, 5'b10101, 5'b11001, 5'b10001, 5'b01110 };
                    1: digit_pattern_comb = { 5'b00100, 5'b01100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b01110 };
                    2: digit_pattern_comb = { 5'b01110, 5'b10001, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b11111 };
                    3: digit_pattern_comb = { 5'b11111, 5'b00010, 5'b00100, 5'b00010, 5'b00001, 5'b10001, 5'b01110 };
                    4: digit_pattern_comb = { 5'b00010, 5'b00110, 5'b01010, 5'b10010, 5'b11111, 5'b00010, 5'b00010 };
                    5: digit_pattern_comb = { 5'b11111, 5'b10000, 5'b11110, 5'b00001, 5'b00001, 5'b10001, 5'b01110 };
                    6: digit_pattern_comb = { 5'b01111, 5'b10000, 5'b11110, 5'b10001, 5'b10001, 5'b10001, 5'b01110 };
                    7: digit_pattern_comb = { 5'b11111, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b01000, 5'b01000 };
                    default: digit_pattern_comb = 0;
                endcase
                
                digit_col_comb = digit_x_comb - 4; 
                digit_row_comb = digit_y_comb - 2; 
                pattern_bit_comb = 34 - (digit_row_comb * 5 + digit_col_comb);
                digit_pixel_val = digit_pattern_comb[pattern_bit_comb];
                
                //==================================================================
                // Hearts rendering (top-right corner)
                //==================================================================
                in_heart_area_comb = (p0_pixel_y >= 2 && p0_pixel_y < 10);
                if (in_heart_area_comb) begin
                    // Check which heart we're in (hearts at x=70, 78, 86)
                    if (p0_pixel_x >= 70 && p0_pixel_x < 78 && hearts_remaining >= 1) begin
                        heart_pixel_comb = get_heart_pixel(p0_pixel_x - 70, p0_pixel_y - 2);
                    end else if (p0_pixel_x >= 78 && p0_pixel_x < 86 && hearts_remaining >= 2) begin
                        heart_pixel_comb = get_heart_pixel(p0_pixel_x - 78, p0_pixel_y - 2);
                    end else if (p0_pixel_x >= 86 && p0_pixel_x < 94 && hearts_remaining >= 3) begin
                        heart_pixel_comb = get_heart_pixel(p0_pixel_x - 86, p0_pixel_y - 2);
                    end else begin
                        heart_pixel_comb = 1'b0;
                    end
                end
                
                //==================================================================
                // Red X rendering (when mistake shown)
                //==================================================================
                if (show_mistake && tut_compare_idx1 != 3'd7 && tut_compare_idx2 != 3'd7) begin
                    // Calculate X position (centered between two boxes)
                    red_x_x_comb = 4 + tut_compare_idx1*15 + 7 + 4;  // Center between boxes
                    in_red_x_area_comb = (p0_pixel_x >= red_x_x_comb && p0_pixel_x < red_x_x_comb + 8) && 
                                        (p0_pixel_y >= 15 && p0_pixel_y < 23);
                    if (in_red_x_area_comb) begin
                        red_x_pixel_comb = get_red_x_pixel(p0_pixel_x - red_x_x_comb, p0_pixel_y - 15);
                    end
                end
                
                //==================================================================
                // DYNAMIC PROMPTS based on sub-state
                //==================================================================
                prompt_sort_y_comb = 6'd50;  // Fixed position for stable rendering
                
                // *** KEY LOGIC: Detect which phase we're in ***
                // If compare indices are valid (not 7), we're in DECISION phase
                // Otherwise, we're in COMPARE phase
                
                if (tut_compare_idx1 != 3'd7 && tut_compare_idx2 != 3'd7) begin
                    //==============================================================
                    // DECISION PHASE: Show "C: Swap   D: Keep"
                    //==============================================================
                    in_prompt_L_area = (p0_pixel_y >= prompt_sort_y_comb && p0_pixel_y < prompt_sort_y_comb + 6) &&
                                      (p0_pixel_x >= 4 && p0_pixel_x < 39);   // "C: Swap" - 7 chars × 5 = 35 pixels
                    in_prompt_R_area = (p0_pixel_y >= prompt_sort_y_comb && p0_pixel_y < prompt_sort_y_comb + 6) &&
                                      (p0_pixel_x >= 59 && p0_pixel_x < 94);  // "D: Keep" - 7 chars × 5 = 35 pixels

                    char_idx_val = in_prompt_L_area ? (p0_pixel_x - 4) / 5 :
                                  (in_prompt_R_area ? (p0_pixel_x - 59) / 5 : 0);
                    char_col_val = in_prompt_L_area ? (p0_pixel_x - 4) % 5 :
                                  (in_prompt_R_area ? (p0_pixel_x - 59) % 5 : 0);
                    
                    // "C: Swap"
                    if (in_prompt_L_area) begin 
                        case (char_idx_val) 
                            0: char_code_4x6_reg=7'd67;  // C
                            1: char_code_4x6_reg=7'd58;  // :
                            2: char_code_4x6_reg=7'd32;  // space
                            3: char_code_4x6_reg=7'd83;  // S
                            4: char_code_4x6_reg=7'd119; // w
                            5: char_code_4x6_reg=7'd97;  // a
                            6: char_code_4x6_reg=7'd112; // p
                            default: char_code_4x6_reg=7'd32; 
                        endcase 
                    end
                    // "D: Keep"
                    else if (in_prompt_R_area) begin 
                        case (char_idx_val) 
                            0: char_code_4x6_reg=7'd68;  // D
                            1: char_code_4x6_reg=7'd58;  // :
                            2: char_code_4x6_reg=7'd32;  // space
                            3: char_code_4x6_reg=7'd75;  // K
                            4: char_code_4x6_reg=7'd101; // e
                            5: char_code_4x6_reg=7'd101; // e
                            6: char_code_4x6_reg=7'd112; // p
                            default: char_code_4x6_reg=7'd32; 
                        endcase 
                    end
                    else begin 
                        char_code_4x6_reg = 7'd0; 
                    end
                    
                end else begin
                    //==============================================================
                    // COMPARE PHASE: Show "L: Left   R: Right"
                    //==============================================================
                    in_prompt_L_area = (p0_pixel_y >= prompt_sort_y_comb && p0_pixel_y < prompt_sort_y_comb + 6) &&
                                      (p0_pixel_x >= 4 && p0_pixel_x < 39);   // "L: Left" - 7 chars × 5 = 35 pixels
                    in_prompt_R_area = (p0_pixel_y >= prompt_sort_y_comb && p0_pixel_y < prompt_sort_y_comb + 6) &&
                                      (p0_pixel_x >= 54 && p0_pixel_x < 94); // "R: Right" - 8 chars × 5 = 40 pixels

                    char_idx_val = in_prompt_L_area ? (p0_pixel_x - 4) / 5 :
                                  (in_prompt_R_area ? (p0_pixel_x - 54) / 5 : 0);
                    char_col_val = in_prompt_L_area ? (p0_pixel_x - 4) % 5 :
                                  (in_prompt_R_area ? (p0_pixel_x - 54) % 5 : 0);
                    
                    // "L: Left"
                    if (in_prompt_L_area) begin 
                        case (char_idx_val) 
                            0: char_code_4x6_reg=7'd76;  // L
                            1: char_code_4x6_reg=7'd58;  // :
                            2: char_code_4x6_reg=7'd32;  // space
                            3: char_code_4x6_reg=7'd76;  // L
                            4: char_code_4x6_reg=7'd101; // e
                            5: char_code_4x6_reg=7'd102; // f
                            6: char_code_4x6_reg=7'd116; // t
                            default: char_code_4x6_reg=7'd32; 
                        endcase 
                    end
                    // "R: Right"
                    else if (in_prompt_R_area) begin 
                        case (char_idx_val) 
                            0: char_code_4x6_reg=7'd82;  // R
                            1: char_code_4x6_reg=7'd58;  // :
                            2: char_code_4x6_reg=7'd32;  // space
                            3: char_code_4x6_reg=7'd82;  // R
                            4: char_code_4x6_reg=7'd105; // i
                            5: char_code_4x6_reg=7'd103; // g
                            6: char_code_4x6_reg=7'd104; // h
                            7: char_code_4x6_reg=7'd116; // t
                            default: char_code_4x6_reg=7'd32; 
                        endcase 
                    end
                    else begin 
                        char_code_4x6_reg = 7'd0; 
                    end
                end
                
                // Mark that we're in prompt area (for pipeline stage 2)
                in_prompt_sort_area = in_prompt_L_area || in_prompt_R_area;
                // Calculate char_row_val individually to prevent boundary glitches
                char_row_val = (in_prompt_L_area || in_prompt_R_area) ? (p0_pixel_y - prompt_sort_y_comb) : 0;
            end

            STATE_TUT_GAME_OVER: begin
                // Large "GAME OVER!" text
                in_title1_area = (p0_pixel_y >= 24 && p0_pixel_y < 30) && (p0_pixel_x >= 8 && p0_pixel_x <= 52);  // "GAME OVER" - 9 chars
                in_title2_area = (p0_pixel_y >= 32 && p0_pixel_y < 38) && (p0_pixel_x >= 23 && p0_pixel_x <= 47); // "RETRY" - 5 chars
                prompt_welcome_y_comb = (bounce_offset) ? 6'd48 : 6'd49;
                in_prompt_welcome_area = (p0_pixel_y >= prompt_welcome_y_comb && p0_pixel_y < prompt_welcome_y_comb + 6) && (p0_pixel_x >= 2 && p0_pixel_x <= 95);  // "Press btnC to retry!" - 20 chars

                char_idx_val = in_title1_area ? (p0_pixel_x - 8) / 5 : (in_title2_area ? (p0_pixel_x - 23) / 5 : (in_prompt_welcome_area ? (p0_pixel_x - 2) / 5 : 0));
                char_col_val = in_title1_area ? (p0_pixel_x - 8) % 5 : (in_title2_area ? (p0_pixel_x - 23) % 5 : (in_prompt_welcome_area ? (p0_pixel_x - 2) % 5 : 0));
                char_row_val = in_title1_area ? (p0_pixel_y - 24) : (in_title2_area ? (p0_pixel_y - 32) : (in_prompt_welcome_area ? (p0_pixel_y - prompt_welcome_y_comb) : 0));
                
                title_color_val = COLOR_RED;  // All red for game over
                
                // "GAME OVER"
                if (in_title1_area) begin 
                    case (char_idx_val) 
                        0: char_code_4x6_reg=7'd71; 1: char_code_4x6_reg=7'd65; 2: char_code_4x6_reg=7'd77; 3: char_code_4x6_reg=7'd69; 
                        4: char_code_4x6_reg=7'd32; 5: char_code_4x6_reg=7'd79; 6: char_code_4x6_reg=7'd86; 7: char_code_4x6_reg=7'd69; 
                        8: char_code_4x6_reg=7'd82; 
                        default: char_code_4x6_reg=7'd32; 
                    endcase 
                end
                // "RETRY"
                else if (in_title2_area) begin 
                    case (char_idx_val) 
                        0: char_code_4x6_reg=7'd82; 1: char_code_4x6_reg=7'd69; 2: char_code_4x6_reg=7'd84; 3: char_code_4x6_reg=7'd82; 
                        4: char_code_4x6_reg=7'd89; 
                        default: char_code_4x6_reg=7'd32; 
                    endcase 
                end
                // "Press btnC to retry!"
                else if (in_prompt_welcome_area) begin 
                    case (char_idx_val) 
                        0: char_code_4x6_reg=7'd80; 1: char_code_4x6_reg=7'd114; 2: char_code_4x6_reg=7'd101; 3: char_code_4x6_reg=7'd115; 
                        4: char_code_4x6_reg=7'd115; 5: char_code_4x6_reg=7'd32; 6: char_code_4x6_reg=7'd98; 7: char_code_4x6_reg=7'd116; 
                        8: char_code_4x6_reg=7'd110; 9: char_code_4x6_reg=7'd67; 10: char_code_4x6_reg=7'd32; 11: char_code_4x6_reg=7'd116; 
                        12: char_code_4x6_reg=7'd111; 13: char_code_4x6_reg=7'd32; 14: char_code_4x6_reg=7'd114; 15: char_code_4x6_reg=7'd101; 
                        16: char_code_4x6_reg=7'd116; 17: char_code_4x6_reg=7'd114; 18: char_code_4x6_reg=7'd121; 19: char_code_4x6_reg=7'd33; 
                        default: char_code_4x6_reg=7'd32; 
                    endcase 
                end
                else begin char_code_4x6_reg = 7'd0; end
            end

            STATE_TUT_VICTORY: begin
                // "WELL DONE!" in green with all boxes green
                in_title1_area = (p0_pixel_y >= 44 && p0_pixel_y < 50) && (p0_pixel_x >= 13 && p0_pixel_x <= 62);  // "WELL DONE!" - 10 chars
                prompt_welcome_y_comb = (bounce_offset) ? 6'd54 : 6'd55;
                in_prompt_welcome_area = (p0_pixel_y >= prompt_welcome_y_comb && p0_pixel_y < prompt_welcome_y_comb + 6) && (p0_pixel_x >= 1 && p0_pixel_x <= 95);  // "Press btnC to try again!" - fits within

                char_idx_val = in_title1_area ? (p0_pixel_x - 13) / 5 : (in_prompt_welcome_area ? (p0_pixel_x - 1) / 5 : 0);
                char_col_val = in_title1_area ? (p0_pixel_x - 13) % 5 : (in_prompt_welcome_area ? (p0_pixel_x - 1) % 5 : 0);
                char_row_val = in_title1_area ? (p0_pixel_y - 44) : (in_prompt_welcome_area ? (p0_pixel_y - prompt_welcome_y_comb) : 0);
                
                title_color_val = COLOR_GREEN;  // All green for victory!
                
                // Show boxes as green
                box_color_val = COLOR_GREEN;
                
                // Show digits in boxes
                digit_x_comb = p0_pixel_x - (4 + box_num_comb*15); 
                digit_y_comb = p0_pixel_y - 27;
                in_digit_area_val = in_box_val && (digit_x_comb >= 4 && digit_x_comb < 9) && (digit_y_comb >= 2 && digit_y_comb < 9);
                
                case (box_num_comb) 
                    0: digit_to_show_comb = tut_sort_array_0; 1: digit_to_show_comb = tut_sort_array_1; 
                    2: digit_to_show_comb = tut_sort_array_2; 3: digit_to_show_comb = tut_sort_array_3; 
                    4: digit_to_show_comb = tut_sort_array_4; 5: digit_to_show_comb = tut_sort_array_5; 
                    default: digit_to_show_comb = 0; 
                endcase
                
                case (digit_to_show_comb) 
                    0: digit_pattern_comb = { 5'b01110, 5'b10001, 5'b10011, 5'b10101, 5'b11001, 5'b10001, 5'b01110 }; 
                    1: digit_pattern_comb = { 5'b00100, 5'b01100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b01110 }; 
                    2: digit_pattern_comb = { 5'b01110, 5'b10001, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b11111 }; 
                    3: digit_pattern_comb = { 5'b11111, 5'b00010, 5'b00100, 5'b00010, 5'b00001, 5'b10001, 5'b01110 }; 
                    4: digit_pattern_comb = { 5'b00010, 5'b00110, 5'b01010, 5'b10010, 5'b11111, 5'b00010, 5'b00010 }; 
                    5: digit_pattern_comb = { 5'b11111, 5'b10000, 5'b11110, 5'b00001, 5'b00001, 5'b10001, 5'b01110 }; 
                    6: digit_pattern_comb = { 5'b01111, 5'b10000, 5'b11110, 5'b10001, 5'b10001, 5'b10001, 5'b01110 }; 
                    7: digit_pattern_comb = { 5'b11111, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b01000, 5'b01000 }; 
                    default: digit_pattern_comb = 0; 
                endcase
                
                digit_col_comb = digit_x_comb - 4; 
                digit_row_comb = digit_y_comb - 2; 
                pattern_bit_comb = 34 - (digit_row_comb * 5 + digit_col_comb);
                digit_pixel_val = digit_pattern_comb[pattern_bit_comb];
                
                // "WELL DONE!"
                if (in_title1_area) begin 
                    case (char_idx_val) 
                        0: char_code_4x6_reg=7'd87; 1: char_code_4x6_reg=7'd69; 2: char_code_4x6_reg=7'd76; 3: char_code_4x6_reg=7'd76; 
                        4: char_code_4x6_reg=7'd32; 5: char_code_4x6_reg=7'd68; 6: char_code_4x6_reg=7'd79; 7: char_code_4x6_reg=7'd78; 
                        8: char_code_4x6_reg=7'd69; 9: char_code_4x6_reg=7'd33; 
                        default: char_code_4x6_reg=7'd32; 
                    endcase 
                end
                // "Press btnC to try again!"
                else if (in_prompt_welcome_area) begin 
                    case (char_idx_val) 
                        0: char_code_4x6_reg=7'd80; 1: char_code_4x6_reg=7'd114; 2: char_code_4x6_reg=7'd101; 3: char_code_4x6_reg=7'd115; 
                        4: char_code_4x6_reg=7'd115; 5: char_code_4x6_reg=7'd32; 6: char_code_4x6_reg=7'd98; 7: char_code_4x6_reg=7'd116; 
                        8: char_code_4x6_reg=7'd110; 9: char_code_4x6_reg=7'd67; 10: char_code_4x6_reg=7'd32; 11: char_code_4x6_reg=7'd116; 
                        12: char_code_4x6_reg=7'd111; 13: char_code_4x6_reg=7'd32; 14: char_code_4x6_reg=7'd116; 15: char_code_4x6_reg=7'd114; 
                        16: char_code_4x6_reg=7'd121; 17: char_code_4x6_reg=7'd32; 18: char_code_4x6_reg=7'd97; 19: char_code_4x6_reg=7'd103; 
                        20: char_code_4x6_reg=7'd97; 21: char_code_4x6_reg=7'd105; 22: char_code_4x6_reg=7'd110; 23: char_code_4x6_reg=7'd33; 
                        default: char_code_4x6_reg=7'd32; 
                    endcase 
                end
                else begin char_code_4x6_reg = 7'd0; end
            end
            default: ; // Do nothing
        endcase

        // Calculate font pixel - needed for stage 1 register
       // Calculate is_font_pixel_comb with strict bounds checking
       // Sorting prompts use regular 4×6 font (4-pixel width), titles use bold 5×7 font (5-pixel width)
                is_font_pixel_comb = (in_prompt_sort_area ? (char_col_val[2:0] < 3'd4) :
                                     (use_bold_font ? (char_col_val[2:0] < 3'd6) :
                                                      (char_col_val[2:0] < 3'd4))) &&
                                     (char_row_val[2:0] < 3'd7) &&
                                     (in_title1_area || in_title2_area || in_prompt_welcome_area || in_prompt_sort_area) &&
                                     (char_idx_val < 5'd24);  // Max 24 characters per line

        // Feed same character code to both font ROMs (selection happens at output)
        char_code_5x7_reg = char_code_4x6_reg;
    end

    // Register all intermediate values into Pipeline Stage 1 registers
    always @(posedge clk_100mhz) begin
        p1_char_row_4x6 <= char_row_val; // Row is needed by ROM
        p1_char_col_4x6 <= char_col_val; // Col is needed for final pixel check
        p1_title_color  <= title_color_val;
        p1_in_cloud     <= in_cloud && cloud_pixel;
        p1_in_tree      <= in_tree;
        p1_tree_color   <= tree_color;
        p1_in_prompt_welcome <= in_prompt_welcome_area;
        p1_in_title1    <= in_title1_area;
        p1_in_title2    <= in_title2_area;
        p1_in_red_line  <= in_red_line_val;
        p1_in_box       <= in_box_val;
        p1_box_color    <= box_color_val;
        p1_in_digit_area <= in_digit_area_val;
        p1_digit_pixel  <= digit_pixel_val;
        p1_in_prompt_sort <= in_prompt_sort_area;
        p1_tut_box_highlight <= tut_box_highlight_val;
        p1_is_font_pixel <= is_font_pixel_comb; // Register font pixel status
        // Tutorial sort visual elements
        p1_in_heart_area <= in_heart_area_comb;
        p1_heart_pixel <= heart_pixel_comb;
        p1_in_red_x_area <= in_red_x_area_comb;
        p1_red_x_pixel <= red_x_pixel_comb;
    end

    //==========================================================================
    // PIPELINE STAGE 2 (Final Color Selection - Uses only Stage 1 Registers)
    //==========================================================================
    // Check font ROM output based on registered col from Stage 1
    wire font_pixel_4x6 = p1_is_font_pixel && font_pixel_row_4x6[3 - p1_char_col_4x6];
    wire font_pixel_5x7 = p1_is_font_pixel && (p1_char_col_4x6 < 5) && font_pixel_row_5x7_bold[4 - p1_char_col_4x6];

    // Select which font pixel to use
    // Sorting prompts use regular font even in Education mode for better rendering
    wire font_pixel_active = (use_bold_font && !p1_in_prompt_sort) ? font_pixel_5x7 : font_pixel_4x6;

    always @(posedge clk_100mhz) begin
        if (!system_enable) begin
            p2_fb_wr_data <= COLOR_BLACK;
        end else begin
            // --- Use registered state signal (current_screen input is combinational) ---
            case (current_screen)
                //==============================================================
                STATE_EDU_SORTING: begin
                    if (p1_in_red_line) begin
                        p2_fb_wr_data <= COLOR_RED;
                    end else if (p1_in_digit_area && p1_digit_pixel) begin
                        p2_fb_wr_data <= COLOR_BLACK;
                    end else if (p1_in_box) begin
                        p2_fb_wr_data <= p1_box_color;
                    end else if (p1_in_prompt_sort && font_pixel_active) begin
                        p2_fb_wr_data <= COLOR_WHITE;  // Bold white text
                    end else begin
                        p2_fb_wr_data <= COLOR_BLACK;
                    end
                end

                //==============================================================
                STATE_EDU_WELCOME: begin
                    // Clean design: only text, no clouds/trees
                    if (p1_in_prompt_welcome && font_pixel_active) begin
                        p2_fb_wr_data <= COLOR_WHITE;  // Bold white text
                    end else if ((p1_in_title1 || p1_in_title2) && font_pixel_active) begin
                        p2_fb_wr_data <= COLOR_WHITE;  // Bold white text
                    end else begin
                        p2_fb_wr_data <= COLOR_BLACK;  // Black background
                    end
                end
                
                STATE_TUT_WELCOME, STATE_TUT_READY: begin
                    // Bold white text matching education mode style
                    if (p1_in_prompt_welcome && font_pixel_active) begin
                        p2_fb_wr_data <= COLOR_WHITE;  // Bold white text
                    end else if ((p1_in_title1 || p1_in_title2) && font_pixel_active) begin
                        p2_fb_wr_data <= COLOR_WHITE;  // Bold white text (no rainbow)
                    end else begin
                        p2_fb_wr_data <= COLOR_BLACK;  // Black background
                    end
                end

                //==============================================================
                STATE_TUT_INPUT: begin
                    if (p1_in_digit_area && p1_digit_pixel) begin 
                        p2_fb_wr_data <= COLOR_BLACK;
                    end else if (p1_in_box) begin 
                        p2_fb_wr_data <= p1_box_color;
                    end else begin 
                        p2_fb_wr_data <= COLOR_BLACK; 
                    end
                end

                //==============================================================
                STATE_TUT_SORTING: begin
                    // Priority order matters!
                    if (p1_in_red_x_area && p1_red_x_pixel) begin
                        // Red X (highest priority - mistake indicator)
                        p2_fb_wr_data <= COLOR_RED;
                    end else if (p1_in_heart_area && p1_heart_pixel) begin
                        // Hearts (top-right)
                        p2_fb_wr_data <= COLOR_RED;
                    end else if (p1_in_red_line) begin 
                        // Red line (partition marker)
                        p2_fb_wr_data <= COLOR_RED;
                    end else if (p1_in_digit_area && p1_digit_pixel) begin 
                        // Digits inside boxes
                        p2_fb_wr_data <= COLOR_BLACK;
                    end else if (p1_in_box) begin 
                        // Box borders (colored based on state)
                        p2_fb_wr_data <= p1_box_color;
                    end else if (p1_in_prompt_sort && font_pixel_4x6) begin 
                        // Bottom prompts
                        p2_fb_wr_data <= COLOR_WHITE;
                    end else begin 
                        p2_fb_wr_data <= COLOR_BLACK; 
                    end
                end

                //==============================================================
                STATE_TUT_GAME_OVER: begin
                    if (p1_in_prompt_welcome && font_pixel_4x6) begin
                        // Bottom prompt
                        p2_fb_wr_data <= COLOR_WHITE;
                    end else if ((p1_in_title1 || p1_in_title2) && font_pixel_4x6) begin
                        // "GAME OVER" and "RETRY" in red
                        p2_fb_wr_data <= p1_title_color;
                    end else begin
                        p2_fb_wr_data <= COLOR_BLACK;
                    end
                end

                //==============================================================
                STATE_TUT_VICTORY: begin
                    if (p1_in_prompt_welcome && font_pixel_4x6) begin
                        // Bottom prompt
                        p2_fb_wr_data <= COLOR_WHITE;
                    end else if (p1_in_title1 && font_pixel_4x6) begin
                        // "WELL DONE!" in green
                        p2_fb_wr_data <= p1_title_color;
                    end else if (p1_in_digit_area && p1_digit_pixel) begin 
                        // Digits in boxes
                        p2_fb_wr_data <= COLOR_BLACK;
                    end else if (p1_in_box) begin 
                        // All boxes green!
                        p2_fb_wr_data <= p1_box_color;
                    end else begin 
                        p2_fb_wr_data <= COLOR_BLACK; 
                    end
                end

                //==============================================================
                default: begin
                    p2_fb_wr_data <= COLOR_BLACK;
                end
            endcase
        end
    end

    //==========================================================================
    // FINAL RENDER (MAIN LOOP - FIXED: Added IDLE state to prevent continuous re-writing)
    //==========================================================================
    always @(posedge clk_100mhz) begin
        if (!system_enable) begin
            // Reset when system disabled
            render_state <= RENDER_IDLE;
            addr_counter <= 13'd0;
            fb_wr_en <= 1'b0;
            prev_frame_begin <= 1'b0;
        end else begin
            // Edge detection for frame_begin
            prev_frame_begin <= frame_begin;

            case (render_state)
                RENDER_IDLE: begin
                    // Wait for rising edge of frame_begin (start of new frame)
                    fb_wr_en <= 1'b0;  // No writing in IDLE

                    if (frame_begin && !prev_frame_begin) begin
                        // Start rendering a new frame
                        render_state <= RENDER_ACTIVE;
                        addr_counter <= 13'd0;
                    end
                end

                RENDER_ACTIVE: begin
                    // Write pixels to frame buffer
                    fb_wr_en <= 1'b1;
                    fb_wr_addr <= p0_addr;
                    fb_wr_data <= p2_fb_wr_data;

                    if (addr_counter >= 13'd6143) begin
                        // Finished rendering all pixels, return to IDLE
                        render_state <= RENDER_IDLE;
                        addr_counter <= 13'd0;
                    end else begin
                        // Continue rendering
                        addr_counter <= addr_counter + 13'd1;
                    end
                end

                default: begin
                    render_state <= RENDER_IDLE;
                end
            endcase
        end
    end
    
    //==========================================================================
        // HELPER FUNCTIONS FOR TUTORIAL SORT VISUALS
        //==========================================================================
        
        // Function to get heart pixel pattern (8x8 heart shape)
        function get_heart_pixel;
            input [2:0] x;  // 0-7
            input [2:0] y;  // 0-7
            begin
                case (y)
                    3'd0: get_heart_pixel = (x == 1 || x == 2 || x == 5 || x == 6);
                    3'd1: get_heart_pixel = (x >= 0 && x <= 7);
                    3'd2: get_heart_pixel = (x >= 0 && x <= 7);
                    3'd3: get_heart_pixel = (x >= 0 && x <= 7);
                    3'd4: get_heart_pixel = (x >= 1 && x <= 6);
                    3'd5: get_heart_pixel = (x >= 2 && x <= 5);
                    3'd6: get_heart_pixel = (x >= 3 && x <= 4);
                    3'd7: get_heart_pixel = 1'b0;
                    default: get_heart_pixel = 1'b0;
                endcase
            end
        endfunction
        
        // Function to get red X pixel pattern (8x8 X shape)
        function get_red_x_pixel;
            input [2:0] x;  // 0-7
            input [2:0] y;  // 0-7
            begin
                // X pattern: diagonal from top-left to bottom-right AND top-right to bottom-left
                get_red_x_pixel = (x == y) || (x == (7 - y));
            end
        endfunction

endmodule