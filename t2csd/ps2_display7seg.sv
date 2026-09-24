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

    logic [3:0] cont_data; // Counts how many bits of ps2_data have been collected
    logic cont_data_rst;   // Tells the counter to only start counting on the state DATA
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
    assign scancode = data[7:0];

    // Signal for all the keys that shouldn't print anything
    logic useless_key;
    assign useless_key =     (scancode==8'h05||scancode==8'h06||scancode==8'h04||scancode==8'h0C||scancode==8'h03
                            ||scancode==8'h0B||scancode==8'h83||scancode==8'h0A||scancode==8'h01||scancode==8'h09
                            ||scancode==8'h07||scancode==8'h58||scancode==8'h12||scancode==8'h14||scancode==8'h11
                            ||scancode==8'h5A||scancode==8'h59||scancode==8'hE0||scancode==8'h6B||scancode==8'h6C
                            ||scancode==8'h69||((scancode[7:4] == 4'h7) && (scancode[3:0] != 4'h1)));

    // Signal for the F0 and second scancode on key release
    logic key_releasing;

    always_ff @(posedge clk or posedge rst) begin
        if(rst) key_releasing <= 1'b0;
        else if(current_state == STOP && next_state == IDLE) begin
            if(scancode == 8'hF0) key_releasing <= 1'b1; // Detects the F0 scancode
            else if(key_releasing) key_releasing <= 1'b0; // Turns the signal off after the resending of the scancode
        end
    end


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
                    if(scancode == 8'hF0 || key_releasing || useless_key) shift_reg[i+1] <= shift_reg[i+1];

                    else if(scancode == 8'h66 || scancode == 8'h71) shift_reg[i+1] <= shift_reg[i+2];
                    
                    else shift_reg[i+1] <= shift_reg[i];
                end
            end
        end
    endgenerate

    // Same Shift Reg Logic for the first and last registers
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            shift_reg[0] <= '0;
            shift_reg[WIDTH_SHIFT_REG-1] <= '0;
        end
        else if(current_state == STOP && next_state == IDLE) begin
            if(scancode == 8'hF0 || key_releasing || useless_key) begin
                shift_reg[0] <= shift_reg[0];
                shift_reg[WIDTH_SHIFT_REG-1] <= shift_reg[WIDTH_SHIFT_REG-1];
            end
            else if(scancode == 8'h66 || scancode == 8'h71) begin
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
    // Inverts decoder's output since display_en is low-active
    assign display_en = rst ? 8'b11111111 : ~display_en_inverted;



    logic [7:0] display_mux;
    assign display_mux = shift_reg[cont];

    scancode_to_display scancode_to_display_inst (
        .scancode(display_mux),
        .display(display)
    );


endmodule