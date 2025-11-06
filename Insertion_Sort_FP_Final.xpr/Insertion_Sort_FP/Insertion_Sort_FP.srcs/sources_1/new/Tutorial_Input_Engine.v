`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.10.2025 15:19:51
// Design Name: 
// Module Name: Tutorial_Input_Engine
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


module Tutorial_Input_Engine(
    input clk_100mhz,
    input reset,            // Global system reset
    input tutorial_mode_active,
    input inc_val_pulse,    // Pulse from btnU via FSM
    input dec_val_pulse,    // Pulse from btnD via FSM
    input move_r_pulse,     // Pulse from btnR via FSM
    input move_l_pulse,     // Pulse from btnL via FSM
    output reg [2:0] tut_array_0, // Array values (0-7)
    output reg [2:0] tut_array_1,
    output reg [2:0] tut_array_2,
    output reg [2:0] tut_array_3,
    output reg [2:0] tut_array_4,
    output reg [2:0] tut_array_5,
    output reg [2:0] cursor_pos     // Index of highlighted box (0-5)
);
    
    reg was_tutorial_inactive;
    
    always @(posedge clk_100mhz) begin
        if (reset) begin
            tut_array_0 <= 3'd0;
            tut_array_1 <= 3'd0;
            tut_array_2 <= 3'd0;
            tut_array_3 <= 3'd0;
            tut_array_4 <= 3'd0;
            tut_array_5 <= 3'd0;
            cursor_pos  <= 3'd0;
            was_tutorial_inactive <= 1'b1;
        end else begin
            // Detect rising edge of tutorial mode activation
                was_tutorial_inactive <= !tutorial_mode_active;
                
                // Reset arrays when tutorial mode is just activated
                if (was_tutorial_inactive && tutorial_mode_active) begin
                    // Just entered tutorial mode - reset!
                    tut_array_0 <= 3'd0;
                    tut_array_1 <= 3'd0;
                    tut_array_2 <= 3'd0;
                    tut_array_3 <= 3'd0;
                    tut_array_4 <= 3'd0;
                    tut_array_5 <= 3'd0;
                    cursor_pos <= 3'd0;
                    
            end else if (inc_val_pulse) begin
                case (cursor_pos)
                    3'd0: tut_array_0 <= (tut_array_0 == 3'd7) ? 3'd0 : tut_array_0 + 1;
                    3'd1: tut_array_1 <= (tut_array_1 == 3'd7) ? 3'd0 : tut_array_1 + 1;
                    3'd2: tut_array_2 <= (tut_array_2 == 3'd7) ? 3'd0 : tut_array_2 + 1;
                    3'd3: tut_array_3 <= (tut_array_3 == 3'd7) ? 3'd0 : tut_array_3 + 1;
                    3'd4: tut_array_4 <= (tut_array_4 == 3'd7) ? 3'd0 : tut_array_4 + 1;
                    3'd5: tut_array_5 <= (tut_array_5 == 3'd7) ? 3'd0 : tut_array_5 + 1;
                endcase
            end else if (dec_val_pulse) begin
                 case (cursor_pos)
                    3'd0: tut_array_0 <= (tut_array_0 == 3'd0) ? 3'd7 : tut_array_0 - 1;
                    3'd1: tut_array_1 <= (tut_array_1 == 3'd0) ? 3'd7 : tut_array_1 - 1;
                    3'd2: tut_array_2 <= (tut_array_2 == 3'd0) ? 3'd7 : tut_array_2 - 1;
                    3'd3: tut_array_3 <= (tut_array_3 == 3'd0) ? 3'd7 : tut_array_3 - 1;
                    3'd4: tut_array_4 <= (tut_array_4 == 3'd0) ? 3'd7 : tut_array_4 - 1;
                    3'd5: tut_array_5 <= (tut_array_5 == 3'd0) ? 3'd7 : tut_array_5 - 1;
                endcase
            end else if (move_r_pulse) begin
                // Move cursor right with wrapping
                cursor_pos <= (cursor_pos == 3'd5) ? 3'd0 : cursor_pos + 1;
            end else if (move_l_pulse) begin
                // Move cursor left with wrapping
                cursor_pos <= (cursor_pos == 3'd0) ? 3'd5 : cursor_pos - 1;
            end
        end
    end

endmodule
