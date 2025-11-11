# EE2026 Sorting Visualizer - Complete Technical Documentation
## Comprehensive System Architecture & Implementation Details

**Author:** Your Name
**Course:** EE2026
**Date:** November 11, 2025
**Target:** Basys 3 FPGA (Artix-7 XC7A35T)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Architecture Overview](#system-architecture-overview)
3. [FSM Implementations](#fsm-implementations)
4. [Clock Management & Timing Systems](#clock-management--timing-systems)
5. [Debouncing Architecture](#debouncing-architecture)
6. [Register Architectures & Memory Systems](#register-architectures--memory-systems)
7. [Animation System & Coordinate Tracking](#animation-system--coordinate-tracking)
8. [OLED Rendering Pipeline](#oled-rendering-pipeline)
9. [Tutorial Mode Validation Systems](#tutorial-mode-validation-systems)
10. [Merge Sort Implementation](#merge-sort-implementation)
11. [Input Handling Systems](#input-handling-systems)
12. [Hardware Resource Utilization](#hardware-resource-utilization)

---

## 1. Executive Summary

This project implements a **Unified Sorting Algorithm Visualizer** on a Basys 3 FPGA with an OLED display, supporting:
- **4 sorting algorithms**: Bubble Sort, Merge Sort, Insertion Sort, Selection Sort
- **Dual modes**: Educational (auto-demo) and Tutorial (interactive)
- **Real-time animation** at 60 Hz frame rate
- **Hardware validation** of user sorting decisions in tutorial mode
- **Clock domain crossing** (CDC) with handshaking protocols
- **Multi-algorithm multiplexing** with conflict detection

### Your Contributions:
- **Bubble Sort**: Educational and Tutorial mode FSMs with 7-state and 10-state machines
- **Merge Sort**: Animation system, swapping logic, register-based state storage, user input handling, real-time validation
- **Debouncing**: Shared 5-button architecture with 20-bit counters and edge detection
- **Integration**: Algorithm multiplexing in unified top module

---

## 2. System Architecture Overview

### 2.1 Top-Level Module: `sorting_visualizer_top.v`

**Location:** `2026_project.srcs/sources_1/new/sorting_visualizer_top.v`
**Size:** 927 lines
**Function:** Master controller integrating all four sorting algorithms

#### Module Interface
```verilog
module sorting_visualizer_top(
    input wire clk,              // 100 MHz system clock
    input wire btnC, btnU, btnL, btnR, btnD,  // 5 pushbuttons
    input wire [15:0] sw,        // 16 switches
    output wire [15:0] led,      // Status LEDs
    output wire [6:0] seg,       // 7-segment display
    output wire [3:0] an,        // 7-segment anodes
    output wire dp,              // Decimal point
    output wire [7:0] JC         // OLED PMOD SPI interface
);
```

#### Switch Configuration Logic
```verilog
// Algorithm selection (one-hot encoding)
SW[15] = Merge Sort
SW[14] = Insertion Sort
SW[13] = Selection Sort
SW[12] = Bubble Sort
SW[10] = Tutorial Mode Enable (combines with algorithm switch)

// Example combinations:
SW[15:0] = 0x8000 → Merge Sort Educational Mode
SW[15:0] = 0x8400 → Merge Sort Tutorial Mode
SW[15:0] = 0x1000 → Bubble Sort Educational Mode
SW[15:0] = 0x1400 → Bubble Sort Tutorial Mode
```

#### Invalid Combination Detection
Prevents multiple algorithms from running simultaneously:
```verilog
wire invalid_combination = (sw[15] && sw[14]) || (sw[15] && sw[13]) ||
                          (sw[15] && sw[12]) || (sw[14] && sw[13]) ||
                          (sw[14] && sw[12]) || (sw[13] && sw[12]);
```

**Design Rationale:**
- Combinational logic prevents resource conflicts
- OLED reset triggered on invalid combination
- LEDs indicate error state (all modules reset)

### 2.2 Module Hierarchy

```
sorting_visualizer_top (927 lines)
├── Clock Generation (inline)
│   ├── clk_6p25MHz (OLED interface)
│   └── clk_movement (~45 Hz animations)
│
├── Button Synchronization (inline)
│   ├── 3-stage shift registers
│   └── Edge detection logic
│
├── Oled_Display Module (399 lines)
│   ├── 32-state FSM
│   ├── SPI protocol controller
│   └── Frame timing (60 Hz)
│
├── Bubble Sort Subsystem
│   ├── bubble_sort_fsm (287 lines) - 7-state FSM
│   ├── tutorial_fsm (535 lines) - 10-state FSM
│   ├── pixel_generator (395 lines)
│   ├── tutorial_pixel_generator (612 lines)
│   ├── button_debounce_5btn (200 lines)
│   └── clock_divider (56 lines)
│
├── Merge Sort Subsystem
│   ├── merge_sort_controller (1882 lines) - 8-state FSM
│   ├── merge_sort_display (293 lines)
│   └── merge_sort_numbers (233 lines)
│
├── Insertion Sort Subsystem
│   ├── Main_FSM (239 lines) - 8-state master controller
│   ├── Sort_Engine (260 lines) - Algorithm engine
│   ├── Tutorial_Sort_Engine (424 lines)
│   ├── Tutorial_Input_Engine (custom)
│   ├── Oled_Renderer (1029 lines)
│   └── Frame_Buffer (76 lines) - 6144-pixel BRAM
│
└── Selection Sort Subsystem
    ├── selection_sort_controller (943 lines) - 11/14 states
    ├── display_generator_comb (2517 lines)
    └── text_animator (vertical bobbing)
```

---

## 3. FSM Implementations

### 3.1 Bubble Sort Educational Mode FSM

**Module:** `bubble_sort_fsm.v` (287 lines)
**State Encoding:** 3-bit (8 possible states, 7 used)

#### State Machine Definition
```verilog
localparam IDLE        = 3'b000;  // Waiting for start signal
localparam COMPARE     = 3'b001;  // Compare adjacent elements
localparam SWAP_START  = 3'b010;  // Initiate swap operation
localparam SWAP_ANIM   = 3'b110;  // 4-phase swap animation
localparam INCREMENT   = 3'b011;  // Move to next pair
localparam NEXT_PASS   = 3'b100;  // Begin new pass if needed
localparam DONE        = 3'b101;  // Sorting complete
```

#### State Transition Diagram
```
IDLE ─(start)→ COMPARE
                   │
         ┌─────────┴──────────┐
         │                    │
    (array[i] > array[i+1]) (array[i] <= array[i+1])
         │                    │
         ↓                    ↓
    SWAP_START            INCREMENT
         │                    │
         ↓                    │
    SWAP_ANIM (240 frames)   │
         │                    │
         └────────┬───────────┘
                  ↓
              INCREMENT
                  │
         ┌────────┴─────────┐
         │                  │
    (i < 5-pass_count)  (i >= 5-pass_count)
         │                  │
         ↓                  ↓
      COMPARE           NEXT_PASS
                            │
                   ┌────────┴────────┐
                   │                 │
            (swapped_this_pass)   (not swapped)
                   │                 │
                   ↓                 ↓
                COMPARE             DONE
```

#### Key Registers and Data Structures

```verilog
// Internal array (6 elements)
reg [7:0] array [0:5];           // 6 × 8-bit values (0-255)

// FSM state tracking
reg [2:0] state, next_state;     // Current and next state

// Sorting variables
reg [2:0] i;                     // Current position in array (0-5)
reg [2:0] pass_count;            // Number of passes completed (0-5)
reg [7:0] temp;                  // Temporary storage for swap
reg swapped_this_pass;           // Early termination flag

// Animation control
reg [6:0] anim_counter;          // Animation frame counter (0-59)
reg [1:0] phase_counter;         // Animation phase (0-3)
reg [20:0] frame_counter;        // Frame tick generator (~60 Hz)

localparam ANIM_FRAMES = 60;     // Frames per phase
// Total animation: 60 frames × 4 phases = 240 frames ≈ 4 seconds per swap
```

#### Animation Phase Breakdown

**Total Swap Animation: 4 Phases × 60 Frames = 240 Frames (~4 seconds at 60 Hz)**

```verilog
// Phase 0 (frames 0-59): Element at compare_idx1 moves UP
//   - Y displacement: 0 → 16 pixels upward
//   - X displacement: 0
//   - Duration: 1 second

// Phase 1 (frames 60-119): Element at compare_idx2 moves LEFT
//   - compare_idx1 stays elevated (Y = -16)
//   - compare_idx2 moves left: 0 → 16 pixels
//   - Duration: 1 second

// Phase 2 (frames 120-179): Element at compare_idx1 moves RIGHT
//   - compare_idx1 moves right: 0 → 16 pixels (still elevated)
//   - compare_idx2 stays at final left position
//   - Duration: 1 second

// Phase 3 (frames 180-239): Element at compare_idx1 moves DOWN
//   - compare_idx1 descends: -16 → 0 pixels
//   - Both elements now in swapped positions
//   - Duration: 1 second
//   - Actual data swap occurs at midpoint (frame 8 of phase 3)
```

#### Frame Tick Generation

```verilog
// 60 Hz frame rate at 100 MHz system clock
// Cycles per frame = 100,000,000 / 60 = 1,666,667 cycles
reg [20:0] frame_counter;
wire frame_tick = (frame_counter >= 21'd1666666);

always @(posedge clk or posedge rst) begin
    if (rst)
        frame_counter <= 0;
    else if (frame_tick)
        frame_counter <= 0;
    else
        frame_counter <= frame_counter + 1;
end
```

**Design Rationale:**
- 21-bit counter required: 2^21 = 2,097,152 > 1,666,667
- Single-cycle pulse on frame_tick
- Synchronized with OLED refresh rate (60 Hz)

#### Pre-loaded Patterns

```verilog
// Pattern storage: 48-bit concatenated array
// array[0]=LEFTMOST digit, array[5]=RIGHTMOST digit

localparam [47:0] PATTERN_RANDOM  = {8'd5, 8'd2, 8'd4, 8'd1, 8'd3, 8'd0};
localparam [47:0] PATTERN_SORTED  = {8'd0, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5};
localparam [47:0] PATTERN_REVERSE = {8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0};
localparam [47:0] PATTERN_CUSTOM  = {8'd3, 8'd5, 8'd1, 8'd4, 8'd2, 8'd0};

// Pattern loading (concatenated assignment)
{array[5], array[4], array[3], array[2], array[1], array[0]} <= PATTERN_RANDOM;
```

**Bit Layout:**
```
[47:40] → array[5] (rightmost)
[39:32] → array[4]
[31:24] → array[3]
[23:16] → array[2]
[15:8]  → array[1]
[7:0]   → array[0] (leftmost)
```

---

### 3.2 Bubble Sort Tutorial Mode FSM

**Module:** `tutorial_fsm.v` (535 lines)
**State Encoding:** 4-bit (16 possible states, 10 used)

#### State Machine Definition
```verilog
localparam [3:0]
    SETUP_INIT          = 4'd0,   // Initialize array with zeros
    SETUP_EDIT          = 4'd1,   // User edits array values
    SETUP_CONFIRM       = 4'd2,   // Wait for confirmation to start
    TUTORIAL_SELECT     = 4'd3,   // Select adjacent pair
    TUTORIAL_COMPARE    = 4'd4,   // Display comparison
    TUTORIAL_AWAIT_SWAP = 4'd5,   // Wait for swap decision
    TUTORIAL_SWAP_ANIM  = 4'd6,   // Animate the swap (16 frames)
    TUTORIAL_FEEDBACK   = 4'd7,   // Show feedback (1 second)
    TUTORIAL_CHECK_DONE = 4'd8,   // Check if sorted
    TUTORIAL_COMPLETE   = 4'd9;   // Success celebration
```

#### State Flow with User Interactions

```
[User creates array]
SETUP_INIT → SETUP_EDIT ─(btnC)→ SETUP_CONFIRM → TUTORIAL_SELECT
                 ↑                                      │
                 │ (btnL/R: navigate)                  │
                 │ (btnU/D: modify)                    │
                 └──────────────────────────────────────┘

[User performs sorting]
TUTORIAL_SELECT ─(btnU: swap)─→ TUTORIAL_SWAP_ANIM → TUTORIAL_FEEDBACK
       │                                                       │
       └──────(btnD: skip)─────────────────────────────────→  │
                                                               ↓
                                                      TUTORIAL_CHECK_DONE
                                                               │
                                     ┌─────────────────────────┴──────────┐
                                     │                                    │
                              (array_is_sorted)                    (not sorted)
                                     │                                    │
                                     ↓                                    ↓
                             TUTORIAL_COMPLETE                    TUTORIAL_SELECT
```

#### Validation System Architecture

**Shadow Bubble Sort Tracker:**
```verilog
// Optimal solution tracker (parallel sorting algorithm)
reg [7:0] optimal_array [0:5];   // Shadow array for reference
reg [2:0] optimal_i, optimal_j;  // Expected indices
reg [2:0] optimal_pass;          // Expected pass number
reg optimal_should_swap;         // Whether swap is needed
reg optimal_sorted;              // Completion flag

// User action tracking
reg user_swapped;                // User's decision
reg user_action_correct;         // Validation result

// Bubble sort order tracking
reg [2:0] expected_pos;          // Expected next comparison position (0-4)
reg [2:0] current_pass;          // Current bubble sort pass (0-5)
reg [2:0] pass_limit;            // Upper limit for current pass (decreases each pass)
```

**Validation Logic:**
```verilog
// In TUTORIAL_SELECT state:
// Check if user is at correct position
if (cursor_pos == expected_pos) begin
    // Correct position! Now check swap/skip decision
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
end
```

**Progress Tracking:**
```verilog
// Progress percentage based on ordered pairs
progress_percent <=
    ((array[0] <= array[1] ? 20 : 0) +
     (array[1] <= array[2] ? 20 : 0) +
     (array[2] <= array[3] ? 20 : 0) +
     (array[3] <= array[4] ? 20 : 0) +
     (array[4] <= array[5] ? 20 : 0));
```

**Design Rationale:**
- 5 ordered pairs × 20% = 100% total progress
- Simple linear approximation
- Real-time visual feedback

#### Array Initialization and Editing

```verilog
// SETUP_EDIT state: User navigates and edits values
if (btn_l_edge) begin
    cursor_pos <= (cursor_pos == 0) ? 5 : cursor_pos - 1;  // Wrap left
end else if (btn_r_edge) begin
    cursor_pos <= (cursor_pos == 5) ? 0 : cursor_pos + 1;  // Wrap right
end

if (btn_u_edge) begin
    array[cursor_pos] <= (array[cursor_pos] == 7) ? 0 : array[cursor_pos] + 1;  // Wrap 0-7
end else if (btn_d_edge) begin
    array[cursor_pos] <= (array[cursor_pos] == 0) ? 7 : array[cursor_pos] - 1;  // Wrap 0-7
end
```

**Value Range:** 0-7 (3-bit values)
**Rationale:** Simplifies display rendering and reduces logic complexity

#### Swap Animation (16 Frames)

```verilog
// TUTORIAL_SWAP_ANIM state
if (frame_tick) begin
    anim_counter <= anim_counter + 1;
    anim_frame <= anim_counter;
end

// Perform actual swap at midpoint (frame 8)
if (anim_counter == 8) begin
    array[cursor_pos] <= array[cursor_pos + 1];
    array[cursor_pos + 1] <= array[cursor_pos];
end

// Animation complete at frame 15
if (anim_counter == 15) begin
    user_action_correct <= optimal_should_swap;
    if (optimal_should_swap) begin
        total_correct_swaps <= total_correct_swaps + 1;
    end
    anim_counter <= 0;
    anim_frame <= 0;
end
```

**Animation Duration:** 16 frames ÷ 60 Hz = 0.267 seconds

#### Feedback Display Timing

```verilog
// TUTORIAL_FEEDBACK state
feedback_correct <= user_action_correct;
feedback_incorrect <= !user_action_correct;

// Increment feedback timer
if (frame_tick) begin
    feedback_timer <= feedback_timer + 1;
end

// Display for ~1 second (60 frames)
if (feedback_timer >= 60) begin
    feedback_timer <= 0;
    next_state = TUTORIAL_CHECK_DONE;
end
```

---

### 3.3 Merge Sort Controller FSM

**Module:** `merge_sort_controller.v` (1882 lines)
**State Encoding:** 3-bit (8 states maximum)

#### State Machine Definition
```verilog
localparam STATE_IDLE = 3'b000;              // Waiting
localparam STATE_INIT = 3'b001;              // Initialize array
localparam STATE_DIVIDE = 3'b010;            // Divide phase animation
localparam STATE_MERGE = 3'b011;             // Merge phase animation
localparam STATE_SORTED = 3'b100;            // Complete
localparam STATE_TUTORIAL_INIT = 3'b101;     // Tutorial: Initialize to zeros
localparam STATE_TUTORIAL_EDIT = 3'b110;     // Tutorial: User edits array
localparam STATE_TUTORIAL_DIVIDE = 3'b111;   // Tutorial: Auto divide + practice
```

#### Divide Phase Visualization (3-Step)

```verilog
localparam DIVIDE_STEP_1 = 3'd0;   // [426] vs [153]
localparam DIVIDE_STEP_2 = 3'd1;   // [42][6] vs [15][3]
localparam DIVIDE_STEP_3 = 3'd2;   // [4][2][6] vs [1][5][3]
localparam DIVIDE_COMPLETE = 3'd3; // Divide visualization complete
```

**Visual Representation:**
```
Step 0 (Initial):
┌───┬───┬───┬───┬───┬───┐
│ 4 │ 2 │ 6 │ 1 │ 5 │ 3 │
└───┴───┴───┴───┴───┴───┘

Step 1 (Split into 2):
┌───────────┐   ┌───────────┐
│  4  2  6  │   │  1  5  3  │
└───────────┘   └───────────┘

Step 2 (Split into 4):
┌─────┬───┐   ┌─────┬───┐
│ 4 2 │ 6 │   │ 1 5 │ 3 │
└─────┴───┘   └─────┴───┘

Step 3 (Split into 6):
┌───┬───┬───┐ ┌───┬───┬───┐
│ 4 │ 2 │ 6 │ │ 1 │ 5 │ 3 │
└───┴───┴───┘ └───┴───┴───┘
```

#### Position and Color Management

```verilog
// Position definitions (Y coordinates on OLED)
localparam POS_TOP = 6'd8;       // Top of screen (y=8)
localparam POS_MID = 6'd32;      // Middle of screen (y=32)
localparam POS_BOTTOM = 6'd48;   // Bottom of screen (y=48)

// X position definitions (box slot positions)
// BOX_WIDTH = 14, spacing = 2, margin = 1
localparam X_SLOT_0 = 7'd1;   // Slot 0: 1 + 0*(14+2) = 1
localparam X_SLOT_1 = 7'd17;  // Slot 1: 1 + 1*(14+2) = 17
localparam X_SLOT_2 = 7'd33;  // Slot 2: 1 + 2*(14+2) = 33
localparam X_SLOT_3 = 7'd49;  // Slot 3: 1 + 3*(14+2) = 49
localparam X_SLOT_4 = 7'd65;  // Slot 4: 1 + 4*(14+2) = 65
localparam X_SLOT_5 = 7'd81;  // Slot 5: 1 + 5*(14+2) = 81
```

**Color Encoding (3-bit):**
```verilog
localparam COLOR_NORMAL = 3'b000;    // White (default)
localparam COLOR_ACTIVE = 3'b001;    // Red (being processed)
localparam COLOR_SORTED = 3'b010;    // Green (final sorted position)
localparam COLOR_COMPARE = 3'b011;   // Yellow (being compared)
localparam COLOR_GROUP1 = 3'b100;    // Magenta (Box 0)
localparam COLOR_GROUP2 = 3'b101;    // Cyan (Box 3)
localparam COLOR_GROUP3 = 3'b110;    // Orange (Box 2)
localparam COLOR_GROUP4 = 3'b111;    // Blue (Box 5)
```

#### Clock Domain Crossing (CDC) Architecture

**Problem:** Button inputs arrive on 100 MHz `clk` domain, but FSM operates on ~45 Hz `clk_movement` domain.

**Solution:** Handshake protocol with 2-stage synchronizers

```verilog
// Request flags (set in clk domain, cleared when ack seen)
reg cursor_left_req;
reg cursor_right_req;
reg value_up_req;
reg value_down_req;
reg check_answer_req;

// Acknowledge flags (set in clk_movement domain)
reg cursor_left_ack;
reg cursor_right_ack;
reg value_up_ack;
reg value_down_ack;
reg check_answer_ack;

// CDC Synchronizers (2-stage) for req signals (clk → clk_movement)
reg [1:0] cursor_left_req_sync;
reg [1:0] cursor_right_req_sync;
reg [1:0] value_up_req_sync;
reg [1:0] value_down_req_sync;
reg [1:0] check_answer_req_sync;

// CDC Synchronizers (2-stage) for ack signals (clk_movement → clk)
reg [1:0] cursor_left_ack_sync;
reg [1:0] cursor_right_ack_sync;
reg [1:0] value_up_ack_sync;
reg [1:0] value_down_ack_sync;
reg [1:0] check_answer_ack_sync;
```

**Synchronizer Implementation:**
```verilog
// In clk domain:
always @(posedge clk) begin
    cursor_left_ack_sync <= {cursor_left_ack_sync[0], cursor_left_ack};
    // Repeat for other signals
end

// In clk_movement domain:
always @(posedge clk_movement) begin
    cursor_left_req_sync <= {cursor_left_req_sync[0], cursor_left_req};
    // Repeat for other signals
end
```

**Handshake Protocol:**
```verilog
// clk domain: Detect button press and set request
if (btn_left_edge && !cursor_left_req && !cursor_left_ack_sync[1]) begin
    cursor_left_req <= 1'b1;  // Set request
end else if (cursor_left_req && cursor_left_ack_sync[1]) begin
    cursor_left_req <= 1'b0;  // Clear when acknowledged
end

// clk_movement domain: Process request and set acknowledge
if (cursor_left_req_sync[1] && !cursor_left_ack) begin
    // Process cursor movement
    cursor_pos <= (cursor_pos == 0) ? 5 : cursor_pos - 1;
    cursor_left_ack <= 1'b1;  // Acknowledge processed
end else if (!cursor_left_req_sync[1] && cursor_left_ack) begin
    cursor_left_ack <= 1'b0;  // Clear acknowledge
end
```

**Design Rationale:**
- 2-stage synchronizer prevents metastability
- Handshake ensures no missed button presses
- Request-acknowledge pattern guarantees single execution per press

#### Debounce Implementation (200ms)

```verilog
// Debounce timers at 100 MHz
reg [19:0] debounce_left;    // ~10ms debounce
reg [19:0] debounce_right;
reg [19:0] debounce_up;
reg [19:0] debounce_down;
reg [19:0] debounce_center;

// Decrement timers every cycle
always @(posedge clk) begin
    if (debounce_left > 20'd0) debounce_left <= debounce_left - 1;
    if (debounce_right > 20'd0) debounce_right <= debounce_right - 1;
    // ...
end

// Accept button press only if debounce expired
if (btn_left_edge && !cursor_left_req && !cursor_left_ack_sync[1] &&
    debounce_left == 20'd0) begin
    cursor_left_req <= 1'b1;
    debounce_left <= 20'd20000000;  // 200ms at 100MHz
end
```

**Timer Value:** 20,000,000 cycles × 10 ns = 200 ms
**Rationale:** Prevents double-triggering from mechanical bouncing

#### Tutorial Practice Mode Architecture

```verilog
// Practice mode registers
reg tutorial_practice_mode;           // Flag: show 2 rows of boxes
reg [2:0] user_answer_array [0:5];    // User's answer (top row)
reg [2:0] tutorial_merge_step_target; // Which merge step (0-2)
reg tutorial_answer_correct;          // Validation flag
reg [4:0] user_separator_lines;       // User's separator positions (sw0-4)
reg [7:0] flash_timer;                // Green flash animation timer
reg tutorial_animating;               // Currently animating merge
reg [5:0] element_correct;            // Per-element correctness (6 boxes)
reg [4:0] separator_correct;          // Per-separator correctness (5 separators)
reg all_correct;                      // All elements AND separators correct
```

**Validation Logic:**
```verilog
// Check each element against expected merged result
for (i = 0; i < 6; i = i + 1) begin
    element_correct[i] <= (user_answer_array[i] == expected_merge_result[i]);
end

// Check separator placement
for (i = 0; i < 5; i = i + 1) begin
    separator_correct[i] <= (user_separator_lines[i] == expected_separators[i]);
end

// Combined correctness
all_correct <= (&element_correct) && (&separator_correct);
```

#### Merge Region Pulsing Effect

```verilog
// Pulsing effect for active merge regions
reg [5:0] pulse_timer;       // Timer for pulsing effect (~0.5s cycle at 45Hz)
reg pulse_state;             // Toggles every 0.5s for pulsing effect
reg [5:0] merge_region_active;  // Which answer boxes should pulse (1=active)

// Pulse timer logic (at clk_movement ~45 Hz)
always @(posedge clk_movement) begin
    if (pulse_timer >= 6'd22) begin  // 22 cycles ≈ 0.5 seconds
        pulse_timer <= 0;
        pulse_state <= ~pulse_state;  // Toggle state
    end else begin
        pulse_timer <= pulse_timer + 1;
    end
end
```

**Visual Effect:** Active merge regions alternate between bright and dim colors

---

## 4. Clock Management & Timing Systems

### 4.1 Clock Architecture Overview

```
100 MHz System Clock (clk) - Basys 3 onboard oscillator
    │
    ├─→ clk_6p25MHz (OLED interface)
    │   └─ Generated by: counter [3:0] divides by 16
    │
    ├─→ clk_movement (~45 Hz animations)
    │   └─ Generated by: counter [20:0] divides by ~2,222,222
    │
    ├─→ clk_1hz_pulse (Bubble Sort steps)
    │   └─ Generated by: counter [26:0] divides by 100,000,000
    │
    ├─→ frame_tick (~60 Hz)
    │   └─ Generated by: counter [20:0] divides by 1,666,667
    │
    ├─→ ce_30hz (Insertion Sort animations)
    │   └─ Generated by: Clock_Generator module
    │
    └─→ clk_1ms (Selection Sort timing)
        └─ Generated by: counter [16:0] divides by 50,000
```

### 4.2 Clock Divider Implementation: `clock_divider.v`

**Location:** `2026_project.srcs/sources_1/new/clock_divider.v`
**Size:** 56 lines

```verilog
module clock_divider(
    input wire clk_100mhz,     // 100 MHz input clock
    input wire rst,            // Active high reset
    output reg clk_6p25mhz,    // 6.25 MHz clock for OLED
    output reg clk_1hz_pulse   // 1 Hz pulse for sort operations
);
```

#### 6.25 MHz Clock Generation

```verilog
// Counter for 6.25 MHz clock (divide by 16)
reg [3:0] counter_6p25mhz;

always @(posedge clk_100mhz or posedge rst) begin
    if (rst) begin
        counter_6p25mhz <= 0;
        clk_6p25mhz <= 0;
    end else begin
        if (counter_6p25mhz == 4'd7) begin
            counter_6p25mhz <= 0;
            clk_6p25mhz <= ~clk_6p25mhz;  // Toggle every 8 cycles
        end else begin
            counter_6p25mhz <= counter_6p25mhz + 1;
        end
    end
end
```

**Calculation:**
- Toggle every 8 cycles: 100 MHz ÷ 8 = 12.5 MHz
- Clock period (full cycle): 12.5 MHz ÷ 2 = 6.25 MHz
- Counter width: 4 bits (maximum 15, using 0-7)

**Design Rationale:**
- 6.25 MHz meets OLED SPI timing requirements
- Simple power-of-2 division (efficient in FPGA)
- Synchronous design prevents glitches

#### 1 Hz Pulse Generation

```verilog
// Counter for 1 Hz pulse (divide by 100,000,000)
// Need 27 bits to count to 100,000,000 (2^27 = 134,217,728)
reg [26:0] counter_1hz;

always @(posedge clk_100mhz or posedge rst) begin
    if (rst) begin
        counter_1hz <= 0;
        clk_1hz_pulse <= 0;
    end else begin
        if (counter_1hz == 27'd99_999_999) begin
            counter_1hz <= 0;
            clk_1hz_pulse <= 1;  // Single cycle pulse
        end else begin
            counter_1hz <= counter_1hz + 1;
            clk_1hz_pulse <= 0;
        end
    end
end
```

**Calculation:**
- 1 second = 100,000,000 cycles at 100 MHz
- Counter counts 0 to 99,999,999 (100M values)
- Pulse width: 1 cycle = 10 ns
- Counter width: 27 bits (2^27 = 134,217,728 > 100,000,000)

**Design Rationale:**
- Single-cycle pulse prevents multi-step execution
- 27-bit counter minimizes resource usage
- Pulse-based design (not continuous clock) for event triggering

### 4.3 Movement Clock (~45 Hz)

**Implementation in `sorting_visualizer_top.v`:**

```verilog
reg [20:0] clk_counter_movement = 0;
reg clk_movement = 0;

// ~45Hz movement clock for animations
always @(posedge clk) begin
    clk_counter_movement <= clk_counter_movement + 1;
    if (clk_counter_movement >= 21'd1111111) begin
        clk_counter_movement <= 0;
        clk_movement <= ~clk_movement;
    end
end
```

**Calculation:**
- Toggle period: 1,111,111 cycles
- Toggle frequency: 100 MHz ÷ 1,111,111 = 90 Hz
- Clock frequency: 90 Hz ÷ 2 = 45 Hz
- Actual period: 22.22 ms per cycle

**Counter Width:** 21 bits (2^21 = 2,097,152 > 1,111,111)

**Design Rationale:**
- 45 Hz provides smooth animation without excessive updates
- Balances visual quality and resource usage
- Matches typical animation frame rates (30-60 Hz)

### 4.4 Frame Tick (~60 Hz)

**Implementation in `sorting_visualizer_top.v` and `bubble_sort_fsm.v`:**

```verilog
// Frame tick generator for animations (~60 Hz)
// At 100MHz clock: 100,000,000 / 60 = 1,666,667 cycles per frame
reg [20:0] frame_counter;
wire frame_tick = (frame_counter >= 21'd1666666);

always @(posedge clk or posedge rst) begin
    if (rst)
        frame_counter <= 0;
    else if (frame_tick)
        frame_counter <= 0;
    else
        frame_counter <= frame_counter + 1;
end
```

**Calculation:**
- Target: 60 Hz frame rate
- Cycles per frame: 100,000,000 ÷ 60 = 1,666,667
- Counter counts 0 to 1,666,666 (1,666,667 values)
- Actual frequency: 100 MHz ÷ 1,666,667 = 59.99998 Hz

**Counter Width:** 21 bits (2^21 = 2,097,152 > 1,666,667)

**Design Rationale:**
- Synchronized with OLED refresh rate (60 Hz)
- Single-cycle pulse for animation frame updates
- Prevents animation tearing and stuttering

### 4.5 OLED Display Clock (Oled_Display Module)

**Module:** `Oled_Display.v` (399 lines)
**Clock Input:** 6.25 MHz (`clk_6p25MHz`)

```verilog
parameter ClkFreq = 6250000; // Hz
input clk, reset;

// Frame begin event
localparam FrameFreq = 60;
localparam FrameDiv = ClkFreq / FrameFreq;  // 6,250,000 / 60 = 104,167
localparam FrameDivWidth = $clog2(FrameDiv);  // 17 bits

reg [FrameDivWidth-1:0] frame_counter;
assign frame_begin = frame_counter == 0;
```

**Calculation:**
- Frame period at 60 Hz: 1/60 = 16.67 ms
- Cycles per frame: 6,250,000 × 0.01667 = 104,167 cycles
- Counter width: ceil(log2(104,167)) = 17 bits

**Design Rationale:**
- 60 Hz provides flicker-free display
- Matches standard video frame rates
- Synchronized with animation frame ticks

---

## 5. Debouncing Architecture

### 5.1 Multi-Button Debouncer: `button_debounce_5btn.v`

**Location:** `2026_project.srcs/sources_1/new/button_debounce_5btn.v`
**Size:** 200 lines
**Purpose:** Debounce all 5 Basys 3 buttons with edge detection

```verilog
module button_debounce_5btn(
    input wire clk,              // 100 MHz system clock
    input wire reset,            // Synchronous reset
    input wire btnL, btnR, btnU, btnD, btnC,  // Raw button inputs
    output reg btn_l_edge,       // Left button rising edge pulse
    output reg btn_r_edge,       // Right button rising edge pulse
    output reg btn_u_edge,       // Up button rising edge pulse
    output reg btn_d_edge,       // Down button rising edge pulse
    output reg btn_c_edge        // Center button rising edge pulse
);
```

#### Debouncing Algorithm

**Threshold-Based Counter Method:**
```verilog
// Debounce threshold: 999,999 cycles = ~10ms at 100MHz
localparam DEBOUNCE_THRESHOLD = 999_999;

// Counters for each button (20 bits to hold up to 1,048,575)
reg [19:0] btn_counter_l;
reg [19:0] btn_counter_r;
reg [19:0] btn_counter_u;
reg [19:0] btn_counter_d;
reg [19:0] btn_counter_c;

// Synchronized button states
reg btn_l_sync, btn_l_prev;
// Repeat for other buttons...
```

**Per-Button Logic (Example: Left Button):**
```verilog
always @(posedge clk) begin
    if (reset) begin
        btn_counter_l <= 0;
        btn_l_sync <= 0;
        btn_l_prev <= 0;
        btn_l_edge <= 0;
    end else begin
        // Increment counter while button is pressed
        if (btnL) begin
            if (btn_counter_l < DEBOUNCE_THRESHOLD) begin
                btn_counter_l <= btn_counter_l + 1;
            end else begin
                btn_l_sync <= 1;  // Button confirmed pressed
            end
        end else begin
            btn_counter_l <= 0;  // Reset counter on release
            btn_l_sync <= 0;
        end

        // Edge detection
        btn_l_prev <= btn_l_sync;
        btn_l_edge <= btn_l_sync && !btn_l_prev;  // Rising edge
    end
end
```

#### Timing Diagram

```
Raw Button Input (bouncy):
         ┌─┐ ┌┐┌┐  ┌────────────────────┐
         │ │ ││││  │                    │
─────────┘ └─┘└┘└──┘                    └────
         ←─────10ms──→

Counter Value:
         0 123401234  0→1→2→...→999,999 (stable)

btn_sync:
                      ┌──────────────────┐
──────────────────────┘                  └────

btn_edge (single-cycle pulse):
                      ┌┐
──────────────────────┘└───────────────────────
```

#### Design Rationale

1. **Threshold Method vs. Shift Register:**
   - Threshold method: Requires button to be stable for N consecutive cycles
   - Shift register method: Requires all bits of shift register to match
   - Threshold chosen for: simpler logic, lower resource usage

2. **10ms Debounce Time:**
   - Typical mechanical button bounce duration: 5-10 ms
   - 999,999 cycles × 10 ns = 9.99999 ms
   - Provides margin for worst-case bounce scenarios

3. **Counter Width (20 bits):**
   - Maximum value needed: 999,999
   - 2^20 = 1,048,576 > 999,999
   - Minimum bits to represent threshold

4. **Edge Detection:**
   - Previous state register (`btn_l_prev`) delays by 1 cycle
   - Rising edge: `btn_sync && !btn_l_prev`
   - Single-cycle pulse for FSM inputs

### 5.2 Alternative Debouncing (Merge Sort Controller)

**Additional 200ms Debounce Layer:**
```verilog
// Debounce timers to prevent double triggering (at 100MHz)
reg [19:0] debounce_left;   // ~200ms debounce
reg [19:0] debounce_right;
reg [19:0] debounce_up;
reg [19:0] debounce_down;
reg [19:0] debounce_center;

// ALWAYS decrement debounce timers (unconditional)
always @(posedge clk) begin
    if (debounce_left > 20'd0) debounce_left <= debounce_left - 1;
    if (debounce_right > 20'd0) debounce_right <= debounce_right - 1;
    // ...
end

// Accept button press only if debounce expired AND handshake idle
if (btn_left_edge && !cursor_left_req && !cursor_left_ack_sync[1] &&
    debounce_left == 20'd0) begin
    cursor_left_req <= 1'b1;
    debounce_left <= 20'd20000000;  // 200ms at 100MHz
end
```

**Calculation:**
- 20,000,000 cycles × 10 ns = 200 ms
- Counter width: 25 bits needed (2^25 = 33,554,432 > 20,000,000)
- **Note:** Code uses 20-bit counter (overflow issue - should be [24:0])

**Design Rationale:**
- Prevents rapid repeated button presses
- User must wait 200 ms between presses
- Improves user experience in tutorial mode

---

## 6. Register Architectures & Memory Systems

### 6.1 Data Word Organization

#### Bubble Sort Arrays
```verilog
// Educational Mode (8-bit values: 0-255)
reg [7:0] array [0:5];  // 6 × 8-bit = 48 bits total

// Individual output ports (for module interface)
output reg [7:0] array0, array1, array2, array3, array4, array5;

// Continuous assignment
always @(*) begin
    array0 = array[0];
    array1 = array[1];
    array2 = array[2];
    array3 = array[3];
    array4 = array[4];
    array5 = array[5];
end
```

**Memory Organization:**
```
Address  | Value  | Bit Width
---------|--------|----------
array[0] | 0-255  | 8 bits
array[1] | 0-255  | 8 bits
array[2] | 0-255  | 8 bits
array[3] | 0-255  | 8 bits
array[4] | 0-255  | 8 bits
array[5] | 0-255  | 8 bits
---------|--------|----------
Total:   |        | 48 bits
```

#### Merge Sort Arrays (Flattened)
```verilog
// Internal arrays (for easier manipulation)
reg [2:0] array_data [0:5];           // 6 × 3-bit values (0-7)
reg [5:0] array_positions_y [0:5];    // 6 × 6-bit Y positions
reg [6:0] array_positions_x [0:5];    // 6 × 7-bit X positions
reg [2:0] array_colors [0:5];         // 6 × 3-bit color codes

// Flattened outputs (for module ports)
output reg [17:0] array_data_flat;         // 6 × 3 = 18 bits
output reg [35:0] array_positions_y_flat;  // 6 × 6 = 36 bits
output reg [41:0] array_positions_x_flat;  // 6 × 7 = 42 bits
output reg [17:0] array_colors_flat;       // 6 × 3 = 18 bits

// Flattening logic (concatenation)
always @(*) begin
    array_data_flat = {array_data[5], array_data[4], array_data[3],
                      array_data[2], array_data[1], array_data[0]};
    // Repeat for other signals...
end
```

**Bit Layout Example (array_data_flat):**
```
[17:15] → array_data[5]
[14:12] → array_data[4]
[11:9]  → array_data[3]
[8:6]   → array_data[2]
[5:3]   → array_data[1]
[2:0]   → array_data[0]
```

**Design Rationale:**
- Verilog synthesis tools prefer flat signals for module ports
- Internal 2D arrays simplify indexing and manipulation
- Flattening/unflattening logic synthesizes to wires (no logic cost)

### 6.2 Color Encoding System

```verilog
// 3-bit color codes (RGB mapping in pixel generators)
localparam COLOR_NORMAL = 3'b000;    // White  (RGB: 16'hFFFF)
localparam COLOR_ACTIVE = 3'b001;    // Red    (RGB: 16'hF800)
localparam COLOR_SORTED = 3'b010;    // Green  (RGB: 16'h07E0)
localparam COLOR_COMPARE = 3'b011;   // Yellow (RGB: 16'hFFE0)
localparam COLOR_GROUP1 = 3'b100;    // Magenta
localparam COLOR_GROUP2 = 3'b101;    // Cyan
localparam COLOR_GROUP3 = 3'b110;    // Orange
localparam COLOR_GROUP4 = 3'b111;    // Blue
```

**RGB565 Format:**
```
Bit Position: [15:11] [10:5] [4:0]
Color:        RED     GREEN  BLUE
Resolution:   5-bit   6-bit  5-bit
```

**Example Conversions:**
- White:  `16'hFFFF` = `11111_111111_11111` (all channels max)
- Red:    `16'hF800` = `11111_000000_00000` (red max, others 0)
- Green:  `16'h07E0` = `00000_111111_00000` (green max, others 0)
- Yellow: `16'hFFE0` = `11111_111111_00000` (red + green max)
- Blue:   `16'h001F` = `00000_000000_11111` (blue max, others 0)

### 6.3 Position and Animation Registers

#### Box Position Calculation (Merge Sort)
```verilog
// Current positions (animated)
reg [5:0] array_positions_y [0:5];  // Y: 0-63 (OLED height: 64)
reg [6:0] array_positions_x [0:5];  // X: 0-95 (OLED width: 96)

// Target positions (for animation goals)
reg [5:0] target_y [0:5];
reg [6:0] target_x [0:5];

// Animation logic (at clk_movement ~45 Hz)
always @(posedge clk_movement) begin
    for (i = 0; i < 6; i = i + 1) begin
        // Interpolate Y position
        if (array_positions_y[i] < target_y[i]) begin
            array_positions_y[i] <= array_positions_y[i] + 1;
        end else if (array_positions_y[i] > target_y[i]) begin
            array_positions_y[i] <= array_positions_y[i] - 1;
        end

        // Interpolate X position
        if (array_positions_x[i] < target_x[i]) begin
            array_positions_x[i] <= array_positions_x[i] + 1;
        end else if (array_positions_x[i] > target_x[i]) begin
            array_positions_x[i] <= array_positions_x[i] - 1;
        end
    end
end
```

**Animation Speed:**
- Update rate: 45 Hz (every 22.22 ms)
- Position increment: 1 pixel per frame
- Example: Moving 16 pixels takes 16 frames ÷ 45 Hz = 0.356 seconds

#### Bubble Sort Animation Offsets
```verilog
// Pre-calculated box positions for each box (with animation offsets applied)
reg [7:0] box_x_pos [0:5];  // X position of each box (8 bits for safety)
reg [6:0] box_y_pos [0:5];  // Y position of each box (7 bits for safety)

// Calculate box positions with animation offsets
wire [5:0] scaled_progress = (anim_progress >= 28) ? BOX_TOTAL : scaled_calc[5:0];

always @(*) begin
    // Initialize all boxes to their default positions
    for (k = 0; k < 6; k = k + 1) begin
        box_x_pos[k] = ARRAY_X_OFFSET + k * BOX_TOTAL;
        box_y_pos[k] = BOX_Y_START;
    end

    // Apply animation offsets when swapping
    if (swap_flag) begin
        case (anim_phase)
            2'b00: begin  // Phase 0: compare_idx1 moves UP
                box_y_pos[compare_idx1] = BOX_Y_START - scaled_progress;
            end

            2'b01: begin  // Phase 1: compare_idx2 moves LEFT
                box_y_pos[compare_idx1] = BOX_Y_START - ANIM_UP_DISTANCE;
                box_x_pos[compare_idx2] = (ARRAY_X_OFFSET + compare_idx2 * BOX_TOTAL) - scaled_progress;
            end
            // ... (phases 2 and 3)
        endcase
    end
end
```

**Scaling Calculation:**
```verilog
// Scale anim_progress (0-29) to pixel distance (0-16)
wire [9:0] scaled_calc = (anim_progress * 17) >> 5;
// Explanation: (anim_progress * 17) / 32
// At anim_progress = 29: (29 * 17) / 32 = 493 / 32 = 15.4 ≈ 15 pixels
// Clamp to 16 at final frames for smooth transitions
```

### 6.4 Insertion Sort Frame Buffer (BRAM)

**Module:** `Frame_Buffer.v` (76 lines)
**Technology:** Block RAM (BRAM) - FPGA dedicated memory resource

```verilog
module Frame_Buffer(
    input wire write_clk,        // 100 MHz (from Oled_Renderer)
    input wire read_clk,         // 6.25 MHz (to OLED display)
    input wire write_enable,
    input wire [12:0] write_addr,  // 0-6143 (96 × 64 = 6144 pixels)
    input wire [15:0] write_data,  // RGB565 color
    input wire [12:0] read_addr,
    output reg [15:0] read_data
);

// Dual-port BRAM: 6144 pixels × 16-bit RGB565
(* ram_style = "block" *) reg [15:0] buffer [0:6143];

// Write port (100 MHz)
always @(posedge write_clk) begin
    if (write_enable) begin
        buffer[write_addr] <= write_data;
    end
end

// Read port (6.25 MHz)
always @(posedge read_clk) begin
    read_data <= buffer[read_addr];
end

// Initialize to black
integer i;
initial begin
    for (i = 0; i < 6144; i = i + 1) begin
        buffer[i] = 16'h0000;  // Black
    end
end
endmodule
```

**Memory Specifications:**
- **Capacity:** 6144 pixels × 16 bits = 98,304 bits = 12 KB
- **Type:** Dual-port BRAM (simultaneous read/write)
- **Write Port:** 100 MHz (renderer domain)
- **Read Port:** 6.25 MHz (OLED domain)
- **Addressing:** 13-bit (2^13 = 8192 > 6144)

**BRAM Inference:**
```verilog
(* ram_style = "block" *) reg [15:0] buffer [0:6143];
```
- Synthesis attribute forces BRAM usage (not distributed RAM or registers)
- Xilinx Vivado recognizes dual-port pattern
- Optimized for Artix-7 FPGA architecture

**Design Rationale:**
- Separates rendering (combinational logic) from display (sequential readout)
- Prevents tearing: complete frame written before display
- Clock domain isolation: write and read at different frequencies

---

## 7. Animation System & Coordinate Tracking

### 7.1 Bubble Sort 4-Phase Swap Animation

#### Phase 0: Vertical Lift (Frames 0-59)
```verilog
// Phase 0: compare_idx1 moves UP (from 0 to ANIM_UP_DISTANCE)
box_y_pos[compare_idx1] = BOX_Y_START - scaled_progress;
```

**Animation Curve:**
```
Y Position vs Frame Number (Phase 0)

Y_offset (pixels)
  16 │                            ●────────
     │                        ●●●●
     │                    ●●●●
  12 │                ●●●●
     │            ●●●●
     │        ●●●●
   8 │    ●●●●
     │●●●●
   4 │●
     │
   0 └─────────────────────────────────────
     0   10   20   30   40   50   60 (frames)
```

#### Phase 1: Horizontal Slide (Frames 60-119)
```verilog
// Phase 1: compare_idx1 stays UP, compare_idx2 moves LEFT
box_y_pos[compare_idx1] = BOX_Y_START - ANIM_UP_DISTANCE;  // Keep elevated
box_x_pos[compare_idx1] = ARRAY_X_OFFSET + compare_idx1 * BOX_TOTAL;
box_x_pos[compare_idx2] = (ARRAY_X_OFFSET + compare_idx2 * BOX_TOTAL) - scaled_progress;
```

**Visual Representation:**
```
Start of Phase 1:
    ┌───┐
    │ 5 │ (elevated)
    └───┘
┌───┬───┬───┬───┬───┐
│ 4 │ 2 │ 6 │ 1 │ 3 │
└───┴───┴───┴───┴───┘
      ↑
  compare_idx2

End of Phase 1:
    ┌───┐
    │ 5 │ (elevated)
    └───┘
┌───┬───┬───┬───┬───┐
│ 4 │ 6 │ 1 │ 3 │   │
└───┴───┴───┴───┴───┘
  ↑
compare_idx2 moved left
```

#### Phase 2: Cross Over (Frames 120-179)
```verilog
// Phase 2: compare_idx1 moves RIGHT (still elevated), compare_idx2 stays
box_y_pos[compare_idx1] = BOX_Y_START - ANIM_UP_DISTANCE;
box_x_pos[compare_idx1] = (ARRAY_X_OFFSET + compare_idx1 * BOX_TOTAL) + scaled_progress;
box_x_pos[compare_idx2] = (ARRAY_X_OFFSET + compare_idx2 * BOX_TOTAL) - BOX_TOTAL;
```

**Visual Representation:**
```
Start of Phase 2:
    ┌───┐
    │ 5 │ (elevated)
    └───┘
┌───┬───┬───┬───┬───┐
│ 4 │ 6 │ 1 │ 3 │   │
└───┴───┴───┴───┴───┘

End of Phase 2:
        ┌───┐
        │ 5 │ (elevated, moved right)
        └───┘
┌───┬───┬───┬───┬───┐
│ 4 │ 6 │ 1 │ 3 │   │
└───┴───┴───┴───┴───┘
```

#### Phase 3: Vertical Descent (Frames 180-239)
```verilog
// Phase 3: compare_idx1 moves DOWN to final position
box_x_pos[compare_idx1] = (ARRAY_X_OFFSET + compare_idx1 * BOX_TOTAL) + BOX_TOTAL;
box_y_pos[compare_idx1] = (BOX_Y_START - ANIM_UP_DISTANCE) + scaled_progress;
box_x_pos[compare_idx2] = (ARRAY_X_OFFSET + compare_idx2 * BOX_TOTAL) - BOX_TOTAL;

// Actual data swap at midpoint (frame 8 of phase 3)
if (anim_counter == 8) begin
    array[i] <= array[i+1];
    array[i+1] <= temp;
end
```

**Visual Representation:**
```
Start of Phase 3:
        ┌───┐
        │ 5 │ (elevated)
        └───┘
┌───┬───┬───┬───┬───┐
│ 4 │ 6 │ 1 │ 3 │   │
└───┴───┴───┴───┴───┘

End of Phase 3 (swap complete):
┌───┬───┬───┬───┬───┬───┐
│ 4 │ 6 │ 5 │ 1 │ 3 │ 2 │
└───┴───┴───┴───┴───┴───┘
     ↑   ↑
   (swapped)
```

### 7.2 Merge Sort Position Interpolation

#### Target Position Assignment
```verilog
// Example: Divide step transitions
case (divide_step)
    DIVIDE_STEP_1: begin
        // Move to top and bottom rows
        target_y[0] = POS_TOP;    target_x[0] = X_SLOT_0;
        target_y[1] = POS_TOP;    target_x[1] = X_SLOT_1;
        target_y[2] = POS_TOP;    target_x[2] = X_SLOT_2;
        target_y[3] = POS_BOTTOM; target_x[3] = X_SLOT_3;
        target_y[4] = POS_BOTTOM; target_x[4] = X_SLOT_4;
        target_y[5] = POS_BOTTOM; target_x[5] = X_SLOT_5;
    end

    DIVIDE_STEP_2: begin
        // Rearrange to show grouping
        target_y[0] = POS_TOP;    target_x[0] = X_SLOT_0;
        target_y[1] = POS_TOP;    target_x[1] = X_SLOT_1;
        target_y[2] = POS_MID;    target_x[2] = X_SLOT_2;
        target_y[3] = POS_BOTTOM; target_x[3] = X_SLOT_3;
        target_y[4] = POS_BOTTOM; target_x[4] = X_SLOT_4;
        target_y[5] = POS_MID;    target_x[5] = X_SLOT_5;
    end
endcase
```

#### Linear Interpolation Logic
```verilog
// Animation logic (at clk_movement ~45 Hz)
always @(posedge clk_movement) begin
    for (i = 0; i < 6; i = i + 1) begin
        // Y position interpolation (1 pixel per frame)
        if (array_positions_y[i] < target_y[i]) begin
            array_positions_y[i] <= array_positions_y[i] + 1;  // Move down
        end else if (array_positions_y[i] > target_y[i]) begin
            array_positions_y[i] <= array_positions_y[i] - 1;  // Move up
        end

        // X position interpolation (1 pixel per frame)
        if (array_positions_x[i] < target_x[i]) begin
            array_positions_x[i] <= array_positions_x[i] + 1;  // Move right
        end else if (array_positions_x[i] > target_x[i]) begin
            array_positions_x[i] <= array_positions_x[i] - 1;  // Move left
        end
    end
end
```

**Animation Characteristics:**
- **Speed:** 1 pixel per frame at 45 Hz = 45 pixels/second
- **Maximum Distance:** ~64 pixels (vertical) or ~80 pixels (horizontal)
- **Maximum Duration:** 80 pixels ÷ 45 pixels/s = 1.78 seconds

#### Animation Completion Detection
```verilog
// Check if all elements have reached target positions
integer pos_check;
reg all_positions_match;
always @(*) begin
    all_positions_match = 1'b1;
    for (pos_check = 0; pos_check < 6; pos_check = pos_check + 1) begin
        if (array_positions_y[pos_check] != target_y[pos_check]) begin
            all_positions_match = 1'b0;
        end
        if (array_positions_x[pos_check] != target_x[pos_check]) begin
            all_positions_match = 1'b0;
        end
    end
end
assign all_positions_reached = all_positions_match;
```

**Design Rationale:**
- Combinational logic for real-time status
- Used as handshake signal for FSM state transitions
- Ensures animations complete before next step

### 7.3 Separator Line Animation (Merge Sort)

```verilog
// Separator visibility and colors
reg [4:0] separator_visible;        // 5 separators × 1 bit each
reg [2:0] separator_colors [0:4];   // 5 separators × 3-bit color

// Separator positioning (vertical lines between boxes)
localparam SEP_0_X = X_SLOT_0 + BOX_WIDTH + (BOX_SPACING / 2);  // Between box 0 and 1
localparam SEP_1_X = X_SLOT_1 + BOX_WIDTH + (BOX_SPACING / 2);  // Between box 1 and 2
localparam SEP_2_X = X_SLOT_2 + BOX_WIDTH + (BOX_SPACING / 2);  // Between box 2 and 3
localparam SEP_3_X = X_SLOT_3 + BOX_WIDTH + (BOX_SPACING / 2);  // Between box 3 and 4
localparam SEP_4_X = X_SLOT_4 + BOX_WIDTH + (BOX_SPACING / 2);  // Between box 4 and 5
```

**Rendering Logic (in `merge_sort_display.v`):**
```verilog
// Check if current pixel is on a separator line
if (separator_visible[0] && x == SEP_0_X) begin
    pixel_data = separator_color_rgb[0];  // Draw separator 0
end else if (separator_visible[1] && x == SEP_1_X) begin
    pixel_data = separator_color_rgb[1];  // Draw separator 1
end
// ... (repeat for other separators)
```

**Tutorial Mode Validation:**
```verilog
// User sets separators with SW0-SW4
reg [4:0] user_separator_lines;       // User's input
reg [4:0] expected_separators;        // Correct answer
reg [4:0] separator_correct;          // Per-separator correctness

// Check each separator
for (i = 0; i < 5; i = i + 1) begin
    separator_correct[i] <= (user_separator_lines[i] == expected_separators[i]);

    // Color feedback
    if (all_correct && flash_timer < 30) begin
        separator_colors[i] <= COLOR_SORTED;  // Green flash
    end else if (!separator_correct[i]) begin
        separator_colors[i] <= COLOR_ACTIVE;  // Red (wrong)
    end else begin
        separator_colors[i] <= COLOR_NORMAL;  // White (correct)
    end
end
```

---

## 8. OLED Rendering Pipeline

### 8.1 OLED Display Controller: `Oled_Display.v`

**Module:** `Oled_Display.v` (399 lines)
**Function:** OLED initialization and SPI protocol controller

#### 32-State FSM for Display Initialization

```verilog
// State machine states (5-bit encoding)
localparam PowerUp = 5'b00000;
localparam Reset = 5'b00001;
localparam ReleaseReset = 5'b00011;
localparam EnableDriver = 5'b00010;
localparam DisplayOff = 5'b00110;
localparam SetRemapDisplayFormat = 5'b00111;
localparam SetStartLine = 5'b00101;
localparam SetOffset = 5'b00100;
localparam SetNormalDisplay = 5'b01100;
localparam SetMultiplexRatio = 5'b01101;
localparam SetMasterConfiguration = 5'b01111;
localparam DisablePowerSave = 5'b01110;
localparam SetPhaseAdjust = 5'b01010;
localparam SetDisplayClock = 5'b01011;
localparam SetSecondPrechargeA = 5'b01001;
localparam SetSecondPrechargeB = 5'b01000;
localparam SetSecondPrechargeC = 5'b11000;
localparam SetPrechargeLevel = 5'b11001;
localparam SetVCOMH = 5'b11011;
localparam SetMasterCurrent = 5'b11010;
localparam SetContrastA = 5'b11110;
localparam SetContrastB = 5'b11111;
localparam SetContrastC = 5'b11101;
localparam DisableScrolling = 5'b11100;
localparam ClearScreen = 5'b10100;
localparam VccEn = 5'b10101;
localparam DisplayOn = 5'b10111;
localparam PrepareNextFrame = 5'b10110;
localparam SetColAddress = 5'b10010;
localparam SetRowAddress = 5'b10011;
localparam WaitNextFrame = 5'b10001;
localparam SendPixel = 5'b10000;
```

#### SPI Protocol Implementation

```verilog
// SPI Master
localparam SpiCommandMaxWidth = 40;  // Maximum command length (bits)
reg [5:0] spi_word_bit_count;       // Bits remaining to send
reg [39:0] spi_word;                 // Shift register for SPI data

wire spi_busy = spi_word_bit_count != 0;
assign cs = !spi_busy;               // Chip select (active low)
assign sclk = clk | !spi_busy;       // Clock gating
assign sdin = spi_word[39] & spi_busy;  // MSB first

// Shift logic (on negedge clk for setup time)
always @(negedge clk) begin
    if (spi_word_bit_count > 1) begin
        spi_word_bit_count <= spi_word_bit_count - 1;
        spi_word <= {spi_word[38:0], 1'b0};  // Shift left
    end
end
```

**Timing Diagram:**
```
clk (6.25 MHz):
    ┌───┐   ┐   ┌───┐   ┌───┐
    │   │   │   │   │   │   │
────┘   └───┘   └───┘   └───┘

sclk (gated):
    ┌───┐   ┌───┐   ┌───┐   ┌───
    │   │   │   │   │   │   │
────┘   └───┘   └───┘   └───┘

cs (active low):
────┐                       ┌────
    │                       │
    └───────────────────────┘

sdin (data):
    ├─bit7─┤─bit6─┤─bit5─┤─bit4─
```

#### Frame Timing and Pixel Transmission

```verilog
// Frame begin event (60 Hz)
reg [16:0] frame_counter;
assign frame_begin = frame_counter == 0;

always @(negedge clk) begin
    frame_counter <= (frame_counter == FrameDiv-1) ? 0 : frame_counter + 1;
end

// Pixel sampling
assign sample_pixel = (state == WaitNextFrame && frame_begin) ||
                     (sending_pixels && frame_counter[3:0] == 0);
assign pixel_index = sending_pixels ?
                    frame_counter[FrameDivWidth-1:$clog2(16)] : 0;
```

**Pixel Transmission Rate:**
- Pixels per frame: 6144 (96 × 64)
- Frame rate: 60 Hz
- Pixel rate: 6144 × 60 = 368,640 pixels/second
- Bits per pixel: 16 (RGB565)
- Data rate: 368,640 × 16 = 5,898,240 bits/second ≈ 5.9 Mbps

### 8.2 Pixel Generator: `pixel_generator.v` (Bubble Sort)

**Module:** `pixel_generator.v` (395 lines)
**Function:** Combinational logic to generate RGB565 pixel data

```verilog
module pixel_generator(
    input wire [13:0] pixel_index,   // 0-6143 (pixel address)
    input wire [7:0] array0, array1, array2, array3, array4, array5,
    input wire [2:0] compare_idx1, compare_idx2,
    input wire swap_flag,
    input wire [5:0] anim_progress,
    input wire [1:0] anim_phase,
    input wire sorting,
    input wire done,
    output reg [15:0] pixel_data     // RGB565 output
);
```

#### Pixel Address Decoding

```verilog
localparam WIDTH = 96;
localparam HEIGHT = 64;

wire [6:0] x = pixel_index % WIDTH;   // X coordinate (0-95)
wire [5:0] y = pixel_index / WIDTH;   // Y coordinate (0-63)
```

**Calculation Example:**
- Pixel index 1000:
  - X = 1000 % 96 = 64
  - Y = 1000 / 96 = 10
  - Position: (64, 10)

#### Box Rendering Logic

```verilog
// Box specifications
localparam BOX_WIDTH = 14;
localparam BOX_HEIGHT = 10;
localparam BOX_SPACING = 2;
localparam BOX_TOTAL = BOX_WIDTH + BOX_SPACING;  // 16 pixels

// Center array horizontally
localparam ARRAY_WIDTH = 6 * BOX_WIDTH + 5 * BOX_SPACING;  // 94 pixels
localparam ARRAY_X_OFFSET = (WIDTH - ARRAY_WIDTH) / 2;     // 1 pixel

// Box vertical positioning
localparam BOX_Y_START = (HEIGHT - BOX_HEIGHT) / 2;  // ~27
localparam BOX_Y_END = BOX_Y_START + BOX_HEIGHT;     // ~37

// Check if pixel is inside a box
integer k;
reg inside_box;
reg [2:0] box_index;
always @(*) begin
    inside_box = 0;
    box_index = 0;
    for (k = 0; k < 6; k = k + 1) begin
        if (x >= box_x_pos[k] && x < box_x_pos[k] + BOX_WIDTH &&
            y >= box_y_pos[k] && y < box_y_pos[k] + BOX_HEIGHT) begin
            inside_box = 1;
            box_index = k;
        end
    end
end
```

#### Number Font Rendering (6×8 Bitmap)

```verilog
// 6x8 font bitmap (48 bits per character)
function digit_pixel;
    input [3:0] digit;
    input [2:0] px, py;  // px: 0-5, py: 0-7
    reg [47:0] font;
    reg [2:0] flipped_py;
    begin
        flipped_py = 7 - py;  // Flip vertically
        case (digit)
            0: font = 48'b011100_100010_100010_100010_100010_100010_100010_011100;
            1: font = 48'b001000_011000_001000_001000_001000_001000_001000_011100;
            2: font = 48'b011100_100010_000010_000100_001000_010000_100000_111110;
            // ... (digits 3-9)
        endcase
        digit_pixel = font[flipped_py * 6 + (5 - px)];
    end
endfunction
```

**Bitmap Layout Example (Digit '0'):**
```
Row 0: 011100  (  ███   )
Row 1: 100010  ( █   █  )
Row 2: 100010  ( █   █  )
Row 3: 100010  ( █   █  )
Row 4: 100010  ( █   █  )
Row 5: 100010  ( █   █  )
Row 6: 100010  ( █   █  )
Row 7: 011100  (  ███   )

Bit layout:
[47:42] = Row 0
[41:36] = Row 1
...
[5:0]   = Row 7
```

#### Color Selection Logic

```verilog
// Determine box color based on state
always @(*) begin
    if (inside_box) begin
        if (done) begin
            color = GREEN;  // Sorted
        end else if (swap_flag && (box_index == compare_idx1 || box_index == compare_idx2)) begin
            color = RED;    // Swapping
        end else if (box_index == compare_idx1 || box_index == compare_idx2) begin
            color = YELLOW; // Comparing
        end else begin
            color = WHITE;  // Normal
        end

        // Check if pixel is on border or inside number
        is_border = (x == box_x_pos[box_index]) ||
                   (x == box_x_pos[box_index] + BOX_WIDTH - 1) ||
                   (y == box_y_pos[box_index]) ||
                   (y == box_y_pos[box_index] + BOX_HEIGHT - 1);

        if (is_border) begin
            pixel_data = color;  // Draw border
        end else begin
            // Check if pixel is part of number
            x_in_box = x - box_x_pos[box_index];
            y_in_box = y - box_y_pos[box_index];
            num_x_start = (BOX_WIDTH - NUM_WIDTH) / 2;
            num_y_start = (BOX_HEIGHT - NUM_HEIGHT) / 2;

            if (x_in_box >= num_x_start && x_in_box < num_x_start + NUM_WIDTH &&
                y_in_box >= num_y_start && y_in_box < num_y_start + NUM_HEIGHT) begin
                // Inside number area
                if (digit_pixel(array_value[box_index],
                               x_in_box - num_x_start,
                               y_in_box - num_y_start)) begin
                    pixel_data = BLACK;  // Number pixel
                end else begin
                    pixel_data = color;  // Background
                end
            end else begin
                pixel_data = color;  // Background outside number
            end
        end
    end else begin
        pixel_data = background_pixel_color;  // Blue dots on black
    end
end
```

### 8.3 Tutorial Pixel Generator: `tutorial_pixel_generator.v`

**Module:** `tutorial_pixel_generator.v` (612 lines)
**Additional Features:** Progress bar, feedback icons, cursor highlighting

#### Progress Bar Rendering

```verilog
// Progress bar parameters
localparam PROGRESS_BAR_Y = 2;         // Top of screen
localparam PROGRESS_BAR_HEIGHT = 4;    // 4 pixels tall
localparam PROGRESS_BAR_WIDTH = 90;    // 90 pixels wide
localparam PROGRESS_BAR_X = (96 - PROGRESS_BAR_WIDTH) / 2;  // Center

// Calculate filled width based on progress_percent (0-100)
wire [6:0] filled_width = (progress_percent * PROGRESS_BAR_WIDTH) / 100;

// Render progress bar
if (y >= PROGRESS_BAR_Y && y < PROGRESS_BAR_Y + PROGRESS_BAR_HEIGHT &&
    x >= PROGRESS_BAR_X && x < PROGRESS_BAR_X + PROGRESS_BAR_WIDTH) begin

    if (x < PROGRESS_BAR_X + filled_width) begin
        pixel_data = GREEN;  // Filled portion
    end else begin
        pixel_data = WHITE;  // Unfilled portion
    end
end
```

**Visual Representation:**
```
Progress = 60%:

┌──────────────────────────────────────────────────────┐
│████████████████████████████████████░░░░░░░░░░░░░░░░│
└──────────────────────────────────────────────────────┘
 ←───────── 60% ──────────→←───── 40% ──────→
```

#### Feedback Icon Rendering

```verilog
// Feedback icon parameters
localparam FEEDBACK_ICON_SIZE = 16;    // 16×16 pixels
localparam FEEDBACK_ICON_X = (96 - FEEDBACK_ICON_SIZE) / 2;
localparam FEEDBACK_ICON_Y = 24;       // Below progress bar

// Checkmark bitmap (16×16)
reg [15:0] checkmark_bitmap [0:15];
initial begin
    checkmark_bitmap[0]  = 16'b0000000000000000;
    checkmark_bitmap[1]  = 16'b0000000000000000;
    checkmark_bitmap[2]  = 16'b0000000000000011;
    checkmark_bitmap[3]  = 16'b0000000000000110;
    checkmark_bitmap[4]  = 16'b0000000000001100;
    checkmark_bitmap[5]  = 16'b0000000000011000;
    checkmark_bitmap[6]  = 16'b0011000000110000;
    checkmark_bitmap[7]  = 16'b0011100001100000;
    checkmark_bitmap[8]  = 16'b0001110011000000;
    checkmark_bitmap[9]  = 16'b0000111110000000;
    checkmark_bitmap[10] = 16'b0000011100000000;
    checkmark_bitmap[11] = 16'b0000001000000000;
    checkmark_bitmap[12] = 16'b0000000000000000;
    // ...
end

// Red X bitmap (16×16)
reg [15:0] red_x_bitmap [0:15];
initial begin
    red_x_bitmap[0]  = 16'b1100000000000011;
    red_x_bitmap[1]  = 16'b0110000000000110;
    red_x_bitmap[2]  = 16'b0011000000001100;
    red_x_bitmap[3]  = 16'b0001100000011000;
    red_x_bitmap[4]  = 16'b0000110000110000;
    red_x_bitmap[5]  = 16'b0000011001100000;
    red_x_bitmap[6]  = 16'b0000001111000000;
    red_x_bitmap[7]  = 16'b0000000110000000;
    red_x_bitmap[8]  = 16'b0000001111000000;
    red_x_bitmap[9]  = 16'b0000011001100000;
    red_x_bitmap[10] = 16'b0000110000110000;
    red_x_bitmap[11] = 16'b0001100000011000;
    // ...
end

// Render feedback icon
if (feedback_correct && x >= FEEDBACK_ICON_X &&
    x < FEEDBACK_ICON_X + FEEDBACK_ICON_SIZE &&
    y >= FEEDBACK_ICON_Y && y < FEEDBACK_ICON_Y + FEEDBACK_ICON_SIZE) begin

    if (checkmark_bitmap[y - FEEDBACK_ICON_Y][FEEDBACK_ICON_SIZE - 1 - (x - FEEDBACK_ICON_X)]) begin
        pixel_data = GREEN;
    end else begin
        pixel_data = BLACK;
    end
end else if (feedback_incorrect && ...) begin
    if (red_x_bitmap[...]) begin
        pixel_data = RED;
    end else begin
        pixel_data = BLACK;
    end
end
```

---

## 9. Tutorial Mode Validation Systems

### 9.1 Bubble Sort Tutorial Validation

#### Optimal Solution Tracker

```verilog
// Shadow bubble sort algorithm running in parallel
reg [7:0] optimal_array [0:5];    // Reference array
reg [2:0] optimal_i, optimal_j;   // Reference indices
reg [2:0] optimal_pass;           // Reference pass number
reg optimal_should_swap;          // Expected action
reg optimal_sorted;               // Completion flag

// Bubble sort order tracking
reg [2:0] expected_pos;           // Expected next comparison (0-4)
reg [2:0] current_pass;           // Current pass (0-5)
reg [2:0] pass_limit;             // Upper limit per pass
```

**Initialization (SETUP_CONFIRM state):**
```verilog
// Copy user's array to optimal tracker
for (i = 0; i < 6; i = i + 1) begin
    optimal_array[i] <= array[i];
end

// Initialize bubble sort order tracking
expected_pos <= 0;     // Start at position 0
current_pass <= 0;     // Start at pass 0
pass_limit <= 4;       // First pass: compare positions 0-4 (pairs 0-1, 1-2, 2-3, 3-4, 4-5)
```

#### Position Validation

```verilog
// In TUTORIAL_SELECT state:
// Calculate optimal next move
optimal_should_swap <= (array[cursor_pos] > array[cursor_pos + 1]);

// User made a decision - check position
if (btn_u_edge || btn_d_edge) begin
    if (cursor_pos == expected_pos) begin
        // CORRECT POSITION!
        if (btn_u_edge) begin
            user_swapped <= 1;
            // Correct if elements are out of order
            user_action_correct <= (array[cursor_pos] > array[cursor_pos + 1]);
        end else begin
            user_swapped <= 0;
            // Correct if elements are in order
            user_action_correct <= (array[cursor_pos] <= array[cursor_pos + 1]);
        end
    end else begin
        // WRONG POSITION! Not following bubble sort order
        user_action_correct <= 0;
        user_swapped <= btn_u_edge;
    end
end
```

**Expected Position Update (TUTORIAL_CHECK_DONE state):**
```verilog
if (!array_is_sorted) begin
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
```

**Pass Progression Example:**
```
Pass 0: expected_pos: 0→1→2→3→4, pass_limit=4
        Compares: (0,1), (1,2), (2,3), (3,4), (4,5)

Pass 1: expected_pos: 0→1→2→3, pass_limit=3
        Compares: (0,1), (1,2), (2,3), (3,4)
        (Element 5 already sorted)

Pass 2: expected_pos: 0→1→2, pass_limit=2
        Compares: (0,1), (1,2), (2,3)
        (Elements 4-5 already sorted)

Pass 3: expected_pos: 0→1, pass_limit=1
        Compares: (0,1), (1,2)
        (Elements 3-5 already sorted)

Pass 4: expected_pos: 0, pass_limit=0
        Compares: (0,1)
        (Elements 2-5 already sorted)
```

#### Hearts System (Future Enhancement)

```verilog
// Hearts system registers (prepared but not fully implemented)
reg [2:0] hearts_remaining;  // 0-3 hearts

// Initialize in SETUP_CONFIRM
hearts_remaining <= 3;

// Decrement on wrong action
if (!user_action_correct && hearts_remaining > 0) begin
    hearts_remaining <= hearts_remaining - 1;
end

// Game over condition
if (hearts_remaining == 0) begin
    next_state = TUTORIAL_GAME_OVER;
end
```

### 9.2 Merge Sort Tutorial Validation

#### Element Correctness Checking

```verilog
// Validation registers
reg [2:0] user_answer_array [0:5];     // User's answer (top row boxes)
reg [2:0] expected_merge_result [0:5]; // Correct answer
reg [5:0] element_correct;             // Per-element flags
reg [4:0] separator_correct;           // Per-separator flags
reg all_correct;                       // Combined flag

// Generate expected merge result (example: step 1)
// Merging [4, 2] and [1, 5] (both pre-sorted)
expected_merge_result[0] = 3'd1;  // Smallest
expected_merge_result[1] = 3'd2;
expected_merge_result[2] = 3'd4;
expected_merge_result[3] = 3'd5;  // Largest
expected_merge_result[4] = 3'd0;  // Unused
expected_merge_result[5] = 3'd0;  // Unused

// Check each element
for (i = 0; i < 6; i = i + 1) begin
    element_correct[i] <= (user_answer_array[i] == expected_merge_result[i]);
end
```

#### Separator Line Validation

```verilog
// Expected separator positions (example: step 1)
// Two groups: [1,2,4,5] and [6,3]
expected_separators = 5'b00010;  // Separator after position 3
//                        │││││
//                        ││││└─ Between box 0 and 1: OFF
//                        │││└── Between box 1 and 2: OFF
//                        ││└─── Between box 2 and 3: OFF
//                        │└──── Between box 3 and 4: ON (split here)
//                        └───── Between box 4 and 5: OFF

// User input from switches
user_separator_lines = sw[4:0];  // SW0-SW4

// Validate each separator
for (i = 0; i < 5; i = i + 1) begin
    separator_correct[i] <= (user_separator_lines[i] == expected_separators[i]);
end

// Combined correctness
all_correct <= (&element_correct) && (&separator_correct);
```

**Bitwise AND Reduction:**
```verilog
// &element_correct expands to:
// element_correct[0] & element_correct[1] & element_correct[2] &
// element_correct[3] & element_correct[4] & element_correct[5]

// Result: 1 if all bits are 1, otherwise 0
```

#### Visual Feedback (Color Flash)

```verilog
// Flash timer for feedback animation
reg [7:0] flash_timer;  // 0-255 frames

// Color assignment logic
always @(*) begin
    for (i = 0; i < 6; i = i + 1) begin
        if (all_correct && flash_timer < 30) begin
            // Green flash for correct answer (first 30 frames)
            answer_colors[i] = COLOR_SORTED;
        end else if (!element_correct[i] && check_answer_req_sync[1]) begin
            // Red for incorrect element
            answer_colors[i] = COLOR_ACTIVE;
        end else begin
            // White (normal)
            answer_colors[i] = COLOR_NORMAL;
        end
    end

    // Separator colors
    for (i = 0; i < 5; i = i + 1) begin
        if (all_correct && flash_timer < 30) begin
            separator_colors[i] = COLOR_SORTED;
        end else if (!separator_correct[i] && check_answer_req_sync[1]) begin
            separator_colors[i] = COLOR_ACTIVE;
        end else begin
            separator_colors[i] = COLOR_NORMAL;
        end
    end
end

// Flash timer logic (at clk_movement ~45 Hz)
if (all_correct) begin
    if (flash_timer < 60) begin  // Flash for 60 frames (~1.3 seconds)
        flash_timer <= flash_timer + 1;
    end else begin
        // Flash complete, advance to next step
        tutorial_merge_step_target <= tutorial_merge_step_target + 1;
        flash_timer <= 0;
    end
end
```

#### Progressive Hints System

```verilog
// Wrong attempt counter
reg [2:0] wrong_attempt_count;  // 0-7 wrong attempts

// Hint timer (1 second at 45 Hz = 45 frames)
reg [5:0] hint_timer;           // Countdown timer
reg [4:0] hint_separators;      // Which separators to highlight

// On wrong answer
if (!all_correct && check_answer_req_sync[1]) begin
    wrong_attempt_count <= wrong_attempt_count + 1;

    // Progressive hints
    if (wrong_attempt_count == 0) begin
        // First attempt: No hints
        hint_separators <= 5'b00000;
    end else if (wrong_attempt_count == 1) begin
        // Second attempt: Show separator hints
        hint_separators <= expected_separators;
        hint_timer <= 45;  // Show for 1 second
    end else if (wrong_attempt_count >= 2) begin
        // Third attempt: Flash incorrect elements
        hint_separators <= expected_separators;
        hint_timer <= 45;
        // Also highlight wrong elements (implemented in display module)
    end
end

// Hint timer decrement
if (hint_timer > 0) begin
    hint_timer <= hint_timer - 1;
end
```

---

## 10. Merge Sort Implementation

### 10.1 Bottom-Up Merge Sort Algorithm

**Algorithm Overview:**
```
Initial array: [4, 2, 6, 1, 5, 3]

Step 1: Merge pairs (size 1)
  Merge [4] and [2] → [2, 4]
  Merge [6] and [1] → [1, 6]
  Merge [5] and [3] → [3, 5]
  Result: [2, 4, 1, 6, 3, 5]

Step 2: Merge pairs (size 2)
  Merge [2, 4] and [1, 6] → [1, 2, 4, 6]
  Merge [3, 5] and [] → [3, 5]
  Result: [1, 2, 4, 6, 3, 5]

Step 3: Merge pairs (size 4)
  Merge [1, 2, 4, 6] and [3, 5] → [1, 2, 3, 4, 5, 6]
  Result: [1, 2, 3, 4, 5, 6] (SORTED)
```

### 10.2 Merge Logic Implementation

```verilog
// Working arrays for merge sort
reg [2:0] work_array [0:5];   // Current array state
reg [2:0] temp_array [0:5];   // Temporary for merging
reg [2:0] sorted_array [0:5]; // Final sorted result

// Merge operation (Step 1: merge size 1)
always @(posedge clk_movement) begin
    if (merge_step == 0) begin
        // Merge [4] and [2]
        if (work_array[0] <= work_array[1]) begin
            temp_array[0] = work_array[0];
            temp_array[1] = work_array[1];
        end else begin
            temp_array[0] = work_array[1];
            temp_array[1] = work_array[0];
        end

        // Merge [6] and [1]
        if (work_array[2] <= work_array[3]) begin
            temp_array[2] = work_array[2];
            temp_array[3] = work_array[3];
        end else begin
            temp_array[2] = work_array[3];
            temp_array[3] = work_array[2];
        end

        // Merge [5] and [3]
        if (work_array[4] <= work_array[5]) begin
            temp_array[4] = work_array[4];
            temp_array[5] = work_array[5];
        end else begin
            temp_array[4] = work_array[5];
            temp_array[5] = work_array[4];
        end

        // Copy back to work_array
        for (i = 0; i < 6; i = i + 1) begin
            work_array[i] <= temp_array[i];
        end
    end
end
```

### 10.3 Swap Tracking (Prevents Duplicate Swaps)

```verilog
// Swap tracking flags
reg swap_done_step1_pair1;  // Track if first pair swapped in step 1
reg swap_done_step1_pair2;  // Track if second pair swapped in step 1
reg swap_done_step2;        // Track if swap done in step 2
reg [2:0] swap_count_step3; // Track number of swaps done in step 3

// Reset on state entry
if (state == STATE_MERGE && state_prev != STATE_MERGE) begin
    swap_done_step1_pair1 <= 0;
    swap_done_step1_pair2 <= 0;
    swap_done_step2 <= 0;
    swap_count_step3 <= 0;
end

// Perform swap only once
if (merge_step == 0 && !swap_done_step1_pair1 && work_array[0] > work_array[1]) begin
    // Swap elements 0 and 1
    work_array[0] <= work_array[1];
    work_array[1] <= work_array[0];
    swap_done_step1_pair1 <= 1;
end
```

**Design Rationale:**
- Prevents multiple swaps per comparison
- Flags reset when entering merge step
- Each flag tracks specific swap operation

### 10.4 Animation Synchronization

```verilog
// Wait for animation completion before proceeding
if (all_positions_reached && step_timer >= 8'd30) begin
    // All elements reached target positions
    // Waited 0.5 seconds (30 frames at 60 Hz)
    // Proceed to next step
    merge_step <= merge_step + 1;
    step_timer <= 0;
end else begin
    step_timer <= step_timer + 1;
end
```

**Timing Breakdown:**
1. Set target positions (1 cycle)
2. Wait for interpolation: up to 80 pixels ÷ 45 px/s = 1.78 seconds
3. Hold at target: 0.5 seconds (visual confirmation)
4. Total per step: ~2.3 seconds

---

## 11. Input Handling Systems

### 11.1 Switch Input Mapping

```verilog
// Algorithm selection switches (one-hot)
wire merge_sort_active = sw[15] && !sw[14] && !sw[13] && !sw[12];
wire insertion_sort_active = sw[14] && !sw[15] && !sw[13] && !sw[12];
wire selection_sort_active = sw[13] && !sw[15] && !sw[14] && !sw[12];
wire bubble_sort_active = sw[12] && !sw[15] && !sw[14] && !sw[13];

// Mode switches
wire tutorial_mode = sw[10];  // Tutorial mode when ON with algorithm switch

// Merge sort tutorial: Separator line placement
wire [4:0] line_switches = sw[4:0];  // SW0-SW4 control separators
```

### 11.2 Button Synchronization (3-Stage Shift Register)

```verilog
// Button synchronization registers
reg [2:0] btnU_sync = 3'b000;
reg [2:0] btnD_sync = 3'b000;
reg [2:0] btnC_sync = 3'b000;
reg [2:0] btnL_sync = 3'b000;
reg [2:0] btnR_sync = 3'b000;

// Synchronization logic (at 100 MHz)
always @(posedge clk) begin
    btnU_sync <= {btnU_sync[1:0], btnU};
    btnD_sync <= {btnD_sync[1:0], btnD};
    btnC_sync <= {btnC_sync[1:0], btnC};
    btnL_sync <= {btnL_sync[1:0], btnL};
    btnR_sync <= {btnR_sync[1:0], btnR};
end

// Edge detection (rising edge only)
wire btn_start = btnU_sync[2] && !btnU_sync[1];
wire btn_pause = btnD_sync[2] && !btnD_sync[1];
wire btn_center = btnC_sync[2] && !btnC_sync[1];
wire btn_left = btnL_sync[2] && !btnL_sync[1];
wire btn_right = btnR_sync[2] && !btnR_sync[1];
```

**Design Rationale:**
1. **3-stage synchronizer:**
   - Stage 0: Raw input (asynchronous)
   - Stage 1: First synchronization (may be metastable)
   - Stage 2: Second synchronization (stable)
   - Stage 3: Used for edge detection

2. **Metastability Prevention:**
   - 2-stage synchronizer (btnU → btnU_sync[0] → btnU_sync[1]) prevents metastability
   - Third stage (btnU_sync[2]) used for edge detection
   - MTBF (Mean Time Between Failures) increased exponentially

3. **Rising Edge Detection:**
   - Edge = current state HIGH && previous state LOW
   - Single-cycle pulse output
   - Suitable for FSM inputs

### 11.3 Button Function Mapping

**Context-Dependent Button Functions:**

| Button | Bubble Tutorial | Merge Tutorial (Edit) | Merge Tutorial (Practice) |
|--------|----------------|----------------------|---------------------------|
| btnU   | Increment value | Increment value     | (Unused) |
| btnD   | Decrement value | Decrement value     | (Unused) |
| btnL   | Navigate left   | Navigate left       | Navigate cursor left |
| btnR   | Navigate right  | Navigate right      | Navigate cursor right |
| btnC   | Confirm array   | Start sorting       | Check answer |

**Context-Dependent Implementation:**
```verilog
// In tutorial_fsm.v (Bubble Sort)
if (state == SETUP_EDIT) begin
    if (btn_u_edge) begin
        array[cursor_pos] <= (array[cursor_pos] == 7) ? 0 : array[cursor_pos] + 1;
    end
end else if (state == TUTORIAL_SELECT) begin
    if (btn_u_edge) begin
        // Swap decision
        next_state = TUTORIAL_SWAP_ANIM;
    end
end

// In merge_sort_controller.v
if (state == STATE_TUTORIAL_EDIT) begin
    if (btn_start_edge) begin  // btnU mapped to btn_start
        // Increment value
        user_answer_array[cursor_pos] <= (user_answer_array[cursor_pos] == 7) ? 0 :
                                        user_answer_array[cursor_pos] + 1;
    end
end else if (state == STATE_TUTORIAL_DIVIDE && tutorial_practice_mode) begin
    if (btn_center_edge) begin
        // Check answer
        check_answer_req <= 1'b1;
    end
end
```

---

## 12. Hardware Resource Utilization

### 12.1 Estimated FPGA Resources (Artix-7 XC7A35T)

**Available Resources:**
- LUTs: 20,800
- Flip-Flops: 41,600
- Block RAM (BRAM): 50 blocks (36 Kb each = 1,800 Kb total)
- DSP Slices: 90

**Estimated Usage (Full Project):**
- **LUTs:** ~8,000-12,000 (40-60% utilization)
  - FSM logic: ~2,000
  - Pixel generators (combinational): ~4,000
  - Clock management: ~500
  - Debouncing: ~1,000
  - OLED controller: ~2,000
  - Miscellaneous: ~2,000

- **Flip-Flops:** ~3,000-5,000 (7-12% utilization)
  - Array registers: ~500
  - Animation counters: ~1,000
  - Synchronizers: ~200
  - FSM state registers: ~100
  - Miscellaneous: ~1,500

- **BRAM:** 1-2 blocks (~2-4% utilization)
  - Insertion Sort frame buffer: 1 block (6144 × 16-bit)
  - Font ROMs: Synthesized to distributed RAM (not BRAM)

- **DSP Slices:** 0 (multiplication operations synthesized to LUTs)

### 12.2 Critical Path Analysis

**Expected Critical Paths:**

1. **Pixel Generator Combinational Logic (Longest):**
   ```
   pixel_index → (x, y) decode → box position check →
   color selection → font lookup → pixel_data output
   ```
   - Estimated delay: ~15-20 ns
   - Maximum frequency: ~50-66 MHz
   - Meets 6.25 MHz OLED clock requirement ✓

2. **Animation Position Update:**
   ```
   array_positions_x[i] → comparator →
   adder/subtractor → array_positions_x[i] register
   ```
   - Estimated delay: ~5-8 ns
   - Maximum frequency: ~125-200 MHz
   - Meets 45 Hz clk_movement requirement ✓

3. **FSM State Transition:**
   ```
   state register → next state logic → state register
   ```
   - Estimated delay: ~3-5 ns
   - Maximum frequency: ~200-333 MHz
   - Meets 100 MHz system clock ✓

### 12.3 Memory Bandwidth

**OLED Display Bandwidth:**
- Pixel rate: 368,640 pixels/second
- Data rate: 368,640 × 16 bits = 5,898,240 bits/second ≈ 5.9 Mbps
- BRAM read bandwidth: 6.25 MHz × 16 bits = 100 Mbps
- Bandwidth utilization: 5.9 / 100 = 5.9% ✓

**Frame Buffer Write Bandwidth:**
- Update rate: 6144 pixels per frame × 60 fps = 368,640 pixels/second
- Write bandwidth: 100 MHz × 16 bits = 1,600 Mbps
- Bandwidth utilization: 5.9 / 1,600 = 0.37% ✓

---

## 13. Design Patterns and Best Practices

### 13.1 FSM Design Pattern (Mealy vs. Moore)

**Moore Machine (Used in Bubble Sort FSM):**
```verilog
// Outputs depend only on current state
always @(*) begin
    case (state)
        IDLE: begin
            sorting = 0;
            done = 0;
        end
        COMPARE: begin
            sorting = 1;
            done = 0;
        end
        // ...
    endcase
end
```

**Mealy Machine (Used in Tutorial FSM):**
```verilog
// Outputs depend on state AND inputs
always @(*) begin
    next_state = state;
    case (state)
        TUTORIAL_SELECT: begin
            if (btn_u_edge) begin
                next_state = TUTORIAL_SWAP_ANIM;
            end else if (btn_d_edge) begin
                next_state = TUTORIAL_FEEDBACK;
            end
        end
    endcase
end
```

**Trade-offs:**
- Moore: Outputs stable (glitch-free), but requires more states
- Mealy: Fewer states, faster response, but potential output glitches
- Both patterns used appropriately in this project

### 13.2 Clock Domain Crossing (CDC) Best Practices

**2-Stage Synchronizer (Standard Pattern):**
```verilog
reg [1:0] signal_sync;
always @(posedge clk_dest) begin
    signal_sync <= {signal_sync[0], signal_src};
end
wire signal_dest = signal_sync[1];
```

**Handshake Protocol (for Multi-Bit Data):**
```verilog
// Source domain (clk)
reg req;
reg [1:0] ack_sync;
always @(posedge clk) begin
    ack_sync <= {ack_sync[0], ack};
    if (data_valid && !req && !ack_sync[1]) begin
        req <= 1;
    end else if (req && ack_sync[1]) begin
        req <= 0;
    end
end

// Destination domain (clk_dest)
reg ack;
reg [1:0] req_sync;
always @(posedge clk_dest) begin
    req_sync <= {req_sync[0], req};
    if (req_sync[1] && !ack) begin
        // Process data
        ack <= 1;
    end else if (!req_sync[1] && ack) begin
        ack <= 0;
    end
end
```

### 13.3 Parameterization and Reusability

**Localparams for Configuration:**
```verilog
localparam WIDTH = 96;
localparam HEIGHT = 64;
localparam BOX_WIDTH = 14;
localparam BOX_SPACING = 2;
localparam ANIM_FRAMES = 60;
```

**Design Rationale:**
- Centralized configuration
- Easy to modify and experiment
- Self-documenting code
- Synthesis-time constant (optimized by tools)

---

## Conclusion

This comprehensive documentation covers every aspect of your EE2026 sorting visualizer project, from high-level architecture to bit-level implementation details. You now have:

1. **Complete FSM specifications** with state transition diagrams
2. **Detailed clock management** with calculations and timing diagrams
3. **In-depth debouncing architecture** with algorithm analysis
4. **Register and memory organization** with bit layouts
5. **Animation system documentation** with frame-by-frame breakdowns
6. **OLED rendering pipeline** with SPI protocol details
7. **Tutorial validation logic** with correctness checking algorithms
8. **Merge sort implementation** with swap tracking
9. **Input handling** with synchronization and edge detection
10. **Resource utilization** estimates and critical path analysis

**For your presentation:**
- Focus on the technical depth of your contributions (Bubble Sort, Merge Sort, debouncing)
- Emphasize design decisions and trade-offs
- Be prepared to explain FSM transitions and validation algorithms
- Understand clock domain crossing and synchronization challenges
- Know your resource utilization and timing constraints

Good luck with your presentation! You've built a sophisticated hardware system with real-time animation, user interaction, and educational value.
