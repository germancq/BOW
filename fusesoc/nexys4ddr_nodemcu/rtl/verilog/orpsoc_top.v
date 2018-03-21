//////////////////////////////////////////////////////////////////////
///                                                               ////
/// ORPSoC top for Atlys board                                    ////
///                                                               ////
/// Instantiates modules, depending on ORPSoC defines file        ////
///                                                               ////
/// Copyright (C) 2013 Stefan Kristiansson                        ////
///  <stefan.kristiansson@saunalahti.fi                           ////
///                                                               ////
//////////////////////////////////////////////////////////////////////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`include "orpsoc-defines.v"

module orpsoc_top #(
	parameter	rom0_aw = 8,
	parameter	uart0_aw = 3
)(
	input		sys_clk_pad_i,
	input		rst_n_pad_i,

	// JTAG
	output		tdo_pad_o,
	input		tms_pad_i,
	input		tck_pad_i,
	input		tdi_pad_i,


        output [3:0] debug_leds,
   	output [3:0]led_test,
	input next_button,
	input center_button,
	inout [7:0] gpio0_io,
	input	[7:0]	switch_i,

	//BOOT
	input spi_comm,
	input 	   spi_start,
        input 	   spi_eof,
        output     o_spi_byte,
	//SPI
	input	   sclk,
	input	   mosi,
	output	   miso,
	input 	   cs,
	
	//7seg
	output [6:0] seg,
	output [3:0] an,
	output DP,

   	// UART
	input		uart0_srx_pad_i,
	output		uart0_stx_pad_o,
	
	
	// DDR2
	
	output [12:0]	ddr2_addr,
	output [2:0]	ddr2_ba,
	output		ddr2_ras_n,
	output		ddr2_cas_n,
	output		ddr2_we_n,
	output		ddr2_odt,
	output		ddr2_cke,
	output	[1:0]	ddr2_dm,
	inout [15:0]	ddr2_dq,
	inout	[1:0]	ddr2_dqs_p,
	inout	[1:0]	ddr2_dqs_n,
	output      ddr2_cs_n,
	output		ddr2_ck_p,
	output		ddr2_ck_n
	
);

parameter	IDCODE_VALUE=32'h14951185;

////////////////////////////////////////////////////////////////////////
//
// Clock and reset generation module
//
////////////////////////////////////////////////////////////////////////

wire	async_rst;
wire	wb_clk, wb_rst; //wb_clk generated by ddr
wire	dbg_tck;

wire	dvi_clk;

wire	ddr2_if_clk;
wire	ddr2_if_rst;
wire	clk100;
wire clk50;

wire locked_mmcm;
design_1_clk_wiz_0_0 clkgen0(
    .clk_in1 (sys_clk_pad_i),
  // Clock out ports
     .clk_out1(clk100),
     .clk_out2(ddr2_if_clk),
     .clk_out3(clk50),
  // Status and control signals
     .resetn (rst_n_pad_i),
     .locked(locked_mmcm)
);

rstgen rstgen0
       (
	// Main clocks in, depending on board
	.sys_clk_pad_i(sys_clk_pad_i),
	// Asynchronous, active low reset in
	.rst_n_pad_i(rst_n_pad_i),
	.locked_mcm(locked_mmcm),

	// Wishbone clock and reset out
	.wb_clk(wb_clk),

	.wb_rst_o(wb_rst),
	.ddr2_if_rst_o(ddr2_if_rst)
);

assign dbg_tck = tck_pad_i;
assign async_rst = ~ rst_n_pad_i;
assign ddr2_clk = ddr2_if_clk;

////////////////////////////////////////////////////////////////////////
//
// Modules interconnections
//
////////////////////////////////////////////////////////////////////////
`include "wb_intercon.vh"




`ifdef JTAG_DEBUG
////////////////////////////////////////////////////////////////////////
//
// GENERIC JTAG TAP
//
////////////////////////////////////////////////////////////////////////

wire	dbg_if_select;
wire	dbg_if_tdo;
wire	jtag_tap_tdo;
wire	jtag_tap_shift_dr;
wire	jtag_tap_pause_dr;
wire	jtag_tap_update_dr;
wire	jtag_tap_capture_dr;

