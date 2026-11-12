module bin_to_vga (
    input logic [3:0] number,
    output logic [0:9][0:9] matrix
);

    always_comb begin
        case(number)
            4'd0: begin
                matrix[0] = '0;
                matrix[1] = 10'b1111111111;
                matrix[2] = 10'b1111111111;
                matrix[3] = 10'b1100000011;
                matrix[4] = 10'b1100000011;
                matrix[5] = 10'b1100000011;
                matrix[6] = 10'b1100000011;
                matrix[7] = 10'b1111111111;
                matrix[8] = 10'b1111111111;
                matrix[9] = '0;
            end
            4'd1: begin
                matrix[0] = '0;
                matrix[1] = '0;
                matrix[2] = '0;
                matrix[3] = 10'b0000000011;
                matrix[4] = 10'b0011000011;
                matrix[5] = 10'b1111111111;
                matrix[6] = 10'b1111111111;
                matrix[7] = 10'b0000000011;
                matrix[8] = 10'b0000000011;
                matrix[9] = '0;
            end
            4'd2: begin
                matrix[0] = '0;
                matrix[1] = 10'b1100111111;
                matrix[2] = 10'b1100111111;
                matrix[3] = 10'b1100110011;
                matrix[4] = 10'b1100110011;
                matrix[5] = 10'b1100110011;
                matrix[6] = 10'b1100110011;
                matrix[7] = 10'b1111110011;
                matrix[8] = 10'b1111110011;
                matrix[9] = '0;
            end
            4'd3: begin
                matrix[0] = '0;
                matrix[1] = 10'b1100110011;
                matrix[2] = 10'b1100110011;
                matrix[3] = 10'b1100110011;
                matrix[4] = 10'b1100110011;
                matrix[5] = 10'b1100110011;
                matrix[6] = 10'b1100110011;
                matrix[7] = 10'b1111111111;
                matrix[8] = 10'b1111111111;
                matrix[9] = '0;
            end
            4'd4: begin
                matrix[0] = '0;
                matrix[1] = 10'b1111110000;
                matrix[2] = 10'b1111110000;
                matrix[3] = 10'b0000110000;
                matrix[4] = 10'b0000110000;
                matrix[5] = 10'b0000110000;
                matrix[6] = 10'b0000110000;
                matrix[7] = 10'b1111111111;
                matrix[8] = 10'b1111111111;
                matrix[9] = '0;
            end
            4'd5: begin
                matrix[0] = '0;
                matrix[1] = 10'b1111110011;
                matrix[2] = 10'b1111110011;
                matrix[3] = 10'b1100110011;
                matrix[4] = 10'b1100110011;
                matrix[5] = 10'b1100110011;
                matrix[6] = 10'b1100110011;
                matrix[7] = 10'b1100111111;
                matrix[8] = 10'b1100111111;
                matrix[9] = '0;
            end
            4'd6: begin
                matrix[0] = '0;
                matrix[1] = 10'b1111111111;
                matrix[2] = 10'b1111111111;
                matrix[3] = 10'b1100110011;
                matrix[4] = 10'b1100110011;
                matrix[5] = 10'b1100110011;
                matrix[6] = 10'b1100110011;
                matrix[7] = 10'b1100111111;
                matrix[8] = 10'b1100111111;
                matrix[9] = '0;
            end
            4'd7: begin
                matrix[0] = '0;
                matrix[1] = 10'b1100000000;
                matrix[2] = 10'b1100000000;
                matrix[3] = 10'b1100000000;
                matrix[4] = 10'b1100000000;
                matrix[5] = 10'b1100000000;
                matrix[6] = 10'b1100000000;
                matrix[7] = 10'b1111111111;
                matrix[8] = 10'b1111111111;
                matrix[9] = '0;
            end
            4'd8: begin
                matrix[0] = '0;
                matrix[1] = 10'b1111111111;
                matrix[2] = 10'b1111111111;
                matrix[3] = 10'b1100110011;
                matrix[4] = 10'b1100110011;
                matrix[5] = 10'b1100110011;
                matrix[6] = 10'b1100110011;
                matrix[7] = 10'b1111111111;
                matrix[8] = 10'b1111111111;
                matrix[9] = '0;
            end
            4'd9: begin
                matrix[0] = '0;
                matrix[1] = 10'b1111110011;
                matrix[2] = 10'b1111110011;
                matrix[3] = 10'b1100110011;
                matrix[4] = 10'b1100110011;
                matrix[5] = 10'b1100110011;
                matrix[6] = 10'b1100110011;
                matrix[7] = 10'b1111111111;
                matrix[8] = 10'b1111111111;
                matrix[9] = '0;
            end
            default: begin
                matrix[0] = 10'b1111111111;
                matrix[1] = 10'b1111111111;
                matrix[2] = 10'b1111111111;
                matrix[3] = 10'b1111111111;
                matrix[4] = 10'b1111111111;
                matrix[5] = 10'b1111111111;
                matrix[6] = 10'b1111111111;
                matrix[7] = 10'b1111111111;
                matrix[8] = 10'b1111111111;
                matrix[9] = 10'b1111111111;
            end
        endcase
    end

endmodule