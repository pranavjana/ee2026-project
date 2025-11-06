`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.10.2025 22:22:32
// Design Name: 
// Module Name: Button_Debouncer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Button_Debouncer(
    input clk_100mhz,           // 100MHz system clock
    input btn_in,               // Raw button input (noisy)
    output reg btn_press_pulse  // Clean single-cycle output pulse
);

    //==========================================================================
    // Debounce Parameters
    //==========================================================================
    // At 100MHz, we want ~10ms debounce time
    // 10ms = 0.01s * 100,000,000 Hz = 1,000,000 cycles
    // We'll use a 20-bit shift register and check when all bits are stable
    
    parameter DEBOUNCE_CYCLES = 1000000;  // 10ms at 100MHz
    
    //==========================================================================
    // Internal Registers
    //==========================================================================
    reg [19:0] shift_reg;       // Shift register to store button history
    reg btn_state;              // Current stable button state
    reg btn_state_prev;         // Previous button state (for edge detection)
    reg [19:0] counter;         // Counter for debounce timing
    
    //==========================================================================
    // Debouncing Logic
    //==========================================================================
    always @(posedge clk_100mhz) begin
        // Shift in the current button value
        shift_reg <= {shift_reg[18:0], btn_in};
        
        // Update counter for timing
        if (counter < DEBOUNCE_CYCLES)
            counter <= counter + 1;
        else
            counter <= DEBOUNCE_CYCLES;
        
        // Check if button has been stable (all 1s or all 0s in shift register)
        if (counter >= DEBOUNCE_CYCLES) begin
            if (shift_reg == 20'hFFFFF) begin
                // Button stable high
                btn_state <= 1;
            end
            else if (shift_reg == 20'h00000) begin
                // Button stable low
                btn_state <= 0;
            end
        end
        
        // Store previous state for edge detection
        btn_state_prev <= btn_state;
        
        // Generate single pulse on rising edge (button press)
        btn_press_pulse <= (btn_state && !btn_state_prev);
        
        // Reset counter if button state changes
        if (btn_in != shift_reg[19])
            counter <= 0;
    end

endmodule
