`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.10.2025 22:22:32
// Design Name: 
// Module Name: sorting_visualizer_top
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


module sorting_visualizer_top(
    input clk,
    input sw_14, // For system enable
    input sw_10, // For tutorial mode enable
    input btnC,
    input btnL,
    input btnR,
    input btnU,
    input btnD,
    output[6:0] seg,
    output[3:0] an,
    output dp,
    output [15:0] led,
    output [7:0] JC         // Use full 8-bit bus like your working project
);

    //==========================================================================
    // System & Mode Enable
    //==========================================================================
    wire system_enable;
    wire tutorial_mode_active; // <-- ADDED

    assign system_enable = sw_14;       // Use sw[14] as main enable
    assign tutorial_mode_active = system_enable && sw_10; // <-- ADDED Tutorial mode logic
    assign led[14] = system_enable;
    assign led[10] = tutorial_mode_active; // <-- ADDED LED indicator for tutorial mode
    
    //==========================================================================
    // Generate 6.25MHz Clock (exactly like your working project)
    //==========================================================================
    wire clk_6p25mhz;
    
    clock_divider clk_div(
        .clk(clk),
        .m(16),  // 100MHz / 16 = 6.25MHz
        .divided_clk(clk_6p25mhz)
    );
    
    //==========================================================================
    // Clock Enable Signals
    //==========================================================================
    wire ce_30hz;
    wire ce_2hz;
    
    Clock_Generator clk_gen(
        .clk_100mhz(clk),
        .reset(!system_enable),
        .ce_1mhz(),  // Not used
        .ce_30hz(ce_30hz),
        .ce_2hz(ce_2hz)
    );
    
    //==========================================================================
    // Button Debouncers
    //==========================================================================
    wire btnC_pulse, btnL_pulse, btnR_pulse, btnU_pulse, btnD_pulse ;
    
    Button_Debouncer debounce_C(
        .clk_100mhz(clk),
        .btn_in(btnC && system_enable),
        .btn_press_pulse(btnC_pulse)
    );
    
    Button_Debouncer debounce_L(
        .clk_100mhz(clk),
        .btn_in(btnL && system_enable),
        .btn_press_pulse(btnL_pulse)
    );
    
    Button_Debouncer debounce_R(
        .clk_100mhz(clk),
        .btn_in(btnR && system_enable),
        .btn_press_pulse(btnR_pulse)
    );
    
    Button_Debouncer debounce_U(
        .clk_100mhz(clk),
        .btn_in(btnU),
        .btn_press_pulse(btnU_pulse)
    );
    
    Button_Debouncer debounce_D(.clk_100mhz(clk), 
    .btn_in(btnD && system_enable), 
    .btn_press_pulse(btnD_pulse) 
    );
    
    //==========================================================================
    // Main FSM
    //==========================================================================
    wire [2:0] current_screen; // Now represents Education states OR Tutorial states
    wire sort_engine_next, sort_engine_prev, sort_engine_reset;
    wire is_sorted_flag, is_at_start_flag;
    wire global_reset;
    
    // --- ADDED: Tutorial Control Signals from FSM ---
    wire tut_inc_val, tut_dec_val, tut_move_cursor_r, tut_move_cursor_l;
    
    // --- Tutorial Sort Control Signals ---
    wire tut_sort_compare_left, tut_sort_compare_right;
    wire tut_sort_swap, tut_sort_keep, tut_sort_reset;
    
    // --- Tutorial Sort Engine Outputs ---
    wire [2:0] tut_sort_array_0, tut_sort_array_1, tut_sort_array_2;
    wire [2:0] tut_sort_array_3, tut_sort_array_4, tut_sort_array_5;
    wire [2:0] tut_sort_red_line_pos;
    wire [2:0] tut_sort_compare_idx1, tut_sort_compare_idx2;
    wire [2:0] tut_sort_swap_idx1, tut_sort_swap_idx2;
    wire [2:0] tut_sort_hearts_remaining;
    wire tut_sort_is_victory, tut_sort_is_game_over, tut_sort_show_mistake;
    
    assign global_reset = !system_enable;
    
    Main_FSM main_fsm(
        .clk_100mhz(clk),
        .reset(global_reset),
        .tutorial_mode_active(tutorial_mode_active),
        .btnC_pulse(btnC_pulse),
        .btnL_pulse(btnL_pulse),
        .btnR_pulse(btnR_pulse),
        .btnU_pulse(btnU_pulse),
        .btnD_pulse(btnD_pulse),
        .sort_engine_is_sorted_flag(is_sorted_flag),
        .sort_engine_is_at_start_flag(is_at_start_flag),
        .current_screen(current_screen),
        .sort_engine_next(sort_engine_next),
        .sort_engine_prev(sort_engine_prev),
        .sort_engine_reset(sort_engine_reset),
        .tut_inc_val(tut_inc_val),
        .tut_dec_val(tut_dec_val),
        .tut_move_cursor_r(tut_move_cursor_r),
        .tut_move_cursor_l(tut_move_cursor_l),
        // Tutorial Sort Outputs
        .tut_sort_compare_left(tut_sort_compare_left),
        .tut_sort_compare_right(tut_sort_compare_right),
        .tut_sort_swap(tut_sort_swap),
        .tut_sort_keep(tut_sort_keep),
        .tut_sort_reset(tut_sort_reset),
        .tut_sort_is_victory(tut_sort_is_victory),
        .tut_sort_is_game_over(tut_sort_is_game_over)
    );
    
    //==========================================================================
    // Sort Engine
    //==========================================================================
    wire [2:0] current_array_0, current_array_1, current_array_2;
    wire [2:0] current_array_3, current_array_4, current_array_5;
    wire [2:0] red_line_pos;
    wire [2:0] compare_idx1, compare_idx2;
    wire [2:0] swap_idx1, swap_idx2;
    
    Sort_Engine sort_engine(
        .clk_100mhz(clk),
        .reset(global_reset || sort_engine_reset),
        .next_step_pulse(sort_engine_next),
        .prev_step_pulse(sort_engine_prev),
        .current_array_0(current_array_0),
        .current_array_1(current_array_1),
        .current_array_2(current_array_2),
        .current_array_3(current_array_3),
        .current_array_4(current_array_4),
        .current_array_5(current_array_5),
        .red_line_pos(red_line_pos),
        .compare_idx1(compare_idx1),
        .compare_idx2(compare_idx2),
        .swap_idx1(swap_idx1),
        .swap_idx2(swap_idx2),
        .is_sorted_flag(is_sorted_flag),
        .is_at_start_flag(is_at_start_flag)
    );
    
    
    //==========================================================================
    // Tutorial Input Engine <-- NEW MODULE INSTANTIATION
    //==========================================================================
        wire [2:0] tut_array_0, tut_array_1, tut_array_2;
        wire [2:0] tut_array_3, tut_array_4, tut_array_5;
        wire [2:0] cursor_pos;
    
        Tutorial_Input_Engine tut_engine (
            .clk_100mhz(clk),
            .reset(global_reset), // Reset when system disabled
            .tutorial_mode_active(tutorial_mode_active),
            .inc_val_pulse(tut_inc_val),
            .dec_val_pulse(tut_dec_val),
            .move_r_pulse(tut_move_cursor_r),
            .move_l_pulse(tut_move_cursor_l),
            .tut_array_0(tut_array_0), .tut_array_1(tut_array_1), .tut_array_2(tut_array_2),
            .tut_array_3(tut_array_3), .tut_array_4(tut_array_4), .tut_array_5(tut_array_5),
            .cursor_pos(cursor_pos)
        );
        
        //==========================================================================
        // Tutorial Sort Engine
        //==========================================================================
        Tutorial_Sort_Engine tutorial_sort_engine(
            .clk_100mhz(clk),
            .reset(tut_sort_reset),
            
            // User inputs from Main_FSM
            .compare_left_pulse(tut_sort_compare_left),
            .compare_right_pulse(tut_sort_compare_right),
            .swap_pulse(tut_sort_swap),
            .keep_pulse(tut_sort_keep),
            
            // Initial array from Tutorial_Input_Engine
            .input_array_0(tut_array_0),
            .input_array_1(tut_array_1),
            .input_array_2(tut_array_2),
            .input_array_3(tut_array_3),
            .input_array_4(tut_array_4),
            .input_array_5(tut_array_5),
            
            // Current array state (for rendering)
            .current_array_0(tut_sort_array_0),
            .current_array_1(tut_sort_array_1),
            .current_array_2(tut_sort_array_2),
            .current_array_3(tut_sort_array_3),
            .current_array_4(tut_sort_array_4),
            .current_array_5(tut_sort_array_5),
            
            // Visual feedback
            .red_line_pos(tut_sort_red_line_pos),
            .compare_idx1(tut_sort_compare_idx1),
            .compare_idx2(tut_sort_compare_idx2),
            .swap_idx1(tut_sort_swap_idx1),
            .swap_idx2(tut_sort_swap_idx2),
            
            // State flags
            .hearts_remaining(tut_sort_hearts_remaining),
            .is_victory(tut_sort_is_victory),
            .is_game_over(tut_sort_is_game_over),
            .show_mistake(tut_sort_show_mistake)
        );
        
        
    
    //==========================================================================
    // OLED Renderer
    //==========================================================================
    wire fb_wr_en;
    wire [12:0] fb_wr_addr;
    wire [15:0] fb_wr_data;
    
    Oled_Renderer renderer(
        .clk_100mhz(clk),
        .ce_30hz(ce_30hz),
        .ce_2hz(ce_2hz),
        .system_enable(system_enable),
        .current_screen(current_screen),
        // Display timing signals (NEW - prevents tearing)
        .frame_begin(frame_begin),
        .sending_pixels(sending_pixels),
        .current_array_0(current_array_0),
        .current_array_1(current_array_1),
        .current_array_2(current_array_2),
        .current_array_3(current_array_3),
        .current_array_4(current_array_4),
        .current_array_5(current_array_5),
        .red_line_pos(red_line_pos),
        .compare_idx1(compare_idx1),
        .compare_idx2(compare_idx2),
        .swap_idx1(swap_idx1),
        .swap_idx2(swap_idx2),
        .is_sorted_flag(is_sorted_flag),
        .is_at_start_flag(is_at_start_flag),
        // Tutorial Mode Inputs
        .tut_array_0(tut_array_0), .tut_array_1(tut_array_1), .tut_array_2(tut_array_2),
        .tut_array_3(tut_array_3), .tut_array_4(tut_array_4), .tut_array_5(tut_array_5),
        .cursor_pos(cursor_pos),
         // *** ADD Tutorial Sort Inputs ***
        .tut_sort_array_0(tut_sort_array_0),
        .tut_sort_array_1(tut_sort_array_1),
        .tut_sort_array_2(tut_sort_array_2),
        .tut_sort_array_3(tut_sort_array_3),
        .tut_sort_array_4(tut_sort_array_4),
        .tut_sort_array_5(tut_sort_array_5),
        .tut_red_line_pos(tut_sort_red_line_pos),
        .tut_compare_idx1(tut_sort_compare_idx1),
        .tut_compare_idx2(tut_sort_compare_idx2),
        .tut_swap_idx1(tut_sort_swap_idx1),
        .tut_swap_idx2(tut_sort_swap_idx2),
        .hearts_remaining(tut_sort_hearts_remaining),
        .show_mistake(tut_sort_show_mistake),
        .fb_wr_en(fb_wr_en),
        .fb_wr_addr(fb_wr_addr),
        .fb_wr_data(fb_wr_data)
    );
    
    //==========================================================================
    // Frame Buffer
    //==========================================================================
    wire [12:0] fb_rd_addr;
    wire [15:0] fb_rd_data;
    
    Frame_Buffer frame_buffer(
        .clk(clk),
        .wr_en(fb_wr_en),
        .wr_addr(fb_wr_addr),
        .wr_data(fb_wr_data),
        .rd_addr(fb_rd_addr),
        .rd_data(fb_rd_data)
    );
    
    //==========================================================================
    // OLED Display Driver - EXACT SAME AS YOUR WORKING PROJECT
    //==========================================================================
    wire frame_begin, sending_pixels, sample_pixel;
    wire [12:0] pixel_index;
    
    Oled_Display oled_display(
        .clk(clk_6p25mhz),          // 6.25MHz clock
        .reset(!system_enable),      // Reset when system off
        .frame_begin(frame_begin),
        .sending_pixels(sending_pixels),
        .sample_pixel(sample_pixel),
        .pixel_index(pixel_index),
        .pixel_data(fb_rd_data),
        .cs(JC[0]),      // Same mapping as your working project
        .sdin(JC[1]),
        .sclk(JC[3]),
        .d_cn(JC[4]),
        .resn(JC[5]),
        .vccen(JC[6]),
        .pmoden(JC[7])
    );
    
    assign fb_rd_addr = pixel_index;
    assign JC[2] = 1'b0;  // JC[2] is unused, tie to ground
    
    //==========================================================================
    // Seven-Segment Display for "Inst" (Insertion Sort indicator)
    //==========================================================================
        
    wire clk_1khz;
        clock_divider seg_clk_div(
            .clk(clk),
            .m(32'd50000),
            .divided_clk(clk_1khz)
        );
        
        reg [1:0] anode_select;
        
        always @(posedge clk_1khz) begin
            anode_select <= anode_select + 1;
        end
        
        assign dp = 1'b1;  // DP always off
        
        reg [6:0] seg_pattern;
        reg [3:0] an_pattern;
        
        always @(*) begin
            if (system_enable) begin
                case (anode_select)
                    2'b00: begin
                        // an[0] = rightmost = "t"
                        // Activate seg[3], seg[4], seg[5], seg[6]
                        an_pattern = 4'b1110;
                        seg_pattern[0] = 1'b1;  // OFF
                        seg_pattern[1] = 1'b1;  // OFF
                        seg_pattern[2] = 1'b1;  // OFF
                        seg_pattern[3] = 1'b0;  // ON
                        seg_pattern[4] = 1'b0;  // ON
                        seg_pattern[5] = 1'b0;  // ON
                        seg_pattern[6] = 1'b0;  // ON
                    end
                    
                    2'b01: begin
                        // an[1] = "S"
                        // Activate seg[0], seg[2], seg[3], seg[5], seg[6]
                        an_pattern = 4'b1101;
                        seg_pattern[0] = 1'b0;  // ON
                        seg_pattern[1] = 1'b1;  // OFF
                        seg_pattern[2] = 1'b0;  // ON
                        seg_pattern[3] = 1'b0;  // ON
                        seg_pattern[4] = 1'b1;  // OFF
                        seg_pattern[5] = 1'b0;  // ON
                        seg_pattern[6] = 1'b0;  // ON
                    end
                    
                    2'b10: begin
                        // an[2] = "n"
                        // Activate seg[2], seg[4], seg[6]
                        an_pattern = 4'b1011;
                        seg_pattern[0] = 1'b1;  // OFF
                        seg_pattern[1] = 1'b1;  // OFF
                        seg_pattern[2] = 1'b0;  // ON
                        seg_pattern[3] = 1'b1;  // OFF
                        seg_pattern[4] = 1'b0;  // ON
                        seg_pattern[5] = 1'b1;  // OFF
                        seg_pattern[6] = 1'b0;  // ON
                    end
                    
                    2'b11: begin
                        // an[3] = leftmost = "I"
                        // Activate seg[4], seg[5]
                        an_pattern = 4'b0111;
                        seg_pattern[0] = 1'b1;  // OFF
                        seg_pattern[1] = 1'b1;  // OFF
                        seg_pattern[2] = 1'b1;  // OFF
                        seg_pattern[3] = 1'b1;  // OFF
                        seg_pattern[4] = 1'b0;  // ON
                        seg_pattern[5] = 1'b0;  // ON
                        seg_pattern[6] = 1'b1;  // OFF
                    end
                    
                    default: begin
                        an_pattern = 4'b1111;
                        seg_pattern = 7'b1111111;
                    end
                endcase
            end else begin
                an_pattern = 4'b1111;
                seg_pattern = 7'b1111111;
            end
        end
        
        assign seg = seg_pattern;
        assign an = an_pattern;
    

endmodule

