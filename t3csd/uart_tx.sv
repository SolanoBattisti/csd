module uart_tx (
    input logic clock,
    input logic reset,
    input logic ps2_clk,
    input logic ps2_data,

    output logic tx_data,
    output logic tx_done
);

    typedef enum logic [1:0] {
        IDLE, START, DATA, STOP
    } state_t;

    // State Machine PS2

    state_t current_state_ps2;
    state_t next_state_ps2;

    always_ff @(posedge clock or posedge reset) begin
        if (reset)    current_state_ps2 <= IDLE;
        else        current_state_ps2 <= next_state_ps2;
    end


    logic subida_ps2_clk;
    logic descida_ps2_clk;
    detector_de_borda borda_ps2 (
        .clock(clock),
        .data(ps2_clk),
        .subida(subida_ps2_clk),
        .descida(descida_ps2_clk)
    );

    logic [3:0] cont_data; // Counts how many bits of ps2_data have been collected
    logic cont_data_rst;   // Tells the counter to only start counting on the state DATA
    assign cont_data_rst = (current_state_ps2 == DATA) ? 1'b0 : 1'b1;

    contador #(.MAX_VALUE(10)) cont_data_inst (
        .clk(ps2_clk),
        .rst(cont_data_rst),
        .cont(cont_data)
    );

    always_comb begin
        case (current_state_ps2)
            IDLE:       next_state_ps2 = (ps2_data == 1'b0) ? START : IDLE;
            START:      next_state_ps2 = (descida_ps2_clk) ? DATA : START;
            DATA:       next_state_ps2 = (cont_data == 4'd10) ? STOP : DATA;
            STOP:       next_state_ps2 = (descida_ps2_clk) ? IDLE : STOP;
            default:    next_state_ps2 = IDLE;
        endcase
    end

    logic [8:0] data;

    always_ff @(negedge ps2_clk) begin
        if (current_state_ps2 == DATA) begin
            data[cont_data-1] <= ps2_data;
        end
    end

   
    logic [7:0] scancode;
    logic parity_bit;
    
    assign parity_bit = data[8];
    assign scancode = data[7:0];

    // ---------------------------------------

    logic [7:0] ascii;

    scancode_to_ascii ascii_gen (
        .scancode(scancode),
        .ascii(ascii)
    );

    logic [9:0] full_tx_data;
    assign full_tx_data = {1'b1, ascii, 1'b0};

    logic uart_clk;

    divisor_clock #(.DIVISOR(10_417), .DUTY_CYCLE(50) ) divisor_uart_clk (
        .clk_in(clock),
        .clk_out(uart_clk)
    );

    // logic subida_uart_clk;
    // logic descida_uart_clk;
    // detector_de_borda borda_uart (
    //     .clock(clock),
    //     .data(uart_clk),
    //     .subida(subida_uart_clk),
    //     .descida(descida_uart_clk)
    // );

    // State Machine UART

    state_t current_state_uart;
    state_t next_state_uart;

    always_ff @(posedge clock or posedge reset) begin
        if (reset)    current_state_uart <= IDLE;
        else        current_state_uart <= next_state_uart;
    end

    logic [3:0] cont_uart; 
    logic cont_uart_rst;   
    assign cont_uart_rst = (current_state_uart == DATA) ? 1'b0 : 1'b1;

    contador #(.MAX_VALUE(11)) cont_uart_inst (
        .clk(uart_clk),
        .rst(cont_uart_rst),
        .cont(cont_uart)
    );

    logic key_releasing;
    logic start_uart;

    always_ff @(posedge clock or posedge reset) begin
        if(reset) begin
            key_releasing <= 1'b0;
            start_uart <= 1'b0;
        end
        else if(current_state_ps2 == STOP && next_state_ps2 == IDLE) begin
            if(scancode == 8'hF0) begin
                key_releasing <= 1'b1; // Detects the F0 scancode
                start_uart <= 1'b0;
            end
            else if(key_releasing) begin
                key_releasing <= 1'b0; // Turns the signal off after the resending of the scancode
                start_uart <= 1'b0;
            end
            else start_uart <= 1'b1;
        end
        else start_uart <= 1'b0;
    end



    always_comb begin
        case (current_state_uart)
            IDLE:       next_state_uart = (start_uart) ? DATA : IDLE;
            DATA:       next_state_uart = (cont_uart == 4'd11) ? IDLE : DATA;
            default:    next_state_uart = IDLE;
        endcase
    end

    always_ff @(negedge uart_clk) begin
        if(current_state_uart == DATA) begin
            tx_data <= full_tx_data[cont_uart-1];
        end
        else begin 
            tx_data <= 1'b1;
        end
    end

    assign tx_done = (current_state_uart == DATA) ? 1'b0 : 1'b1;


endmodule