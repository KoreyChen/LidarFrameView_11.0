//dcfifo ADD_RAM_OUTPUT_REGISTER="ON" CBX_SINGLE_OUTPUT_FILE="ON" CLOCKS_ARE_SYNCHRONIZED="FALSE" INTENDED_DEVICE_FAMILY="Cyclone" LPM_NUMWORDS=1024 LPM_SHOWAHEAD="OFF" LPM_TYPE="dcfifo" LPM_WIDTH=8 LPM_WIDTHU=10 OVERFLOW_CHECKING="ON" UNDERFLOW_CHECKING="ON" USE_EAB="ON" aclr data q rdclk rdempty rdfull rdreq rdusedw wrclk wrempty wrfull wrreq wrusedw
//VERSION_BEGIN 11.0 cbx_mgl 2011:04:27:21:11:03:SJ cbx_stratixii 2011:04:27:21:07:19:SJ cbx_util_mgl 2011:04:27:21:07:19:SJ  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 1991-2011 Altera Corporation
//  Your use of Altera Corporation's design tools, logic functions 
//  and other software and tools, and its AMPP partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Altera Program License 
//  Subscription Agreement, Altera MegaCore Function License 
//  Agreement, or other applicable license agreement, including, 
//  without limitation, that your use is for the sole purpose of 
//  programming logic devices manufactured by Altera and sold by 
//  Altera or its authorized distributors.  Please refer to the 
//  applicable agreement for further details.



//synthesis_resources = dcfifo 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  mgpp01
	( 
	aclr,
	data,
	q,
	rdclk,
	rdempty,
	rdfull,
	rdreq,
	rdusedw,
	wrclk,
	wrempty,
	wrfull,
	wrreq,
	wrusedw) /* synthesis synthesis_clearbox=1 */;
	input   aclr;
	input   [7:0]  data;
	output   [7:0]  q;
	input   rdclk;
	output   rdempty;
	output   rdfull;
	input   rdreq;
	output   [9:0]  rdusedw;
	input   wrclk;
	output   wrempty;
	output   wrfull;
	input   wrreq;
	output   [9:0]  wrusedw;

	wire  [7:0]   wire_mgl_prim1_q;
	wire  wire_mgl_prim1_rdempty;
	wire  wire_mgl_prim1_rdfull;
	wire  [9:0]   wire_mgl_prim1_rdusedw;
	wire  wire_mgl_prim1_wrempty;
	wire  wire_mgl_prim1_wrfull;
	wire  [9:0]   wire_mgl_prim1_wrusedw;

	dcfifo   mgl_prim1
	( 
	.aclr(aclr),
	.data(data),
	.q(wire_mgl_prim1_q),
	.rdclk(rdclk),
	.rdempty(wire_mgl_prim1_rdempty),
	.rdfull(wire_mgl_prim1_rdfull),
	.rdreq(rdreq),
	.rdusedw(wire_mgl_prim1_rdusedw),
	.wrclk(wrclk),
	.wrempty(wire_mgl_prim1_wrempty),
	.wrfull(wire_mgl_prim1_wrfull),
	.wrreq(wrreq),
	.wrusedw(wire_mgl_prim1_wrusedw));
	defparam
		mgl_prim1.add_ram_output_register = "ON",
		mgl_prim1.clocks_are_synchronized = "FALSE",
		mgl_prim1.intended_device_family = "Cyclone",
		mgl_prim1.lpm_numwords = 1024,
		mgl_prim1.lpm_showahead = "OFF",
		mgl_prim1.lpm_type = "dcfifo",
		mgl_prim1.lpm_width = 8,
		mgl_prim1.lpm_widthu = 10,
		mgl_prim1.overflow_checking = "ON",
		mgl_prim1.underflow_checking = "ON",
		mgl_prim1.use_eab = "ON";
	assign
		q = wire_mgl_prim1_q,
		rdempty = wire_mgl_prim1_rdempty,
		rdfull = wire_mgl_prim1_rdfull,
		rdusedw = wire_mgl_prim1_rdusedw,
		wrempty = wire_mgl_prim1_wrempty,
		wrfull = wire_mgl_prim1_wrfull,
		wrusedw = wire_mgl_prim1_wrusedw;
endmodule //mgpp01
//VALID FILE
