// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (lin64) Build 2552052 Fri May 24 14:47:09 MDT 2019
// Date        : Mon Jun 29 08:10:52 2026
// Host        : hwdev-xbs2 running 64-bit Ubuntu 16.04.7 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/clifford/telespazio/twox8192spectddc/twox8192spectddc/myproj/myproj.srcs/sources_1/ip/ska_tx_packet_fifo/ska_tx_packet_fifo_stub.v
// Design      : ska_tx_packet_fifo
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx690tffg1927-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_4,Vivado 2019.1" *)
module ska_tx_packet_fifo(wr_clk, wr_rst, rd_clk, rd_rst, din, wr_en, rd_en, 
  dout, full, overflow, empty, prog_full)
/* synthesis syn_black_box black_box_pad_pin="wr_clk,wr_rst,rd_clk,rd_rst,din[263:0],wr_en,rd_en,dout[263:0],full,overflow,empty,prog_full" */;
  input wr_clk;
  input wr_rst;
  input rd_clk;
  input rd_rst;
  input [263:0]din;
  input wr_en;
  input rd_en;
  output [263:0]dout;
  output full;
  output overflow;
  output empty;
  output prog_full;
endmodule
