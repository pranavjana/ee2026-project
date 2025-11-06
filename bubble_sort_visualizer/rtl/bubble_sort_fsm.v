`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Bubble Sort FSM Module
// Implements bubble sort algorithm with state tracking for visualization
// Supports 6 elements with 8-bit values (0-255)
//////////////////////////////////////////////////////////////////////////////////

module bubble_sort_fsm(
    input wire clk,              // System clock
    input wire rst,              // Active high reset
    input wire start,            // Start sorting
    input wire step_pulse,       // Pulse to advance one step (1 Hz)
    input wire [1:0] pattern_sel,// Pattern selection (00=random, 01=sorted, 10=reverse, 11=custom)
    output reg [7:0] array [0:5], // 6-element array (values 0-255)
    output reg [2:0] compare_idx1, // First index being compared
    output reg [2:0] compare_idx2, // Second index being compared
    output reg swap_flag,         // High when swap is occurring
    output reg sorting,           // High when actively sorting
    output reg done               // High when sort is complete
);

    // FSM States
    localparam IDLE        = 3'b000;
    localparam COMPARE     = 3'b001;
    localparam SWAP        = 3'b010;
    localparam INCREMENT   = 3'b011;
    localparam NEXT_PASS   = 3'b100;
    localparam DONE        = 3'b101;

    reg [2:0] state, next_state;

    // Sorting variables
    reg [2:0] i;              // Current position in array
    reg [2:0] pass_count;     // Number of passes completed
    reg [7:0] temp;           // Temporary storage for swap
    reg swapped_this_pass;    // Flag to detect if any swaps occurred

    // Pre-loaded patterns
    // Pattern 0: Random
    localparam [47:0] PATTERN_RANDOM  = {8'd150, 8'd50, 8'd200, 8'd30, 8'd180, 8'd100};
    // Pattern 1: Already sorted
    localparam [47:0] PATTERN_SORTED  = {8'd30, 8'd60, 8'd90, 8'd120, 8'd150, 8'd180};
    // Pattern 2: Reverse sorted
    localparam [47:0] PATTERN_REVERSE = {8'd200, 8'd160, 8'd120, 8'd80, 8'd40, 8'd20};
    // Pattern 3: Custom pattern with duplicates
    localparam [47:0] PATTERN_CUSTOM  = {8'd100, 8'd150, 8'd50, 8'd150, 8'd200, 8'd75};

    // State register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start)
                    next_state = COMPARE;
            end

            COMPARE: begin
                if (step_pulse) begin
                    // Check if we need to swap
                    if (array[i] > array[i+1])
                        next_state = SWAP;
                    else
                        next_state = INCREMENT;
                end
            end

            SWAP: begin
                if (step_pulse)
                    next_state = INCREMENT;
            end

            INCREMENT: begin
                // Check if we've reached the end of current pass
                if (i >= (5 - pass_count - 1))
                    next_state = NEXT_PASS;
                else
                    next_state = COMPARE;
            end

            NEXT_PASS: begin
                // Check if array is sorted (no swaps occurred) or all passes done
                if (!swapped_this_pass || pass_count >= 5)
                    next_state = DONE;
                else
                    next_state = COMPARE;
            end

            DONE: begin
                if (start)  // Allow restart
                    next_state = COMPARE;
            end

            default: next_state = IDLE;
        endcase
    end

    // Output and datapath logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Initialize array based on pattern
            {array[5], array[4], array[3], array[2], array[1], array[0]} <= PATTERN_RANDOM;
            compare_idx1 <= 0;
            compare_idx2 <= 1;
            swap_flag <= 0;
            sorting <= 0;
            done <= 0;
            i <= 0;
            pass_count <= 0;
            temp <= 0;
            swapped_this_pass <= 0;
        end else begin
            case (state)
                IDLE: begin
                    // Load selected pattern
                    case (pattern_sel)
                        2'b00: {array[5], array[4], array[3], array[2], array[1], array[0]} <= PATTERN_RANDOM;
                        2'b01: {array[5], array[4], array[3], array[2], array[1], array[0]} <= PATTERN_SORTED;
                        2'b10: {array[5], array[4], array[3], array[2], array[1], array[0]} <= PATTERN_REVERSE;
                        2'b11: {array[5], array[4], array[3], array[2], array[1], array[0]} <= PATTERN_CUSTOM;
                    endcase
                    i <= 0;
                    pass_count <= 0;
                    compare_idx1 <= 0;
                    compare_idx2 <= 1;
                    swap_flag <= 0;
                    sorting <= 0;
                    done <= 0;
                    swapped_this_pass <= 0;
                end

                COMPARE: begin
                    sorting <= 1;
                    compare_idx1 <= i;
                    compare_idx2 <= i + 1;
                    swap_flag <= 0;
                    done <= 0;
                end

                SWAP: begin
                    // Perform swap
                    temp <= array[i];
                    array[i] <= array[i+1];
                    array[i+1] <= temp;
                    swap_flag <= 1;
                    swapped_this_pass <= 1;
                end

                INCREMENT: begin
                    i <= i + 1;
                    swap_flag <= 0;
                end

                NEXT_PASS: begin
                    i <= 0;
                    pass_count <= pass_count + 1;
                    swapped_this_pass <= 0;
                    compare_idx1 <= 0;
                    compare_idx2 <= 1;
                end

                DONE: begin
                    sorting <= 0;
                    done <= 1;
                    swap_flag <= 0;
                    compare_idx1 <= 3'b111;  // Invalid index to indicate no comparison
                    compare_idx2 <= 3'b111;
                end
            endcase
        end
    end

endmodule
