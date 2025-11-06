# EE2026 Bubble Sort Visualizer - Comprehensive Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Hardware Interfaces](#hardware-interfaces)
3. [Operating Modes](#operating-modes)
4. [Module Architecture](#module-architecture)
5. [Signal Routing](#signal-routing)
6. [Integration Guide](#integration-guide)
7. [Build and Deployment](#build-and-deployment)

---

## Project Overview

### Purpose
Interactive bubble sort visualization and educational tutorial running on Basys 3 FPGA (Artix-7). Provides both automated demonstration and hands-on learning experience.

### Key Features
- **Demo Mode**: Automated bubble sort visualization with step-by-step animation
- **Tutorial Mode**: Interactive learning with real-time feedback
- **Visual Feedback**: 96×64 OLED display with color-coded states
- **Multiple Patterns**: 4 predefined sorting patterns
- **Hardware Controls**: 5 buttons + 16 switches for full interaction

### Platform Specifications
- **FPGA**: Xilinx Artix-7 (Basys 3 board)
- **Language**: Verilog HDL
- **System Clock**: 100 MHz
- **Build Tool**: Vivado Design Suite
- **Display**: RGB565 OLED (96×64 pixels) via SPI

---

## Hardware Interfaces

### Input Devices

#### Switches (sw[15:0])

| Switch | Function | Values | Description |
|--------|----------|--------|-------------|
| `sw[12]` | **Bubble Sort Active** | ON/OFF | Main enable switch. Must be ON for any functionality. LED[12] mirrors this state. |
| `sw[0]` | **Tutorial Mode** | ON/OFF | When sw[12]=ON and sw[0]=ON, enters tutorial mode. Otherwise demo mode. |
| `sw[1:0]` | **Pattern Selection** (Demo only) | 00/01/10/11 | Selects initial array pattern (see patterns below) |
| `sw[15:13,11:2]` | *Reserved* | - | Unused, available for expansion |

**Pattern Selection (sw[1:0] - Demo Mode Only):**
```
00 = Random:   [5, 2, 4, 1, 3, 0]
01 = Sorted:   [0, 1, 2, 3, 4, 5]
10 = Reverse:  [5, 4, 3, 2, 1, 0]
11 = Custom:   [3, 5, 1, 4, 2, 0]
```

#### Buttons (Debounced, 10ms threshold)

| Button | Demo Mode Function | Tutorial Mode Function |
|--------|-------------------|------------------------|
| `btnU` (Up) | Start/resume sorting | Increment value (setup) / Confirm swap (sorting) |
| `btnD` (Down) | Pause/resume | Decrement value (setup) / Skip swap (sorting) |
| `btnL` (Left) | Unused | Move cursor left (setup) / Navigate array (sorting) |
| `btnR` (Right) | Unused | Move cursor right (setup) / Navigate array (sorting) |
| `btnC` (Center) | Global reset | Reset / Confirm setup and start |

**Button Debouncing:**
- Hardware debounce: 999,999 cycles @ 100MHz = 10ms
- Single-cycle edge pulse generation
- Independent debounce counters per button

### Output Devices

#### OLED Display (96×64 RGB565)

**Physical Interface (PMOD JC):**
```
JC[0] = CS (Chip Select)
JC[1] = SDIN (Serial Data In)
JC[2] = Not connected
JC[3] = SCLK (Serial Clock, 6.25 MHz)
JC[4] = D/CN (Data/Command)
JC[5] = RESN (Reset)
JC[6] = VCCEN (Power Enable)
JC[7] = PMODEN (Power Mode)
```

**Color Scheme (RGB565 format):**
```verilog
Black:   16'h0000  // Background
White:   16'hFFFF  // Default elements
Yellow:  16'hFFE0  // Comparing
Red:     16'hF800  // Swapping
Green:   16'h07E0  // Sorted/Correct
Blue:    16'h001F  // Background pattern
Cyan:    16'h07FF  // Tutorial UI
Magenta: 16'hF81F  // Tutorial UI
Orange:  16'hFC00  // Tutorial UI
Gray:    16'h8410  // Tutorial UI
```

**Display Layout - Demo Mode:**
```
┌─────────────────────────────┐ 96×64 pixels
│ Background (blue dots)      │
│                             │
│   ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐  │
│   │5 │ │2 │ │4 │ │1 │ │3 │ │0 │  │ Array boxes (14×10 px)
│   └──┘ └──┘ └──┘ └──┘ └──┘ └──┘  │
│                             │
└─────────────────────────────┘
```

**Display Layout - Tutorial Mode:**
```
┌─────────────────────────────┐
│ Progress: [████░░░] 45%     │ Rows 0-6: Progress bar
│ Status: Comparing...        │ Rows 7-15: Status text
│       ✓ or ✗               │ Rows 16-26: Feedback sprite
│   ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐  │ Rows 27-42: Array
│   │3 │ │5 │ │1 │ │4 │ │2 │ │0 │  │
│   └──┘ └──┘ └──┘ └──┘ └──┘ └──┘  │
│ U:Swap D:Skip L/R:Navigate  │ Rows 43-52: Instructions
│ State: TUTORIAL_SELECT      │ Rows 53-63: Debug info
└─────────────────────────────┘
```

#### 7-Segment Display (4-digit)

**Display Modes:**
```
"bUbL" - Bubble sort demo mode active
"tutr" - Tutorial mode active
"sort" - Currently sorting
"done" - Sort complete
(blank) - Idle/disabled
```

**Multiplexing:**
- Refresh rate: ~100 kHz
- 20-bit counter for digit selection
- Active-low anode control (an[3:0])

#### LED Array (led[15:0])

```
led[12] = ON when sw[12]=ON (bubble sort enabled)
led[0]  = ON when tutorial mode active
led[15:13,11:1] = Unused, available for expansion
```

---

## Operating Modes

### Mode 1: Demo/Auto-Sort Mode

**Activation:**
- `sw[12] = ON` (bubble sort enabled)
- `sw[0] = OFF` (tutorial disabled)

**User Flow:**
1. Set `sw[12] = ON` to enable
2. Select pattern with `sw[1:0]`
3. Press `btnU` to start sorting
4. Algorithm steps through at 1 Hz (one comparison per second)
5. Press `btnD` to pause/resume
6. Press `btnC` to reset

**Visual Indicators:**
- **Yellow boxes**: Currently being compared
- **Red boxes**: Currently being swapped
- **Green boxes**: Sort complete
- **7-segment**: "bUbL" identifier
- **LED[12]**: ON

**FSM States:**
```
IDLE → COMPARE → SWAP → SWAP_WAIT → INCREMENT → NEXT_PASS → DONE
                  ↓                      ↑
                  └──────────────────────┘ (if no swap needed)
```

**Timing:**
- Step rate: 1 Hz (controlled by clk_1hz_pulse)
- Animation: Smooth color transitions
- Frame rate: 60 Hz refresh

---

### Mode 2: Tutorial/Interactive Mode

**Activation:**
- `sw[12] = ON` (bubble sort enabled)
- `sw[0] = ON` (tutorial enabled)

**User Flow:**

#### Phase 1: Array Setup
```
State: SETUP_INIT → SETUP_EDIT → SETUP_CONFIRM
```

1. Array initializes to [0,0,0,0,0,0]
2. **SETUP_EDIT** - Create your array:
   - `btnL/R`: Navigate cursor left/right (6 positions)
   - `btnU/D`: Increment/decrement value (0-7, wraps)
   - Cursor highlights current position
3. Press `btnC` to confirm and start tutorial

#### Phase 2: Interactive Sorting
```
State: TUTORIAL_SELECT → TUTORIAL_COMPARE → TUTORIAL_AWAIT_SWAP
       → TUTORIAL_SWAP_ANIM → TUTORIAL_FEEDBACK → (repeat)
```

1. **TUTORIAL_SELECT**:
   - Use `btnL/R` to select adjacent pair to compare
   - Yellow highlighting shows selection

2. **TUTORIAL_COMPARE**:
   - System shows which elements are being compared

3. **TUTORIAL_AWAIT_SWAP**:
   - **Decision time**: Should you swap?
   - `btnU` = Perform swap
   - `btnD` = Skip (don't swap)

4. **TUTORIAL_SWAP_ANIM**:
   - If swap chosen, animates swap over 16 frames (~267ms)
   - Smooth sliding transition

5. **TUTORIAL_FEEDBACK**:
   - **Green checkmark (✓)**: Correct decision
   - **Red X (✗)**: Incorrect decision
   - Progress bar updates
   - Displays for ~1 second

6. Repeat until array sorted

#### Phase 3: Completion
```
State: TUTORIAL_CHECK_DONE → TUTORIAL_COMPLETE
```

- **TUTORIAL_COMPLETE**: Celebration screen
- Progress bar at 100%
- Press `btnC` to restart

**Visual Indicators:**
- **Progress bar**: Shows completion percentage (0-100%)
- **Checkmark sprite**: 8×8 green checkmark for correct
- **X sprite**: 8×8 red X for incorrect
- **7-segment**: "tutr" identifier
- **LED[0]**: ON

**Feedback System:**
- Real-time comparison with optimal solution
- Shadow bubble sort tracks correct path
- Inversion counter validates decisions
- Percentage calculation based on total inversions

---

## Module Architecture

### Module Hierarchy
```
bubble_sort_top (Top-level)
├── clock_divider (Clock generation)
├── button_debounce_5btn (Input debouncing)
├── bubble_sort_fsm (Auto-sort FSM)
├── tutorial_fsm (Tutorial FSM)
├── pixel_generator (Demo graphics) ──┐
├── tutorial_pixel_generator (Tutorial graphics) ──┤ Muxed by mode
└── Oled_Display (OLED controller) ◄────────────────┘
```

---

### Module Specifications

#### 1. bubble_sort_top.v (Top-Level Integration)

**Purpose:** System integration, mode selection, I/O management

**Input Ports:**
```verilog
input clk,                    // 100 MHz system clock
input [15:0] sw,              // 16 switches
input btnU, btnD, btnL, btnR, btnC,  // 5 buttons
```

**Output Ports:**
```verilog
output [15:0] led,            // 16 LEDs
output [6:0] seg,             // 7-segment segments
output [3:0] an,              // 7-segment anodes
output [7:0] JC               // OLED PMOD connector
```

**Key Functionality:**
- Mode selection logic (sw[12] and sw[0])
- Button edge pulse routing
- Clock domain management
- Pixel data multiplexing
- 7-segment character encoding
- Frame tick generation (60 Hz)
- LED assignment

**7-Segment Character Map:**
```verilog
"b" = 7'b0011111
"U" = 7'b0111110
"L" = 7'b0001110
"t" = 7'b0001111
"u" = 7'b0011100
"r" = 7'b0000101
"d" = 7'b0111101
"o" = 7'b0111101
"n" = 7'b0010101
"e" = 7'b0001111
```

---

#### 2. bubble_sort_fsm.v (Auto-Sort Controller)

**Purpose:** Implements bubble sort algorithm for demo mode

**FSM States:**
```verilog
IDLE        // Waiting for start
COMPARE     // Comparing adjacent elements
SWAP        // Initiating swap
SWAP_WAIT   // Swap completion (visual delay)
INCREMENT   // Move to next pair
NEXT_PASS   // Start new pass through array
DONE        // Sort complete
```

**Input Ports:**
```verilog
input clk,                    // System clock
input reset,                  // Global reset
input start,                  // Start signal (btnU)
input step_pulse,             // 1 Hz step timing
input pause,                  // Pause signal (btnD)
input [1:0] pattern_sel,      // Pattern selection (sw[1:0])
```

**Output Ports:**
```verilog
output reg [7:0] array0, array1, array2, array3, array4, array5,
output reg [2:0] compare_idx1, compare_idx2,  // Indices being compared
output reg swap_flag,         // High during swap
output reg sorting,           // High while sorting
output reg done               // High when complete
```

**Algorithm Details:**
- 6 elements (array0-array5)
- 8-bit values (0-255)
- Ascending order (smallest to largest)
- Pass optimization (reduces range each pass)
- Early termination (detects no swaps needed)
- Maximum passes: 5
- Worst case comparisons: 15

**Pattern Definitions:**
```verilog
2'b00: array = {8'd5, 8'd2, 8'd4, 8'd1, 8'd3, 8'd0};  // Random
2'b01: array = {8'd0, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5};  // Sorted
2'b10: array = {8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0};  // Reverse
2'b11: array = {8'd3, 8'd5, 8'd1, 8'd4, 8'd2, 8'd0};  // Custom
```

---

#### 3. tutorial_fsm.v (Interactive Tutorial Controller)

**Purpose:** Manages user-driven bubble sort learning experience

**FSM States (10 total):**
```verilog
SETUP_INIT          // Initialize array to zeros
SETUP_EDIT          // User edits array values
SETUP_CONFIRM       // Finalize array setup
TUTORIAL_SELECT     // User selects pair to compare
TUTORIAL_COMPARE    // Display comparison
TUTORIAL_AWAIT_SWAP // Wait for swap decision
TUTORIAL_SWAP_ANIM  // Animate swap (16 frames)
TUTORIAL_FEEDBACK   // Show correct/incorrect feedback
TUTORIAL_CHECK_DONE // Verify if sorted
TUTORIAL_COMPLETE   // Success celebration
```

**Input Ports:**
```verilog
input clk, reset,
input tutorial_active,        // sw[0] && sw[12]
input btn_u, btn_d, btn_l, btn_r, btn_c,  // Edge pulses
input frame_tick              // 60 Hz animation timing
```

**Output Ports:**
```verilog
output reg [7:0] array0-5,    // Current array
output reg [2:0] cursor_pos,  // Setup cursor position
output reg [2:0] select_pos,  // Selected comparison position
output reg [4:0] anim_frame,  // Animation frame counter (0-31)
output reg [6:0] progress,    // Completion percentage (0-100)
output reg feedback_correct, feedback_incorrect,
output reg tutorial_done,
output reg [3:0] current_state  // For debugging
```

**Key Features:**

**Setup Phase:**
- Cursor navigation with btnL/R
- Value editing with btnU/D (wraps 0-7)
- Confirmation with btnC

**Sorting Phase:**
- User selects adjacent pairs
- Real-time feedback on decisions
- Shadow bubble sort for validation
- Inversion counting for progress

**Animation:**
- 16-frame swap animation (~267ms @ 60Hz)
- Smooth interpolation
- Frame counter: 0-31 (wraps)

**Progress Calculation:**
```verilog
progress = 100 - (100 * current_inversions / initial_inversions)
```

**Feedback Logic:**
- Compares user decision with optimal solution
- Sets feedback_correct or feedback_incorrect
- Displays for ~1 second

---

#### 4. button_debounce_5btn.v (Input Processing)

**Purpose:** Debounce all buttons and generate edge pulses

**Debounce Specification:**
```verilog
DEBOUNCE_THRESHOLD = 999_999  // 10ms @ 100MHz
```

**Input/Output:**
```verilog
input clk, reset,
input btnU, btnD, btnL, btnR, btnC,  // Raw buttons
output btn_u_edge, btn_d_edge, btn_l_edge, btn_r_edge, btn_c_edge  // Pulses
```

**Algorithm:**
- Independent 20-bit counter per button
- Synchronized state tracking
- Rising edge detection
- Single-cycle pulse generation

**Logic Flow:**
```
Raw Button → Counter (stabilization) → Sync Register → Edge Detector → Pulse
```

---

#### 5. clock_divider.v (Clock Generation)

**Purpose:** Generate multiple clock domains from 100 MHz system clock

**Input/Output:**
```verilog
input clk,                    // 100 MHz
output reg clk_6p25mhz,      // OLED SPI clock (÷16)
output reg clk_1hz_pulse     // Sorting step pulse (÷100M)
```

**Clock Specifications:**
- **clk_6p25mhz**: 6.25 MHz continuous clock for OLED
  - Division: 100MHz ÷ 16 = 6.25MHz
  - Counter range: 0-7

- **clk_1hz_pulse**: 1 Hz single-cycle pulse for sorting steps
  - Division: 100MHz ÷ 100M = 1Hz
  - Counter range: 0-49,999,999
  - Pulse width: 1 cycle (10ns)

---

#### 6. pixel_generator.v (Demo Mode Graphics)

**Purpose:** Render bubble sort visualization for auto-sort mode

**Input Ports:**
```verilog
input [12:0] pixel_index,     // Current pixel (0-6143)
input [7:0] array0-5,         // Array values
input [2:0] compare_idx1, compare_idx2,  // Highlighting
input swap_flag, done         // State indicators
```

**Output Ports:**
```verilog
output reg [15:0] oled_data   // RGB565 pixel color
```

**Rendering Logic:**
- Combinational logic for all 6,144 pixels
- Pixel coordinate calculation (x = pixel_index % 96, y = pixel_index / 96)
- Box boundary detection (14×10 pixels + 2px spacing)
- Font rendering (6×8 digit glyphs)
- Background pattern (blue dots every 8 pixels)

**Box Layout:**
```
Box 0: x=0-13,   y=27-36
Box 1: x=16-29,  y=27-36
Box 2: x=32-45,  y=27-36
Box 3: x=48-61,  y=27-36
Box 4: x=64-77,  y=27-36
Box 5: x=80-93,  y=27-36
```

**Color Priority:**
```
1. If done → Green
2. If swap_flag and (box == idx1 or idx2) → Red
3. If comparing and (box == idx1 or idx2) → Yellow
4. Else → White
```

**Font System:**
- 6×8 pixel glyphs for digits 0-9
- Stored as 48-bit bitmaps
- Vertical flip for rendering
- Centered within box

---

#### 7. tutorial_pixel_generator.v (Tutorial Mode Graphics)

**Purpose:** Render interactive tutorial interface

**Input Ports:**
```verilog
input [12:0] pixel_index,
input [7:0] array0-5,
input [2:0] cursor_pos, select_pos,
input [4:0] anim_frame,
input [6:0] progress,
input feedback_correct, feedback_incorrect,
input [3:0] current_state
```

**Output Ports:**
```verilog
output reg [15:0] oled_data
```

**Display Regions (96×64 pixels):**

| Rows | Region | Content |
|------|--------|---------|
| 0-6 | Progress Bar | Blue outline, green fill based on progress% |
| 7-15 | Status Text | State-dependent messages |
| 16-26 | Feedback | 8×8 checkmark or X sprite |
| 27-42 | Array Boxes | 6 boxes with values, cursor highlighting |
| 43-52 | Instructions | Button hints based on state |
| 53-63 | Debug Info | Current FSM state |

**Character ROM:**
- 5×7 font for digits (0-9) and letters (A-Z)
- Total: 36 characters
- Stored as 35-bit bitmaps

**Sprite System:**
```verilog
// Checkmark (8×8 pixels)
[0,0,0,0,0,0,1,1]
[0,0,0,0,0,1,1,0]
[1,0,0,0,1,1,0,0]
[1,1,0,1,1,0,0,0]
[0,1,1,1,0,0,0,0]
[0,0,1,0,0,0,0,0]
[0,0,0,0,0,0,0,0]
[0,0,0,0,0,0,0,0]

// X mark (8×8 pixels)
[1,1,0,0,0,0,1,1]
[0,1,1,0,0,1,1,0]
[0,0,1,1,1,1,0,0]
[0,0,0,1,1,0,0,0]
[0,0,1,1,1,1,0,0]
[0,1,1,0,0,1,1,0]
[1,1,0,0,0,0,1,1]
[0,0,0,0,0,0,0,0]
```

**Progress Bar Rendering:**
```verilog
fill_width = (progress * 86) / 100;  // Max 86 pixels
if (x < fill_width) color = GREEN;
else color = GRAY;
```

**Animation:**
- Frame interpolation for swap animation
- Smooth transitions using anim_frame counter

---

#### 8. Oled_Display.v (OLED Controller - DO NOT MODIFY)

**Purpose:** SPI interface controller for RGB OLED display

**Parameters:**
```verilog
ClkFreq = 6_250_000          // 6.25 MHz SPI clock
FrameFreq = 60               // 60 Hz refresh rate
```

**Input Ports:**
```verilog
input clk,                   // 6.25 MHz
input reset,
input [15:0] pixel_data      // RGB565 from pixel generator
```

**Output Ports:**
```verilog
output [12:0] pixel_index,   // Current pixel (0-6143)
output CS, SDIN, SCLK, DC, RES, VCCEN, PMODEN  // SPI signals
```

**Functionality:**
- **Initialization**: Power-up sequence, command configuration
- **SPI Communication**: Serial data transmission @ 6.25 MHz
- **Frame Buffer**: Streams 6,144 pixels (96×64) per frame
- **Refresh**: 60 Hz continuous refresh
- **Power Management**: Controls VccEn and Pmoden

**DO NOT MODIFY** - This is a provided controller. Only connect pixel_data input.

---

#### 9. Basys3_Master.xdc (Pin Constraints)

**Purpose:** Map Verilog signals to physical FPGA pins

**Critical Constraints:**

**Clock:**
```tcl
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 [get_ports clk]  # 100 MHz
```

**Switches:**
```tcl
sw[0]:  V17   sw[1]:  V16   sw[12]: W2   sw[13]: U1
sw[14]: T1    sw[15]: R2
```

**Buttons:**
```tcl
btnC: U18   btnU: T18   btnL: W19   btnR: T17   btnD: U17
```

**LEDs:**
```tcl
led[0]:  U16  led[1]:  E19  ... led[12]: V11  ... led[15]: L1
```

**7-Segment:**
```tcl
seg[0-6]: W7, W6, U8, V8, U5, V5, U7
an[0-3]:  U2, U4, V4, W4
```

**OLED (PMOD JC):**
```tcl
JC[0]: K17   JC[1]: M18   JC[2]: P18   JC[3]: L17
JC[4]: M19   JC[5]: P17   JC[6]: R18
```

---

## Signal Routing

### Complete Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                         CLOCK DOMAIN                                 │
│  100 MHz ──→ clock_divider ──→ 6.25 MHz (OLED)                      │
│                            └──→ 1 Hz pulse (sorting steps)           │
│                            └──→ 60 Hz frame_tick (animation)         │
└──────────────────────────────────────────────────────────────────────┘
                                    ↓
┌──────────────────────────────────────────────────────────────────────┐
│                         INPUT LAYER                                  │
│  Buttons ──→ button_debounce_5btn ──→ Edge Pulses                   │
│  Switches ──→ Direct routing                                         │
└──────────────────────────────────────────────────────────────────────┘
                                    ↓
┌──────────────────────────────────────────────────────────────────────┐
│                      CONTROL LAYER (FSMs)                            │
│                                                                       │
│  sw[12]=ON, sw[0]=OFF:                                               │
│    bubble_sort_fsm ──→ array0-5, compare_idx1/2, swap_flag, done    │
│                                                                       │
│  sw[12]=ON, sw[0]=ON:                                                │
│    tutorial_fsm ──→ array0-5, cursor_pos, anim_frame, progress,     │
│                     feedback signals                                 │
└──────────────────────────────────────────────────────────────────────┘
                                    ↓
┌──────────────────────────────────────────────────────────────────────┐
│                      RENDERING LAYER                                 │
│                                                                       │
│  Mode Mux selects:                                                   │
│    pixel_generator (demo) ──┐                                        │
│    tutorial_pixel_generator ┘──→ pixel_data[15:0]                   │
│                                                                       │
│  Input: pixel_index from OLED controller                             │
│  Output: RGB565 color for current pixel                              │
└──────────────────────────────────────────────────────────────────────┘
                                    ↓
┌──────────────────────────────────────────────────────────────────────┐
│                      OUTPUT LAYER                                    │
│                                                                       │
│  Oled_Display ──→ JC[7:0] (SPI) ──→ Physical OLED                   │
│  7-seg encoder ──→ seg[6:0], an[3:0]                                │
│  LED assignment ──→ led[15:0]                                        │
└──────────────────────────────────────────────────────────────────────┘
```

### Critical Timing Paths

**Path 1: Button to FSM**
```
Button (raw) → Debouncer (10ms) → Edge Pulse → FSM (1 cycle) → State Update
Total latency: ~10ms + 2 clock cycles
```

**Path 2: FSM to Display**
```
FSM State → Array Update → Pixel Generator (combinational) → OLED Controller
Total latency: 1 clock cycle + SPI transmission time
```

**Path 3: Clock Division**
```
100 MHz → ÷16 counter → 6.25 MHz OLED clock
100 MHz → ÷100M counter → 1 Hz pulse
```

---

## Integration Guide

### Integrating with Another Project

#### Step 1: Understand Interface Requirements

**Inputs your project provides:**
- System clock (must be 100 MHz or modify clock_divider.v)
- Reset signal (active high)
- Control signals (can replace switch/button logic)

**Outputs you can use:**
- Array data (6×8-bit values)
- Sort status (sorting, done, compare_idx, swap_flag)
- Tutorial state information

**Peripherals you must support:**
- OLED display with SPI interface
- OR: Replace pixel generators with your own display driver

#### Step 2: Module Instantiation Template

```verilog
bubble_sort_top your_instance_name (
    // Clock and reset
    .clk(your_100mhz_clock),

    // Control inputs
    .sw({
        your_switches[15:13],    // Unused
        your_bubble_enable,      // sw[12]
        your_switches[11:2],     // Unused
        your_pattern_select,     // sw[1:0]
        your_tutorial_enable     // sw[0]
    }),

    // Button inputs (provide edge pulses or raw buttons)
    .btnU(your_start_button),
    .btnD(your_pause_button),
    .btnL(your_left_button),
    .btnR(your_right_button),
    .btnC(your_reset_button),

    // LED outputs
    .led(your_led_array),

    // 7-segment outputs
    .seg(your_segments),
    .an(your_anodes),

    // OLED output
    .JC(your_pmod_connector)
);
```

#### Step 3: Modify for Custom Control

**Example: Replace switches with state machine control**

In `bubble_sort_top.v`, change:
```verilog
// Original
wire bubble_sort_active = sw[12];
wire tutorial_mode = sw[0];

// Modified for external control
input wire bubble_sort_active,
input wire tutorial_mode,
// Remove: input [15:0] sw,
```

**Example: Use different clock frequency**

Modify `clock_divider.v`:
```verilog
// Original: 100 MHz → 6.25 MHz
parameter DIV_OLED = 16;

// For 50 MHz input → 6.25 MHz
parameter DIV_OLED = 8;

// For 1 Hz pulse from different frequency:
parameter DIV_1HZ = your_frequency_in_hz;
```

#### Step 4: Interface with Custom Display

**Option A: Use OLED as-is**
- Connect your PMOD JC pins
- Ensure 6.25 MHz SPI clock available
- Provide pixel data from generators

**Option B: Replace pixel generators**
- Keep FSMs for logic
- Route array0-5 and state signals to your display driver
- Remove/bypass OLED controller

**Example: Extract array data only**
```verilog
wire [7:0] sorted_array [0:5];
assign sorted_array[0] = bubble_sort_active ?
    (tutorial_mode ? tutorial_array0 : fsm_array0) : 8'b0;
// ... repeat for array[1-5]

// Use sorted_array in your display logic
```

#### Step 5: Combine with Your FSM

**Example: Use as sub-module in larger state machine**

```verilog
module combined_project (
    input clk,
    input reset,
    // ... your inputs
    output [7:0] JC,
    // ... your outputs
);

// Your main FSM
reg bubble_enable, tutorial_enable;
wire [7:0] bubble_array0, bubble_array1;  // ... etc
wire bubble_done;

always @(posedge clk) begin
    case (main_state)
        INIT: begin
            bubble_enable <= 0;
        end

        BUBBLE_SORT_PHASE: begin
            bubble_enable <= 1;
            tutorial_enable <= 0;
            if (bubble_done) main_state <= NEXT_PHASE;
        end

        TUTORIAL_PHASE: begin
            bubble_enable <= 1;
            tutorial_enable <= 1;
        end
    endcase
end

// Instantiate bubble sort
bubble_sort_top bubble_inst (
    .clk(clk),
    .sw({4'b0, bubble_enable, 7'b0, 2'b00, tutorial_enable}),
    // ... other connections
);

// Your additional logic
// ...

endmodule
```

---

### Configuration Parameters

#### Modifiable Constants

**In bubble_sort_top.v:**
```verilog
// Line 82: Frame tick divider (change animation speed)
parameter FRAME_DIV = 1_666_667;  // 60 Hz @ 100MHz
// Modify to: FRAME_DIV = 5_000_000; for 20 Hz (slower animation)
```

**In bubble_sort_fsm.v:**
```verilog
// Lines 52-59: Pattern definitions
// Add more patterns:
2'b00: begin /* pattern 0 */ end
2'b01: begin /* pattern 1 */ end
2'b10: begin /* pattern 2 */ end
2'b11: begin /* pattern 3 */ end
// To add 8 patterns, change pattern_sel to [2:0] (3 bits)
```

**In pixel_generator.v:**
```verilog
// Lines 36-42: Color definitions
localparam BLACK   = 16'h0000;
localparam WHITE   = 16'hFFFF;
// Change to your preferred colors:
localparam WHITE   = 16'h8410;  // Gray instead of white
```

**In tutorial_fsm.v:**
```verilog
// Line 125: Feedback display duration
if (feedback_timer < 60) ...  // 1 second @ 60Hz
// Change to: if (feedback_timer < 120) ... for 2-second feedback
```

**In clock_divider.v:**
```verilog
// Adapt to different input clock:
parameter CLK_FREQ = 100_000_000;
parameter TARGET_OLED = 6_250_000;
parameter DIV_OLED = CLK_FREQ / TARGET_OLED / 2;  // Auto-calculate
```

---

### Communication Protocol

If integrating via inter-module communication:

**Output Signals to Monitor:**
```verilog
output wire sorting,           // High while sort in progress
output wire done,              // High when complete
output wire [2:0] compare_idx1, compare_idx2,  // Current comparison
output wire swap_flag,         // High during swap
output wire [7:0] array0-5,   // Current array state
```

**Input Control Signals:**
```verilog
input wire start,              // Pulse to start sorting
input wire pause,              // Pause/resume toggle
input wire reset,              // Return to initial state
input wire [1:0] pattern_sel, // Pattern selection
```

**Tutorial-Specific Outputs:**
```verilog
output wire [6:0] progress,           // 0-100 completion
output wire feedback_correct,         // Correct decision
output wire feedback_incorrect,       // Incorrect decision
output wire tutorial_done,            // Tutorial complete
output wire [3:0] current_state,      // For debugging
```

---

### Timing Constraints for Integration

**Minimum Clock Requirements:**
- System clock: 100 MHz (or modify dividers proportionally)
- OLED clock: 6.25 MHz ± 10%
- Button debounce: ≥10ms stability

**Maximum Propagation Delays:**
- Button to FSM response: <1 frame (16.67ms @ 60Hz)
- FSM state to display update: <1 clock cycle
- Pixel generation: Combinational (no delay)

**Setup/Hold Times:**
- All signals synchronous to system clock
- No asynchronous inputs except reset
- Button edges already synchronized by debouncer

---

## Build and Deployment

### Vivado Project Setup

**Project File:** `2026_project.xpr`

**To Open:**
```bash
cd /home/user/ee2026-project
vivado 2026_project.xpr
```

**Source Files (add to project):**
```
2026_project.srcs/sources_1/new/
├── bubble_sort_top.v           (Top-level - set as top module)
├── bubble_sort_fsm.v
├── tutorial_fsm.v
├── button_debounce_5btn.v
├── clock_divider.v
├── pixel_generator.v
├── tutorial_pixel_generator.v
└── Oled_Display.v

2026_project.srcs/constrs_1/new/
└── Basys3_Master.xdc           (Constraints)
```

### Build Process

**Step 1: Synthesis**
```
Tools → Run Synthesis
Or: Flow → Run Synthesis
Wait for completion (~2-5 minutes)
```

**Step 2: Implementation**
```
Tools → Run Implementation
Or: Flow → Run Implementation
Includes: Opt Design, Place Design, Route Design
Wait for completion (~3-7 minutes)
```

**Step 3: Generate Bitstream**
```
Tools → Generate Bitstream
Output: bubble_sort_top.bit
Wait for completion (~1-2 minutes)
```

**Step 4: Program FPGA**
```
Open Hardware Manager
Auto-connect to Basys 3
Program device with .bit file
```

### Build Verification

**Check Reports:**
1. **Utilization Report**: Ensure <80% resource usage
2. **Timing Report**: Verify all constraints met (WNS ≥ 0)
3. **DRC Report**: No critical warnings

**Expected Resource Usage:**
```
LUTs: ~15-25% (moderate)
FFs: ~10-20% (low-moderate)
BRAM: ~5-10% (minimal)
DSPs: 0% (none used)
```

### Deployment Checklist

- [ ] All source files added to project
- [ ] bubble_sort_top.v set as top module
- [ ] Basys3_Master.xdc constraints file loaded
- [ ] Synthesis completed without errors
- [ ] Implementation completed without errors
- [ ] Timing constraints met (check timing report)
- [ ] Bitstream generated successfully
- [ ] Basys 3 connected via USB
- [ ] OLED PMOD connected to JC port
- [ ] Device programmed successfully
- [ ] Switches and buttons respond correctly
- [ ] OLED display shows graphics
- [ ] 7-segment displays correct characters

---

## Troubleshooting

### Common Issues

**Issue: OLED display blank**
- Check PMOD JC connections
- Verify 6.25 MHz clock generation
- Check sw[12] is ON
- Reset with btnC

**Issue: No response to buttons**
- Verify debounce threshold (999,999 cycles)
- Check button edge pulse generation
- Confirm FSM state transitions
- Use ILA (Integrated Logic Analyzer) to debug

**Issue: Timing constraints not met**
- Reduce clock frequency
- Simplify combinational logic in pixel generators
- Add pipeline stages
- Check critical path in timing report

**Issue: Tutorial mode not activating**
- Ensure BOTH sw[12]=ON and sw[0]=ON
- Check tutorial_active signal routing
- Verify mode mux logic in top module

**Issue: Incorrect sorting behavior**
- Verify pattern selection (sw[1:0])
- Check FSM state transitions
- Confirm step_pulse generation (1 Hz)
- Use simulation to verify algorithm

---

## Appendix: Quick Reference

### Switch Quick Reference
```
sw[12] = Main enable (must be ON)
sw[0]  = Tutorial mode (ON=tutorial, OFF=demo)
sw[1:0] = Pattern (demo mode only)
  00 = Random
  01 = Sorted
  10 = Reverse
  11 = Custom
```

### Button Quick Reference (Demo Mode)
```
btnU = Start/Resume
btnD = Pause
btnC = Reset
btnL = Unused
btnR = Unused
```

### Button Quick Reference (Tutorial Mode)
```
Setup Phase:
  btnL/R = Navigate cursor
  btnU/D = Change value
  btnC = Confirm and start

Sorting Phase:
  btnL/R = Select pair
  btnU = Swap
  btnD = Skip
  btnC = Reset
```

### Color Code Reference
```
Demo Mode:
  White = Default
  Yellow = Comparing
  Red = Swapping
  Green = Done

Tutorial Mode:
  Green checkmark = Correct
  Red X = Incorrect
  Yellow = Selected
  Green progress bar = Completion
```

### File Modification Priority
```
HIGH (likely to modify):
  - bubble_sort_top.v (integration logic)
  - bubble_sort_fsm.v (patterns, algorithm)
  - tutorial_fsm.v (feedback timing)

MEDIUM (may modify for customization):
  - pixel_generator.v (colors, layout)
  - tutorial_pixel_generator.v (UI design)
  - clock_divider.v (clock frequencies)
  - Basys3_Master.xdc (pin mapping)

LOW (rarely modify):
  - button_debounce_5btn.v (standard debounce)

NEVER:
  - Oled_Display.v (provided controller)
```

---

## Document Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-11-06 | Initial comprehensive documentation |

---

**End of Documentation**

For questions or integration support, refer to source code comments and module-level documentation within each .v file.
