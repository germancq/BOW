// Design: Bootloader module
// Description: 
// Author: German Cano Quiveu <germancq@dte.us.es>
// Copyright Universidad de Sevilla, Spain


module bootloader_module (
  input clk,
  input button,
  input reset,
  input i_spi_start,
  input i_spi_comm,
  output reg o_cpu_rst,
  input i_ram_ack,
  input i_spi_eof,
  input i_spi_done,
  input [7:0] i_spi_data,
  output reg o_spi_byte,
  output reg o_ram_rst,
  output reg o_ram_we,
  output reg o_ram_cyc,
  output reg o_ram_stb,
  output reg o_ram_cti,
  output reg [3:0] o_ram_sel,
  output reg [31:0] o_ram_data,
  output reg [31:0] o_ram_addr,
  output reg o_mux,
  output  [3:0] debug_leds);

parameter SDSPI_DATA_WIDTH = 32;

reg [3:0] current_state;
reg [3:0] next_state;

assign debug_leds = current_state;

parameter IDLE = 4'h0;
parameter IDLE_BLOCK = 4'h1;
parameter READ_BLOCK = 4'h2;

parameter WRITE_BLOCK = 4'h3;
parameter IDLE_TOTAL_BYTES = 4'h4;
parameter READ_TOTAL_BYTES = 4'h5;
parameter WRITE_TOTAL_BYTES = 4'h6;
parameter IDLE_DATA = 4'h7;
parameter READ_DATA_BYTES = 4'h8;
parameter LOAD_DATA = 4'h9;
parameter POST_LOAD = 4'ha;
parameter READ_BYTE = 4'hb;
parameter UP_WORD_BYTE = 4'hc;
parameter WAIT_COUNTER = 4'hd;


reg up;
wire [31:0] counter_o;
reg rst_counter;
reg [31:0] address_ram;

contador_up counter0(
   .clk(clk),
   .rst(rst_counter),
   .up(up),
   .q(counter_o)
);


reg rst_counter_word;
wire [31:0] counter_word_o;
reg up_word;
assign counter_word = counter_word_o[2];

contador_up counter2(
   .clk(clk),
   .rst(rst_counter_word),
   .up(up_word),
   .q(counter_word_o)
);

reg up_bytes;
wire [31:0] counter_bytes;
reg rst_counter_bytes;

contador_up counter_1(
   .clk(clk),
   .rst(rst_counter_bytes),
   .up(up_bytes),
   .q(counter_bytes)
);
/*
reg up_div_clk;
wire [31:0] counter_div;
reg rst_counter_div;

contador_up counter_2(
   .clk(clk),
   .rst(rst_counter_div),
   .up(up_div_clk),
   .q(counter_div)
);
*/
wire[31:0] reg_block_bumber;
reg r_block_cl;
reg r_block_w;
registro #(.WIDTH(32)) r_block_0(
    .clk(clk),
    .cl(r_block_cl),
    .w(r_block_w),
    .din(reg_sdspi_data),
    .dout(reg_block_bumber)
);

wire[31:0] reg_total_bytes;
reg r_total_bytes_cl;
reg r_total_bytes_w;
registro #(.WIDTH(32)) r_total_bytes_0(
    .clk(clk),
    .cl(r_total_bytes_cl),
    .w(r_total_bytes_w),
    .din(reg_sdspi_data),
    .dout(reg_total_bytes)
);

