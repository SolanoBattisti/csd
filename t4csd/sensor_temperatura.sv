module sensor_temperatura (
    input logic clock,
    input logic reset,
    inout logic sda,
    output logic scl,
    output logic [7:0] display,
    output logic [7:0] display_en
);
    localparam int NUM_DISPLAYS = 8;
    localparam logic [0:17] FIRST_MSG = 18'b100100001000000001;
    localparam logic [0:7] SECOND_MSG = 8'b10010001;

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
        if (reset)  current_state <= IDLE;
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
            START:          next_state = (subida_scl) ? FIRST_WRITE : START;
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


    logic [15:0] temp_reg;

    logic sda_in;
    assign sda_in = sda;

    logic sda_reg;

    logic output_en;
    assign sda = output_en ? sda_reg : 1'bz;
    
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            sda_reg <= 1'b1;
            output_en <= 1'b0;
        end
        else begin
            if (current_state == FIRST_WRITE) begin
                if (descida_scl) begin
                    if (cont_data == 5'd8 || cont_data == 5'd17 || cont_data == 5'd19) output_en <= 1'b0;
                    else begin
                        output_en <= 1'b1;
                        sda_reg <= FIRST_MSG[cont_data];
                    end
                end
            end
            if (current_state == SECOND_WRITE) begin
                if (descida_scl) begin
                    if (cont_data == 5'd8) output_en <= 1'b0;
                    else begin
                        output_en <= 1'b1;
                        sda_reg <= SECOND_MSG[cont_data];
                    end
                end
            end
            if (current_state == READ) begin
                if (descida_scl) begin
                    if (cont_data == 5'd17) begin       // ACK BY MASTER
                        output_en <= 1'b1;
                        sda_reg <= 1'b0;
                    end
                    else if (cont_data == 5'd26) begin       // NO-ACK BY MASTER
                        output_en <= 1'b1;
                        sda_reg <= 1'b1;
                    end
                    else output_en <= 1'b0;
                end
                if (subida_scl) begin                   // READING
                    if (cont_data >= 5'd9 && cont_data <= 5'd16) begin     
                        temp_reg[24-cont_data] <= sda_in;       // MOST SIGNIFICANT BYTE (BEFORE ACK BY MASTER)
                    end
                    else if (cont_data >= 5'd18 && cont_data <= 5'd25) begin
                        temp_reg[25-cont_data] <= sda_in;       // LEAST SIGNIFICANT BYTE (AFTER ACK BY MASTER)
                    end
                end
            end
        end
    end


    

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

    assign display_en = reset ? 8'b11111111 : ~display_en_inverted; // Inverte saída do decoder pois display_en é ativo baixo

    logic [25:0] temperatura;
    assign temperatura = (temp_reg * 1000) / 128;

    logic [3:0] dezena;
    logic [3:0] unidade;
    logic [3:0] decimo;
    logic [3:0] centesimo;
    always_comb begin 
        dezena = (temperatura / 1000) % 10;
        unidade = (temperatura / 100) % 10;
        decimo = (temperatura / 10) % 10;
        centesimo = (temperatura % 10);
    end


    logic [3:0] display_mux;
    always_comb begin
        case(cont)
            3'd0: display_mux = 4'd12;      // "C"
            3'd1: display_mux = centesimo;
            3'd2: display_mux = decimo;
            3'd3: display_mux = unidade;
            3'd4: display_mux = dezena;
            3'd5: display_mux = 4'd15;
            3'd6: display_mux = 4'd14;
            3'd7: display_mux = 4'd13;
        endcase
    end

    assign display[7] = (cont == 4'd3) ? 1'b0 : 1'b1;

    // Decodificação em segmentos
    bin_to_display bin_to_display_inst (
        .in(display_mux),
        .display(display[6:0])
    );

endmodule