module vga_controller (
    input logic clock,
    input logic reset, 
    input logic left,
    input logic right,
    input logic up,
    input logic down,
    output logic [3:0] color_red,
    output logic [3:0] color_green,
    output logic [3:0] color_blue,
    output logic vga_hs,
    output logic vga_vs
);

    localparam int H_DISPLAY = 640;
    localparam int H_FP = 16;
    localparam int H_SYNC = 96;
    localparam int H_BP = 48;
    localparam int H_TOTAL = H_DISPLAY + H_FP + H_SYNC + H_BP;

    localparam int V_DISPLAY = 480;
    localparam int V_FP = 10;
    localparam int V_SYNC = 2;
    localparam int V_BP = 33;
    localparam int V_TOTAL = V_DISPLAY + V_FP + V_SYNC + V_BP;  // 525

    // Objeto
    localparam int SIZE = 80; 
    localparam int X_INICIAL = (H_DISPLAY-SIZE)/2;
    localparam int Y_INICIAL = (V_DISPLAY-SIZE)/2;

    // Sincronização botões
    logic [3:0] buttons_q;
    logic [3:0] buttons_qq;

    logic left_qq;
    logic right_qq;
    logic up_qq;
    logic down_qq;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            buttons_q <= 4'b0000;
            buttons_qq <= 4'b0000;
        end else begin
            buttons_q <= {left, right, up, down};
            buttons_qq <= buttons_q;
        end
    end

    assign {left_qq, right_qq, up_qq, down_qq} = buttons_qq;


    logic [1:0] div_cnt;
    logic pix_clk;

    divisor_clock #(.DIVISOR(4), .DUTY_CYCLE(25) ) divisor_clock_inst (     // 25 MHz
        .clk_in(clock),
        .clk_out(pix_clk)
    );

    logic [9:0] h_count, v_count;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else if (pix_clk) begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1) v_count <= 10'd0;
                else v_count <= v_count + 10'd1;
            end 
            else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    // h_sync
    logic vga_hs_comb;
    assign vga_hs_comb = ~((h_count >= H_DISPLAY + H_FP) && (h_count <  H_DISPLAY + H_FP + H_SYNC));

    // v_sync
    logic vga_vs_comb;
    assign vga_vs_comb = ~((v_count >= V_DISPLAY + V_FP) && (v_count <  V_DISPLAY + V_FP + V_SYNC));

    
    // posicao objeto
    logic [9:0] obj_x, obj_y;
    logic frame_tick;

    assign frame_tick = pix_clk && (h_count == 10'd0) && (v_count == V_DISPLAY);

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            obj_x <= X_INICIAL[9:0];
            obj_y <= Y_INICIAL[9:0];
        end else if (frame_tick) begin
            if (left_qq) begin
                if (obj_x >= 1) obj_x <= obj_x - 10'd1;
                else obj_x <= 10'd0;
            end 
            else if (right_qq) begin
                if (obj_x + SIZE <= H_DISPLAY - 1) obj_x <= obj_x + 10'd1;
                else obj_x <= H_DISPLAY[9:0] - SIZE[9:0];
            end

            if (up_qq) begin
                if (obj_y >= 1) obj_y <= obj_y - 10'd1;
                else obj_y <= 10'd0;
            end else if (down_qq) begin
                if (obj_y + SIZE <= V_DISPLAY - 1) obj_y <= obj_y + 10'd1;
                else obj_y <= V_DISPLAY[9:0] - SIZE[9:0];
            end
        end
    end

    // Cor
    logic in_object;
    assign in_object = (h_count >= obj_x) && (h_count < obj_x + SIZE) &&
                       (v_count >= obj_y) && (v_count < obj_y + SIZE);

    logic display_time;
    assign display_time = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            color_red   <= 4'h0;
            color_green <= 4'h0;
            color_blue  <= 4'h0;
            vga_hs      <= 1'b1;
            vga_vs      <= 1'b1;
        end else begin
            vga_hs <= vga_hs_comb;
            vga_vs <= vga_vs_comb;

            if (!display_time) begin
                color_red   <= 4'h0;
                color_green <= 4'h0;
                color_blue  <= 4'h0;
            end else if (in_object) begin       // objeto: branco
                color_red   <= 4'hE;
                color_green <= 4'hE;
                color_blue  <= 4'h2;
            end else begin                      // fundo: azul escuro
                color_red   <= 4'h7;
                color_green <= 4'h0;
                color_blue  <= 4'h0;
            end
        end
    end

endmodule