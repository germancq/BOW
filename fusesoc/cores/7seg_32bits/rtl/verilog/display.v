`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    11:58:38 11/11/2013
// Design Name:
// Module Name:    display
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module display(
	input extclk,
	input reset,
	input [31:0] din,
	input w_display,
	output [6:0] seg,
	output [7:0] an
    );




	 wire [31:0] q;
	 wire [3:0] num;

	 contador c1 (.clk(extclk),.rst(reset),.q(q));
	 secuencia s1 (.clk(q[15]),.rst(reset),.an(an));
	 display_mem d1 (.d_in(din),.w(q[22]),.reset(reset),.sel(an),.d_out(num));
	 convertidor_bin7seg seg1 (.bin_in(num),.a(seg[0]),.b(seg[1]),.c(seg[2]),.d(seg[3]),.e(seg[4]),.f(seg[5]),.g(seg[6]));

endmodule
