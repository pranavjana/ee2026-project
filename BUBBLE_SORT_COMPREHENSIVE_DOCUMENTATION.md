# BUBBLE SORT VISUALIZER - COMPREHENSIVE DOCUMENTATION
## EE2026 Digital Design Project

---

## GROUP INFORMATION
**Group ID:** [Your Group ID]
**Members:**
- [Member 1 Name] - [Matriculation Number]
- [Member 2 Name] - [Matriculation Number]
- [Member 3 Name] - [Matriculation Number]

---

# SHEET 1: USER GUIDE & QUICK START

## 1. SYSTEM OVERVIEW

The Bubble Sort Visualizer is an interactive FPGA-based educational tool implemented on the Basys 3 board with a 96×64 OLED display. The system features **two distinct operating modes**:

1. **DEMO MODE** - Automated bubble sort visualization with step-by-step animation
2. **TUTORIAL MODE** - Interactive learning environment where users manually perform bubble sort with real-time feedback

### Key Hardware Components
- **FPGA Board:** Basys 3 (Artix-7 XC7A35T)
- **Display:** 96×64 OLED PMOD (connected to JC connector)
- **Clock:** 100 MHz system clock
- **Inputs:** 5 buttons (btnU, btnD, btnL, btnR, btnC) and 16 switches
- **Outputs:** OLED display, 16 LEDs, 4-digit 7-segment display

---

## 2. QUICK START GUIDE

### 2.1 DEMO MODE - Automated Bubble Sort Visualization

**Purpose:** Observe automatic bubble sort algorithm execution with visual animations

#### Hardware Setup:
```
Switch Configuration:
  SW[12] = ON     → Activate Bubble Sort
  SW[0]  = OFF    → Demo Mode (not Tutorial)
  SW[1:0]         → Pattern selection:
                    00 = Random (5,2,4,1,3,0)
                    01 = Already Sorted (0,1,2,3,4,5)
                    10 = Reverse Sorted (5,4,3,2,1,0)
                    11 = Custom Pattern (3,5,1,4,2,0)
```

#### Button Controls:
| Button | Function | Description |
|--------|----------|-------------|
| **btnU** | START/RUN | Begin sorting animation |
| **btnC** | RESET | Reset to initial state, reload pattern |
| **btnD** | PAUSE/RESUME | Pause or resume animation |

#### Visual Indicators:

**OLED Display (96×64 pixels):**
- **6 boxes** arranged horizontally, each containing a single-digit number
- **Yellow boxes** indicate elements currently being compared
- **Red boxes** show elements being swapped (with 4-phase animation)
- **Green boxes** indicate sorting is complete
- **Blue dot pattern** on background for visual reference
- **"BUBBLE SORT!" text** appears when complete

**7-Segment Display:**
- Shows **"bUbL"** when Demo Mode is active
- Shows **"Sort"** during active sorting
- Shows **"donE"** when sorting completes

**LEDs:**
- **LED[12]** lights up when Bubble Sort is selected (SW[12]=ON)

#### Operation Flow:

```
┌─────────────┐
│   IDLE      │ ← Initial state
└──────┬──────┘
       │ Press btnU (START)
       ▼
┌─────────────┐
│  SORTING    │ ← Automatic progression (1 Hz steps)
│  (ACTIVE)   │
└──────┬──────┘
       │ Press btnD (PAUSE)
       ▼
┌─────────────┐
│   PAUSED    │ ← Animation frozen
└──────┬──────┘
       │ Press btnD (RESUME)
       │ OR continue sorting
       ▼
┌─────────────┐
│    DONE     │ ← Array fully sorted
└─────────────┘
```

---

### 2.2 TUTORIAL MODE - Interactive Learning Mode

**Purpose:** Learn bubble sort by manually selecting pairs and deciding swaps

#### Hardware Setup:
```
Switch Configuration:
  SW[12] = ON     → Activate Bubble Sort
  SW[0]  = ON     → Tutorial Mode
```

#### Tutorial Phases:

**PHASE 1: SETUP - Create Your Array (States 0-2)**

| Button | Function | Description |
|--------|----------|-------------|
| **btnL** | Move Left | Move cursor to previous box (wraps around) |
| **btnR** | Move Right | Move cursor to next box (wraps around) |
| **btnU** | Increment | Increase value (0→1→...→7→0) |
| **btnD** | Decrement | Decrease value (7→6→...→0→7) |
| **btnC** | CONFIRM | Start the tutorial sorting phase |

**Display Features:**
- **Cyan-highlighted box** shows current cursor position (thick border)
- **White boxes** with black numbers (values 0-7)
- All 6 boxes start at value 0

**PHASE 2: SORTING - Interactive Bubble Sort (States 3-9)**

| Button | Function | Description |
|--------|----------|-------------|
| **btnL** | Select Left Pair | Choose current position and left neighbor |
| **btnR** | Select Right Pair | Choose current position and right neighbor |
| **btnU** | SWAP | Perform swap on selected pair |
| **btnD** | KEEP/SKIP | Don't swap, keep current order |

**Visual Feedback:**
- **Yellow boxes** highlight the pair you selected
- **Progress bar** (top of screen, rows 1-5) shows completion percentage
- **Checkmark (✓)** in green = Correct decision
- **X mark** in red = Incorrect decision
- **"COMPARE: X Y"** text shows values being compared
- **"SWAPPING!"** text during swap animation
- **Rainbow celebration** when array is fully sorted

**Tutorial Rules:**
1. **Follow bubble sort order** - Must compare pairs sequentially
2. **Correct direction** - After swap, must compare left; after skip, must compare right
3. **Swap when needed** - Swap if left element > right element
4. **Visual validation** - Immediate feedback on every action

#### Complete Tutorial Flow Diagram:

