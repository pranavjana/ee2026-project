`timescale 1ns / 1ps

module selection_sort_controller(
    input clk,
    input reset,
    input enable,
    input ctr_button,
    input sw10,
    input sw7,          // SW7 for tutorial reset
    input btnU,
    input btnD,
    input btnL,
    input btnR,
    output reg [17:0] array_flat,
    output reg [2:0] current_i,
    output reg [2:0] current_j,
    output reg [2:0] min_idx,
    output reg [1:0] wrong_attempt_count,
    output reg sorting_active,
    output reg [1:0] state_type,
    output reg sort_complete,
    output reg [2:0] intro_state,
    output reg demo_mode,
    output reg tutorial_mode,
    output reg [3:0] tutorial_state,
    output reg [2:0] selected_box,
    output reg [17:0] tutorial_array,
    output reg [11:0] tutorial_timer,
    output reg [5:0] box_confirmed,
    output reg [2:0] test_cursor_pos,
    output reg [2:0] test_unsorted_idx,
    output reg test_selecting_swap,
    output reg [2:0] user_min_selected,
    output reg [7:0] comparison_count,
    output reg [7:0] swap_count,
    output reg manual_step_mode,
    output reg [2:0] tutorial_progress,
    output reg show_swap_info
);

    // Internal array
    reg [2:0] array [0:5];
    reg [2:0] tut_array [0:5];
   

    // State definitions
    localparam IDLE = 4'd0;
    localparam INTRO_SELECTION = 4'd1;
    localparam INTRO_SORT = 4'd2;
    localparam INTRO_WAIT = 4'd3;
    localparam INIT = 4'd4;
    localparam FIND_MIN_COMPARE = 4'd5;
    localparam SHOW_MIN = 4'd6;
    localparam SHOW_SWAP = 4'd7;  // *** NEW STATE for showing swap info ***
    localparam SWAP_COMPLETE = 4'd8;
    localparam INCREMENT_I = 4'd9;
    localparam DONE = 4'd10;
    
    // Tutorial states
    localparam TUTORIAL_WELCOME = 4'd0;
    localparam TUTORIAL_TO = 4'd1;
    localparam TUTORIAL_TUTORIAL = 4'd2;
    localparam TUTORIAL_MODE = 4'd3;
    localparam TUTORIAL_ALL = 4'd4;
    localparam TUTORIAL_INPUT = 4'd5;
    localparam TUTORIAL_BEGIN = 4'd6;
    localparam TUTORIAL_TEST_INIT = 4'd7;
    localparam TUTORIAL_FIND_MIN = 4'd8;
    localparam TUTORIAL_SELECT_SWAP = 4'd9;
    localparam TUTORIAL_CORRECT = 4'd10;
    localparam TUTORIAL_WRONG = 4'd11;
    localparam TUTORIAL_WELL_DONE = 4'd12;
    localparam TUTORIAL_FAILED = 4'd13;  // NEW STATE
    
    // Timing parameters
    localparam CLKS_PER_HALF_SEC = 500;
    localparam CLKS_PER_1_SEC = 1000;
    localparam CLKS_PER_2_SEC = 2000;
    localparam SORT_STEP_DELAY = 500;
    localparam BUTTON_DEBOUNCE = 10;
    localparam FEEDBACK_DISPLAY_TIME = 1000;
    localparam CLKS_PER_FAILED_DISPLAY = 2000;  // 2 seconds for FAILED message
    
    reg [3:0] state, next_state;
    reg [2:0] swap_temp;
    reg prev_enable;
    reg [25:0] intro_timer;
    reg [9:0] sort_delay_counter;
    reg prev_ctr_button;
    reg prev_sw10;
    reg prev_sw7;
    reg prev_btnU_demo;
    reg [1:0] wrong_attempt_count;  // Track number of wrong attempts (0-3)
    wire delay_complete;
    
    // Tutorial mode timing and button debouncing
    reg [7:0] btnU_debounce, btnD_debounce, btnL_debounce, btnR_debounce, btnC_debounce_tut;
    reg prev_btnU_debounced, prev_btnD_debounced, prev_btnL_debounced, prev_btnR_debounced, prev_btnC_debounced;
    
    // NEW: RIGHT button debouncing for demo mode manual stepping
    reg [7:0] btnR_debounce_demo;
    reg prev_btnR_demo;
    
    // Tutorial test variables
    reg [2:0] actual_min_idx;
    reg [10:0] feedback_timer;
    
    assign delay_complete = (sort_delay_counter >= SORT_STEP_DELAY);
    
    // Button debounced signals
    wire btnU_debounced = (btnU_debounce >= BUTTON_DEBOUNCE);
    wire btnD_debounced = (btnD_debounce >= BUTTON_DEBOUNCE);
    wire btnL_debounced = (btnL_debounce >= BUTTON_DEBOUNCE);
    wire btnR_debounced = (btnR_debounce >= BUTTON_DEBOUNCE);
    wire btnC_debounced_tut = (btnC_debounce_tut >= BUTTON_DEBOUNCE);
    
    // Edge detection
    wire btnU_pressed = btnU_debounced && !prev_btnU_debounced;
    wire btnD_pressed = btnD_debounced && !prev_btnD_debounced;
    wire btnL_pressed = btnL_debounced && !prev_btnL_debounced;
    wire btnR_pressed = btnR_debounced && !prev_btnR_debounced;
    wire btnC_pressed_tut = btnC_debounced_tut && !prev_btnC_debounced;
    
    wire btnU_pressed_demo = btnU && !prev_btnU_demo;
    
    // NEW: Edge detection for RIGHT button manual stepping (demo mode)
    wire btnR_debounced_demo = (btnR_debounce_demo >= BUTTON_DEBOUNCE);
    wire btnR_pressed_demo = btnR_debounced_demo && !prev_btnR_demo;
    
    wire all_boxes_confirmed = (box_confirmed == 6'b111111);
    
    // Combinational logic to find minimum
    reg [2:0] calculated_min_idx;
    always @(*) begin
        calculated_min_idx = test_unsorted_idx;
        
        case (test_unsorted_idx)
            3'd0: begin
                calculated_min_idx = 0;
                if (tut_array[1] < tut_array[calculated_min_idx]) calculated_min_idx = 1;
                if (tut_array[2] < tut_array[calculated_min_idx]) calculated_min_idx = 2;
                if (tut_array[3] < tut_array[calculated_min_idx]) calculated_min_idx = 3;
                if (tut_array[4] < tut_array[calculated_min_idx]) calculated_min_idx = 4;
                if (tut_array[5] < tut_array[calculated_min_idx]) calculated_min_idx = 5;
            end
            3'd1: begin
                calculated_min_idx = 1;
                if (tut_array[2] < tut_array[calculated_min_idx]) calculated_min_idx = 2;
                if (tut_array[3] < tut_array[calculated_min_idx]) calculated_min_idx = 3;
                if (tut_array[4] < tut_array[calculated_min_idx]) calculated_min_idx = 4;
                if (tut_array[5] < tut_array[calculated_min_idx]) calculated_min_idx = 5;
            end
            3'd2: begin
                calculated_min_idx = 2;
                if (tut_array[3] < tut_array[calculated_min_idx]) calculated_min_idx = 3;
                if (tut_array[4] < tut_array[calculated_min_idx]) calculated_min_idx = 4;
                if (tut_array[5] < tut_array[calculated_min_idx]) calculated_min_idx = 5;
            end
            3'd3: begin
                calculated_min_idx = 3;
                if (tut_array[4] < tut_array[calculated_min_idx]) calculated_min_idx = 4;
                if (tut_array[5] < tut_array[calculated_min_idx]) calculated_min_idx = 5;
            end
            3'd4: begin
                calculated_min_idx = 4;
                if (tut_array[5] < tut_array[calculated_min_idx]) calculated_min_idx = 5;
            end
            3'd5: begin
                calculated_min_idx = 5;
            end
            default: calculated_min_idx = test_unsorted_idx;
        endcase
    end
    
    // Initialize array
    initial begin
        array[0] = 3'd0;
        array[1] = 3'd3;
        array[2] = 3'd1;
        array[3] = 3'd4;
        array[4] = 3'd2;
        array[5] = 3'd5;
        tut_array[0] = 3'd0;
        tut_array[1] = 3'd0;
        tut_array[2] = 3'd0;
        tut_array[3] = 3'd0;
        tut_array[4] = 3'd0;
        tut_array[5] = 3'd0;
        show_swap_info = 0;
    end
    
    // State machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            current_i <= 0;
            current_j <= 0;
            min_idx <= 0;
            sorting_active <= 0;
            state_type <= 0;
            sort_complete <= 0;
            prev_enable <= 0;
            swap_temp <= 0;
            intro_state <= 0;
            intro_timer <= 0;
            prev_ctr_button <= 0;
            prev_sw10 <= 0;
            prev_sw7 <= 0;
            prev_btnU_demo <= 0;
            demo_mode <= 0;
            tutorial_mode <= 0;
            tutorial_state <= 0;
            tutorial_timer <= 0;
            selected_box <= 0;
            sort_delay_counter <= 0;
            btnU_debounce <= 0;
            btnD_debounce <= 0;
            btnL_debounce <= 0;
            btnR_debounce <= 0;
            btnC_debounce_tut <= 0;
            prev_btnU_debounced <= 0;
            prev_btnD_debounced <= 0;
            prev_btnL_debounced <= 0;
            prev_btnR_debounced <= 0;
            prev_btnC_debounced <= 0;
            box_confirmed <= 6'b000000;
            test_cursor_pos <= 0;
            test_unsorted_idx <= 0;
            test_selecting_swap <= 0;
            user_min_selected <= 0;
            actual_min_idx <= 0;
            feedback_timer <= 0;
            comparison_count <= 0;
            swap_count <= 0;
            manual_step_mode <= 0;
            tutorial_progress <= 0;
            btnR_debounce_demo <= 0;
            prev_btnR_demo <= 0;
            show_swap_info <= 0;
            wrong_attempt_count <= 0;
            array[0] <= 3'd0;
            array[1] <= 3'd3;
            array[2] <= 3'd1;
            array[3] <= 3'd4;
            array[4] <= 3'd2;
            array[5] <= 3'd5;
            tut_array[0] <= 3'd0;
            tut_array[1] <= 3'd0;
            tut_array[2] <= 3'd0;
            tut_array[3] <= 3'd0;
            tut_array[4] <= 3'd0;
            tut_array[5] <= 3'd0;
        end else begin
            prev_enable <= enable;
            prev_ctr_button <= ctr_button;
            prev_sw10 <= sw10;
            prev_sw7 <= sw7;
            prev_btnU_demo <= btnU;
            
            prev_btnU_debounced <= btnU_debounced;
            prev_btnD_debounced <= btnD_debounced;
            prev_btnL_debounced <= btnL_debounced;
            prev_btnR_debounced <= btnR_debounced;
            prev_btnC_debounced <= btnC_debounced_tut;
            
            // NEW: Track RIGHT button for demo mode
            prev_btnR_demo <= btnR_debounced_demo;
            
            // Button debouncing
            if (btnU) begin
                if (btnU_debounce < BUTTON_DEBOUNCE + 10)
                    btnU_debounce <= btnU_debounce + 1;
            end else begin
                btnU_debounce <= 0;
            end
            
            if (btnD) begin
                if (btnD_debounce < BUTTON_DEBOUNCE + 10)
                    btnD_debounce <= btnD_debounce + 1;
            end else begin
                btnD_debounce <= 0;
            end
            
            if (btnL) begin
                if (btnL_debounce < BUTTON_DEBOUNCE + 10)
                    btnL_debounce <= btnL_debounce + 1;
            end else begin
                btnL_debounce <= 0;
            end
            
            if (btnR) begin
                if (btnR_debounce < BUTTON_DEBOUNCE + 10)
                    btnR_debounce <= btnR_debounce + 1;
            end else begin
                btnR_debounce <= 0;
            end
            
            if (ctr_button) begin
                if (btnC_debounce_tut < BUTTON_DEBOUNCE + 10)
                    btnC_debounce_tut <= btnC_debounce_tut + 1;
            end else begin
                btnC_debounce_tut <= 0;
            end
            
            // NEW: Debounce RIGHT button for demo mode manual stepping
            if (btnR) begin
                if (btnR_debounce_demo < BUTTON_DEBOUNCE + 10)
                    btnR_debounce_demo <= btnR_debounce_demo + 1;
            end else begin
                btnR_debounce_demo <= 0;
            end
            
            // ========== TUTORIAL MODE LOGIC ==========
            if (enable && sw10) begin
                // NEW: Auto-reset demo mode when entering tutorial from demo
                // This ensures demo restarts from intro when user returns
                if (!prev_sw10) begin
                    // Coming from demo mode - reset demo state
                    state <= INTRO_SELECTION;
                    intro_timer <= 0;
                    intro_state <= 0;
                    current_i <= 0;
                    current_j <= 0;
                    min_idx <= 0;
                    sorting_active <= 0;
                    state_type <= 0;
                    sort_complete <= 0;
                    demo_mode <= 0;
                    sort_delay_counter <= 0;
                    show_swap_info <= 0;
                    array[0] <= 3'd0;
                    array[1] <= 3'd3;
                    array[2] <= 3'd1;
                    array[3] <= 3'd4;
                    array[4] <= 3'd2;
                    array[5] <= 3'd5;
                end
                
                // SW7 RESET FOR TUTORIAL MODE
                if (sw7) begin
                    tutorial_mode <= 1;
                    tutorial_state <= TUTORIAL_WELCOME;
                    tutorial_timer <= 0;
                    selected_box <= 0;
                    box_confirmed <= 6'b000000;
                    test_cursor_pos <= 0;
                    test_unsorted_idx <= 0;
                    test_selecting_swap <= 0;
                    user_min_selected <= 0;
                    actual_min_idx <= 0;
                    feedback_timer <= 0;
                    sort_complete <= 0;
                    tutorial_progress <= 0; 
                    wrong_attempt_count <= 0; 
                    tut_array[0] <= 3'd0;
                    tut_array[1] <= 3'd0;
                    tut_array[2] <= 3'd0;
                    tut_array[3] <= 3'd0;
                    tut_array[4] <= 3'd0;
                    tut_array[5] <= 3'd0;
                end else begin
                    tutorial_mode <= 1;
                    demo_mode <= 0;
                    sorting_active <= 0;
                    sort_complete <= 0;
                    intro_state <= 3'd3;
                    
                    if (tutorial_state == TUTORIAL_WELCOME) begin
                        tutorial_timer <= tutorial_timer + 1;
                        if (tutorial_timer >= CLKS_PER_HALF_SEC) begin
                            tutorial_state <= TUTORIAL_TO;
                            tutorial_timer <= 0;
                        end
                    end else if (tutorial_state == TUTORIAL_TO) begin
                        tutorial_timer <= tutorial_timer + 1;
                        if (tutorial_timer >= CLKS_PER_HALF_SEC) begin
                            tutorial_state <= TUTORIAL_TUTORIAL;
                            tutorial_timer <= 0;
                        end
                    end else if (tutorial_state == TUTORIAL_TUTORIAL) begin
                        tutorial_timer <= tutorial_timer + 1;
                        if (tutorial_timer >= CLKS_PER_HALF_SEC) begin
                            tutorial_state <= TUTORIAL_MODE;
                            tutorial_timer <= 0;
                        end
                    end else if (tutorial_state == TUTORIAL_MODE) begin
                        tutorial_timer <= tutorial_timer + 1;
                        if (tutorial_timer >= CLKS_PER_HALF_SEC) begin
                            tutorial_state <= TUTORIAL_ALL;
                            tutorial_timer <= 0;
                        end
                    end else if (tutorial_state == TUTORIAL_ALL) begin
                        tutorial_timer <= tutorial_timer + 1;
                        if (tutorial_timer >= CLKS_PER_2_SEC) begin
                            tutorial_state <= TUTORIAL_INPUT;
                            tutorial_timer <= 0;
                        end
                    end else if (tutorial_state == TUTORIAL_INPUT) begin
                        if (btnU_pressed && !box_confirmed[selected_box]) begin
                            if (tut_array[selected_box] < 3'd7)
                                tut_array[selected_box] <= tut_array[selected_box] + 1;
                            else
                                tut_array[selected_box] <= 3'd0;
                        end
                        
                        if (btnD_pressed && !box_confirmed[selected_box]) begin
                            if (tut_array[selected_box] > 3'd0)
                                tut_array[selected_box] <= tut_array[selected_box] - 1;
                            else
                                tut_array[selected_box] <= 3'd7;
                        end
                        
                        if (btnL_pressed) begin
                            if (selected_box > 0)
                                selected_box <= selected_box - 1;
                            else
                                selected_box <= 3'd5;
                        end
                        
                        if (btnR_pressed) begin
                            if (selected_box < 5)
                                selected_box <= selected_box + 1;
                            else
                                selected_box <= 3'd0;
                        end
                        
                        if (btnC_pressed_tut) begin
                            box_confirmed[selected_box] <= ~box_confirmed[selected_box];
                        end
                        
                        if (all_boxes_confirmed) begin
                            tutorial_state <= TUTORIAL_BEGIN;
                            tutorial_timer <= 0;
                        end
                        
                    end else if (tutorial_state == TUTORIAL_BEGIN) begin
                        tutorial_timer <= tutorial_timer + 1;
                        if (tutorial_timer >= CLKS_PER_1_SEC) begin
                            tutorial_state <= TUTORIAL_TEST_INIT;
                            tutorial_timer <= 0;
                            test_unsorted_idx <= 0;
                            test_cursor_pos <= 0;
                            test_selecting_swap <= 0;
                        end
                        
                    end else if (tutorial_state == TUTORIAL_TEST_INIT) begin
                        tutorial_timer <= tutorial_timer + 1;
                        if (tutorial_timer >= CLKS_PER_HALF_SEC) begin
                            tutorial_state <= TUTORIAL_FIND_MIN;
                            tutorial_timer <= 0;
                            test_cursor_pos <= test_unsorted_idx;
                        end
                        
                    end else if (tutorial_state == TUTORIAL_FIND_MIN) begin
                        test_selecting_swap <= 0;
                        
                        if (btnL_pressed && test_cursor_pos > test_unsorted_idx) begin
                            test_cursor_pos <= test_cursor_pos - 1;
                        end
                        
                        if (btnR_pressed && test_cursor_pos < 5) begin
                            test_cursor_pos <= test_cursor_pos + 1;
                        end
                        
                        if (btnC_pressed_tut) begin
                            user_min_selected <= test_cursor_pos;
                            tutorial_state <= TUTORIAL_SELECT_SWAP;
                        end
                        
                    end else if (tutorial_state == TUTORIAL_SELECT_SWAP) begin
                        test_selecting_swap <= 1;
                        
                        if (btnL_pressed && test_cursor_pos > 0) begin
                            test_cursor_pos <= test_cursor_pos - 1;
                        end
                        
                        if (btnR_pressed && test_cursor_pos < 5) begin
                            test_cursor_pos <= test_cursor_pos + 1;
                        end
                        
                        if (btnC_pressed_tut) begin
                            actual_min_idx <= calculated_min_idx;
                            
                            if ((tut_array[user_min_selected] == tut_array[calculated_min_idx]) && 
                                (test_cursor_pos == test_unsorted_idx)) begin
                                tutorial_state <= TUTORIAL_CORRECT;
                                feedback_timer <= 0;
                            end else begin
                                tutorial_state <= TUTORIAL_WRONG;
                                feedback_timer <= 0;
                            end
                        end
                        
                    end else if (tutorial_state == TUTORIAL_CORRECT) begin
                        feedback_timer <= feedback_timer + 1;
                        
                        if (feedback_timer == 1) begin
                            tut_array[test_unsorted_idx] <= tut_array[user_min_selected];
                            tut_array[user_min_selected] <= tut_array[test_unsorted_idx];
                            tutorial_progress <= tutorial_progress + 1;
                            
                            
                        end
                        
                        if (feedback_timer >= FEEDBACK_DISPLAY_TIME) begin
                            test_unsorted_idx <= test_unsorted_idx + 1;
                            
                            if (test_unsorted_idx >= 5) begin
                                tutorial_state <= TUTORIAL_WELL_DONE;
                                tutorial_timer <= 0;
                            end else begin
                                tutorial_state <= TUTORIAL_FIND_MIN;
                                test_cursor_pos <= test_unsorted_idx + 1;
                                feedback_timer <= 0;
                            end
                        end
                        
                   end else if (tutorial_state == TUTORIAL_WRONG) begin
                            feedback_timer <= feedback_timer + 1;
                            
                            // Increment wrong attempt counter when entering this state
                            if (feedback_timer == 1) begin
                                wrong_attempt_count <= wrong_attempt_count + 1;
                            end
                            
                            if (feedback_timer >= FEEDBACK_DISPLAY_TIME) begin
                                // Check if user has failed 3 times
                                if (wrong_attempt_count >= 2'd3) begin
                                    tutorial_state <= TUTORIAL_FAILED;
                                    tutorial_timer <= 0;
                                    feedback_timer <= 0;
                                end else begin
                                    // Continue with normal flow
                                    tutorial_state <= TUTORIAL_FIND_MIN;
                                    test_cursor_pos <= test_unsorted_idx;
                                    feedback_timer <= 0;
                                end
                            end
                            end else if (tutorial_state == TUTORIAL_FAILED) begin
                                tutorial_timer <= tutorial_timer + 1;
                                
                                if (tutorial_timer >= CLKS_PER_FAILED_DISPLAY) begin
                                    // Reset back to INPUT NUM screen
                                    tutorial_state <= TUTORIAL_INPUT;
                                    tutorial_timer <= 0;
                                    selected_box <= 0;
                                    box_confirmed <= 6'b000000;
                                    test_cursor_pos <= 0;
                                    test_unsorted_idx <= 0;
                                    test_selecting_swap <= 0;
                                    user_min_selected <= 0;
                                    actual_min_idx <= 0;
                                    feedback_timer <= 0;
                                    tutorial_progress <= 0;
                                    wrong_attempt_count <= 0;  // Reset counter
                                    
                                    // Clear the array
                                    tut_array[0] <= 3'd0;
                                    tut_array[1] <= 3'd0;
                                    tut_array[2] <= 3'd0;
                                    tut_array[3] <= 3'd0;
                                    tut_array[4] <= 3'd0;
                                    tut_array[5] <= 3'd0;
                                end
                        
                    end else if (tutorial_state == TUTORIAL_WELL_DONE) begin
                        tutorial_timer <= tutorial_timer + 1;
                        sort_complete <= 1;
                         if (tutorial_timer == 1) begin
                               wrong_attempt_count <= 0;
                               end
                    end
                end
                
                if (!sw10 && prev_sw10) begin
                    tutorial_mode <= 0;
                    tutorial_state <= TUTORIAL_WELCOME;
                    tutorial_timer <= 0;
                    selected_box <= 0;
                    box_confirmed <= 6'b000000;
                    test_cursor_pos <= 0;
                    test_unsorted_idx <= 0;
                    test_selecting_swap <= 0;
                    tutorial_progress <= 0; 
                    tut_array[0] <= 3'd0;
                    tut_array[1] <= 3'd0;
                    tut_array[2] <= 3'd0;
                    tut_array[3] <= 3'd0;
                    tut_array[4] <= 3'd0;
                    tut_array[5] <= 3'd0;
                end
                
            // ========== DEMO MODE LOGIC ==========
            end else if (enable && !sw10) begin
                tutorial_mode <= 0;
                
                // Reset tutorial mode variables when leaving tutorial
                if (prev_sw10) begin
                    tutorial_state <= TUTORIAL_WELCOME;
                    tutorial_timer <= 0;
                    selected_box <= 0;
                    box_confirmed <= 6'b000000;
                    test_cursor_pos <= 0;
                    test_unsorted_idx <= 0;
                    test_selecting_swap <= 0;
                    tutorial_progress <= 0; 
                    tut_array[0] <= 3'd0;
                    tut_array[1] <= 3'd0;
                    tut_array[2] <= 3'd0;
                    tut_array[3] <= 3'd0;
                    tut_array[4] <= 3'd0;
                    tut_array[5] <= 3'd0;
                    
                    // NEW: Auto-reset demo mode when SW10 is toggled OFF
                    // This allows user to return to tutorial, then come back to a fresh demo
                    state <= INTRO_SELECTION;
                    intro_timer <= 0;
                    intro_state <= 0;
                    current_i <= 0;
                    current_j <= 0;
                    min_idx <= 0;
                    sorting_active <= 0;
                    state_type <= 0;
                    sort_complete <= 0;
                    demo_mode <= 0;
                    sort_delay_counter <= 0;
                    show_swap_info <= 0;
                    array[0] <= 3'd0;
                    array[1] <= 3'd3;
                    array[2] <= 3'd1;
                    array[3] <= 3'd4;
                    array[4] <= 3'd2;
                    array[5] <= 3'd5;
                end
                
                // Center button resets demo back to intro screen (not start sorting)
                if (ctr_button && !prev_ctr_button && 
                    (state != INTRO_WAIT) && (state != INTRO_SELECTION) && (state != INTRO_SORT)) begin
                    state <= INTRO_SELECTION;
                    intro_timer <= 0;
                    intro_state <= 0;
                    current_i <= 0;
                    current_j <= 0;
                    min_idx <= 0;
                    sorting_active <= 0;
                    state_type <= 0;
                    sort_complete <= 0;
                    demo_mode <= 0;
                    sort_delay_counter <= 0;
                    comparison_count <= 0;
                    swap_count <= 0;
                    manual_step_mode <= 0;
                    show_swap_info <= 0;
                    array[0] <= 3'd0;
                    array[1] <= 3'd3;
                    array[2] <= 3'd1;
                    array[3] <= 3'd4;
                    array[4] <= 3'd2;
                    array[5] <= 3'd5;
                end
                else if (!prev_enable) begin
                    state <= INTRO_SELECTION;
                    intro_timer <= 0;
                    intro_state <= 0;
                    current_i <= 0;
                    current_j <= 0;
                    min_idx <= 0;
                    sort_complete <= 0;
                    demo_mode <= 0;
                    sort_delay_counter <= 0;
                    comparison_count <= 0;
                    swap_count <= 0;
                    manual_step_mode <= 0;
                    show_swap_info <= 0;
                    array[0] <= 3'd0;
                    array[1] <= 3'd3;
                    array[2] <= 3'd1;
                    array[3] <= 3'd4;
                    array[4] <= 3'd2;
                    array[5] <= 3'd5;
                end else begin
                    if (state != next_state) begin
                        state <= next_state;
                        intro_timer <= 0;
                        sort_delay_counter <= 0;
                    end else begin
                        if (state == INTRO_SELECTION || state == INTRO_SORT) begin
                            intro_timer <= intro_timer + 1;
                        end
                        
                        if (state == INIT || state == FIND_MIN_COMPARE || 
                            state == SHOW_MIN || state == SHOW_SWAP ||
                            state == SWAP_COMPLETE || state == INCREMENT_I) begin
                            sort_delay_counter <= sort_delay_counter + 1;
                        end
                    end
                end
                
                case (state)
                    IDLE: begin
                        sorting_active <= 0;
                        state_type <= 0;
                        intro_state <= 0;
                        demo_mode <= 0;
                        sort_complete <= 0;
                        show_swap_info <= 0;
                    end
                    
                    INTRO_SELECTION: begin
                        intro_state <= 3'd0;
                        sorting_active <= 0;
                        sort_complete <= 0;
                        show_swap_info <= 0;
                    end
                    
                    INTRO_SORT: begin
                        intro_state <= 3'd1;
                        sorting_active <= 0;
                        sort_complete <= 0;
                        show_swap_info <= 0;
                    end
                    
                    INTRO_WAIT: begin
                        intro_state <= 3'd2;
                        sorting_active <= 0;
                        sort_complete <= 0;
                        show_swap_info <= 0;
                        if (btnU_pressed_demo) begin
                            demo_mode <= 1;
                        end
                    end
                    
                    INIT: begin
                        show_swap_info <= 0;
                        if (delay_complete) begin
                            sorting_active <= 1;
                            intro_state <= 3'd3;
                            min_idx <= current_i;
                            current_j <= current_i + 1;
                            state_type <= 1;
                            sort_complete <= 0;
                            manual_step_mode <= 1;  // Enable manual stepping
                        end
                    end
                    
                    FIND_MIN_COMPARE: begin
                        state_type <= 1;
                        sort_complete <= 0;
                        show_swap_info <= 0;  // Ensure swap info hidden during comparison
                        if (delay_complete) begin
                            // Only compare if current_j is within array bounds
                            if (current_j < 6) begin
                                comparison_count <= comparison_count + 1;
                                if (array[current_j] < array[min_idx]) begin
                                    min_idx <= current_j;
                                end
                            end
                            current_j <= current_j + 1;
                            sort_delay_counter <= 0;
                        end
                    end
                    
                    SHOW_MIN: begin
                        state_type <= 2;  // Set to swap mode  
                        sort_complete <= 0;
                        show_swap_info <= 0;  // *** SHOW "MIN : X" FIRST ***
                        // Wait for RIGHT button - handled in next_state logic
                    end
                    
                    SHOW_SWAP: begin
                        state_type <= 2;  // Keep swap mode
                        sort_complete <= 0;
                        show_swap_info <= 1;  // *** NOW SHOW SWAP INFO ***
                        // Save swap_temp when entering this state
                        if (current_i != min_idx) begin
                            swap_temp <= array[current_i];
                        end
                        // Wait for RIGHT button - handled in next_state logic
                    end
                    
                    SWAP_COMPLETE: begin
                        sort_complete <= 0;
                        show_swap_info <= 0;  // Hide swap info after swap completes
                        if (delay_complete) begin
                            state_type <= 0;  // Reset state_type
                            // Only perform swap if needed
                            if (current_i != min_idx) begin
                                array[current_i] <= array[min_idx];
                                array[min_idx] <= swap_temp;
                                swap_count <= swap_count + 1;
                            end
                        end
                    end
                    
                    INCREMENT_I: begin
                        sort_complete <= 0;
                        state_type <= 0;  
                        show_swap_info <= 0;
                        if (delay_complete && btnR_pressed_demo) begin
                            current_i <= current_i + 1;
                        end
                    end
                    
                    DONE: begin
                        sorting_active <= 0;
                        state_type <= 3;
                        sort_complete <= 1;
                        show_swap_info <= 0;
                    end
                endcase
                
            end else if (!enable) begin
                state <= IDLE;
                sort_complete <= 0;
                intro_state <= 0;
                intro_timer <= 0;
                demo_mode <= 0;
                tutorial_mode <= 0;
                tutorial_state <= TUTORIAL_WELCOME;
                tutorial_timer <= 0;
                selected_box <= 0;
                box_confirmed <= 6'b000000;
                sort_delay_counter <= 0;
                test_cursor_pos <= 0;
                test_unsorted_idx <= 0;
                test_selecting_swap <= 0;
                tutorial_progress <= 0;
                show_swap_info <= 0;
            end
        end
    end
    
    // Next state logic (COMBINATIONAL BLOCK)
    always @(*) begin
        case (state)
            IDLE: begin
                next_state = IDLE;
            end
            
            INTRO_SELECTION: begin
                if (intro_timer >= CLKS_PER_HALF_SEC)
                    next_state = INTRO_SORT;
                else
                    next_state = INTRO_SELECTION;
            end
            
            INTRO_SORT: begin
                if (intro_timer >= CLKS_PER_HALF_SEC)
                    next_state = INTRO_WAIT;
                else
                    next_state = INTRO_SORT;
            end
            
            INTRO_WAIT: begin
                if (btnU_pressed_demo)
                    next_state = INIT;
                else
                    next_state = INTRO_WAIT;
            end
            
            INIT: begin
                if (delay_complete)
                    next_state = FIND_MIN_COMPARE;
                else
                    next_state = INIT;
            end
            
            FIND_MIN_COMPARE: begin
                if (delay_complete) begin
                    if (current_j >= 6)
                        next_state = SHOW_MIN;
                    else
                        next_state = FIND_MIN_COMPARE;
                end else
                    next_state = FIND_MIN_COMPARE;
            end
            
            SHOW_MIN: begin
                // *** Wait for RIGHT button to show "MIN : X" ***
                if (btnR_pressed_demo)
                    next_state = SHOW_SWAP;  // Go to show swap info state
                else
                    next_state = SHOW_MIN;  // Wait for button
            end
            
            SHOW_SWAP: begin
                // *** Wait for RIGHT button before proceeding ***
                if (btnR_pressed_demo) begin
                    if (current_i == min_idx)
                        next_state = INCREMENT_I;  // No swap needed, skip SWAP_COMPLETE
                    else
                        next_state = SWAP_COMPLETE;  // Swap needed
                end else
                    next_state = SHOW_SWAP;  // Stay until button pressed
            end
            
            SWAP_COMPLETE: begin
                if (delay_complete)
                    next_state = INCREMENT_I;
                else
                    next_state = SWAP_COMPLETE;
            end
            
            INCREMENT_I: begin
                if (delay_complete) begin
                    // In manual mode, wait for RIGHT button press to proceed to next iteration
                    if (!manual_step_mode || btnR_pressed_demo) begin
                        if (current_i < 5)  // Sort through index 5
                            next_state = INIT;
                        else
                            next_state = DONE;
                    end else begin
                        next_state = INCREMENT_I;  // Stay until button pressed
                    end
                end else
                    next_state = INCREMENT_I;
            end
            
            DONE: begin
                next_state = DONE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Pack arrays
    always @(*) begin
        array_flat[17:15] = array[5];
        array_flat[14:12] = array[4];
        array_flat[11:9]  = array[3];
        array_flat[8:6]   = array[2];
        array_flat[5:3]   = array[1];
        array_flat[2:0]   = array[0];
        
        tutorial_array[17:15] = tut_array[5];
        tutorial_array[14:12] = tut_array[4];
        tutorial_array[11:9]  = tut_array[3];
        tutorial_array[8:6]   = tut_array[2];
        tutorial_array[5:3]   = tut_array[1];
        tutorial_array[2:0]   = tut_array[0];
    end

endmodule