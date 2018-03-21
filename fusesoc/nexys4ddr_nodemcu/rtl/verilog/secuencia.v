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
	output reg [3:0] an
	);


	reg [1:0]CurrentState;
	reg [1:0]NextState;
	parameter A=2'b00;
	parameter B=2'b01;
	parameter C=2'b10;
	parameter D=2'b11; 
	
	//ver NS
	always @(*)
		begin
			case (CurrentState)
				A: NextState <= B;
				B: NextState <= C;
				C: NextState <= D;
				D: NextState <= A;
				default : NextState <= A;
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
	//outputs
	always @(*)
		begin
			case (CurrentState)
				A: an<= 4'b0111;
				B: an<= 4'b1011;
				C: an<= 4'b1101;
				D: an<= 4'b1110;
				default : an<=4'b1111;
			endcase	
		end

endmodule