```
┌──────────────────┐
│  SETUP_INIT (0)  │ ← All boxes = 0
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  SETUP_EDIT (1)  │ ← Use btnL/R/U/D to create array
└────────┬─────────┘
         │ Press btnC
         ▼
┌──────────────────┐
│ SETUP_CONFIRM(2) │ ← Prepare for sorting
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────────┐
│       TUTORIAL_SELECT (3)                 │
│  ┌────────────────────────────────────┐  │
│  │ Use btnL/R to select pair          │  │
│  │ Press btnU to SWAP                 │  │
│  │ Press btnD to KEEP                 │  │
│  └────────────────────────────────────┘  │
└───────┬────────────────┬─────────────────┘
        │ btnU pressed   │ btnD pressed
        ▼                ▼
  ┌──────────┐     ┌──────────┐
  │ SWAP (6) │     │FEEDBACK  │
  │ Animate  │     │   (7)    │
  └────┬─────┘     └────┬─────┘
       │                │
       └────────┬───────┘
                ▼
         ┌──────────────┐
         │ FEEDBACK (7) │ ← Show ✓ or X
         └──────┬───────┘
                ▼
         ┌──────────────┐
         │CHECK_DONE(8) │ ← Is array sorted?
         └──────┬───────┘
          YES │ │ NO
              │ └──────→ Back to SELECT (3)
              ▼
         ┌──────────────┐
         │ COMPLETE (9) │ ← Rainbow celebration!
         └──────────────┘
```

---

## 3. OPERATING INSTRUCTIONS BY USE CASE

### Use Case 1: "I want to watch bubble sort in action"
1. Set **SW[12] = ON**, all other switches OFF
2. Press **btnU** to start
3. Watch the yellow comparison and red swap animations
4. Press **btnD** to pause, **btnD** again to resume
5. Press **btnC** to reset and try different patterns (SW[1:0])

### Use Case 2: "I want to learn bubble sort step-by-step"
1. Set **SW[12] = ON** and **SW[0] = ON**
2. Use buttons to create your array (btnL/R to move, btnU/D to change values)
3. Press **btnC** to start tutorial
4. For each comparison:
   - Use **btnL** or **btnR** to select which adjacent pair
   - Press **btnU** to swap OR **btnD** to keep
5. Follow the feedback (green ✓ or red X)
6. Continue until array is sorted (rainbow celebration!)
7. Press **btnC** to restart with new array

### Use Case 3: "I want to see different starting patterns"
**Demo Mode with Various Patterns:**
1. SW[12]=ON, SW[1:0]=00 → Random pattern (needs sorting)
2. SW[12]=ON, SW[1:0]=01 → Already sorted (no swaps)
3. SW[12]=ON, SW[1:0]=10 → Reverse sorted (worst case)
4. SW[12]=ON, SW[1:0]=11 → Custom pattern
5. Press btnU to start each time

---

## 4. TROUBLESHOOTING GUIDE

| Issue | Likely Cause | Solution |
|-------|--------------|----------|
| OLED display is blank | SW[12] not ON | Turn ON switch 12 |
| Display shows nothing | Multiple algorithm switches ON | Turn OFF SW[13], SW[14], SW[15] |
| Tutorial not responding | Wrong mode | Ensure SW[0] = ON for tutorial |
| Buttons don't work | Debouncing delay | Wait ~100ms between presses |
| Animation stuck | Paused | Press btnD to resume |
| 7-seg shows blank | No algorithm selected | Turn ON SW[12] |

---

# SHEET 2: TECHNICAL IMPLEMENTATION DETAILS

## 5. SYSTEM ARCHITECTURE

### 5.1 Top-Level Module: `bubble_sort_top.v`

**Module Hierarchy:**
```
bubble_sort_top (Top Level)
├── button_debounce_5btn (Button Interface)
├── clock_divider (Clock Generation)
│   ├── clk_6.25MHz → OLED display timing
│   └── clk_1Hz_pulse → FSM step timing
├── bubble_sort_fsm (Demo Mode Logic)
├── tutorial_fsm (Tutorial Mode Logic)
├── pixel_generator (Demo Mode Display)
├── tutorial_pixel_generator (Tutorial Mode Display)
└── Oled_Display (Hardware Driver)
```

**Key Technical Specifications:**
- **System Clock:** 100 MHz
- **OLED Clock:** 6.25 MHz (divided from 100 MHz)
- **Animation Frame Rate:** ~60 Hz (1,666,667 clock cycles per frame)
- **FSM Step Rate (Demo):** 1 Hz (paused when btnD pressed)
- **Display Resolution:** 96 pixels (width) × 64 pixels (height) = 6,144 pixels
- **Color Format:** RGB565 (16-bit: 5R-6G-5B)
- **Array Size:** 6 elements (8-bit values, displayed as 0-9 single digits)

### 5.2 Mode Multiplexing (Lines 178-191)

The top module intelligently switches between demo and tutorial modes:

```verilog
// Mode detection
wire tutorial_mode = sw[12] && sw[0];

// Signal multiplexing
wire [7:0] array0 = tutorial_mode ? tutorial_array0 : auto_array0;
wire [7:0] array1 = tutorial_mode ? tutorial_array1 : auto_array1;
// ... (array2-5 similarly muxed)

wire [2:0] compare_idx1 = tutorial_mode ? tutorial_cursor_pos : auto_compare_idx1;
wire [2:0] compare_idx2 = tutorial_mode ? tutorial_compare_pos : auto_compare_idx2;
wire sorting = tutorial_mode ? (!tutorial_is_sorted) : auto_sorting;
wire done = tutorial_mode ? tutorial_is_sorted : auto_done;

// Pixel data multiplexing
assign pixel_data = tutorial_mode ? tutorial_pixel_data : auto_pixel_data;
```

**Technical Highlight:** Clean separation of concerns with zero-overhead multiplexing at synthesis time.

---

## 6. DEMO MODE - TECHNICAL DEEP DIVE

### 6.1 Finite State Machine: `bubble_sort_fsm.v`

**FSM States (7 states, 3-bit encoding):**

| State | Encoding | Description | Duration |
|-------|----------|-------------|----------|
| **IDLE** | 3'b000 | Waiting for start signal | Until btnU pressed |
| **COMPARE** | 3'b001 | Compare array[i] and array[i+1] | 1 step_pulse (1 second) |
| **SWAP_START** | 3'b010 | Initiate swap, prepare animation | 1 clock cycle |
| **SWAP_ANIM** | 3'b110 | Animate 4-phase swap | 240 frames (~4 seconds) |
| **INCREMENT** | 3'b011 | Move to next comparison (i++) | 1 clock cycle |
| **NEXT_PASS** | 3'b100 | Start new pass or check completion | 1 clock cycle |
| **DONE** | 3'b101 | Sorting complete | Until btnU pressed |

