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
	input [31:0] d_in,
	input w,
	input reset,
	input [7:0] sel,
	output reg [3:0] d_out
    );

reg [3:0] q1;
reg [3:0] q2;
reg [3:0] q3;
reg [3:0] q4;
reg [3:0] q5;
reg [3:0] q6;
reg [3:0] q7;
reg [3:0] q8;


always @(posedge w)
	begin
		if(reset==1)
			begin
			q1<=4'b0000;
			q2<=4'b0000;
			q3<=4'b0000;
			q4<=4'b0000;
			q5<=4'b0000;
			q6<=4'b0000;
			q7<=4'b0000;
			q8<=4'b0000;
			end
		else
			begin
			q1<=d_in[3:0];
			q2<=d_in[7:4];
			q3<=d_in[11:8];
			q4<=d_in[15:12];
			q5<=d_in[19:16];
			q6<=d_in[23:20];
			q7<=d_in[27:24];
			q8<=d_in[31:28];
			end
	end


//MUX
always @(*)
	begin
		case (sel)
			8'b11111110: d_out <= q1;
			8'b11111101: d_out <= q2;
			8'b11111011: d_out <= q3;
			8'b11110111: d_out <= q4;
			8'b11101111: d_out <= q5;
			8'b11011111: d_out <= q6;
			8'b10111111: d_out <= q7;
			8'b01111111: d_out <= q8;
			default: d_out <= q1;
		endcase
	end

endmodule
