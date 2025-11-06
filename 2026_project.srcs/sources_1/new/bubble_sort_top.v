`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Top Module for Bubble Sort Visualizer
// Integrates all components for OLED-based visualization on Basys 3
// Pranav's Bubble Sort Implementation
//
// Inputs:
//   - clk: 100 MHz system clock
//   - sw[15:0]: Switches for control
//     * sw[1:0]: Pattern selection (00=random, 01=sorted, 10=reverse, 11=custom)
//     * sw[12]: Bubble Sort active (Pranav) - displays "bUbL"
//     * sw[0]: Tutorial mode (when sw[12]=1, sw[0]=1 enables tutorial)
//   - btnU: Up button - Start/Run demo
//   - btnC: Center button - Reset
//   - btnD: Down button - Pause/Resume
//
// Outputs:
//   - JC[7:0]: OLED PMOD signals
//   - led[15:0]: Status LEDs
//   - seg[6:0]: 7-segment display segments (shows "bUbL" when sw[12] is ON)
//   - an[3:0]: 7-segment display anodes
//////////////////////////////////////////////////////////////////////////////////

module bubble_sort_top(
    input wire clk,              // 100 MHz clock
    input wire btnC,             // Center button - Reset
    input wire btnU,             // Up button - Start/Run
    input wire btnL,             // Left button (unused)
    input wire btnR,             // Right button (unused)
    input wire btnD,             // Down button - Pause/Resume
    input wire [15:0] sw,        // Switches (using sw[12] for Bubble Sort)
    output wire [15:0] led,      // LEDs
    output wire [6:0] seg,       // 7-segment display segments
    output wire [3:0] an,        // 7-segment display anodes
    output wire [7:0] JC         // OLED PMOD connector
);

    // Algorithm selection
    wire bubble_sort_active = sw[12];    // Pranav's Bubble Sort
    wire tutorial_mode = sw[12] && sw[0]; // Tutorial mode when both sw[12] and sw[0] are ON

    // Button debouncing - use 5-button module for tutorial mode
    wire btn_l_edge, btn_r_edge, btn_u_edge, btn_d_edge, btn_c_edge;

    button_debounce_5btn btn_debouncer (
        .clk(clk),
        .reset(1'b0),  // No async reset needed
        .btnL(btnL),
        .btnR(btnR),
        .btnU(btnU),
        .btnD(btnD),
        .btnC(btnC),
        .btn_l_edge(btn_l_edge),
        .btn_r_edge(btn_r_edge),
        .btn_u_edge(btn_u_edge),
        .btn_d_edge(btn_d_edge),
        .btn_c_edge(btn_c_edge)
    );

    // Legacy button signals for compatibility with auto-sort mode
    wire btn_start_edge = btn_u_edge;
    wire btn_reset_edge = btn_c_edge;
    wire btn_pause_edge = btn_d_edge;

    // Pause/Resume state (for auto-sort mode only)
    reg paused;

    // Pause/Resume control
    always @(posedge clk) begin
        if (btn_reset_edge)
            paused <= 0;
        else if (btn_pause_edge && !tutorial_mode)
            paused <= ~paused;
    end

    // Frame tick generator for animations (~60 Hz)
    // Using 100MHz / 1,666,667 ≈ 60 Hz
    reg [20:0] frame_counter;
    reg frame_tick;

    always @(posedge clk) begin
        if (frame_counter >= 21'd1666666) begin
            frame_counter <= 0;
            frame_tick <= 1;
        end else begin
            frame_counter <= frame_counter + 1;
            frame_tick <= 0;
        end
    end

    // Clock signals
    wire clk_oled;
    wire clk_1hz_pulse;
    wire clk_1hz_pulse_gated;

    // Clock divider instantiation
    clock_divider clk_div (
        .clk_100mhz(clk),
        .rst(btn_reset_edge),
        .clk_6p25mhz(clk_oled),
        .clk_1hz_pulse(clk_1hz_pulse)
    );

    // Gate the step pulse when paused
    assign clk_1hz_pulse_gated = clk_1hz_pulse && !paused;

    // Auto-sort mode signals
    wire [7:0] auto_array0, auto_array1, auto_array2, auto_array3, auto_array4, auto_array5;
    wire [2:0] auto_compare_idx1;
    wire [2:0] auto_compare_idx2;
    wire auto_swap_flag;
    wire [4:0] auto_anim_progress;
    wire [1:0] auto_anim_phase;
    wire auto_sorting;
    wire auto_done;

    // Bubble sort FSM instantiation (auto-sort mode)
    bubble_sort_fsm sort_fsm (
        .clk(clk),
        .rst(btn_reset_edge),
        .start(btn_start_edge),
        .step_pulse(clk_1hz_pulse_gated),  // Use gated pulse for pause
        .pattern_sel(sw[1:0]),
        .array0(auto_array0),
        .array1(auto_array1),
        .array2(auto_array2),
        .array3(auto_array3),
        .array4(auto_array4),
        .array5(auto_array5),
        .compare_idx1(auto_compare_idx1),
        .compare_idx2(auto_compare_idx2),
        .swap_flag(auto_swap_flag),
        .anim_progress(auto_anim_progress),
        .anim_phase(auto_anim_phase),
        .sorting(auto_sorting),
        .done(auto_done)
    );

    // Tutorial mode signals
    wire [7:0] tutorial_array0, tutorial_array1, tutorial_array2;
    wire [7:0] tutorial_array3, tutorial_array4, tutorial_array5;
    wire [2:0] tutorial_cursor_pos;
    wire [2:0] tutorial_compare_pos;
    wire [4:0] tutorial_anim_frame;
    wire [6:0] tutorial_progress;
    wire tutorial_feedback_correct;
    wire tutorial_feedback_incorrect;
    wire tutorial_is_sorted;
    wire [3:0] tutorial_state;

    // Tutorial FSM instantiation
    tutorial_fsm tutorial (
        .clk(clk),
        .reset(btn_reset_edge),
        .enable(tutorial_mode),
        .btn_l_edge(btn_l_edge),
        .btn_r_edge(btn_r_edge),
        .btn_u_edge(btn_u_edge),
        .btn_d_edge(btn_d_edge),
        .btn_c_edge(btn_c_edge),
        .frame_tick(frame_tick),
        .array0(tutorial_array0),
        .array1(tutorial_array1),
        .array2(tutorial_array2),
        .array3(tutorial_array3),
        .array4(tutorial_array4),
        .array5(tutorial_array5),
        .cursor_pos(tutorial_cursor_pos),
        .compare_pos(tutorial_compare_pos),
        .anim_frame(tutorial_anim_frame),
        .progress_percent(tutorial_progress),
        .feedback_correct(tutorial_feedback_correct),
        .feedback_incorrect(tutorial_feedback_incorrect),
        .is_sorted(tutorial_is_sorted),
        .current_state_num(tutorial_state)
    );

    // Mux between auto-sort and tutorial mode
    wire [7:0] array0 = tutorial_mode ? tutorial_array0 : auto_array0;
    wire [7:0] array1 = tutorial_mode ? tutorial_array1 : auto_array1;
    wire [7:0] array2 = tutorial_mode ? tutorial_array2 : auto_array2;
    wire [7:0] array3 = tutorial_mode ? tutorial_array3 : auto_array3;
    wire [7:0] array4 = tutorial_mode ? tutorial_array4 : auto_array4;
    wire [7:0] array5 = tutorial_mode ? tutorial_array5 : auto_array5;
    wire [2:0] compare_idx1 = tutorial_mode ? tutorial_cursor_pos : auto_compare_idx1;
    wire [2:0] compare_idx2 = tutorial_mode ? tutorial_compare_pos : auto_compare_idx2;
    wire swap_flag = tutorial_mode ? 1'b0 : auto_swap_flag;
    wire [4:0] anim_progress = tutorial_mode ? 5'b0 : auto_anim_progress;
    wire [1:0] anim_phase = tutorial_mode ? 2'b0 : auto_anim_phase;
    wire sorting = tutorial_mode ? (!tutorial_is_sorted) : auto_sorting;
    wire done = tutorial_mode ? tutorial_is_sorted : auto_done;

    // OLED display signals
    wire frame_begin;
    wire sending_pixels;
    wire sample_pixel;
    wire [13:0] pixel_index;
    wire [15:0] auto_pixel_data;
    wire [15:0] tutorial_pixel_data;
    wire [15:0] pixel_data;
    wire [15:0] pixel_data_gated;

    // OLED Display instantiation
    Oled_Display #(
        .ClkFreq(6250000)
    ) oled (
        .clk(clk_oled),
        .reset(btn_reset_edge || !bubble_sort_active),  // Reset OLED when sw[12] is OFF
        .frame_begin(frame_begin),
        .sending_pixels(sending_pixels),
        .sample_pixel(sample_pixel),
        .pixel_index(pixel_index),
        .pixel_data(pixel_data_gated),
        .cs(JC[0]),
        .sdin(JC[1]),
        .sclk(JC[3]),
        .d_cn(JC[4]),
        .resn(JC[5]),
        .vccen(JC[6]),
        .pmoden(JC[7])
    );

    // Auto-sort pixel generator instantiation
    pixel_generator auto_pix_gen (
        .pixel_index(pixel_index),
        .array0(array0),
        .array1(array1),
        .array2(array2),
        .array3(array3),
        .array4(array4),
        .array5(array5),
        .compare_idx1(compare_idx1),
        .compare_idx2(compare_idx2),
        .swap_flag(swap_flag),
        .anim_progress(anim_progress),
        .anim_phase(anim_phase),
        .sorting(sorting),
        .done(done),
        .pixel_data(auto_pixel_data)
    );

    // Tutorial pixel generator instantiation
    tutorial_pixel_generator tutorial_pix_gen (
        .pixel_index(pixel_index),
        .array0(tutorial_array0),
        .array1(tutorial_array1),
        .array2(tutorial_array2),
        .array3(tutorial_array3),
        .array4(tutorial_array4),
        .array5(tutorial_array5),
        .cursor_pos(tutorial_cursor_pos),
        .compare_pos(tutorial_compare_pos),
        .anim_frame(tutorial_anim_frame),
        .progress_percent(tutorial_progress),
        .feedback_correct(tutorial_feedback_correct),
        .feedback_incorrect(tutorial_feedback_incorrect),
        .is_sorted(tutorial_is_sorted),
        .current_state(tutorial_state),
        .pixel_data(tutorial_pixel_data)
    );

    // Mux pixel data based on mode
    assign pixel_data = tutorial_mode ? tutorial_pixel_data : auto_pixel_data;

    // Gate pixel data - only show when sw[12] is ON
    assign pixel_data_gated = bubble_sort_active ? pixel_data : 16'h0000;

    // LED indicators
    reg [15:0] led_reg;
    assign led = led_reg;

    always @(*) begin
        led_reg = 16'h0000;                // Turn off all LEDs by default
        led_reg[12] = bubble_sort_active;  // LED[12] ON when sw[12] is ON
        led_reg[0] = tutorial_mode;        // LED[0] ON when tutorial mode active
    end

    // 7-segment display controller
    reg [7:0] display_char [0:3];  // 4 characters to display
    wire [1:0] digit_select;
    reg [19:0] refresh_counter;

    // Refresh counter for 7-segment multiplexing
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
    end

    assign digit_select = refresh_counter[19:18];

    // Display characters based on mode and state
    always @(*) begin
        if (tutorial_mode) begin
            // Display "tutr" when in tutorial mode
            display_char[3] = 8'h78;  // 't' = 0b01111000 (leftmost)
            display_char[2] = 8'h3e;  // 'u' = 0b00111110
            display_char[1] = 8'h78;  // 't' = 0b01111000
            display_char[0] = 8'h50;  // 'r' = 0b01010000 (rightmost)
        end else if (bubble_sort_active) begin
            // Display "bUbL" when sw[12] is ON (reversed because rightmost digit is [0])
            display_char[3] = 8'h7c;  // 'b' = 0b01111100 (leftmost)
            display_char[2] = 8'h3e;  // 'U' = 0b00111110
            display_char[1] = 8'h7c;  // 'b' = 0b01111100
            display_char[0] = 8'h38;  // 'L' = 0b00111000 (rightmost)
        end else if (done) begin
            // Show "done" pattern
            display_char[3] = 8'h5e;  // 'd'
            display_char[2] = 8'h3f;  // 'O'
            display_char[1] = 8'h37;  // 'n'
            display_char[0] = 8'h79;  // 'E'
        end else if (sorting) begin
            // Show sorting status
            display_char[3] = 8'h6d;  // 'S'
            display_char[2] = 8'h3f;  // 'O'
            display_char[1] = 8'h77;  // 'r'
            display_char[0] = 8'h78;  // 't'
        end else begin
            // Show blank or idle state
            display_char[3] = 8'h00;  // blank
            display_char[2] = 8'h00;  // blank
            display_char[1] = 8'h00;  // blank
            display_char[0] = 8'h00;  // blank
        end
    end

    // Current character for display
    reg [7:0] current_char;
    always @(*) begin
        case (digit_select)
            2'b00: current_char = display_char[0];
            2'b01: current_char = display_char[1];
            2'b10: current_char = display_char[2];
            2'b11: current_char = display_char[3];
        endcase
    end

    // Anode control (active low)
    assign an = ~(4'b0001 << digit_select);

    // Direct segment output (active low)
    // current_char contains the segment pattern (GFEDCBA format)
    // seg output is (GFEDCBA format)
    assign seg = ~current_char[6:0];

    // JC[2] is not used in standard OLED configuration
    assign JC[2] = 1'b0;

endmodule
