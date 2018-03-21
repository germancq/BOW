// Design: generic MUX
// Description: 
// Author: German Cano Quiveu <germancq@dte.us.es>
// Copyright Universidad de Sevilla, Spain
// Rev: 29, aug 2017

module generic_mux #(parameter WIDTH=32)
(
	input [WIDTH-1:0] a,
	input [WIDTH-1:0] b,
	output reg [WIDTH-1:0] c,
	input ctl);

always @(*)
begin
	if (ctl)
		c = b;
	else
		c = a;
end

//assign c = ctl ? a : b; only wires can be assigned in that way

endmodule