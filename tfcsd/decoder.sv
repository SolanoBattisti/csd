module decoder #(
    parameter int IN_WIDTH = 3,
    parameter int OUT_WIDTH = 2**IN_WIDTH
)(
    input logic [IN_WIDTH-1:0] in,
    output logic [OUT_WIDTH-1:0] out
);

    assign out = {{(OUT_WIDTH-1){1'b0}}, 1'b1} << in;

endmodule
