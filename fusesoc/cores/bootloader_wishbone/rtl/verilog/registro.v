`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:11:12 12/10/2013 
// Design Name: 
// Module Name:    registro 
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
module registro(
	input clk,
	input cl,
	input w,
	input [WIDTH - 1:0] din,
	output reg [WIDTH - 1:0] dout
    );

    parameter WIDTH = 8;

	always @(posedge clk)
	begin
		if (cl == 1)
			dout<=0;
		else if (w==1)
			dout<=din;
		else
			dout<=dout;
	end
endmodule
