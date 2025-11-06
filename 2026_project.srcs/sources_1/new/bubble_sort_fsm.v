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
    output reg [4:0] anim_progress, // Animation progress (0-7 per phase)
    output reg [1:0] anim_phase,    // Animation phase (0-3 for 4-phase swap)
    output reg sorting,           // High when actively sorting
    output reg done               // High when sort is complete
);

    // Internal array for sorting
    reg [7:0] array [0:5];

    // FSM States
    localparam IDLE        = 3'b000;
    localparam COMPARE     = 3'b001;
    localparam SWAP_START  = 3'b010;
    localparam SWAP_ANIM   = 3'b110;
    localparam INCREMENT   = 3'b011;
    localparam NEXT_PASS   = 3'b100;
    localparam DONE        = 3'b101;

    reg [2:0] state, next_state;

    // Sorting variables
    reg [2:0] i;              // Current position in array
    reg [2:0] pass_count;     // Number of passes completed
    reg [7:0] temp;           // Temporary storage for swap
    reg swapped_this_pass;    // Flag to detect if any swaps occurred

    // Animation variables
    reg [6:0] anim_counter;
    localparam ANIM_FRAMES = 60;   // Number of frames per phase (60 frames * 4 phases = 240 total, ~4 seconds per swap)
    reg [1:0] phase_counter;      // Tracks which phase of animation (0-3)

    // Frame tick generator for animations (~60 Hz)
    // At 100MHz clock: 100,000,000 / 60 = 1,666,667 cycles per frame
    reg [20:0] frame_counter;
    wire frame_tick = (frame_counter >= 21'd1666666);  // ~60Hz at 100MHz

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

    // Frame counter for animation
    always @(posedge clk or posedge rst) begin
        if (rst)
            frame_counter <= 0;
        else if (frame_tick)
            frame_counter <= 0;
        else
            frame_counter <= frame_counter + 1;
    end

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
                        next_state = SWAP_START;
                    else
                        next_state = INCREMENT;
                end
            end

            SWAP_START: begin
                next_state = SWAP_ANIM;
            end

            SWAP_ANIM: begin
                // Stay in this state until animation completes
                next_state = SWAP_ANIM;  // Explicitly stay here
                // Complete when all 4 phases are done
                if (phase_counter >= 3 && anim_counter >= ANIM_FRAMES - 1)
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
            anim_progress <= 0;
            anim_phase <= 0;
            sorting <= 0;
            done <= 0;
            i <= 0;
            pass_count <= 0;
            temp <= 0;
            swapped_this_pass <= 0;
            anim_counter <= 0;
            phase_counter <= 0;
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
                    anim_progress <= 0;
                    anim_phase <= 0;
                    sorting <= 0;
                    done <= 0;
                    swapped_this_pass <= 0;
                    anim_counter <= 0;
                    phase_counter <= 0;
                end

                COMPARE: begin
                    sorting <= 1;
                    compare_idx1 <= i;
                    compare_idx2 <= i + 1;
                    swap_flag <= 0;
                    anim_progress <= 0;
                    anim_phase <= 0;
                    done <= 0;
                    anim_counter <= 0;
                    phase_counter <= 0;
                end

                SWAP_START: begin
                    temp <= array[i];
                    swap_flag <= 1;
                    anim_progress <= 0;
                    anim_phase <= 0;
                    anim_counter <= 0;
                    phase_counter <= 0;
                    swapped_this_pass <= 1;
                end

                SWAP_ANIM: begin
                    // Keep swap flag high during animation
                    swap_flag <= 1;

                    // DIAGNOSTIC: Force constant values to test rendering
                    anim_progress <= 5'd30;  // Force to 30 (middle of range)
                    anim_phase <= 2'b01;     // Force to phase 1

                    // SIMPLIFIED FOR DEBUG: Increment every clock cycle (very fast animation)
                    // Once working, we can slow it down with frame_tick
                    if (anim_counter == ANIM_FRAMES - 1) begin
                        // Reached end of this phase
                        if (phase_counter < 3) begin
                            // Move to next phase
                            phase_counter <= phase_counter + 1;
                            anim_counter <= 0;
                        end else begin
                            // Phase 3 complete - do the swap and hold position
                            array[i] <= array[i+1];
                            array[i+1] <= temp;
                            // Stay at phase 3, frame 59 (don't increment)
                        end
                    end else begin
                        // Continue incrementing within this phase
                        anim_counter <= anim_counter + 1;
                    end
                end

                INCREMENT: begin
                    i <= i + 1;
                    swap_flag <= 0;
                    anim_progress <= 0;
                    anim_phase <= 0;
                    anim_counter <= 0;
                    phase_counter <= 0;
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
                    anim_progress <= 0;
                    anim_phase <= 0;
                    compare_idx1 <= 3'b111;  // Invalid index to indicate no comparison
                    compare_idx2 <= 3'b111;
                end

                default: begin
                    // Ensure all outputs are driven in unexpected states
                    swap_flag <= 0;
                    anim_progress <= 0;
                    anim_phase <= 0;
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
