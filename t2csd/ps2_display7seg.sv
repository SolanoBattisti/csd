module ps2_display7seg #(
    parameter int WIDTH_SHIFT_REG = 64
)(
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
    
    assign parity_bit = data[8];
    assign scancode = ((data[7]^data[6]^data[5]^data[4]^data[3]^data[2]^data[1]^data[0]) == parity_bit) ? data[7:0] : '0;



    // Shift Reg Logic

    logic [7:0] shift_reg [0:WIDTH_SHIFT_REG-1];

    genvar i;
    generate
        for(i=0; i < WIDTH_SHIFT_REG-2; i++) begin
            always_ff @(posedge clk or posedge rst) begin
                if(rst) begin
                    shift_reg[i+1] <= '0;
                end
                else if(current_state == STOP && next_state == IDLE) begin
                    if(scancode == 8'h66) shift_reg[i+1] <= shift_reg[i+2];
                    else shift_reg[i+1] <= shift_reg[i];
                end
            end
        end
    endgenerate

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            shift_reg[0] <= '0;
        end
        else if(current_state == STOP && next_state == IDLE) begin
            if(scancode == 8'h66) begin
                shift_reg[0] <= shift_reg[1];
                shift_reg[WIDTH_SHIFT_REG-1] <= '0;
            end
            else begin
                shift_reg[0] <= scancode;
                shift_reg[WIDTH_SHIFT_REG-1] <= shift_reg[WIDTH_SHIFT_REG-2];
            end
        end
    end


    


    // Display Logic
    logic clk_display;
    divisor_clock #(.DIVISOR(100_000), .DUTY_CYCLE(50) ) divisor_clock_inst (
        .clk_in(clk),
        .clk_out(clk_display)
    );

    logic [2:0] cont;
    contador #(.MAX_VALUE(8)) contador_inst (
        .clk(clk_display),
        .rst(rst),
        .cont(cont)
    );


    logic [7:0] display_en_inverted;
    decoder #(.IN_WIDTH(3)) decoder_inst (
        .in(cont),
        .out(display_en_inverted)
    );
    // Inverte saída do decoder pois display_en é ativo baixo
    assign display_en = rst ? 8'b11111111 : ~display_en_inverted;



    logic [7:0] display_mux;
    always_comb begin
        case(cont)
            3'd0: display_mux = shift_reg[0];
            3'd1: display_mux = shift_reg[1];
            3'd2: display_mux = shift_reg[2];
            3'd3: display_mux = shift_reg[3];
            3'd4: display_mux = shift_reg[4];
            3'd5: display_mux = shift_reg[5];
            3'd6: display_mux = shift_reg[6];
            3'd7: display_mux = shift_reg[7];
        endcase
    end

    scancode_to_display scancode_to_display_inst (
        .scancode(display_mux),
        .display(display)
    );


endmodule