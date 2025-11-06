`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.10.2025 00:45:19
// Design Name: 
// Module Name: Tutorial_Sort_Engine
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


module Tutorial_Sort_Engine(
    input clk_100mhz,
    input reset,
    
    // User inputs (from Main_FSM)
    input compare_left_pulse,       // btnL pressed
    input compare_right_pulse,      // btnR pressed
    input swap_pulse,               // btnC pressed
    input keep_pulse,               // btnD pressed
    
    // Initial array from Tutorial_Input_Engine
    input [2:0] input_array_0,
    input [2:0] input_array_1,
    input [2:0] input_array_2,
    input [2:0] input_array_3,
    input [2:0] input_array_4,
    input [2:0] input_array_5,
    
    // Current array state (for rendering)
    output reg [2:0] current_array_0,
    output reg [2:0] current_array_1,
    output reg [2:0] current_array_2,
    output reg [2:0] current_array_3,
    output reg [2:0] current_array_4,
    output reg [2:0] current_array_5,
    
    // Visual feedback
    output reg [2:0] red_line_pos,      // Position of red line (0-5)
    output reg [2:0] compare_idx1,      // First comparison box (yellow)
    output reg [2:0] compare_idx2,      // Second comparison box (yellow)
    output reg [2:0] swap_idx1,         // First swap box (blue)
    output reg [2:0] swap_idx2,         // Second swap box (blue)
    
    // State flags
    output reg [2:0] hearts_remaining,  // 3, 2, 1, or 0
    output reg is_victory,
    output reg is_game_over,
    output reg show_mistake             // Display red X
);

    //==========================================================================
    // Internal State Machine
    //==========================================================================
    localparam WAIT_DIRECTION   = 3'd0;  // Waiting for user to choose L or R
    localparam SHOW_COMPARISON  = 3'd1;  // Show yellow highlights
    localparam WAIT_DECISION    = 3'd2;  // Waiting for user to choose C or D
    localparam ANIMATE_SWAP     = 3'd3;  // Blue swap animation
    localparam SHOW_MISTAKE     = 3'd4;  // Red X animation
    localparam CHECK_ADVANCE    = 3'd5;  // Decide next action
    localparam VICTORY          = 3'd6;  // All sorted!
    localparam GAME_OVER        = 3'd7;  // Lost all hearts
    
    reg [2:0] state;
    
    // Sorting tracking variables
    reg [2:0] current_position;     // Which position is being sorted (0-5)
    reg [2:0] sorted_boundary;      // Red line position (0-5)
    reg comparing_direction;        // 0=left, 1=right
    reg last_action_was_swap;       // Track if we just swapped
    
    // Animation timing
    localparam SWAP_DELAY_CYCLES = 27'd15_000_000;      // 0.25 seconds
    localparam MISTAKE_DELAY_CYCLES = 27'd50_000_000;  // 1.0 seconds
    reg [26:0] delay_counter;
    
    // Helper wires for array access
    wire [2:0] array_read [0:5];
    assign array_read[0] = current_array_0;
    assign array_read[1] = current_array_1;
    assign array_read[2] = current_array_2;
    assign array_read[3] = current_array_3;
    assign array_read[4] = current_array_4;
    assign array_read[5] = current_array_5;
    
    // Temporary storage for swapping
    reg [2:0] temp_value;
    
    //==========================================================================
    // Validator Logic (Combinational)
    //==========================================================================
    reg [2:0] value1, value2;
        reg should_swap;
        
        // Get values being compared (with bounds checking)
        always @(*) begin
            if (comparing_direction == 1'b1) begin
                // Comparing RIGHT
                value1 = array_read[current_position];
                value2 = array_read[current_position + 1];
            end else begin
                // Comparing LEFT
                if (current_position > 0) begin
                    value1 = array_read[current_position - 1];
                    value2 = array_read[current_position];
                end else begin
                    // Safety: should never happen, but prevent underflow
                    value1 = 3'd0;
                    value2 = 3'd0;
                end
            end
            
            // Determine if swap is correct (value2 < value1)
            should_swap = (value2 < value1);
        end
    
    //==========================================================================
    // State Machine
    //==========================================================================
    always @(posedge clk_100mhz) begin
        if (reset) begin
            // Initialize
            state <= WAIT_DIRECTION;
            current_position <= 3'd0;  // Start from first element
            sorted_boundary <= 3'd0;
            hearts_remaining <= 3'd3;
            is_victory <= 1'b0;
            is_game_over <= 1'b0;
            show_mistake <= 1'b0;
            comparing_direction <= 1'b1;  // Start with right
            last_action_was_swap <= 1'b0;
            delay_counter <= 27'd0;

            // Load initial array
            current_array_0 <= input_array_0;
            current_array_1 <= input_array_1;
            current_array_2 <= input_array_2;
            current_array_3 <= input_array_3;
            current_array_4 <= input_array_4;
            current_array_5 <= input_array_5;

            // Visual indicators
            red_line_pos <= 3'd1;  // Red line after first box
            compare_idx1 <= 3'd7;  // Invalid = hidden
            compare_idx2 <= 3'd7;
            swap_idx1 <= 3'd7;
            swap_idx2 <= 3'd7;
            
        end else begin
            // Default: clear one-cycle flags
            show_mistake <= 1'b0;
            
            case (state)
                //==============================================================
                WAIT_DIRECTION: begin
                    // Single yellow box on current position
                    compare_idx1 <= current_position;
                    compare_idx2 <= 3'd7;  // Hide second box
                    swap_idx1 <= 3'd7;
                    swap_idx2 <= 3'd7;
                    
                    // Determine correct direction
                    if (current_position == 3'd0) begin
                        // At leftmost position, must compare right
                        if (compare_right_pulse) begin
                            comparing_direction <= 1'b1;  // right
                            state <= SHOW_COMPARISON;
                        end else if (compare_left_pulse) begin
                            // WRONG! No left element
                            show_mistake <= 1'b1;
                            hearts_remaining <= hearts_remaining - 1;
                            delay_counter <= 27'd0;
                            state <= SHOW_MISTAKE;
                        end
                        
                    end else if (last_action_was_swap) begin
                        // After swap, must compare left
                        if (compare_left_pulse) begin
                            comparing_direction <= 1'b0;  // left
                            state <= SHOW_COMPARISON;
                        end else if (compare_right_pulse) begin
                            // WRONG! Should bubble backward
                            show_mistake <= 1'b1;
                            hearts_remaining <= hearts_remaining - 1;
                            delay_counter <= 27'd0;
                            state <= SHOW_MISTAKE;
                        end
                        
                    end else begin
                        // After keep, must compare right
                        if (compare_right_pulse) begin
                            comparing_direction <= 1'b1;  // right
                            state <= SHOW_COMPARISON;
                        end else if (compare_left_pulse) begin
                            // WRONG! Should move forward
                            show_mistake <= 1'b1;
                            hearts_remaining <= hearts_remaining - 1;
                            delay_counter <= 27'd0;
                            state <= SHOW_MISTAKE;
                        end
                    end
                end
                
                //==============================================================
                SHOW_COMPARISON: begin
                    // Show two yellow boxes
                    if (comparing_direction == 1'b1) begin
                        // Comparing right
                        compare_idx1 <= current_position;
                        compare_idx2 <= current_position + 1;
                    end else begin
                        // Comparing left
                        compare_idx1 <= current_position - 1;
                        compare_idx2 <= current_position;
                    end
                    
                    // Immediately transition to decision phase
                    state <= WAIT_DECISION;
                end
                
                //==============================================================
                WAIT_DECISION: begin
                    // Yellow boxes stay visible
                    // Wait for user to press C (swap) or D (keep)
                    
                    if (swap_pulse) begin
                        // User chose SWAP
                        if (should_swap) begin
                            // CORRECT!
                            last_action_was_swap <= 1'b1;
                            
                            // Perform swap in array
                            if (comparing_direction == 1'b1) begin
                                // Swapping current_position with current_position+1
                                temp_value <= array_read[current_position];
                                
                                case (current_position)
                                    3'd0: begin
                                        current_array_0 <= array_read[1];
                                        current_array_1 <= array_read[0];
                                    end
                                    3'd1: begin
                                        current_array_1 <= array_read[2];
                                        current_array_2 <= array_read[1];
                                    end
                                    3'd2: begin
                                        current_array_2 <= array_read[3];
                                        current_array_3 <= array_read[2];
                                    end
                                    3'd3: begin
                                        current_array_3 <= array_read[4];
                                        current_array_4 <= array_read[3];
                                    end
                                    3'd4: begin
                                        current_array_4 <= array_read[5];
                                        current_array_5 <= array_read[4];
                                    end
                                endcase
                                
                                // Current position doesn't change (element moved right, but we track position)
                                // Actually, we need to track the ELEMENT that moved
                                // The element that was at current_position is now at current_position+1
                                // But we want to track where the smaller element went
                                // So current_position stays the same!
                                
                            end else begin
                                // Swapping current_position with current_position-1
                                case (current_position)
                                    3'd1: begin
                                        current_array_0 <= array_read[1];
                                        current_array_1 <= array_read[0];
                                    end
                                    3'd2: begin
                                        current_array_1 <= array_read[2];
                                        current_array_2 <= array_read[1];
                                    end
                                    3'd3: begin
                                        current_array_2 <= array_read[3];
                                        current_array_3 <= array_read[2];
                                    end
                                    3'd4: begin
                                        current_array_3 <= array_read[4];
                                        current_array_4 <= array_read[3];
                                    end
                                    3'd5: begin
                                        current_array_4 <= array_read[5];
                                        current_array_5 <= array_read[4];
                                    end
                                endcase
                                
                                // Element moved left, so track it
                                current_position <= current_position - 1;
                            end
                            
                            // Show blue animation
                            swap_idx1 <= compare_idx1;
                            swap_idx2 <= compare_idx2;
                            compare_idx1 <= 3'd7;
                            compare_idx2 <= 3'd7;
                            
                            delay_counter <= 27'd0;
                            state <= ANIMATE_SWAP;
                            
                        end else begin
                            // WRONG! Should have kept
                            show_mistake <= 1'b1;
                            hearts_remaining <= hearts_remaining - 1;
                            delay_counter <= 27'd0;
                            state <= SHOW_MISTAKE;
                        end
                        
                    end else if (keep_pulse) begin
                        // User chose KEEP
                        if (!should_swap) begin
                            // CORRECT!
                            last_action_was_swap <= 1'b0;
                            compare_idx1 <= 3'd7;
                            compare_idx2 <= 3'd7;
                            state <= CHECK_ADVANCE;
                            
                        end else begin
                            // WRONG! Should have swapped
                            show_mistake <= 1'b1;
                            hearts_remaining <= hearts_remaining - 1;
                            delay_counter <= 27'd0;
                            state <= SHOW_MISTAKE;
                        end
                    end
                end
                
                //==============================================================
                ANIMATE_SWAP: begin
                    // Blue boxes visible during animation
                    if (delay_counter < SWAP_DELAY_CYCLES) begin
                        delay_counter <= delay_counter + 1;
                    end else begin
                        // Animation done
                        swap_idx1 <= 3'd7;
                        swap_idx2 <= 3'd7;
                        
                        // After swap, continue with current_position
                        // Check if we can still bubble left
                        if (current_position == 3'd0) begin
                            // Reached left edge, advance
                            state <= CHECK_ADVANCE;
                        end else begin
                            // Can still compare left
                            state <= WAIT_DIRECTION;
                        end
                    end
                end
                
                //==============================================================
                SHOW_MISTAKE: begin
                    // Red X visible, delay counter running
                    if (delay_counter < MISTAKE_DELAY_CYCLES) begin
                        delay_counter <= delay_counter + 1;
                        show_mistake <= 1'b1;
                    end else begin
                        show_mistake <= 1'b0;
                        
                        // Check if game over
                        if (hearts_remaining == 3'd0) begin
                            is_game_over <= 1'b1;
                            state <= GAME_OVER;
                        end else begin
                            // Return to previous state
                            state <= WAIT_DIRECTION;
                        end
                    end
                end
                
                //==============================================================
                CHECK_ADVANCE: begin
                    // Element is sorted at current_position
                    // Move sorted boundary forward
                    sorted_boundary <= sorted_boundary + 1;
                    red_line_pos <= red_line_pos + 1;  // Move red line forward

                    // Check if all sorted
                    if (sorted_boundary == 3'd4) begin
                        // All 6 elements sorted!
                        is_victory <= 1'b1;
                        state <= VICTORY;
                    end else begin
                        // Move to next unsorted element
                        current_position <= sorted_boundary + 1;
                        last_action_was_swap <= 1'b0;
                        state <= WAIT_DIRECTION;
                    end
                end
                
                //==============================================================
                VICTORY: begin
                    // Stay in victory state
                    // Main_FSM will handle transition back
                end
                
                //==============================================================
                GAME_OVER: begin
                    // Stay in game over state
                    // Main_FSM will handle transition back
                end
                
                //==============================================================
                default: begin
                    state <= WAIT_DIRECTION;
                end
            endcase
        end
    end
    
endmodule
