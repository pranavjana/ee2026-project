`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Unified Sorting Visualizer Top Module
// Integrates Bubble Sort and Merge Sort Visualizations
//
// Switch Configuration:
//   - SW15: Merge Sort Demo
//   - SW15 + SW10: Merge Sort Tutorial
//   - SW12: Bubble Sort Demo
//   - SW12 + SW10: Bubble Sort Tutorial
//
// Hardware:
//   - Basys 3 FPGA Board
//   - OLED Display (PMOD connector JC)
//   - 100 MHz system clock
//////////////////////////////////////////////////////////////////////////////////

module sorting_visualizer_top(
    input wire clk,              // 100 MHz clock
    input wire btnC,             // Center button - Reset
    input wire btnU,             // Up button - Start/Run/Navigate
    input wire btnL,             // Left button - Navigate
    input wire btnR,             // Right button - Navigate
    input wire btnD,             // Down button - Pause/Resume/Navigate
    input wire [15:0] sw,        // Switches
    output wire [15:0] led,      // LEDs
    output wire [6:0] seg,       // 7-segment display segments
    output wire [3:0] an,        // 7-segment display anodes
    output wire dp,              // Decimal point
    output wire [7:0] JC         // OLED PMOD connector
);

    //==========================================================================
    // Algorithm Selection and Mode Control
    //==========================================================================
    // Check for invalid combination (both SW15 and SW12 ON)
    wire invalid_combination = sw[15] && sw[12];

    // Only activate if no conflict
    wire merge_sort_active = sw[15] && !sw[12];     // SW15 ON, SW12 OFF
    wire bubble_sort_active = sw[12] && !sw[15];    // SW12 ON, SW15 OFF

    // Tutorial mode flags
    wire merge_tutorial_mode = merge_sort_active && sw[10];   // SW15 + SW10 (no SW12)
    wire bubble_tutorial_mode = bubble_sort_active && sw[10]; // SW12 + SW10 (no SW15)

    // Educational mode (demo) flags
    wire merge_demo_mode = merge_sort_active && !sw[10];      // SW15 only
    wire bubble_demo_mode = bubble_sort_active && !sw[10];    // SW12 only

    // Reset signals for algorithm switching
    // Reset merge sort when bubble sort becomes active or invalid combination
    wire reset_merge_sort = bubble_sort_active || invalid_combination;
    // Reset bubble sort when merge sort becomes active or invalid combination
    wire reset_bubble_sort = merge_sort_active || invalid_combination;

    //==========================================================================
    // Clock Generation
    //==========================================================================
    wire clk_6p25MHz;
    wire clk_1hz_pulse;
    reg [15:0] clk_counter_6p25MHz = 0;
    reg [20:0] clk_counter_movement = 0;
    reg clk_6p25MHz_reg = 0;
    reg clk_movement = 0;

    // 6.25 MHz clock for OLED (100MHz / 8 = 12.5MHz, toggle = 6.25MHz)
    always @(posedge clk) begin
        clk_counter_6p25MHz <= clk_counter_6p25MHz + 1;
        if (clk_counter_6p25MHz >= 16'd7) begin
            clk_counter_6p25MHz <= 0;
            clk_6p25MHz_reg <= ~clk_6p25MHz_reg;
        end
    end
    assign clk_6p25MHz = clk_6p25MHz_reg;

    // ~45Hz movement clock for animations
    always @(posedge clk) begin
        clk_counter_movement <= clk_counter_movement + 1;
        if (clk_counter_movement >= 21'd1111111) begin
            clk_counter_movement <= 0;
            clk_movement <= ~clk_movement;
        end
    end

    //==========================================================================
    // Button Synchronization and Edge Detection
    //==========================================================================
    reg [2:0] btnU_sync = 3'b000;
    reg [2:0] btnD_sync = 3'b000;
    reg [2:0] btnC_sync = 3'b000;
    reg [2:0] btnL_sync = 3'b000;
    reg [2:0] btnR_sync = 3'b000;

    always @(posedge clk) begin
        btnU_sync <= {btnU_sync[1:0], btnU};
        btnD_sync <= {btnD_sync[1:0], btnD};
        btnC_sync <= {btnC_sync[1:0], btnC};
        btnL_sync <= {btnL_sync[1:0], btnL};
        btnR_sync <= {btnR_sync[1:0], btnR};
    end

    // Edge detection
    wire btn_start = btnU_sync[2] && !btnU_sync[1];
    wire btn_pause = btnD_sync[2] && !btnD_sync[1];
    wire btn_center = btnC_sync[2] && !btnC_sync[1];
    wire btn_left = btnL_sync[2] && !btnL_sync[1];
    wire btn_right = btnR_sync[2] && !btnR_sync[1];

    // Reset signals - combine button press with algorithm switching
    // Merge sort resets when: button pressed (not in tutorial) OR bubble sort activated
    wire btn_reset_merge = (btn_center && !merge_tutorial_mode) || reset_merge_sort;
    // Bubble sort resets when: button pressed OR merge sort activated
    wire btn_reset_bubble = btn_center || reset_bubble_sort;

    //==========================================================================
    // OLED Display Interface (Shared)
    //==========================================================================
    wire frame_begin, sending_pixels, sample_pixel;
    wire [12:0] pixel_index;
    wire [15:0] pixel_data_final;

    // OLED display reset when invalid combination or no algorithm active
    wire oled_reset = invalid_combination || (!merge_sort_active && !bubble_sort_active);

    Oled_Display oled_display (
        .clk(clk_6p25MHz),
        .reset(oled_reset),
        .frame_begin(frame_begin),
        .sending_pixels(sending_pixels),
        .sample_pixel(sample_pixel),
        .pixel_index(pixel_index),
        .pixel_data(pixel_data_final),
        .cs(JC[0]),
        .sdin(JC[1]),
        .sclk(JC[3]),
        .d_cn(JC[4]),
        .resn(JC[5]),
        .vccen(JC[6]),
        .pmoden(JC[7])
    );
    assign JC[2] = 0; // Unused pin

    //==========================================================================
    // Merge Sort Visualization System
    //==========================================================================
    wire [17:0] merge_array_data_flat;
    wire [17:0] merge_answer_data_flat;
    wire [35:0] merge_array_positions_y_flat;
    wire [41:0] merge_array_positions_x_flat;
    wire [17:0] merge_array_colors_flat;
    wire [17:0] merge_answer_colors_flat;
    wire [4:0] merge_separator_visible;
    wire [14:0] merge_separator_colors_flat;
    wire [2:0] merge_cursor_pos;
    wire merge_practice_mode_active;
    wire [2:0] merge_sort_current_state;
    wire [2:0] merge_divide_step_status;
    wire [2:0] merge_merge_step_status;
    wire merge_sorting_active, merge_animation_busy, merge_sort_complete;
    wire merge_all_positions_reached;
    wire merge_pulse_state_signal;
    wire [5:0] merge_region_active_signal;
    wire [5:0] merge_hint_timer_signal;
    wire [4:0] merge_hint_separators_signal;
    wire [15:0] merge_pixel_data;

    // Merge Sort Controller
    merge_sort_controller merge_controller (
        .clk(clk),
        .clk_6p25MHz(clk_6p25MHz),
        .clk_movement(clk_movement),
        .reset(btn_reset_merge),
        .btn_start(btn_start),
        .btn_pause(btn_pause),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_center(btn_center),
        .demo_active(merge_sort_active),
        .educational_mode(merge_demo_mode),
        .tutorial_mode(merge_tutorial_mode),
        .line_switches(sw[4:0]),
        .array_data_flat(merge_array_data_flat),
        .answer_data_flat(merge_answer_data_flat),
        .array_positions_y_flat(merge_array_positions_y_flat),
        .array_positions_x_flat(merge_array_positions_x_flat),
        .array_colors_flat(merge_array_colors_flat),
        .answer_colors_flat(merge_answer_colors_flat),
        .separator_visible(merge_separator_visible),
        .separator_colors_flat(merge_separator_colors_flat),
        .cursor_pos_out(merge_cursor_pos),
        .practice_mode_active(merge_practice_mode_active),
        .current_state(merge_sort_current_state),
        .divide_step_out(merge_divide_step_status),
        .merge_step_out(merge_merge_step_status),
        .sorting_active(merge_sorting_active),
        .animation_busy(merge_animation_busy),
        .sort_complete(merge_sort_complete),
        .all_positions_reached(merge_all_positions_reached),
        .pulse_state_out(merge_pulse_state_signal),
        .merge_region_active_flat(merge_region_active_signal),
        .hint_timer_out(merge_hint_timer_signal),
        .hint_separators_flat(merge_hint_separators_signal)
    );

    // Merge Sort Display Engine
    merge_sort_display merge_display_engine (
        .clk_6p25MHz(clk_6p25MHz),
        .reset(btn_reset_merge),
        .pixel_index(pixel_index),
        .pixel_data(merge_pixel_data),
        .array_data_flat(merge_array_data_flat),
        .answer_data_flat(merge_answer_data_flat),
        .array_positions_y_flat(merge_array_positions_y_flat),
        .array_positions_x_flat(merge_array_positions_x_flat),
        .array_colors_flat(merge_array_colors_flat),
        .answer_colors_flat(merge_answer_colors_flat),
        .separator_visible(merge_separator_visible),
        .separator_colors_flat(merge_separator_colors_flat),
        .cursor_pos(merge_cursor_pos),
        .practice_mode_active(merge_practice_mode_active),
        .current_state(merge_sort_current_state),
        .divide_step(merge_divide_step_status),
        .merge_step(merge_merge_step_status),
        .sorting_active(merge_sorting_active),
        .demo_active(merge_sort_active),
        .pulse_state(merge_pulse_state_signal),
        .merge_region_active(merge_region_active_signal),
        .hint_timer(merge_hint_timer_signal),
        .hint_separators(merge_hint_separators_signal)
    );

    //==========================================================================
    // Bubble Sort Visualization System
    //==========================================================================
    // Bubble sort FSM signals
    wire [7:0] bubble_array0, bubble_array1, bubble_array2;
    wire [7:0] bubble_array3, bubble_array4, bubble_array5;
    wire [2:0] bubble_compare_idx1, bubble_compare_idx2;
    wire bubble_swap_flag, bubble_sorting, bubble_done;
    wire [5:0] bubble_anim_progress;
    wire [1:0] bubble_anim_phase;
    wire [15:0] bubble_pixel_data_auto, bubble_pixel_data_tutorial;
    wire [15:0] bubble_pixel_data;

    // Tutorial mode signals for bubble sort
    wire [7:0] bubble_tutorial_array0, bubble_tutorial_array1, bubble_tutorial_array2;
    wire [7:0] bubble_tutorial_array3, bubble_tutorial_array4, bubble_tutorial_array5;
    wire [2:0] bubble_tutorial_cursor_pos, bubble_tutorial_compare_pos;
    wire [4:0] bubble_tutorial_anim_frame;
    wire [6:0] bubble_tutorial_progress;
    wire bubble_tutorial_feedback_correct, bubble_tutorial_feedback_incorrect;
    wire bubble_tutorial_is_sorted;
    wire [3:0] bubble_tutorial_state;

    // Pause state for bubble sort auto mode
    reg bubble_paused;
    always @(posedge clk) begin
        if (btn_reset_bubble)
            bubble_paused <= 0;
        else if (btn_pause && !bubble_tutorial_mode)
            bubble_paused <= ~bubble_paused;
    end

    // Frame tick generator for bubble sort tutorial animations (~60 Hz)
    reg [20:0] bubble_frame_counter;
    reg bubble_frame_tick;
    always @(posedge clk) begin
        if (bubble_frame_counter >= 21'd1666666) begin
            bubble_frame_counter <= 0;
            bubble_frame_tick <= 1;
        end else begin
            bubble_frame_counter <= bubble_frame_counter + 1;
            bubble_frame_tick <= 0;
        end
    end

    // Button debouncing for bubble sort
    wire bubble_btn_l_edge, bubble_btn_r_edge, bubble_btn_u_edge;
    wire bubble_btn_d_edge, bubble_btn_c_edge;

    button_debounce_5btn bubble_btn_debouncer (
        .clk(clk),
        .reset(1'b0),
        .btnL(btnL),
        .btnR(btnR),
        .btnU(btnU),
        .btnD(btnD),
        .btnC(btnC),
        .btn_l_edge(bubble_btn_l_edge),
        .btn_r_edge(bubble_btn_r_edge),
        .btn_u_edge(bubble_btn_u_edge),
        .btn_d_edge(bubble_btn_d_edge),
        .btn_c_edge(bubble_btn_c_edge)
    );

    // Clock divider for bubble sort (1Hz pulse)
    wire bubble_clk_1hz_pulse;
    wire bubble_clk_1hz_pulse_gated;
    clock_divider bubble_clk_div (
        .clk_100mhz(clk),
        .rst(btn_reset_bubble),
        .clk_6p25mhz(),  // Not used, we use shared clk_6p25MHz
        .clk_1hz_pulse(bubble_clk_1hz_pulse)
    );
    // Gate step pulse during animation to prevent state machine from advancing during swap
    assign bubble_clk_1hz_pulse_gated = bubble_clk_1hz_pulse && !bubble_paused && !bubble_swap_flag;

    // Bubble Sort FSM (auto mode)
    bubble_sort_fsm bubble_fsm (
        .clk(clk),
        .rst(btn_reset_bubble),
        .start(bubble_btn_u_edge),
        .step_pulse(bubble_clk_1hz_pulse_gated),
        .pattern_sel(sw[1:0]),
        .array0(bubble_array0),
        .array1(bubble_array1),
        .array2(bubble_array2),
        .array3(bubble_array3),
        .array4(bubble_array4),
        .array5(bubble_array5),
        .compare_idx1(bubble_compare_idx1),
        .compare_idx2(bubble_compare_idx2),
        .swap_flag(bubble_swap_flag),
        .anim_progress(bubble_anim_progress),
        .anim_phase(bubble_anim_phase),
        .sorting(bubble_sorting),
        .done(bubble_done)
    );

    // Tutorial FSM for bubble sort
    tutorial_fsm bubble_tutorial (
        .clk(clk),
        .reset(btn_reset_bubble),
        .enable(bubble_tutorial_mode),
        .btn_l_edge(bubble_btn_l_edge),
        .btn_r_edge(bubble_btn_r_edge),
        .btn_u_edge(bubble_btn_u_edge),
        .btn_d_edge(bubble_btn_d_edge),
        .btn_c_edge(bubble_btn_c_edge),
        .frame_tick(bubble_frame_tick),
        .array0(bubble_tutorial_array0),
        .array1(bubble_tutorial_array1),
        .array2(bubble_tutorial_array2),
        .array3(bubble_tutorial_array3),
        .array4(bubble_tutorial_array4),
        .array5(bubble_tutorial_array5),
        .cursor_pos(bubble_tutorial_cursor_pos),
        .compare_pos(bubble_tutorial_compare_pos),
        .anim_frame(bubble_tutorial_anim_frame),
        .progress_percent(bubble_tutorial_progress),
        .feedback_correct(bubble_tutorial_feedback_correct),
        .feedback_incorrect(bubble_tutorial_feedback_incorrect),
        .is_sorted(bubble_tutorial_is_sorted),
        .current_state_num(bubble_tutorial_state)
    );

    // Mux between auto and tutorial mode for bubble sort
    wire [7:0] bubble_final_array0 = bubble_tutorial_mode ? bubble_tutorial_array0 : bubble_array0;
    wire [7:0] bubble_final_array1 = bubble_tutorial_mode ? bubble_tutorial_array1 : bubble_array1;
    wire [7:0] bubble_final_array2 = bubble_tutorial_mode ? bubble_tutorial_array2 : bubble_array2;
    wire [7:0] bubble_final_array3 = bubble_tutorial_mode ? bubble_tutorial_array3 : bubble_array3;
    wire [7:0] bubble_final_array4 = bubble_tutorial_mode ? bubble_tutorial_array4 : bubble_array4;
    wire [7:0] bubble_final_array5 = bubble_tutorial_mode ? bubble_tutorial_array5 : bubble_array5;
    wire [2:0] bubble_final_compare_idx1 = bubble_tutorial_mode ? bubble_tutorial_cursor_pos : bubble_compare_idx1;
    wire [2:0] bubble_final_compare_idx2 = bubble_tutorial_mode ? bubble_tutorial_compare_pos : bubble_compare_idx2;
    wire bubble_final_swap_flag = bubble_tutorial_mode ? 1'b0 : bubble_swap_flag;
    wire [5:0] bubble_final_anim_progress = bubble_tutorial_mode ? 6'b0 : bubble_anim_progress;
    wire [1:0] bubble_final_anim_phase = bubble_tutorial_mode ? 2'b0 : bubble_anim_phase;
    wire bubble_final_sorting = bubble_tutorial_mode ? (!bubble_tutorial_is_sorted) : bubble_sorting;
    wire bubble_final_done = bubble_tutorial_mode ? bubble_tutorial_is_sorted : bubble_done;

    // Pixel generators for bubble sort
    pixel_generator bubble_pix_gen_auto (
        .pixel_index(pixel_index),
        .array0(bubble_final_array0),
        .array1(bubble_final_array1),
        .array2(bubble_final_array2),
        .array3(bubble_final_array3),
        .array4(bubble_final_array4),
        .array5(bubble_final_array5),
        .compare_idx1(bubble_final_compare_idx1),
        .compare_idx2(bubble_final_compare_idx2),
        .swap_flag(bubble_final_swap_flag),
        .anim_progress(bubble_final_anim_progress),
        .anim_phase(bubble_final_anim_phase),
        .sorting(bubble_final_sorting),
        .done(bubble_final_done),
        .pixel_data(bubble_pixel_data_auto)
    );

    tutorial_pixel_generator bubble_pix_gen_tutorial (
        .pixel_index(pixel_index),
        .array0(bubble_tutorial_array0),
        .array1(bubble_tutorial_array1),
        .array2(bubble_tutorial_array2),
        .array3(bubble_tutorial_array3),
        .array4(bubble_tutorial_array4),
        .array5(bubble_tutorial_array5),
        .cursor_pos(bubble_tutorial_cursor_pos),
        .compare_pos(bubble_tutorial_compare_pos),
        .anim_frame(bubble_tutorial_anim_frame),
        .progress_percent(bubble_tutorial_progress),
        .feedback_correct(bubble_tutorial_feedback_correct),
        .feedback_incorrect(bubble_tutorial_feedback_incorrect),
        .is_sorted(bubble_tutorial_is_sorted),
        .current_state(bubble_tutorial_state),
        .pixel_data(bubble_pixel_data_tutorial)
    );

    // Multiplex bubble sort pixel data
    assign bubble_pixel_data = bubble_tutorial_mode ? bubble_pixel_data_tutorial : bubble_pixel_data_auto;

    //==========================================================================
    // Output Multiplexing
    //==========================================================================
    // OLED pixel data multiplexing
    assign pixel_data_final = merge_sort_active ? merge_pixel_data :
                              bubble_sort_active ? bubble_pixel_data :
                              16'h0000; // Black screen when no algorithm active

    // LED multiplexing
    reg [15:0] led_output;
    assign led = led_output;

    always @(*) begin
        if (invalid_combination) begin
            // Invalid combination - blink LED[15] and LED[12] as warning
            led_output = 16'h0000;
            led_output[15] = 1'b1;  // Show both switches are ON
            led_output[12] = 1'b1;
        end else if (merge_sort_active) begin
            // Merge sort LED status
            led_output[15] = merge_sort_active;
            led_output[14] = merge_sorting_active;
            led_output[13] = merge_animation_busy;
            led_output[12] = merge_sort_complete;
            led_output[11:8] = {1'b0, merge_sort_current_state};
            led_output[7:0] = 8'h00;
        end else if (bubble_sort_active) begin
            // Bubble sort LED status
            led_output = 16'h0000;
            led_output[12] = bubble_sort_active;
            led_output[0] = bubble_tutorial_mode;
        end else begin
            led_output = 16'h0000;
        end
    end

    //==========================================================================
    // Seven-Segment Display
    //==========================================================================
    reg [19:0] display_counter = 0;
    reg [1:0] digit_select = 0;

    always @(posedge clk) begin
        display_counter <= display_counter + 1;
        if (display_counter == 0) begin
            digit_select <= digit_select + 1;
        end
    end

    // Segment patterns for merge sort - displays "MErG"
    localparam SEG_M = 7'b1101010;  // "M"
    localparam SEG_E = 7'b0000110;  // "E"
    localparam SEG_R = 7'b0101111;  // "r"
    localparam SEG_G = 7'b0010000;  // "G"

    // Segment patterns for bubble sort - displays "bUbL" or "tutr"
    localparam SEG_B_LOWER = 7'b1111100;  // "b"
    localparam SEG_U_UPPER = 7'b0111110;  // "U"
    localparam SEG_L_UPPER = 7'b0111000;  // "L"
    localparam SEG_T_LOWER = 7'b1111000;  // "t"
    localparam SEG_R_LOWER = 7'b1010000;  // "r"

    // Segment patterns for error - displays "Err"
    localparam SEG_DASH = 7'b1000000;     // "-"
    localparam SEG_E_ERROR = ~7'b0000110; // "E" for error (inverted from normal E)

    reg [6:0] seg_pattern;
    reg [3:0] anode_pattern;

    always @(*) begin
        if (invalid_combination) begin
            // Display "Err-" for invalid combination
            case (digit_select)
                2'b00: begin anode_pattern = 4'b1110; seg_pattern = SEG_DASH; end      // Rightmost: "-"
                2'b01: begin anode_pattern = 4'b1101; seg_pattern = SEG_R_LOWER; end   // "r"
                2'b10: begin anode_pattern = 4'b1011; seg_pattern = SEG_R_LOWER; end   // "r"
                2'b11: begin anode_pattern = 4'b0111; seg_pattern = SEG_E_ERROR; end   // Leftmost: "E" (special pattern)
            endcase
        end else if (merge_sort_active) begin
            // Display "MErG" for merge sort
            case (digit_select)
                2'b00: begin anode_pattern = 4'b1110; seg_pattern = SEG_G; end     // Rightmost
                2'b01: begin anode_pattern = 4'b1101; seg_pattern = SEG_R; end
                2'b10: begin anode_pattern = 4'b1011; seg_pattern = SEG_E; end
                2'b11: begin anode_pattern = 4'b0111; seg_pattern = SEG_M; end     // Leftmost
            endcase
        end else if (bubble_sort_active) begin
            if (bubble_tutorial_mode) begin
                // Display "tutr" for tutorial mode
                case (digit_select)
                    2'b00: begin anode_pattern = 4'b1110; seg_pattern = SEG_R_LOWER; end   // Rightmost
                    2'b01: begin anode_pattern = 4'b1101; seg_pattern = SEG_T_LOWER; end
                    2'b10: begin anode_pattern = 4'b1011; seg_pattern = SEG_U_UPPER; end
                    2'b11: begin anode_pattern = 4'b0111; seg_pattern = SEG_T_LOWER; end   // Leftmost
                endcase
            end else begin
                // Display "bUbL" for demo mode
                case (digit_select)
                    2'b00: begin anode_pattern = 4'b1110; seg_pattern = SEG_L_UPPER; end   // Rightmost
                    2'b01: begin anode_pattern = 4'b1101; seg_pattern = SEG_B_LOWER; end
                    2'b10: begin anode_pattern = 4'b1011; seg_pattern = SEG_U_UPPER; end
                    2'b11: begin anode_pattern = 4'b0111; seg_pattern = SEG_B_LOWER; end   // Leftmost
                endcase
            end
        end else begin
            // All off when no algorithm active
            seg_pattern = 7'b1111111;
            anode_pattern = 4'b1111;
        end
    end

    // Segments are active-low, so invert the pattern
    assign seg = ~seg_pattern;
    assign an = anode_pattern;
    assign dp = 1'b1;  // Decimal point off (active-low)

endmodule
