`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:57:40 10/28/2013 
// Design Name: 
// Module Name:    contador 
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
module contador(
	input clk,
	input rst,
	output reg [31:0] q
    );
	 
 always @(posedge clk)
	begin
	if (rst == 1)
		q<=0;
	else 
		q<=q+1;
	end


endmodule
