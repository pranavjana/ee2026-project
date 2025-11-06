`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.10.2025 22:22:32
// Design Name: 
// Module Name: Main_FSM
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


module Main_FSM(
    input clk_100mhz,
    input reset,                // Global reset (system disable)
    input tutorial_mode_active, // Mode flag
    input btnC_pulse,
    input btnL_pulse,
    input btnR_pulse,
    input btnU_pulse,
    input btnD_pulse,
    input sort_engine_is_sorted_flag,
    input sort_engine_is_at_start_flag,
    
    // Tutorial Sort Engine inputs
    input tut_sort_is_victory,
    input tut_sort_is_game_over,
    
    output reg [2:0] current_screen, // *** EXPANDED TO 3 BITS ***
    
    // Education Mode Outputs
    output reg sort_engine_next,
    output reg sort_engine_prev,
    output reg sort_engine_reset,
    
    // Tutorial Mode Outputs (Input phase)
    output reg tut_inc_val,
    output reg tut_dec_val,
    output reg tut_move_cursor_r,
    output reg tut_move_cursor_l,
    
    // Tutorial Mode Outputs (Sorting phase)
    output reg tut_sort_compare_left,
    output reg tut_sort_compare_right,
    output reg tut_sort_swap,
    output reg tut_sort_keep,
    output reg tut_sort_reset
);

    //==========================================================================
    // State Definitions (3 BITS - 8 STATES)
    //==========================================================================
    localparam STATE_EDU_WELCOME     = 3'b000;
    localparam STATE_EDU_SORTING     = 3'b001;
    localparam STATE_TUT_WELCOME     = 3'b010;
    localparam STATE_TUT_INPUT       = 3'b011;
    localparam STATE_TUT_READY       = 3'b100;
    localparam STATE_TUT_SORTING     = 3'b101;
    localparam STATE_TUT_GAME_OVER   = 3'b110;
    localparam STATE_TUT_VICTORY     = 3'b111;

    //==========================================================================
    // State Machine Logic
    //==========================================================================
    reg [2:0] state_reg;
    reg [2:0] next_state_comb;

    // State Register Logic
    always @(posedge clk_100mhz) begin
        if (reset) begin
            state_reg <= STATE_EDU_WELCOME;
        end else begin
            state_reg <= next_state_comb;
        end
    end

    // Combinational Logic for Next State and Outputs
    always @(*) begin
        // Default outputs
        next_state_comb = state_reg;
        sort_engine_next = 1'b0;
        sort_engine_prev = 1'b0;
        sort_engine_reset = 1'b0;
        tut_inc_val = 1'b0;
        tut_dec_val = 1'b0;
        tut_move_cursor_r = 1'b0;
        tut_move_cursor_l = 1'b0;
        tut_sort_compare_left = 1'b0;
        tut_sort_compare_right = 1'b0;
        tut_sort_swap = 1'b0;
        tut_sort_keep = 1'b0;
        tut_sort_reset = 1'b0;

        // --- MODE SWITCHING LOGIC ---
        if (tutorial_mode_active && (state_reg == STATE_EDU_WELCOME || state_reg == STATE_EDU_SORTING)) begin
            next_state_comb = STATE_TUT_WELCOME;
            sort_engine_reset = 1'b1;
        end else if (!tutorial_mode_active && (state_reg == STATE_TUT_WELCOME || 
                                                 state_reg == STATE_TUT_INPUT || 
                                                 state_reg == STATE_TUT_READY ||
                                                 state_reg == STATE_TUT_SORTING ||
                                                 state_reg == STATE_TUT_GAME_OVER ||
                                                 state_reg == STATE_TUT_VICTORY)) begin
            next_state_comb = STATE_EDU_WELCOME;
            sort_engine_reset = 1'b1;
            tut_sort_reset = 1'b1;
        // --- NORMAL STATE TRANSITIONS ---
        end else begin
            case (state_reg)
                //==============================================================
                // EDUCATION MODE STATES
                //==============================================================
                STATE_EDU_WELCOME: begin
                    if (!tutorial_mode_active && btnC_pulse) begin
                        next_state_comb = STATE_EDU_SORTING;
                        sort_engine_reset = 1'b1;
                    end
                end

                STATE_EDU_SORTING: begin
                    if (!tutorial_mode_active) begin
                        if (btnU_pulse) begin
                            next_state_comb = STATE_EDU_WELCOME;
                            sort_engine_reset = 1'b1;
                        end else if (btnR_pulse && !sort_engine_is_sorted_flag) begin
                            sort_engine_next = 1'b1;
                        end else if (btnL_pulse && !sort_engine_is_at_start_flag) begin
                            sort_engine_prev = 1'b1;
                        end
                    end
                end

                //==============================================================
                // TUTORIAL MODE STATES
                //==============================================================
                STATE_TUT_WELCOME: begin
                    if (tutorial_mode_active && btnC_pulse) begin
                        next_state_comb = STATE_TUT_INPUT;
                        tut_sort_reset = 1'b1;  // Reset tutorial engine
                    end
                end

                STATE_TUT_INPUT: begin
                    if (tutorial_mode_active) begin
                        if (btnU_pulse) begin 
                            tut_inc_val = 1'b1;
                        end else if (btnD_pulse) begin 
                            tut_dec_val = 1'b1;
                        end else if (btnR_pulse) begin 
                            tut_move_cursor_r = 1'b1;
                        end else if (btnL_pulse) begin 
                            tut_move_cursor_l = 1'b1;
                        end else if (btnC_pulse) begin
                            // Skip ready screen - go directly to sorting
                            next_state_comb = STATE_TUT_SORTING;
                            tut_sort_reset = 1'b1;
                        end
                    end
                end

                STATE_TUT_READY: begin
                    if (tutorial_mode_active) begin
                        if (btnC_pulse) begin
                            // Start sorting!
                            next_state_comb = STATE_TUT_SORTING;
                            tut_sort_reset = 1'b1;  // Initialize sorting engine
                        end else if (btnU_pulse) begin
                            // Allow going back to input
                            next_state_comb = STATE_TUT_INPUT;
                        end
                    end
                end

                STATE_TUT_SORTING: begin
                    if (tutorial_mode_active) begin
                        // Check for victory/game over from Tutorial_Sort_Engine
                        if (tut_sort_is_victory) begin
                            next_state_comb = STATE_TUT_VICTORY;
                        end else if (tut_sort_is_game_over) begin
                            next_state_comb = STATE_TUT_GAME_OVER;
                        end else begin
                            // Normal button handling during sorting
                            if (btnU_pulse) begin
                                // RESTART button - return to welcome screen
                                next_state_comb = STATE_TUT_WELCOME;
                                tut_sort_reset = 1'b1;
                            end else if (btnL_pulse) begin
                                tut_sort_compare_left = 1'b1;
                            end else if (btnR_pulse) begin
                                tut_sort_compare_right = 1'b1;
                            end else if (btnC_pulse) begin
                                tut_sort_swap = 1'b1;
                            end else if (btnD_pulse) begin
                                tut_sort_keep = 1'b1;
                            end
                        end
                    end
                end

                STATE_TUT_GAME_OVER: begin
                    if (tutorial_mode_active) begin
                        if (btnC_pulse) begin
                            next_state_comb = STATE_TUT_INPUT;
                            tut_sort_reset = 1'b1;
                        end
                    end
                end

                STATE_TUT_VICTORY: begin
                    if (tutorial_mode_active) begin
                        if (btnC_pulse) begin
                            next_state_comb = STATE_TUT_INPUT;
                            tut_sort_reset = 1'b1;
                        end
                    end
                end

                default: begin
                    next_state_comb = STATE_EDU_WELCOME;
                    sort_engine_reset = 1'b1;
                    tut_sort_reset = 1'b1;
                end
            endcase
        end
        
        // Assign registered state to output
        current_screen = state_reg;
    end

endmodule