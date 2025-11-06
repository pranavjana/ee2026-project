`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/22/2025
// Design Name:
// Module Name: tutorial_fsm
// Project Name: Bubble Sort Tutorial
// Target Devices: Basys 3 (Artix-7)
// Tool Versions:
// Description:
//   Interactive bubble sort tutorial state machine.
//   Allows users to create custom arrays and step through bubble sort
//   with visual feedback on correct/incorrect comparisons and swaps.
//
//   Tutorial Flow:
//   1. SETUP_INIT: Initialize 6 boxes with 0
//   2. SETUP_EDIT: User navigates (btnL/R) and edits values (btnU/D)
//   3. SETUP_CONFIRM: User presses btnC to start tutorial
//   4. TUTORIAL_SELECT: Select adjacent pair with btnL/R
//   5. TUTORIAL_COMPARE: Show comparison
//   6. TUTORIAL_AWAIT_SWAP: Wait for swap decision (btnU=swap, btnD=skip)
//   7. TUTORIAL_SWAP_ANIM: Animate swap
//   8. TUTORIAL_FEEDBACK: Show correct/incorrect feedback
//   9. TUTORIAL_CHECK_DONE: Check if array is sorted
//   10. TUTORIAL_COMPLETE: Success celebration
//
// Dependencies: None
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module tutorial_fsm(
    input wire clk,                    // 100 MHz system clock
    input wire reset,                  // Synchronous reset (btnC in setup)
    input wire enable,                 // Tutorial mode enable (sw[12] & sw[0])
    input wire btn_l_edge,             // Left button edge
    input wire btn_r_edge,             // Right button edge
    input wire btn_u_edge,             // Up button edge
    input wire btn_d_edge,             // Down button edge
    input wire btn_c_edge,             // Center button edge
    input wire frame_tick,             // ~60 Hz frame tick for animations

    // Array outputs for display (individual elements for synthesis compatibility)
    output reg [7:0] array0,           // Array element 0
    output reg [7:0] array1,           // Array element 1
    output reg [7:0] array2,           // Array element 2
    output reg [7:0] array3,           // Array element 3
    output reg [7:0] array4,           // Array element 4
    output reg [7:0] array5,           // Array element 5
    output reg [2:0] cursor_pos,       // Current cursor/selection position
    output reg [2:0] compare_pos,      // Second comparison position (cursor_pos+1)
    output reg [4:0] anim_frame,       // Animation frame counter (0-31)
    output reg [6:0] progress_percent, // Progress percentage (0-100)
    output reg feedback_correct,       // Show green checkmark
    output reg feedback_incorrect,     // Show red X
    output reg is_sorted,              // Array is fully sorted
    output reg [3:0] current_state_num // Current state for debugging
);

    //=========================================================================
    // State Definitions
    //=========================================================================
    localparam [3:0]
        SETUP_INIT          = 4'd0,   // Initialize array with zeros
        SETUP_EDIT          = 4'd1,   // User edits array values
        SETUP_CONFIRM       = 4'd2,   // Wait for confirmation to start
        TUTORIAL_SELECT     = 4'd3,   // Select adjacent pair
        TUTORIAL_COMPARE    = 4'd4,   // Display comparison
        TUTORIAL_AWAIT_SWAP = 4'd5,   // Wait for swap decision
        TUTORIAL_SWAP_ANIM  = 4'd6,   // Animate the swap
        TUTORIAL_FEEDBACK   = 4'd7,   // Show feedback
        TUTORIAL_CHECK_DONE = 4'd8,   // Check if sorted
        TUTORIAL_COMPLETE   = 4'd9;   // Success celebration

    reg [3:0] state, next_state;

    //=========================================================================
    // Internal Registers
    //=========================================================================

    // Internal array (working copy)
    reg [7:0] array [0:5];

    // Continuously assign internal array to individual outputs
    always @(*) begin
        array0 = array[0];
        array1 = array[1];
        array2 = array[2];
        array3 = array[3];
        array4 = array[4];
        array5 = array[5];
    end

    // Optimal solution tracker (shadow bubble sort)
    reg [7:0] optimal_array [0:5];
    reg [2:0] optimal_i, optimal_j;
    reg [2:0] optimal_pass;
    reg optimal_should_swap;
    reg optimal_sorted;

    // User's action tracker
    reg user_swapped;
    reg user_action_correct;

    // Swap temporary storage
    reg [7:0] swap_temp;

    // Animation and timing
    reg [4:0] anim_counter;
    reg [7:0] feedback_timer;  // Feedback display duration

    // Total swaps for progress tracking
    reg [6:0] total_correct_swaps;
    reg [6:0] swaps_needed;  // Total swaps needed for optimal sort

    // Bubble sort order tracking
    reg [2:0] expected_pos;      // Expected next comparison position (0-4)
    reg [2:0] current_pass;      // Current bubble sort pass (0-5)
    reg [2:0] pass_limit;        // Upper limit for current pass (5-1 each pass)

    //=========================================================================
    // State Register
    //=========================================================================
    always @(posedge clk) begin
        if (!enable) begin
            state <= SETUP_INIT;
        end else begin
            state <= next_state;
        end
    end

    //=========================================================================
    // Next State Logic
    //=========================================================================
    // Combinational check if array is currently sorted
    wire array_is_sorted = (array[0] <= array[1]) &&
                           (array[1] <= array[2]) &&
                           (array[2] <= array[3]) &&
                           (array[3] <= array[4]) &&
                           (array[4] <= array[5]);

    always @(*) begin
        next_state = state;

        case (state)
            SETUP_INIT: begin
                next_state = SETUP_EDIT;
            end

            SETUP_EDIT: begin
                if (btn_c_edge) begin
                    next_state = SETUP_CONFIRM;
                end
            end

            SETUP_CONFIRM: begin
                next_state = TUTORIAL_SELECT;
            end

            TUTORIAL_SELECT: begin
                // User selects which pair to compare and decides to swap or skip
                if (btn_u_edge) begin
                    // User chose to swap
                    next_state = TUTORIAL_SWAP_ANIM;
                end else if (btn_d_edge) begin
                    // User chose not to swap
                    next_state = TUTORIAL_FEEDBACK;
                end
            end

            TUTORIAL_COMPARE: begin
                // Show comparison briefly (not currently used - for future enhancement)
                next_state = TUTORIAL_AWAIT_SWAP;
            end

            TUTORIAL_AWAIT_SWAP: begin
                // Wait for user decision (not currently used - for future enhancement)
                if (btn_u_edge) begin
                    next_state = TUTORIAL_SWAP_ANIM;
                end else if (btn_d_edge) begin
                    next_state = TUTORIAL_FEEDBACK;
                end
            end

            TUTORIAL_SWAP_ANIM: begin
                if (anim_counter >= 15) begin  // 16 frames (0-15)
                    next_state = TUTORIAL_FEEDBACK;
                end
            end

            TUTORIAL_FEEDBACK: begin
                if (feedback_timer >= 60) begin  // Display for ~1 second
                    next_state = TUTORIAL_CHECK_DONE;
                end
            end

            TUTORIAL_CHECK_DONE: begin
                // Use combinational check to detect sorted immediately
                if (array_is_sorted) begin
                    next_state = TUTORIAL_COMPLETE;
                end else begin
                    next_state = TUTORIAL_SELECT;
                end
            end

            TUTORIAL_COMPLETE: begin
                // Stay in complete state, reset with btnC
                if (btn_c_edge) begin
                    next_state = SETUP_INIT;
                end
            end

            default: begin
                next_state = SETUP_INIT;
            end
        endcase
    end

    //=========================================================================
    // Output Logic and Data Path
    //=========================================================================
    integer i;

    always @(posedge clk) begin
        if (!enable) begin
            // Reset all array elements only when disabled
            for (i = 0; i < 6; i = i + 1) begin
                array[i] <= 0;
                optimal_array[i] <= 0;
            end

            cursor_pos <= 0;
            compare_pos <= 1;
            anim_frame <= 0;
            anim_counter <= 0;
            progress_percent <= 0;
            feedback_correct <= 0;
            feedback_incorrect <= 0;
            is_sorted <= 0;
            user_swapped <= 0;
            user_action_correct <= 0;
            total_correct_swaps <= 0;
            swaps_needed <= 0;
            feedback_timer <= 0;
            optimal_i <= 0;
            optimal_j <= 0;
            optimal_pass <= 0;
            optimal_should_swap <= 0;
            optimal_sorted <= 0;
            current_state_num <= 0;
            expected_pos <= 0;
            current_pass <= 0;
            pass_limit <= 4;

        end else begin
            current_state_num <= state;

            case (state)
                //=============================================================
                // SETUP_INIT: Initialize array with zeros
                //=============================================================
                SETUP_INIT: begin
                    for (i = 0; i < 6; i = i + 1) begin
                        array[i] <= 0;
                    end
                    cursor_pos <= 0;
                    anim_frame <= 0;
                    progress_percent <= 0;
                    feedback_correct <= 0;
                    feedback_incorrect <= 0;
                    is_sorted <= 0;
                    total_correct_swaps <= 0;
                end

                //=============================================================
                // SETUP_EDIT: User navigates and edits values
                //=============================================================
                SETUP_EDIT: begin
                    // Navigate with btnL (left) and btnR (right)
                    if (btn_l_edge) begin
                        if (cursor_pos == 0) begin
                            cursor_pos <= 5;  // Wrap to end
                        end else begin
                            cursor_pos <= cursor_pos - 1;
                        end
                    end else if (btn_r_edge) begin
                        if (cursor_pos == 5) begin
                            cursor_pos <= 0;  // Wrap to start
                        end else begin
                            cursor_pos <= cursor_pos + 1;
                        end
                    end

                    // Modify value with btnU (increment) and btnD (decrement)
                    if (btn_u_edge) begin
                        if (array[cursor_pos] == 7) begin
                            array[cursor_pos] <= 0;  // Wrap to 0
                        end else begin
                            array[cursor_pos] <= array[cursor_pos] + 1;
                        end
                    end else if (btn_d_edge) begin
                        if (array[cursor_pos] == 0) begin
                            array[cursor_pos] <= 7;  // Wrap to 7
                        end else begin
                            array[cursor_pos] <= array[cursor_pos] - 1;
                        end
                    end
                end

                //=============================================================
                // SETUP_CONFIRM: Copy to optimal and calculate swaps needed
                //=============================================================
                SETUP_CONFIRM: begin
                    // Copy user's array to optimal tracker
                    for (i = 0; i < 6; i = i + 1) begin
                        optimal_array[i] <= array[i];
                    end

                    // Calculate swaps needed (bubble sort pass count)
                    // For simplicity, estimate as inversions count / 2
                    // This will be updated to actual count in tutorial
                    swaps_needed <= 15;  // Max possible swaps for 6 elements

                    // Reset position to start
                    cursor_pos <= 0;
                    compare_pos <= 1;

                    // Initialize optimal sort tracker
                    optimal_i <= 0;
                    optimal_j <= 0;
                    optimal_pass <= 0;
                    optimal_sorted <= 0;

                    // Initialize bubble sort order tracking
                    expected_pos <= 0;    // Start at position 0
                    current_pass <= 0;    // Start at pass 0
                    pass_limit <= 4;      // First pass goes to position 4 (compares 0-1, 1-2, 2-3, 3-4, 4-5)
                end

                //=============================================================
                // TUTORIAL_SELECT: User selects adjacent pair
                //=============================================================
                TUTORIAL_SELECT: begin
                    feedback_correct <= 0;
                    feedback_incorrect <= 0;

                    // Navigate selection with btnL and btnR
                    if (btn_l_edge) begin
                        if (cursor_pos == 0) begin
                            cursor_pos <= 4;  // Wrap to last valid pair
                        end else begin
                            cursor_pos <= cursor_pos - 1;
                        end
                    end else if (btn_r_edge) begin
                        if (cursor_pos == 4) begin
                            cursor_pos <= 0;  // Wrap to first pair
                        end else begin
                            cursor_pos <= cursor_pos + 1;
                        end
                    end

                    // Update comparison position (always cursor_pos + 1)
                    compare_pos <= cursor_pos + 1;

                    // Calculate optimal next move
                    // Check if should swap these two elements
                    optimal_should_swap <= (array[cursor_pos] > array[cursor_pos + 1]);

                    // Track user decision and validate bubble sort order
                    if (btn_u_edge || btn_d_edge) begin
                        // User made a decision - check if they're at the correct position
                        if (cursor_pos == expected_pos) begin
                            // Correct position! Now check if swap/skip decision is correct
                            if (btn_u_edge) begin
                                user_swapped <= 1;  // User chose to swap
                                // Correct if elements are out of order
                                user_action_correct <= (array[cursor_pos] > array[cursor_pos + 1]);
                            end else begin
                                user_swapped <= 0;  // User chose not to swap
                                // Correct if elements are already in order
                                user_action_correct <= (array[cursor_pos] <= array[cursor_pos + 1]);
                            end
                        end else begin
                            // Wrong position! Not following bubble sort order
                            user_action_correct <= 0;
                            if (btn_u_edge) begin
                                user_swapped <= 1;
                            end else begin
                                user_swapped <= 0;
                            end
                        end
                    end
                end

                //=============================================================
                // TUTORIAL_COMPARE: Display comparison
                //=============================================================
                TUTORIAL_COMPARE: begin
                    // Just hold state for visual display
                    // Next state happens automatically
                end

                //=============================================================
                // TUTORIAL_AWAIT_SWAP: Wait for user decision
                //=============================================================
                TUTORIAL_AWAIT_SWAP: begin
                    // User presses btnU to swap or btnD to skip
                    // Handled in next state logic
                    user_swapped <= 0;  // Will be set in next state
                end

                //=============================================================
                // TUTORIAL_SWAP_ANIM: Animate the swap
                //=============================================================
                TUTORIAL_SWAP_ANIM: begin
                    // user_swapped is already set in TUTORIAL_SELECT

                    // Increment animation frame counter on each frame tick
                    if (frame_tick) begin
                        anim_counter <= anim_counter + 1;
                        anim_frame <= anim_counter;
                    end

                    // Perform actual swap at midpoint (frame 8)
                    if (anim_counter == 8) begin
                        // Swap elements directly without temp variable issue
                        array[cursor_pos] <= array[cursor_pos + 1];
                        array[cursor_pos + 1] <= array[cursor_pos];
                    end

                    // Check if action was correct
                    if (anim_counter == 15) begin
                        user_action_correct <= optimal_should_swap;
                        if (optimal_should_swap) begin
                            total_correct_swaps <= total_correct_swaps + 1;
                        end
                        anim_counter <= 0;
                        anim_frame <= 0;
                    end
                end

                //=============================================================
                // TUTORIAL_FEEDBACK: Show correct/incorrect feedback
                //=============================================================
                TUTORIAL_FEEDBACK: begin
                    // Reset animation counter
                    anim_counter <= 0;
                    anim_frame <= 0;

                    // Display feedback based on user_action_correct
                    // (which was set in TUTORIAL_SELECT based on position and decision)
                    feedback_correct <= user_action_correct;
                    feedback_incorrect <= !user_action_correct;

                    // Increment feedback timer
                    if (frame_tick) begin
                        feedback_timer <= feedback_timer + 1;
                    end

                    // Reset timer when leaving state
                    if (feedback_timer >= 60) begin
                        feedback_timer <= 0;
                    end
                end

                //=============================================================
                // TUTORIAL_CHECK_DONE: Check if array is fully sorted
                //=============================================================
                TUTORIAL_CHECK_DONE: begin
                    feedback_correct <= 0;
                    feedback_incorrect <= 0;

                    // Update is_sorted register based on combinational check
                    is_sorted <= array_is_sorted;

                    // Update progress and cursor position
                    if (array_is_sorted) begin
                        progress_percent <= 100;
                    end else begin
                        // Update progress percentage based on how many pairs are in order
                        // Simple approximation: count ordered pairs
                        progress_percent <=
                            ((array[0] <= array[1] ? 20 : 0) +
                             (array[1] <= array[2] ? 20 : 0) +
                             (array[2] <= array[3] ? 20 : 0) +
                             (array[3] <= array[4] ? 20 : 0) +
                             (array[4] <= array[5] ? 20 : 0));

                        // Advance bubble sort position tracker
                        if (expected_pos < pass_limit) begin
                            // Continue with current pass
                            expected_pos <= expected_pos + 1;
                        end else begin
                            // Move to next pass
                            current_pass <= current_pass + 1;
                            expected_pos <= 0;
                            // Each pass, the limit decreases by 1
                            if (pass_limit > 0) begin
                                pass_limit <= pass_limit - 1;
                            end
                        end
                    end
                end

                //=============================================================
                // TUTORIAL_COMPLETE: Success celebration
                //=============================================================
                TUTORIAL_COMPLETE: begin
                    is_sorted <= 1;
                    progress_percent <= 100;
                    feedback_correct <= 1;
                    feedback_incorrect <= 0;

                    // Animate celebration (cycle through animation frames)
                    if (frame_tick) begin
                        anim_frame <= anim_frame + 1;
                        if (anim_frame >= 31) begin
                            anim_frame <= 0;
                        end
                    end
                end

                default: begin
                    // Should never reach here
                end
            endcase
        end
    end

endmodule
