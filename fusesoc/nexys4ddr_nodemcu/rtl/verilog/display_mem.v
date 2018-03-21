`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:48:31 11/04/2013 
// Design Name: 
// Module Name:    display_mem 
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
module display_mem(
	input [15:0] d_in,
	input w,
	input reset,
	input [3:0] sel,
	output reg [3:0] d_out
    );

reg [3:0] q1;
reg [3:0] q2;
reg [3:0] q3;
reg [3:0] q4;


always @(posedge w)
	begin
		if(reset==1)
			begin
			q1<=4'b0000;
			q2<=4'b0000;
			q3<=4'b0000;
			q4<=4'b0000;
			end
		else	
			begin
			q1<=d_in[3:0];
			q2<=d_in[7:4];
			q3<=d_in[11:8];
			q4<=d_in[15:12];
			end
	end


//MUX
always @(*)
	begin
		case (sel)
			4'b1110: d_out <= q1;
			4'b1101: d_out <= q2;
			4'b1011: d_out <= q3;
			4'b0111: d_out <= q4;
			default: d_out <= q1;
		endcase
	end

endmodule