**State Transition Logic (Lines 92-146):**

```verilog
always @(*) begin
    case (state)
        IDLE: if (start) next_state = COMPARE;

        COMPARE: if (step_pulse) begin
            // Ascending sort: swap if array[i] > array[i+1]
            if (array[i] > array[i+1])
                next_state = SWAP_START;
            else
                next_state = INCREMENT;
        end

        SWAP_START: next_state = SWAP_ANIM;

        SWAP_ANIM: begin
            // Stay until all 4 phases complete (60 frames each)
            if (phase_counter >= 3 && anim_counter >= 59)
                next_state = INCREMENT;
        end

        INCREMENT:
            if (i >= (5 - pass_count - 1))
                next_state = NEXT_PASS;
            else
                next_state = COMPARE;

        NEXT_PASS:
            if (!swapped_this_pass || pass_count >= 5)
                next_state = DONE;
            else
                next_state = COMPARE;

        DONE: if (start) next_state = COMPARE;
    endcase
end
```

### 6.2 Animation System

**4-Phase Swap Animation (Lines 176-203):**

Each swap consists of 4 distinct phases, 60 frames each (total: 240 frames ≈ 4 seconds at 60 Hz):

1. **Phase 0 (UP):** `compare_idx1` element moves UP by 16 pixels
   - Frames 0-59: Y-offset increases from 0 to -16
   - Horizontal position unchanged

2. **Phase 1 (LEFT SLIDE):** `compare_idx2` element slides LEFT by 16 pixels (BOX_TOTAL)
   - Frames 0-59: X-offset decreases from 0 to -16
   - `compare_idx1` stays elevated at -16 Y-offset

3. **Phase 2 (RIGHT SLIDE):** `compare_idx1` element slides RIGHT by 16 pixels
   - Frames 0-59: X-offset increases from 0 to +16
   - Both elements now at swapped X positions
   - `compare_idx1` still elevated

4. **Phase 3 (DOWN):** `compare_idx1` element moves DOWN to final position
   - Frames 0-59: Y-offset decreases from -16 to 0
   - At frame 59, actual array swap occurs: `array[i] ↔ array[i+1]`

**Scaling Algorithm (pixel_generator.v, lines 166-167):**
```verilog
wire [9:0] scaled_calc = (anim_progress * 17) >> 5;
// Maps 0-29 frames → 0-16 pixels
wire [5:0] scaled_progress = (anim_progress >= 28) ? BOX_TOTAL : scaled_calc[5:0];
```

**Technical Highlight:** Smooth interpolation using fixed-point arithmetic for hardware-friendly animation.

### 6.3 Pre-Loaded Patterns (Lines 59-70)

Four distinct 48-bit patterns for educational variety:

```verilog
localparam [47:0] PATTERN_RANDOM  = {8'd5, 8'd2, 8'd4, 8'd1, 8'd3, 8'd0};  // Most swaps
localparam [47:0] PATTERN_SORTED  = {8'd0, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5};  // No swaps
localparam [47:0] PATTERN_REVERSE = {8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0};  // Worst case
localparam [47:0] PATTERN_CUSTOM  = {8'd3, 8'd5, 8'd1, 8'd4, 8'd2, 8'd0};  // Mixed
```

**Pattern Selection Logic (Lines 170-175):**
```verilog
case (pattern_sel)
    2'b00: {array[5], ..., array[0]} <= PATTERN_RANDOM;
    2'b01: {array[5], ..., array[0]} <= PATTERN_SORTED;
    2'b10: {array[5], ..., array[0]} <= PATTERN_REVERSE;
    2'b11: {array[5], ..., array[0]} <= PATTERN_CUSTOM;
endcase
```

---

## 7. TUTORIAL MODE - TECHNICAL DEEP DIVE

### 7.1 Tutorial FSM: `tutorial_fsm.v`

**10-State Interactive Learning Flow:**

| State | Code | Purpose | User Action | Validation |
|-------|------|---------|-------------|------------|
| **SETUP_INIT** | 4'd0 | Initialize all boxes to 0 | None | Automatic |
| **SETUP_EDIT** | 4'd1 | User creates custom array | btnL/R/U/D/C | Value range 0-7 |
| **SETUP_CONFIRM** | 4'd2 | Prepare for tutorial | Auto | Calculate metrics |
| **TUTORIAL_SELECT** | 4'd3 | Select adjacent pair | btnL/R, then btnU/D | Position + decision |
| **TUTORIAL_COMPARE** | 4'd4 | Display comparison | Auto | Visual only |
| **TUTORIAL_AWAIT_SWAP** | 4'd5 | Wait for decision | btnU (swap) or btnD (keep) | Optimal check |
| **TUTORIAL_SWAP_ANIM** | 4'd6 | Animate swap (if chosen) | None | 16 frames |
| **TUTORIAL_FEEDBACK** | 4'd7 | Show ✓ or X | None | ~1 second |
| **TUTORIAL_CHECK_DONE** | 4'd8 | Check if sorted | Auto | Array order check |
| **TUTORIAL_COMPLETE** | 4'd9 | Celebration | btnC to restart | Rainbow animation |

### 7.2 Validation Logic (Lines 371-397)

**Position Validation:**
```verilog
// Expected position tracking (bubble sort order enforcement)
reg [2:0] expected_pos;      // Should be 0-4 sequentially
reg [2:0] current_pass;      // Which bubble sort pass (0-5)
reg [2:0] pass_limit;        // Upper limit for current pass

// User action validation
if (cursor_pos == expected_pos) begin
    // Correct position! Check swap/skip decision
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
    // Wrong position! Not following bubble sort order
    user_action_correct <= 0;
end
```

**Technical Highlight:** Dual validation - checks both correct position AND correct decision.

### 7.3 Progress Tracking (Lines 485-492)

**Progress Bar Calculation:**
```verilog
progress_percent <=
    ((array[0] <= array[1] ? 20 : 0) +
     (array[1] <= array[2] ? 20 : 0) +
     (array[2] <= array[3] ? 20 : 0) +
     (array[3] <= array[4] ? 20 : 0) +
     (array[4] <= array[5] ? 20 : 0));
```
Each ordered pair contributes 20% to completion.

### 7.4 Array Sorted Check (Lines 141-145)

