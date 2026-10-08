module bin_to_display (
    input logic [3:0] in,
    output logic [6:0] display
);

    always_comb begin
        case(in)
            4'd0: display = 7'b0000001;
            4'd1: display = 7'b1001111;
            4'd2: display = 7'b0010010;
            4'd3: display = 7'b0000110;
            4'd4: display = 7'b1001100;
            4'd5: display = 7'b0100100;
            4'd6: display = 7'b0100000;
            4'd7: display = 7'b0001111;
            4'd8: display = 7'b0000000;
            4'd9: display = 7'b0000100;
            4'd10: display = 7'b0001000;
            4'd11: display = 7'b1100000;
            4'd12: display = 7'b0110001;
            4'd13: display = 7'b1000010;
            4'd14: display = 7'b0110000;
            4'd15: display = 7'b0111000;
        endcase
    end

endmodule