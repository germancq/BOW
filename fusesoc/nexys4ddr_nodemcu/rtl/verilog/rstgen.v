module rstgen
       (
	// Main clocks in, depending on board
	input  sys_clk_pad_i,
	// Asynchronous, active low reset in
	input  rst_n_pad_i,
	input locked_mcm,

	// Wishbone clock and reset out
	input wb_clk,

	output wb_rst_o,
	output ddr2_if_rst_o
);

//
// Reset generation
//
//

// Reset generation for wishbone
reg [15:0] 	   wb_rst_shr;
always @(posedge wb_clk or posedge rst_n_pad_i)
	if (rst_n_pad_i)
		wb_rst_shr <= 16'hffff;
	else
		wb_rst_shr <= {wb_rst_shr[14:0], ~(locked_mcm)};

assign wb_rst_o = ~ rst_n_pad_i;//wb_rst_shr[15];

assign ddr2_if_rst_o = rst_n_pad_i;

endmodule // clkgen