**Combinational Logic for Instant Detection:**
```verilog
wire array_is_sorted = (array[0] <= array[1]) &&
                       (array[1] <= array[2]) &&
                       (array[2] <= array[3]) &&
                       (array[3] <= array[4]) &&
                       (array[4] <= array[5]);
```

---

## 8. DISPLAY RENDERING SUBSYSTEM

### 8.1 Demo Mode Pixel Generator: `pixel_generator.v`

**Display Specifications:**
- **Box Dimensions:** 14×10 pixels each (including 1-pixel border)
- **Box Spacing:** 2 pixels between boxes
- **Total Array Width:** 94 pixels (6 boxes × 14 + 5 spacings × 2)
- **Horizontal Centering:** 1-pixel offset from left edge
- **Vertical Position:** Rows 27-37 (centered on 64-pixel height)

**Number Font: 6×8 Pixel Glyphs (Lines 66-88)**

Custom bitmap font for digits 0-9:
```verilog
function digit_pixel;
    input [3:0] digit;
    input [2:0] px, py;  // px: 0-5, py: 0-7
    reg [47:0] font;
    begin
        case (digit)
            0: font = 48'b011100_100010_100010_100010_100010_100010_100010_011100;
            1: font = 48'b001000_011000_001000_001000_001000_001000_001000_011100;
            // ... digits 2-9
        endcase
        digit_pixel = font[flipped_py * 6 + (5 - px)];
    end
endfunction
```

**Color Coding (Lines 234-243, 309-317):**
```verilog
color = done ? GREEN :                                      // All sorted
        (swap_flag && (i == compare_idx1 || i == compare_idx2)) ? RED :  // Swapping
        (sorting && (i == compare_idx1 || i == compare_idx2)) ? YELLOW : // Comparing
        WHITE;                                              // Normal
```

**RGB565 Color Palette:**
```verilog
localparam [15:0] BLACK  = 16'h0000;
localparam [15:0] WHITE  = 16'hFFFF;
localparam [15:0] YELLOW = 16'hFFE0;
localparam [15:0] RED    = 16'hF800;
localparam [15:0] GREEN  = 16'h07E0;
localparam [15:0] BLUE   = 16'h001F;
```

**Background Dot Pattern (Lines 56-59):**
```verilog
assign background_dot = (x[2:0] == 3'b000) && (y[2:0] == 3'b000);
assign background_pixel_color = background_dot ? BLUE : BLACK;
// Creates 8×8 grid of blue dots
```

### 8.2 Tutorial Mode Pixel Generator: `tutorial_pixel_generator.v`

**Enhanced Display Layout (96×64 OLED):**

| Rows | Feature | Description |
|------|---------|-------------|
| 0-6 | **Progress Bar** | Green filled bar with white border |
| 7-15 | **Status Text** | State-colored indicator bar |
| 16-26 | **Feedback Area** | 8×8 checkmark (✓) or X sprites |
| 27-42 | **Array Boxes** | 6 boxes with numbers (14×10 each) |
| 43-52 | **Instruction Text** | "COMPARE: X Y" or "SWAPPING!" |
| 53-63 | **Background** | Blue dot pattern |

**Feedback Sprites (8×8 bitmaps):**

Checkmark sprite (lines 161-172):
```verilog
checkmark_sprite[0] = 8'b00000000;
checkmark_sprite[1] = 8'b00000001;
checkmark_sprite[2] = 8'b00000011;
checkmark_sprite[3] = 8'b10000110;
checkmark_sprite[4] = 8'b11001100;
checkmark_sprite[5] = 8'b01111000;
checkmark_sprite[6] = 8'b00110000;
checkmark_sprite[7] = 8'b00000000;
```

X sprite (lines 177-188):
```verilog
x_sprite[0] = 8'b10000001;
x_sprite[1] = 8'b11000011;
x_sprite[2] = 8'b01100110;
x_sprite[3] = 8'b00111100;
x_sprite[4] = 8'b00111100;
x_sprite[5] = 8'b01100110;
x_sprite[6] = 8'b11000011;
x_sprite[7] = 8'b10000001;
```

**Letter ROM (5×7 font, lines 129-156):**
```verilog
// Example: Letter 'S' = 18
letter_rom[18] = 35'b01111_10000_10000_01110_00001_00001_11110;
```

**Box Color State Machine (Lines 354-373):**
```verilog
// Cursor highlight in setup (CYAN)
if ((current_state == 4'd1) && (i == cursor_pos))
    box_color = CYAN;

// Selected pair in tutorial (YELLOW)
else if ((current_state == 4'd3 || 4'd4 || 4'd5) &&
         (i == cursor_pos || i == compare_pos))
    box_color = YELLOW;

// Swapping animation (RED)
else if (current_state == 4'd6 &&
         (i == cursor_pos || i == compare_pos))
    box_color = RED;

// All sorted (GREEN)
else if (is_sorted)
    box_color = GREEN;
```

**Celebration Animation (Lines 588-609):**
```verilog
if (current_state == 4'd9) begin  // TUTORIAL_COMPLETE
    // Rainbow cycling through boxes
    case ((anim_frame + i) % 6)
        0: box_color = RED;
        1: box_color = ORANGE;
        2: box_color = YELLOW;
        3: box_color = GREEN;
        4: box_color = CYAN;
        5: box_color = MAGENTA;
    endcase
end
```

---

## 9. HARDWARE INTERFACE LAYER

### 9.1 Button Debouncing: `button_debounce_5btn.v`

**Purpose:** Eliminate mechanical bounce and provide clean edge detection

**Implementation:**
- **Sampling:** 1 kHz (every 1 ms)
- **Debounce Window:** Requires 10 consecutive stable samples
- **Edge Detection:** Rising edge only (0→1 transition)
- **Output:** Single-cycle pulse on valid button press

**Technical Highlight:** Prevents double-triggering and ensures deterministic user input.

### 9.2 Clock Generation: `clock_divider.v`

**Generated Clocks:**

1. **6.25 MHz (clk_oled):**
   ```verilog
   // 100 MHz ÷ 16 = 6.25 MHz
   always @(posedge clk) begin
       if (clk_counter_6p25MHz >= 7) begin
           clk_counter_6p25MHz <= 0;
           clk_6p25MHz <= ~clk_6p25MHz;
       end
   end
   ```
   **Use:** OLED SPI communication timing