tap_top jtag_tap0 (
	.tdo_pad_o			(tdo_pad_o),
	.tms_pad_i			(tms_pad_i),
	.tck_pad_i			(dbg_tck),
	.trst_pad_i			(async_rst),
	.tdi_pad_i			(tdi_pad_i),

	.tdo_padoe_o			(tdo_padoe_o),

	.tdo_o				(jtag_tap_tdo),

	.shift_dr_o			(jtag_tap_shift_dr),
	.pause_dr_o			(jtag_tap_pause_dr),
	.update_dr_o			(jtag_tap_update_dr),
	.capture_dr_o			(jtag_tap_capture_dr),

	.extest_select_o		(),
	.sample_preload_select_o	(),
	.mbist_select_o			(),
	.debug_select_o			(dbg_if_select),


	.bs_chain_tdi_i			(1'b0),
	.mbist_tdi_i			(1'b0),
	.debug_tdi_i			(dbg_if_tdo)
);

`endif

////////////////////////////////////////////////////////////////////////
//
// OR1K CPU
//
////////////////////////////////////////////////////////////////////////

wire	[31:0]	or1k_irq;

wire	[31:0]	or1k_dbg_dat_i;
wire	[31:0]	or1k_dbg_adr_i;
wire		or1k_dbg_we_i;
wire		or1k_dbg_stb_i;
wire		or1k_dbg_ack_o;
wire	[31:0]	or1k_dbg_dat_o;

wire		or1k_dbg_stall_i;
wire		or1k_dbg_ewt_i;
wire	[3:0]	or1k_dbg_lss_o;
wire	[1:0]	or1k_dbg_is_o;
wire	[10:0]	or1k_dbg_wp_o;
wire		or1k_dbg_bp_o;
wire		or1k_dbg_rst;

wire		sig_tick;

wire		or1k_rst;

wire boot_cpu_rst;

assign or1k_rst = wb_rst | or1k_dbg_rst | boot_cpu_rst;

`ifdef OR1200

or1200_top #(.boot_adr(32'hf0000100))
or1200_top0 (
	// Instruction bus, clocks, reset
	.iwb_clk_i			(wb_clk),
	.iwb_rst_i			(wb_rst),
	.iwb_ack_i			(wb_s2m_or1k_i_ack),
	.iwb_err_i			(wb_s2m_or1k_i_err),
	.iwb_rty_i			(wb_s2m_or1k_i_rty),
	.iwb_dat_i			(wb_s2m_or1k_i_dat),

	.iwb_cyc_o			(wb_m2s_or1k_i_cyc),
	.iwb_adr_o			(wb_m2s_or1k_i_adr),
	.iwb_stb_o			(wb_m2s_or1k_i_stb),
	.iwb_we_o			(wb_m2s_or1k_i_we),
	.iwb_sel_o			(wb_m2s_or1k_i_sel),
	.iwb_dat_o			(wb_m2s_or1k_i_dat),
	.iwb_cti_o			(wb_m2s_or1k_i_cti),
	.iwb_bte_o			(wb_m2s_or1k_i_bte),

	// Data bus, clocks, reset
	.dwb_clk_i			(wb_clk),
	.dwb_rst_i			(wb_rst),
	.dwb_ack_i			(wb_s2m_or1k_d_ack),
	.dwb_err_i			(wb_s2m_or1k_d_err),
	.dwb_rty_i			(wb_s2m_or1k_d_rty),
	.dwb_dat_i			(wb_s2m_or1k_d_dat),

	.dwb_cyc_o			(wb_m2s_or1k_d_cyc),
	.dwb_adr_o			(wb_m2s_or1k_d_adr),
	.dwb_stb_o			(wb_m2s_or1k_d_stb),
	.dwb_we_o			(wb_m2s_or1k_d_we),
	.dwb_sel_o			(wb_m2s_or1k_d_sel),
	.dwb_dat_o			(wb_m2s_or1k_d_dat),
	.dwb_cti_o			(wb_m2s_or1k_d_cti),
	.dwb_bte_o			(wb_m2s_or1k_d_bte),

	// Debug interface ports
	.dbg_stall_i			(or1k_dbg_stall_i),
	.dbg_ewt_i			(1'b0),
	.dbg_lss_o			(or1k_dbg_lss_o),
	.dbg_is_o			(or1k_dbg_is_o),
	.dbg_wp_o			(or1k_dbg_wp_o),
	.dbg_bp_o			(or1k_dbg_bp_o),

	.dbg_adr_i			(or1k_dbg_adr_i),
	.dbg_we_i			(or1k_dbg_we_i),
	.dbg_stb_i			(or1k_dbg_stb_i),
	.dbg_dat_i			(or1k_dbg_dat_i),
	.dbg_dat_o			(or1k_dbg_dat_o),
	.dbg_ack_o			(or1k_dbg_ack_o),

	.pm_clksd_o			(),
	.pm_dc_gate_o			(),
	.pm_ic_gate_o			(),
	.pm_dmmu_gate_o			(),
	.pm_immu_gate_o			(),
	.pm_tt_gate_o			(),
	.pm_cpu_gate_o			(),
	.pm_wakeup_o			(),
	.pm_lvolt_o			(),

	// Core clocks, resets
	.clk_i				(wb_clk),
	.rst_i				(or1k_rst),

	.clmode_i			(2'b00),

	// Interrupts
	.pic_ints_i			(or1k_irq),
	.sig_tick			(sig_tick),

	.pm_cpustall_i			(1'b0)
);
`endif

`ifdef MOR1KX
mor1kx #(
	.FEATURE_DEBUGUNIT("ENABLED"),
	.FEATURE_CMOV("ENABLED"),
	.FEATURE_INSTRUCTIONCACHE("ENABLED"),
	.OPTION_ICACHE_BLOCK_WIDTH(5),
	.OPTION_ICACHE_SET_WIDTH(8),
	.OPTION_ICACHE_WAYS(4),
	.OPTION_ICACHE_LIMIT_WIDTH(32),
	.FEATURE_IMMU("ENABLED"),
	.OPTION_IMMU_SET_WIDTH(7),
	.FEATURE_DATACACHE("ENABLED"),
	.OPTION_DCACHE_BLOCK_WIDTH(5),
	.OPTION_DCACHE_SET_WIDTH(8),
	.OPTION_DCACHE_WAYS(4),
	.OPTION_DCACHE_LIMIT_WIDTH(31),
	.FEATURE_DMMU("ENABLED"),
	.OPTION_DMMU_SET_WIDTH(7),
	.OPTION_PIC_TRIGGER("LATCHED_LEVEL"),

	.IBUS_WB_TYPE("B3_REGISTERED_FEEDBACK"),
	.DBUS_WB_TYPE("B3_REGISTERED_FEEDBACK"),
	.OPTION_CPU0("CAPPUCCINO"),
	.OPTION_RESET_PC(32'h00000100)
) mor1kx0 (
	.iwbm_adr_o(wb_m2s_or1k_i_adr),
	.iwbm_stb_o(wb_m2s_or1k_i_stb),
	.iwbm_cyc_o(wb_m2s_or1k_i_cyc),
	.iwbm_sel_o(wb_m2s_or1k_i_sel),
	.iwbm_we_o (wb_m2s_or1k_i_we),
	.iwbm_cti_o(wb_m2s_or1k_i_cti),
	.iwbm_bte_o(wb_m2s_or1k_i_bte),
	.iwbm_dat_o(wb_m2s_or1k_i_dat),

	.dwbm_adr_o(wb_m2s_or1k_d_adr),
	.dwbm_stb_o(wb_m2s_or1k_d_stb),
	.dwbm_cyc_o(wb_m2s_or1k_d_cyc),
	.dwbm_sel_o(wb_m2s_or1k_d_sel),
	.dwbm_we_o (wb_m2s_or1k_d_we ),
	.dwbm_cti_o(wb_m2s_or1k_d_cti),
	.dwbm_bte_o(wb_m2s_or1k_d_bte),
	.dwbm_dat_o(wb_m2s_or1k_d_dat),

	.clk(wb_clk),
	.rst(or1k_rst),

	.iwbm_err_i(wb_s2m_or1k_i_err),
	.iwbm_ack_i(wb_s2m_or1k_i_ack),
	.iwbm_dat_i(wb_s2m_or1k_i_dat),
	.iwbm_rty_i(wb_s2m_or1k_i_rty),

	.dwbm_err_i(wb_s2m_or1k_d_err),
	.dwbm_ack_i(wb_s2m_or1k_d_ack),
	.dwbm_dat_i(wb_s2m_or1k_d_dat),
	.dwbm_rty_i(wb_s2m_or1k_d_rty),

	.irq_i(or1k_irq),

	.du_addr_i(or1k_dbg_adr_i[15:0]),
	.du_stb_i(or1k_dbg_stb_i),
	.du_dat_i(or1k_dbg_dat_i),
	.du_we_i(or1k_dbg_we_i),
	.du_dat_o(or1k_dbg_dat_o),
	.du_ack_o(or1k_dbg_ack_o),
	.du_stall_i(or1k_dbg_stall_i),
	.du_stall_o(or1k_dbg_bp_o)
);

`endif

////////////////////////////////////////////////////////////////////////
//
// Debug Interface
//
////////////////////////////////////////////////////////////////////////

adbg_top dbg_if0 (
	// OR1K interface
	.cpu0_clk_i	(wb_clk),
	.cpu0_rst_o	(or1k_dbg_rst),
	.cpu0_addr_o	(or1k_dbg_adr_i),
	.cpu0_data_o	(or1k_dbg_dat_i),
	.cpu0_stb_o	(or1k_dbg_stb_i),
	.cpu0_we_o	(or1k_dbg_we_i),
	.cpu0_data_i	(or1k_dbg_dat_o),
	.cpu0_ack_i	(or1k_dbg_ack_o),
	.cpu0_stall_o	(or1k_dbg_stall_i),
	.cpu0_bp_i	(or1k_dbg_bp_o),

	// TAP interface
	.tck_i		(dbg_tck),
	.tdi_i		(jtag_tap_tdo),
	.tdo_o		(dbg_if_tdo),
	.rst_i		(wb_rst),
	.capture_dr_i	(jtag_tap_capture_dr),
	.shift_dr_i	(jtag_tap_shift_dr),
	.pause_dr_i	(jtag_tap_pause_dr),
	.update_dr_i	(jtag_tap_update_dr),
	.debug_select_i	(dbg_if_select),

	// Wishbone debug master
	.wb_rst_i	(wb_rst),
	.wb_clk_i	(wb_clk),
	.wb_dat_i	(wb_s2m_dbg_dat),
	.wb_ack_i	(wb_s2m_dbg_ack),
	.wb_err_i	(wb_s2m_dbg_err),

	.wb_adr_o	(wb_m2s_dbg_adr),
	.wb_dat_o	(wb_m2s_dbg_dat),
	.wb_cyc_o	(wb_m2s_dbg_cyc),
	.wb_stb_o	(wb_m2s_dbg_stb),
	.wb_sel_o	(wb_m2s_dbg_sel),
	.wb_we_o	(wb_m2s_dbg_we),
	.wb_cti_o	(wb_m2s_dbg_cti),
	.wb_bte_o	(wb_m2s_dbg_bte)
);

////////////////////////////////////////////////////////////////////////
//
// ROM
//
////////////////////////////////////////////////////////////////////////

assign	wb_s2m_rom0_err = 1'b0;
assign	wb_s2m_rom0_rty = 1'b0;

`ifdef BOOTROM
rom #(.addr_width(rom0_aw))
rom0 (
	.wb_clk		(wb_clk),
	.wb_rst		(wb_rst),
	.wb_adr_i	(wb_m2s_rom0_adr[(rom0_aw + 2) - 1 : 2]),
	.wb_cyc_i	(wb_m2s_rom0_cyc),
	.wb_stb_i	(wb_m2s_rom0_stb),
	.wb_cti_i	(wb_m2s_rom0_cti),
	.wb_bte_i	(wb_m2s_rom0_bte),
	.wb_dat_o	(wb_s2m_rom0_dat),
	.wb_ack_o	(wb_s2m_rom0_ack)
);
`else
assign	wb_s2m_rom0_dat_o = 0;
assign	wb_s2m_rom0_ack_o = 0;
`endif



////////////////////////////////////////////////////////////////////////
//
// BOOTLOADER MODULE
//
////////////////////////////////////////////////////////////////////////


wire ram0_mux;



wire [7:0] spi_2_boot_data;
wire spi_2_boot_done;

wire ram0_ack;
wire ram0_rst;
wire ram0_we;
wire ram0_cyc;
wire ram0_stb;
wire ram0_cti;
wire [3:0] ram0_sel;
wire [31:0] ram0_data;
wire [31:0] ram0_addr;

bootloader_module boot0(
	.clk	(wb_clk),
	.reset (center_button),
	.button (next_button),
	.o_cpu_rst (boot_cpu_rst),
	.i_ram_ack (wb_s2m_ddr2_bus_ack),
	.o_ram_rst (ram0_rst),
	.o_ram_we (ram0_we),
   	.o_ram_cyc (ram0_cyc),
	.o_ram_stb (ram0_stb),
	.o_ram_cti (ram0_cti),
	.o_ram_sel (ram0_sel),
	.o_ram_data (ram0_data),
	.o_ram_addr (ram0_addr),
	.i_spi_comm (spi_comm),
	.i_spi_start (spi_start),
  	.i_spi_done (spi_2_boot_done),
  	.i_spi_eof (spi_eof),
  	.i_spi_data (spi_2_boot_data),
  	.o_spi_byte (o_spi_byte),
	.o_mux (ram0_mux),
   	.debug_leds (led_test)
);

////////////////////////////////////////////////////////////////////////
//
// SPI_SLAVE
//
////////////////////////////////////////////////////////////////////////

SPI_slave esp8266(
    .clk(wb_clk),
    .SCK(sclk),
    .MOSI(mosi),
    .MISO(miso),
    .SSEL(cs),
    .LED(),
    .byte_received(spi_2_boot_done),
    .byte_data_received(spi_2_boot_data)
);
////////////////////////////////////////////////////////////////////////
//
// DISPLAY 7-SEG
//
////////////////////////////////////////////////////////////////////////

display seg7(
    .extclk(wb_clk),
	.reset(wb_rst),
	.din({8'hAB,spi_2_boot_data}),//15:0
	.w_display(1'b1),
	.seg(seg),
	.an(an)
);

////////////////////////////////////////////////////////////////////////
//
// MUX
//
////////////////////////////////////////////////////////////////////////
wire ram_rst;
generic_mux#(.WIDTH(1)) 
ram_mux_0(
    .a(wb_rst),
    .b(ram0_rst),
    .c(ram_rst),
    .ctl(ram0_mux)
);

wire ram_we;
generic_mux#(.WIDTH(1)) 
ram_mux_1(
    .a(wb_m2s_ddr2_bus_we),
    .b(ram0_we),
    .c(ram_we),
    .ctl(ram0_mux)
);

wire ram_cyc;
generic_mux#(.WIDTH(1)) 
ram_mux_2(
    .a(wb_m2s_ddr2_bus_cyc),
    .b(ram0_cyc),
    .c(ram_cyc),
    .ctl(ram0_mux)
);

wire ram_stb;
generic_mux#(.WIDTH(1)) 
ram_mux_3(
    .a(wb_m2s_ddr2_bus_stb),
    .b(ram0_stb),
    .c(ram_stb),
    .ctl(ram0_mux)
);

wire ram_cti;
generic_mux#(.WIDTH(1)) 
ram_mux_4(
    .a(wb_m2s_ddr2_bus_cti),
    .b(ram0_cti),
    .c(ram_cti),
    .ctl(ram0_mux)
);

wire [31:0] ram_data;
generic_mux ram_mux_5(
    .a(wb_m2s_ddr2_bus_dat),
    .b(ram0_data),
    .c(ram_data),
    .ctl(ram0_mux)
);

wire [31:0] ram_addr;
generic_mux ram_mux_6(
    .a(wb_m2s_ddr2_bus_adr),
    .b(ram0_addr),
    .c(ram_addr),
    .ctl(ram0_mux)
);

wire [3:0] ram_sel;
generic_mux ram_mux_7(
    .a(wb_m2s_ddr2_bus_sel),
    .b(ram0_sel),
    .c(ram_sel),
    .ctl(ram0_mux)
);
////////////////////////////////////////////////////////////////////////
//
// DDR2 SDRAM Memory Controller
//
////////////////////////////////////////////////////////////////////////


xilinx_ddr2 xilinx_ddr2_0 (
	.wbm0_adr_i	(ram_addr),
	.wbm0_bte_i	(wb_m2s_ddr2_bus_bte),
	.wbm0_cti_i	(ram_cti),
	.wbm0_cyc_i	(ram_cyc),
	.wbm0_dat_i	(ram_data),
	.wbm0_sel_i	(ram_sel),
	.wbm0_stb_i	(ram_stb),
	.wbm0_we_i	(ram_we),
	.wbm0_ack_o	(wb_s2m_ddr2_bus_ack),
	.wbm0_err_o	(wb_s2m_ddr2_bus_err),
	.wbm0_rty_o	(wb_s2m_ddr2_bus_rty),
	.wbm0_dat_o	(wb_s2m_ddr2_bus_dat),

	.wb_clk		(wb_clk),
	.wb_rst		(ram_rst),

	.ddr2_addr		(ddr2_addr[12:0]),
	.ddr2_ba	(ddr2_ba),
	.ddr2_ras_n	(ddr2_ras_n),
	.ddr2_cas_n	(ddr2_cas_n),
	.ddr2_we_n	(ddr2_we_n),
	.ddr2_odt	(ddr2_odt),
	.ddr2_cke	(ddr2_cke),
	.ddr2_dm	(ddr2_dm[0]),
	.ddr2_udm	(ddr2_dm[1]),
	.ddr2_ck_p	(ddr2_ck_p),
	.ddr2_ck_n	(ddr2_ck_n),
	.ddr2_dq	(ddr2_dq),
	.ddr2_dqs_p	(ddr2_dqs_p[0]),
	.ddr2_dqs_n	(ddr2_dqs_n[0]),
	.ddr2_cs_n  (ddr2_cs_n),
	.ddr2_udqs_p	(ddr2_dqs_p[1]),
	.ddr2_udqs_n	(ddr2_dqs_n[1]),
	.ddr2_if_clk	(ddr2_if_clk),
	.ddr2_if_rst	(ddr2_if_rst)
);

////////////////////////////////////////////////////////////////////////
//
// GPIO 0
//
////////////////////////////////////////////////////////////////////////

wire [7:0]	gpio0_in;
wire [7:0]	gpio0_out;
wire [7:0]	gpio0_dir;

// Tristate logic for IO
// 0 = input, 1 = output
genvar                    i;
generate
	for (i = 0; i < 8; i = i+1) begin: gpio0_tris
		assign gpio0_io[i] = gpio0_dir[i] ? gpio0_out[i] : 1'bz;
		assign gpio0_in[i] = gpio0_dir[i] ? gpio0_out[i] : gpio0_io[i];
	end
endgenerate

gpio gpio0 (
	// GPIO bus
	.gpio_i		(gpio0_in),
	.gpio_o		(gpio0_out),
	.gpio_dir_o	(gpio0_dir),
	// Wishbone slave interface
	.wb_adr_i	(wb_m2s_gpio0_adr[0]),
	.wb_dat_i	(wb_m2s_gpio0_dat),
	.wb_we_i	(wb_m2s_gpio0_we),
	.wb_cyc_i	(wb_m2s_gpio0_cyc),
	.wb_stb_i	(wb_m2s_gpio0_stb),
	.wb_cti_i	(wb_m2s_gpio0_cti),
	.wb_bte_i	(wb_m2s_gpio0_bte),
	.wb_dat_o	(wb_s2m_gpio0_dat),
	.wb_ack_o	(wb_s2m_gpio0_ack),
	.wb_err_o	(wb_s2m_gpio0_err),
	.wb_rty_o	(wb_s2m_gpio0_rty),

	.wb_clk		(wb_clk),
	.wb_rst		(wb_rst)
);

////////////////////////////////////////////////////////////////////////
//
// SWITCH0
//
////////////////////////////////////////////////////////////////////////

switch switch0 (
	// switch bus
	.switch_i	(switch_i),
	// Wishbone slave interface
	.wb_adr_i	(wb_m2s_switch0_adr[0]),
	.wb_dat_i	(wb_m2s_switch0_dat),
	.wb_we_i	(wb_m2s_switch0_we),
	.wb_cyc_i	(wb_m2s_switch0_cyc),
	.wb_stb_i	(wb_m2s_switch0_stb),
	.wb_cti_i	(wb_m2s_switch0_cti),
	.wb_bte_i	(wb_m2s_switch0_bte),
	.wb_dat_o	(wb_s2m_switch0_dat),
	.wb_ack_o	(wb_s2m_switch0_ack),
	.wb_err_o	(wb_s2m_switch0_err),
	.wb_rty_o	(wb_s2m_switch0_rty),

	.wb_clk		(wb_clk),
	.wb_rst		(wb_rst)
);

////////////////////////////////////////////////////////////////////////
//
// UART0
//
////////////////////////////////////////////////////////////////////////

wire	uart0_irq;

uart_top uart16550_0 (
	// Wishbone slave interface
	.wb_clk_i	(wb_clk),
	.wb_rst_i	(wb_rst),
	.wb_adr_i	(wb_m2s_uart0_adr[uart0_aw-1:0]),
	.wb_dat_i	(wb_m2s_uart0_dat),
	.wb_we_i	(wb_m2s_uart0_we),
	.wb_stb_i	(wb_m2s_uart0_stb),
	.wb_cyc_i	(wb_m2s_uart0_cyc),
	.wb_sel_i	(4'b0), // Not used in 8-bit mode
	.wb_dat_o	(wb_s2m_uart0_dat),
	.wb_ack_o	(wb_s2m_uart0_ack),

	// Outputs
	.int_o		(uart0_irq),
	.stx_pad_o	(uart0_stx_pad_o),
	.rts_pad_o	(),
	.dtr_pad_o	(),

	// Inputs
	.srx_pad_i	(uart0_srx_pad_i),
	.cts_pad_i	(1'b0),
	.dsr_pad_i	(1'b0),
	.ri_pad_i	(1'b0),
	.dcd_pad_i	(1'b0)
);

////////////////////////////////////////////////////////////////////////
//
// Interrupt assignment
//
////////////////////////////////////////////////////////////////////////

assign or1k_irq[0] = 0; // Non-maskable inside OR1K
assign or1k_irq[1] = 0; // Non-maskable inside OR1K
assign or1k_irq[2] = uart0_irq;
assign or1k_irq[3] = 0;
assign or1k_irq[4] = 0;
assign or1k_irq[5] = 0;
assign or1k_irq[6] = 0;
assign or1k_irq[7] = 0;
assign or1k_irq[8] = 0;
assign or1k_irq[9] = 0;
assign or1k_irq[10] = 0;
assign or1k_irq[11] = 0;
assign or1k_irq[12] = 0;
assign or1k_irq[13] = 0;
assign or1k_irq[14] = 0;
assign or1k_irq[15] = 0;
assign or1k_irq[16] = 0;
assign or1k_irq[17] = 0;
assign or1k_irq[18] = 0;
assign or1k_irq[19] = 0;
assign or1k_irq[20] = 0;
assign or1k_irq[21] = 0;
assign or1k_irq[22] = 0;
assign or1k_irq[23] = 0;
assign or1k_irq[24] = 0;
assign or1k_irq[25] = 0;
assign or1k_irq[26] = 0;
assign or1k_irq[27] = 0;
assign or1k_irq[28] = 0;
assign or1k_irq[29] = 0;
assign or1k_irq[30] = 0;
assign or1k_irq[31] = 0;

endmodule // orpsoc_top
