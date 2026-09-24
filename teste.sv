module ps2_display7seg (
    input logic clk,
    input logic rst,

    input logic ps2_clk,
    input logic ps2_data,

    output logic [7:0] display,
    output logic [7:0] display_en
);


    // State Machine
    typedef enum logic [1:0] {
        IDLE, START, DATA, STOP
    } state_t;

    state_t current_state;
    state_t next_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)    current_state <= IDLE;
        else        current_state <= next_state;
    end

    // logic ps2_clk_mux;
    // assign ps2_clk_mux = (current_state == IDLE) ? 1'b1 : ps2_clk;

    logic subida_ps2_clk;
    logic descida_ps2_clk;
    detector_de_borda borda_ps2 (
        .clock(clk),
        .data(ps2_clk),
        .subida(subida_ps2_clk),
        .descida(descida_ps2_clk)
    );

    logic [3:0] cont_data;
    logic cont_data_rst;
    assign cont_data_rst = (current_state == DATA) ? 1'b0 : 1'b1;

    contador #(.MAX_VALUE(10)) cont_data_inst (
        .clk(ps2_clk),
        .rst(cont_data_rst),
        .cont(cont_data)
    );

    always_comb begin
        case (current_state)
            IDLE:       next_state = (ps2_data == 1'b0) ? START : IDLE;
            START:      next_state = (descida_ps2_clk) ? DATA : START;
            DATA:       next_state = (cont_data == 4'd10) ? STOP : DATA;
            STOP:       next_state = (descida_ps2_clk) ? IDLE : STOP;
            default:    next_state = IDLE;
        endcase
    end

    logic [8:0] data;

    always_ff @(negedge ps2_clk) begin
        if (current_state == DATA) begin
            data[cont_data-1] <= ps2_data;
        end
    end

    logic [7:0] scancode;
    logic parity_bit;
    
    assign scancode = data[7:0];
    assign parity_bit = data[8];


    

    


    // Display Logic
    logic clk_cont;
    divisor_clock #(.DIVISOR(100_000), .DUTY_CYCLE(50) ) divisor_clock_inst (
        .clk_in(clk),
        .clk_out(clk_cont)
    );

    assign display_en = (rst || current_state != IDLE) ? 8'b11111111 : ((clk_cont) ? 8'b11111101 : 8'b11111110);

    logic [3:0] display_mux;
    assign display_mux = (clk_cont) ? scancode[7:4] : scancode[3:0];

    bin_to_display display_logic (
        .in(display_mux),
        .display(display[6:0])
    );

    assign display[7] = 1'b1; // Ponto do display sempre desligado


endmodule