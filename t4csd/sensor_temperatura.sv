module sensor_temperatura (
    input logic clock,
    input logic reset,
    inout logic sda,
    output logic scl,
    output logic [7:0] display,
    output logic [7:0] display_en
);
    localparam int NUM_DISPLAYS = 8;
    localparam logic [7:0] SENSOR_ADDR = 8'b1001_0111;
    logic [11:0] sync_count = 12'd0;
    logic [7:0] temperature_MSB;
    logic [7:0] temperature_LSB;
    logic [11:0] temperature_reg;
    logic sda_in;
    logic sda_out;
    logic output_en;
    

    logic clk_200kHz;
    divisor_clock #(.DIVISOR(500), .DUTY_CYCLE(50) ) divisor_clk_200kHz (    // 200 kHz
        .clk_in(clock),
        .clk_out(clk_200kHz)
    );

    divisor_clock #(.DIVISOR(10_000), .DUTY_CYCLE(50) ) divisor_scl (       // 10 kHz
        .clk_in(clock),
        .clk_out(scl)
    );

    

    // logic subida_scl;
    // logic descida_scl;
    // detector_de_borda detector_borda_scl (
    //     .clock(clock),
    //     .data(scl_signal),
    //     .subida(subida_scl),
    //     .descida(descida_scl)
    // );

    typedef enum logic [4:0] {
        POWER_UP,
        START,
        SEND_ADDR6,
		SEND_ADDR5,
		SEND_ADDR4,
		SEND_ADDR3,
		SEND_ADDR2,
		SEND_ADDR1,
		SEND_ADDR0,
	    SEND_RW,
        REC_ACK,
        REC_MSB7,
		REC_MSB6,
		REC_MSB5,
		REC_MSB4,
		REC_MSB3,
		REC_MSB2,
		REC_MSB1,
		REC_MSB0,
        SEND_ACK,
        REC_LSB7,
		REC_LSB6,
		REC_LSB5,
		REC_LSB4,
		REC_LSB3,
		REC_LSB2,
		REC_LSB1,
		REC_LSB0,
        NACK
    } state_t;

    state_t current_state;
    // state_t next_state;

    // always_ff @(posedge clock or posedge reset) begin
    //     if (reset)  current_state <= IDLE;
    //     else        current_state <= next_state;
    // end


    // logic [4:0] cont_data;
    // logic cont_data_rst;
    // assign cont_data_rst = (current_state == IDLE || 
    //                         current_state == START || 
    //                         current_state == REC_ACK) ? 1'b1 : 1'b0;

    // contador #(.MAX_VALUE(28)) cont_data_inst (
    //     .clk(scl_signal),
    //     .rst(cont_data_rst),
    //     .cont(cont_data)
    // );

    // logic [11:0] sync_count = 12'd0;
    // contador #(.MAX_VALUE(4095)) sync_count_inst (
    //     .clk(clk_200kHz),
    //     .rst(reset),
    //     .cont(sync_count)
    // );

    // always_comb begin
    //     case (current_state)
    //         IDLE:       next_state = (sync_count == 12'd1999) ? START : IDLE;
    //         START:      next_state = (sync_count == 12'd2013) ? SEND_ADDR : START;
    //         SEND_ADDR:  next_state = (sync_count == 12'd2169) ? REC_ACK : SEND_ADDR;
    //         REC_ACK:    next_state = (sync_count == 12'd2189) ? REC_MSB : REC_ACK;
    //         REC_MSB:    next_state = (sync_count == 12'd2349) ? ACK : REC_MSB;
    //         ACK:        next_state = (sync_count == 12'd2369) ? REC_LSB : ACK;
    //         REC_LSB:    next_state = (sync_count == 12'd2529) ? NACK : REC_LSB;
    //         NACK:       next_state = (sync_count == 12'd2559) ? START : NACK;
    //         default:    next_state = IDLE;
    //     endcase
    // end

    

    // // Sending and receiving data
    // always_ff @(posedge clk_200kHz or posedge reset) begin
    //     if (reset) begin
    //         sda_out <= 1'b1;
    //         sync_count <= 12'd0;
    //     end
    //     else begin
    //         sync_count <= sync_count + 1;
    //         case(current_state)
    //             START: begin
    //                 if (sync_count == 12'd2004) sda_out <= 1'b0;        // START condition 1/4 de clock apos SCL subir
    //             end

    //             SEND_ADDR: begin
    //                 if (sync_count == 12'd2014) sda_out <= SENSOR_ADDR[7];
    //                 if (sync_count == 12'd2034) sda_out <= SENSOR_ADDR[6];
    //                 if (sync_count == 12'd2054) sda_out <= SENSOR_ADDR[5];
    //                 if (sync_count == 12'd2074) sda_out <= SENSOR_ADDR[4];
    //                 if (sync_count == 12'd2094) sda_out <= SENSOR_ADDR[3];
    //                 if (sync_count == 12'd2114) sda_out <= SENSOR_ADDR[2];
    //                 if (sync_count == 12'd2134) sda_out <= SENSOR_ADDR[1];
    //                 if (sync_count == 12'd2154) sda_out <= SENSOR_ADDR[0];
    //             end

    //             REC_MSB: begin
    //                 if (sync_count == 12'd2190) temperature_MSB[7] <= sda_in;
    //                 if (sync_count == 12'd2210) temperature_MSB[6] <= sda_in;
    //                 if (sync_count == 12'd2230) temperature_MSB[5] <= sda_in;
    //                 if (sync_count == 12'd2250) temperature_MSB[4] <= sda_in;
    //                 if (sync_count == 12'd2270) temperature_MSB[3] <= sda_in;
    //                 if (sync_count == 12'd2290) temperature_MSB[2] <= sda_in;
    //                 if (sync_count == 12'd2310) temperature_MSB[1] <= sda_in;
    //                 if (sync_count == 12'd2330) begin
    //                     sda_out <= 1'b0;     // ACK
    //                     temperature_MSB[0] <= sda_in;
    //                 end
    //             end

    //             REC_LSB: begin
    //                 if (sync_count == 12'd2370) temperature_LSB[7] <= sda_in;
    //                 if (sync_count == 12'd2390) temperature_LSB[6] <= sda_in;
    //                 if (sync_count == 12'd2410) temperature_LSB[5] <= sda_in;
    //                 if (sync_count == 12'd2430) temperature_LSB[4] <= sda_in;
    //                 if (sync_count == 12'd2450) temperature_LSB[3] <= sda_in;
    //                 if (sync_count == 12'd2470) temperature_LSB[2] <= sda_in;
    //                 if (sync_count == 12'd2490) temperature_LSB[1] <= sda_in;
    //                 if (sync_count == 12'd2510) begin
    //                     sda_out <= 1'b1;     // NACK
    //                     temperature_LSB[0] <= sda_in;
    //                 end
    //             end

    //             NACK: begin
    //                 temperature_reg <= {temperature_MSB[6:0], temperature_LSB[7:3]};
    //                 if (sync_count == 12'd2558) sync_count <= 12'd2000;
    //             end

    //         endcase
    //     end
    // end

    always_ff @(posedge clk_200kHz or posedge reset) begin
        if(reset) begin
            current_state <= START;
			sync_count <= 12'd2000;
        end
        else begin
			sync_count <= sync_count + 1;
            case(current_state)
                POWER_UP    : begin
                                if(sync_count == 12'd1999)
                                    current_state <= START;
                end
                START       : begin
                                if(sync_count == 12'd2004)
                                    sda_out <= 1'b0;          // send START condition 1/4 clock after SCL goes high    
                                if(sync_count == 12'd2013)
                                    current_state <= SEND_ADDR6; 
                end
                SEND_ADDR6  : begin
                                sda_out <= SENSOR_ADDR[7];
                                if(sync_count == 12'd2033)
                                    current_state <= SEND_ADDR5;
                end
				SEND_ADDR5  : begin
                                sda_out <= SENSOR_ADDR[6];
                                if(sync_count == 12'd2053)
                                    current_state <= SEND_ADDR4;
                end
				SEND_ADDR4  : begin
                                sda_out <= SENSOR_ADDR[5];
                                if(sync_count == 12'd2073)
                                    current_state <= SEND_ADDR3;
                end
				SEND_ADDR3  : begin
                                sda_out <= SENSOR_ADDR[4];
                                if(sync_count == 12'd2093)
                                    current_state <= SEND_ADDR2;
                end
				SEND_ADDR2  : begin
                                sda_out <= SENSOR_ADDR[3];
                                if(sync_count == 12'd2113)
                                    current_state <= SEND_ADDR1;
                end
				SEND_ADDR1  : begin
                                sda_out <= SENSOR_ADDR[2];
                                if(sync_count == 12'd2133)
                                    current_state <= SEND_ADDR0;
                end
				SEND_ADDR0  : begin
                                sda_out <= SENSOR_ADDR[1];
                                if(sync_count == 12'd2153)
                                    current_state <= SEND_RW;
                end
				SEND_RW     : begin
                                sda_out <= SENSOR_ADDR[0];
				                if(sync_count == 12'd2169)
                                    current_state <= REC_ACK;
                end
                REC_ACK     : begin
                                if(sync_count == 12'd2189)
                                    current_state <= REC_MSB7;
                end
                REC_MSB7     : begin
                                temperature_MSB[7] <= sda_in;
                                if(sync_count == 12'd2209)
                                    current_state <= REC_MSB6;
                                
                end
				REC_MSB6     : begin
                                temperature_MSB[6] <= sda_in;
                                if(sync_count == 12'd2229)
                                    current_state <= REC_MSB5;
                                
                end
				REC_MSB5     : begin
                                temperature_MSB[5] <= sda_in;
                                if(sync_count == 12'd2249)
                                    current_state <= REC_MSB4;
                                
                end
				REC_MSB4     : begin
                                temperature_MSB[4] <= sda_in;
                                if(sync_count == 12'd2269)
                                    current_state <= REC_MSB3;
                                
                end
				REC_MSB3     : begin
                                temperature_MSB[3] <= sda_in;
                                if(sync_count == 12'd2289)
                                    current_state <= REC_MSB2;
                                
                end
				REC_MSB2     : begin
                                temperature_MSB[2] <= sda_in;
                                if(sync_count == 12'd2309)
                                    current_state <= REC_MSB1;
                                
                end
				REC_MSB1     : begin
                                temperature_MSB[1] <= sda_in;
                                if(sync_count == 12'd2329)
                                    current_state <= REC_MSB0;
                                
                end
				REC_MSB0     : begin
								sda_out <= 1'b0;
                                temperature_MSB[0] <= sda_in;
                                if(sync_count == 12'd2349)
                                    current_state <= SEND_ACK;
                                
                end
                SEND_ACK   : begin
                                if(sync_count == 12'd2369)
                                    current_state <= REC_LSB7;
                end
                REC_LSB7    : begin
                                temperature_LSB[7] <= sda_in;
                                if(sync_count == 12'd2389)
									current_state <= REC_LSB6;
                end
                REC_LSB6    : begin
                                temperature_LSB[6] <= sda_in;
                                if(sync_count == 12'd2409)
									current_state <= REC_LSB5;
                end
				REC_LSB5    : begin
                                temperature_LSB[5] <= sda_in;
                                if(sync_count == 12'd2429)
									current_state <= REC_LSB4;
                end
				REC_LSB4    : begin
                                temperature_LSB[4] <= sda_in;
                                if(sync_count == 12'd2449)
									current_state <= REC_LSB3;
                end
				REC_LSB3    : begin
                                temperature_LSB[3] <= sda_in;
                                if(sync_count == 12'd2469)
									current_state <= REC_LSB2;
                end
				REC_LSB2    : begin
                                temperature_LSB[2] <= sda_in;
                                if(sync_count == 12'd2489)
									current_state <= REC_LSB1;
                end
				REC_LSB1    : begin
                                temperature_LSB[1] <= sda_in;
                                if(sync_count == 12'd2509)
									current_state <= REC_LSB0;
                end
				REC_LSB0    : begin
								sda_out <= 1'b1;
                                temperature_LSB[0] <= sda_in;
                                if(sync_count == 12'd2529)
									current_state <= NACK;
                end
                NACK        : begin
                                if(sync_count == 12'd2559) begin
									sync_count <= 12'd2000;
                                    current_state <= START;
								end
                end
            endcase     
        end
    end       
    
    // Buffer for temperature data
    always_ff @(posedge clk_200kHz) begin
        if(current_state == NACK) temperature_reg <= { temperature_MSB[6:0], temperature_LSB[7:3] };
    end
  
    assign sda_in = sda;

    assign output_en = (current_state == POWER_UP || current_state == START || current_state == SEND_ADDR6 || 
                        current_state == SEND_ADDR5 || current_state == SEND_ADDR4 || current_state == SEND_ADDR3 || 
                        current_state == SEND_ADDR2 || current_state == SEND_ADDR1 || current_state == SEND_ADDR0 || 
                        current_state == SEND_RW || current_state == SEND_ACK || current_state == NACK) ? 1'b1 : 1'b0;

    assign sda = output_en ? sda_out : 1'bz;

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

    logic [25:0] temperature;
    assign temperature = (temperature_reg * 1000) >> 4;

    logic [3:0] dezena;
    logic [3:0] unidade;
    logic [3:0] decimo;
    logic [3:0] centesimo;
    always_comb begin 
        dezena = (temperature / 1000) % 10;
        unidade = (temperature / 100) % 10;
        decimo = (temperature / 10) % 10;
        centesimo = (temperature % 10);
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
            3'd6: display_mux = 4'd15;
            3'd7: display_mux = 4'd15;
        endcase
    end

    assign display[7] = (cont == 4'd3) ? 1'b0 : 1'b1;

    // Decodificação em segmentos
    bin_to_display bin_to_display_inst (
        .in(display_mux),
        .display(display[6:0])
    );

endmodule