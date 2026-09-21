module contador_pontos #(
    parameter int MAX_POINTS = 15
)(
    input logic clk,
    input logic rst,
    input logic incr,
    input logic decr,

    output logic [$clog2(MAX_POINTS)-1:0] pontos
);

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            pontos <= '0;
        end else begin
            if(incr) begin
                if(pontos >= MAX_POINTS) pontos <= pontos;
                else pontos <= pontos + 1;
            end
            else if(decr) begin
                if(pontos != 0) pontos <= pontos - 1'b1; 
                else pontos <= '0;  // Evita que pontos baixe de zero
            end
        end
    end

endmodule