/*
	Prof. Marlon Moraes
	marlon.moraes@pucrs.br
*/

module divisor_clock
#(
	parameter int	DIVISOR		= 10,
	parameter int	DUTY_CYCLE	= 50
)
(
	input	logic	clk_in,
	output	logic	clk_out
);

	const real	DUTY_CYCLE_CALC	= real'(DIVISOR)*(real'(DUTY_CYCLE) / 100);	// duty cycle calculado.
	int			cont			= 0;										// contador da divisão.

	// referência da divisão.
	always_ff @(posedge clk_in)
	begin
		if (cont < DIVISOR-1)
			cont <= cont + 1;
		else
			cont <= 0;
			
		if (cont < int'(DUTY_CYCLE_CALC))
			clk_out	<= 1'b1;
		else
			clk_out	<= 1'b0;
			
	end


endmodule