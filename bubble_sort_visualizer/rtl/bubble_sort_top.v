`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Top Module for Bubble Sort Visualizer
// Integrates all components for OLED-based visualization on Basys 3
//
// Inputs:
//   - clk: 100 MHz system clock
//   - sw[3:0]: Switches for control
//     * sw[1:0]: Pattern selection (00=random, 01=sorted, 10=reverse, 11=custom)
//     * sw[2]: Not used (reserved)
//     * sw[3]: Not used (reserved)
//   - btnC: Center button - Start sorting
//   - btnU: Up button - Reset
//
// Outputs:
//   - JC[7:0]: OLED PMOD signals
//   - led[15:0]: Status LEDs
//   - seg[6:0]: 7-segment display segments
//   - an[3:0]: 7-segment display anodes
//////////////////////////////////////////////////////////////////////////////////

module bubble_sort_top(
    input wire clk,              // 100 MHz clock
    input wire btnC,             // Center button - Start
    input wire btnU,             // Up button - Reset
    input wire btnL,             // Left button (unused)
    input wire btnR,             // Right button (unused)
    input wire btnD,             // Down button (unused)
    input wire [3:0] sw,         // Switches
    output wire [15:0] led,      // LEDs
    output wire [6:0] seg,       // 7-segment display segments
    output wire [3:0] an,        // 7-segment display anodes
    output wire [7:0] JC         // OLED PMOD connector
);

    // Button debouncing and edge detection
    reg [19:0] btn_counter_start;
    reg [19:0] btn_counter_reset;
    reg btn_start_sync, btn_start_prev;
    reg btn_reset_sync, btn_reset_prev;
    wire btn_start_edge;
    wire btn_reset_edge;

    // Debounce start button
    always @(posedge clk) begin
        if (btnC) begin
            if (btn_counter_start < 20'd999999)
                btn_counter_start <= btn_counter_start + 1;
            else
                btn_start_sync <= 1;
        end else begin
            btn_counter_start <= 0;
            btn_start_sync <= 0;
        end
    end

    // Detect rising edge of start button
    always @(posedge clk) begin
        btn_start_prev <= btn_start_sync;
    end
    assign btn_start_edge = btn_start_sync && !btn_start_prev;

    // Debounce reset button
    always @(posedge clk) begin
        if (btnU) begin
            if (btn_counter_reset < 20'd999999)
                btn_counter_reset <= btn_counter_reset + 1;
            else
                btn_reset_sync <= 1;
        end else begin
            btn_counter_reset <= 0;
            btn_reset_sync <= 0;
        end
    end

    // Detect rising edge of reset button
    always @(posedge clk) begin
        btn_reset_prev <= btn_reset_sync;
    end
    assign btn_reset_edge = btn_reset_sync && !btn_reset_prev;

    // Clock signals
    wire clk_oled;
    wire clk_1hz_pulse;

    // Clock divider instantiation
    clock_divider clk_div (
        .clk_100mhz(clk),
        .rst(btn_reset_edge),
        .clk_6p25mhz(clk_oled),
        .clk_1hz_pulse(clk_1hz_pulse)
    );

    // Bubble sort signals
    wire [7:0] array [0:5];
    wire [2:0] compare_idx1;
    wire [2:0] compare_idx2;
    wire swap_flag;
    wire sorting;
    wire done;

    // Bubble sort FSM instantiation
    bubble_sort_fsm sort_fsm (
        .clk(clk),
        .rst(btn_reset_edge),
        .start(btn_start_edge),
        .step_pulse(clk_1hz_pulse),
        .pattern_sel(sw[1:0]),
        .array(array),
        .compare_idx1(compare_idx1),
        .compare_idx2(compare_idx2),
        .swap_flag(swap_flag),
        .sorting(sorting),
        .done(done)
    );

    // OLED display signals
    wire frame_begin;
    wire sending_pixels;
    wire sample_pixel;
    wire [13:0] pixel_index;
    wire [15:0] pixel_data;

    // OLED Display instantiation
    Oled_Display #(
        .ClkFreq(6250000)
    ) oled (
        .clk(clk_oled),
        .reset(btn_reset_edge),
        .frame_begin(frame_begin),
        .sending_pixels(sending_pixels),
        .sample_pixel(sample_pixel),
        .pixel_index(pixel_index),
        .pixel_data(pixel_data),
        .cs(JC[0]),
        .sdin(JC[1]),
        .sclk(JC[3]),
        .d_cn(JC[4]),
        .resn(JC[5]),
        .vccen(JC[6]),
        .pmoden(JC[7])
    );

    // Pixel generator instantiation
    pixel_generator pix_gen (
        .pixel_index(pixel_index),
        .array(array),
        .compare_idx1(compare_idx1),
        .compare_idx2(compare_idx2),
        .swap_flag(swap_flag),
        .sorting(sorting),
        .done(done),
        .pixel_data(pixel_data)
    );

    // LED indicators
    // Show array values on LEDs (scaled down to fit)
    assign led[15:14] = array[5][7:6];  // Bar 5 (MSBs)
    assign led[13:12] = array[4][7:6];  // Bar 4
    assign led[11:10] = array[3][7:6];  // Bar 3
    assign led[9:8]   = array[2][7:6];  // Bar 2
    assign led[7:6]   = array[1][7:6];  // Bar 1
    assign led[5:4]   = array[0][7:6];  // Bar 0
    assign led[3]     = sorting;        // Sorting indicator
    assign led[2]     = done;           // Done indicator
    assign led[1]     = swap_flag;      // Swap indicator
    assign led[0]     = btn_start_sync; // Button press indicator

    // 7-segment display controller
    reg [15:0] display_value;
    reg [1:0] digit_select;
    reg [19:0] refresh_counter;

    // Refresh counter for 7-segment multiplexing
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
    end

    assign digit_select = refresh_counter[19:18];

    // Display value shows current comparison indices and state
    always @(*) begin
        if (done)
            display_value = 16'hDDDD;  // Show "D" pattern when done
        else if (sorting)
            display_value = {8'h00, compare_idx1, 1'b0, compare_idx2, 1'b0};
        else
            display_value = {8'h00, sw[1:0], 6'h00};  // Show selected pattern
    end

    // 7-segment decoder
    reg [3:0] current_digit;
    always @(*) begin
        case (digit_select)
            2'b00: current_digit = display_value[3:0];
            2'b01: current_digit = display_value[7:4];
            2'b10: current_digit = display_value[11:8];
            2'b11: current_digit = display_value[15:12];
        endcase
    end

    // Anode control (active low)
    assign an = ~(4'b0001 << digit_select);

    // 7-segment pattern (active low, segments: DP G F E D C B A)
    reg [6:0] seg_pattern;
    always @(*) begin
        case (current_digit)
            4'h0: seg_pattern = 7'b1000000;  // 0
            4'h1: seg_pattern = 7'b1111001;  // 1
            4'h2: seg_pattern = 7'b0100100;  // 2
            4'h3: seg_pattern = 7'b0110000;  // 3
            4'h4: seg_pattern = 7'b0011001;  // 4
            4'h5: seg_pattern = 7'b0010010;  // 5
            4'h6: seg_pattern = 7'b0000010;  // 6
            4'h7: seg_pattern = 7'b1111000;  // 7
            4'h8: seg_pattern = 7'b0000000;  // 8
            4'h9: seg_pattern = 7'b0010000;  // 9
            4'hA: seg_pattern = 7'b0001000;  // A
            4'hB: seg_pattern = 7'b0000011;  // b
            4'hC: seg_pattern = 7'b1000110;  // C
            4'hD: seg_pattern = 7'b0100001;  // d
            4'hE: seg_pattern = 7'b0000110;  // E
            4'hF: seg_pattern = 7'b0001110;  // F
        endcase
    end
    assign seg = seg_pattern;

    // JC[2] is not used in standard OLED configuration
    assign JC[2] = 1'b0;

endmodule
