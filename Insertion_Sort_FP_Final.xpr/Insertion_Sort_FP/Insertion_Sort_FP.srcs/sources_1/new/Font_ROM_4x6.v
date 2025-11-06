`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Font_ROM_4x6.v - 4x6 Pixel Font for Text Rendering
// CLEANED AND DEDUPLICATED VERSION
//////////////////////////////////////////////////////////////////////////////////

module Font_ROM_4x6(
    input [6:0] char_code,     // ASCII character code (0-127)
    input [2:0] row,           // Row within character (0-5)
    output reg [3:0] pixel_row // 4 pixels for this row (1=foreground, 0=background)
);

    always @(*) begin
        case (char_code)

            // Space (32)
            7'd32: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b0000;
                    3'd2: pixel_row = 4'b0000; 3'd3: pixel_row = 4'b0000;
                    3'd4: pixel_row = 4'b0000; 3'd5: pixel_row = 4'b0000;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // '!' (33)
            7'd33: begin
                case (row)
                    3'd0: pixel_row = 4'b0110; 3'd1: pixel_row = 4'b0110;
                    3'd2: pixel_row = 4'b0110; 3'd3: pixel_row = 4'b0110;
                    3'd4: pixel_row = 4'b0000; 3'd5: pixel_row = 4'b0110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // '0' (48)
            7'd48: begin
                case (row)
                    3'd0: pixel_row = 4'b0110; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b1001; 3'd3: pixel_row = 4'b1001;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b0110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // '1' (49)
            7'd49: begin
                case (row)
                    3'd0: pixel_row = 4'b0010; 3'd1: pixel_row = 4'b0110;
                    3'd2: pixel_row = 4'b0010; 3'd3: pixel_row = 4'b0010;
                    3'd4: pixel_row = 4'b0010; 3'd5: pixel_row = 4'b0111;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // '2' (50)
            7'd50: begin
                case (row)
                    3'd0: pixel_row = 4'b0110; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b0001; 3'd3: pixel_row = 4'b0010;
                    3'd4: pixel_row = 4'b0100; 3'd5: pixel_row = 4'b1111;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // '3' (51)
            7'd51: begin
                case (row)
                    3'd0: pixel_row = 4'b1110; 3'd1: pixel_row = 4'b0001;
                    3'd2: pixel_row = 4'b0110; 3'd3: pixel_row = 4'b0001;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b0110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // '4' (52)
            7'd52: begin
                case (row)
                    3'd0: pixel_row = 4'b0010; 3'd1: pixel_row = 4'b0110;
                    3'd2: pixel_row = 4'b1010; 3'd3: pixel_row = 4'b1111;
                    3'd4: pixel_row = 4'b0010; 3'd5: pixel_row = 4'b0010;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // '5' (53)
            7'd53: begin
                case (row)
                    3'd0: pixel_row = 4'b1111; 3'd1: pixel_row = 4'b1000;
                    3'd2: pixel_row = 4'b1110; 3'd3: pixel_row = 4'b0001;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b0110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // ':' (58)
            7'd58: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b0110;
                    3'd2: pixel_row = 4'b0110; 3'd3: pixel_row = 4'b0000;
                    3'd4: pixel_row = 4'b0110; 3'd5: pixel_row = 4'b0110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // '?' (63)
            7'd63: begin
                case (row)
                    3'd0: pixel_row = 4'b0110; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b0010; 3'd3: pixel_row = 4'b0100;
                    3'd4: pixel_row = 4'b0000; 3'd5: pixel_row = 4'b0100;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'A' (65)
            7'd65: begin
                case (row)
                    3'd0: pixel_row = 4'b0110; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b1001; 3'd3: pixel_row = 4'b1111;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b1001;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'B' (66)
            7'd66: begin
                case (row)
                    3'd0: pixel_row = 4'b1110; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b1110; 3'd3: pixel_row = 4'b1001;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b1110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'C' (67)
            7'd67: begin
                case (row)
                    3'd0: pixel_row = 4'b0111; 3'd1: pixel_row = 4'b1000;
                    3'd2: pixel_row = 4'b1000; 3'd3: pixel_row = 4'b1000;
                    3'd4: pixel_row = 4'b1000; 3'd5: pixel_row = 4'b0111;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'D' (68)
            7'd68: begin
                case (row)
                    3'd0: pixel_row = 4'b1110; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b1001; 3'd3: pixel_row = 4'b1001;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b1110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'E' (69)
            7'd69: begin
                case (row)
                    3'd0: pixel_row = 4'b1111; 3'd1: pixel_row = 4'b1000;
                    3'd2: pixel_row = 4'b1110; 3'd3: pixel_row = 4'b1000;
                    3'd4: pixel_row = 4'b1000; 3'd5: pixel_row = 4'b1111;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'G' (71)
            7'd71: begin
                case (row)
                    3'd0: pixel_row = 4'b0111; 3'd1: pixel_row = 4'b1000;
                    3'd2: pixel_row = 4'b1000; 3'd3: pixel_row = 4'b1011;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b0111;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'I' (73)
            7'd73: begin
                case (row)
                    3'd0: pixel_row = 4'b0111; 3'd1: pixel_row = 4'b0010;
                    3'd2: pixel_row = 4'b0010; 3'd3: pixel_row = 4'b0010;
                    3'd4: pixel_row = 4'b0010; 3'd5: pixel_row = 4'b0111;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'K' (75)
            7'd75: begin
                case (row)
                    3'd0: pixel_row = 4'b1001; 3'd1: pixel_row = 4'b1010;
                    3'd2: pixel_row = 4'b1100; 3'd3: pixel_row = 4'b1010;
                    3'd4: pixel_row = 4'b1010; 3'd5: pixel_row = 4'b1001;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'L' (76)
            7'd76: begin
                case (row)
                    3'd0: pixel_row = 4'b1000; 3'd1: pixel_row = 4'b1000;
                    3'd2: pixel_row = 4'b1000; 3'd3: pixel_row = 4'b1000;
                    3'd4: pixel_row = 4'b1000; 3'd5: pixel_row = 4'b1111;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'M' (77)
            7'd77: begin
                case (row)
                    3'd0: pixel_row = 4'b1001; 3'd1: pixel_row = 4'b1111;
                    3'd2: pixel_row = 4'b1111; 3'd3: pixel_row = 4'b1001;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b1001;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'N' (78)
            7'd78: begin
                case (row)
                    3'd0: pixel_row = 4'b1001; 3'd1: pixel_row = 4'b1101;
                    3'd2: pixel_row = 4'b1111; 3'd3: pixel_row = 4'b1011;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b1001;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'O' (79)
            7'd79: begin
                case (row)
                    3'd0: pixel_row = 4'b0110; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b1001; 3'd3: pixel_row = 4'b1001;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b0110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'P' (80)
            7'd80: begin
                case (row)
                    3'd0: pixel_row = 4'b1110; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b1001; 3'd3: pixel_row = 4'b1110;
                    3'd4: pixel_row = 4'b1000; 3'd5: pixel_row = 4'b1000;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'R' (82)
            7'd82: begin
                case (row)
                    3'd0: pixel_row = 4'b1110; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b1001; 3'd3: pixel_row = 4'b1110;
                    3'd4: pixel_row = 4'b1010; 3'd5: pixel_row = 4'b1001;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'S' (83)
            7'd83: begin
                case (row)
                    3'd0: pixel_row = 4'b0111; 3'd1: pixel_row = 4'b1000;
                    3'd2: pixel_row = 4'b0110; 3'd3: pixel_row = 4'b0001;
                    3'd4: pixel_row = 4'b0001; 3'd5: pixel_row = 4'b1110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'T' (84)
            7'd84: begin
                case (row)
                    3'd0: pixel_row = 4'b1111; 3'd1: pixel_row = 4'b0110;
                    3'd2: pixel_row = 4'b0110; 3'd3: pixel_row = 4'b0110;
                    3'd4: pixel_row = 4'b0110; 3'd5: pixel_row = 4'b0110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'U' (85)
            7'd85: begin
                case (row)
                    3'd0: pixel_row = 4'b1001; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b1001; 3'd3: pixel_row = 4'b1001;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b0110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'V' (86)
            7'd86: begin
                case (row)
                    3'd0: pixel_row = 4'b1001; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b1001; 3'd3: pixel_row = 4'b1001;
                    3'd4: pixel_row = 4'b0110; 3'd5: pixel_row = 4'b0110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'W' (87)
            7'd87: begin
                case (row)
                    3'd0: pixel_row = 4'b1001; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b1001; 3'd3: pixel_row = 4'b1111;
                    3'd4: pixel_row = 4'b1111; 3'd5: pixel_row = 4'b1001;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'Y' (89)
            7'd89: begin
                case (row)
                    3'd0: pixel_row = 4'b1001; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b0110; 3'd3: pixel_row = 4'b0110;
                    3'd4: pixel_row = 4'b0110; 3'd5: pixel_row = 4'b0110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'a' (97)
            7'd97: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b0110;
                    3'd2: pixel_row = 4'b0001; 3'd3: pixel_row = 4'b0111;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b0111;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'b' (98)
            7'd98: begin
                case (row)
                    3'd0: pixel_row = 4'b1000; 3'd1: pixel_row = 4'b1000;
                    3'd2: pixel_row = 4'b1110; 3'd3: pixel_row = 4'b1001;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b1110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'c' (99)
            7'd99: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b0000;
                    3'd2: pixel_row = 4'b0111; 3'd3: pixel_row = 4'b1000;
                    3'd4: pixel_row = 4'b1000; 3'd5: pixel_row = 4'b0111;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'd' (100)
            7'd100: begin
                case (row)
                    3'd0: pixel_row = 4'b0001; 3'd1: pixel_row = 4'b0001;
                    3'd2: pixel_row = 4'b0111; 3'd3: pixel_row = 4'b1001;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b0111;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'e' (101)
            7'd101: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b0110;
                    3'd2: pixel_row = 4'b1001; 3'd3: pixel_row = 4'b1111;
                    3'd4: pixel_row = 4'b1000; 3'd5: pixel_row = 4'b0111;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'f' (102)
            7'd102: begin
                case (row)
                    3'd0: pixel_row = 4'b0011; 3'd1: pixel_row = 4'b0100;
                    3'd2: pixel_row = 4'b1110; 3'd3: pixel_row = 4'b0100;
                    3'd4: pixel_row = 4'b0100; 3'd5: pixel_row = 4'b0100;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'g' (103)
            7'd103: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b0111;
                    3'd2: pixel_row = 4'b1001; 3'd3: pixel_row = 4'b0111;
                    3'd4: pixel_row = 4'b0001; 3'd5: pixel_row = 4'b0110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'h' (104)
            7'd104: begin
                case (row)
                    3'd0: pixel_row = 4'b1000; 3'd1: pixel_row = 4'b1000;
                    3'd2: pixel_row = 4'b1110; 3'd3: pixel_row = 4'b1001;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b1001;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'i' (105)
            7'd105: begin
                case (row)
                    3'd0: pixel_row = 4'b0010; 3'd1: pixel_row = 4'b0000;
                    3'd2: pixel_row = 4'b0110; 3'd3: pixel_row = 4'b0010;
                    3'd4: pixel_row = 4'b0010; 3'd5: pixel_row = 4'b0111;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'k' (107)
            7'd107: begin
                case (row)
                    3'd0: pixel_row = 4'b1000; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b1010; 3'd3: pixel_row = 4'b1100;
                    3'd4: pixel_row = 4'b1010; 3'd5: pixel_row = 4'b1001;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'l' (108)
            7'd108: begin
                case (row)
                    3'd0: pixel_row = 4'b1000; 3'd1: pixel_row = 4'b1000;
                    3'd2: pixel_row = 4'b1000; 3'd3: pixel_row = 4'b1000;
                    3'd4: pixel_row = 4'b1000; 3'd5: pixel_row = 4'b1110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'm' (109)
            7'd109: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b0000;
                    3'd2: pixel_row = 4'b1110; 3'd3: pixel_row = 4'b1111;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b1001;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'n' (110)
            7'd110: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b0000;
                    3'd2: pixel_row = 4'b1110; 3'd3: pixel_row = 4'b1001;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b1001;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'o' (111)
            7'd111: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b0000;
                    3'd2: pixel_row = 4'b0110; 3'd3: pixel_row = 4'b1001;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b0110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'p' (112)
            7'd112: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b1110;
                    3'd2: pixel_row = 4'b1001; 3'd3: pixel_row = 4'b1110;
                    3'd4: pixel_row = 4'b1000; 3'd5: pixel_row = 4'b1000;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'r' (114)
            7'd114: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b0000;
                    3'd2: pixel_row = 4'b1011; 3'd3: pixel_row = 4'b1100;
                    3'd4: pixel_row = 4'b1000; 3'd5: pixel_row = 4'b1000;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 's' (115)
            7'd115: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b0111;
                    3'd2: pixel_row = 4'b1000; 3'd3: pixel_row = 4'b0110;
                    3'd4: pixel_row = 4'b0001; 3'd5: pixel_row = 4'b1110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 't' (116)
            7'd116: begin
                case (row)
                    3'd0: pixel_row = 4'b0100; 3'd1: pixel_row = 4'b0100;
                    3'd2: pixel_row = 4'b1110; 3'd3: pixel_row = 4'b0100;
                    3'd4: pixel_row = 4'b0100; 3'd5: pixel_row = 4'b0011;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'u' (117)
            7'd117: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b0000;
                    3'd2: pixel_row = 4'b1001; 3'd3: pixel_row = 4'b1001;
                    3'd4: pixel_row = 4'b1001; 3'd5: pixel_row = 4'b0111;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'w' (119)
            7'd119: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b1001; 3'd3: pixel_row = 4'b1111;
                    3'd4: pixel_row = 4'b1111; 3'd5: pixel_row = 4'b1001;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'x' (120)
            7'd120: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b0110; 3'd3: pixel_row = 4'b0110;
                    3'd4: pixel_row = 4'b0110; 3'd5: pixel_row = 4'b1001;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // 'y' (121)
            7'd121: begin
                case (row)
                    3'd0: pixel_row = 4'b0000; 3'd1: pixel_row = 4'b1001;
                    3'd2: pixel_row = 4'b1001; 3'd3: pixel_row = 4'b0111;
                    3'd4: pixel_row = 4'b0001; 3'd5: pixel_row = 4'b0110;
                    default: pixel_row = 4'b0000;
                endcase
            end

            // Default: return blank for any undefined character
            default: begin
                pixel_row = 4'b0000;
            end

        endcase
    end

endmodule
