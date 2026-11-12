module ps2_setpoint_config (
    input logic clk,
    input logic rst,

    input logic ps2_clk,
    input logic ps2_data,

    output logic send_set_point,
    output logic [11:0] set_point
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

    // Signal for all the keys that aren't the digits or Enter
    logic not_a_digit;
    assign not_a_digit =   (scancode!=8'h16 && scancode!=8'h1E && scancode!=8'h26 && scancode!=8'h25 &&
                            scancode!=8'h2E && scancode!=8'h36 && scancode!=8'h3D && scancode!=8'h3E &&
                            scancode!=8'h46 && scancode!=8'h45 && scancode!=8'h5A);

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
    //logic [7:0] shift_reg [0:WIDTH_SHIFT_REG-1];
    logic [7:0] scancode_dezena;
    logic [7:0] scancode_unidade;

    // genvar i;
    // generate
    //     for(i=0; i < WIDTH_SHIFT_REG-2; i++) begin
    //         always_ff @(posedge clk or posedge rst) begin
    //             if(rst) begin
    //                 shift_reg[i+1] <= '0;
    //             end
    //             else if(current_state == STOP && next_state == IDLE) begin
    //                 if(scancode == 8'hF0 || key_releasing || not_a_digit) shift_reg[i+1] <= shift_reg[i+1];

    //                 else if(scancode == 8'h66 || scancode == 8'h71) shift_reg[i+1] <= shift_reg[i+2];
                    
    //                 else shift_reg[i+1] <= shift_reg[i];
    //             end
    //         end
    //     end
    // endgenerate


    // Same Shift Reg Logic for the first and last registers
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            send_set_point <= 1'b0;
            scancode_unidade <= '0;
            scancode_dezena <= '0;
        end
        else if(current_state == STOP && next_state == IDLE) begin
            if(scancode == 8'hF0 || key_releasing || not_a_digit) begin
                send_set_point <= 1'b0;
                // scancode_unidade <= scancode_unidade;
                // scancode_dezena <= scancode_dezena;
            end else if(scancode == 8'h5A) begin        // tecla Enter
                send_set_point <= 1'b1;
            end else begin
                send_set_point <= 1'b0;
                scancode_unidade <= scancode;
                scancode_dezena <= scancode_unidade;
            end
        end
    end

    logic [3:0] set_point_dezena;
    always_comb begin
        case(scancode_dezena)
            8'h45: set_point_dezena = 4'd0;
            8'h16: set_point_dezena = 4'd1;
            8'h1E: set_point_dezena = 4'd2;
            8'h26: set_point_dezena = 4'd3;
            8'h25: set_point_dezena = 4'd4;
            8'h2E: set_point_dezena = 4'd5;
            8'h36: set_point_dezena = 4'd6;
            8'h3D: set_point_dezena = 4'd7;
            8'h3E: set_point_dezena = 4'd8;
            8'h46: set_point_dezena = 4'd9;
            default: set_point_dezena = 4'd0;
        endcase
    end

    logic [3:0] set_point_unidade;
    always_comb begin
        case(scancode_unidade)
            8'h45: set_point_unidade = 4'd0;
            8'h16: set_point_unidade = 4'd1;
            8'h1E: set_point_unidade = 4'd2;
            8'h26: set_point_unidade = 4'd3;
            8'h25: set_point_unidade = 4'd4;
            8'h2E: set_point_unidade = 4'd5;
            8'h36: set_point_unidade = 4'd6;
            8'h3D: set_point_unidade = 4'd7;
            8'h3E: set_point_unidade = 4'd8;
            8'h46: set_point_unidade = 4'd9;
            default: set_point_unidade = 4'd0;
        endcase
    end

    logic [11:0] pre_set_point;
    assign pre_set_point = (10*set_point_dezena + set_point_unidade);

    assign set_point = pre_set_point << 4; // multiplica por 16 para ficar no padrão que o modulo top usa

endmodule