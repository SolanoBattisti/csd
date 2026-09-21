module placar_eletronico_digital #(
    parameter int NUM_DISPLAYS = 8
) (
    input logic clock,
    input logic reset,

    input logic incr_a,
    input logic decr_a,
    input logic incr_b,
    input logic decr_b,

    output logic [6:0] display,
    output logic [NUM_DISPLAYS-1:0] display_en
);

    logic [13:0] pontos_A;
    logic [13:0] pontos_B;


    // Instaciação de detectores para borda de subida de cada botão
    logic subida_incr_a;
    logic subida_decr_a;
    logic subida_incr_b;
    logic subida_decr_b;

    detector_de_borda detector_incr_a (
        .clock(clock),
        .data(incr_a),
        .subida(subida_incr_a),
        .descida()
    );

    detector_de_borda detector_decr_a (
        .clock(clock),
        .data(decr_a),
        .subida(subida_decr_a),
        .descida()
    );

    detector_de_borda detector_incr_b (
        .clock(clock),
        .data(incr_b),
        .subida(subida_incr_b),
        .descida()
    );

    detector_de_borda detector_decr_b (
        .clock(clock),
        .data(decr_b),
        .subida(subida_decr_b),
        .descida()
    );

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

    contador_pontos #(.MAX_POINTS(9999)) contador_equipe_A (
        .clk(clock),
        .rst(reset),
        .incr(subida_incr_a),
        .decr(subida_decr_a),
        .pontos(pontos_A)
    );

    contador_pontos #(.MAX_POINTS(9999)) contador_equipe_B (
        .clk(clock),
        .rst(reset),
        .incr(subida_incr_b),
        .decr(subida_decr_b),
        .pontos(pontos_B)
    );

    // Separando pontos_A em milhares, centenas, dezenas e unidades
    logic [3:0] A_M;
    logic [3:0] A_C;
    logic [3:0] A_D;
    logic [3:0] A_U;
    always_comb begin 
        if(pontos_A > 14'd9999) begin
            A_M = 4'd9;
            A_C = 4'd9;
            A_D = 4'd9;
            A_U = 4'd9;
        end else begin
            A_M = (pontos_A / 1000);
            A_C = (pontos_A / 100) % 10;
            A_D = (pontos_A / 10) % 10;
            A_U = (pontos_A % 10);
        end
    end

    // Separando pontos_B em milhares, centenas, dezenas e unidades
    logic [3:0] B_M;
    logic [3:0] B_C;
    logic [3:0] B_D;
    logic [3:0] B_U;
    always_comb begin 
        if(pontos_B > 14'd9999) begin
            B_M = 4'd9;
            B_C = 4'd9;
            B_D = 4'd9;
            B_U = 4'd9;
        end else begin
            B_M = (pontos_B / 1000);
            B_C = (pontos_B / 100) % 10;
            B_D = (pontos_B / 10) % 10;
            B_U = (pontos_B % 10);
        end
    end


    logic [3:0] display_mux;
    always_comb begin
        case(cont)
            3'd0: display_mux = B_U;
            3'd1: display_mux = B_D;
            3'd2: display_mux = B_C;
            3'd3: display_mux = B_M;
            3'd4: display_mux = A_U;
            3'd5: display_mux = A_D;
            3'd6: display_mux = A_C;
            3'd7: display_mux = A_M;
        endcase
    end

    // Decodificação em segmentos
    bin_to_display bin_to_display_inst (
        .in(display_mux),
        .display(display)
    );

endmodule
