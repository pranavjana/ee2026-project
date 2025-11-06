`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/22/2025
// Design Name:
// Module Name: button_debounce_5btn
// Project Name: Bubble Sort Tutorial
// Target Devices: Basys 3 (Artix-7)
// Tool Versions:
// Description:
//   Five-button debouncing module with edge detection.
//   Debounces all 5 Basys 3 buttons (Left, Right, Up, Down, Center)
//   and generates single-cycle pulses on rising edges.
//
//   Based on the debouncing algorithm from bubble_sort_top.v
//   Debounce threshold: 999,999 cycles @ 100MHz = ~10ms
//
// Dependencies: None
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module button_debounce_5btn(
    input wire clk,              // 100 MHz system clock
    input wire reset,            // Synchronous reset
    input wire btnL,             // Left button (raw input)
    input wire btnR,             // Right button (raw input)
    input wire btnU,             // Up button (raw input)
    input wire btnD,             // Down button (raw input)
    input wire btnC,             // Center button (raw input)
    output reg btn_l_edge,       // Left button rising edge pulse
    output reg btn_r_edge,       // Right button rising edge pulse
    output reg btn_u_edge,       // Up button rising edge pulse
    output reg btn_d_edge,       // Down button rising edge pulse
    output reg btn_c_edge        // Center button rising edge pulse
);

    // Debounce threshold: 999,999 cycles = 10ms at 100MHz
    localparam DEBOUNCE_THRESHOLD = 999_999;

    // Counters for each button (20 bits to hold up to 1,048,575)
    reg [19:0] btn_counter_l;
    reg [19:0] btn_counter_r;
    reg [19:0] btn_counter_u;
    reg [19:0] btn_counter_d;
    reg [19:0] btn_counter_c;

    // Synchronized button states
    reg btn_l_sync, btn_l_prev;
    reg btn_r_sync, btn_r_prev;
    reg btn_u_sync, btn_u_prev;
    reg btn_d_sync, btn_d_prev;
    reg btn_c_sync, btn_c_prev;

    //=========================================================================
    // Left Button Debouncing
    //=========================================================================
    always @(posedge clk) begin
        if (reset) begin
            btn_counter_l <= 0;
            btn_l_sync <= 0;
            btn_l_prev <= 0;
            btn_l_edge <= 0;
        end else begin
            // Increment counter while button is pressed
            if (btnL) begin
                if (btn_counter_l < DEBOUNCE_THRESHOLD) begin
                    btn_counter_l <= btn_counter_l + 1;
                end else begin
                    btn_l_sync <= 1;
                end
            end else begin
                btn_counter_l <= 0;
                btn_l_sync <= 0;
            end

            // Edge detection
            btn_l_prev <= btn_l_sync;
            btn_l_edge <= btn_l_sync && !btn_l_prev;
        end
    end

    //=========================================================================
    // Right Button Debouncing
    //=========================================================================
    always @(posedge clk) begin
        if (reset) begin
            btn_counter_r <= 0;
            btn_r_sync <= 0;
            btn_r_prev <= 0;
            btn_r_edge <= 0;
        end else begin
            // Increment counter while button is pressed
            if (btnR) begin
                if (btn_counter_r < DEBOUNCE_THRESHOLD) begin
                    btn_counter_r <= btn_counter_r + 1;
                end else begin
                    btn_r_sync <= 1;
                end
            end else begin
                btn_counter_r <= 0;
                btn_r_sync <= 0;
            end

            // Edge detection
            btn_r_prev <= btn_r_sync;
            btn_r_edge <= btn_r_sync && !btn_r_prev;
        end
    end

    //=========================================================================
    // Up Button Debouncing
    //=========================================================================
    always @(posedge clk) begin
        if (reset) begin
            btn_counter_u <= 0;
            btn_u_sync <= 0;
            btn_u_prev <= 0;
            btn_u_edge <= 0;
        end else begin
            // Increment counter while button is pressed
            if (btnU) begin
                if (btn_counter_u < DEBOUNCE_THRESHOLD) begin
                    btn_counter_u <= btn_counter_u + 1;
                end else begin
                    btn_u_sync <= 1;
                end
            end else begin
                btn_counter_u <= 0;
                btn_u_sync <= 0;
            end

            // Edge detection
            btn_u_prev <= btn_u_sync;
            btn_u_edge <= btn_u_sync && !btn_u_prev;
        end
    end

    //=========================================================================
    // Down Button Debouncing
    //=========================================================================
    always @(posedge clk) begin
        if (reset) begin
            btn_counter_d <= 0;
            btn_d_sync <= 0;
            btn_d_prev <= 0;
            btn_d_edge <= 0;
        end else begin
            // Increment counter while button is pressed
            if (btnD) begin
                if (btn_counter_d < DEBOUNCE_THRESHOLD) begin
                    btn_counter_d <= btn_counter_d + 1;
                end else begin
                    btn_d_sync <= 1;
                end
            end else begin
                btn_counter_d <= 0;
                btn_d_sync <= 0;
            end

            // Edge detection
            btn_d_prev <= btn_d_sync;
            btn_d_edge <= btn_d_sync && !btn_d_prev;
        end
    end

    //=========================================================================
    // Center Button Debouncing
    //=========================================================================
    always @(posedge clk) begin
        if (reset) begin
            btn_counter_c <= 0;
            btn_c_sync <= 0;
            btn_c_prev <= 0;
            btn_c_edge <= 0;
        end else begin
            // Increment counter while button is pressed
            if (btnC) begin
                if (btn_counter_c < DEBOUNCE_THRESHOLD) begin
                    btn_counter_c <= btn_counter_c + 1;
                end else begin
                    btn_c_sync <= 1;
                end
            end else begin
                btn_counter_c <= 0;
                btn_c_sync <= 0;
            end

            // Edge detection
            btn_c_prev <= btn_c_sync;
            btn_c_edge <= btn_c_sync && !btn_c_prev;
        end
    end

endmodule
