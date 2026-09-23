module scancode_to_display (
    input logic [7:0] scancode,
    output logic [7:0] display
);

    always_comb begin
        case(scancode)
            8'h45: display = 8'b10000001;
            8'h16: display = 8'b11001111;
            8'h1E: display = 8'b10010010;
            8'h26: display = 8'b10000110;
            8'h25: display = 8'b11001100;
            8'h2E: display = 8'b10100100;
            8'h36: display = 8'b10100000;
            8'h3D: display = 8'b10001111;
            8'h3E: display = 8'b10000000;
            8'h46: display = 8'b10000100;
            8'h1C: display = 8'b10001000;
            8'h32: display = 8'b11100000;
            8'h21: display = 8'b10110001;
            8'h4C: display = 8'b10110001;
            8'h23: display = 8'b11000010;
            8'h24: display = 8'b10110000;
            8'h2B: display = 8'b10111000;
            8'h34: display = 8'b10100001;
            8'h33: display = 8'b11101000;
            8'h43: display = 8'b10101111;
            8'h3B: display = 8'b10100111;
            8'h42: display = 8'b10101000;
            8'h4B: display = 8'b11110001;
            8'h3A: display = 8'b10101010;
            8'h31: display = 8'b11101010;
            8'h44: display = 8'b11100010;
            8'h4D: display = 8'b10011000;
            8'h15: display = 8'b10001100;
            8'h2D: display = 8'b11111010;
            8'h1B: display = 8'b10100101;
            8'h2C: display = 8'b11110000;
            8'h3C: display = 8'b11000001;
            8'h2A: display = 8'b11100011;
            8'h1D: display = 8'b11010100;
            8'h22: display = 8'b11101100;
            8'h35: display = 8'b11000100;
            8'h1A: display = 8'b10010011;
            8'h49: display = 8'b01111111;
            8'h4E: display = 8'b11111110;
            8'h41: display = 8'b11111011;
            8'h0E: display = 8'b11111101;
            8'h55: display = 8'b11110110;
            8'h29: display = 8'b11111111;
            8'h0D: display = 8'b11111111;
            8'hF0: display = 8'b11001001;
            default: display = 8'b11111111;
        endcase
    end

endmodule