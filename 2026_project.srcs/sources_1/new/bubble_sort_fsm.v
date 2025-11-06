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
    output reg [7:0] array0,      // Array element 0
    output reg [7:0] array1,      // Array element 1
    output reg [7:0] array2,      // Array element 2
    output reg [7:0] array3,      // Array element 3
    output reg [7:0] array4,      // Array element 4
    output reg [7:0] array5,      // Array element 5
    output reg [2:0] compare_idx1, // First index being compared
    output reg [2:0] compare_idx2, // Second index being compared
    output reg swap_flag,         // High when swap is occurring
    output reg sorting,           // High when actively sorting
    output reg done               // High when sort is complete
);

    // Internal array for sorting
    reg [7:0] array [0:5];

    // FSM States
    localparam IDLE        = 3'b000;
    localparam COMPARE     = 3'b001;
    localparam SWAP        = 3'b010;
    localparam SWAP_WAIT   = 3'b110;
    localparam INCREMENT   = 3'b011;
    localparam NEXT_PASS   = 3'b100;
    localparam DONE        = 3'b101;

    reg [2:0] state, next_state;

    // Sorting variables
    reg [2:0] i;              // Current position in array
    reg [2:0] pass_count;     // Number of passes completed
    reg [7:0] temp1, temp2;   // Temporary storage for swap (need both values)
    reg swapped_this_pass;    // Flag to detect if any swaps occurred
    reg swap_done;            // Flag to pulse swap_flag for one cycle only

    // Pre-loaded patterns - Single digits 0-9
    // array[0]=LEFTMOST digit, array[5]=RIGHTMOST digit
    // After sorting (ascending), should show: 0 1 2 3 4 5

    // Pattern 0: Random - needs sorting (contains 5,2,4,1,3,0)
    localparam [47:0] PATTERN_RANDOM  = {8'd5, 8'd2, 8'd4, 8'd1, 8'd3, 8'd0};
    // Pattern 1: Already sorted (0,1,2,3,4,5)
    localparam [47:0] PATTERN_SORTED  = {8'd0, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5};
    // Pattern 2: Reverse sorted (5,4,3,2,1,0)
    localparam [47:0] PATTERN_REVERSE = {8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0};
    // Pattern 3: Custom pattern (3,5,1,4,2,0)
    localparam [47:0] PATTERN_CUSTOM  = {8'd3, 8'd5, 8'd1, 8'd4, 8'd2, 8'd0};

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
                    // Check if we need to swap (sort ASCENDING: smallest to largest)
                    // array[0] should be smallest, array[5] should be largest
                    if (array[i] > array[i+1])
                        next_state = SWAP;
                    else
                        next_state = INCREMENT;
                end
            end

            SWAP: begin
                next_state = SWAP_WAIT;
            end

            SWAP_WAIT: begin
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
            temp1 <= 0;
            temp2 <= 0;
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
                    swap_flag <= 0;  // Clear swap flag before next comparison
                    done <= 0;
                end

                SWAP: begin
                    // Save BOTH values first
                    temp1 <= array[i];     // Save the first element
                    temp2 <= array[i+1];   // Save the second element
                    swap_flag <= 1;
                    swapped_this_pass <= 1;
                    swap_done <= 1;
                end

                SWAP_WAIT: begin
                    // Now swap using the saved values
                    array[i] <= temp2;     // Put second element in first position
                    array[i+1] <= temp1;   // Put first element in second position
                    swap_flag <= 1;  // Keep flag high during swap
                end

                INCREMENT: begin
                    i <= i + 1;
                    swap_flag <= 0;  // Clear swap flag after SWAP state
                    swap_done <= 0;
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

    // Continuous assignment of internal array to output ports
    always @(*) begin
        array0 = array[0];
        array1 = array[1];
        array2 = array[2];
        array3 = array[3];
        array4 = array[4];
        array5 = array[5];
    end

endmodule
