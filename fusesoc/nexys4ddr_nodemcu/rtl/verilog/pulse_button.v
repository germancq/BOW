// Design: pulse button
// Description: 
// Author: German Cano Quiveu <germancq@dte.us.es>
// Copyright Universidad de Sevilla, Spain
// Rev: 4, sep 2017

module pulse_button(
	input clk,
	input reset,
	input button,
	output pulse);

wire currentValue_q;
wire currentValue_not_q;
wire previousValue_q;
wire previousValue_not_q;

biestable_d currentValue(
	.clk(clk),
	.reset(reset),
	.d(button),
	.q(currentValue_q),
	.not_q(currentValue_not_q)
);

biestable_d previousValue(
	.clk(clk),
	.reset(reset),
	.d(currentValue_q),
	.q(previousValue_q),
	.not_q(previousValue_not_q)
);

and_gate and1(
	.a(currentValue_q),
	.b(previousValue_not_q),
	.c(pulse)
);

endmodule
