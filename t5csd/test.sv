// ============================================================================
// Experiência 5 - Controlador VGA
// Construção de Sistemas Digitais - PUCRS
//
// Resolução : 640x480 @ 60 Hz (h_sync negativo, v_sync negativo)
// Clock     : 100 MHz -> habilitação de pixel a cada 4 ciclos = 25 MHz
//             (a norma pede 25,175 MHz; 25 MHz é aceito pelos monitores)
// Objeto    : quadrado de 64x64 pixels movido por left/right/up/down
// ============================================================================
module vga_controller (
    input  logic       clock,        // 100 MHz
    input  logic       reset,        // assíncrono, ativo em nível alto
    input  logic       left,
    input  logic       right,
    input  logic       up,
    input  logic       down,
    output logic [3:0] color_red,
    output logic [3:0] color_green,
    output logic [3:0] color_blue,
    output logic       vga_hs,
    output logic       vga_vs
);

    // ------------------------------------------------------------------
    // Parâmetros de temporização (Tabela 2 - 640x480 @ 60 Hz)
    // ------------------------------------------------------------------
    localparam int H_DISPLAY = 800;
    localparam int H_FP      = 56;
    localparam int H_SYNC    = 120;
    localparam int H_BP      = 64;
    localparam int H_TOTAL   = H_DISPLAY + H_FP + H_SYNC + H_BP;  // 800

    localparam int V_DISPLAY = 600;
    localparam int V_FP      = 37;
    localparam int V_SYNC    = 6;
    localparam int V_BP      = 23;
    localparam int V_TOTAL   = V_DISPLAY + V_FP + V_SYNC + V_BP;  // 525

    // ------------------------------------------------------------------
    // Parâmetros do objeto
    // ------------------------------------------------------------------
    localparam int SIZE   = 64;   // lado do quadrado (>= 50 pixels)
    localparam int STEP   = 2;    // pixels deslocados por quadro (~120 px/s)
    localparam int X_INIT = (H_DISPLAY - SIZE) / 2;
    localparam int Y_INIT = (V_DISPLAY - SIZE) / 2;

    // ------------------------------------------------------------------
    // Sincronização dos botões (2 flip-flops) para evitar metaestabilidade
    // ------------------------------------------------------------------
    logic left_subida, right_subida, up_subida, down_subida;

    detector_de_borda detector_left (
        .clock(clock),
        .data(left),
        .subida(left_subida),
        .descida()
    );

    detector_de_borda detector_right (
        .clock(clock),
        .data(right),
        .subida(right_subida),
        .descida()
    );

    detector_de_borda detector_up (
        .clock(clock),
        .data(up),
        .subida(up_subida),
        .descida()
    );

    detector_de_borda detector_down (
        .clock(clock),
        .data(down),
        .subida(down_subida),
        .descida()
    );

    // ------------------------------------------------------------------
    // Habilitação de pixel: 100 MHz / 4 = 25 MHz
    // ------------------------------------------------------------------
    logic pix_clk;
    divisor_clock #(.DIVISOR(2), .DUTY_CYCLE(50) ) divisor_clock_inst (
        .clk_in(clock),
        .clk_out(pix_clk)
    );


    // ------------------------------------------------------------------
    // Contadores horizontal e vertical
    // ------------------------------------------------------------------
    logic [9:0] h_count, v_count;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else if (pix_clk) begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1) v_count <= 10'd0;
                else                        v_count <= v_count + 10'd1;
            end else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    // ------------------------------------------------------------------
    // Sinais de sincronismo (pulso em nível baixo) e região visível
    // ------------------------------------------------------------------
    logic hs_int, vs_int, video_on;

    assign hs_int = ((h_count >= H_DISPLAY + H_FP) &&
                      (h_count <  H_DISPLAY + H_FP + H_SYNC));

    assign vs_int = ((v_count >= V_DISPLAY + V_FP) &&
                      (v_count <  V_DISPLAY + V_FP + V_SYNC));

    assign video_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

    // ------------------------------------------------------------------
    // Posição do objeto: atualizada uma vez por quadro (início do blanking
    // vertical), o que dá velocidade constante e evita "tearing"
    // ------------------------------------------------------------------
    logic [9:0] obj_x, obj_y;
    logic       frame_tick;

    assign frame_tick = pix_clk && (h_count == 10'd0) && (v_count == V_DISPLAY);

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            obj_x <= X_INIT[9:0];
            obj_y <= Y_INIT[9:0];
        end else if (frame_tick) begin
            // Eixo X (se left e right juntos, left tem prioridade)
            if (left_subida) begin
                if (obj_x >= STEP) obj_x <= obj_x - STEP[9:0];
                else               obj_x <= 10'd0;
            end else if (right_subida) begin
                if (obj_x + SIZE + STEP <= H_DISPLAY) obj_x <= obj_x + STEP[9:0];
                else                                  obj_x <= H_DISPLAY[9:0] - SIZE[9:0];
            end

            // Eixo Y (se up e down juntos, up tem prioridade)
            if (up_subida) begin
                if (obj_y >= STEP) obj_y <= obj_y - STEP[9:0];
                else               obj_y <= 10'd0;
            end else if (down_subida) begin
                if (obj_y + SIZE + STEP <= V_DISPLAY) obj_y <= obj_y + STEP[9:0];
                else                                  obj_y <= V_DISPLAY[9:0] - SIZE[9:0];
            end
        end
    end

    // ------------------------------------------------------------------
    // Geração da cor
    // ------------------------------------------------------------------
    logic in_object;

    assign in_object = (h_count >= obj_x) && (h_count < obj_x + SIZE) &&
                       (v_count >= obj_y) && (v_count < obj_y + SIZE);

    // ------------------------------------------------------------------
    // Registradores de saída (eliminam glitches nas saídas VGA)
    // Fora da região visível o barramento de cor fica em preto (0).
    // ------------------------------------------------------------------
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            color_red   <= 4'h0;
            color_green <= 4'h0;
            color_blue  <= 4'h0;
            vga_hs      <= 1'b0;
            vga_vs      <= 1'b0;
        end else begin
            vga_hs <= hs_int;
            vga_vs <= vs_int;

            if (!video_on) begin
                color_red   <= 4'h0;
                color_green <= 4'h0;
                color_blue  <= 4'h0;
            end else if (in_object) begin       // objeto: branco
                color_red   <= 4'hF;
                color_green <= 4'hF;
                color_blue  <= 4'hF;
            end else begin                      // fundo: azul escuro
                color_red   <= 4'h0;
                color_green <= 4'h0;
                color_blue  <= 4'h4;
            end
        end
    end

endmodule