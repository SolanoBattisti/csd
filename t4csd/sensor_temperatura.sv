module sensor_temperatura (
    input logic clock,
    input logic reset,
    inout logic sda,
    output logic scl,
    output logic [7:0] display,
    output logic [7:0] display_en
);

    divisor_clock #(.DIVISOR(2_000), .DUTY_CYCLE(50) ) divisor_uart_clk (
        .clk_in(clock),
        .clk_out(scl)
    );





    // DISPLAY LOGIC

    // Clock para o contador, 1kHz
    logic clk_cont;
    divisor_clock #(.DIVISOR(100_000), .DUTY_CYCLE(50) ) divisor_clock_inst (
        .clk_in(clock),
        .clk_out(clk_cont)
    );

    // Instanciando contador
    logic [$clog2(NUM_DISPLAYS)-1:0] cont;
    contador #(.MAX_VALUE(NUM_DISPLAYS)) contador_inst (
        .clk(clk_cont),
        .rst(reset),
        .cont(cont)
    );


    logic [7:0] display_en_inverted;
    decoder #(.IN_WIDTH($clog2(NUM_DISPLAYS))) decoder_inst (
        .in(cont),
        .out(display_en_inverted)
    );
    // Enquanto reset está ativo, displays ligados mostrando 0
    assign display_en = reset ? 8'b00000000 : ~display_en_inverted; // Inverte saída do decoder pois display_en é ativo baixo

    logic [3:0] display_mux;
    always_comb begin
        case(cont)
            3'd0: display_mux = ;
            3'd1: display_mux = ;
            3'd2: display_mux = ;
            3'd3: display_mux = ;
            3'd4: display_mux = ;
            3'd5: display_mux = ;
            3'd6: display_mux = ;
            3'd7: display_mux = ;
        endcase
    end

    // Decodificação em segmentos
    bin_to_display bin_to_display_inst (
        .in(display_mux),
        .display(display)
    );

endmodule