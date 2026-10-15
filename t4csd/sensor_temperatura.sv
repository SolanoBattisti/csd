module sensor_temperatura (
    input logic clock,
    input logic reset,
    inout logic sda,
    output logic scl,
    output logic [7:0] display,
    output logic [7:0] display_en
);


    logic scl_signal;
    divisor_clock #(.DIVISOR(2_000), .DUTY_CYCLE(50) ) divisor_uart_clk (       // 50 kHz
        .clk_in(clock),
        .clk_out(scl_signal)
    );

    logic subida_scl;
    logic descida_scl;
    detector_de_borda detector_borda_scl (
        .clock(clock),
        .data(scl_signal),
        .subida(subida_scl),
        .descida(descida_scl)
    );

    typedef enum logic [2:0] {
        IDLE, START, FIRST_WRITE, REPEAT_START, SECOND_WRITE, READ
    } state_t;

    state_t current_state;
    state_t next_state;

    always_ff @(posedge clock or posedge reset) begin
        if (rst)    current_state <= IDLE;
        else        current_state <= next_state;
    end


    logic [4:0] cont_data;
    logic cont_data_rst;
    assign cont_data_rst = (current_state == IDLE || 
                            current_state == START || 
                            current_state == REPEAT_START) ? 1'b1 : 1'b0;

    contador #(.MAX_VALUE(28)) cont_data_inst (
        .clk(scl_signal),
        .rst(cont_data_rst),
        .cont(cont_data)
    );


    always_comb begin
        case (current_state)
            IDLE:           next_state = (subida_scl) ? START : IDLE;
            START:          next_state = (descida_scl) ? FIRST_WRITE : START;
            FIRST_WRITE:    next_state = (cont_data == 5'd19) ? REPEAT_START : FIRST_WRITE;
            REPEAT_START:   next_state = (descida_scl) ? SECOND_WRITE : REPEAT_START;
            SECOND_WRITE:   next_state = (cont_data == 5'd9) ? READ : SECOND_WRITE;
            READ:           next_state = (cont_data == 5'd27) ? IDLE : READ;
            default:        next_state = IDLE;
        endcase
    end

    assign scl =    (current_state == IDLE || 
                    current_state == START || 
                    current_state == REPEAT_START) ? 1'b1 : scl_signal;
    
    
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