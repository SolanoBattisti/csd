module trabalho_final (
    input logic clock,
    input logic reset,

    input logic ps2_clk,
    input logic ps2_data,

    inout logic sda,
    output logic scl,

    output logic tx_data,
    output logic tx_done,

    output logic [7:0] display,
    output logic [7:0] display_en,

    output logic [3:0] color_red,
    output logic [3:0] color_green,
    output logic [3:0] color_blue,
    output logic vga_hs,
    output logic vga_vs
);
    localparam int NUM_DISPLAYS = 8;

    logic [11:0] temp_data;
    sensor_temperatura sensor_inst (        // Instanciando o sensor de temperatura através do ADT7420
        .clock(clock),
        .reset(reset),
        .sda(sda),
        .scl(scl),
        .temp_data(temp_data)     // temp_data armazena a temperatura vezes 16 em um registrador de 12 bits 
    );
    
    // ===================================================================================================
    // CONFIGURAÇÃO DO SET POINT

    logic [11:0] set_point;
    logic [11:0] set_point_ps2;
    logic rec_set_point;

    ps2_setpoint_config ps2_inst (
        .clk(clock),
        .rst(reset),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .send_set_point(rec_set_point),
        .set_point(set_point_ps2)
    );

    always_ff @( posedge clock or posedge reset ) begin
        if (reset) begin
            set_point <= 12'b000110010000;      // 25 graus de set point no reset
        end
        else begin
            // Ao apertar a tecla Enter, o modulo recebe o novo setpoint
            if(rec_set_point) set_point <= set_point_ps2;
        end
    end
    // ===================================================================================================

    logic [11:0] upper_hyst;
    assign upper_hyst = set_point + 12'b000000010000;
    logic [11:0] lower_hyst;
    assign lower_hyst = set_point - 12'b000000010000;

    
    typedef enum logic [1:0] { HOT, NORMAL, COLD } status_type;
    status_type status;

    always_comb begin
        if ( temp_data > upper_hyst ) status = HOT;
        else if ( temp_data < lower_hyst ) status = COLD;
        else status = NORMAL;
    end
    // ===================================================================================================
    
    





    // ===================================================================================================
    // DAQUI PRA BAIXO É TUDO DISPLAY

    // Clock para o contador do display, 1kHz
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

    assign display_en = reset ? 8'b11111111 : ~display_en_inverted; // Inverte saída do decoder pois display_en é ativo baixo
    
    // ===================================================================================================
    // MOSTRANDO TEMPERATURA NO DISPLAY

    logic [21:0] pre_temp;
    assign pre_temp = (temp_data * 100);

    logic [21:0] temperature;
    assign temperature = pre_temp >> 4;

    logic [3:0] temperatura_dezena;
    logic [3:0] temperatura_unidade;
    logic [3:0] temperatura_decimo;
    logic [3:0] temperatura_centesimo;
    always_comb begin 
        temperatura_dezena = (temperature / 1000) % 10;
        temperatura_unidade = (temperature / 100) % 10;
        temperatura_decimo = (temperature / 10) % 10;
        temperatura_centesimo = (temperature % 10);
    end

    // ===================================================================================================
    // MOSTRANDO STATUS NO DISPLAY

    logic [3:0] display_status;
    always_comb begin
        case(status)
            HOT: display_status = 4'd11;
            NORMAL: display_status = 4'd12;
            COLD: display_status = 4'd13;
            default: display_status = 4'd15;
        endcase
    end

    // ===================================================================================================
    // MOSTRANDO SET POINT NO DISPLAY

    logic [3:0] set_point_dezena;
    logic [3:0] set_point_unidade;
    assign set_point_dezena = ((set_point >> 4)/10)%10;
    assign set_point_unidade = (set_point >> 4) % 10;

    // ===================================================================================================


    logic [3:0] display_mux;
    always_comb begin
        case(cont)
            3'd0: display_mux = temperatura_centesimo;
            3'd1: display_mux = temperatura_decimo;
            3'd2: display_mux = temperatura_unidade;
            3'd3: display_mux = temperatura_dezena;
            3'd4: display_mux = display_status;
            3'd5: display_mux = display_status;
            3'd6: display_mux = set_point_unidade;
            3'd7: display_mux = set_point_dezena;
        endcase
    end

    assign display[7] = (cont == 4'd2) ? 1'b0 : 1'b1;

    // Decodificação em segmentos
    bin_to_display bin_to_display_inst (
        .in(display_mux),
        .display(display[6:0])
    );

    logic subida_rec;
    detector_de_borda borda_rec (
        .clock(clock),
        .data(rec_set_point),
        .subida(subida_rec),
        .descida()
    );

    logic [7:0] ascii_dezena;
    assign ascii_dezena = ({4'h0, set_point_dezena}) + 8'h30;

    logic [7:0] ascii_unidade;
    assign ascii_unidade = ({4'h0, set_point_unidade}) + 8'h30;


    uart_msg #(.MSG_TYPE(1)) uart_msg_inst (
        .clock(clock),
        .reset(reset),
        .ascii_dezena(ascii_dezena),
        .ascii_unidade(ascii_unidade),
        .start_uart(subida_rec),
        .tx_data(tx_data),
        .tx_done(tx_done)
    );




    vga_temperature teste (
        .*
    );

endmodule