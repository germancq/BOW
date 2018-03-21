// Design: D-biestable
// Description: 
// Author: German Cano Quiveu <germancq@dte.us.es>
// Copyright Universidad de Sevilla, Spain
// Rev: 4, sep 2017

module biestable_d(
	input clk,
	input reset,
	input d,
	output reg q,
	output not_q);

always @(posedge clk)
begin
	if(reset == 1'b1)
		q <= 1'b0;
	else
		q <= d;
end

assign not_q = ~q;

endmodule
