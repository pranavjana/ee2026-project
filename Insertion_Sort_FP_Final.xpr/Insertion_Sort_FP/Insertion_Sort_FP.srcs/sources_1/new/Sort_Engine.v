`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.10.2025 22:22:32
// Design Name: 
// Module Name: Sort_Engine
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


module Sort_Engine(
    input clk_100mhz,
    input reset,
    input next_step_pulse,
    input prev_step_pulse,
    output reg [2:0] current_array_0,
    output reg [2:0] current_array_1,
    output reg [2:0] current_array_2,
    output reg [2:0] current_array_3,
    output reg [2:0] current_array_4,
    output reg [2:0] current_array_5,
    output reg [2:0] red_line_pos,
    output reg [2:0] compare_idx1,
    output reg [2:0] compare_idx2,
    output reg [2:0] swap_idx1,
    output reg [2:0] swap_idx2,
    output reg is_sorted_flag,
    output reg is_at_start_flag
);

    // History buffer
    localparam HISTORY_DEPTH = 32;
    reg [2:0] history_array_0 [0:HISTORY_DEPTH-1];
    reg [2:0] history_array_1 [0:HISTORY_DEPTH-1];
    reg [2:0] history_array_2 [0:HISTORY_DEPTH-1];
    reg [2:0] history_array_3 [0:HISTORY_DEPTH-1];
    reg [2:0] history_array_4 [0:HISTORY_DEPTH-1];
    reg [2:0] history_array_5 [0:HISTORY_DEPTH-1];

    reg [2:0] history_red_line [0:HISTORY_DEPTH-1];
    reg [2:0] history_i_index [0:HISTORY_DEPTH-1];
    reg [2:0] history_j_index [0:HISTORY_DEPTH-1];
    reg [4:0] history_pointer;

    // --- ADDED: History for color flags ---
    reg [2:0] history_compare_idx1 [0:HISTORY_DEPTH-1]; // <-- ADDED
    reg [2:0] history_compare_idx2 [0:HISTORY_DEPTH-1]; // <-- ADDED
    reg [2:0] history_swap_idx1 [0:HISTORY_DEPTH-1];    // <-- ADDED
    reg [2:0] history_swap_idx2 [0:HISTORY_DEPTH-1];    // <-- ADDED
    reg       history_is_comparing [0:HISTORY_DEPTH-1]; // <-- ADDED

    // FSM state registers for Insertion Sort
    reg [2:0] i_index; // Outer loop (partition), from 1 to 5
    reg [2:0] j_index; // Inner loop (swap), from i down to 1
    
    reg is_comparing; // <-- ADDED: FSM state for 2-step compare/act

    // Step delay for showing swap (blue)
    localparam SWAP_DELAY_CYCLES = 25'd25_000_000; 
    reg [24:0] step_delay;
    reg showing_swap;
    
    // Temporary registers for swapping
    reg [2:0] temp_val1, temp_val2;
    
    // Helper to save history
    task save_history;
        begin
            history_array_0[history_pointer] <= current_array_0;
            history_array_1[history_pointer] <= current_array_1;
            history_array_2[history_pointer] <= current_array_2;
            history_array_3[history_pointer] <= current_array_3;
            history_array_4[history_pointer] <= current_array_4;
            history_array_5[history_pointer] <= current_array_5;
            history_red_line[history_pointer] <= red_line_pos;
            history_i_index[history_pointer]  <= i_index;
            history_j_index[history_pointer]  <= j_index;

            // --- ADDED: Save color flags to history ---
            history_compare_idx1[history_pointer] <= compare_idx1; // <-- ADDED
            history_compare_idx2[history_pointer] <= compare_idx2; // <-- ADDED
            history_swap_idx1[history_pointer]    <= swap_idx1;    // <-- ADDED
            history_swap_idx2[history_pointer]    <= swap_idx2;    // <-- ADDED
            history_is_comparing[history_pointer] <= is_comparing; // <-- ADDED
            
            if (history_pointer < HISTORY_DEPTH - 1)
                history_pointer <= history_pointer + 1;
        end
    endtask
    
    // Combinational 'read' logic to access array elements by index
    wire [2:0] array_read [0:5];
    assign array_read[0] = current_array_0;
    assign array_read[1] = current_array_1;
    assign array_read[2] = current_array_2;
    assign array_read[3] = current_array_3;
    assign array_read[4] = current_array_4;
    assign array_read[5] = current_array_5;

    always @(posedge clk_100mhz) begin
        if (reset) begin
            // Initialize array (Verilog-2001 compatible)
            current_array_0 <= 3'd0;
            current_array_1 <= 3'd3;
            current_array_2 <= 3'd1;
            current_array_3 <= 3'd4;
            current_array_4 <= 3'd2;
            current_array_5 <= 3'd5;
            
            // Initialize FSM state
            red_line_pos <= 3'd1;
            i_index <= 3'd1; // Outer loop starts at 1
            j_index <= 3'd1; // Inner loop starts at 1
            is_comparing <= 0; // <-- ADDED
            
            // Clear comparison/swap flags (7 is invalid index)
            compare_idx1 <= 3'd7;
            compare_idx2 <= 3'd7;
            swap_idx1 <= 3'd7;
            swap_idx2 <= 3'd7;
            
            // Reset flags and history
            is_sorted_flag <= 0;
            is_at_start_flag <= 1;
            history_pointer <= 0;
            step_delay <= 0;
            showing_swap <= 0;
            
        end else if (showing_swap) begin
            // We are in the middle of a swap animation
            if (step_delay < SWAP_DELAY_CYCLES) begin
                step_delay <= step_delay + 1;
            end else begin
                // Animation finished, clear flags
                swap_idx1 <= 3'd7;
                swap_idx2 <= 3'd7;
                showing_swap <= 0;
                step_delay <= 0;
            end
            
        end else if (next_step_pulse && !is_sorted_flag) begin
            // --- MAIN FSM LOGIC ---
            
            // Save current state BEFORE processing the step
            save_history();
            is_at_start_flag <= 0;
            
            // Default: clear swap flags
            swap_idx1 <= 3'd7;
            swap_idx2 <= 3'd7;

            // --- CHANGED: Two-step compare/act logic ---
            if (!is_comparing) begin
                // --- STEP 1: SHOW COMPARISON (YELLOW) ---
                is_comparing <= 1; // Now we are in "comparing" state
                
                // Set comparison flags for this step
                compare_idx1 <= j_index - 1;
                compare_idx2 <= j_index;

            end else begin
                // --- STEP 2: ACT ON COMPARISON (SWAP/ADVANCE) ---
                is_comparing <= 0; // Go back to "idle" state
                
                // Read values for comparison
                temp_val1 = array_read[j_index - 1];
                temp_val2 = array_read[j_index];

                // Inner loop check: if j > 0 and array[j] < array[j-1]
                if (j_index > 0 && temp_val2 < temp_val1) begin
                    // --- SWAP (BLUE) ---
                    // We need to swap elements at j_index and j_index-1
                    case (j_index)
                        1: begin current_array_0 <= temp_val2; current_array_1 <= temp_val1; end
                        2: begin current_array_1 <= temp_val2; current_array_2 <= temp_val1; end
                        3: begin current_array_2 <= temp_val2; current_array_3 <= temp_val1; end
                        4: begin current_array_3 <= temp_val2; current_array_4 <= temp_val1; end
                        5: begin current_array_4 <= temp_val2; current_array_5 <= temp_val1; end
                    endcase
                    
                    // Set swap flags for renderer
                    swap_idx1 <= j_index - 1;
                    swap_idx2 <= j_index;
                    
                    // Show swap animation
                    showing_swap <= 1;
                    step_delay <= 0;
                    
                    // Move j_index back
                    j_index <= j_index - 1;

                end else begin
                    // --- NO SWAP (ADVANCE) ---
                    // Element is in sorted position
                    // Advance outer loop (i_index)
                    
                    if (i_index == 5) begin
                        is_sorted_flag <= 1;
                        red_line_pos <= 6; // Show sorted
                    end else begin
                        // Advance to next element
                        i_index <= i_index + 1;
                        j_index <= i_index + 1; // j starts at new i
                        red_line_pos <= i_index + 1; // Move red line
                    end
                end
                
                // Clear compare flags after "act" step
                compare_idx1 <= 3'd7;
                compare_idx2 <= 3'd7;
            end
            // --- END OF CHANGED LOGIC ---

        end else if (prev_step_pulse && history_pointer > 0) begin
            // --- RESTORE PREVIOUS STATE ---
            
            // Decrement pointer
            history_pointer <= history_pointer - 1;
            
            // Read state from (history_pointer - 1)
            current_array_0 <= history_array_0[history_pointer - 1];
            current_array_1 <= history_array_1[history_pointer - 1];
            current_array_2 <= history_array_2[history_pointer - 1];
            current_array_3 <= history_array_3[history_pointer - 1];
            current_array_4 <= history_array_4[history_pointer - 1];
            current_array_5 <= history_array_5[history_pointer - 1];
            
            red_line_pos <= history_red_line[history_pointer - 1];
            i_index <= history_i_index[history_pointer - 1];
            j_index <= history_j_index[history_pointer - 1];
            is_comparing <= history_is_comparing[history_pointer - 1]; // <-- ADDED
            
            // --- CHANGED: Restore color flags ---
            compare_idx1 <= history_compare_idx1[history_pointer - 1]; // <-- CHANGED
            compare_idx2 <= history_compare_idx2[history_pointer - 1]; // <-- CHANGED
            swap_idx1    <= history_swap_idx1[history_pointer - 1];    // <-- CHANGED
            swap_idx2    <= history_swap_idx2[history_pointer - 1];    // <-- CHANGED
            
            is_sorted_flag <= 0;
            showing_swap <= 0;
            step_delay <= 0;
            
            if (history_pointer == 1)
                is_at_start_flag <= 1;
        end
    end

endmodule