wire [7:0] reg_state_prev;
reg r_state_prev_cl;
reg r_state_prev_w;
registro r_state_prev_0(
    .clk(clk),
    .cl(r_state_prev_cl),
    .w(r_state_prev_w),
    .din({4'b0000,current_state}),
    .dout(reg_state_prev)
);

wire [31:0] reg_sdspi_data;
wire [7:0] reg_sdspi_data_0,reg_sdspi_data_1,reg_sdspi_data_2,reg_sdspi_data_3;
assign reg_sdspi_data = {reg_sdspi_data_3,reg_sdspi_data_2,reg_sdspi_data_1,reg_sdspi_data_0};
reg reg_sdspi_data_0_cl;
reg reg_sdspi_data_0_w;
registro r0(
	.clk(clk),
	.cl(reg_sdspi_data_0_cl),
	.w(reg_sdspi_data_0_w),
	.din(i_spi_data),
	.dout(reg_sdspi_data_0)
);
reg reg_sdspi_data_1_cl;
reg reg_sdspi_data_1_w;
registro r1(
	.clk(clk),
	.cl(reg_sdspi_data_1_cl),
	.w(reg_sdspi_data_1_w),
	.din(i_spi_data),
	.dout(reg_sdspi_data_1)
);
reg reg_sdspi_data_2_cl;
reg reg_sdspi_data_2_w;
registro r2(
	.clk(clk),
	.cl(reg_sdspi_data_2_cl),
	.w(reg_sdspi_data_2_w),
	.din(i_spi_data),
	.dout(reg_sdspi_data_2)
);
reg reg_sdspi_data_3_cl;
reg reg_sdspi_data_3_w;
registro r3(
	.clk(clk),
	.cl(reg_sdspi_data_3_cl),
	.w(reg_sdspi_data_3_w),
	.din(i_spi_data),
	.dout(reg_sdspi_data_3)
);

wire btn_pulse;
reg reset_button;
pulse_button btn0(
    .clk(clk),
    .reset(reset_button),
    .button(button),
    .pulse(btn_pulse)
);

reg [31:0] reg_ram_data;
initial current_state = IDLE;


//Next State
always @(*)
begin
	next_state = current_state;

	case(current_state)
		IDLE:
			begin
				if(i_spi_start == 1'b1)
					next_state = IDLE_BLOCK;
			end
		IDLE_BLOCK:
		    begin 
		       if(i_spi_comm == 1'b1)
		            next_state = READ_BLOCK;    
		    end	
		READ_BLOCK:
		    begin
		        if(counter_word)
                	    next_state = WRITE_BLOCK;
              	        else
                	    next_state = READ_BYTE;
		    end
		WRITE_BLOCK:
		    begin
		        next_state = IDLE_TOTAL_BYTES;
		    end    
		IDLE_TOTAL_BYTES:  
		    begin
               		if(i_spi_comm == 1'b1)
                    	  next_state = READ_TOTAL_BYTES;
		    end
		READ_TOTAL_BYTES:
		    begin
		      if(counter_word)
		        next_state = WRITE_TOTAL_BYTES;
		      else
		        next_state = READ_BYTE;
		    end
		WRITE_TOTAL_BYTES:
		    begin
		       next_state = IDLE_DATA;
		    end  
		IDLE_DATA:
		    begin
		       if(i_spi_comm == 1'b1)
		            next_state = READ_DATA_BYTES; 
		    end
		READ_DATA_BYTES:
		    begin
		        if(counter_word)
		            next_state = LOAD_DATA;
		        else if(counter_bytes == reg_total_bytes)
		            next_state = IDLE_BLOCK;
		        else
		            next_state = READ_BYTE;
		    end
		LOAD_DATA:
		    begin
		        if(i_ram_ack == 1'b1)
		            next_state = POST_LOAD;
		    end
		POST_LOAD://clear word counter & add address counter
		    begin
		        next_state = WAIT_COUNTER;
		    end              
		READ_BYTE:
		    begin
		        if(i_spi_done == 1'b1)
		            next_state = UP_WORD_BYTE;
		    end
		UP_WORD_BYTE://up the two counters bytes
		    begin
		      next_state = WAIT_COUNTER;
		    end  
		WAIT_COUNTER:
		    begin
		        next_state = reg_state_prev[3:0];
		    end    
		default: next_state = IDLE;
		
	endcase
end

//Outputs
always @(*)
begin
	o_mux = 1'b1;

	o_ram_rst = 1'b0;
	o_ram_we = 1'b0;
	o_ram_cyc = 1'b0;
	o_ram_stb = 1'b0;
	o_ram_cti = 1'b0;
	o_ram_sel = 4'b0000;
	o_ram_data = reg_sdspi_data;
   	o_ram_addr = 32'h00000000 | (reg_block_bumber<<9) |(counter_o<<2);

	o_spi_byte = 1'b1;

	rst_counter = 1'b0;
	rst_counter_word = 1'b0;
	rst_counter_bytes = 1'b0;
	up = 1'b0;
	up_word = 1'b0;
	up_bytes = 1'b0;

	reg_sdspi_data_3_w = 0;
	reg_sdspi_data_2_w = 0;
	reg_sdspi_data_1_w = 0;
	reg_sdspi_data_0_w = 0;
	reg_sdspi_data_3_cl = 0;
	reg_sdspi_data_2_cl = 0;
	reg_sdspi_data_1_cl = 0;
	reg_sdspi_data_0_cl = 0;
	
	r_block_cl = 0;
    r_block_w = 0;
    r_total_bytes_cl = 0;
    r_total_bytes_w = 0;
    r_state_prev_cl = 0;
    r_state_prev_w = 0;

   	o_cpu_rst = 1'b1;
    reset_button = 1'b0;

    //up_div_clk = 1'b0;
    //rst_counter_div = 1'b0;

	case(current_state)
	
		IDLE:
			begin
			    o_mux = 1'b0;
				
				o_cpu_rst = 1'b0;
				rst_counter = 1'b1;
				rst_counter_word = 1'b1;
				rst_counter_bytes = 1'b1;
				//rst_counter_div = 1'b1;

				reg_sdspi_data_3_cl = 1;
				reg_sdspi_data_2_cl = 1;
				reg_sdspi_data_1_cl = 1;
				reg_sdspi_data_0_cl = 1;
				
				r_state_prev_cl = 1;
				r_total_bytes_cl = 1;
				r_block_cl = 0;
				
	
			end
		IDLE_BLOCK:
            begin
                rst_counter = 1'b1;
                rst_counter_word = 1'b1;
                rst_counter_bytes = 1'b1;
            end    
        READ_BLOCK:
            begin
              r_state_prev_w = 1;
            end
        WRITE_BLOCK:
            begin
               r_block_w = 1;
            end    
        IDLE_TOTAL_BYTES:  
            begin
                rst_counter = 1'b1;
                rst_counter_word = 1'b1;
                rst_counter_bytes = 1'b1;
            end
        READ_TOTAL_BYTES:
            begin
                r_state_prev_w = 1;
            end
        WRITE_TOTAL_BYTES:
            begin
               r_total_bytes_w = 1;
            end  
        IDLE_DATA:
            begin
                rst_counter = 1'b1;
                rst_counter_word = 1'b1;
                rst_counter_bytes = 1'b1; 
            end
        READ_DATA_BYTES:
            begin
                r_state_prev_w = 1;
            end
        LOAD_DATA:
            begin
                o_ram_we = 1'b1;
                o_ram_cyc = 1'b1;
                o_ram_stb = 1'b1;
                o_ram_sel = 4'b1111;
            end
        POST_LOAD://clear word counter & add address counter
            begin
                up = 1'b1;
		rst_counter_word = 1'b1;
            end              
        READ_BYTE:
            begin
                o_spi_byte = 1'b0;//counter_div[31];
                //up_div_clk = 1'b1;
            end
        UP_WORD_BYTE://up the two counters bytes
            begin
              //rst_counter_div = 1'b0;
              up_word = 1'b1;
              up_bytes = 1'b1;
              if(counter_word_o == 32'h00000000)
                  reg_sdspi_data_3_w = 1;
              else if (counter_word_o == 32'h00000001)
                  reg_sdspi_data_2_w = 1;
              else if (counter_word_o == 32'h00000002)
                  reg_sdspi_data_1_w = 1;
              else if (counter_word_o == 32'h00000003)
                  reg_sdspi_data_0_w = 1;
            end  
        WAIT_COUNTER:
            begin
                
            end	
		default: 
			begin
			end
			
	endcase
end

//CS <= NS
always @(posedge clk)
begin
	if(reset || i_spi_eof == 1'b1)
		current_state <= IDLE;	
	else
		current_state <= next_state;
end

endmodule

