\# FPGA Selection Sort Visualizer



\## 1. Project Overview



\*\*Project Name:\*\* Selection Sort Visualizer

\*\*Purpose:\*\* To visually and interactively demonstrate the "Selection Sort" algorithm on an FPGA, using a Pmod OLED display.

\*\*Core Function:\*\* The system sorts a 6-element array of 3-bit numbers (values 0–7).



\### Primary Features



\#### Dual Mode Operation



\- \*\*Demo Mode:\*\* A manually-stepped visual demonstration of the algorithm's execution on a predefined array.

\- \*\*Tutorial Mode:\*\* An interactive test where the user must correctly perform the steps of a selection sort (input an array, find the minimum, and select the swap position).



\*\*Visual Interface:\*\* All visualization is rendered on a 96x64 RGB Pmod OLED display.

\*\*Hardware:\*\* Designed for an FPGA board (like a Basys 3) with at least 16 switches, 5 push-buttons (Up, Down, Left, Right, Center), 16 LEDs, and a 4-digit 7-segment display.



---



\## 2. System Architecture



The project follows a modular, hierarchical design. The top-level module `sort\_visualizer\_top` connects all I/O and instantiates the following key sub-modules:



\- \*\*sort\_visualizer\_top:\*\* The top-level wrapper that maps FPGA inputs/outputs to the core logic and peripherals.

\- \*\*selection\_sort\_controller (The "Brain"):\*\* Primary state machine managing the mode (Demo/Tutorial), algorithm states, and button input logic.

\- \*\*display\_generator\_comb (The "Artist"):\*\* Purely combinational renderer converting state information into pixel colors for the OLED.

\- \*\*Oled\_Display:\*\* Predefined display driver for SPI communication with the OLED screen.

\- \*\*Clock Dividers (clock\_divider, clock\_divider\_1ms):\*\* Generate the necessary clock frequencies.

\- \*\*text\_animator:\*\* Produces an animated "breathing" text effect in Demo Mode.

\- \*\*seven\_segment\_display:\*\* Drives the 7-segment display to show "S-O-R-T" when enabled.



---



\## 3. Interface Definition (Inputs \& Outputs)



This section details all external I/O as defined in `sort\_visualizer\_top.v` and `consts.xdc`.



\### 3.1 Inputs



| Port | Name | consts.xdc Pin(s) | Function |

|------|------|-------------------|-----------|

| `clk` | System Clock | W5 | 100MHz main clock |

| `sw\[13]` | Master Enable | U1 | ON/OFF switch. If OFF, system idle. Must be ON for any functionality. |

| `sw\[10]` | Mode Select | T2 | OFF: Demo Mode; ON: Tutorial Mode |

| `sw\[7]` | Tutorial Reset | W13 | Resets tutorial to "WELCOME" screen when in Tutorial Mode |

| `sw\[15:0]` | Other Switches | varies | Unused switches mirror to corresponding LEDs |

| `btnC` | Center Button | U18 | Confirm/Reset — context-dependent |

| `btnU` | Up Button | T18 | Start/Increment — context-dependent |

| `btnD` | Down Button | U17 | Decrement during number input |

| `btnL` | Left Button | W19 | Move cursor left |

| `btnR` | Right Button | T17 | Step (Demo) / Move cursor (Tutorial) |



\### 3.2 Outputs



| Port | Name | consts.xdc Pin(s) | Function |

|------|------|--------------------|-----------|

| `JC\[7:0]` | Pmod Data | K17, M18, etc. | Pmod OLED Display |

| `seg\[6:0]` | 7-Seg Cathodes | W7, W6, etc. | Display segments |

| `an\[3:0]` | 7-Seg Anodes | U2, U4, etc. | Display "S-O-R-T" |

| `led\[15:0]` | LEDs | U16, E19, etc. | Mirror switches or indicate tutorial progress |



---



\## 4. Core Functionality \& Modes



\### Master Enable



`sw\[13]` must be ON to activate the system.



\### 4.1 Mode 1: Demo Mode (`sw\[10] = OFF`)



Demonstrates selection sort on a fixed array `\[0,3,1,4,2,5]`. Requires user input (`btnR`) to manually step through.



