// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Tue May 30 10:06:05 2023
// Host        : gavin-win10 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               W:/VHDL/Proj/FRM123701U1R4_DDC_DEC4_8_16_2019_1/Vivado/IP/ddc_dec16_in_dec32_out_input_fifo/ddc_dec16_in_dec32_out_input_fifo_stub.v
// Design      : ddc_dec16_in_dec32_out_input_fifo
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx690tffg1927-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_4,Vivado 2019.1" *)
module ddc_dec16_in_dec32_out_input_fifo(clk, rst, din, wr_en, rd_en, dout, full, empty)
/* synthesis syn_black_box black_box_pad_pin="clk,rst,din[127:0],wr_en,rd_en,dout[127:0],full,empty" */;
  input clk;
  input rst;
  input [127:0]din;
  input wr_en;
  input rd_en;
  output [127:0]dout;
  output full;
  output empty;
endmodule
