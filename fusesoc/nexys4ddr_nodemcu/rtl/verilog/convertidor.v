// Design: Convertidor binario a 7 segmentos
// Description: 
// Author: Paulino Ruiz de Clavijo <paulino@dte.us.es>
// Copyright Universidad de Sevilla, Spain
// Rev: 1, feb 2011

module convertidor_bin7seg(
	input  [3:0] bin_in,	      // entrada binaria 4 bits
	output reg a,b,c,d,e,f,g);	// salida 7-segmentos

	// Escriba aqui el código
	// Se recomienda utilizar un proceso always con
	// una sentencia case
	reg [6:0] salida; 
	
	always @(*)
		begin
			salida <= {a,b,c,d,e,f,g};
			case (bin_in)
				4'h0 : salida<=8'h1;
				4'h1 : salida<=8'b1001111;
				4'h2 : salida<=8'b0010010;				
				4'h3 : salida<=8'b0000110;		
				4'h4 : salida<=8'b1001100;
				4'h5 : salida<=8'b0100100;
				4'h6 : salida<=8'b0100000;
				4'h7 : salida<=8'b0001111;
				4'h8 : salida<=8'b0000000;
				4'h9 : salida<=8'b0000100;
				4'hA : salida<=8'b0001000;
				4'hB : salida<=8'b1100000;
				4'hC : salida<=8'b0110001;
				4'hD : salida<=8'b1000010;
				4'hE : salida<=8'b0110000;
				4'hF : salida<=8'b0111000;
				default: salida<=8'b1111111;
			endcase
		a<=salida[6];	
		b<=salida[5];
		c<=salida[4];
		d<=salida[3];
		e<=salida[2];
		f<=salida[1];
		g<=salida[0];	
	end 
	
endmodule	//  convertidor_bin7seg