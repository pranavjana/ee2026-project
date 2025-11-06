`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Simplified Top Module for Bubble Sort Visualizer
// Only OLED display, btnU (reset), btnC (start)
//////////////////////////////////////////////////////////////////////////////////

module bubble_sort_top(
    input wire clk,              // 100 MHz clock
    input wire btnC,             // Center button - Start
    input wire btnU,             // Up button - Reset
    input wire btnL,             // Left button (unused)
    input wire btnR,             // Right button (unused)
    input wire btnD,             // Down button (unused)
    input wire [3:0] sw,         // Switches (unused in simple version)
    output wire [15:0] led,      // LEDs
    output wire [6:0] seg,       // 7-segment display segments (unused)
    output wire [3:0] an,        // 7-segment display anodes (unused)
    output wire [7:0] JC         // OLED PMOD connector
);

    // Tie off unused outputs
    assign seg = 7'b1111111;  // All segments off
    assign an = 4'b1111;      // All anodes off

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
    wire [7:0] array0, array1, array2, array3, array4, array5;
    wire [2:0] compare_idx1;
    wire [2:0] compare_idx2;
    wire swap_flag;
    wire sorting;
    wire done;

    // Bubble sort FSM instantiation (always use pattern 00 - random)
    bubble_sort_fsm sort_fsm (
        .clk(clk),
        .rst(btn_reset_edge),
        .start(btn_start_edge),
        .step_pulse(clk_1hz_pulse),
        .pattern_sel(2'b00),  // Fixed to random pattern
        .array0(array0),
        .array1(array1),
        .array2(array2),
        .array3(array3),
        .array4(array4),
        .array5(array5),
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
        .array0(array0),
        .array1(array1),
        .array2(array2),
        .array3(array3),
        .array4(array4),
        .array5(array5),
        .compare_idx1(compare_idx1),
        .compare_idx2(compare_idx2),
        .swap_flag(swap_flag),
        .sorting(sorting),
        .done(done),
        .pixel_data(pixel_data)
    );

    // LED indicators - show array values
    reg [15:0] led_reg;
    assign led = led_reg;

    always @(*) begin
        led_reg[15:14] = array5[7:6];    // Bar 5 (MSBs)
        led_reg[13:12] = array4[7:6];    // Bar 4
        led_reg[11:10] = array3[7:6];    // Bar 3
        led_reg[9:8]   = array2[7:6];    // Bar 2
        led_reg[7:6]   = array1[7:6];    // Bar 1
        led_reg[5:4]   = array0[7:6];    // Bar 0
        led_reg[3]     = sorting;        // Sorting indicator
        led_reg[2]     = done;           // Done indicator
        led_reg[1]     = swap_flag;      // Swap indicator
        led_reg[0]     = btn_start_sync; // Button press indicator
    end

    // JC[2] is not used in standard OLED configuration
    assign JC[2] = 1'b0;

endmodule
