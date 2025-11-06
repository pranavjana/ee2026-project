`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Bold 5x7 Pixel Font for Education Mode
// Thicker, more visible characters
//////////////////////////////////////////////////////////////////////////////////

module Font_ROM_5x7_Bold(
    input [6:0] char_code,
    input [2:0] row,
    output reg [4:0] pixel_row
);

always @(*) begin
    case (char_code)
        // Space
        7'd32: begin
            case (row)
                3'd0: pixel_row = 5'b00000;
                3'd1: pixel_row = 5'b00000;
                3'd2: pixel_row = 5'b00000;
                3'd3: pixel_row = 5'b00000;
                3'd4: pixel_row = 5'b00000;
                3'd5: pixel_row = 5'b00000;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // ! (exclamation)
        7'd33: begin
            case (row)
                3'd0: pixel_row = 5'b01110;
                3'd1: pixel_row = 5'b01110;
                3'd2: pixel_row = 5'b01110;
                3'd3: pixel_row = 5'b00000;
                3'd4: pixel_row = 5'b01110;
                3'd5: pixel_row = 5'b01110;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // : (colon)
        7'd58: begin
            case (row)
                3'd0: pixel_row = 5'b00000;
                3'd1: pixel_row = 5'b01110;
                3'd2: pixel_row = 5'b01110;
                3'd3: pixel_row = 5'b00000;
                3'd4: pixel_row = 5'b01110;
                3'd5: pixel_row = 5'b01110;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // A
        7'd65: begin
            case (row)
                3'd0: pixel_row = 5'b01110;
                3'd1: pixel_row = 5'b11111;
                3'd2: pixel_row = 5'b11011;
                3'd3: pixel_row = 5'b11111;
                3'd4: pixel_row = 5'b11011;
                3'd5: pixel_row = 5'b11011;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // B
        7'd66: begin
            case (row)
                3'd0: pixel_row = 5'b11110;
                3'd1: pixel_row = 5'b11011;
                3'd2: pixel_row = 5'b11110;
                3'd3: pixel_row = 5'b11011;
                3'd4: pixel_row = 5'b11011;
                3'd5: pixel_row = 5'b11110;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // C
        7'd67: begin
            case (row)
                3'd0: pixel_row = 5'b01111;
                3'd1: pixel_row = 5'b11000;
                3'd2: pixel_row = 5'b11000;
                3'd3: pixel_row = 5'b11000;
                3'd4: pixel_row = 5'b11000;
                3'd5: pixel_row = 5'b01111;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // D
        7'd68: begin
            case (row)
                3'd0: pixel_row = 5'b11110;
                3'd1: pixel_row = 5'b11011;
                3'd2: pixel_row = 5'b11011;
                3'd3: pixel_row = 5'b11011;
                3'd4: pixel_row = 5'b11011;
                3'd5: pixel_row = 5'b11110;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // E
        7'd69: begin
            case (row)
                3'd0: pixel_row = 5'b11111;
                3'd1: pixel_row = 5'b11000;
                3'd2: pixel_row = 5'b11110;
                3'd3: pixel_row = 5'b11000;
                3'd4: pixel_row = 5'b11000;
                3'd5: pixel_row = 5'b11111;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // I
        7'd73: begin
            case (row)
                3'd0: pixel_row = 5'b11111;
                3'd1: pixel_row = 5'b01110;
                3'd2: pixel_row = 5'b01110;
                3'd3: pixel_row = 5'b01110;
                3'd4: pixel_row = 5'b01110;
                3'd5: pixel_row = 5'b11111;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // L
        7'd76: begin
            case (row)
                3'd0: pixel_row = 5'b11000;
                3'd1: pixel_row = 5'b11000;
                3'd2: pixel_row = 5'b11000;
                3'd3: pixel_row = 5'b11000;
                3'd4: pixel_row = 5'b11000;
                3'd5: pixel_row = 5'b11111;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // N
        7'd78: begin
            case (row)
                3'd0: pixel_row = 5'b11011;
                3'd1: pixel_row = 5'b11111;
                3'd2: pixel_row = 5'b11111;
                3'd3: pixel_row = 5'b11011;
                3'd4: pixel_row = 5'b11011;
                3'd5: pixel_row = 5'b11011;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // O
        7'd79: begin
            case (row)
                3'd0: pixel_row = 5'b01110;
                3'd1: pixel_row = 5'b11011;
                3'd2: pixel_row = 5'b11011;
                3'd3: pixel_row = 5'b11011;
                3'd4: pixel_row = 5'b11011;
                3'd5: pixel_row = 5'b01110;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // P
        7'd80: begin
            case (row)
                3'd0: pixel_row = 5'b11110;
                3'd1: pixel_row = 5'b11011;
                3'd2: pixel_row = 5'b11011;
                3'd3: pixel_row = 5'b11110;
                3'd4: pixel_row = 5'b11000;
                3'd5: pixel_row = 5'b11000;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // R
        7'd82: begin
            case (row)
                3'd0: pixel_row = 5'b11110;
                3'd1: pixel_row = 5'b11011;
                3'd2: pixel_row = 5'b11011;
                3'd3: pixel_row = 5'b11110;
                3'd4: pixel_row = 5'b11011;
                3'd5: pixel_row = 5'b11011;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // S
        7'd83: begin
            case (row)
                3'd0: pixel_row = 5'b01111;
                3'd1: pixel_row = 5'b11000;
                3'd2: pixel_row = 5'b01110;
                3'd3: pixel_row = 5'b00011;
                3'd4: pixel_row = 5'b00011;
                3'd5: pixel_row = 5'b11110;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // T
        7'd84: begin
            case (row)
                3'd0: pixel_row = 5'b11111;
                3'd1: pixel_row = 5'b01110;
                3'd2: pixel_row = 5'b01110;
                3'd3: pixel_row = 5'b01110;
                3'd4: pixel_row = 5'b01110;
                3'd5: pixel_row = 5'b01110;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // U
        7'd85: begin
            case (row)
                3'd0: pixel_row = 5'b11011;
                3'd1: pixel_row = 5'b11011;
                3'd2: pixel_row = 5'b11011;
                3'd3: pixel_row = 5'b11011;
                3'd4: pixel_row = 5'b11011;
                3'd5: pixel_row = 5'b01110;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // W
        7'd87: begin
            case (row)
                3'd0: pixel_row = 5'b11011;
                3'd1: pixel_row = 5'b11011;
                3'd2: pixel_row = 5'b11011;
                3'd3: pixel_row = 5'b11111;
                3'd4: pixel_row = 5'b11111;
                3'd5: pixel_row = 5'b11011;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // a (lowercase)
        7'd97: begin
            case (row)
                3'd0: pixel_row = 5'b00000;
                3'd1: pixel_row = 5'b01110;
                3'd2: pixel_row = 5'b00011;
                3'd3: pixel_row = 5'b01111;
                3'd4: pixel_row = 5'b11011;
                3'd5: pixel_row = 5'b01111;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // b (lowercase)
        7'd98: begin
            case (row)
                3'd0: pixel_row = 5'b11000;
                3'd1: pixel_row = 5'b11000;
                3'd2: pixel_row = 5'b11110;
                3'd3: pixel_row = 5'b11011;
                3'd4: pixel_row = 5'b11011;
                3'd5: pixel_row = 5'b11110;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // c (lowercase)
        7'd99: begin
            case (row)
                3'd0: pixel_row = 5'b00000;
                3'd1: pixel_row = 5'b01111;
                3'd2: pixel_row = 5'b11000;
                3'd3: pixel_row = 5'b11000;
                3'd4: pixel_row = 5'b11000;
                3'd5: pixel_row = 5'b01111;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // d (lowercase)
        7'd100: begin
            case (row)
                3'd0: pixel_row = 5'b00011;
                3'd1: pixel_row = 5'b00011;
                3'd2: pixel_row = 5'b01111;
                3'd3: pixel_row = 5'b11011;
                3'd4: pixel_row = 5'b11011;
                3'd5: pixel_row = 5'b01111;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // e (lowercase)
        7'd101: begin
            case (row)
                3'd0: pixel_row = 5'b00000;
                3'd1: pixel_row = 5'b01110;
                3'd2: pixel_row = 5'b11011;
                3'd3: pixel_row = 5'b11110;
                3'd4: pixel_row = 5'b11000;
                3'd5: pixel_row = 5'b01111;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // i (lowercase)
        7'd105: begin
            case (row)
                3'd0: pixel_row = 5'b01110;
                3'd1: pixel_row = 5'b00000;
                3'd2: pixel_row = 5'b11110;
                3'd3: pixel_row = 5'b01110;
                3'd4: pixel_row = 5'b01110;
                3'd5: pixel_row = 5'b11111;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // k (lowercase)
        7'd107: begin
            case (row)
                3'd0: pixel_row = 5'b11000;
                3'd1: pixel_row = 5'b11000;
                3'd2: pixel_row = 5'b11011;
                3'd3: pixel_row = 5'b11110;
                3'd4: pixel_row = 5'b11011;
                3'd5: pixel_row = 5'b11011;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // l (lowercase)
        7'd108: begin
            case (row)
                3'd0: pixel_row = 5'b01110;
                3'd1: pixel_row = 5'b01110;
                3'd2: pixel_row = 5'b01110;
                3'd3: pixel_row = 5'b01110;
                3'd4: pixel_row = 5'b01110;
                3'd5: pixel_row = 5'b01110;
                3'd6: pixel_row = 5'b01110;
                default: pixel_row = 5'b00000;
            endcase
        end

        // m (lowercase) - distinct double-hump pattern
        7'd109: begin
            case (row)
                3'd0: pixel_row = 5'b00000;
                3'd1: pixel_row = 5'b11010;
                3'd2: pixel_row = 5'b11111;
                3'd3: pixel_row = 5'b11111;
                3'd4: pixel_row = 5'b11011;
                3'd5: pixel_row = 5'b11011;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // n (lowercase)
        7'd110: begin
            case (row)
                3'd0: pixel_row = 5'b00000;
                3'd1: pixel_row = 5'b11110;
                3'd2: pixel_row = 5'b11011;
                3'd3: pixel_row = 5'b11011;
                3'd4: pixel_row = 5'b11011;
                3'd5: pixel_row = 5'b11011;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // o (lowercase)
        7'd111: begin
            case (row)
                3'd0: pixel_row = 5'b00000;
                3'd1: pixel_row = 5'b01110;
                3'd2: pixel_row = 5'b11011;
                3'd3: pixel_row = 5'b11011;
                3'd4: pixel_row = 5'b11011;
                3'd5: pixel_row = 5'b01110;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // p (lowercase)
        7'd112: begin
            case (row)
                3'd0: pixel_row = 5'b00000;
                3'd1: pixel_row = 5'b11110;
                3'd2: pixel_row = 5'b11011;
                3'd3: pixel_row = 5'b11011;
                3'd4: pixel_row = 5'b11110;
                3'd5: pixel_row = 5'b11000;
                3'd6: pixel_row = 5'b11000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // r (lowercase)
        7'd114: begin
            case (row)
                3'd0: pixel_row = 5'b00000;
                3'd1: pixel_row = 5'b11111;
                3'd2: pixel_row = 5'b11000;
                3'd3: pixel_row = 5'b11000;
                3'd4: pixel_row = 5'b11000;
                3'd5: pixel_row = 5'b11000;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // s (lowercase)
        7'd115: begin
            case (row)
                3'd0: pixel_row = 5'b00000;
                3'd1: pixel_row = 5'b01111;
                3'd2: pixel_row = 5'b11000;
                3'd3: pixel_row = 5'b01110;
                3'd4: pixel_row = 5'b00011;
                3'd5: pixel_row = 5'b11110;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // t (lowercase)
        7'd116: begin
            case (row)
                3'd0: pixel_row = 5'b01100;
                3'd1: pixel_row = 5'b11111;
                3'd2: pixel_row = 5'b01100;
                3'd3: pixel_row = 5'b01100;
                3'd4: pixel_row = 5'b01100;
                3'd5: pixel_row = 5'b00111;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        // u (lowercase)
        7'd117: begin
            case (row)
                3'd0: pixel_row = 5'b00000;
                3'd1: pixel_row = 5'b11011;
                3'd2: pixel_row = 5'b11011;
                3'd3: pixel_row = 5'b11011;
                3'd4: pixel_row = 5'b11011;
                3'd5: pixel_row = 5'b11011;
                3'd6: pixel_row = 5'b01111;
                default: pixel_row = 5'b00000;
            endcase
        end

        // x (lowercase)
        7'd120: begin
            case (row)
                3'd0: pixel_row = 5'b00000;
                3'd1: pixel_row = 5'b11011;
                3'd2: pixel_row = 5'b01110;
                3'd3: pixel_row = 5'b01110;
                3'd4: pixel_row = 5'b01110;
                3'd5: pixel_row = 5'b11011;
                3'd6: pixel_row = 5'b00000;
                default: pixel_row = 5'b00000;
            endcase
        end

        default: pixel_row = 5'b00000;
    endcase
end

endmodule
