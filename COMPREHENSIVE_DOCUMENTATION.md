\# EE2026 Sorting Algorithms Visualizer - Comprehensive Documentation

## Integrated Bubble Sort & Merge Sort Visualization System

\## Table of Contents

1\. \[Project Overview](#project-overview)

2\. \[Hardware Interfaces](#hardware-interfaces)

3\. \[Operating Modes](#operating-modes)

4\. \[Module Architecture](#module-architecture)

5\. \[Signal Routing](#signal-routing)

6\. \[Integration Guide](#integration-guide)

7\. \[Build and Deployment](#build-and-deployment)



---



\## Project Overview



\### Purpose

Interactive sorting algorithms visualization and educational tutorial system running on Basys 3 FPGA (Artix-7). Features **Bubble Sort** and **Merge Sort** algorithms with both automated demonstrations and hands-on tutorial modes.



\### Key Features

\- \*\*Dual Algorithm Support\*\*: Switch between Bubble Sort and Merge Sort visualizations

\- \*\*Demo Modes\*\*: Automated visualization with step-by-step animation for both algorithms

\- \*\*Tutorial Modes\*\*: Interactive learning experiences with real-time feedback

\- \*\*Visual Feedback\*\*: 96×64 OLED display with color-coded states and animations

\- \*\*Multiple Patterns\*\*: Configurable initial array patterns

\- \*\*Hardware Controls\*\*: 5 buttons + 16 switches for full interaction

\- \*\*Unified Interface\*\*: Seamless switching between algorithms via hardware switches



\### Platform Specifications

\- \*\*FPGA\*\*: Xilinx Artix-7 (Basys 3 board)

\- \*\*Language\*\*: Verilog HDL

\- \*\*System Clock\*\*: 100 MHz

\- \*\*Build Tool\*\*: Vivado Design Suite

\- \*\*Display\*\*: RGB565 OLED (96×64 pixels) via SPI



---



\## Hardware Interfaces



\### Input Devices



\#### Switches (sw\[15:0])



| Switch | Function | Values | Description |

|--------|----------|--------|-------------|

| `sw\\\[12]` | \*\*Bubble Sort Active\*\* | ON/OFF | Main enable switch. Must be ON for any functionality. LED\[12] mirrors this state. |

| `sw\\\[0]` | \*\*Tutorial Mode\*\* | ON/OFF | When sw\[12]=ON and sw\[0]=ON, enters tutorial mode. Otherwise demo mode. |

| `sw\\\[1:0]` | \*\*Pattern Selection\*\* (Demo only) | 00/01/10/11 | Selects initial array pattern (see patterns below) |

| `sw\\\[15:13,11:2]` | \*Reserved\* | - | Unused, available for expansion |



\*\*Pattern Selection (sw\[1:0] - Demo Mode Only):\*\*

```

00 = Random:   \\\[5, 2, 4, 1, 3, 0]

01 = Sorted:   \\\[0, 1, 2, 3, 4, 5]

10 = Reverse:  \\\[5, 4, 3, 2, 1, 0]

11 = Custom:   \\\[3, 5, 1, 4, 2, 0]

```



\#### Buttons (Debounced, 10ms threshold)



| Button | Demo Mode Function | Tutorial Mode Function |

|--------|-------------------|------------------------|

| `btnU` (Up) | Start/resume sorting | Increment value (setup) / Confirm swap (sorting) |

| `btnD` (Down) | Pause/resume | Decrement value (setup) / Skip swap (sorting) |

| `btnL` (Left) | Unused | Move cursor left (setup) / Navigate array (sorting) |

| `btnR` (Right) | Unused | Move cursor right (setup) / Navigate array (sorting) |

| `btnC` (Center) | Global reset | Reset / Confirm setup and start |



\*\*Button Debouncing:\*\*

\- Hardware debounce: 999,999 cycles @ 100MHz = 10ms

\- Single-cycle edge pulse generation

\- Independent debounce counters per button



\### Output Devices



\#### OLED Display (96×64 RGB565)



\*\*Physical Interface (PMOD JC):\*\*

```

JC\\\[0] = CS (Chip Select)

JC\\\[1] = SDIN (Serial Data In)

JC\\\[2] = Not connected

JC\\\[3] = SCLK (Serial Clock, 6.25 MHz)

JC\\\[4] = D/CN (Data/Command)

JC\\\[5] = RESN (Reset)

JC\\\[6] = VCCEN (Power Enable)

JC\\\[7] = PMODEN (Power Mode)

```



\*\*Color Scheme (RGB565 format):\*\*

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



\*\*Display Layout - Demo Mode:\*\*

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



\*\*Display Layout - Tutorial Mode:\*\*

```

┌─────────────────────────────┐

│ Progress: \\\[████░░░] 45%     │ Rows 0-6: Progress bar

│ Status: Comparing...        │ Rows 7-15: Status text

│       ✓ or ✗               │ Rows 16-26: Feedback sprite

│   ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐  │ Rows 27-42: Array

│   │3 │ │5 │ │1 │ │4 │ │2 │ │0 │  │

│   └──┘ └──┘ └──┘ └──┘ └──┘ └──┘  │

│ U:Swap D:Skip L/R:Navigate  │ Rows 43-52: Instructions

│ State: TUTORIAL\\\_SELECT      │ Rows 53-63: Debug info

└─────────────────────────────┘

```



\#### 7-Segment Display (4-digit)



\*\*Display Modes:\*\*# EE2026 Bubble Sort Visualizer - Comprehensive Documentation



\## Table of Contents

1\. \[Project Overview](#project-overview)

2\. \[Hardware Interfaces](#hardware-interfaces)

3\. \[Operating Modes](#operating-modes)

4\. \[Module Architecture](#module-architecture)

5\. \[Signal Routing](#signal-routing)

6\. \[Integration Guide](#integration-guide)

7\. \[Build and Deployment](#build-and-deployment)



---



\## Project Overview



\### Purpose

Interactive bubble sort visualization and educational tutorial running on Basys 3 FPGA (Artix-7). Provides both automated demonstration and hands-on learning experience.



\### Key Features

\- \*\*Demo Mode\*\*: Automated bubble sort visualization with step-by-step animation

\- \*\*Tutorial Mode\*\*: Interactive learning with real-time feedback

\- \*\*Visual Feedback\*\*: 96×64 OLED display with color-coded states

\- \*\*Multiple Patterns\*\*: 4 predefined sorting patterns

\- \*\*Hardware Controls\*\*: 5 buttons + 16 switches for full interaction



\### Platform Specifications

\- \*\*FPGA\*\*: Xilinx Artix-7 (Basys 3 board)

\- \*\*Language\*\*: Verilog HDL

\- \*\*System Clock\*\*: 100 MHz

\- \*\*Build Tool\*\*: Vivado Design Suite

\- \*\*Display\*\*: RGB565 OLED (96×64 pixels) via SPI



---



\## Hardware Interfaces



\### Input Devices



\#### Switches (sw\[15:0])



| Switch | Function | Values | Description |

|--------|----------|--------|-------------|

| `sw\\\[12]` | \*\*Bubble Sort Active\*\* | ON/OFF | Main enable switch. Must be ON for any functionality. LED\[12] mirrors this state. |

| `sw\\\[0]` | \*\*Tutorial Mode\*\* | ON/OFF | When sw\[12]=ON and sw\[0]=ON, enters tutorial mode. Otherwise demo mode. |

| `sw\\\[1:0]` | \*\*Pattern Selection\*\* (Demo only) | 00/01/10/11 | Selects initial array pattern (see patterns below) |

| `sw\\\[15:13,11:2]` | \*Reserved\* | - | Unused, available for expansion |



\*\*Pattern Selection (sw\[1:0] - Demo Mode Only):\*\*

```

00 = Random:   \\\[5, 2, 4, 1, 3, 0]

01 = Sorted:   \\\[0, 1, 2, 3, 4, 5]

10 = Reverse:  \\\[5, 4, 3, 2, 1, 0]

11 = Custom:   \\\[3, 5, 1, 4, 2, 0]

```



\#### Buttons (Debounced, 10ms threshold)



| Button | Demo Mode Function | Tutorial Mode Function |

|--------|-------------------|------------------------|

| `btnU` (Up) | Start/resume sorting | Increment value (setup) / Confirm swap (sorting) |

| `btnD` (Down) | Pause/resume | Decrement value (setup) / Skip swap (sorting) |

| `btnL` (Left) | Unused | Move cursor left (setup) / Navigate array (sorting) |

| `btnR` (Right) | Unused | Move cursor right (setup) / Navigate array (sorting) |

| `btnC` (Center) | Global reset | Reset / Confirm setup and start |



\*\*Button Debouncing:\*\*

\- Hardware debounce: 999,999 cycles @ 100MHz = 10ms

\- Single-cycle edge pulse generation

\- Independent debounce counters per button



\### Output Devices



\#### OLED Display (96×64 RGB565)



\*\*Physical Interface (PMOD JC):\*\*

```

JC\\\[0] = CS (Chip Select)

JC\\\[1] = SDIN (Serial Data In)

JC\\\[2] = Not connected

JC\\\[3] = SCLK (Serial Clock, 6.25 MHz)

JC\\\[4] = D/CN (Data/Command)

JC\\\[5] = RESN (Reset)

JC\\\[6] = VCCEN (Power Enable)

JC\\\[7] = PMODEN (Power Mode)

```



\*\*Color Scheme (RGB565 format):\*\*

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



\*\*Display Layout - Demo Mode:\*\*

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



\*\*Display Layout - Tutorial Mode:\*\*

```

┌─────────────────────────────┐

│ Progress: \\\[████░░░] 45%     │ Rows 0-6: Progress bar

│ Status: Comparing...        │ Rows 7-15: Status text

│       ✓ or ✗               │ Rows 16-26: Feedback sprite

│   ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐  │ Rows 27-42: Array

│   │3 │ │5 │ │1 │ │4 │ │2 │ │0 │  │

│   └──┘ └──┘ └──┘ └──┘ └──┘ └──┘  │

│ U:Swap D:Skip L/R:Navigate  │ Rows 43-52: Instructions

│ State: TUTORIAL\\\_SELECT      │ Rows 53-63: Debug info

└─────────────────────────────┘

```



\#### 7-Segment Display (4-digit)



\*\*Display Modes:\*\*

```

"bUbL" - Bubble sort demo mode active

"tutr" - Tutorial mode active

"sort" - Currently sorting

"done" - Sort complete

(blank) - Idle/disabled

```



\*\*Multiplexing:\*\*

\- Refresh rate: ~100 kHz

\- 20-bit counter for digit selection

\- Active-low anode control (an\[3:0])



\#### LED Array (led\[15:0])



```

led\\\[12] = ON when sw\\\[12]=ON (bubble sort enabled)

led\\\[0]  = ON when tutorial mode active

led\\\[15:13,11:1] = Unused, available for expansion

```



---



\## Operating Modes



\### Mode 1: Demo/Auto-Sort Mode



\*\*Activation:\*\*

\- `sw\\\[12] = ON` (bubble sort enabled)

\- `sw\\\[0] = OFF` (tutorial disabled)



\*\*User Flow:\*\*

1\. Set `sw\\\[12] = ON` to enable

2\. Select pattern with `sw\\\[1:0]`

3\. Press `btnU` to start sorting

4\. Algorithm steps through at 1 Hz (one comparison per second)

5\. Press `btnD` to pause/resume

6\. Press `btnC` to reset



\*\*Visual Indicators:\*\*

\- \*\*Yellow boxes\*\*: Currently being compared

\- \*\*Red boxes\*\*: Currently being swapped

\- \*\*Green boxes\*\*: Sort complete

\- \*\*7-segment\*\*: "bUbL" identifier

\- \*\*LED\[12]\*\*: ON



\*\*FSM States:\*\*

```

IDLE → COMPARE → SWAP → SWAP\\\_WAIT → INCREMENT → NEXT\\\_PASS → DONE

\&nbsp;                 ↓                      ↑

\&nbsp;                 └──────────────────────┘ (if no swap needed)

```



\*\*Timing:\*\*

\- Step rate: 1 Hz (controlled by clk\_1hz\_pulse)

\- Animation: Smooth color transitions

\- Frame rate: 60 Hz refresh



---



\### Mode 2: Tutorial/Interactive Mode



\*\*Activation:\*\*

\- `sw\\\[12] = ON` (bubble sort enabled)

\- `sw\\\[0] = ON` (tutorial enabled)



\*\*User Flow:\*\*



\#### Phase 1: Array Setup

```

State: SETUP\\\_INIT → SETUP\\\_EDIT → SETUP\\\_CONFIRM

```



1\. Array initializes to \[0,0,0,0,0,0]

2\. \*\*SETUP\_EDIT\*\* - Create your array:

   - `btnL/R`: Navigate cursor left/right (6 positions)

   - `btnU/D`: Increment/decrement value (0-7, wraps)

   - Cursor highlights current position

3\. Press `btnC` to confirm and start tutorial



\#### Phase 2: Interactive Sorting

```

State: TUTORIAL\\\_SELECT → TUTORIAL\\\_COMPARE → TUTORIAL\\\_AWAIT\\\_SWAP

\&nbsp;      → TUTORIAL\\\_SWAP\\\_ANIM → TUTORIAL\\\_FEEDBACK → (repeat)

```



1\. \*\*TUTORIAL\_SELECT\*\*:

   - Use `btnL/R` to select adjacent pair to compare

   - Yellow highlighting shows selection



2\. \*\*TUTORIAL\_COMPARE\*\*:

   - System shows which elements are being compared



3\. \*\*TUTORIAL\_AWAIT\_SWAP\*\*:

   - \*\*Decision time\*\*: Should you swap?

   - `btnU` = Perform swap

   - `btnD` = Skip (don't swap)



4\. \*\*TUTORIAL\_SWAP\_ANIM\*\*:

   - If swap chosen, animates swap over 16 frames (~267ms)

   - Smooth sliding transition



5\. \*\*TUTORIAL\_FEEDBACK\*\*:

   - \*\*Green checkmark (✓)\*\*: Correct decision

   - \*\*Red X (✗)\*\*: Incorrect decision

   - Progress bar updates

   - Displays for ~1 second



6\. Repeat until array sorted



\#### Phase 3: Completion

```

State: TUTORIAL\\\_CHECK\\\_DONE → TUTORIAL\\\_COMPLETE

```



\- \*\*TUTORIAL\_COMPLETE\*\*: Celebration screen

\- Progress bar at 100%

\- Press `btnC` to restart



\*\*Visual Indicators:\*\*

\- \*\*Progress bar\*\*: Shows completion percentage (0-100%)

\- \*\*Checkmark sprite\*\*: 8×8 green checkmark for correct

\- \*\*X sprite\*\*: 8×8 red X for incorrect

\- \*\*7-segment\*\*: "tutr" identifier

\- \*\*LED\[0]\*\*: ON



\*\*Feedback System:\*\*

\- Real-time comparison with optimal solution

\- Shadow bubble sort tracks correct path

\- Inversion counter validates decisions

\- Percentage calculation based on total inversions



---



\## Module Architecture



\### Module Hierarchy

```

bubble\\\_sort\\\_top (Top-level)

├── clock\\\_divider (Clock generation)

├── button\\\_debounce\\\_5btn (Input debouncing)

├── bubble\\\_sort\\\_fsm (Auto-sort FSM)

├── tutorial\\\_fsm (Tutorial FSM)

├── pixel\\\_generator (Demo graphics) ──┐

├── tutorial\\\_pixel\\\_generator (Tutorial graphics) ──┤ Muxed by mode

└── Oled\\\_Display (OLED controller) ◄────────────────┘

```



---



\### Module Specifications



\#### 1. bubble\_sort\_top.v (Top-Level Integration)



\*\*Purpose:\*\* System integration, mode selection, I/O management



\*\*Input Ports:\*\*

```verilog

input clk,                    // 100 MHz system clock

input \\\[15:0] sw,              // 16 switches

input btnU, btnD, btnL, btnR, btnC,  // 5 buttons

```



\*\*Output Ports:\*\*

```verilog

output \\\[15:0] led,            // 16 LEDs

output \\\[6:0] seg,             // 7-segment segments

output \\\[3:0] an,              // 7-segment anodes

output \\\[7:0] JC               // OLED PMOD connector

```



\*\*Key Functionality:\*\*

\- Mode selection logic (sw\[12] and sw\[0])

\- Button edge pulse routing

\- Clock domain management

\- Pixel data multiplexing

\- 7-segment character encoding

\- Frame tick generation (60 Hz)

\- LED assignment



\*\*7-Segment Character Map:\*\*

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



\#### 2. bubble\_sort\_fsm.v (Auto-Sort Controller)



\*\*Purpose:\*\* Implements bubble sort algorithm for demo mode



\*\*FSM States:\*\*

```verilog

IDLE        // Waiting for start

COMPARE     // Comparing adjacent elements

SWAP        // Initiating swap

SWAP\\\_WAIT   // Swap completion (visual delay)

INCREMENT   // Move to next pair

NEXT\\\_PASS   // Start new pass through array

DONE        // Sort complete

```



\*\*Input Ports:\*\*

```verilog

input clk,                    // System clock

input reset,                  // Global reset

input start,                  // Start signal (btnU)

input step\\\_pulse,             // 1 Hz step timing

input pause,                  // Pause signal (btnD)

input \\\[1:0] pattern\\\_sel,      // Pattern selection (sw\\\[1:0])

```



\*\*Output Ports:\*\*

```verilog

output reg \\\[7:0] array0, array1, array2, array3, array4, array5,

output reg \\\[2:0] compare\\\_idx1, compare\\\_idx2,  // Indices being compared

output reg swap\\\_flag,         // High during swap

output reg sorting,           // High while sorting

output reg done               // High when complete

```



\*\*Algorithm Details:\*\*

\- 6 elements (array0-array5)

\- 8-bit values (0-255)

\- Ascending order (smallest to largest)

\- Pass optimization (reduces range each pass)

\- Early termination (detects no swaps needed)

\- Maximum passes: 5

\- Worst case comparisons: 15



\*\*Pattern Definitions:\*\*

```verilog

2'b00: array = {8'd5, 8'd2, 8'd4, 8'd1, 8'd3, 8'd0};  // Random

2'b01: array = {8'd0, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5};  // Sorted

2'b10: array = {8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0};  // Reverse

2'b11: array = {8'd3, 8'd5, 8'd1, 8'd4, 8'd2, 8'd0};  // Custom

```



---



\#### 3. tutorial\_fsm.v (Interactive Tutorial Controller)



\*\*Purpose:\*\* Manages user-driven bubble sort learning experience



\*\*FSM States (10 total):\*\*

```verilog

SETUP\\\_INIT          // Initialize array to zeros

SETUP\\\_EDIT          // User edits array values

SETUP\\\_CONFIRM       // Finalize array setup

TUTORIAL\\\_SELECT     // User selects pair to compare

TUTORIAL\\\_COMPARE    // Display comparison

TUTORIAL\\\_AWAIT\\\_SWAP // Wait for swap decision

TUTORIAL\\\_SWAP\\\_ANIM  // Animate swap (16 frames)

TUTORIAL\\\_FEEDBACK   // Show correct/incorrect feedback

TUTORIAL\\\_CHECK\\\_DONE // Verify if sorted

TUTORIAL\\\_COMPLETE   // Success celebration

```



\*\*Input Ports:\*\*

```verilog

input clk, reset,

input tutorial\\\_active,        // sw\\\[0] \\\&\\\& sw\\\[12]

input btn\\\_u, btn\\\_d, btn\\\_l, btn\\\_r, btn\\\_c,  // Edge pulses

input frame\\\_tick              // 60 Hz animation timing

```



\*\*Output Ports:\*\*

```verilog

output reg \\\[7:0] array0-5,    // Current array

output reg \\\[2:0] cursor\\\_pos,  // Setup cursor position

output reg \\\[2:0] select\\\_pos,  // Selected comparison position

output reg \\\[4:0] anim\\\_frame,  // Animation frame counter (0-31)

output reg \\\[6:0] progress,    // Completion percentage (0-100)

output reg feedback\\\_correct, feedback\\\_incorrect,

output reg tutorial\\\_done,

output reg \\\[3:0] current\\\_state  // For debugging

```



\*\*Key Features:\*\*



\*\*Setup Phase:\*\*

\- Cursor navigation with btnL/R

\- Value editing with btnU/D (wraps 0-7)

\- Confirmation with btnC



\*\*Sorting Phase:\*\*

\- User selects adjacent pairs

\- Real-time feedback on decisions

\- Shadow bubble sort for validation

\- Inversion counting for progress



\*\*Animation:\*\*

\- 16-frame swap animation (~267ms @ 60Hz)

\- Smooth interpolation

\- Frame counter: 0-31 (wraps)



\*\*Progress Calculation:\*\*

```verilog

progress = 100 - (100 \\\* current\\\_inversions / initial\\\_inversions)

```



\*\*Feedback Logic:\*\*

\- Compares user decision with optimal solution

\- Sets feedback\_correct or feedback\_incorrect

\- Displays for ~1 second



---



\#### 4. button\_debounce\_5btn.v (Input Processing)



\*\*Purpose:\*\* Debounce all buttons and generate edge pulses



\*\*Debounce Specification:\*\*

```verilog

DEBOUNCE\\\_THRESHOLD = 999\\\_999  // 10ms @ 100MHz

```



\*\*Input/Output:\*\*

```verilog

input clk, reset,

input btnU, btnD, btnL, btnR, btnC,  // Raw buttons

output btn\\\_u\\\_edge, btn\\\_d\\\_edge, btn\\\_l\\\_edge, btn\\\_r\\\_edge, btn\\\_c\\\_edge  // Pulses

```



\*\*Algorithm:\*\*

\- Independent 20-bit counter per button

\- Synchronized state tracking

\- Rising edge detection

\- Single-cycle pulse generation



\*\*Logic Flow:\*\*

```

Raw Button → Counter (stabilization) → Sync Register → Edge Detector → Pulse

```



---



\#### 5. clock\_divider.v (Clock Generation)



\*\*Purpose:\*\* Generate multiple clock domains from 100 MHz system clock



\*\*Input/Output:\*\*

```verilog

input clk,                    // 100 MHz

output reg clk\\\_6p25mhz,      // OLED SPI clock (÷16)

output reg clk\\\_1hz\\\_pulse     // Sorting step pulse (÷100M)

```



\*\*Clock Specifications:\*\*

\- \*\*clk\_6p25mhz\*\*: 6.25 MHz continuous clock for OLED

  - Division: 100MHz ÷ 16 = 6.25MHz

  - Counter range: 0-7



\- \*\*clk\_1hz\_pulse\*\*: 1 Hz single-cycle pulse for sorting steps

  - Division: 100MHz ÷ 100M = 1Hz

  - Counter range: 0-49,999,999

  - Pulse width: 1 cycle (10ns)



---



\#### 6. pixel\_generator.v (Demo Mode Graphics)



\*\*Purpose:\*\* Render bubble sort visualization for auto-sort mode



\*\*Input Ports:\*\*

```verilog

input \\\[12:0] pixel\\\_index,     // Current pixel (0-6143)

input \\\[7:0] array0-5,         // Array values

input \\\[2:0] compare\\\_idx1, compare\\\_idx2,  // Highlighting

input swap\\\_flag, done         // State indicators

```



\*\*Output Ports:\*\*

```verilog

output reg \\\[15:0] oled\\\_data   // RGB565 pixel color

```



\*\*Rendering Logic:\*\*

\- Combinational logic for all 6,144 pixels

\- Pixel coordinate calculation (x = pixel\_index % 96, y = pixel\_index / 96)

\- Box boundary detection (14×10 pixels + 2px spacing)

\- Font rendering (6×8 digit glyphs)

\- Background pattern (blue dots every 8 pixels)



\*\*Box Layout:\*\*

```

Box 0: x=0-13,   y=27-36

Box 1: x=16-29,  y=27-36

Box 2: x=32-45,  y=27-36

Box 3: x=48-61,  y=27-36

Box 4: x=64-77,  y=27-36

Box 5: x=80-93,  y=27-36

```



\*\*Color Priority:\*\*

```

1\\. If done → Green

2\\. If swap\\\_flag and (box == idx1 or idx2) → Red

3\\. If comparing and (box == idx1 or idx2) → Yellow

4\\. Else → White

```



\*\*Font System:\*\*

\- 6×8 pixel glyphs for digits 0-9

\- Stored as 48-bit bitmaps

\- Vertical flip for rendering

\- Centered within box



---



\#### 7. tutorial\_pixel\_generator.v (Tutorial Mode Graphics)



\*\*Purpose:\*\* Render interactive tutorial interface



\*\*Input Ports:\*\*

```verilog

input \\\[12:0] pixel\\\_index,

input \\\[7:0] array0-5,

input \\\[2:0] cursor\\\_pos, select\\\_pos,

input \\\[4:0] anim\\\_frame,

input \\\[6:0] progress,

input feedback\\\_correct, feedback\\\_incorrect,

input \\\[3:0] current\\\_state

```



\*\*Output Ports:\*\*

```verilog

output reg \\\[15:0] oled\\\_data

```



\*\*Display Regions (96×64 pixels):\*\*



| Rows | Region | Content |

|------|--------|---------|

| 0-6 | Progress Bar | Blue outline, green fill based on progress% |

| 7-15 | Status Text | State-dependent messages |

| 16-26 | Feedback | 8×8 checkmark or X sprite |

| 27-42 | Array Boxes | 6 boxes with values, cursor highlighting |

| 43-52 | Instructions | Button hints based on state |

| 53-63 | Debug Info | Current FSM state |



\*\*Character ROM:\*\*

\- 5×7 font for digits (0-9) and letters (A-Z)

\- Total: 36 characters

\- Stored as 35-bit bitmaps



\*\*Sprite System:\*\*

```verilog

// Checkmark (8×8 pixels)

\\\[0,0,0,0,0,0,1,1]

\\\[0,0,0,0,0,1,1,0]

\\\[1,0,0,0,1,1,0,0]

\\\[1,1,0,1,1,0,0,0]

\\\[0,1,1,1,0,0,0,0]

\\\[0,0,1,0,0,0,0,0]

\\\[0,0,0,0,0,0,0,0]

\\\[0,0,0,0,0,0,0,0]



// X mark (8×8 pixels)

\\\[1,1,0,0,0,0,1,1]

\\\[0,1,1,0,0,1,1,0]

\\\[0,0,1,1,1,1,0,0]

\\\[0,0,0,1,1,0,0,0]

\\\[0,0,1,1,1,1,0,0]

\\\[0,1,1,0,0,1,1,0]

\\\[1,1,0,0,0,0,1,1]

\\\[0,0,0,0,0,0,0,0]

```



\*\*Progress Bar Rendering:\*\*

```verilog

fill\\\_width = (progress \\\* 86) / 100;  // Max 86 pixels

if (x < fill\\\_width) color = GREEN;

else color = GRAY;

```



\*\*Animation:\*\*

\- Frame interpolation for swap animation

\- Smooth transitions using anim\_frame counter



---



\#### 8. Oled\_Display.v (OLED Controller - DO NOT MODIFY)



\*\*Purpose:\*\* SPI interface controller for RGB OLED display



\*\*Parameters:\*\*

```verilog

ClkFreq = 6\\\_250\\\_000          // 6.25 MHz SPI clock

FrameFreq = 60               // 60 Hz refresh rate

```



\*\*Input Ports:\*\*

```verilog

input clk,                   // 6.25 MHz

input reset,

input \\\[15:0] pixel\\\_data      // RGB565 from pixel generator

```



\*\*Output Ports:\*\*

```verilog

output \\\[12:0] pixel\\\_index,   // Current pixel (0-6143)

output CS, SDIN, SCLK, DC, RES, VCCEN, PMODEN  // SPI signals

```



\*\*Functionality:\*\*

\- \*\*Initialization\*\*: Power-up sequence, command configuration

\- \*\*SPI Communication\*\*: Serial data transmission @ 6.25 MHz

\- \*\*Frame Buffer\*\*: Streams 6,144 pixels (96×64) per frame

\- \*\*Refresh\*\*: 60 Hz continuous refresh

\- \*\*Power Management\*\*: Controls VccEn and Pmoden



\*\*DO NOT MODIFY\*\* - This is a provided controller. Only connect pixel\_data input.



---



\#### 9. Basys3\_Master.xdc (Pin Constraints)



\*\*Purpose:\*\* Map Verilog signals to physical FPGA pins



\*\*Critical Constraints:\*\*



\*\*Clock:\*\*

```tcl

set\\\_property PACKAGE\\\_PIN W5 \\\[get\\\_ports clk]

set\\\_property IOSTANDARD LVCMOS33 \\\[get\\\_ports clk]

create\\\_clock -period 10.000 \\\[get\\\_ports clk]  # 100 MHz

```



\*\*Switches:\*\*

```tcl

sw\\\[0]:  V17   sw\\\[1]:  V16   sw\\\[12]: W2   sw\\\[13]: U1

sw\\\[14]: T1    sw\\\[15]: R2

```



\*\*Buttons:\*\*

```tcl

btnC: U18   btnU: T18   btnL: W19   btnR: T17   btnD: U17

```



\*\*LEDs:\*\*

```tcl

led\\\[0]:  U16  led\\\[1]:  E19  ... led\\\[12]: V11  ... led\\\[15]: L1

```



\*\*7-Segment:\*\*

```tcl

seg\\\[0-6]: W7, W6, U8, V8, U5, V5, U7

an\\\[0-3]:  U2, U4, V4, W4

```



\*\*OLED (PMOD JC):\*\*

```tcl

JC\\\[0]: K17   JC\\\[1]: M18   JC\\\[2]: P18   JC\\\[3]: L17

JC\\\[4]: M19   JC\\\[5]: P17   JC\\\[6]: R18

```



---



\## Signal Routing



\### Complete Data Flow Diagram



```

┌──────────────────────────────────────────────────────────────────────┐

│                         CLOCK DOMAIN                                 │

│  100 MHz ──→ clock\\\_divider ──→ 6.25 MHz (OLED)                      │

│                            └──→ 1 Hz pulse (sorting steps)           │

│                            └──→ 60 Hz frame\\\_tick (animation)         │

└──────────────────────────────────────────────────────────────────────┘

\&nbsp;                                   ↓

┌──────────────────────────────────────────────────────────────────────┐

│                         INPUT LAYER                                  │

│  Buttons ──→ button\\\_debounce\\\_5btn ──→ Edge Pulses                   │

│  Switches ──→ Direct routing                                         │

└──────────────────────────────────────────────────────────────────────┘

\&nbsp;                                   ↓

┌──────────────────────────────────────────────────────────────────────┐

│                      CONTROL LAYER (FSMs)                            │

│                                                                       │

│  sw\\\[12]=ON, sw\\\[0]=OFF:                                               │

│    bubble\\\_sort\\\_fsm ──→ array0-5, compare\\\_idx1/2, swap\\\_flag, done    │

│                                                                       │

│  sw\\\[12]=ON, sw\\\[0]=ON:                                                │

│    tutorial\\\_fsm ──→ array0-5, cursor\\\_pos, anim\\\_frame, progress,     │

│                     feedback signals                                 │

└──────────────────────────────────────────────────────────────────────┘

\&nbsp;                                   ↓

┌──────────────────────────────────────────────────────────────────────┐

│                      RENDERING LAYER                                 │

│                                                                       │

│  Mode Mux selects:                                                   │

│    pixel\\\_generator (demo) ──┐                                        │

│    tutorial\\\_pixel\\\_generator ┘──→ pixel\\\_data\\\[15:0]                   │

│                                                                       │

│  Input: pixel\\\_index from OLED controller                             │

│  Output: RGB565 color for current pixel                              │

└──────────────────────────────────────────────────────────────────────┘

\&nbsp;                                   ↓

┌──────────────────────────────────────────────────────────────────────┐

│                      OUTPUT LAYER                                    │

│                                                                       │

│  Oled\\\_Display ──→ JC\\\[7:0] (SPI) ──→ Physical OLED                   │

│  7-seg encoder ──→ seg\\\[6:0], an\\\[3:0]                                │

│  LED assignment ──→ led\\\[15:0]                                        │

└──────────────────────────────────────────────────────────────────────┘

```



\### Critical Timing Paths



\*\*Path 1: Button to FSM\*\*

```

Button (raw) → Debouncer (10ms) → Edge Pulse → FSM (1 cycle) → State Update

Total latency: ~10ms + 2 clock cycles

```



\*\*Path 2: FSM to Display\*\*

```

FSM State → Array Update → Pixel Generator (combinational) → OLED Controller

Total latency: 1 clock cycle + SPI transmission time

```



\*\*Path 3: Clock Division\*\*

```

100 MHz → ÷16 counter → 6.25 MHz OLED clock

100 MHz → ÷100M counter → 1 Hz pulse

```



---



\## Integration Guide



\### Integrating with Another Project



\#### Step 1: Understand Interface Requirements



\*\*Inputs your project provides:\*\*

\- System clock (must be 100 MHz or modify clock\_divider.v)

\- Reset signal (active high)

\- Control signals (can replace switch/button logic)



\*\*Outputs you can use:\*\*

\- Array data (6×8-bit values)

\- Sort status (sorting, done, compare\_idx, swap\_flag)

\- Tutorial state information



\*\*Peripherals you must support:\*\*

\- OLED display with SPI interface

\- OR: Replace pixel generators with your own display driver



\#### Step 2: Module Instantiation Template



```verilog

bubble\\\_sort\\\_top your\\\_instance\\\_name (

\&nbsp;   // Clock and reset

\&nbsp;   .clk(your\\\_100mhz\\\_clock),



\&nbsp;   // Control inputs

\&nbsp;   .sw({

\&nbsp;       your\\\_switches\\\[15:13],    // Unused

\&nbsp;       your\\\_bubble\\\_enable,      // sw\\\[12]

\&nbsp;       your\\\_switches\\\[11:2],     // Unused

\&nbsp;       your\\\_pattern\\\_select,     // sw\\\[1:0]

\&nbsp;       your\\\_tutorial\\\_enable     // sw\\\[0]

\&nbsp;   }),



\&nbsp;   // Button inputs (provide edge pulses or raw buttons)

\&nbsp;   .btnU(your\\\_start\\\_button),

\&nbsp;   .btnD(your\\\_pause\\\_button),

\&nbsp;   .btnL(your\\\_left\\\_button),

\&nbsp;   .btnR(your\\\_right\\\_button),

\&nbsp;   .btnC(your\\\_reset\\\_button),



\&nbsp;   // LED outputs

\&nbsp;   .led(your\\\_led\\\_array),



\&nbsp;   // 7-segment outputs

\&nbsp;   .seg(your\\\_segments),

\&nbsp;   .an(your\\\_anodes),



\&nbsp;   // OLED output

\&nbsp;   .JC(your\\\_pmod\\\_connector)

);

```



\#### Step 3: Modify for Custom Control



\*\*Example: Replace switches with state machine control\*\*



In `bubble\\\_sort\\\_top.v`, change:

```verilog

// Original

wire bubble\\\_sort\\\_active = sw\\\[12];

wire tutorial\\\_mode = sw\\\[0];



// Modified for external control

input wire bubble\\\_sort\\\_active,

input wire tutorial\\\_mode,

// Remove: input \\\[15:0] sw,

```



\*\*Example: Use different clock frequency\*\*



Modify `clock\\\_divider.v`:

```verilog

// Original: 100 MHz → 6.25 MHz

parameter DIV\\\_OLED = 16;



// For 50 MHz input → 6.25 MHz

parameter DIV\\\_OLED = 8;



// For 1 Hz pulse from different frequency:

parameter DIV\\\_1HZ = your\\\_frequency\\\_in\\\_hz;

```



\#### Step 4: Interface with Custom Display



\*\*Option A: Use OLED as-is\*\*

\- Connect your PMOD JC pins

\- Ensure 6.25 MHz SPI clock available

\- Provide pixel data from generators



\*\*Option B: Replace pixel generators\*\*

\- Keep FSMs for logic

\- Route array0-5 and state signals to your display driver

\- Remove/bypass OLED controller



\*\*Example: Extract array data only\*\*

```verilog

wire \\\[7:0] sorted\\\_array \\\[0:5];

assign sorted\\\_array\\\[0] = bubble\\\_sort\\\_active ?

\&nbsp;   (tutorial\\\_mode ? tutorial\\\_array0 : fsm\\\_array0) : 8'b0;

// ... repeat for array\\\[1-5]



// Use sorted\\\_array in your display logic

```



\#### Step 5: Combine with Your FSM



\*\*Example: Use as sub-module in larger state machine\*\*



```verilog

module combined\\\_project (

\&nbsp;   input clk,

\&nbsp;   input reset,

\&nbsp;   // ... your inputs

\&nbsp;   output \\\[7:0] JC,

\&nbsp;   // ... your outputs

);



// Your main FSM

reg bubble\\\_enable, tutorial\\\_enable;

wire \\\[7:0] bubble\\\_array0, bubble\\\_array1;  // ... etc

wire bubble\\\_done;



always @(posedge clk) begin

\&nbsp;   case (main\\\_state)

\&nbsp;       INIT: begin

\&nbsp;           bubble\\\_enable <= 0;

\&nbsp;       end



\&nbsp;       BUBBLE\\\_SORT\\\_PHASE: begin

\&nbsp;           bubble\\\_enable <= 1;

\&nbsp;           tutorial\\\_enable <= 0;

\&nbsp;           if (bubble\\\_done) main\\\_state <= NEXT\\\_PHASE;

\&nbsp;       end



\&nbsp;       TUTORIAL\\\_PHASE: begin

\&nbsp;           bubble\\\_enable <= 1;

\&nbsp;           tutorial\\\_enable <= 1;

\&nbsp;       end

\&nbsp;   endcase

end



// Instantiate bubble sort

bubble\\\_sort\\\_top bubble\\\_inst (

\&nbsp;   .clk(clk),

\&nbsp;   .sw({4'b0, bubble\\\_enable, 7'b0, 2'b00, tutorial\\\_enable}),

\&nbsp;   // ... other connections

);



// Your additional logic

// ...



endmodule

```



---



\### Configuration Parameters



\#### Modifiable Constants



\*\*In bubble\_sort\_top.v:\*\*

```verilog

// Line 82: Frame tick divider (change animation speed)

parameter FRAME\\\_DIV = 1\\\_666\\\_667;  // 60 Hz @ 100MHz

// Modify to: FRAME\\\_DIV = 5\\\_000\\\_000; for 20 Hz (slower animation)

```



\*\*In bubble\_sort\_fsm.v:\*\*

```verilog

// Lines 52-59: Pattern definitions

// Add more patterns:

2'b00: begin /\\\* pattern 0 \\\*/ end

2'b01: begin /\\\* pattern 1 \\\*/ end

2'b10: begin /\\\* pattern 2 \\\*/ end

2'b11: begin /\\\* pattern 3 \\\*/ end

// To add 8 patterns, change pattern\\\_sel to \\\[2:0] (3 bits)

```



\*\*In pixel\_generator.v:\*\*

```verilog

// Lines 36-42: Color definitions

localparam BLACK   = 16'h0000;

localparam WHITE   = 16'hFFFF;

// Change to your preferred colors:

localparam WHITE   = 16'h8410;  // Gray instead of white

```



\*\*In tutorial\_fsm.v:\*\*

```verilog

// Line 125: Feedback display duration

if (feedback\\\_timer < 60) ...  // 1 second @ 60Hz

// Change to: if (feedback\\\_timer < 120) ... for 2-second feedback

```



\*\*In clock\_divider.v:\*\*

```verilog

// Adapt to different input clock:

parameter CLK\\\_FREQ = 100\\\_000\\\_000;

parameter TARGET\\\_OLED = 6\\\_250\\\_000;

parameter DIV\\\_OLED = CLK\\\_FREQ / TARGET\\\_OLED / 2;  // Auto-calculate

```



---



\### Communication Protocol



If integrating via inter-module communication:



\*\*Output Signals to Monitor:\*\*

```verilog

output wire sorting,           // High while sort in progress

output wire done,              // High when complete

output wire \\\[2:0] compare\\\_idx1, compare\\\_idx2,  // Current comparison

output wire swap\\\_flag,         // High during swap

output wire \\\[7:0] array0-5,   // Current array state

```



\*\*Input Control Signals:\*\*

```verilog

input wire start,              // Pulse to start sorting

input wire pause,              // Pause/resume toggle

input wire reset,              // Return to initial state

input wire \\\[1:0] pattern\\\_sel, // Pattern selection

```



\*\*Tutorial-Specific Outputs:\*\*

```verilog

output wire \\\[6:0] progress,           // 0-100 completion

output wire feedback\\\_correct,         // Correct decision

output wire feedback\\\_incorrect,       // Incorrect decision

output wire tutorial\\\_done,            // Tutorial complete

output wire \\\[3:0] current\\\_state,      // For debugging

```



---



\### Timing Constraints for Integration



\*\*Minimum Clock Requirements:\*\*

\- System clock: 100 MHz (or modify dividers proportionally)

\- OLED clock: 6.25 MHz ± 10%

\- Button debounce: ≥10ms stability



\*\*Maximum Propagation Delays:\*\*

\- Button to FSM response: <1 frame (16.67ms @ 60Hz)

\- FSM state to display update: <1 clock cycle

\- Pixel generation: Combinational (no delay)



\*\*Setup/Hold Times:\*\*

\- All signals synchronous to system clock

\- No asynchronous inputs except reset

\- Button edges already synchronized by debouncer



---



\## Build and Deployment



\### Vivado Project Setup



\*\*Project File:\*\* `2026\\\_project.xpr`



\*\*To Open:\*\*

```bash

cd /home/user/ee2026-project

vivado 2026\\\_project.xpr

```



\*\*Source Files (add to project):\*\*

```

2026\\\_project.srcs/sources\\\_1/new/

├── bubble\\\_sort\\\_top.v           (Top-level - set as top module)

├── bubble\\\_sort\\\_fsm.v

├── tutorial\\\_fsm.v

├── button\\\_debounce\\\_5btn.v

├── clock\\\_divider.v

├── pixel\\\_generator.v

├── tutorial\\\_pixel\\\_generator.v

└── Oled\\\_Display.v



2026\\\_project.srcs/constrs\\\_1/new/

└── Basys3\\\_Master.xdc           (Constraints)

```



\### Build Process



\*\*Step 1: Synthesis\*\*

```

Tools → Run Synthesis

Or: Flow → Run Synthesis

Wait for completion (~2-5 minutes)

```



\*\*Step 2: Implementation\*\*

```

Tools → Run Implementation

Or: Flow → Run Implementation

Includes: Opt Design, Place Design, Route Design

Wait for completion (~3-7 minutes)

```



\*\*Step 3: Generate Bitstream\*\*

```

Tools → Generate Bitstream

Output: bubble\\\_sort\\\_top.bit

Wait for completion (~1-2 minutes)

```



\*\*Step 4: Program FPGA\*\*

```

Open Hardware Manager

Auto-connect to Basys 3

Program device with .bit file

```



\### Build Verification



\*\*Check Reports:\*\*

1\. \*\*Utilization Report\*\*: Ensure <80% resource usage

2\. \*\*Timing Report\*\*: Verify all constraints met (WNS ≥ 0)

3\. \*\*DRC Report\*\*: No critical warnings



\*\*Expected Resource Usage:\*\*

```

LUTs: ~15-25% (moderate)

FFs: ~10-20% (low-moderate)

BRAM: ~5-10% (minimal)

DSPs: 0% (none used)

```



\### Deployment Checklist



\- \[ ] All source files added to project

\- \[ ] bubble\_sort\_top.v set as top module

\- \[ ] Basys3\_Master.xdc constraints file loaded

\- \[ ] Synthesis completed without errors

\- \[ ] Implementation completed without errors

\- \[ ] Timing constraints met (check timing report)

\- \[ ] Bitstream generated successfully

\- \[ ] Basys 3 connected via USB

\- \[ ] OLED PMOD connected to JC port

\- \[ ] Device programmed successfully

\- \[ ] Switches and buttons respond correctly

\- \[ ] OLED display shows graphics

\- \[ ] 7-segment displays correct characters



---



\## Troubleshooting



\### Common Issues



\*\*Issue: OLED display blank\*\*

\- Check PMOD JC connections

\- Verify 6.25 MHz clock generation

\- Check sw\[12] is ON

\- Reset with btnC



\*\*Issue: No response to buttons\*\*

\- Verify debounce threshold (999,999 cycles)

\- Check button edge pulse generation

\- Confirm FSM state transitions

\- Use ILA (Integrated Logic Analyzer) to debug



\*\*Issue: Timing constraints not met\*\*

\- Reduce clock frequency

\- Simplify combinational logic in pixel generators

\- Add pipeline stages

\- Check critical path in timing report



\*\*Issue: Tutorial mode not activating\*\*

\- Ensure BOTH sw\[12]=ON and sw\[0]=ON

\- Check tutorial\_active signal routing

\- Verify mode mux logic in top module



\*\*Issue: Incorrect sorting behavior\*\*

\- Verify pattern selection (sw\[1:0])

\- Check FSM state transitions

\- Confirm step\_pulse generation (1 Hz)

\- Use simulation to verify algorithm



---



\## Appendix: Quick Reference



\### Switch Quick Reference

```

sw\\\[12] = Main enable (must be ON)

sw\\\[0]  = Tutorial mode (ON=tutorial, OFF=demo)

sw\\\[1:0] = Pattern (demo mode only)

\&nbsp; 00 = Random

\&nbsp; 01 = Sorted

\&nbsp; 10 = Reverse

\&nbsp; 11 = Custom

```



\### Button Quick Reference (Demo Mode)

```

btnU = Start/Resume

btnD = Pause

btnC = Reset

btnL = Unused

btnR = Unused

```



\### Button Quick Reference (Tutorial Mode)

```

Setup Phase:

\&nbsp; btnL/R = Navigate cursor

\&nbsp; btnU/D = Change value

\&nbsp; btnC = Confirm and start



Sorting Phase:

\&nbsp; btnL/R = Select pair

\&nbsp; btnU = Swap

\&nbsp; btnD = Skip

\&nbsp; btnC = Reset

```



\### Color Code Reference

```

Demo Mode:

\&nbsp; White = Default

\&nbsp; Yellow = Comparing

\&nbsp; Red = Swapping

\&nbsp; Green = Done



Tutorial Mode:

\&nbsp; Green checkmark = Correct

\&nbsp; Red X = Incorrect

\&nbsp; Yellow = Selected

\&nbsp; Green progress bar = Completion

```



\### File Modification Priority

```

HIGH (likely to modify):

\&nbsp; - bubble\\\_sort\\\_top.v (integration logic)

\&nbsp; - bubble\\\_sort\\\_fsm.v (patterns, algorithm)

\&nbsp; - tutorial\\\_fsm.v (feedback timing)



MEDIUM (may modify for customization):

\&nbsp; - pixel\\\_generator.v (colors, layout)

\&nbsp; - tutorial\\\_pixel\\\_generator.v (UI design)

\&nbsp; - clock\\\_divider.v (clock frequencies)

\&nbsp; - Basys3\\\_Master.xdc (pin mapping)



LOW (rarely modify):

\&nbsp; - button\\\_debounce\\\_5btn.v (standard debounce)



NEVER:

\&nbsp; - Oled\\\_Display.v (provided controller)

```



---



\## Document Revision History



| Version | Date | Changes |

|---------|------|---------|

| 1.0 | 2025-11-06 | Initial comprehensive documentation |



---



\*\*End of Documentation\*\*



For questions or integration support, refer to source code comments and module-level documentation within each .v file.

```

"bUbL" - Bubble sort demo mode active

"tutr" - Tutorial mode active

"sort" - Currently sorting

"done" - Sort complete

(blank) - Idle/disabled

```



\*\*Multiplexing:\*\*

\- Refresh rate: ~100 kHz

\- 20-bit counter for digit selection

\- Active-low anode control (an\[3:0])



\#### LED Array (led\[15:0])



```

led\\\[12] = ON when sw\\\[12]=ON (bubble sort enabled)

led\\\[0]  = ON when tutorial mode active

led\\\[15:13,11:1] = Unused, available for expansion

```



---



\## Operating Modes



\### Mode 1: Demo/Auto-Sort Mode



\*\*Activation:\*\*

\- `sw\\\[12] = ON` (bubble sort enabled)

\- `sw\\\[0] = OFF` (tutorial disabled)



\*\*User Flow:\*\*

1\. Set `sw\\\[12] = ON` to enable

2\. Select pattern with `sw\\\[1:0]`

3\. Press `btnU` to start sorting

4\. Algorithm steps through at 1 Hz (one comparison per second)

5\. Press `btnD` to pause/resume

6\. Press `btnC` to reset



\*\*Visual Indicators:\*\*

\- \*\*Yellow boxes\*\*: Currently being compared

\- \*\*Red boxes\*\*: Currently being swapped

\- \*\*Green boxes\*\*: Sort complete

\- \*\*7-segment\*\*: "bUbL" identifier

\- \*\*LED\[12]\*\*: ON



\*\*FSM States:\*\*

```

IDLE → COMPARE → SWAP → SWAP\\\_WAIT → INCREMENT → NEXT\\\_PASS → DONE

\&nbsp;                 ↓                      ↑

\&nbsp;                 └──────────────────────┘ (if no swap needed)

```



\*\*Timing:\*\*

\- Step rate: 1 Hz (controlled by clk\_1hz\_pulse)

\- Animation: Smooth color transitions

\- Frame rate: 60 Hz refresh



---



\### Mode 2: Tutorial/Interactive Mode



\*\*Activation:\*\*

\- `sw\\\[12] = ON` (bubble sort enabled)

\- `sw\\\[0] = ON` (tutorial enabled)



\*\*User Flow:\*\*



\#### Phase 1: Array Setup

```

State: SETUP\\\_INIT → SETUP\\\_EDIT → SETUP\\\_CONFIRM

```



1\. Array initializes to \[0,0,0,0,0,0]

2\. \*\*SETUP\_EDIT\*\* - Create your array:

   - `btnL/R`: Navigate cursor left/right (6 positions)

   - `btnU/D`: Increment/decrement value (0-7, wraps)

   - Cursor highlights current position

3\. Press `btnC` to confirm and start tutorial



\#### Phase 2: Interactive Sorting

```

State: TUTORIAL\\\_SELECT → TUTORIAL\\\_COMPARE → TUTORIAL\\\_AWAIT\\\_SWAP

\&nbsp;      → TUTORIAL\\\_SWAP\\\_ANIM → TUTORIAL\\\_FEEDBACK → (repeat)

```



1\. \*\*TUTORIAL\_SELECT\*\*:

   - Use `btnL/R` to select adjacent pair to compare

   - Yellow highlighting shows selection



2\. \*\*TUTORIAL\_COMPARE\*\*:

   - System shows which elements are being compared



3\. \*\*TUTORIAL\_AWAIT\_SWAP\*\*:

   - \*\*Decision time\*\*: Should you swap?

   - `btnU` = Perform swap

   - `btnD` = Skip (don't swap)



4\. \*\*TUTORIAL\_SWAP\_ANIM\*\*:

   - If swap chosen, animates swap over 16 frames (~267ms)

   - Smooth sliding transition



5\. \*\*TUTORIAL\_FEEDBACK\*\*:

   - \*\*Green checkmark (✓)\*\*: Correct decision

   - \*\*Red X (✗)\*\*: Incorrect decision

   - Progress bar updates

   - Displays for ~1 second



6\. Repeat until array sorted



\#### Phase 3: Completion

```

State: TUTORIAL\\\_CHECK\\\_DONE → TUTORIAL\\\_COMPLETE

```



\- \*\*TUTORIAL\_COMPLETE\*\*: Celebration screen

\- Progress bar at 100%

\- Press `btnC` to restart



\*\*Visual Indicators:\*\*

\- \*\*Progress bar\*\*: Shows completion percentage (0-100%)

\- \*\*Checkmark sprite\*\*: 8×8 green checkmark for correct

\- \*\*X sprite\*\*: 8×8 red X for incorrect

\- \*\*7-segment\*\*: "tutr" identifier

\- \*\*LED\[0]\*\*: ON



\*\*Feedback System:\*\*

\- Real-time comparison with optimal solution

\- Shadow bubble sort tracks correct path

\- Inversion counter validates decisions

\- Percentage calculation based on total inversions



---



\## Module Architecture



\### Module Hierarchy

```

bubble\\\_sort\\\_top (Top-level)

├── clock\\\_divider (Clock generation)

├── button\\\_debounce\\\_5btn (Input debouncing)

├── bubble\\\_sort\\\_fsm (Auto-sort FSM)

├── tutorial\\\_fsm (Tutorial FSM)

├── pixel\\\_generator (Demo graphics) ──┐

├── tutorial\\\_pixel\\\_generator (Tutorial graphics) ──┤ Muxed by mode

└── Oled\\\_Display (OLED controller) ◄────────────────┘

```



---



\### Module Specifications



\#### 1. bubble\_sort\_top.v (Top-Level Integration)



\*\*Purpose:\*\* System integration, mode selection, I/O management



\*\*Input Ports:\*\*

```verilog

input clk,                    // 100 MHz system clock

input \\\[15:0] sw,              // 16 switches

input btnU, btnD, btnL, btnR, btnC,  // 5 buttons

```



\*\*Output Ports:\*\*

```verilog

output \\\[15:0] led,            // 16 LEDs

output \\\[6:0] seg,             // 7-segment segments

output \\\[3:0] an,              // 7-segment anodes

output \\\[7:0] JC               // OLED PMOD connector

```



\*\*Key Functionality:\*\*

\- Mode selection logic (sw\[12] and sw\[0])

\- Button edge pulse routing

\- Clock domain management

\- Pixel data multiplexing

\- 7-segment character encoding

\- Frame tick generation (60 Hz)

\- LED assignment



\*\*7-Segment Character Map:\*\*

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



\#### 2. bubble\_sort\_fsm.v (Auto-Sort Controller)



\*\*Purpose:\*\* Implements bubble sort algorithm for demo mode



\*\*FSM States:\*\*

```verilog

IDLE        // Waiting for start

COMPARE     // Comparing adjacent elements

SWAP        // Initiating swap

SWAP\\\_WAIT   // Swap completion (visual delay)

INCREMENT   // Move to next pair

NEXT\\\_PASS   // Start new pass through array

DONE        // Sort complete

```



\*\*Input Ports:\*\*

```verilog

input clk,                    // System clock

input reset,                  // Global reset

input start,                  // Start signal (btnU)

input step\\\_pulse,             // 1 Hz step timing

input pause,                  // Pause signal (btnD)

input \\\[1:0] pattern\\\_sel,      // Pattern selection (sw\\\[1:0])

```



\*\*Output Ports:\*\*

```verilog

output reg \\\[7:0] array0, array1, array2, array3, array4, array5,

output reg \\\[2:0] compare\\\_idx1, compare\\\_idx2,  // Indices being compared

output reg swap\\\_flag,         // High during swap

output reg sorting,           // High while sorting

output reg done               // High when complete

```



\*\*Algorithm Details:\*\*

\- 6 elements (array0-array5)

\- 8-bit values (0-255)

\- Ascending order (smallest to largest)

\- Pass optimization (reduces range each pass)

\- Early termination (detects no swaps needed)

\- Maximum passes: 5

\- Worst case comparisons: 15



\*\*Pattern Definitions:\*\*

```verilog

2'b00: array = {8'd5, 8'd2, 8'd4, 8'd1, 8'd3, 8'd0};  // Random

2'b01: array = {8'd0, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5};  // Sorted

2'b10: array = {8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0};  // Reverse

2'b11: array = {8'd3, 8'd5, 8'd1, 8'd4, 8'd2, 8'd0};  // Custom

```



---



\#### 3. tutorial\_fsm.v (Interactive Tutorial Controller)



\*\*Purpose:\*\* Manages user-driven bubble sort learning experience



\*\*FSM States (10 total):\*\*

```verilog

SETUP\\\_INIT          // Initialize array to zeros

SETUP\\\_EDIT          // User edits array values

SETUP\\\_CONFIRM       // Finalize array setup

TUTORIAL\\\_SELECT     // User selects pair to compare

TUTORIAL\\\_COMPARE    // Display comparison

TUTORIAL\\\_AWAIT\\\_SWAP // Wait for swap decision

TUTORIAL\\\_SWAP\\\_ANIM  // Animate swap (16 frames)

TUTORIAL\\\_FEEDBACK   // Show correct/incorrect feedback

TUTORIAL\\\_CHECK\\\_DONE // Verify if sorted

TUTORIAL\\\_COMPLETE   // Success celebration

```



\*\*Input Ports:\*\*

```verilog

input clk, reset,

input tutorial\\\_active,        // sw\\\[0] \\\&\\\& sw\\\[12]

input btn\\\_u, btn\\\_d, btn\\\_l, btn\\\_r, btn\\\_c,  // Edge pulses

input frame\\\_tick              // 60 Hz animation timing

```



\*\*Output Ports:\*\*

```verilog

output reg \\\[7:0] array0-5,    // Current array

output reg \\\[2:0] cursor\\\_pos,  // Setup cursor position

output reg \\\[2:0] select\\\_pos,  // Selected comparison position

output reg \\\[4:0] anim\\\_frame,  // Animation frame counter (0-31)

output reg \\\[6:0] progress,    // Completion percentage (0-100)

output reg feedback\\\_correct, feedback\\\_incorrect,

output reg tutorial\\\_done,

output reg \\\[3:0] current\\\_state  // For debugging

```



\*\*Key Features:\*\*



\*\*Setup Phase:\*\*

\- Cursor navigation with btnL/R

\- Value editing with btnU/D (wraps 0-7)

\- Confirmation with btnC



\*\*Sorting Phase:\*\*

\- User selects adjacent pairs

\- Real-time feedback on decisions

\- Shadow bubble sort for validation

\- Inversion counting for progress



\*\*Animation:\*\*

\- 16-frame swap animation (~267ms @ 60Hz)

\- Smooth interpolation

\- Frame counter: 0-31 (wraps)



\*\*Progress Calculation:\*\*

```verilog

progress = 100 - (100 \\\* current\\\_inversions / initial\\\_inversions)

```



\*\*Feedback Logic:\*\*

\- Compares user decision with optimal solution

\- Sets feedback\_correct or feedback\_incorrect

\- Displays for ~1 second



---



\#### 4. button\_debounce\_5btn.v (Input Processing)



\*\*Purpose:\*\* Debounce all buttons and generate edge pulses



\*\*Debounce Specification:\*\*

```verilog

DEBOUNCE\\\_THRESHOLD = 999\\\_999  // 10ms @ 100MHz

```



\*\*Input/Output:\*\*

```verilog

input clk, reset,

input btnU, btnD, btnL, btnR, btnC,  // Raw buttons

output btn\\\_u\\\_edge, btn\\\_d\\\_edge, btn\\\_l\\\_edge, btn\\\_r\\\_edge, btn\\\_c\\\_edge  // Pulses

```



\*\*Algorithm:\*\*

\- Independent 20-bit counter per button

\- Synchronized state tracking

\- Rising edge detection

\- Single-cycle pulse generation



\*\*Logic Flow:\*\*

```

Raw Button → Counter (stabilization) → Sync Register → Edge Detector → Pulse

```



---



\#### 5. clock\_divider.v (Clock Generation)



\*\*Purpose:\*\* Generate multiple clock domains from 100 MHz system clock



\*\*Input/Output:\*\*

```verilog

input clk,                    // 100 MHz

output reg clk\\\_6p25mhz,      // OLED SPI clock (÷16)

output reg clk\\\_1hz\\\_pulse     // Sorting step pulse (÷100M)

```



\*\*Clock Specifications:\*\*

\- \*\*clk\_6p25mhz\*\*: 6.25 MHz continuous clock for OLED

  - Division: 100MHz ÷ 16 = 6.25MHz

  - Counter range: 0-7



\- \*\*clk\_1hz\_pulse\*\*: 1 Hz single-cycle pulse for sorting steps

  - Division: 100MHz ÷ 100M = 1Hz

  - Counter range: 0-49,999,999

  - Pulse width: 1 cycle (10ns)



---



\#### 6. pixel\_generator.v (Demo Mode Graphics)



\*\*Purpose:\*\* Render bubble sort visualization for auto-sort mode



\*\*Input Ports:\*\*

```verilog

input \\\[12:0] pixel\\\_index,     // Current pixel (0-6143)

input \\\[7:0] array0-5,         // Array values

input \\\[2:0] compare\\\_idx1, compare\\\_idx2,  // Highlighting

input swap\\\_flag, done         // State indicators

```



\*\*Output Ports:\*\*

```verilog

output reg \\\[15:0] oled\\\_data   // RGB565 pixel color

```



\*\*Rendering Logic:\*\*

\- Combinational logic for all 6,144 pixels

\- Pixel coordinate calculation (x = pixel\_index % 96, y = pixel\_index / 96)

\- Box boundary detection (14×10 pixels + 2px spacing)

\- Font rendering (6×8 digit glyphs)

\- Background pattern (blue dots every 8 pixels)



\*\*Box Layout:\*\*

```

Box 0: x=0-13,   y=27-36

Box 1: x=16-29,  y=27-36

Box 2: x=32-45,  y=27-36

Box 3: x=48-61,  y=27-36

Box 4: x=64-77,  y=27-36

Box 5: x=80-93,  y=27-36

```



\*\*Color Priority:\*\*

```

1\\. If done → Green

2\\. If swap\\\_flag and (box == idx1 or idx2) → Red

3\\. If comparing and (box == idx1 or idx2) → Yellow

4\\. Else → White

```



\*\*Font System:\*\*

\- 6×8 pixel glyphs for digits 0-9

\- Stored as 48-bit bitmaps

\- Vertical flip for rendering

\- Centered within box



---



\#### 7. tutorial\_pixel\_generator.v (Tutorial Mode Graphics)



\*\*Purpose:\*\* Render interactive tutorial interface



\*\*Input Ports:\*\*

```verilog

input \\\[12:0] pixel\\\_index,

input \\\[7:0] array0-5,

input \\\[2:0] cursor\\\_pos, select\\\_pos,

input \\\[4:0] anim\\\_frame,

input \\\[6:0] progress,

input feedback\\\_correct, feedback\\\_incorrect,

input \\\[3:0] current\\\_state

```



\*\*Output Ports:\*\*

```verilog

output reg \\\[15:0] oled\\\_data

```



\*\*Display Regions (96×64 pixels):\*\*



| Rows | Region | Content |

|------|--------|---------|

| 0-6 | Progress Bar | Blue outline, green fill based on progress% |

| 7-15 | Status Text | State-dependent messages |

| 16-26 | Feedback | 8×8 checkmark or X sprite |

| 27-42 | Array Boxes | 6 boxes with values, cursor highlighting |

| 43-52 | Instructions | Button hints based on state |

| 53-63 | Debug Info | Current FSM state |



\*\*Character ROM:\*\*

\- 5×7 font for digits (0-9) and letters (A-Z)

\- Total: 36 characters

\- Stored as 35-bit bitmaps



\*\*Sprite System:\*\*

```verilog

// Checkmark (8×8 pixels)

\\\[0,0,0,0,0,0,1,1]

\\\[0,0,0,0,0,1,1,0]

\\\[1,0,0,0,1,1,0,0]

\\\[1,1,0,1,1,0,0,0]

\\\[0,1,1,1,0,0,0,0]

\\\[0,0,1,0,0,0,0,0]

\\\[0,0,0,0,0,0,0,0]

\\\[0,0,0,0,0,0,0,0]



// X mark (8×8 pixels)

\\\[1,1,0,0,0,0,1,1]

\\\[0,1,1,0,0,1,1,0]

\\\[0,0,1,1,1,1,0,0]

\\\[0,0,0,1,1,0,0,0]

\\\[0,0,1,1,1,1,0,0]

\\\[0,1,1,0,0,1,1,0]

\\\[1,1,0,0,0,0,1,1]

\\\[0,0,0,0,0,0,0,0]

```



\*\*Progress Bar Rendering:\*\*

```verilog

fill\\\_width = (progress \\\* 86) / 100;  // Max 86 pixels

if (x < fill\\\_width) color = GREEN;

else color = GRAY;

```



\*\*Animation:\*\*

\- Frame interpolation for swap animation

\- Smooth transitions using anim\_frame counter



---



\#### 8. Oled\_Display.v (OLED Controller - DO NOT MODIFY)



\*\*Purpose:\*\* SPI interface controller for RGB OLED display



\*\*Parameters:\*\*

```verilog

ClkFreq = 6\\\_250\\\_000          // 6.25 MHz SPI clock

FrameFreq = 60               // 60 Hz refresh rate

```



\*\*Input Ports:\*\*

```verilog

input clk,                   // 6.25 MHz

input reset,

input \\\[15:0] pixel\\\_data      // RGB565 from pixel generator

```



\*\*Output Ports:\*\*

```verilog

output \\\[12:0] pixel\\\_index,   // Current pixel (0-6143)

output CS, SDIN, SCLK, DC, RES, VCCEN, PMODEN  // SPI signals

```



\*\*Functionality:\*\*

\- \*\*Initialization\*\*: Power-up sequence, command configuration

\- \*\*SPI Communication\*\*: Serial data transmission @ 6.25 MHz

\- \*\*Frame Buffer\*\*: Streams 6,144 pixels (96×64) per frame

\- \*\*Refresh\*\*: 60 Hz continuous refresh

\- \*\*Power Management\*\*: Controls VccEn and Pmoden



\*\*DO NOT MODIFY\*\* - This is a provided controller. Only connect pixel\_data input.



---



\#### 9. Basys3\_Master.xdc (Pin Constraints)



\*\*Purpose:\*\* Map Verilog signals to physical FPGA pins



\*\*Critical Constraints:\*\*



\*\*Clock:\*\*

```tcl

set\\\_property PACKAGE\\\_PIN W5 \\\[get\\\_ports clk]

set\\\_property IOSTANDARD LVCMOS33 \\\[get\\\_ports clk]

create\\\_clock -period 10.000 \\\[get\\\_ports clk]  # 100 MHz

```



\*\*Switches:\*\*

```tcl

sw\\\[0]:  V17   sw\\\[1]:  V16   sw\\\[12]: W2   sw\\\[13]: U1

sw\\\[14]: T1    sw\\\[15]: R2

```



\*\*Buttons:\*\*

```tcl

btnC: U18   btnU: T18   btnL: W19   btnR: T17   btnD: U17

```



\*\*LEDs:\*\*

```tcl

led\\\[0]:  U16  led\\\[1]:  E19  ... led\\\[12]: V11  ... led\\\[15]: L1

```



\*\*7-Segment:\*\*

```tcl

seg\\\[0-6]: W7, W6, U8, V8, U5, V5, U7

an\\\[0-3]:  U2, U4, V4, W4

```



\*\*OLED (PMOD JC):\*\*

```tcl

JC\\\[0]: K17   JC\\\[1]: M18   JC\\\[2]: P18   JC\\\[3]: L17

JC\\\[4]: M19   JC\\\[5]: P17   JC\\\[6]: R18

```



---



\## Signal Routing



\### Complete Data Flow Diagram



```

┌──────────────────────────────────────────────────────────────────────┐

│                         CLOCK DOMAIN                                 │

│  100 MHz ──→ clock\\\_divider ──→ 6.25 MHz (OLED)                      │

│                            └──→ 1 Hz pulse (sorting steps)           │

│                            └──→ 60 Hz frame\\\_tick (animation)         │

└──────────────────────────────────────────────────────────────────────┘

\&nbsp;                                   ↓

┌──────────────────────────────────────────────────────────────────────┐

│                         INPUT LAYER                                  │

│  Buttons ──→ button\\\_debounce\\\_5btn ──→ Edge Pulses                   │

│  Switches ──→ Direct routing                                         │

└──────────────────────────────────────────────────────────────────────┘

\&nbsp;                                   ↓

┌──────────────────────────────────────────────────────────────────────┐

│                      CONTROL LAYER (FSMs)                            │

│                                                                       │

│  sw\\\[12]=ON, sw\\\[0]=OFF:                                               │

│    bubble\\\_sort\\\_fsm ──→ array0-5, compare\\\_idx1/2, swap\\\_flag, done    │

│                                                                       │

│  sw\\\[12]=ON, sw\\\[0]=ON:                                                │

│    tutorial\\\_fsm ──→ array0-5, cursor\\\_pos, anim\\\_frame, progress,     │

│                     feedback signals                                 │

└──────────────────────────────────────────────────────────────────────┘

\&nbsp;                                   ↓

┌──────────────────────────────────────────────────────────────────────┐

│                      RENDERING LAYER                                 │

│                                                                       │

│  Mode Mux selects:                                                   │

│    pixel\\\_generator (demo) ──┐                                        │

│    tutorial\\\_pixel\\\_generator ┘──→ pixel\\\_data\\\[15:0]                   │

│                                                                       │

│  Input: pixel\\\_index from OLED controller                             │

│  Output: RGB565 color for current pixel                              │

└──────────────────────────────────────────────────────────────────────┘

\&nbsp;                                   ↓

┌──────────────────────────────────────────────────────────────────────┐

│                      OUTPUT LAYER                                    │

│                                                                       │

│  Oled\\\_Display ──→ JC\\\[7:0] (SPI) ──→ Physical OLED                   │

│  7-seg encoder ──→ seg\\\[6:0], an\\\[3:0]                                │

│  LED assignment ──→ led\\\[15:0]                                        │

└──────────────────────────────────────────────────────────────────────┘

```



\### Critical Timing Paths



\*\*Path 1: Button to FSM\*\*

```

Button (raw) → Debouncer (10ms) → Edge Pulse → FSM (1 cycle) → State Update

Total latency: ~10ms + 2 clock cycles

```



\*\*Path 2: FSM to Display\*\*

```

FSM State → Array Update → Pixel Generator (combinational) → OLED Controller

Total latency: 1 clock cycle + SPI transmission time

```



\*\*Path 3: Clock Division\*\*

```

100 MHz → ÷16 counter → 6.25 MHz OLED clock

100 MHz → ÷100M counter → 1 Hz pulse

```



---



\## Integration Guide



\### Integrating with Another Project



\#### Step 1: Understand Interface Requirements



\*\*Inputs your project provides:\*\*

\- System clock (must be 100 MHz or modify clock\_divider.v)

\- Reset signal (active high)

\- Control signals (can replace switch/button logic)



\*\*Outputs you can use:\*\*

\- Array data (6×8-bit values)

\- Sort status (sorting, done, compare\_idx, swap\_flag)

\- Tutorial state information



\*\*Peripherals you must support:\*\*

\- OLED display with SPI interface

\- OR: Replace pixel generators with your own display driver



\#### Step 2: Module Instantiation Template



```verilog

bubble\\\_sort\\\_top your\\\_instance\\\_name (

\&nbsp;   // Clock and reset

\&nbsp;   .clk(your\\\_100mhz\\\_clock),



\&nbsp;   // Control inputs

\&nbsp;   .sw({

\&nbsp;       your\\\_switches\\\[15:13],    // Unused

\&nbsp;       your\\\_bubble\\\_enable,      // sw\\\[12]

\&nbsp;       your\\\_switches\\\[11:2],     // Unused

\&nbsp;       your\\\_pattern\\\_select,     // sw\\\[1:0]

\&nbsp;       your\\\_tutorial\\\_enable     // sw\\\[0]

\&nbsp;   }),



\&nbsp;   // Button inputs (provide edge pulses or raw buttons)

\&nbsp;   .btnU(your\\\_start\\\_button),

\&nbsp;   .btnD(your\\\_pause\\\_button),

\&nbsp;   .btnL(your\\\_left\\\_button),

\&nbsp;   .btnR(your\\\_right\\\_button),

\&nbsp;   .btnC(your\\\_reset\\\_button),



\&nbsp;   // LED outputs

\&nbsp;   .led(your\\\_led\\\_array),



\&nbsp;   // 7-segment outputs

\&nbsp;   .seg(your\\\_segments),

\&nbsp;   .an(your\\\_anodes),



\&nbsp;   // OLED output

\&nbsp;   .JC(your\\\_pmod\\\_connector)

);

```



\#### Step 3: Modify for Custom Control



\*\*Example: Replace switches with state machine control\*\*



In `bubble\\\_sort\\\_top.v`, change:

```verilog

// Original

wire bubble\\\_sort\\\_active = sw\\\[12];

wire tutorial\\\_mode = sw\\\[0];



// Modified for external control

input wire bubble\\\_sort\\\_active,

input wire tutorial\\\_mode,

// Remove: input \\\[15:0] sw,

```



\*\*Example: Use different clock frequency\*\*



Modify `clock\\\_divider.v`:

```verilog

// Original: 100 MHz → 6.25 MHz

parameter DIV\\\_OLED = 16;



// For 50 MHz input → 6.25 MHz

parameter DIV\\\_OLED = 8;



// For 1 Hz pulse from different frequency:

parameter DIV\\\_1HZ = your\\\_frequency\\\_in\\\_hz;

```



\#### Step 4: Interface with Custom Display



\*\*Option A: Use OLED as-is\*\*

\- Connect your PMOD JC pins

\- Ensure 6.25 MHz SPI clock available

\- Provide pixel data from generators



\*\*Option B: Replace pixel generators\*\*

\- Keep FSMs for logic

\- Route array0-5 and state signals to your display driver

\- Remove/bypass OLED controller



\*\*Example: Extract array data only\*\*

```verilog

wire \\\[7:0] sorted\\\_array \\\[0:5];

assign sorted\\\_array\\\[0] = bubble\\\_sort\\\_active ?

\&nbsp;   (tutorial\\\_mode ? tutorial\\\_array0 : fsm\\\_array0) : 8'b0;

// ... repeat for array\\\[1-5]



// Use sorted\\\_array in your display logic

```



\#### Step 5: Combine with Your FSM



\*\*Example: Use as sub-module in larger state machine\*\*



```verilog

module combined\\\_project (

\&nbsp;   input clk,

\&nbsp;   input reset,

\&nbsp;   // ... your inputs

\&nbsp;   output \\\[7:0] JC,

\&nbsp;   // ... your outputs

);



// Your main FSM

reg bubble\\\_enable, tutorial\\\_enable;

wire \\\[7:0] bubble\\\_array0, bubble\\\_array1;  // ... etc

wire bubble\\\_done;



always @(posedge clk) begin

\&nbsp;   case (main\\\_state)

\&nbsp;       INIT: begin

\&nbsp;           bubble\\\_enable <= 0;

\&nbsp;       end



\&nbsp;       BUBBLE\\\_SORT\\\_PHASE: begin

\&nbsp;           bubble\\\_enable <= 1;

\&nbsp;           tutorial\\\_enable <= 0;

\&nbsp;           if (bubble\\\_done) main\\\_state <= NEXT\\\_PHASE;

\&nbsp;       end



\&nbsp;       TUTORIAL\\\_PHASE: begin

\&nbsp;           bubble\\\_enable <= 1;

\&nbsp;           tutorial\\\_enable <= 1;

\&nbsp;       end

\&nbsp;   endcase

end



// Instantiate bubble sort

bubble\\\_sort\\\_top bubble\\\_inst (

\&nbsp;   .clk(clk),

\&nbsp;   .sw({4'b0, bubble\\\_enable, 7'b0, 2'b00, tutorial\\\_enable}),

\&nbsp;   // ... other connections

);



// Your additional logic

// ...



endmodule

```



---



\### Configuration Parameters



\#### Modifiable Constants



\*\*In bubble\_sort\_top.v:\*\*

```verilog

// Line 82: Frame tick divider (change animation speed)

parameter FRAME\\\_DIV = 1\\\_666\\\_667;  // 60 Hz @ 100MHz

// Modify to: FRAME\\\_DIV = 5\\\_000\\\_000; for 20 Hz (slower animation)

```



\*\*In bubble\_sort\_fsm.v:\*\*

```verilog

// Lines 52-59: Pattern definitions

// Add more patterns:

2'b00: begin /\\\* pattern 0 \\\*/ end

2'b01: begin /\\\* pattern 1 \\\*/ end

2'b10: begin /\\\* pattern 2 \\\*/ end

2'b11: begin /\\\* pattern 3 \\\*/ end

// To add 8 patterns, change pattern\\\_sel to \\\[2:0] (3 bits)

```



\*\*In pixel\_generator.v:\*\*

```verilog

// Lines 36-42: Color definitions

localparam BLACK   = 16'h0000;

localparam WHITE   = 16'hFFFF;

// Change to your preferred colors:

localparam WHITE   = 16'h8410;  // Gray instead of white

```



\*\*In tutorial\_fsm.v:\*\*

```verilog

// Line 125: Feedback display duration

if (feedback\\\_timer < 60) ...  // 1 second @ 60Hz

// Change to: if (feedback\\\_timer < 120) ... for 2-second feedback

```



\*\*In clock\_divider.v:\*\*

```verilog

// Adapt to different input clock:

parameter CLK\\\_FREQ = 100\\\_000\\\_000;

parameter TARGET\\\_OLED = 6\\\_250\\\_000;

parameter DIV\\\_OLED = CLK\\\_FREQ / TARGET\\\_OLED / 2;  // Auto-calculate

```



---



\### Communication Protocol



If integrating via inter-module communication:



\*\*Output Signals to Monitor:\*\*

```verilog

output wire sorting,           // High while sort in progress

output wire done,              // High when complete

output wire \\\[2:0] compare\\\_idx1, compare\\\_idx2,  // Current comparison

output wire swap\\\_flag,         // High during swap

output wire \\\[7:0] array0-5,   // Current array state

```



\*\*Input Control Signals:\*\*

```verilog

input wire start,              // Pulse to start sorting

input wire pause,              // Pause/resume toggle

input wire reset,              // Return to initial state

input wire \\\[1:0] pattern\\\_sel, // Pattern selection

```



\*\*Tutorial-Specific Outputs:\*\*

```verilog

output wire \\\[6:0] progress,           // 0-100 completion

output wire feedback\\\_correct,         // Correct decision

output wire feedback\\\_incorrect,       // Incorrect decision

output wire tutorial\\\_done,            // Tutorial complete

output wire \\\[3:0] current\\\_state,      // For debugging

```



---



\### Timing Constraints for Integration



\*\*Minimum Clock Requirements:\*\*

\- System clock: 100 MHz (or modify dividers proportionally)

\- OLED clock: 6.25 MHz ± 10%

\- Button debounce: ≥10ms stability



\*\*Maximum Propagation Delays:\*\*

\- Button to FSM response: <1 frame (16.67ms @ 60Hz)

\- FSM state to display update: <1 clock cycle

\- Pixel generation: Combinational (no delay)



\*\*Setup/Hold Times:\*\*

\- All signals synchronous to system clock

\- No asynchronous inputs except reset

\- Button edges already synchronized by debouncer



---



\## Build and Deployment



\### Vivado Project Setup



\*\*Project File:\*\* `2026\\\_project.xpr`



\*\*To Open:\*\*

```bash

cd /home/user/ee2026-project

vivado 2026\\\_project.xpr

```



\*\*Source Files (add to project):\*\*

```

2026\\\_project.srcs/sources\\\_1/new/

├── bubble\\\_sort\\\_top.v           (Top-level - set as top module)

├── bubble\\\_sort\\\_fsm.v

├── tutorial\\\_fsm.v

├── button\\\_debounce\\\_5btn.v

├── clock\\\_divider.v

├── pixel\\\_generator.v

├── tutorial\\\_pixel\\\_generator.v

└── Oled\\\_Display.v



2026\\\_project.srcs/constrs\\\_1/new/

└── Basys3\\\_Master.xdc           (Constraints)

```



\### Build Process



\*\*Step 1: Synthesis\*\*

```

Tools → Run Synthesis

Or: Flow → Run Synthesis

Wait for completion (~2-5 minutes)

```



\*\*Step 2: Implementation\*\*

```

Tools → Run Implementation

Or: Flow → Run Implementation

Includes: Opt Design, Place Design, Route Design

Wait for completion (~3-7 minutes)

```



\*\*Step 3: Generate Bitstream\*\*

```

Tools → Generate Bitstream

Output: bubble\\\_sort\\\_top.bit

Wait for completion (~1-2 minutes)

```



\*\*Step 4: Program FPGA\*\*

```

Open Hardware Manager

Auto-connect to Basys 3

Program device with .bit file

```



\### Build Verification



\*\*Check Reports:\*\*

1\. \*\*Utilization Report\*\*: Ensure <80% resource usage

2\. \*\*Timing Report\*\*: Verify all constraints met (WNS ≥ 0)

3\. \*\*DRC Report\*\*: No critical warnings



\*\*Expected Resource Usage:\*\*

```

LUTs: ~15-25% (moderate)

FFs: ~10-20% (low-moderate)

BRAM: ~5-10% (minimal)

DSPs: 0% (none used)

```



\### Deployment Checklist



\- \[ ] All source files added to project

\- \[ ] bubble\_sort\_top.v set as top module

\- \[ ] Basys3\_Master.xdc constraints file loaded

\- \[ ] Synthesis completed without errors

\- \[ ] Implementation completed without errors

\- \[ ] Timing constraints met (check timing report)

\- \[ ] Bitstream generated successfully

\- \[ ] Basys 3 connected via USB

\- \[ ] OLED PMOD connected to JC port

\- \[ ] Device programmed successfully

\- \[ ] Switches and buttons respond correctly

\- \[ ] OLED display shows graphics

\- \[ ] 7-segment displays correct characters



---



\## Troubleshooting



\### Common Issues



\*\*Issue: OLED display blank\*\*

\- Check PMOD JC connections

\- Verify 6.25 MHz clock generation

\- Check sw\[12] is ON

\- Reset with btnC



\*\*Issue: No response to buttons\*\*

\- Verify debounce threshold (999,999 cycles)

\- Check button edge pulse generation

\- Confirm FSM state transitions

\- Use ILA (Integrated Logic Analyzer) to debug



\*\*Issue: Timing constraints not met\*\*

\- Reduce clock frequency

\- Simplify combinational logic in pixel generators

\- Add pipeline stages

\- Check critical path in timing report



\*\*Issue: Tutorial mode not activating\*\*

\- Ensure BOTH sw\[12]=ON and sw\[0]=ON

\- Check tutorial\_active signal routing

\- Verify mode mux logic in top module



\*\*Issue: Incorrect sorting behavior\*\*

\- Verify pattern selection (sw\[1:0])

\- Check FSM state transitions

\- Confirm step\_pulse generation (1 Hz)

\- Use simulation to verify algorithm



---



\## Appendix: Quick Reference



\### Switch Quick Reference

```

sw\\\[12] = Main enable (must be ON)

sw\\\[0]  = Tutorial mode (ON=tutorial, OFF=demo)

sw\\\[1:0] = Pattern (demo mode only)

\&nbsp; 00 = Random

\&nbsp; 01 = Sorted

\&nbsp; 10 = Reverse

\&nbsp; 11 = Custom

```



\### Button Quick Reference (Demo Mode)

```

btnU = Start/Resume

btnD = Pause

btnC = Reset

btnL = Unused

btnR = Unused

```



\### Button Quick Reference (Tutorial Mode)

```

Setup Phase:

\&nbsp; btnL/R = Navigate cursor

\&nbsp; btnU/D = Change value

\&nbsp; btnC = Confirm and start



Sorting Phase:

\&nbsp; btnL/R = Select pair

\&nbsp; btnU = Swap

\&nbsp; btnD = Skip

\&nbsp; btnC = Reset

```



\### Color Code Reference

```

Demo Mode:

\&nbsp; White = Default

\&nbsp; Yellow = Comparing

\&nbsp; Red = Swapping

\&nbsp; Green = Done



Tutorial Mode:

\&nbsp; Green checkmark = Correct

\&nbsp; Red X = Incorrect

\&nbsp; Yellow = Selected

\&nbsp; Green progress bar = Completion

```



\### File Modification Priority

```

HIGH (likely to modify):

\&nbsp; - bubble\\\_sort\\\_top.v (integration logic)

\&nbsp; - bubble\\\_sort\\\_fsm.v (patterns, algorithm)

\&nbsp; - tutorial\\\_fsm.v (feedback timing)



MEDIUM (may modify for customization):

\&nbsp; - pixel\\\_generator.v (colors, layout)

\&nbsp; - tutorial\\\_pixel\\\_generator.v (UI design)

\&nbsp; - clock\\\_divider.v (clock frequencies)

\&nbsp; - Basys3\\\_Master.xdc (pin mapping)



LOW (rarely modify):

\&nbsp; - button\\\_debounce\\\_5btn.v (standard debounce)



NEVER:

\&nbsp; - Oled\\\_Display.v (provided controller)

```



---



\## Document Revision History



| Version | Date | Changes |

|---------|------|---------|

| 1.0 | 2025-11-06 | Initial comprehensive documentation |



---



\*\*End of Documentation\*\*



For questions or integration support, refer to source code comments and module-level documentation within each .v file.

-------------------------------------------Afshals Project----------------------------------------------------------------

# CLAUDE.md - EE2026 FDP Merge Sort Visualization Project



\## Project Context

\- \*\*Course\*\*: EE2026 Digital Design, AY 2025-2026 Semester 1

\- \*\*Student\*\*: Afshal Gulam (A0307936W)

\- \*\*Team\*\*: Group with Pranav (Bubble), Abhijit (Selection), Praveen (Insertion), Afshal (Merge)

\- \*\*Project\*\*: Interactive FPGA Design Project (I-FDP) - Sorting Visualizer

\- \*\*Current Phase\*\*: Educational Mode ✅ Complete + Tutorial Mode ✅ Complete (Week 10+)



\## My Component: Merge Sort Visualization Engine



\### Objective

Implement merge sort algorithm with two modes:



\*\*EDUCATIONAL MODE\*\* ✅ \*\*COMPLETE\*\* (SW15=ON, SW10=OFF):

\- Automatic visualization of merge sort for fixed array \[4,2,6,1,5,3]

\- Visual "divide" phase (numbers move down in 3 steps)

\- Visual "merge" phase (numbers move up while sorting in 3 steps)

\- Professional animation with color coding and smooth timing (~2.6s per step)

\- Numbers displayed in 14×10 pixel filled colored boxes with 1px borders

\- Pause/resume capability with btnD

\- Clean, minimal UI for clear visualization



\*\*TUTORIAL MODE\*\* ✅ \*\*COMPLETE\*\* (SW15=ON, SW10=ON) ⭐:

\- \*\*Phase 1 - TUTORIAL\_EDIT\*\*: Interactive array building

&nbsp; - User creates custom array with cursor-based editing

&nbsp; - btnL/R: Navigate cursor (wrap 0↔5)

&nbsp; - btnU/D: Increment/decrement values (0-7 with wrap)

&nbsp; - Cursor shown with thick 3px CYAN border

&nbsp; - btnC: Confirm array and proceed to divide



\- \*\*Phase 2 - TUTORIAL\_DIVIDE\*\*: Automatic divide animation

&nbsp; - Same visual divide as Educational Mode

&nbsp; - Works with any user-created array

&nbsp; - 3-step decomposition with color coding



\- \*\*Phase 3 - TUTORIAL\_PRACTICE\*\*: Interactive merge learning with progressive hints

&nbsp; - 2-row display system:

&nbsp;   - Bottom row: Current work array state

&nbsp;   - Top row: User's answer boxes for expected merge result

&nbsp; - User actions:

&nbsp;   - btnL/R: Cursor navigation (wrap 0↔5)

&nbsp;   - btnU/D: Edit answer values (0-7 with wrap)

&nbsp;   - SW0-4: Place separator lines between merged segments

&nbsp;   - btnC: Check answer

&nbsp; - Validation \& Feedback:

&nbsp;   - Correct: Green flash (0.67s) → Auto-animate merge → Next step

&nbsp;   - Incorrect: Red flash → Allow unlimited retries

&nbsp; - \*\*Progressive Hints System\*\* (NEW):

&nbsp;   - Ghost separators: Faint white separator hints for 1s at step start

&nbsp;   - Pulsing borders: Super thin 1px yellow borders on active merge regions

&nbsp;   - Smart activation: Pulsing only appears after first wrong attempt

&nbsp;   - Helps struggling users without overwhelming beginners

&nbsp; - Step-by-step progression: Pairs → Groups → Final merge

&nbsp; - CDC Request/Acknowledge handshake for reliable button handling

&nbsp; - 200ms hardware debounce for all buttons



\### Technical Specifications - Tutorial Mode Implementation

\- \*\*Display\*\*: 96×64 pixels, RGB565 16-bit color format

\- \*\*Array Size\*\*: 6 elements (values 0-7)

&nbsp; - Educational: Fixed \[4,2,6,1,5,3] → \[1,2,3,4,5,6]

&nbsp; - Tutorial: User-created array

\- \*\*Box Dimensions\*\*: 14×10 pixels, fully filled with color

\- \*\*Box Borders\*\*: Variable thickness - 1px (normal), 3px (cursor selected), 1px yellow (pulsing hint)

\- \*\*Number Fonts\*\*: 6×8 pixel fonts for digits 0-7

\- \*\*Animation\*\*: Smooth X and Y movement using 45Hz clock (~2.6s per step)

\- \*\*2-Row Display\*\*: Bottom (work array) + Top (answer boxes) in Tutorial Practice

\- \*\*Dynamic Positioning\*\*: Answer row Y-position follows work row during animations

\- \*\*Separators\*\*: 5 dynamic white separator lines (2px wide) at X: 15-16, 31-32, 47-48, 63-64, 79-80

\- \*\*Box Colors\*\*: \[Magenta, Red, Orange, Cyan, Green, Blue] for positions 0-5

\- \*\*Feedback Colors\*\*: Red (wrong), Green (correct), reserved for validation feedback only

\- \*\*Hint System\*\*:

&nbsp; - Ghost separators: Faint white (RGB565: 0x4208) for 1 second

&nbsp; - Pulsing borders: 1px yellow borders, only after ≥1 wrong attempt

&nbsp; - Progressive activation: No hints initially, activate after user struggles

\- \*\*Control Modes\*\*:

&nbsp; - Educational: SW15=ON, SW10=OFF (btnU=Start, btnD=Pause, btnC=Reset)

&nbsp; - Tutorial: SW15=ON, SW10=ON (btnL/R=Cursor, btnU/D=Inc/Dec, btnC=Confirm/Check, SW0-4=Separators)

\- \*\*CDC Protocol\*\*: Request/Acknowledge handshake (100MHz ↔ 45Hz)

\- \*\*Debounce\*\*: 200ms hardware debounce per button (20,000,000 cycles at 100MHz)

\- \*\*UI\*\*: Clean display with minimal interface elements



\### Architecture Design (TUTORIAL MODE IMPLEMENTATION)

```

Top\_Student.v (Main Integration with Tutorial Support)

├── Clock Generation (6.25MHz OLED, 45Hz movement)

├── Control Interface (button debouncing, mode selection)

│   ├── educational\_mode = sw\[15] \&\& !sw\[10]

│   └── tutorial\_mode = sw\[15] \&\& sw\[10]

├── OLED Display Interface (connects to Oled\_Display.v)

├── LED status display (mode, state, positions)

├── Seven-segment display ("MERG")

└── Enhanced signal connections (12 signals to/from controller)



merge\_sort\_controller.v (7-State FSM + Tutorial System + CDC)

├── \*\*7-State Machine\*\*: IDLE, INIT, DIVIDE, MERGE, SORTED,

│                       TUTORIAL\_INIT, TUTORIAL\_EDIT, TUTORIAL\_DIVIDE

├── Tutorial System:

│   ├── cursor\_pos\[2:0] - Current cursor position (0-5)

│   ├── work\_array\[0:5] - Main array values (0-7)

│   ├── user\_answer\_array\[0:5] - User's answer for merge step

│   ├── tutorial\_practice\_mode flag - Enable 2-row display

│   ├── check\_tutorial\_answer() task - Step-specific validation

│   └── \*\*Progressive Hints\*\* (NEW):

│       ├── wrong\_attempt\_count\[2:0] - Counts wrong attempts per step

│       ├── pulse\_timer/pulse\_state - 0.5s toggle for pulsing effect

│       ├── merge\_region\_active\[5:0] - Which boxes pulse (only if wrong\_attempt\_count ≥ 1)

│       ├── hint\_timer\[5:0] - 1s countdown for ghost separators

│       └── hint\_separators\[4:0] - Separator position hints

├── CDC Request/Acknowledge Handshake:

│   ├── 5 channels: cursor\_left, cursor\_right, value\_up, value\_down, check\_answer

│   ├── Request flags (clk domain) + Acknowledge flags (clk\_movement domain)

│   ├── 2-stage synchronizers for safe clock crossing

│   └── Full 4-phase handshake protocol

├── Debounce System:

│   ├── 5 independent 20-bit timers (200ms at 100MHz)

│   ├── Per-button countdown timers

│   └── Prevents double-triggering

├── Position tracking: X and Y positions for all elements

├── 3-step divide + 3-step merge with color coding

├── Animation control (~2.6s per step)

├── Enhanced flattened bus outputs:

│   ├── array\_data\_flat \[17:0], answer\_data\_flat \[17:0]

│   ├── array\_positions\_x\_flat \[41:0], array\_positions\_y\_flat \[35:0]

│   ├── array\_colors\_flat \[17:0], answer\_colors\_flat \[17:0]

│   ├── separator\_visible \[4:0]

│   ├── cursor\_pos\_out \[2:0], practice\_mode\_active

│   └── current\_state \[2:0], sorting\_active, sort\_complete



merge\_sort\_display.v (Enhanced OLED Rendering with 2-Row Support + Progressive Hints)

├── 6 bottom-row box renderers (work array)

├── 6 top-row answer box renderers (answer array)

├── \*\*Progressive Hints Rendering\*\* (NEW):

│   ├── 1px yellow pulsing borders on answer boxes (super thin)

│   ├── Ghost separators: Faint white (0x4208) separator hints

│   └── Conditional rendering based on wrong\_attempt\_count

├── Dynamic answer box Y-positioning:

│   └── Calculates Y based on work array's current position

├── Priority encoding: pulsing borders > answer boxes > work boxes > separators > hints > background

├── Separator line rendering (5 positions, 2px wide)

├── Background patterns

├── Coordinate mapping (pixel\_index to x,y)

└── Clean UI without status indicators



merge\_sort\_numbers.v (Enhanced Number Fonts \& Box Rendering with Cursor)

├── 6×8 pixel number fonts (0-7) in ROM

├── number\_box\_renderer module:

│   ├── \*\*NEW\*\*: is\_cursor input parameter

│   ├── Variable border thickness: 3px (cursor), 1px (normal)

│   ├── 14×10 pixel filled colored boxes

│   ├── Centered number rendering

│   └── Dynamic X and Y positioning from controller

└── 8-color system support

```



\### Integration Requirements

\- Connect to existing Oled\_Display.v interface

\- Use shared clock dividers from project template

\- Integrate with team's switch control scheme

\- Follow EE2026 coding standards (no arithmetic operators in combinational logic)



\## Current Implementation Status



\### ✅ COMPLETED - Educational Mode + Tutorial Mode + Progressive Hints (Week 10+)

\- \*\*Complete 2-mode merge sort system\*\* with automatic demo and interactive learning

\- \*\*7-state FSM controller\*\* with Tutorial support, CDC handshake, and debounce protection

\- \*\*Enhanced OLED rendering\*\* with 2-row display capability for practice mode

\- \*\*Cursor system\*\* with variable border thickness (3px cursor, 1px normal)

\- \*\*Answer validation\*\* with step-specific checking and green/red flash feedback

\- \*\*Progressive Hints System\*\* ⭐ NEW:

&nbsp; - Ghost separators (faint white) appear for 1s at step start

&nbsp; - 1px yellow pulsing borders on active merge regions

&nbsp; - Smart activation: Only after first wrong attempt

&nbsp; - Wrong attempt counter tracks user progress per step

\- \*\*CDC Request/Acknowledge protocol\*\* for reliable button handling across clock domains

\- \*\*200ms hardware debounce\*\* for all 5 buttons (no software delays needed)

\- \*\*Dynamic answer box positioning\*\* that follows work array during animations

\- \*\*Element tracking\*\* and smooth X/Y animations

\- \*\*Separator control\*\* via SW0-4 in Tutorial practice mode

\- \*\*Hardware integration\*\* tested and working on Basys3

\- \*\*Enhanced team integration interface\*\* ready with 12-signal bus



\### 🚀 READY FOR TEAM INTEGRATION (Tutorial Mode Support)

\- \*\*Switch Control\*\*:

&nbsp; - SW15: Enable merge sort

&nbsp; - SW10: Toggle Tutorial mode (ON=Tutorial, OFF=Educational)

&nbsp; - SW0-4: Separator placement (Tutorial practice only)

\- \*\*Enhanced Compatible Interface\*\*: Full flattened bus system

&nbsp; - `array\_data\_flat \[17:0]` - Work array values

&nbsp; - `answer\_data\_flat \[17:0]` - Answer array values (NEW)

&nbsp; - `array\_positions\_y\_flat \[35:0]` - Y positions

&nbsp; - `array\_positions\_x\_flat \[41:0]` - X positions

&nbsp; - `array\_colors\_flat \[17:0]` - Work array colors

&nbsp; - `answer\_colors\_flat \[17:0]` - Answer box colors (NEW)

&nbsp; - `separator\_visible \[4:0]` - Dynamic separator control

&nbsp; - `cursor\_pos\_out \[2:0]` - Cursor position (NEW)

&nbsp; - `practice\_mode\_active` - 2-row display flag (NEW)

&nbsp; - Status outputs: current\_state, sorting\_active, sort\_complete

\- \*\*Resource Sharing\*\*: OLED, seven-segment, LEDs, all buttons

\- \*\*Advanced Features\*\*: Tutorial learning, CDC handshake, debounce, 2-row display



\## Key Files and Locations

\- \*\*Latest Working Project\*\*: `/Users/afshal/Desktop/Y2S1/EE2026/Lab/Project/Week 8/MergeSort\_Demo\_New.xpr.zip`

\- \*\*Working Source Files\*\*: `MergeSort\_Demo/MergeSort\_Demo.srcs/sources\_1/imports/sources\_1/new/`

&nbsp; - `Top\_Student.v` (main integration, 236 lines)

&nbsp; - `merge\_sort\_controller.v` (7-state FSM + Tutorial system, 1537 lines)

&nbsp; - `merge\_sort\_display.v` (OLED rendering with 2-row support, 224 lines)

&nbsp; - `merge\_sort\_numbers.v` (fonts + box rendering with cursor, 234 lines)

&nbsp; - `Oled\_Display.v` (provided OLED interface)

\- \*\*Constraints\*\*: `MergeSort\_Demo.srcs/constrs\_1/imports/new/Basys3\_constraints.xdc`

\- \*\*Documentation\*\*:

&nbsp; - This CLAUDE.md file (project context)

&nbsp; - PROJECT\_STATUS.md (current status and features)

&nbsp; - Skill.md (patterns and best practices)

&nbsp; - TEAM\_INTEGRATION\_GUIDE.md (for teammates)

&nbsp; - MERGE\_SORT\_IMPLEMENTATION.md (technical details)



\## Development Notes



\### OLED Interface Details

\- \*\*Module\*\*: Oled\_Display.v (provided, do not modify)

\- \*\*Clock\*\*: 6.25MHz for OLED interface

\- \*\*Data Format\*\*: 16-bit RGB565 color per pixel

\- \*\*Coordinate System\*\*: x = pixel\_index % 96, y = pixel\_index / 96

\- \*\*Pixel Index\*\*: 0 to 6143 (96×64-1)



\### Enhanced Merge Sort Algorithm Implementation (FULLY WORKING)

\- \*\*Iterative bottom-up approach\*\* implemented in hardware with element tracking

\- \*\*5-State FSM\*\*: IDLE → INIT → DIVIDE → MERGE → SORTED

\- \*\*3-Step Divide Phase\*\*: Visual separation with color grouping and dynamic separators

&nbsp; - Step 1: \[426] vs \[153] (2 groups, 1 separator)

&nbsp; - Step 2: \[42]\[6] vs \[15]\[3] (4 groups, 3 separators)  

&nbsp; - Step 3: \[4]\[2]\[6] vs \[1]\[5]\[3] (6 individual, 5 separators)

\- \*\*3-Step Merge Phase\*\*: Iterative merging with element swapping animation

&nbsp; - Step 1: Merge pairs \[4,2]→\[2,4], \[1,5]→\[1,5] (elements physically swap, 3 separators)

&nbsp; - Step 2: Merge groups \[2,4,6] and \[1,3,5] (visual movement, 1 separator)

&nbsp; - Step 3: Final merge \[1,2,3,4,5,6] (complete sort, 0 separators)

\- \*\*Enhanced Color System\*\*: Intelligent color flow with state preservation

&nbsp; - DIVIDE\_STEP\_3: Individual colors for each element

&nbsp; - MERGE\_STEP\_1: Sorted pairs get group colors (purple/cyan), singles keep original

&nbsp; - MERGE\_STEP\_2: Merged groups get new colors, preserve during sorting

&nbsp; - MERGE\_STEP\_3: Final array becomes green when fully sorted

\- \*\*Element Tracking\*\*: Each element has unique ID that follows through all swaps

\- \*\*Animation\*\*: Smooth X-position interpolation during swaps at ~45Hz



\### Enhanced Team Integration Protocol (READY)

\- \*\*SW15 = Afshal's Merge Sort\*\*: Clear switch assignment for team

\- \*\*Enhanced Flattened Bus Interface\*\*: 

&nbsp; - `array\_data\_flat \[17:0]` - Element values (6 × 3 bits)

&nbsp; - `array\_positions\_y\_flat \[35:0]` - Y positions (6 × 6 bits)

&nbsp; - `array\_positions\_x\_flat \[41:0]` - X positions (6 × 7 bits) \*\*NEW\*\*

&nbsp; - `array\_colors\_flat \[17:0]` - Element colors (6 × 3 bits)

&nbsp; - `separator\_visible \[4:0]` - Separator control flags \*\*NEW\*\*

\- \*\*Shared OLED\*\*: Enhanced compatibility with team's pixel data multiplexing

\- \*\*Clock Domains\*\*: Uses standard 6.25MHz OLED clock + 45Hz movement

\- \*\*Status LEDs\*\*: Shows algorithm state for debugging/demonstration

\- \*\*Seven-segment\*\*: Displays "MERG" when active

\- \*\*Advanced Features\*\*: Element tracking, dynamic separators, swap animations



\## Testing Strategy

1\. \*\*Module-level\*\*: Test each Verilog module independently

2\. \*\*Integration\*\*: Test merge sort visualization in isolation

3\. \*\*Team Integration\*\*: Test with other team members' algorithms

4\. \*\*Hardware Validation\*\*: Test on actual Basys3 board with OLED



\## Constraints and Limitations

\- FPGA resource constraints (LUTs, memory)

\- No arithmetic operators in combinational logic

\- 16-bit color palette limitations

\- 96×64 pixel resolution constraints

\- Real-time animation timing requirements



\## Command Shortcuts for Development

```bash

\# Navigate to project

cd "/Users/afshal/Desktop/Y2S1/EE2026/Lab/Project/Week 8/FDP"



\# Common file locations

\# Source: FDP.srcs/sources\_1/new/

\# Constraints: FDP.srcs/constrs\_1/new/

\# Simulation: FDP.srcs/sim\_1/new/

```



\## References

\- EE2026 Project Manual PDF

\- Basys3\_Master.xdc constraint file

\- Lab 1-3 previous implementations

\- Week 7 basic tasks integration example (S3\_15 group)

\- Skill.md for EE2026 patterns and best practices



---

\*Last Updated: Week 10+ - Educational Mode + Tutorial Mode + Progressive Hints Complete, November 2025\*

\*Focus: Interactive learning with progressive hints (ghost separators, pulsing borders after wrong attempts), 2-row practice display, CDC handshake, debounce protection\*

\*Latest Features: 1px yellow pulsing borders (only after ≥1 wrong attempt), faint white ghost separators (1s duration), box colors \[Magenta, Red, Orange, Cyan, Green, Blue]\*

\*Next Review: Team integration and final hardware testing (Week 11-12)\*



\## Quick Reference for Teammates



\*\*Afshal's Merge Sort Algorithm Control:\*\*



\*\*Educational Mode\*\* (SW15=ON, SW10=OFF):

\- \*\*btnU\*\*: Start/restart animation

\- \*\*btnD\*\*: Pause/resume animation

\- \*\*btnC\*\*: Reset system



\*\*Tutorial Mode\*\* (SW15=ON, SW10=ON):

\- \*\*btnL/R\*\*: Cursor navigation (wrap 0↔5)

\- \*\*btnU/D\*\*: Increment/decrement values (0-7)

\- \*\*btnC\*\*: Confirm array (EDIT) or Check answer (PRACTICE)

\- \*\*SW0-4\*\*: Separator line placement (PRACTICE phase)



\*\*Common\*\*:

\- \*\*LEDs\*\*: Show mode, state, and progress

\- \*\*Seven-segment\*\*: Displays "MERG" when active

\- \*\*Ready for integration\*\*: Enhanced flattened bus with 12 signals





# EE2026 Team Integration Guide

\*\*For Pranav (Bubble), Abhijit (Selection), Praveen (Insertion)\*\*

\*\*From: Afshal (Merge Sort) - Educational + Tutorial Modes Complete\*\*



\## 🎯 Purpose

This guide provides \*\*proven patterns and interface standards\*\* for integrating all 4 sorting algorithms into one bitstream. Each teammate implements their algorithm \*\*their own way\*\* - this guide just ensures compatibility.



\*\*Key Principles:\*\*

\- ✅ Use the universal interface for compatibility

\- ✅ Implement your algorithm however you want

\- ✅ Follow the switch assignment scheme

\- ✅ Share the OLED display cleanly

\- ❌ Don't feel forced to use any specific pattern if you have a better approach



\## 🔧 \*\*Switch Assignment Plan\*\*

```verilog

// Proposed switch control scheme for team integration

wire bubble\_sort\_active = sw\[12];    // Pranav's Bubble Sort

wire selection\_sort\_active = sw\[13]; // Abhijit's Selection Sort  

wire insertion\_sort\_active = sw\[14]; // Praveen's Insertion Sort

wire merge\_sort\_active = sw\[15];     // Afshal's Merge Sort (DONE)



// In Top\_Student.v - pixel data multiplexing

always @(\*) begin

&nbsp;   if (merge\_sort\_active) begin

&nbsp;       pixel\_data = merge\_sort\_pixel\_data;

&nbsp;   end else if (insertion\_sort\_active) begin

&nbsp;       pixel\_data = insertion\_sort\_pixel\_data;

&nbsp;   end else if (selection\_sort\_active) begin

&nbsp;       pixel\_data = selection\_sort\_pixel\_data;

&nbsp;   end else if (bubble\_sort\_active) begin

&nbsp;       pixel\_data = bubble\_sort\_pixel\_data;

&nbsp;   end else begin

&nbsp;       pixel\_data = 16'h0000;  // Black when no algorithm active

&nbsp;   end

end

```



---



\## 📋 \*\*Integration Requirements Summary\*\*



\### \*\*REQUIRED (Must Have for Integration):\*\*

1\. ✅ \*\*Switch Assignment\*\*: Use your assigned switch (SW12-15)

2\. ✅ \*\*Universal Interface\*\*: Output the flattened bus signals (array\_data\_flat, array\_positions\_y\_flat, etc.)

3\. ✅ \*\*Shared OLED\*\*: Connect pixel\_data output to Top\_Student multiplexer

4\. ✅ \*\*Same Display Module\*\*: Use merge\_sort\_display.v (or equivalent that accepts same signals)



\### \*\*OPTIONAL (Implement Your Way):\*\*

\- ❌ FSM structure (use any state machine you want)

\- ❌ Animation system (static display is fine)

\- ❌ Color scheme (use any colors, just be consistent)

\- ❌ Button control (simple edge detection or CDC, your choice)

\- ❌ Tutorial mode (demo-only is perfectly fine)

\- ❌ Number of elements (6 is suggested, but you can use different array sizes)



\*\*Bottom Line:\*\* As long as your module outputs the correct signals on the flattened buses, you can implement your sorting algorithm any way you like!



---



\## 📐 \*\*Universal Interface Pattern (REQUIRED for Integration)\*\*

\*\*This interface is the ONLY requirement for integration - everything else is optional!\*\*



Each algorithm must output the same flattened bus signals so Top\_Student.v can multiplex them to the shared OLED display. \*\*How you generate these signals internally is completely up to you.\*\*



```verilog

// Module interface (works for bubble, selection, insertion, merge)

module your\_sort\_controller(

&nbsp;   input clk,

&nbsp;   input clk\_6p25MHz,

&nbsp;   input clk\_movement,           // 45Hz for animations

&nbsp;   input reset,

&nbsp;   input btn\_start,              // Start/restart algorithm

&nbsp;   input btn\_pause,              // Pause/resume animation

&nbsp;   input btn\_left,               // Left navigation (if implementing interactive mode)

&nbsp;   input btn\_right,              // Right navigation (if implementing interactive mode)

&nbsp;   input btn\_center,             // Confirmation button (if implementing interactive mode)

&nbsp;   input demo\_active,            // Enable from switch

&nbsp;   input educational\_mode,       // Educational mode (auto demo)

&nbsp;   input tutorial\_mode,          // Tutorial mode (interactive learning) - OPTIONAL

&nbsp;   input \[4:0] line\_switches,    // SW0-4 for features (optional)



&nbsp;   // Universal interface - SAME FOR ALL ALGORITHMS

&nbsp;   output reg \[17:0] array\_data\_flat,        // 6 elements × 3 bits (0-7 values)

&nbsp;   output reg \[17:0] answer\_data\_flat,       // Answer boxes (tutorial mode) - OPTIONAL

&nbsp;   output reg \[35:0] array\_positions\_y\_flat, // 6 elements × 6 bits (Y positions)

&nbsp;   output reg \[41:0] array\_positions\_x\_flat, // 6 elements × 7 bits (X positions)

&nbsp;   output reg \[17:0] array\_colors\_flat,      // 6 elements × 3 bits (color codes)

&nbsp;   output reg \[17:0] answer\_colors\_flat,     // Answer box colors (tutorial) - OPTIONAL

&nbsp;   output reg \[4:0] separator\_visible,       // 5 separators visibility flags

&nbsp;   output reg \[2:0] cursor\_pos\_out,          // Cursor position (tutorial) - OPTIONAL

&nbsp;   output reg practice\_mode\_active,          // 2-row display flag (tutorial) - OPTIONAL



&nbsp;   // Status outputs

&nbsp;   output reg \[2:0] current\_state,

&nbsp;   output reg sorting\_active,

&nbsp;   output reg sort\_complete

);



// Internal arrays for easier manipulation

reg \[2:0] array\_data \[0:5];        // Your algorithm works on this (values 0-7)

reg \[2:0] answer\_array \[0:5];      // For tutorial practice mode (OPTIONAL)

reg \[5:0] array\_positions\_y \[0:5]; // Y-axis animation positions

reg \[6:0] array\_positions\_x \[0:5]; // X-axis animation positions

reg \[2:0] array\_colors \[0:5];      // Color for each element

reg \[2:0] answer\_colors \[0:5];     // Colors for answer boxes (OPTIONAL)



// Convert to flattened buses (COPY THIS EXACTLY)

always @(\*) begin

&nbsp;   array\_data\_flat = {array\_data\[5], array\_data\[4], array\_data\[3],

&nbsp;                      array\_data\[2], array\_data\[1], array\_data\[0]};

&nbsp;   answer\_data\_flat = {answer\_array\[5], answer\_array\[4], answer\_array\[3],

&nbsp;                       answer\_array\[2], answer\_array\[1], answer\_array\[0]};

&nbsp;   array\_positions\_y\_flat = {array\_positions\_y\[5], array\_positions\_y\[4],

&nbsp;                              array\_positions\_y\[3], array\_positions\_y\[2],

&nbsp;                              array\_positions\_y\[1], array\_positions\_y\[0]};

&nbsp;   array\_positions\_x\_flat = {array\_positions\_x\[5], array\_positions\_x\[4],

&nbsp;                              array\_positions\_x\[3], array\_positions\_x\[2],

&nbsp;                              array\_positions\_x\[1], array\_positions\_x\[0]};

&nbsp;   array\_colors\_flat = {array\_colors\[5], array\_colors\[4], array\_colors\[3],

&nbsp;                        array\_colors\[2], array\_colors\[1], array\_colors\[0]};

&nbsp;   answer\_colors\_flat = {answer\_colors\[5], answer\_colors\[4], answer\_colors\[3],

&nbsp;                         answer\_colors\[2], answer\_colors\[1], answer\_colors\[0]};

end



endmodule

```



\## 🎨 \*\*Color Coding System (OPTIONAL - Suggested for Consistency)\*\*

\*\*Note:\*\* These are Afshal's proven colors. Feel free to use different colors if your algorithm needs it!



```verilog

// Suggested color codes for visual consistency across algorithms

localparam COLOR\_NORMAL = 3'b000;    // White - not being processed

localparam COLOR\_ACTIVE = 3'b001;    // Red - currently being processed (RESERVED for feedback)

localparam COLOR\_SORTED = 3'b010;    // Green - in final sorted position (RESERVED for feedback)

localparam COLOR\_COMPARE = 3'b011;   // Yellow - being compared / hints

localparam COLOR\_GROUP1 = 3'b100;    // Magenta - group 1 / element colors

localparam COLOR\_GROUP2 = 3'b101;    // Cyan - group 2 / element colors

localparam COLOR\_GROUP3 = 3'b110;    // Orange - group 3 / element colors

localparam COLOR\_GROUP4 = 3'b111;    // Blue - group 4 / element colors



// Recommended box colors for 6 elements (Afshal's proven scheme):

// Position 0: Magenta, Position 1: Red\*, Position 2: Orange

// Position 3: Cyan, Position 4: Green\*, Position 5: Blue

// \*Note: Red/Green also used for validation feedback, plan accordingly



// Example usage in your algorithm:

// Bubble Sort: YELLOW for comparing pair, GREEN when element reaches final position

// Selection Sort: YELLOW during minimum search, MAGENTA for swap operation

// Insertion Sort: ORANGE for element being inserted, CYAN for comparison region

```



\## 🔄 \*\*Simple FSM Pattern (OPTIONAL - Example Only)\*\*

\*\*This is just ONE way to structure your algorithm. Use whatever FSM design works best for you!\*\*



```verilog

// Example states (customize for your algorithm)

localparam STATE\_IDLE = 3'b000;

localparam STATE\_INIT = 3'b001;

localparam STATE\_SORTING = 3'b010;    // Your main algorithm phase

localparam STATE\_SORTED = 3'b011;



reg \[2:0] state, next\_state;



// State transitions (customize conditions for your algorithm)

always @(\*) begin

&nbsp;   next\_state = state;

&nbsp;   case (state)

&nbsp;       STATE\_IDLE: begin

&nbsp;           if (demo\_active \&\& btn\_start) begin

&nbsp;               next\_state = STATE\_INIT;

&nbsp;           end

&nbsp;       end

&nbsp;       STATE\_INIT: begin

&nbsp;           if (init\_timer >= INIT\_DELAY) begin

&nbsp;               next\_state = STATE\_SORTING;

&nbsp;           end

&nbsp;       end

&nbsp;       STATE\_SORTING: begin

&nbsp;           if (algorithm\_complete) begin  // Your algorithm's completion condition

&nbsp;               next\_state = STATE\_SORTED;

&nbsp;           end

&nbsp;       end

&nbsp;       STATE\_SORTED: begin

&nbsp;           if (btn\_start) begin

&nbsp;               next\_state = STATE\_INIT;  // Restart

&nbsp;           end

&nbsp;       end

&nbsp;   endcase

end



// State register

always @(posedge clk or posedge reset) begin

&nbsp;   if (reset) begin

&nbsp;       state <= STATE\_IDLE;

&nbsp;   end else begin

&nbsp;       state <= next\_state;

&nbsp;   end

end

```



\## 📊 \*\*Animation System (OPTIONAL - Example Pattern)\*\*

\*\*Use this if you want smooth animations. Static displays also work fine!\*\*



```verilog

// Example position parameters (adapt to your needs)

localparam POS\_TOP = 6'd8;       // Start position

localparam POS\_BOTTOM = 6'd48;   // End position  

localparam POS\_MID = 6'd32;      // Middle position



// Target position system

reg \[5:0] target\_y \[0:5];

reg \[5:0] array\_positions\_y \[0:5];



// Animation completion detection (COPY THIS)

integer pos\_check;

reg all\_positions\_match;

always @(\*) begin

&nbsp;   all\_positions\_match = 1'b1;

&nbsp;   for (pos\_check = 0; pos\_check < 6; pos\_check = pos\_check + 1) begin

&nbsp;       if (array\_positions\_y\[pos\_check] != target\_y\[pos\_check]) begin

&nbsp;           all\_positions\_match = 1'b0;

&nbsp;       end

&nbsp;   end

end



// Movement logic (adapt for your algorithm's visualization)

always @(posedge clk\_movement) begin

&nbsp;   if (state == STATE\_SORTING) begin

&nbsp;       // Example: Move elements based on your algorithm's needs

&nbsp;       for (i = 0; i < 6; i = i + 1) begin

&nbsp;           if (array\_positions\_y\[i] < target\_y\[i]) begin

&nbsp;               array\_positions\_y\[i] <= array\_positions\_y\[i] + 1;

&nbsp;           end else if (array\_positions\_y\[i] > target\_y\[i]) begin

&nbsp;               array\_positions\_y\[i] <= array\_positions\_y\[i] - 1;

&nbsp;           end

&nbsp;       end

&nbsp;   end

end

```



\## 🎮 \*\*Button Control Patterns (OPTIONAL - Choose What Works)\*\*



\### \*\*Simple Edge Detection (Easiest - For Auto-Demo Mode)\*\*

```verilog

// Edge detection for buttons (COPY THIS EXACTLY)

reg \[2:0] btnU\_sync = 3'b000;

reg \[2:0] btnD\_sync = 3'b000;

reg \[2:0] btnC\_sync = 3'b000;



always @(posedge clk) begin

&nbsp;   btnU\_sync <= {btnU\_sync\[1:0], btnU};

&nbsp;   btnD\_sync <= {btnD\_sync\[1:0], btnD};

&nbsp;   btnC\_sync <= {btnC\_sync\[1:0], btnC};

end



wire btn\_start = btnU\_sync\[2] \&\& !btnU\_sync\[1];  // Rising edge

wire btn\_pause = btnD\_sync\[2] \&\& !btnD\_sync\[1];  // Rising edge

wire btn\_reset = btnC\_sync\[2] \&\& !btnC\_sync\[1];  // Rising edge

```



\### \*\*CDC Request/Acknowledge Pattern (Advanced - For Interactive Mode)\*\*

\*\*Only needed if you're doing interactive features across clock domains. Skip if not needed!\*\*



```verilog

// Request/Acknowledge flags for clock domain crossing

// Set request in clk domain (100MHz), acknowledge in clk\_movement domain (45Hz)



// Request flags (clk domain)

reg value\_up\_req;

reg value\_down\_req;



// Acknowledge flags (clk\_movement domain)

reg value\_up\_ack;

reg value\_down\_ack;



// 2-stage synchronizers (clk -> clk\_movement)

reg \[1:0] value\_up\_req\_sync;

reg \[1:0] value\_down\_req\_sync;



// 2-stage synchronizers (clk\_movement -> clk)

reg \[1:0] value\_up\_ack\_sync;

reg \[1:0] value\_down\_ack\_sync;



// Debounce timers (200ms at 100MHz = 20,000,000 cycles)

reg \[19:0] debounce\_up;

reg \[19:0] debounce\_down;



// Synchronize req signals into clk\_movement domain

always @(posedge clk\_movement or posedge reset) begin

&nbsp;   if (reset) begin

&nbsp;       value\_up\_req\_sync <= 2'b00;

&nbsp;       value\_down\_req\_sync <= 2'b00;

&nbsp;   end else begin

&nbsp;       value\_up\_req\_sync <= {value\_up\_req\_sync\[0], value\_up\_req};

&nbsp;       value\_down\_req\_sync <= {value\_down\_req\_sync\[0], value\_down\_req};

&nbsp;   end

end



// Synchronize ack signals back to clk domain

always @(posedge clk or posedge reset) begin

&nbsp;   if (reset) begin

&nbsp;       value\_up\_ack\_sync <= 2'b00;

&nbsp;       value\_down\_ack\_sync <= 2'b00;

&nbsp;   end else begin

&nbsp;       value\_up\_ack\_sync <= {value\_up\_ack\_sync\[0], value\_up\_ack};

&nbsp;       value\_down\_ack\_sync <= {value\_down\_ack\_sync\[0], value\_down\_ack};

&nbsp;   end

end



// Button handling in clk domain (set request when button pressed)

always @(posedge clk or posedge reset) begin

&nbsp;   if (reset) begin

&nbsp;       value\_up\_req <= 1'b0;

&nbsp;       value\_down\_req <= 1'b0;

&nbsp;       debounce\_up <= 20'd0;

&nbsp;       debounce\_down <= 20'd0;

&nbsp;   end else begin

&nbsp;       // Decrement debounce timers

&nbsp;       if (debounce\_up > 20'd0) debounce\_up <= debounce\_up - 1;

&nbsp;       if (debounce\_down > 20'd0) debounce\_down <= debounce\_down - 1;



&nbsp;       // UP button - set request when pressed and not debouncing

&nbsp;       if (btn\_start\_edge \&\& !value\_up\_req \&\& !value\_up\_ack\_sync\[1] \&\& debounce\_up == 20'd0) begin

&nbsp;           value\_up\_req <= 1'b1;

&nbsp;           debounce\_up <= 20'd20000000;  // 200ms

&nbsp;       end else if (value\_up\_req \&\& value\_up\_ack\_sync\[1]) begin

&nbsp;           value\_up\_req <= 1'b0;  // Clear when acknowledged

&nbsp;       end



&nbsp;       // DOWN button - similar pattern

&nbsp;       if (btn\_pause\_edge \&\& !value\_down\_req \&\& !value\_down\_ack\_sync\[1] \&\& debounce\_down == 20'd0) begin

&nbsp;           value\_down\_req <= 1'b1;

&nbsp;           debounce\_down <= 20'd20000000;

&nbsp;       end else if (value\_down\_req \&\& value\_down\_ack\_sync\[1]) begin

&nbsp;           value\_down\_req <= 1'b0;

&nbsp;       end

&nbsp;   end

end



// Process requests in clk\_movement domain

always @(posedge clk\_movement or posedge reset) begin

&nbsp;   if (reset) begin

&nbsp;       value\_up\_ack <= 1'b0;

&nbsp;       value\_down\_ack <= 1'b0;

&nbsp;   end else begin

&nbsp;       // Process UP request

&nbsp;       if (value\_up\_req\_sync\[1] \&\& !value\_up\_ack) begin

&nbsp;           // Perform action (e.g., increment value)

&nbsp;           if (work\_array\[cursor\_pos] == 3'd7) begin

&nbsp;               work\_array\[cursor\_pos] <= 3'd0;

&nbsp;           end else begin

&nbsp;               work\_array\[cursor\_pos] <= work\_array\[cursor\_pos] + 1;

&nbsp;           end

&nbsp;           value\_up\_ack <= 1'b1;  // Acknowledge

&nbsp;       end

&nbsp;       if (!value\_up\_req\_sync\[1] \&\& value\_up\_ack) begin

&nbsp;           value\_up\_ack <= 1'b0;  // Clear ack when request clears

&nbsp;       end



&nbsp;       // Similar for DOWN request...

&nbsp;   end

end

```



\## 🏗️ \*\*Algorithm-Specific Adaptations\*\*



\### For Pranav (Bubble Sort):

\- \*\*States\*\*: IDLE → INIT → BUBBLE\_PASS → SORTED

\- \*\*Colors\*\*: RED for comparing pair, GREEN when element reaches final position

\- \*\*Animation\*\*: Highlight adjacent elements during comparison



\### For Abhijit (Selection Sort):

\- \*\*States\*\*: IDLE → INIT → FIND\_MIN → SWAP → SORTED  

\- \*\*Colors\*\*: YELLOW during minimum search, RED for swap operation

\- \*\*Animation\*\*: Highlight minimum element and swap positions



\### For Praveen (Insertion Sort):

\- \*\*States\*\*: IDLE → INIT → INSERT\_ELEMENT → SORTED

\- \*\*Colors\*\*: RED for element being inserted, YELLOW for shift operations

\- \*\*Animation\*\*: Show element moving to correct position



\## 📁 \*\*Files to Copy and Modify\*\*



1\. \*\*Copy merge\_sort\_display.v\*\* → Rename to your\_sort\_display.v (no changes needed!)

2\. \*\*Copy merge\_sort\_numbers.v\*\* → Rename to your\_sort\_numbers.v (no changes needed!)

3\. \*\*Copy pattern from merge\_sort\_controller.v\*\* → Create your\_sort\_controller.v (modify algorithm logic only)



\## 🤝 \*\*Integration Steps\*\*



1\. \*\*Week 8-9\*\*: Each person develops their algorithm independently (any approach)

2\. \*\*Week 10\*\*: Test each algorithm works with their assigned switch

3\. \*\*Week 10\*\*: Integrate all 4 algorithms into single Top\_Student.v (pixel data multiplexing)

4\. \*\*Week 11\*\*: Final testing, polish, and presentation prep



\*\*Integration Tips:\*\*

\- Don't wait until Week 11 to test integration!

\- Each person can work independently as long as interface is correct

\- Test one algorithm at a time when integrating

\- If someone's algorithm isn't ready, temporarily use placeholder black screen for that switch



\## 🎓 \*\*Advanced: Tutorial/Interactive Mode Features (Optional)\*\*



If you want to implement interactive learning modes like Afshal's merge sort tutorial, consider these proven patterns:



\### \*\*Progressive Hints System\*\*

```verilog

// Wrong attempt tracking

reg \[2:0] wrong\_attempt\_count;  // Count wrong attempts per step



// Visual hints (only activate after struggles)

reg \[5:0] pulse\_timer;          // Timer for pulsing effect (~0.5s cycle)

reg pulse\_state;                // Toggles every 0.5s

reg \[5:0] hint\_regions\_active;  // Which elements need hints



// Ghost hints (faint visual cues)

reg \[5:0] hint\_timer;           // Countdown timer (1 second)

localparam COLOR\_FAINT = 16'h4208;  // Dim white (RGB565: R:8, G:16, B:8)



// Progressive activation logic

if (wrong\_attempt\_count >= 3'd1) begin

&nbsp;   // Enable pulsing borders or visual hints

&nbsp;   hint\_regions\_active <= 6'b111111;  // Activate hints for all elements

end else begin

&nbsp;   hint\_regions\_active <= 6'b000000;  // No hints initially

end

```



\### \*\*Answer Validation with Feedback\*\*

```verilog

// Per-element validation

reg \[5:0] element\_correct;      // Correctness flags for each element

reg \[2:0] flash\_timer;          // Flash duration timer



// Validation task

task check\_user\_answer;

&nbsp;   begin

&nbsp;       // Check each element

&nbsp;       for (i = 0; i < 6; i = i + 1) begin

&nbsp;           element\_correct\[i] <= (user\_array\[i] == expected\_array\[i]);

&nbsp;       end



&nbsp;       // Increment wrong attempt counter if incorrect

&nbsp;       if (!(all\_correct)) begin

&nbsp;           wrong\_attempt\_count <= wrong\_attempt\_count + 1;

&nbsp;       end



&nbsp;       flash\_timer <= 1;  // Trigger flash feedback

&nbsp;   end

endtask



// Flash feedback rendering (red=wrong, green=correct)

if (flash\_timer > 0) begin

&nbsp;   element\_colors\[i] <= element\_correct\[i] ? COLOR\_SORTED : COLOR\_ACTIVE;

end

```



\### \*\*2-Row Display System\*\*

```verilog

// Bottom row: Work array (algorithm visualization)

// Top row: User's answer boxes (for practice)

wire \[5:0] answer\_box\_y\_pos;



// Dynamic positioning - answer boxes follow work array

assign answer\_box\_y\_pos = (work\_positions\_y\[0] == POS\_BOTTOM) ?

&nbsp;                         (POS\_TOP + 2 \* (POS\_BOTTOM - POS\_TOP) / 3) :

&nbsp;                         (work\_positions\_y\[0] >= (POS\_TOP + 2 \* (POS\_BOTTOM - POS\_TOP) / 3)) ?

&nbsp;                         (POS\_TOP + (POS\_BOTTOM - POS\_TOP) / 3) : POS\_TOP;

```



\*\*Benefits of Tutorial Mode:\*\*

\- Engaging educational experience

\- Demonstrates deep understanding of your algorithm

\- Differentiates your component from basic implementations

\- Excellent for presentation/demo



\## 📞 \*\*Questions?\*\*

\- Check Skill.md for detailed Verilog patterns

\- Use CLAUDE.md structure for documenting your implementation

\- Ask Afshal for clarification on interface patterns or tutorial mode implementation



\*\*Good luck with your implementations! 🚀\*\*