\*\*State Flow:\*\*

\- `INTRO\_SELECTION` / `INTRO\_SORT`: Animated title.

\- `INTRO\_WAIT`: Waits for `btnU` to begin.

\- `INIT`: Displays initial array and sets pointers.

\- `FIND\_MIN\_COMPARE`: Highlights comparisons automatically.

\- `SHOW\_MIN`: Displays found minimum. Waits for `btnR`.

\- `SHOW\_SWAP`: Shows swap action. Waits for `btnR`.

\- `SWAP\_COMPLETE`: Visually swap elements.

\- `INCREMENT\_I`: Move to next iteration. Waits for `btnR`.

\- `DONE`: Displays sorted array and "DONE!".



Press `btnC` anytime to reset to intro.



\### 4.2 Mode 2: Tutorial Mode (`sw\[10] = ON`)



Interactive mode where user performs selection sort manually.



\*\*State Flow:\*\*

\- `TUTORIAL\_WELCOME` → `TUTORIAL\_TO` → `TUTORIAL\_TUTORIAL` → `TUTORIAL\_MODE`

\- `TUTORIAL\_INPUT`: User inputs 6 numbers (0–7) using buttons.

\- `TUTORIAL\_BEGIN`: Starts test animation.

\- `TUTORIAL\_TEST\_INIT` → `TUTORIAL\_FIND\_MIN` → `TUTORIAL\_SELECT\_SWAP`

\- Feedback:

&nbsp; - `TUTORIAL\_CORRECT`: Success; increments progress LEDs.

&nbsp; - `TUTORIAL\_WRONG`: Mistake; retry.

&nbsp; - `TUTORIAL\_FAILED`: 3 strikes = reset.

&nbsp; - `TUTORIAL\_WELL\_DONE`: Successfully completed.



Flip `sw\[7]` ON at any point to reset.



---



\## 5. Module-by-Module Detail



\### selection\_sort\_controller.v

Core FSM managing both Demo and Tutorial. Driven by 1kHz clock.



\- \*\*Demo FSM States:\*\* `IDLE`, `INTRO\_SELECTION`, `INTRO\_SORT`, `INTRO\_WAIT`, `INIT`, `FIND\_MIN\_COMPARE`, `SHOW\_MIN`, `SHOW\_SWAP`, `SWAP\_COMPLETE`, `INCREMENT\_I`, `DONE`.

\- \*\*Tutorial FSM States:\*\* `TUTORIAL\_WELCOME`, `TUTORIAL\_TO`, `TUTORIAL\_TUTORIAL`, `TUTORIAL\_MODE`, `TUTORIAL\_ALL`, `TUTORIAL\_INPUT`, `TUTORIAL\_BEGIN`, `TUTORIAL\_TEST\_INIT`, `TUTORIAL\_FIND\_MIN`, `TUTORIAL\_SELECT\_SWAP`, `TUTORIAL\_CORRECT`, `TUTORIAL\_WRONG`, `TUTORIAL\_WELL\_DONE`, `TUTORIAL\_FAILED`.



Tracks `current\_i`, `tutorial\_progress`, and `wrong\_attempt\_count`.



\### display\_generator.v

Contains `display\_generator\_comb` — a purely combinational pixel renderer.

Generates RGB pixel data based on system state and pixel index.



\### Clock Modules

\- \*\*clock\_divider\_1ms.v:\*\* Divides 100MHz clock by 50,000 → 1kHz signal.

\- \*\*clock\_divider.v:\*\* Used to generate a 12.5MHz clock → further divided to 6.25MHz for OLED.



---



\## 6. Integration Notes



\- \*\*Primary Control:\*\* `sw\[13]` (Enable), `sw\[10]` (Mode)

\- \*\*Simulation:\*\* Simulate button signals to automate demo/tutorial.

\- \*\*Monitoring:\*\* Track `sort\_complete`, `tutorial\_progress`, `wrong\_attempt\_count`, and `array\_flat`.

\- \*\*Display Conflict:\*\* If sharing OLED, multiplex `display\_generator\_comb`.

\- \*\*Timing:\*\* All logic synchronized to `clk\_1ms` (1ms tick).



