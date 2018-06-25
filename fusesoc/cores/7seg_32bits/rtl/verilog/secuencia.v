`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    10:38:19 10/28/2013
// Design Name:
// Module Name:    secuencia
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
module secuencia(
	input clk,
	input rst,
	output reg [7:0] an
	);


	reg [2:0]CurrentState;
	reg [2:0]NextState;
	parameter A=3'b000;
	parameter B=3'b001;
	parameter C=3'b010;
	parameter D=3'b011;
	parameter E=3'b100;
	parameter F=3'b101;
	parameter G=3'b110;
	parameter H=3'b111;

	//ver NS
	always @(*)
		begin
			case (CurrentState)
				A: NextState <= B;
				B: NextState <= C;
				C: NextState <= D;
				D: NextState <= E;
				E: NextState <= F;
				F: NextState <= G;
				G: NextState <= H;
				H: NextState <= A;
				default : NextState <= A;
			endcase
		end

	//outputs
	always @(*)
		begin
			case (CurrentState)
				A: an<= 8'b01111111;
				B: an<= 8'b10111111;
				C: an<= 8'b11011111;
				D: an<= 8'b11101111;
				E: an<= 8'b11110111;
				F: an<= 8'b11111011;
				G: an<= 8'b11111101;
				H: an<= 8'b11111110;
				default : an<=8'b11111111;
			endcase
		end

	//registro
	always @(posedge clk)
		begin
			if (rst==1)
				CurrentState <= A;
			else
				CurrentState <= NextState;
		end


endmodule

