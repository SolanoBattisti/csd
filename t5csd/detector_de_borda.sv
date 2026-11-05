module detector_de_borda (
    input logic clock,

    input logic data,

    output logic subida,
    output logic descida
);

    logic reg_a;
    logic reg_b;

    always_ff @(posedge clock) begin
        reg_a <= data;
        reg_b <= reg_a;
    end

    assign subida = (reg_a && !reg_b);
    assign descida = (!reg_a && reg_b);

endmodule