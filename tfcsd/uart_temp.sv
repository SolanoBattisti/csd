// FUNCIONANDO PERFEITAMENTE
// MENSAGEM: "Novo Set Point: XX"

module uart_msg #(
    parameter int MSG_TYPE = 0      // 1 - Novo Set Point | 2 - Novo Máx | 3 - Novo Mín | 4 - Mudança de Status   
)(
    input logic clock,
    input logic reset,
    input logic [7:0] ascii_dezena,
    input logic [7:0] ascii_unidade,
    input logic start_uart,

    output logic tx_data,
    output logic tx_done
);
    localparam int WIDTH_MSG = 190;



    logic [WIDTH_MSG-1:0] full_tx_data;




    // ASCII FOR EACH DIGIT OF THE MESSAGE (FROM LAST TO FIRST DIGIT), EACH ATTACHED TO THE START AND STOP BITS
    assign full_tx_data =  {{1'b1, 8'h0A, 1'b0}, {1'b1, ascii_unidade, 1'b0}, {1'b1, ascii_dezena, 1'b0}, 
                            {1'b1, 8'h20, 1'b0}, {1'b1, 8'h3A, 1'b0}, {1'b1, 8'h74, 1'b0}, 
                            {1'b1, 8'h6E, 1'b0}, {1'b1, 8'h69, 1'b0}, {1'b1, 8'h6F, 1'b0}, {1'b1, 8'h50, 1'b0}, 
                            {1'b1, 8'h20, 1'b0}, {1'b1, 8'h74, 1'b0}, {1'b1, 8'h65, 1'b0}, {1'b1, 8'h53, 1'b0}, 
                            {1'b1, 8'h20, 1'b0}, {1'b1, 8'h6F, 1'b0}, {1'b1, 8'h76, 1'b0}, {1'b1, 8'h6F, 1'b0}, 
                            {1'b1, 8'h4E, 1'b0}};

    logic uart_clk;

    divisor_clock #(.DIVISOR(10_417), .DUTY_CYCLE(50) ) divisor_uart_clk (
        .clk_in(clock),
        .clk_out(uart_clk)
    );

    
    // State Machine UART

    typedef enum logic { IDLE, DATA } state_t;

    state_t current_state_uart;
    state_t next_state_uart;

    always_ff @(posedge clock or posedge reset) begin
        if (reset)    current_state_uart <= IDLE;
        else        current_state_uart <= next_state_uart;
    end

    logic [7:0] cont_uart; 
    logic cont_uart_rst;   
    assign cont_uart_rst = (current_state_uart == DATA) ? 1'b0 : 1'b1;

    contador #(.MAX_VALUE(WIDTH_MSG+1)) cont_uart_inst (
        .clk(uart_clk),
        .rst(cont_uart_rst),
        .cont(cont_uart)
    );



    always_comb begin
        case (current_state_uart)
            IDLE:       next_state_uart = (start_uart) ? DATA : IDLE;
            DATA:       next_state_uart = (cont_uart == WIDTH_MSG+1) ? IDLE : DATA;
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