2. **1 Hz Pulse (clk_1hz_pulse):**
   ```verilog
   // 100,000,000 cycles = 1 second
   always @(posedge clk) begin
       if (counter_1hz >= 100_000_000 - 1) begin
           counter_1hz <= 0;
           clk_1hz_pulse <= 1;
       end else begin
           clk_1hz_pulse <= 0;
       end
   end
   ```
   **Use:** FSM step progression in demo mode

3. **~60 Hz Frame Tick (frame_tick):**
   ```verilog
   // 100 MHz ÷ 1,666,667 ≈ 60 Hz
   if (frame_counter >= 1_666_666) begin
       frame_tick <= 1;
   end
   ```
   **Use:** Animation frame synchronization

### 9.3 OLED Display Driver: `Oled_Display.v`

**Communication Protocol:** SPI (Serial Peripheral Interface)

**Signals:**
- **cs (JC[0]):** Chip Select (active low)
- **sdin (JC[1]):** Serial Data In
- **sclk (JC[3]):** Serial Clock
- **d_cn (JC[4]):** Data/Command control
- **resn (JC[5]):** Reset (active low)
- **vccen (JC[6]):** VCC Enable
- **pmoden (JC[7]):** PMOD Enable

**Frame Rendering:**
- **Total Pixels:** 96 × 64 = 6,144 pixels
- **Pixel Index:** 14-bit counter (0 to 6143)
- **Pixel Sampling:** `sample_pixel` signal triggers pixel_generator
- **Frame Begin:** `frame_begin` signal marks new frame start

**Technical Note:** DO NOT MODIFY - Based on external reference implementation for OLED PMOD compatibility.

---

## 10. INTEGRATION & UNIFIED CONTROL

### 10.1 Sorting Visualizer Top: `sorting_visualizer_top.v`

**Multi-Algorithm Support:**

The system integrates 4 sorting algorithms with conflict detection:

```verilog
// Algorithm selection (lines 41-48)
wire invalid_combination = (sw[15] && sw[14]) || (sw[15] && sw[13]) || ...;

wire merge_sort_active = sw[15] && !sw[14] && !sw[13] && !sw[12];
wire insertion_sort_active = sw[14] && !sw[15] && !sw[13] && !sw[12];
wire selection_sort_active = sw[13] && !sw[15] && !sw[14] && !sw[12];
wire bubble_sort_active = sw[12] && !sw[15] && !sw[14] && !sw[13];
```

**Auto-Reset on Algorithm Switch (Lines 63-70):**
```verilog
wire reset_bubble_sort = merge_sort_active || insertion_sort_active ||
                         selection_sort_active || invalid_combination;
```

**Tutorial Mode Detection:**
```verilog
wire bubble_tutorial_mode = bubble_sort_active && sw[10];
wire bubble_demo_mode = bubble_sort_active && !sw[10];
```

---

## 11. KEY TECHNICAL ACHIEVEMENTS

### 11.1 Hardware Optimization

1. **Efficient State Encoding:**
   - 3-bit FSM states (demo): Only 7 states, no wasted encodings
   - 4-bit FSM states (tutorial): 10 states with room for expansion

2. **Resource-Conscious Animation:**
   - Fixed-point arithmetic for scaling (no floating-point units)
   - Pre-calculated box positions to reduce combinational logic

3. **Pixel Generation Parallelism:**
   - Single always block evaluates all 6 boxes in parallel
   - Priority-based rendering (box 0 has highest priority)

### 11.2 User Experience Features

1. **Smooth 4-Phase Swap Animation:**
   - Visual continuity across phase boundaries
   - Maintains box positions during multi-phase transitions
   - Actual array swap only at final frame for visual clarity

2. **Real-Time Feedback:**
   - Immediate checkmark/X display on user decision
   - Progress bar updates after every comparison
   - Color-coded states (cyan=setup, yellow=compare, red=swap, green=done)

