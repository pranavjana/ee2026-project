`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.10.2025 00:45:19
// Design Name: 
// Module Name: Tutorial_Validator
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


module Tutorial_Validator(
    input [2:0] array_j_minus_1,    // Value at position j-1
    input [2:0] array_j,            // Value at position j
    input user_action,              // 0=keep, 1=swap
    output reg is_correct
);
    // Validation logic:
    // SWAP is correct when: array[j] < array[j-1] (need to move j backward)
    // KEEP is correct when: array[j] >= array[j-1] (j is in correct position)
    
    always @(*) begin
        case (user_action)
            1'b1: begin 
                // User chose SWAP
                // Correct if current element is smaller than previous
                is_correct = (array_j < array_j_minus_1);
            end
            1'b0: begin 
                // User chose KEEP
                // Correct if current element is greater than or equal to previous
                is_correct = (array_j >= array_j_minus_1);
            end
        endcase
    end
endmodule
