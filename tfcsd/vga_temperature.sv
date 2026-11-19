module vga_temperature #(
    parameter int REG_SIZE = 100
)(
    input logic clock,
    input logic reset,
    input logic [11:0] temp_data,
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
    localparam int SIZE = 10; 
    localparam int X1 = 7*(H_DISPLAY-SIZE)/8 - 20;
    localparam int Y1 = 7*(V_DISPLAY-SIZE)/8;

    localparam int X2 = 7*(H_DISPLAY-SIZE)/8 - 11;
    localparam int Y2 = 7*(V_DISPLAY-SIZE)/8;

    localparam int X3 = 7*(H_DISPLAY-SIZE)/8;
    localparam int Y3 = 7*(V_DISPLAY-SIZE)/8;

    localparam int X4 = 7*(H_DISPLAY-SIZE)/8 + 9;
    localparam int Y4 = 7*(V_DISPLAY-SIZE)/8;

    localparam int XP = X3 - 2;
    localparam int YP = 7*(V_DISPLAY-SIZE)/8 + 8;

    // ==============================================================================
    //  GRÁFICO

    localparam int LOWER_LIMIT = 5*(V_DISPLAY-SIZE)/6 + 1;

    logic graph_clk;
    divisor_clock #(.DIVISOR(100_000_000), .DUTY_CYCLE(50) ) graph_clk_inst (     // 1 Hz
        .clk_in(clock),
        .clk_out(graph_clk)
    );


    logic [11:0] shift_reg [0:REG_SIZE-1];

    genvar i;
    generate
        for(i=0; i < REG_SIZE-2; i++) begin
            always_ff @(posedge graph_clk or posedge reset) begin
                if(reset) shift_reg[i+1] <= '0;
                else shift_reg[i+1] <= shift_reg[i];
            end
        end
    endgenerate

    // Same Shift Reg Logic for the first and last registers
    always_ff @(posedge graph_clk or posedge reset) begin
        if(reset) begin
            shift_reg[0] <= '0;
            shift_reg[REG_SIZE-1] <= '0;
        end
        else begin
            shift_reg[0] <= temp_data;
            shift_reg[REG_SIZE-1] <= shift_reg[REG_SIZE-2];
        end
    end

    logic [9:0] x_points [0:REG_SIZE-1];    
    logic [9:0] y_points [0:REG_SIZE-1];
    genvar j;
    generate
        for(j=0; j < REG_SIZE; j++) begin
            assign x_points[j] = 10'd620 - 6*j;
            assign y_points[j] = 10'd600 - (shift_reg[j]);
        end
    endgenerate



    // ==============================================================================

    logic [1:0] div_cnt;
    logic pix_clk;

    divisor_clock #(.DIVISOR(4), .DUTY_CYCLE(25) ) pix_clk_inst (     // 25 MHz
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
    //logic [9:0] X1, Y1;
    logic frame_tick;

    assign frame_tick = pix_clk && (h_count == 10'd0) && (v_count == V_DISPLAY);

    // =================================================
    logic [21:0] pre_temp;
    assign pre_temp = (temp_data * 100);

    logic [21:0] temperature;
    assign temperature = pre_temp >> 4;

    logic [3:0] temperatura_dezena;
    logic [3:0] temperatura_unidade;
    logic [3:0] temperatura_decimo;
    logic [3:0] temperatura_centesimo;
    always_comb begin 
        temperatura_dezena = (temperature / 1000) % 10;
        temperatura_unidade = (temperature / 100) % 10;
        temperatura_decimo = (temperature / 10) % 10;
        temperatura_centesimo = (temperature % 10);
    end
    // ===================================================

    logic [0:9][0:9] matrix1;
    bin_to_vga bin_to_vga_inst1 (
        .number(temperatura_dezena),
        .matrix(matrix1)
    );

    logic [0:9][0:9] matrix2;
    bin_to_vga bin_to_vga_inst2 (
        .number(temperatura_unidade),
        .matrix(matrix2)
    );

    logic [0:9][0:9] matrix3;
    bin_to_vga bin_to_vga_inst3 (
        .number(temperatura_decimo),
        .matrix(matrix3)
    );

    logic [0:9][0:9] matrix4;
    bin_to_vga bin_to_vga_inst4 (
        .number(temperatura_centesimo),
        .matrix(matrix4)
    );


    logic [REG_SIZE-1:0] in_graph;
    genvar k;
    generate
        for(k=0; k < REG_SIZE; k++) begin
            assign in_graph[k] = (h_count == x_points[k]) && (v_count == y_points[k]);
        end
    endgenerate

    logic in_object;
    //assign in_object = (h_count >= X1) && (h_count < X1 + SIZE) &&
     //                  (v_count >= Y1) && (v_count < Y1 + SIZE);

    always_comb begin
        if (((h_count >= X3) && (h_count < X3 + 2) && 
            (v_count >= YP) && (v_count < YP + 2)) || v_count == LOWER_LIMIT) begin

            in_object = 1'b1;
        end
        else if ((h_count >= X1) && (h_count < X1 + SIZE) && 
            (v_count >= Y1) && (v_count < Y1 + SIZE)) begin

            in_object = matrix1[h_count-X1][v_count-Y1];

        end
        else if ((h_count >= X2) && (h_count < X2 + SIZE) && 
            (v_count >= Y2) && (v_count < Y2 + SIZE)) begin

            in_object = matrix2[h_count-X2][v_count-Y2];
        end
        else if ((h_count >= X3) && (h_count < X3 + SIZE) && 
            (v_count >= Y3) && (v_count < Y3 + SIZE)) begin

            in_object = matrix3[h_count-X3][v_count-Y3];
        end
        else if ((h_count >= X4) && (h_count < X4 + SIZE) && 
            (v_count >= Y4) && (v_count < Y4 + SIZE)) begin

            in_object = matrix4[h_count-X4][v_count-Y4];

        end
        else in_object = |in_graph;
    end
    
    // always_ff @(posedge clock or posedge reset) begin
    //     if (reset) begin
    //         X1 <= X1[9:0];
    //         Y1 <= Y1[9:0];
    //     end else if (frame_tick) begin
    //         if (left_qq) begin
    //             if (X1 >= 1) X1 <= X1 - 10'd1;
    //             else X1 <= 10'd0;
    //         end 
    //         else if (right_qq) begin
    //             if (X1 + SIZE <= H_DISPLAY - 1) X1 <= X1 + 10'd1;
    //             else X1 <= H_DISPLAY[9:0] - SIZE[9:0];
    //         end

    //         if (up_qq) begin
    //             if (Y1 >= 1) Y1 <= Y1 - 10'd1;
    //             else Y1 <= 10'd0;
    //         end else if (down_qq) begin
    //             if (Y1 + SIZE <= V_DISPLAY - 1) Y1 <= Y1 + 10'd1;
    //             else Y1 <= V_DISPLAY[9:0] - SIZE[9:0];
    //         end
    //     end
    // end

    // Cor
    

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