3. **Educational Scaffolding:**
   - Tutorial enforces bubble sort order (can't skip positions)
   - Direction validation (must compare left after swap, right after skip)
   - Visual comparison display shows exact values being compared

### 11.3 Robustness & Reliability

1. **Button Debouncing:**
   - 10ms debounce window prevents double-presses
   - Rising-edge detection ensures single action per press

2. **State Machine Safety:**
   - Default cases prevent undefined states
   - Reset paths from all states
   - Mode switching automatically resets FSMs

3. **Display Synchronization:**
   - Frame-locked animation updates
   - Pixel sampling synchronized with OLED refresh
   - No tearing or visual artifacts

---

## 12. TECHNICAL SPECIFICATIONS SUMMARY

### 12.1 Demo Mode Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| Array Size | 6 elements | 8-bit values (0-255), displayed as 0-9 |
| Comparison Rate | 1 Hz | Configurable via step_pulse |
| Swap Animation | 4 seconds | 4 phases × 60 frames × 16.67ms |
| Frame Rate | 60 FPS | 100MHz ÷ 1,666,667 |
| FSM States | 7 states | 3-bit encoding |
| Pattern Options | 4 presets | Random, Sorted, Reverse, Custom |
| Pause/Resume | Yes | Via btnD |
| Display Colors | 6 colors | Black, White, Yellow, Red, Green, Blue |

### 12.2 Tutorial Mode Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| Array Size | 6 elements | 3-bit values (0-7) user-editable |
| FSM States | 10 states | 4-bit encoding |
| Input Methods | 5 buttons | L/R/U/D/C for full control |
| Feedback Types | 2 types | Checkmark (✓) and X mark |
| Progress Tracking | 0-100% | Based on ordered pairs |
| Validation | Dual | Position AND decision correctness |
| Swap Animation | ~0.25 seconds | 16 frames at 60 FPS |
| Feedback Display | ~1 second | 60 frames hold time |
| Celebration | Rainbow cycle | 6-color rotation on completion |

### 12.3 Display Specifications

| Component | Demo Mode | Tutorial Mode |
|-----------|-----------|---------------|
| Box Count | 6 boxes | 6 boxes |
| Box Size | 14×10 pixels | 14×10 pixels |
| Font Size | 6×8 pixels | 5×7 pixels |
| Progress Bar | No | Yes (rows 1-5) |
| Feedback Area | No | Yes (rows 16-26) |
| Instruction Text | "BUBBLE SORT!" on done | "COMPARE: X Y" / "SWAPPING!" |
| Background | Blue dot grid (8×8) | Blue dot grid (8×8) |
| Color Palette | 6 colors | 8 colors |

---

## 13. FILE STRUCTURE & DEPENDENCIES

### 13.1 Core Bubble Sort Modules

```
bubble_sort_top.v (348 lines)
├── Inputs: clk, btnC, btnU, btnL, btnR, btnD, sw[15:0]
├── Outputs: led[15:0], seg[6:0], an[3:0], JC[7:0]
├── Instantiates:
│   ├── button_debounce_5btn
│   ├── clock_divider
│   ├── bubble_sort_fsm (demo mode)
│   ├── tutorial_fsm (tutorial mode)
│   ├── pixel_generator (demo display)
│   ├── tutorial_pixel_generator (tutorial display)
│   └── Oled_Display
└── Mode Selection: sw[12]=bubble, sw[0]=tutorial flag

bubble_sort_fsm.v (288 lines)
├── Purpose: Demo mode FSM and animation
├── States: 7 (IDLE, COMPARE, SWAP_START, SWAP_ANIM, INCREMENT, NEXT_PASS, DONE)
├── Features:
│   ├── 4 pre-loaded patterns
│   ├── 4-phase swap animation (60 frames each)
│   ├── Automatic step progression (1 Hz)
│   └── Pause/resume support
└── Outputs: array0-5, compare indices, swap_flag, anim signals

tutorial_fsm.v (536 lines)
├── Purpose: Interactive tutorial FSM
├── States: 10 (SETUP_INIT → TUTORIAL_COMPLETE)
├── Features:
│   ├── Custom array creation (values 0-7)
│   ├── Position and decision validation
│   ├── Real-time feedback (✓ or X)
│   ├── Progress tracking (0-100%)
│   └── Celebration animation
└── Outputs: array0-5, cursor_pos, compare_pos, feedback flags, progress

pixel_generator.v (396 lines)
├── Purpose: Demo mode display rendering
├── Features:
│   ├── 6×8 digit font
│   ├── 4-phase swap animation rendering
│   ├── Color-coded boxes (WHITE/YELLOW/RED/GREEN)
│   ├── "BUBBLE SORT!" victory text
│   └── Blue dot background pattern
└── Output: pixel_data (RGB565)

tutorial_pixel_generator.v (613 lines)
├── Purpose: Tutorial mode display rendering
├── Layout:
│   ├── Progress bar (rows 0-6)
│   ├── Status indicator (rows 7-15)
│   ├── Feedback sprites (rows 16-26)
│   ├── Array boxes (rows 27-42)
│   ├── Instruction text (rows 43-52)
│   └── Background (rows 53-63)
├── Features:
│   ├── 5×7 character and letter fonts
│   ├── 8×8 checkmark and X sprites
│   ├── Rainbow celebration (6 colors)
│   └── State-dependent color coding
└── Output: pixel_data (RGB565)
```

### 13.2 Support Modules

```
button_debounce_5btn.v
├── Samples at 1 kHz
├── 10-sample debounce window
└── Rising-edge detection for all 5 buttons

clock_divider.v
├── 6.25 MHz (OLED SPI)
├── 1 Hz pulse (FSM steps)
└── ~60 Hz frame tick (animations)

Oled_Display.v
├── SPI protocol implementation
├── Frame buffer management
└── 6,144-pixel addressing (96×64)

sorting_visualizer_top.v
├── Multi-algorithm integration
├── Conflict detection (SW15-12)
└── Unified OLED sharing
```

---

## 14. ALGORITHMIC CORRECTNESS

### 14.1 Bubble Sort Algorithm

**Classic Implementation:**
```python
def bubble_sort(array):
    n = len(array)
    for pass_num in range(n):
        swapped = False
        for i in range(n - pass_num - 1):
            if array[i] > array[i + 1]:
                array[i], array[i + 1] = array[i + 1], array[i]
                swapped = True
        if not swapped:
            break  # Early termination if already sorted
```

**Verilog FSM Mapping:**

| Python Code | Verilog State | Lines |
|-------------|---------------|-------|
| `for pass_num in range(n)` | NEXT_PASS loop control | 249-255 |
| `for i in range(n - pass_num - 1)` | INCREMENT, limit check | 124-129, 240-247 |
| `if array[i] > array[i+1]` | COMPARE state | 100-108, 190-200 |
| `array[i], array[i+1] = ...` | SWAP_ANIM (frame 59) | 229-232 |
| `swapped = True` | swapped_this_pass flag | 209, 252 |
| `if not swapped: break` | NEXT_PASS early exit | 133 |

**Time Complexity:**
- **Best Case:** O(n) when array is already sorted (early termination)
- **Average Case:** O(n²)
- **Worst Case:** O(n²) when array is reverse sorted

**Space Complexity:** O(1) - in-place sorting

### 14.2 Correctness Verification

**Test Patterns:**

1. **PATTERN_RANDOM** (5,2,4,1,3,0):
   - Expected swaps: 9
   - Expected passes: 5 (no early termination)
   - Final state: (0,1,2,3,4,5)

2. **PATTERN_SORTED** (0,1,2,3,4,5):
   - Expected swaps: 0
   - Expected passes: 1 (early termination after pass 0)
   - Final state: (0,1,2,3,4,5)

3. **PATTERN_REVERSE** (5,4,3,2,1,0):
   - Expected swaps: 15 (worst case: n(n-1)/2 = 6×5/2)
   - Expected passes: 5 (all passes needed)
   - Final state: (0,1,2,3,4,5)

**Invariants Maintained:**
1. After pass `k`, the largest `k` elements are in their final positions
2. `compare_idx1` always equals `i`, `compare_idx2` always equals `i+1`
3. Comparison limit decreases by 1 each pass: `i < (5 - pass_count)`
4. Array is sorted in ascending order upon DONE state

---

## 15. TIMING ANALYSIS

### 15.1 Demo Mode Timing

**For PATTERN_RANDOM (5,2,4,1,3,0):**

| Event | Time | Cumulative |
|-------|------|------------|
| Press btnU (START) | 0s | 0s |
| First COMPARE (5 vs 2) | 1s | 1s |
| SWAP_ANIM (4 sec) | 4s | 5s |
| Second COMPARE (5 vs 4) | 1s | 6s |
| SWAP_ANIM (4 sec) | 4s | 10s |
| ... (7 more swaps) | 56s | 66s |
| Total time to DONE | ~70s | ~70s |

**Calculation:**
- 9 swaps × 4 seconds each = 36 seconds
- ~20 non-swap comparisons × 1 second = 20 seconds
- Transition overhead: ~5 seconds
- **Total: approximately 60-70 seconds**

### 15.2 Tutorial Mode Timing

**User-Dependent, but Typical Scenario:**

| Phase | Actions | Time Estimate |
|-------|---------|---------------|
| Setup (create array) | 6 boxes × 2-3 button presses | 10-20 seconds |
| Confirm | Press btnC | 1 second |
| Tutorial sorting | 15-20 comparisons + swaps | 30-60 seconds |
| Feedback delays | ~1 second each | 15-20 seconds |
| Victory celebration | Watch rainbow | 5-10 seconds |
| **Total** | **Complete tutorial** | **60-110 seconds** |

**Performance Factors:**
- User's familiarity with bubble sort
- Number of mistakes (red X feedback adds time)
- Array complexity (more inversions = more swaps)

---

## 16. POWER CONSUMPTION ESTIMATE

**Basys 3 FPGA (XC7A35T) Typical Power:**

| Component | Power Draw | Notes |
|-----------|------------|-------|
| FPGA Static | 50-100 mW | Leakage current |
| FPGA Dynamic (Low Activity) | 100-200 mW | Clock distribution, FSM |
| FPGA Dynamic (High Activity) | 300-500 mW | Pixel generation, animation |
| OLED Display | 100-150 mW | Active pixels (varies by content) |
| LEDs (2 active) | 20-40 mW | LED[12] and LED[0] |
| 7-Segment Display | 50-100 mW | 4 digits multiplexed |
| **Total System** | **620-1090 mW** | **Typical: ~800 mW** |

**Optimization Opportunities:**
- Reduce animation frame rate (60 Hz → 30 Hz): 10-15% power savings
- Dim OLED brightness: 20-30% display power savings
- Clock gating for inactive modules: 5-10% FPGA power savings

---

## 17. RESOURCE UTILIZATION (ESTIMATED)

**For Bubble Sort Module on Artix-7 XC7A35T:**

| Resource | Used (Est.) | Available | Utilization |
|----------|-------------|-----------|-------------|
| **Slice LUTs** | 800-1200 | 20,800 | 4-6% |
| **Slice Registers** | 400-600 | 41,600 | 1-2% |
| **Block RAM** | 2-4 (36Kb) | 50 | 4-8% |
| **DSP48 Slices** | 0 | 90 | 0% |
| **IO Pins** | 38 | 106 | 36% |

**Breakdown:**
- **FSMs:** ~200 LUTs, ~150 registers
- **Pixel Generators:** ~500 LUTs (font ROMs, color logic)
- **Display Driver:** ~300 LUTs, ~200 registers
- **Clock/Button Logic:** ~100 LUTs, ~50 registers

**Technical Note:** No DSP slices used - all arithmetic is simple addition/comparison.

---

## 18. FUTURE ENHANCEMENT OPPORTUNITIES

### 18.1 Feature Enhancements

1. **Variable Speed Control:**
   - Add SW[9:8] for speed selection (0.5Hz / 1Hz / 2Hz / 4Hz)
   - Enhance learning by allowing fast-forward

2. **Sound Effects:**
   - Beep on swap (PMOD AMP2)
   - Victory chime on completion
   - Error buzz on tutorial mistakes

3. **Statistics Display:**
   - Show swap count and comparison count
   - Display on 7-segment or OLED
   - Track tutorial accuracy percentage

4. **Multi-Level Tutorial:**
   - Beginner: Show correct answer hints
   - Intermediate: Current mode (position + decision validation)
   - Expert: No guidance, only final result

### 18.2 Technical Enhancements

1. **Optimized Animation:**
   - Variable-speed animation (faster for small offsets)
   - Bezier curve interpolation for smoother motion

2. **Enhanced Feedback:**
   - Color-coded hints (green glow for correct pair)
   - Arrow indicators showing required swap direction

3. **Expanded Array Size:**
   - Support 8 or 10 elements (requires wider OLED or smaller boxes)
   - Configurable via switches

4. **Historical Playback:**
   - Record and replay tutorial sessions
   - Allow step-backward in demo mode

---

## 19. CONCLUSION

### 19.1 Technical Achievements

This Bubble Sort Visualizer demonstrates **professional-grade FPGA design** with:

1. **Robust State Machine Design:**
   - Clean state separation (7 demo states, 10 tutorial states)
   - Deterministic transitions with no race conditions
   - Reset paths from all states

2. **Efficient Hardware Implementation:**
   - Resource-conscious: <6% LUT utilization
   - No floating-point or DSP usage (pure combinational/sequential logic)
   - Optimized pixel generation with parallel box rendering

3. **Sophisticated Animation System:**
   - 4-phase swap with smooth interpolation
   - Frame-locked synchronization (60 FPS)
   - Visual continuity across phase boundaries

4. **Comprehensive User Experience:**
   - Dual-mode operation (demo + tutorial)
   - Real-time feedback (visual + text)
   - Intuitive button mapping

5. **Educational Value:**
   - Enforces correct bubble sort algorithm order
   - Validates both position and decision
   - Progress tracking and instant feedback

### 19.2 Learning Outcomes

**For Users:**
- Visual understanding of bubble sort algorithm
- Hands-on practice with interactive tutorial
- Observation of time complexity (O(n²)) in action

**For Developers:**
- Complex FSM design and implementation
- FPGA clock management and synchronization
- Display driver integration (OLED SPI)
- Animation rendering techniques
- Button debouncing and edge detection

### 19.3 Project Impact

This project successfully bridges **theoretical algorithms** and **tangible hardware**, making computer science education more **accessible and engaging**. The dual-mode approach caters to both **visual learners** (demo mode) and **kinesthetic learners** (tutorial mode), maximizing educational effectiveness.

**Key Differentiators:**
- ✓ Real hardware implementation (not simulation)
- ✓ Dual-mode learning (passive + active)
- ✓ Comprehensive validation (position + decision)
- ✓ Professional-grade animation and UX
- ✓ Extensible architecture (easy to add more algorithms)

---

## APPENDIX A: SIGNAL REFERENCE

### A.1 Demo Mode Signals

| Signal Name | Width | Direction | Description |
|-------------|-------|-----------|-------------|
| `clk` | 1 | Input | 100 MHz system clock |
| `rst` | 1 | Input | Synchronous reset (active high) |
| `start` | 1 | Input | Start sorting (btnU edge) |
| `step_pulse` | 1 | Input | 1 Hz step progression |
| `pattern_sel` | 2 | Input | Pattern selection (SW[1:0]) |
| `array0`-`array5` | 8×6 | Output | Current array values |
| `compare_idx1` | 3 | Output | First comparison index (0-5) |
| `compare_idx2` | 3 | Output | Second comparison index (0-5) |
| `swap_flag` | 1 | Output | High during swap animation |
| `anim_progress` | 5 | Output | Animation frame (0-59) |
| `anim_phase` | 2 | Output | Animation phase (0-3) |
| `sorting` | 1 | Output | High when actively sorting |
| `done` | 1 | Output | High when sort complete |

### A.2 Tutorial Mode Signals

| Signal Name | Width | Direction | Description |
|-------------|-------|-----------|-------------|
| `clk` | 1 | Input | 100 MHz system clock |
| `reset` | 1 | Input | Synchronous reset |
| `enable` | 1 | Input | Tutorial mode enable (SW[12] & SW[0]) |
| `btn_l_edge` | 1 | Input | Left button rising edge |
| `btn_r_edge` | 1 | Input | Right button rising edge |
| `btn_u_edge` | 1 | Input | Up button rising edge |
| `btn_d_edge` | 1 | Input | Down button rising edge |
| `btn_c_edge` | 1 | Input | Center button rising edge |
| `frame_tick` | 1 | Input | ~60 Hz frame synchronization |
| `array0`-`array5` | 8×6 | Output | Current array values |
| `cursor_pos` | 3 | Output | Selected pair position (0-4) |
| `compare_pos` | 3 | Output | Second element of pair (cursor+1) |
| `anim_frame` | 5 | Output | Animation frame counter (0-31) |
| `progress_percent` | 7 | Output | Progress percentage (0-100) |
| `feedback_correct` | 1 | Output | Show green checkmark |
| `feedback_incorrect` | 1 | Output | Show red X |
| `is_sorted` | 1 | Output | Array fully sorted flag |
| `current_state_num` | 4 | Output | Current FSM state (0-9) |

---

## APPENDIX B: STATE ENCODING REFERENCE

### B.1 Demo Mode States (bubble_sort_fsm.v)

| State Name | Encoding | Decimal | Description |
|------------|----------|---------|-------------|
| IDLE | 3'b000 | 0 | Waiting for start |
| COMPARE | 3'b001 | 1 | Comparing elements |
| SWAP_START | 3'b010 | 2 | Initiate swap |
| SWAP_ANIM | 3'b110 | 6 | Swap animation |
| INCREMENT | 3'b011 | 3 | Advance index |
| NEXT_PASS | 3'b100 | 4 | Next bubble pass |
| DONE | 3'b101 | 5 | Sorting complete |

### B.2 Tutorial Mode States (tutorial_fsm.v)

| State Name | Encoding | Decimal | Description |
|------------|----------|---------|-------------|
| SETUP_INIT | 4'd0 | 0 | Initialize array |
| SETUP_EDIT | 4'd1 | 1 | User edits values |
| SETUP_CONFIRM | 4'd2 | 2 | Confirm and prepare |
| TUTORIAL_SELECT | 4'd3 | 3 | Select pair and decide |
| TUTORIAL_COMPARE | 4'd4 | 4 | Show comparison |
| TUTORIAL_AWAIT_SWAP | 4'd5 | 5 | Wait for decision |
| TUTORIAL_SWAP_ANIM | 4'd6 | 6 | Swap animation |
| TUTORIAL_FEEDBACK | 4'd7 | 7 | Show ✓ or X |
| TUTORIAL_CHECK_DONE | 4'd8 | 8 | Check if sorted |
| TUTORIAL_COMPLETE | 4'd9 | 9 | Victory celebration |

---

## APPENDIX C: COLOR PALETTE REFERENCE

### C.1 RGB565 Encoding

| Color | Hex Value | Binary (RGB565) | Usage |
|-------|-----------|-----------------|-------|
| **BLACK** | 16'h0000 | 00000_000000_00000 | Background, number text |
| **WHITE** | 16'hFFFF | 11111_111111_11111 | Normal boxes, borders |
| **RED** | 16'hF800 | 11111_000000_00000 | Swapping boxes (demo), error feedback |
| **GREEN** | 16'h07E0 | 00000_111111_00000 | Done state, correct feedback, progress bar |
| **BLUE** | 16'h001F | 00000_000000_11111 | Background dots |
| **YELLOW** | 16'hFFE0 | 11111_111111_00000 | Comparing boxes, tutorial selection |
| **CYAN** | 16'h07FF | 00000_111111_11111 | Tutorial cursor (setup mode) |
| **MAGENTA** | 16'hF81F | 11111_000001_11111 | Celebration, swap flash |
| **ORANGE** | 16'hFC00 | 11111_100000_00000 | Tutorial status indicator |
| **GRAY** | 16'h7BEF | 01111_011111_01111 | Empty progress bar |

---

## APPENDIX D: CONTACT & SUPPORT

**For Technical Questions:**
- Review this documentation thoroughly
- Check COMPREHENSIVE_DOCUMENTATION.md for broader system context
- Consult Basys 3 Reference Manual for hardware specifications

**For Hardware Issues:**
- Verify OLED PMOD connection to JC port
- Check power supply (USB or external)
- Confirm FPGA programming successful (DONE LED should be lit)

**For Software/Simulation:**
- Use Vivado 2018.2 or later
- Simulation testbench available in `2026_project.srcs/sim_1/`
- Constraints file: `Basys3_Master.xdc`

---

**END OF DOCUMENTATION**

*This comprehensive documentation covers all aspects of the Bubble Sort Visualizer implementation, from high-level user operation to low-level hardware details. For maximum educational value, users are encouraged to experiment with both demo and tutorial modes, observing the algorithm's behavior across different input patterns.*
