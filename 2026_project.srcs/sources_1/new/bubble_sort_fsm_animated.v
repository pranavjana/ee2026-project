`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Bubble Sort FSM with Smooth Animation Support
// Tracks swap animation progress for smooth sliding transitions
//////////////////////////////////////////////////////////////////////////////////

module bubble_sort_fsm(
    input wire clk,              // System clock
    input wire rst,              // Active high reset
    input wire start,            // Start sorting
    input wire step_pulse,       // Pulse to advance one step (1 Hz)
    input wire [1:0] pattern_sel,// Pattern selection
    output reg [7:0] array0,      // Array element 0
    output reg [7:0] array1,      // Array element 1
    output reg [7:0] array2,      // Array element 2
    output reg [7:0] array3,      // Array element 3
    output reg [7:0] array4,      // Array element 4
    output reg [7:0] array5,      // Array element 5
    output reg [2:0] compare_idx1, // First index being compared
    output reg [2:0] compare_idx2, // Second index being compared
    output reg swap_flag,         // High during swap
    output reg [4:0] anim_progress, // Animation progress (0-31 for smooth interpolation)
    output reg sorting,           // High when actively sorting
    output reg done               // High when sort is complete
);

    // Internal array for sorting
    reg [7:0] array [0:5];

    // FSM States
    localparam IDLE        = 3'b000;
    localparam COMPARE     = 3'b001;
    localparam SWAP_START  = 3'b010;
    localparam SWAP_ANIM   = 3'b011;
    localparam INCREMENT   = 3'b100;
    localparam NEXT_PASS   = 3'b101;
    localparam DONE        = 3'b110;

    reg [2:0] state, next_state;

    // Sorting variables
    reg [2:0] i;              // Current position in array
    reg [2:0] pass_count;     // Number of passes completed
    reg [7:0] temp;           // Temporary storage for swap
    reg swapped_this_pass;    // Flag to detect if any swaps occurred

    // Animation counter (counts frames for smooth swap)
    reg [4:0] anim_counter;
    localparam ANIM_FRAMES = 16;  // Number of frames for swap animation

    // Pre-loaded patterns
    localparam [47:0] PATTERN_RANDOM  = {8'd200, 8'd80, 8'd160, 8'd40, 8'd120, 8'd240};
    localparam [47:0] PATTERN_SORTED  = {8'd40, 8'd80, 8'd120, 8'd160, 8'd200, 8'd240};
    localparam [47:0] PATTERN_REVERSE = {8'd240, 8'd200, 8'd160, 8'd120, 8'd80, 8'd40};
    localparam [47:0] PATTERN_CUSTOM  = {8'd100, 8'd220, 8'd60, 8'd180, 8'd140, 8'd20};

    // Frame counter for animation (runs at OLED refresh rate ~60Hz)
    reg [19:0] frame_counter;
    wire frame_tick = (frame_counter == 20'd104166);  // ~60Hz at 6.25MHz

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
                if (anim_counter >= ANIM_FRAMES - 1)
                    next_state = INCREMENT;
            end

            INCREMENT: begin
                if (i >= (5 - pass_count - 1))
                    next_state = NEXT_PASS;
                else
                    next_state = COMPARE;
            end

            NEXT_PASS: begin
                if (!swapped_this_pass || pass_count >= 5)
                    next_state = DONE;
                else
                    next_state = COMPARE;
            end

            DONE: begin
                if (start)
                    next_state = COMPARE;
            end

            default: next_state = IDLE;
        endcase
    end

    // Output and datapath logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {array[5], array[4], array[3], array[2], array[1], array[0]} <= PATTERN_RANDOM;
            compare_idx1 <= 0;
            compare_idx2 <= 1;
            swap_flag <= 0;
            anim_progress <= 0;
            sorting <= 0;
            done <= 0;
            i <= 0;
            pass_count <= 0;
            temp <= 0;
            swapped_this_pass <= 0;
            anim_counter <= 0;
        end else begin
            case (state)
                IDLE: begin
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
                    sorting <= 0;
                    done <= 0;
                    swapped_this_pass <= 0;
                    anim_counter <= 0;
                end

                COMPARE: begin
                    sorting <= 1;
                    compare_idx1 <= i;
                    compare_idx2 <= i + 1;
                    swap_flag <= 0;
                    anim_progress <= 0;
                    done <= 0;
                    anim_counter <= 0;
                end

                SWAP_START: begin
                    temp <= array[i];
                    swap_flag <= 1;
                    anim_progress <= 0;
                    anim_counter <= 0;
                    swapped_this_pass <= 1;
                end

                SWAP_ANIM: begin
                    // Increment animation counter each frame
                    if (frame_tick) begin
                        anim_counter <= anim_counter + 1;
                        anim_progress <= anim_counter;
                    end

                    // Complete swap at end of animation
                    if (anim_counter == ANIM_FRAMES - 1) begin
                        array[i] <= array[i+1];
                        array[i+1] <= temp;
                    end
                end

                INCREMENT: begin
                    i <= i + 1;
                    swap_flag <= 0;
                    anim_progress <= 0;
                    anim_counter <= 0;
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
                    compare_idx1 <= 3'b111;
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
