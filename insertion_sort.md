\# InS3rtion-S0rt: Comprehensive Project Documentation



\## Project Overview



\*\*InS3rtion-S0rt\*\* is an educational FPGA-based insertion sort visualizer designed for the Basys3 development board. The project provides two distinct operating modes:

1\. \*\*Education Mode\*\*: Interactive step-by-step demonstration of the insertion sort algorithm

2\. \*\*Tutorial Mode\*\*: Gamified learning experience where users manually perform sorting operations



\*\*Hardware Platform\*\*: Xilinx Basys3 FPGA Board

\*\*HDL Language\*\*: Verilog

\*\*Display\*\*: OLED Display (96x64 pixels, 16-bit RGB565 color)

\*\*Clock Frequency\*\*: 100MHz input, 6.25MHz OLED driver clock



---



\## Table of Contents



1\. \[Hardware I/O Specification](#hardware-io-specification)

2\. \[Switch Configuration](#switch-configuration)

3\. \[Button Controls](#button-controls)

4\. \[Operating Modes](#operating-modes)

5\. \[Module Architecture](#module-architecture)

6\. \[State Machine Flow](#state-machine-flow)

7\. \[Display Output](#display-output)

8\. \[Integration Guide](#integration-guide)

9\. \[Timing Specifications](#timing-specifications)

10\. \[Data Structures](#data-structures)



---



\## Hardware I/O Specification



\### Top-Level Module: `sorting\_visualizer\_top`



\#### Inputs



| Signal | Type | Pin/Port | Description |

|--------|------|----------|-------------|

| `clk` | input | System Clock | 100MHz system clock |

| `sw\_14` | input | Switch 14 | System master enable (active HIGH) |

| `sw\_10` | input | Switch 10 | Tutorial mode enable (active HIGH) |

| `btnC` | input | Center Button | Context-sensitive: Confirm/Next/Swap |

| `btnL` | input | Left Button | Context-sensitive: Previous/Move Left/Compare Left |

| `btnR` | input | Right Button | Context-sensitive: Next/Move Right/Compare Right |

| `btnU` | input | Up Button | Context-sensitive: Return/Increment Value/Restart |

| `btnD` | input | Down Button | Context-sensitive: Decrement Value/Keep (no swap) |



\#### Outputs



| Signal | Type | Pin/Port | Description |

|--------|------|----------|-------------|

| `seg\[6:0]` | output | 7-Segment Display | Displays "InSt" (Insertion Sort) |

| `an\[3:0]` | output | 7-Segment Anodes | Anode control for 4-digit display |

| `dp` | output | Decimal Point | Always OFF (tied HIGH) |

| `led\[15:0]` | output | LEDs | Status indicators |

| `JC\[7:0]` | output | PMOD JC | OLED display interface |



\#### LED Indicators



| LED | Function | Active State |

|-----|----------|--------------|

| `led\[14]` | System enabled | HIGH when SW14 is ON |

| `led\[10]` | Tutorial mode active | HIGH when SW10 AND SW14 are ON |

| `led\[13:11], led\[9:0]` | Unused | - |



\#### OLED Display Pins (PMOD JC)



| JC Pin | Signal | Description |

|--------|--------|-------------|

| `JC\[0]` | CS | Chip Select (active LOW) |

| `JC\[1]` | SDIN | Serial Data Input (MOSI) |

| `JC\[2]` | - | Unused (tied to GND) |

| `JC\[3]` | SCLK | Serial Clock |

| `JC\[4]` | D/C\_N | Data/Command Select |

| `JC\[5]` | RES\_N | Reset (active LOW) |

| `JC\[6]` | VCCEN | VCC Enable |

| `JC\[7]` | PMODEN | Power Supply Enable |



---



\## Switch Configuration



\### SW14: System Master Enable



\*\*Function\*\*: Primary system power control

\*\*States\*\*:

\- `OFF (0)`: System disabled, all modules in reset, display blank, LEDs off

\- `ON (1)`: System active, enters Education Mode by default



\*\*Implementation\*\*: Connected to `system\_enable` signal throughout design



\### SW10: Tutorial Mode Enable



\*\*Function\*\*: Mode selector (requires SW14 to be ON)

\*\*States\*\*:

\- `OFF (0)`: Education Mode (demo mode with automatic algorithm progression)

\- `ON (1)`: Tutorial Mode (interactive game-based learning)



\*\*Implementation\*\*:

```verilog

assign tutorial\_mode\_active = system\_enable \&\& sw\_10;

```



\*\*Mode Switching Behavior\*\*:

\- Switching modes triggers automatic state machine reset

\- Array data is reset to initial conditions

\- History buffer is cleared

\- Display transitions to welcome screen of new mode



---



\## Button Controls



\### Context-Sensitive Button Mapping



Buttons perform different functions depending on the current operating mode and state:



\#### Education Mode (SW10 = OFF)



| State | btnC | btnL | btnR | btnU | btnD |

|-------|------|------|------|------|------|

| \*\*WELCOME\*\* | Start sorting | - | - | - | - |

| \*\*SORTING\*\* | - | Previous step | Next step | Return to welcome | - |



\#### Tutorial Mode (SW10 = ON)



| State | btnC | btnL | btnR | btnU | btnD |

|-------|------|------|------|------|------|

| \*\*WELCOME\*\* | Start tutorial | - | - | - | - |

| \*\*INPUT\*\* | Confirm array | Move cursor left | Move cursor right | Increment value | Decrement value |

| \*\*SORTING\*\* | Swap elements | Compare left | Compare right | Restart | Keep (no swap) |

| \*\*VICTORY\*\* | Return to input | - | - | - | - |

| \*\*GAME OVER\*\* | Return to input | - | - | - | - |



\### Button Debouncing



All buttons are debounced using a 10ms debounce window with a 20-bit shift register:



\*\*Parameters\*\*:

\- Debounce time: 10ms

\- Clock frequency: 100MHz

\- Debounce cycles: 1,000,000



\*\*Implementation\*\*: `Button\_Debouncer.v` module generates single-cycle pulses on button press events



---



\## Operating Modes



\### Education Mode (Demo Mode)



\*\*Purpose\*\*: Demonstrate the insertion sort algorithm step-by-step



\*\*Features\*\*:

\- Pre-loaded array: `\[0, 3, 1, 4, 2, 5]`

\- Forward/backward navigation through algorithm steps

\- Visual indicators:

&nbsp; - \*\*Red line\*\*: Partition boundary (sorted vs unsorted)

&nbsp; - \*\*Yellow boxes\*\*: Elements being compared

&nbsp; - \*\*Blue boxes\*\*: Elements being swapped

&nbsp; - \*\*Green boxes\*\*: Fully sorted array

\- History buffer: Stores up to 32 previous states for backward navigation



\*\*User Flow\*\*:

1\. Turn ON SW14

2\. System displays welcome screen

3\. Press btnC to enter sorting visualization

4\. Use btnR to step forward, btnL to step backward

5\. Press btnU to return to welcome screen



\*\*Array Access\*\*: Read-only, predefined sequence



\### Tutorial Mode (Interactive Game)



\*\*Purpose\*\*: Teach insertion sort through hands-on practice



\*\*Features\*\*:

\- \*\*Phase 1: Input\*\* - User creates custom array (values 0-7)

\- \*\*Phase 2: Sorting\*\* - User performs sorting operations

\- \*\*Lives System\*\*: 3 hearts, lose one per mistake

\- \*\*Victory Condition\*\*: Successfully sort the array

\- \*\*Game Over Condition\*\*: Lose all 3 hearts



\*\*Visual Feedback\*\*:

\- \*\*Yellow single box\*\*: Current position awaiting direction

\- \*\*Yellow dual boxes\*\*: Comparison in progress

\- \*\*Blue boxes\*\*: Correct swap in progress

\- \*\*Red X\*\*: Mistake indicator

\- \*\*Hearts\*\*: Lives remaining display

\- \*\*Red line\*\*: Sorted partition boundary



\*\*User Flow\*\*:

1\. Turn ON SW14 and SW10

2\. System displays tutorial welcome screen

3\. Press btnC to enter input phase

4\. Create array using btnU/D (increment/decrement), btnL/R (move cursor)

5\. Press btnC to start sorting

6\. Choose comparison direction: btnL (compare left) or btnR (compare right)

7\. System highlights two elements in yellow

8\. Decide action: btnC (swap) or btnD (keep)

9\. Continue until array is sorted or game over



\*\*Game Logic Validation\*\*:

\- System validates every user decision

\- Incorrect direction choice → lose 1 heart

\- Incorrect swap/keep decision → lose 1 heart

\- Tutorial Sort Engine tracks correct algorithm state internally

\- Victory screen displayed when array is fully sorted

\- Game over screen displayed when hearts reach 0



---



\## Module Architecture



\### Module Hierarchy



```

sorting\_visualizer\_top (Top Level)

├── clock\_divider (6.25MHz generation)

├── Clock\_Generator (30Hz, 2Hz timing)

├── Button\_Debouncer (×5 instances)

├── Main\_FSM (State machine controller)

├── Sort\_Engine (Education mode logic)

├── Tutorial\_Input\_Engine (Tutorial input phase)

├── Tutorial\_Sort\_Engine (Tutorial sorting logic)

├── Oled\_Renderer (Graphics generator)

├── Frame\_Buffer (Video memory)

└── Oled\_Display (SPI driver)

```



\### Module Descriptions



\#### 1. `sorting\_visualizer\_top`

\*\*File\*\*: `sorting\_visualizer\_top.v`

\*\*Function\*\*: Top-level integration, I/O mapping, clock generation

\*\*Key Responsibilities\*\*:

\- Route all external I/O signals

\- Instantiate and connect all submodules

\- Generate 6.25MHz OLED clock from 100MHz system clock

\- Implement 7-segment display for "InSt" text

\- LED status indicators



\#### 2. `Main\_FSM`

\*\*File\*\*: `Main\_FSM.v`

\*\*Function\*\*: Central state machine controller

\*\*States\*\* (3-bit encoding):

\- `000`: EDU\_WELCOME

\- `001`: EDU\_SORTING

\- `010`: TUT\_WELCOME

\- `011`: TUT\_INPUT

\- `100`: TUT\_READY (unused in current implementation)

\- `101`: TUT\_SORTING

\- `110`: TUT\_GAME\_OVER

\- `111`: TUT\_VICTORY



\*\*Responsibilities\*\*:

\- Mode switching (Education ↔ Tutorial)

\- Button input routing to appropriate engine

\- State transitions based on user input and engine flags

\- Output control signal generation



\*\*Key Outputs\*\*:

\- `current\_screen\[2:0]`: Current state for renderer

\- `sort\_engine\_next/prev/reset`: Education mode controls

\- `tut\_inc\_val/dec\_val/move\_cursor\_r/l`: Tutorial input controls

\- `tut\_sort\_compare\_left/right/swap/keep/reset`: Tutorial sort controls



\#### 3. `Sort\_Engine`

\*\*File\*\*: `Sort\_Engine.v`

\*\*Function\*\*: Insertion sort algorithm implementation for Education mode

\*\*Key Features\*\*:

\- Pre-loaded array: `\[0, 3, 1, 4, 2, 5]`

\- Two-step comparison process (compare → action)

\- History buffer (32 entries) for backward navigation

\- Visual indicator generation (compare\_idx1/2, swap\_idx1/2)

\- Red line position tracking (sorted boundary)



\*\*Algorithm State\*\*:

\- `i\_index`: Outer loop index (1 to 5)

\- `j\_index`: Inner loop index (bubble backward)

\- `is\_comparing`: Two-step state flag



\*\*Outputs\*\*:

\- `current\_array\_\[0-5]`: Current array state (6 elements, 3 bits each)

\- `red\_line\_pos`: Partition boundary (0-6)

\- `compare\_idx1/2`: Yellow highlight indices

\- `swap\_idx1/2`: Blue highlight indices

\- `is\_sorted\_flag`: Algorithm complete

\- `is\_at\_start\_flag`: At initial state



\#### 4. `Tutorial\_Input\_Engine`

\*\*File\*\*: `Tutorial\_Input\_Engine.v`

\*\*Function\*\*: Handle user array input in tutorial mode

\*\*Features\*\*:

\- 6-element array, values 0-7 (3-bit)

\- Cursor position tracking (0-5)

\- Increment/decrement with wraparound

\- Cursor movement with wraparound

\- Reset on mode activation



\*\*Outputs\*\*:

\- `tut\_array\_\[0-5]`: User-created array

\- `cursor\_pos`: Current cursor position (highlighted element)



\#### 5. `Tutorial\_Sort\_Engine`

\*\*File\*\*: `Tutorial\_Sort\_Engine.v`

\*\*Function\*\*: Interactive sorting game logic with validation

\*\*Key Features\*\*:

\- Validates every user decision against correct algorithm

\- Tracks hearts (3 → 0)

\- Detects victory and game over conditions

\- Generates visual feedback (yellow/blue highlights, red X)

\- Insertion sort state tracking



\*\*Internal States\*\* (3-bit):

\- `WAIT\_DIRECTION`: Waiting for btnL or btnR

\- `SHOW\_COMPARISON`: Display yellow boxes

\- `WAIT\_DECISION`: Waiting for btnC (swap) or btnD (keep)

\- `ANIMATE\_SWAP`: Blue animation (0.25 seconds)

\- `SHOW\_MISTAKE`: Red X animation (1.0 seconds)

\- `CHECK\_ADVANCE`: Advance to next element

\- `VICTORY`: Sorted successfully

\- `GAME\_OVER`: Lost all hearts



\*\*Validation Logic\*\*:

\- Tracks correct insertion sort state internally

\- Compares user decisions against correct action

\- Awards/penalizes accordingly



\*\*Outputs\*\*:

\- `current\_array\_\[0-5]`: Current array state

\- `red\_line\_pos`: Sorted boundary

\- `compare\_idx1/2`: Yellow highlights

\- `swap\_idx1/2`: Blue highlights

\- `hearts\_remaining`: Lives left (0-3)

\- `is\_victory`: Victory flag

\- `is\_game\_over`: Game over flag

\- `show\_mistake`: Red X flag



\#### 6. `Oled\_Renderer`

\*\*File\*\*: `Oled\_Renderer.v`

\*\*Function\*\*: Generate graphical output for all screens

\*\*Rendering Pipeline\*\*:

\- 3-stage pipeline for efficient rendering

\- 96×64 pixel framebuffer generation

\- Font rendering (4×6 and 5×7 fonts)

\- Geometric shape drawing (boxes, lines, trees, clouds, hearts, X)



\*\*Color Palette\*\* (RGB565):

\- `BLACK`: 0x0000

\- `WHITE`: 0xFFFF

\- `RED`: 0xF800

\- `BLUE`: 0x001F

\- `YELLOW`: 0xFFE0

\- `GREEN`: 0x07E0

\- `BROWN`: 0xA145

\- `GREEN2`: 0x06C0



\*\*Screen Rendering by State\*\*:

\- \*\*EDU\_WELCOME\*\*: Title, trees, clouds, "Press Center"

\- \*\*EDU\_SORTING\*\*: Array boxes with colors, red line, prompts

\- \*\*TUT\_WELCOME\*\*: Tutorial title, instructions

\- \*\*TUT\_INPUT\*\*: Editable array, cursor highlight

\- \*\*TUT\_SORTING\*\*: Array, yellow/blue highlights, hearts, red X

\- \*\*TUT\_VICTORY\*\*: Victory message, animation

\- \*\*TUT\_GAME\_OVER\*\*: Game over message



\*\*Outputs\*\*:

\- `fb\_wr\_en`: Frame buffer write enable

\- `fb\_wr\_addr\[12:0]`: Write address (0-6143)

\- `fb\_wr\_data\[15:0]`: Pixel data (RGB565)



\#### 7. `Frame\_Buffer`

\*\*File\*\*: `Frame\_Buffer.v`

\*\*Function\*\*: Dual-port video memory

\*\*Specification\*\*:

\- Size: 6144 bytes (96×64 pixels)

\- Format: 16-bit RGB565 per pixel

\- Port A: Write (from renderer)

\- Port B: Read (from OLED driver)



\#### 8. `Oled\_Display`

\*\*File\*\*: `Oled\_Display.v`

\*\*Function\*\*: SPI-based OLED driver

\*\*Specification\*\*:

\- Protocol: 4-wire SPI

\- Clock: 6.25MHz

\- Frame rate: ~30Hz

\- Initialization sequence included

\- Synchronization signals: `frame\_begin`, `sending\_pixels`



\#### 9. `Clock\_Generator`

\*\*File\*\*: `Clock\_Generator.v`

\*\*Function\*\*: Generate timing signals

\*\*Outputs\*\*:

\- `ce\_30hz`: 30Hz clock enable (renderer updates)

\- `ce\_2hz`: 2Hz clock enable (blinking elements)



\#### 10. `Button\_Debouncer`

\*\*File\*\*: `Button\_Debouncer.v`

\*\*Function\*\*: Eliminate mechanical switch bounce

\*\*Parameters\*\*:

\- Debounce time: 10ms

\- Output: Single-cycle pulse on press



---



\## State Machine Flow



\### Education Mode State Diagram



```

\[POWER ON] → EDU\_WELCOME

&nbsp;              │

&nbsp;              │ btnC

&nbsp;              ▼

&nbsp;          EDU\_SORTING ◄────┐

&nbsp;              │             │

&nbsp;              │ btnU        │ btnR/btnL

&nbsp;              │             │ (navigate)

&nbsp;              └─────────────┘

```



\### Tutorial Mode State Diagram



```

\[SW10 ON] → TUT\_WELCOME

&nbsp;              │

&nbsp;              │ btnC

&nbsp;              ▼

&nbsp;          TUT\_INPUT

&nbsp;              │

&nbsp;              │ btnC

&nbsp;              ▼

&nbsp;          TUT\_SORTING ◄──────────────┐

&nbsp;              │                      │

&nbsp;              ├─── (victory) ───→ TUT\_VICTORY

&nbsp;              │                      │

&nbsp;              ├─── (no hearts) ─→ TUT\_GAME\_OVER

&nbsp;              │                      │

&nbsp;              │ btnC ◄───────────────┘

&nbsp;              ▼

&nbsp;          TUT\_INPUT

```



\### Tutorial Sorting Sub-States



```

WAIT\_DIRECTION (yellow single box)

&nbsp;   │

&nbsp;   │ btnL or btnR

&nbsp;   ▼

SHOW\_COMPARISON (yellow dual boxes)

&nbsp;   │

&nbsp;   ▼

WAIT\_DECISION

&nbsp;   │

&nbsp;   ├─── btnC (swap) ───→ ANIMATE\_SWAP (blue boxes)

&nbsp;   │                          │

&nbsp;   │                          ▼

&nbsp;   │                     CHECK\_ADVANCE

&nbsp;   │

&nbsp;   ├─── btnD (keep) ───→ CHECK\_ADVANCE

&nbsp;   │

&nbsp;   └─── (wrong) ───────→ SHOW\_MISTAKE (red X)

&nbsp;                              │

&nbsp;                              ├─── (hearts > 0) ───→ WAIT\_DIRECTION

&nbsp;                              │

&nbsp;                              └─── (hearts = 0) ───→ GAME\_OVER

```



---



\## Display Output



\### Screen Layouts



\#### 1. Education Welcome Screen

\- \*\*Title\*\*: "Insertion Sort"

\- \*\*Graphics\*\*: Trees, clouds

\- \*\*Prompt\*\*: "Press Center to Start"

\- \*\*Colors\*\*: Green, brown, blue, white



\#### 2. Education Sorting Screen

\- \*\*Array Display\*\*: 6 boxes with numbers (0-5)

\- \*\*Red Line\*\*: Vertical line showing sorted boundary

\- \*\*Yellow Boxes\*\*: Elements being compared

\- \*\*Blue Boxes\*\*: Elements being swapped (temporary)

\- \*\*Green Boxes\*\*: All boxes turn green when fully sorted

\- \*\*Prompt\*\*: "L=Back R=Next U=Menu"



\#### 3. Tutorial Welcome Screen

\- \*\*Title\*\*: "Tutorial Mode"

\- \*\*Instructions\*\*: "Press Center to Start"

\- \*\*Graphics\*\*: Educational theme



\#### 4. Tutorial Input Screen

\- \*\*Array Display\*\*: 6 editable boxes (values 0-7)

\- \*\*Cursor\*\*: Highlighted box (current selection)

\- \*\*Prompt\*\*: "U=Inc D=Dec L/R=Move C=Start"



\#### 5. Tutorial Sorting Screen

\- \*\*Array Display\*\*: 6 boxes with current values

\- \*\*Yellow Boxes\*\*: Comparison highlights (single or dual)

\- \*\*Blue Boxes\*\*: Swap animation

\- \*\*Red Line\*\*: Sorted boundary

\- \*\*Hearts\*\*: 3 heart icons, filled based on `hearts\_remaining`

\- \*\*Red X\*\*: Large X displayed on mistakes

\- \*\*Prompts\*\*: Context-sensitive based on sub-state



\#### 6. Tutorial Victory Screen

\- \*\*Message\*\*: "Victory!" or "Sorted!"

\- \*\*Graphics\*\*: Celebration theme

\- \*\*Prompt\*\*: "Press Center"



\#### 7. Tutorial Game Over Screen

\- \*\*Message\*\*: "Game Over"

\- \*\*Graphics\*\*: Try again theme

\- \*\*Prompt\*\*: "Press Center to Retry"



\### Visual Indicators Reference



| Indicator | Color | Meaning | Duration |

|-----------|-------|---------|----------|

| Red Line | Red | Sorted partition boundary | Persistent |

| Yellow Single Box | Yellow | Current element (awaiting direction) | Persistent |

| Yellow Dual Boxes | Yellow | Elements being compared | Until decision made |

| Blue Boxes | Blue | Elements being swapped | 0.25 seconds |

| Green Boxes | Green | Array fully sorted | Persistent |

| Red X | Red | User mistake | 1.0 seconds |

| Heart (filled) | Red | Life remaining | Persistent |

| Heart (empty) | White outline | Life lost | Persistent |



---



\## Integration Guide



\### For Integration with Other Projects



\#### Key Integration Points



1\. \*\*Input Signals Required\*\*:

&nbsp;  - 100MHz clock source

&nbsp;  - System enable switch (any switch)

&nbsp;  - Mode select switch (any switch)

&nbsp;  - 5 button inputs (debounced or raw)



2\. \*\*Output Signals Provided\*\*:

&nbsp;  - OLED display signals (can drive any compatible OLED)

&nbsp;  - LED status indicators (2 used, 14 available)

&nbsp;  - 7-segment display (optional, can be removed)



3\. \*\*Customization Options\*\*:

&nbsp;  - \*\*Change initial array\*\*: Modify `Sort\_Engine.v` lines 115-120

&nbsp;  - \*\*Change array size\*\*: Requires structural changes to all engines

&nbsp;  - \*\*Adjust timing\*\*: Modify constants in `Clock\_Generator.v`

&nbsp;  - \*\*Modify colors\*\*: Change color parameters in `Oled\_Renderer.v` lines 58-61

&nbsp;  - \*\*Add/remove screens\*\*: Extend `Main\_FSM.v` state machine



\#### Integration Steps



1\. \*\*Pin Mapping\*\*:

&nbsp;  - Map `clk` to your clock source

&nbsp;  - Map `sw\_14` and `sw\_10` to available switches

&nbsp;  - Map button inputs to physical buttons

&nbsp;  - Map `JC\[7:0]` to your OLED PMOD connector



2\. \*\*Constraint File\*\* (.xdc):

&nbsp;  ```tcl

&nbsp;  # Clock (100MHz)

&nbsp;  set\_property PACKAGE\_PIN W5 \[get\_ports clk]

&nbsp;  set\_property IOSTANDARD LVCMOS33 \[get\_ports clk]



&nbsp;  # Switches

&nbsp;  set\_property PACKAGE\_PIN R2 \[get\_ports sw\_14]

&nbsp;  set\_property PACKAGE\_PIN U1 \[get\_ports sw\_10]

&nbsp;  set\_property IOSTANDARD LVCMOS33 \[get\_ports {sw\_\*}]



&nbsp;  # Buttons

&nbsp;  set\_property PACKAGE\_PIN U18 \[get\_ports btnC]

&nbsp;  set\_property PACKAGE\_PIN W19 \[get\_ports btnL]

&nbsp;  set\_property PACKAGE\_PIN T17 \[get\_ports btnR]

&nbsp;  set\_property PACKAGE\_PIN T18 \[get\_ports btnU]

&nbsp;  set\_property PACKAGE\_PIN U17 \[get\_ports btnD]

&nbsp;  set\_property IOSTANDARD LVCMOS33 \[get\_ports {btn\*}]



&nbsp;  # OLED (PMOD JC)

&nbsp;  set\_property PACKAGE\_PIN K17 \[get\_ports {JC\[0]}]

&nbsp;  set\_property PACKAGE\_PIN M18 \[get\_ports {JC\[1]}]

&nbsp;  set\_property PACKAGE\_PIN N17 \[get\_ports {JC\[2]}]

&nbsp;  set\_property PACKAGE\_PIN P18 \[get\_ports {JC\[3]}]

&nbsp;  set\_property PACKAGE\_PIN L17 \[get\_ports {JC\[4]}]

&nbsp;  set\_property PACKAGE\_PIN M19 \[get\_ports {JC\[5]}]

&nbsp;  set\_property PACKAGE\_PIN P17 \[get\_ports {JC\[6]}]

&nbsp;  set\_property PACKAGE\_PIN R18 \[get\_ports {JC\[7]}]

&nbsp;  set\_property IOSTANDARD LVCMOS33 \[get\_ports {JC\[\*]}]

&nbsp;  ```



3\. \*\*Combine with Other Modules\*\*:

&nbsp;  - Option A: Keep as separate entity, use switches for mode selection

&nbsp;  - Option B: Integrate into larger state machine, use `system\_enable` as module enable

&nbsp;  - Option C: Share OLED display, add display multiplexing logic



4\. \*\*Resource Sharing Considerations\*\*:

&nbsp;  - \*\*OLED Display\*\*: Can be time-multiplexed between modules

&nbsp;  - \*\*Buttons\*\*: Can be shared with other functions when module disabled

&nbsp;  - \*\*Clock Generator\*\*: Can be shared if other modules need 30Hz/2Hz timing

&nbsp;  - \*\*Frame Buffer\*\*: Consumes significant block RAM (6144 bytes)



\#### Testbench Integration



For simulation testing:



```verilog

module tb\_integration;

&nbsp;   reg clk, sw\_14, sw\_10;

&nbsp;   reg btnC, btnL, btnR, btnU, btnD;

&nbsp;   wire \[6:0] seg;

&nbsp;   wire \[3:0] an;

&nbsp;   wire dp;

&nbsp;   wire \[15:0] led;

&nbsp;   wire \[7:0] JC;



&nbsp;   sorting\_visualizer\_top uut (

&nbsp;       .clk(clk),

&nbsp;       .sw\_14(sw\_14),

&nbsp;       .sw\_10(sw\_10),

&nbsp;       .btnC(btnC), .btnL(btnL), .btnR(btnR), .btnU(btnU), .btnD(btnD),

&nbsp;       .seg(seg), .an(an), .dp(dp), .led(led), .JC(JC)

&nbsp;   );



&nbsp;   // Clock generation (100MHz)

&nbsp;   initial clk = 0;

&nbsp;   always #5 clk = ~clk;



&nbsp;   // Test sequence

&nbsp;   initial begin

&nbsp;       // Initialize

&nbsp;       sw\_14 = 0; sw\_10 = 0;

&nbsp;       btnC = 0; btnL = 0; btnR = 0; btnU = 0; btnD = 0;



&nbsp;       // Enable system

&nbsp;       #100 sw\_14 = 1;



&nbsp;       // Test education mode...

&nbsp;       // Test tutorial mode...

&nbsp;   end

endmodule

```



---



\## Timing Specifications



\### Clock Domains



| Clock | Frequency | Source | Usage |

|-------|-----------|--------|-------|

| `clk` | 100MHz | External | System clock |

| `clk\_6p25mhz` | 6.25MHz | Divider (÷16) | OLED SPI clock |

| `ce\_30hz` | 30Hz | Clock Generator | Renderer updates |

| `ce\_2hz` | 2Hz | Clock Generator | Blinking elements |

| `clk\_1khz` | 1kHz | Divider (÷50000) | 7-segment multiplexing |



\### Animation Timings



| Animation | Duration | Implementation |

|-----------|----------|----------------|

| Swap (Education) | 0.25 seconds | 25,000,000 cycles @ 100MHz |

| Swap (Tutorial) | 0.25 seconds | 15,000,000 cycles @ 100MHz |

| Mistake Display | 1.0 seconds | 50,000,000 cycles @ 100MHz |

| Button Debounce | 10ms | 1,000,000 cycles @ 100MHz |

| Frame Refresh | ~30Hz | OLED driver timing |



\### Critical Paths



1\. \*\*Renderer Pipeline\*\*: 3 stages, all at 100MHz

2\. \*\*Frame Buffer\*\*: Dual-port synchronous RAM

3\. \*\*OLED Driver\*\*: SPI state machine at 6.25MHz

4\. \*\*FSM Transitions\*\*: Single-cycle, synchronous



---



\## Data Structures



\### Array Representation



\*\*Format\*\*: 6 elements, 3-bit values (0-7)



\*\*Education Mode Default\*\*:

```

Index:  0  1  2  3  4  5

Value: \[0, 3, 1, 4, 2, 5]

```



\*\*Tutorial Mode\*\*: User-defined (0-7 per element)



\### History Buffer (Sort\_Engine)



\*\*Capacity\*\*: 32 states

\*\*Contents\*\*:

\- `current\_array\_\[0-5]`: Array snapshot

\- `red\_line\_pos`: Partition position

\- `i\_index`, `j\_index`: Algorithm state

\- `compare\_idx1/2`, `swap\_idx1/2`: Visual indicators

\- `is\_comparing`: Two-step flag



\*\*Pointer\*\*: 5-bit `history\_pointer` (0-31)



\### State Encoding



\*\*Main\_FSM States\*\* (3-bit):

```verilog

000: EDU\_WELCOME

001: EDU\_SORTING

010: TUT\_WELCOME

011: TUT\_INPUT

100: TUT\_READY (unused)

101: TUT\_SORTING

110: TUT\_GAME\_OVER

111: TUT\_VICTORY

```



\*\*Tutorial\_Sort\_Engine States\*\* (3-bit):

```verilog

000: WAIT\_DIRECTION

001: SHOW\_COMPARISON

010: WAIT\_DECISION

011: ANIMATE\_SWAP

100: SHOW\_MISTAKE

101: CHECK\_ADVANCE

110: VICTORY

111: GAME\_OVER

```



---



\## Functional Summary



\### Inputs Summary



| Input | Function | Active Level | Modes |

|-------|----------|--------------|-------|

| `clk` | System clock | - | All |

| `sw\_14` | Master enable | HIGH | All |

| `sw\_10` | Tutorial mode | HIGH | Tutorial |

| `btnC` | Confirm/Swap | Press | Both |

| `btnL` | Previous/Left/Compare Left | Press | Both |

| `btnR` | Next/Right/Compare Right | Press | Both |

| `btnU` | Menu/Increment/Restart | Press | Both |

| `btnD` | Decrement/Keep | Press | Tutorial |



\### Outputs Summary



| Output | Function | Signal Type | Description |

|--------|----------|-------------|-------------|

| `seg\[6:0]` | 7-segment display | Active LOW | Displays "InSt" |

| `an\[3:0]` | Digit select | Active LOW | Multiplexed display |

| `dp` | Decimal point | Active LOW | Always OFF (HIGH) |

| `led\[14]` | System enabled | Active HIGH | System status |

| `led\[10]` | Tutorial mode | Active HIGH | Mode indicator |

| `JC\[7:0]` | OLED interface | SPI signals | Display output |



\### Module I/O Count



| Module | Inputs | Outputs | Bidirectional |

|--------|--------|---------|---------------|

| `sorting\_visualizer\_top` | 7 | 29 | 0 |

| `Main\_FSM` | 8 | 12 | 0 |

| `Sort\_Engine` | 4 | 13 | 0 |

| `Tutorial\_Input\_Engine` | 6 | 7 | 0 |

| `Tutorial\_Sort\_Engine` | 16 | 18 | 0 |

| `Oled\_Renderer` | 38 | 3 | 0 |

| `Button\_Debouncer` | 2 | 1 | 0 |



---



\## File Listing



\### Source Files



| File | Lines | Purpose |

|------|-------|---------|

| `sorting\_visualizer\_top.v` | 446 | Top-level integration |

| `Main\_FSM.v` | 240 | State machine controller |

| `Sort\_Engine.v` | 261 | Education mode algorithm |

| `Tutorial\_Input\_Engine.v` | 96 | Tutorial array input |

| `Tutorial\_Sort\_Engine.v` | 425 | Tutorial sorting game |

| `Oled\_Renderer.v` | ~1500 | Graphics rendering |

| `Frame\_Buffer.v` | ~50 | Video memory |

| `Oled\_Display.v` | ~300 | OLED SPI driver |

| `Button\_Debouncer.v` | 83 | Input debouncing |

| `Clock\_Generator.v` | ~100 | Timing generation |

| `clock\_divider.v` | ~50 | Clock division |

| `Font\_ROM\_4x6.v` | ~200 | Small font data |

| `Font\_ROM\_5x7\_Bold.v` | ~300 | Large font data |



\*\*Total Lines of Code\*\*: ~4,000



---



\## Revision History



| Version | Date | Author | Changes |

|---------|------|--------|---------|

| 1.0 | 2025-10-18 | - | Initial implementation |

| 1.1 | 2025-10-31 | - | Added Tutorial Mode with game mechanics |

| 2.0 | 2025-11-06 | - | Comprehensive documentation for integration |



---



\## Contact and Support



For integration support or questions:

\- Review this documentation thoroughly

\- Check module interfaces in source files

\- Examine signal timing in simulation

\- Validate pin assignments in constraints file



---



\## Appendix: Quick Reference



\### Startup Sequence



1\. Apply power to Basys3 board

2\. Program FPGA with bitstream

3\. Set SW14 to ON position

4\. LED\[14] illuminates (system active)

5\. "InSt" appears on 7-segment display

6\. OLED shows welcome screen

7\. For Tutorial Mode: Set SW10 to ON, LED\[10] illuminates



\### Troubleshooting



| Issue | Check | Solution |

|-------|-------|----------|

| Display blank | SW14, OLED connections | Verify enable switch, check PMOD JC wiring |

| No button response | Debouncing, SW14 | Verify system enabled, check button connections |

| Wrong mode active | SW10, LED\[10] | Toggle SW10, observe LED\[10] indicator |

| Display corruption | Clock frequency, SPI timing | Verify 6.25MHz clock, check timing constraints |



---



\*\*End of Documentation\*\*

