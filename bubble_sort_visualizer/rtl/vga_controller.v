`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// VGA Controller for 640x480 @ 60Hz
// Pixel Clock: 25.175 MHz (approximated as 25 MHz)
//
// Horizontal Timing:
//   Display:       640 pixels
//   Front Porch:   16 pixels
//   Sync Pulse:    96 pixels
//   Back Porch:    48 pixels
//   Total:         800 pixels
//
// Vertical Timing:
//   Display:       480 lines
//   Front Porch:   10 lines
//   Sync Pulse:    2 lines
//   Back Porch:    33 lines
//   Total:         525 lines
//////////////////////////////////////////////////////////////////////////////////

module vga_controller(
    input wire clk,           // 25 MHz pixel clock
    input wire rst,           // Active high reset
    output reg hsync,         // Horizontal sync
    output reg vsync,         // Vertical sync
    output wire [9:0] x,      // Current pixel x coordinate
    output wire [9:0] y,      // Current pixel y coordinate
    output wire video_on      // High when in display region
);

    // VGA 640x480 @ 60Hz timing parameters
    // Horizontal timing (pixels)
    localparam H_DISPLAY    = 640;
    localparam H_FRONT      = 16;
    localparam H_SYNC       = 96;
    localparam H_BACK       = 48;
    localparam H_TOTAL      = 800;

    // Vertical timing (lines)
    localparam V_DISPLAY    = 480;
    localparam V_FRONT      = 10;
    localparam V_SYNC       = 2;
    localparam V_BACK       = 33;
    localparam V_TOTAL      = 525;

    // Horizontal and vertical counters
    reg [9:0] h_count;
    reg [9:0] v_count;

    // Horizontal counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            h_count <= 0;
        end else begin
            if (h_count == H_TOTAL - 1)
                h_count <= 0;
            else
                h_count <= h_count + 1;
        end
    end

    // Vertical counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            v_count <= 0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                if (v_count == V_TOTAL - 1)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
            end
        end
    end

    // Generate horizontal sync signal (active low)
    always @(posedge clk or posedge rst) begin
        if (rst)
            hsync <= 1'b1;
        else
            hsync <= (h_count >= (H_DISPLAY + H_FRONT)) &&
                     (h_count < (H_DISPLAY + H_FRONT + H_SYNC)) ? 1'b0 : 1'b1;
    end

    // Generate vertical sync signal (active low)
    always @(posedge clk or posedge rst) begin
        if (rst)
            vsync <= 1'b1;
        else
            vsync <= (v_count >= (V_DISPLAY + V_FRONT)) &&
                     (v_count < (V_DISPLAY + V_FRONT + V_SYNC)) ? 1'b0 : 1'b1;
    end

    // Output current pixel coordinates
    assign x = (h_count < H_DISPLAY) ? h_count : 10'd0;
    assign y = (v_count < V_DISPLAY) ? v_count : 10'd0;

    // Video on signal (high during active display region)
    assign video_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

endmodule
