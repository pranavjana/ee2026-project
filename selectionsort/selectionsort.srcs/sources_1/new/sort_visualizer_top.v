`timescale 1ns / 1ps

// ========== COMPLETE TOP MODULE - WITH SW7 TUTORIAL RESET ==========
module sort_visualizer_top(
    input clk,
    input [15:0] sw,
    input btnC,
    input btnU,
    input btnD,
    input btnL,
    input btnR,
    output [7:0] JC,
    output [6:0] seg,
    output [3:0] an,
    output [15:0] led
);

    // ========== LED ASSIGNMENT ==========
    assign led[15:6] = sw[15:6];
    assign led[5] = tutorial_mode ? (tutorial_progress >= 3'd6) : sw[5];
    assign led[4] = tutorial_mode ? (tutorial_progress >= 3'd5) : sw[4];
    assign led[3] = tutorial_mode ? (tutorial_progress >= 3'd4) : sw[3];
    assign led[2] = tutorial_mode ? (tutorial_progress >= 3'd3) : sw[2];
    assign led[1] = tutorial_mode ? (tutorial_progress >= 3'd2) : sw[1];
    assign led[0] = tutorial_mode ? (tutorial_progress >= 3'd1) : sw[0];

    // ========== CLOCK GENERATION ==========
    wire clk_6p25MHz;
    clock_divider #(.M(32'd7)) clk_div_6p25(
        .clk(clk),
        .slow_clock(clk_6p25MHz)
    );
    
    wire clk_1ms;
    clock_divider_1ms clk_1ms_gen(
        .clk(clk),
        .clk_1ms(clk_1ms)
    );
    
    // ========== OLED DISPLAY SIGNALS ==========
    wire frame_begin, sending_pixels, sample_pixel;
    wire [12:0] pixel_index;
    wire [15:0] oled_colour;
    
    // ========== SORTING CONTROLLER OUTPUTS ==========
    wire [17:0] array_flat;
    wire [2:0] current_i, current_j, min_idx;
    wire sorting_active;
    wire [1:0] state_type;
    wire sort_complete;
    wire [2:0] intro_state;
    wire demo_mode;
    wire show_swap_info;
    
    
    // ========== TUTORIAL MODE SIGNALS ==========
    wire tutorial_mode;
    wire [3:0] tutorial_state;
    wire [2:0] selected_box;
    wire [1:0] wrong_attempt_count;
    wire [17:0] tutorial_array;
    wire [11:0] tutorial_timer;
    wire [5:0] box_confirmed;
    
    // ========== INTERACTIVE TEST SIGNALS ==========
    wire [2:0] test_cursor_pos;
    wire [2:0] test_unsorted_idx;
    wire test_selecting_swap;
    wire [2:0] user_min_selected; 
    wire [2:0] tutorial_progress;
    
    // ========== PERFORMANCE COUNTERS ==========
    wire [7:0] comparison_count;
    wire [7:0] swap_count;
    wire manual_step_mode;
    
    // ========== TEXT ANIMATION ==========
    wire [2:0] anim_offset;
    wire enable_animator = sw[13] && (intro_state == 3'd2);
    
    text_animator animator(
        .clk_1ms(clk_1ms),
        .reset(1'b0),
        .enable(enable_animator),
        .offset(anim_offset)
    );
    
    // ========== SELECTION SORT CONTROLLER ==========
    selection_sort_controller sort_ctrl(
        .clk(clk_1ms),
        .reset(1'b0),
        .enable(sw[13]),
        .ctr_button(btnC),
        .sw10(sw[10]),
        .sw7(sw[7]),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        // Standard outputs
        .array_flat(array_flat),
        .current_i(current_i),
        .current_j(current_j),
        .min_idx(min_idx),
        .sorting_active(sorting_active),
        .state_type(state_type),
        .sort_complete(sort_complete),
        .intro_state(intro_state),
        .wrong_attempt_count(wrong_attempt_count),
        .demo_mode(demo_mode),
        // Tutorial mode outputs
        .tutorial_mode(tutorial_mode),
        .tutorial_state(tutorial_state),
        .selected_box(selected_box),
        .tutorial_array(tutorial_array),
        .tutorial_timer(tutorial_timer),
        .box_confirmed(box_confirmed),
        // Interactive test outputs
        .test_cursor_pos(test_cursor_pos),
        .test_unsorted_idx(test_unsorted_idx),
        .test_selecting_swap(test_selecting_swap),
        .user_min_selected(user_min_selected),
        // Performance counters
        .comparison_count(comparison_count),
        .swap_count(swap_count),
        .manual_step_mode(manual_step_mode),
        .tutorial_progress(tutorial_progress),
         .show_swap_info(show_swap_info)
    );
    
    // ========== DISPLAY GENERATOR ==========
    display_generator_comb disp_gen(
        .enable(sw[13]),
        .pixel_index(pixel_index),
        // Demo mode inputs
        .array_flat(array_flat),
        .current_i(current_i),
        .current_j(current_j),
        .min_idx(min_idx),
        .sorting_active(sorting_active),
        .state_type(state_type),
        .intro_state(intro_state),
        .anim_offset(anim_offset),
        .sort_complete(sort_complete),
        // Tutorial mode inputs
        .tutorial_mode(tutorial_mode),
        .tutorial_state(tutorial_state),
        .wrong_attempt_count(wrong_attempt_count),
        .selected_box(selected_box),
        .tutorial_array(tutorial_array),
        .tutorial_timer(tutorial_timer),
        .box_confirmed(box_confirmed),
        // Interactive test inputs
        .test_cursor_pos(test_cursor_pos),
        .test_unsorted_idx(test_unsorted_idx),
        .test_selecting_swap(test_selecting_swap),
        // Performance counters
        .comparison_count(comparison_count),
        .swap_count(swap_count),
        // Output
        .user_min_selected(user_min_selected),
        .tutorial_progress(tutorial_progress), 
        .show_swap_info(show_swap_info),
        .pixel_data(oled_colour)
    );
    
    // ========== OLED DISPLAY DRIVER ==========
    Oled_Display student_oled(
        .clk(clk_6p25MHz),
        .reset(1'b0),
        .frame_begin(frame_begin),
        .sending_pixels(sending_pixels),
        .sample_pixel(sample_pixel),
        .pixel_index(pixel_index),
        .pixel_data(oled_colour),
        .cs(JC[0]),
        .sdin(JC[1]),
        .sclk(JC[3]),
        .d_cn(JC[4]),
        .resn(JC[5]),
        .vccen(JC[6]),
        .pmoden(JC[7])
    );
    
    // ========== 7-SEGMENT DISPLAY ==========
    seven_segment_display seg_display(
        .clk(clk),
        .enable(sw[13]),
        .seg(seg),
        .an(an)
    );

endmodule


// ========== CLOCK DIVIDER (Generic) ==========
module clock_divider #(
    parameter M = 32'd7
)(
    input clk,
    output reg slow_clock
);
    reg [31:0] count = 0;
    
    always @(posedge clk) begin
        count <= (count == M) ? 0 : count + 1;
        slow_clock <= (count == 0) ? ~slow_clock : slow_clock;
    end
endmodule


// ========== CLOCK DIVIDER 1MS ==========
module clock_divider_1ms(
    input clk,
    output reg clk_1ms
);
    reg [16:0] counter = 0;
    
    always @(posedge clk) begin
        if (counter == 17'd49999) begin
            counter <= 0;
            clk_1ms <= ~clk_1ms;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule


// ========== TEXT ANIMATOR ==========
module text_animator(
    input clk_1ms,
    input reset,
    input enable,
    output reg [2:0] offset
);
    reg [7:0] counter = 0;
    reg direction = 0;
    
    always @(posedge clk_1ms or posedge reset) begin
        if (reset || !enable) begin
            counter <= 0;
            direction <= 0;
            offset <= 0;
        end else begin
            if (direction == 0) begin
                if (counter == 99) begin
                    direction <= 1;
                end else begin
                    counter <= counter + 1;
                end
            end else begin
                if (counter == 0) begin
                    direction <= 0;
                end else begin
                    counter <= counter - 1;
                end
            end
            
            offset <= (counter >= 50) ? 3'd1 : 3'd0;
        end
    end
endmodule


// ========== 7-SEGMENT DISPLAY MODULE ==========
module seven_segment_display(
    input clk,
    input enable,
    output reg [6:0] seg,
    output reg [3:0] an
);
    wire [1:0] digit_select;
    reg [16:0] refresh_counter;
    
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
    end
    
    assign digit_select = refresh_counter[16:15];
    
    always @(*) begin
        if (!enable) begin
            seg = 7'b1111111;
            an = 4'b1111;
        end else begin
            case (digit_select)
                2'b00: begin
                    an = 4'b0111;
                    seg = 7'b0010010;
                end
                2'b01: begin
                    an = 4'b1011;
                    seg = 7'b0000110;
                end
                2'b10: begin
                    an = 4'b1101;
                    seg = 7'b1000111;
                end
                2'b11: begin
                    an = 4'b1110;
                    seg = 7'b0101011;
                end
            endcase
        end
    end
endmodule