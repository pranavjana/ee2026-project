// ========== SWAP TEXT RENDERER ==========
module swap_text_renderer(
    input [6:0] x,
    input [5:0] y,
    input [2:0] pos1,
    input [2:0] pos2,
    input show_no_swap,
    output reg is_text
);
    function [34:0] get_letter;
        input [7:0] char;
        begin
            case (char)
                "S": get_letter = 35'b11110_10001_01110_00001_11110;
                "W": get_letter = 35'b10001_10001_10101_11011_10001;
                "A": get_letter = 35'b01110_10001_11111_10001_10001;
                "P": get_letter = 35'b11110_10001_11110_10000_10000;
                ":": get_letter = 35'b00000_00100_00000_00100_00000;
                "N": get_letter = 35'b10001_11001_10101_10011_10001;
                "O": get_letter = 35'b01110_10001_10001_10001_01110;
                "<": get_letter = 35'b00010_00100_01000_00100_00010;
                "-": get_letter = 35'b00000_00000_11111_00000_00000;
                ">": get_letter = 35'b01000_00100_00010_00100_01000;
                "0": get_letter = 35'b01110_10001_10001_10001_01110;
                "1": get_letter = 35'b00100_01100_00100_00100_01110;
                "2": get_letter = 35'b01110_10001_00110_01000_11111;
                "3": get_letter = 35'b11110_00001_01110_00001_11110;
                "4": get_letter = 35'b00110_01010_10010_11111_00010;
                "5": get_letter = 35'b11111_10000_11110_00001_11110;
                "6": get_letter = 35'b01110_10000_11110_10001_01110;
                "7": get_letter = 35'b11111_00001_00010_00100_01000;
                " ": get_letter = 35'b00000_00000_00000_00000_00000;
                default: get_letter = 35'b00000_00000_00000_00000_00000;
            endcase
        end
    endfunction
    
    function is_in_letter;
        input [7:0] char;
        input [6:0] x_start;
        input [6:0] x_coord;
        input [5:0] y_coord;
        input [5:0] y_start;
        reg [34:0] pattern;
        reg [2:0] local_x, local_y;
        begin
            is_in_letter = 0;
            if (x_coord >= x_start && x_coord < x_start + 5 && 
                y_coord >= y_start && y_coord < y_start + 5) begin
                local_x = x_coord - x_start;
                local_y = y_coord - y_start;
                pattern = get_letter(char);
                is_in_letter = pattern[24 - (local_y * 5 + local_x)];
            end
        end
    endfunction
    
    localparam SWAP_Y = 50;
    
    always @(*) begin
        is_text = 0;
        
        if (y >= SWAP_Y && y < SWAP_Y + 5) begin
            if (show_no_swap) begin
                // "SWAP : NO" - centered at x=30
                if (x >= 30 && x < 35) is_text = is_in_letter("S", 30, x, y, SWAP_Y);
                else if (x >= 36 && x < 41) is_text = is_in_letter("W", 36, x, y, SWAP_Y);
                else if (x >= 42 && x < 47) is_text = is_in_letter("A", 42, x, y, SWAP_Y);
                else if (x >= 48 && x < 53) is_text = is_in_letter("P", 48, x, y, SWAP_Y);
                else if (x >= 54 && x < 59) is_text = is_in_letter(":", 54, x, y, SWAP_Y);
                else if (x >= 60 && x < 65) is_text = is_in_letter("N", 60, x, y, SWAP_Y);
                else if (x >= 66 && x < 71) is_text = is_in_letter("O", 66, x, y, SWAP_Y);
            end else begin
                // "SWAP : X <-> Y" - centered at x=18
                if (x >= 18 && x < 23) is_text = is_in_letter("S", 18, x, y, SWAP_Y);
                else if (x >= 24 && x < 29) is_text = is_in_letter("W", 24, x, y, SWAP_Y);
                else if (x >= 30 && x < 35) is_text = is_in_letter("A", 30, x, y, SWAP_Y);
                else if (x >= 36 && x < 41) is_text = is_in_letter("P", 36, x, y, SWAP_Y);
                else if (x >= 42 && x < 47) is_text = is_in_letter(":", 42, x, y, SWAP_Y);
                else if (x >= 48 && x < 53) is_text = is_in_letter(pos1 + "0", 48, x, y, SWAP_Y);
                else if (x >= 54 && x < 59) is_text = is_in_letter("<", 54, x, y, SWAP_Y);
                else if (x >= 60 && x < 65) is_text = is_in_letter("-", 60, x, y, SWAP_Y);
                else if (x >= 66 && x < 71) is_text = is_in_letter(">", 66, x, y, SWAP_Y);
                else if (x >= 72 && x < 77) is_text = is_in_letter(pos2 + "0", 72, x, y, SWAP_Y);
            end
        end
    end
endmodule