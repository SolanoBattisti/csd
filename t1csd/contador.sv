module contador #(
    parameter int MAX_VALUE = 8    
)(
    input logic clk,
    input logic rst,
    
    output logic [$clog2(MAX_VALUE)-1:0] cont
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cont <= '0;
        end
        else begin
            cont <= cont + 1;
        end
    end

endmodule