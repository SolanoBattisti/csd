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
    localparam int H_DISPLAY = 640;
    localparam int H_FP      = 16;
    localparam int H_SYNC    = 96;
    localparam int H_BP      = 48;
    localparam int H_TOTAL   = H_DISPLAY + H_FP + H_SYNC + H_BP;  // 800

    localparam int V_DISPLAY = 480;
    localparam int V_FP      = 10;
    localparam int V_SYNC    = 2;
    localparam int V_BP      = 33;
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
    logic [3:0] btn_meta, btn_sync;
    logic       left_s, right_s, up_s, down_s;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            btn_meta <= 4'b0000;
            btn_sync <= 4'b0000;
        end else begin
            btn_meta <= {left, right, up, down};
            btn_sync <= btn_meta;
        end
    end

    assign {left_s, right_s, up_s, down_s} = btn_sync;

    // ------------------------------------------------------------------
    // Habilitação de pixel: 100 MHz / 4 = 25 MHz
    // ------------------------------------------------------------------
    logic [1:0] div_cnt;
    logic       pix_tick;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) div_cnt <= 2'd0;
        else       div_cnt <= div_cnt + 2'd1;
    end

    assign pix_tick = (div_cnt == 2'd3);

    // ------------------------------------------------------------------
    // Contadores horizontal e vertical
    // ------------------------------------------------------------------
    logic [9:0] h_count, v_count;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else if (pix_tick) begin
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

    assign hs_int = ~((h_count >= H_DISPLAY + H_FP) &&
                      (h_count <  H_DISPLAY + H_FP + H_SYNC));

    assign vs_int = ~((v_count >= V_DISPLAY + V_FP) &&
                      (v_count <  V_DISPLAY + V_FP + V_SYNC));

    assign video_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

    // ------------------------------------------------------------------
    // Posição do objeto: atualizada uma vez por quadro (início do blanking
    // vertical), o que dá velocidade constante e evita "tearing"
    // ------------------------------------------------------------------
    logic [9:0] obj_x, obj_y;
    logic       frame_tick;

    assign frame_tick = pix_tick && (h_count == 10'd0) && (v_count == V_DISPLAY);

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            obj_x <= X_INIT[9:0];
            obj_y <= Y_INIT[9:0];
        end else if (frame_tick) begin
            // Eixo X (se left e right juntos, left tem prioridade)
            if (left_s) begin
                if (obj_x >= STEP) obj_x <= obj_x - STEP[9:0];
                else               obj_x <= 10'd0;
            end else if (right_s) begin
                if (obj_x + SIZE + STEP <= H_DISPLAY) obj_x <= obj_x + STEP[9:0];
                else                                  obj_x <= H_DISPLAY[9:0] - SIZE[9:0];
            end

            // Eixo Y (se up e down juntos, up tem prioridade)
            if (up_s) begin
                if (obj_y >= STEP) obj_y <= obj_y - STEP[9:0];
                else               obj_y <= 10'd0;
            end else if (down_s) begin
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
            vga_hs      <= 1'b1;
            vga_vs      <= 1'b1;
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