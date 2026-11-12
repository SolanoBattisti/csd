module sensor_temperatura (
    input logic clock,
    input logic reset,
    inout logic sda,
    output logic scl,
    output logic [11:0] temp_data
);

    localparam int NUM_DISPLAYS = 8;
    localparam logic [7:0] SENSOR_ADDR = 8'b1001_0111;
    logic [11:0] sync_count = 12'd0;
    logic [7:0] temperature_MSB;
    logic [7:0] temperature_LSB;
    logic [11:0] temp_data_reg;
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
    
    always_ff @(posedge clk_200kHz or posedge reset) begin
        if(reset) begin
            current_state <= START;
			sync_count <= 12'd2000;
        end
        else begin
			sync_count <= sync_count + 1;
            case(current_state)
                POWER_UP: begin
                    if(sync_count == 12'd1999)
                        current_state <= START;
                end

                START: begin
                    if(sync_count == 12'd2004)
                        sda_out <= 1'b0;          // send START condition 1/4 clock after SCL goes high    
                    if(sync_count == 12'd2013)
                        current_state <= SEND_ADDR6; 
                end

                SEND_ADDR6: begin
                    sda_out <= SENSOR_ADDR[7];
                    if(sync_count == 12'd2033)
                        current_state <= SEND_ADDR5;
                end

				SEND_ADDR5: begin
                    sda_out <= SENSOR_ADDR[6];
                    if(sync_count == 12'd2053)
                        current_state <= SEND_ADDR4;
                end

				SEND_ADDR4: begin
                    sda_out <= SENSOR_ADDR[5];
                    if(sync_count == 12'd2073)
                    current_state <= SEND_ADDR3;
                end

				SEND_ADDR3: begin
                    sda_out <= SENSOR_ADDR[4];
                    if(sync_count == 12'd2093)
                        current_state <= SEND_ADDR2;
                end

				SEND_ADDR2: begin
                    sda_out <= SENSOR_ADDR[3];
                    if(sync_count == 12'd2113)
                        current_state <= SEND_ADDR1;
                end

				SEND_ADDR1: begin
                    sda_out <= SENSOR_ADDR[2];
                    if(sync_count == 12'd2133)
                        current_state <= SEND_ADDR0;
                end

				SEND_ADDR0: begin
                    sda_out <= SENSOR_ADDR[1];
                    if(sync_count == 12'd2153)
                        current_state <= SEND_RW;
                end

				SEND_RW: begin
                    sda_out <= SENSOR_ADDR[0];
		            if(sync_count == 12'd2169)
                        current_state <= REC_ACK;
                end

                REC_ACK: begin
                    if(sync_count == 12'd2189)
                        current_state <= REC_MSB7;
                end

                REC_MSB7: begin
                    temperature_MSB[7] <= sda_in;
                    if(sync_count == 12'd2209)
                        current_state <= REC_MSB6;        
                end

				REC_MSB6: begin
                    temperature_MSB[6] <= sda_in;
                    if(sync_count == 12'd2229)
                        current_state <= REC_MSB5;          
                end

				REC_MSB5: begin
                    temperature_MSB[5] <= sda_in;
                    if(sync_count == 12'd2249)
                        current_state <= REC_MSB4;     
                end

				REC_MSB4: begin
                    temperature_MSB[4] <= sda_in;
                    if(sync_count == 12'd2269)
                        current_state <= REC_MSB3;           
                end

				REC_MSB3: begin
                    temperature_MSB[3] <= sda_in;
                    if(sync_count == 12'd2289)
                        current_state <= REC_MSB2;          
                end

				REC_MSB2: begin
                    temperature_MSB[2] <= sda_in;
                    if(sync_count == 12'd2309)
                        current_state <= REC_MSB1;     
                end

				REC_MSB1: begin
                    temperature_MSB[1] <= sda_in;
                    if(sync_count == 12'd2329)
                        current_state <= REC_MSB0;         
                end

				REC_MSB0: begin
				    sda_out <= 1'b0;    // ACK
                    temperature_MSB[0] <= sda_in;
                    if(sync_count == 12'd2349)
                        current_state <= SEND_ACK;
                                
                end

                SEND_ACK: begin
                    if(sync_count == 12'd2369)
                        current_state <= REC_LSB7;
                end

                REC_LSB7: begin
                    temperature_LSB[7] <= sda_in;
                    if(sync_count == 12'd2389)
		  			    current_state <= REC_LSB6;
                end

                REC_LSB6: begin
                    temperature_LSB[6] <= sda_in;
                    if(sync_count == 12'd2409)
		    			current_state <= REC_LSB5;
                end

				REC_LSB5: begin
                    temperature_LSB[5] <= sda_in;
                    if(sync_count == 12'd2429)
						current_state <= REC_LSB4;
                end

				REC_LSB4: begin
                    temperature_LSB[4] <= sda_in;
                    if(sync_count == 12'd2449)
						current_state <= REC_LSB3;
                end

				REC_LSB3: begin
                    temperature_LSB[3] <= sda_in;
                    if(sync_count == 12'd2469)
						current_state <= REC_LSB2;
                end

				REC_LSB2: begin
                    temperature_LSB[2] <= sda_in;
                    if(sync_count == 12'd2489)
						current_state <= REC_LSB1;
                end

				REC_LSB1: begin
                    temperature_LSB[1] <= sda_in;
                    if(sync_count == 12'd2509)
						current_state <= REC_LSB0;
                end

				REC_LSB0: begin
					sda_out <= 1'b1;    // NACK
                    temperature_LSB[0] <= sda_in;
                    if(sync_count == 12'd2529)
						current_state <= NACK;
                end

                NACK: begin
                    if(sync_count == 12'd2559) begin
						sync_count <= 12'd2000;
                        current_state <= START;
					end
                end
            endcase     
        end
    end       
    
    // Buffer for pre_temp data
    always_ff @(posedge clk_200kHz) begin
        if(current_state == NACK) temp_data_reg <= { temperature_MSB[6:0], temperature_LSB[7:3] };
    end
  
    assign sda_in = sda;

    assign output_en = (current_state == POWER_UP || current_state == START || current_state == SEND_ADDR6 || 
                        current_state == SEND_ADDR5 || current_state == SEND_ADDR4 || current_state == SEND_ADDR3 || 
                        current_state == SEND_ADDR2 || current_state == SEND_ADDR1 || current_state == SEND_ADDR0 || 
                        current_state == SEND_RW || current_state == SEND_ACK || current_state == NACK) ? 1'b1 : 1'b0;

    assign sda = output_en ? sda_out : 1'bz;


    assign temp_data = temp_data_reg;


endmodule