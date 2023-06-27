// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Tue May 30 11:09:17 2023
// Host        : gavin-win10 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               W:/VHDL/Proj/FRM123701U1R4_DDC_DEC4_8_16_2019_1/Vivado/IP/resamp_int4_dec5_c18_dp16_60dB/resamp_int4_dec5_c18_dp16_60dB_stub.v
// Design      : resamp_int4_dec5_c18_dp16_60dB
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx690tffg1927-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fir_compiler_v7_2_12,Vivado 2019.1" *)
module resamp_int4_dec5_c18_dp16_60dB(aresetn, aclk, s_axis_data_tvalid, 
  s_axis_data_tready, s_axis_data_tdata, m_axis_data_tvalid, m_axis_data_tdata)
/* synthesis syn_black_box black_box_pad_pin="aresetn,aclk,s_axis_data_tvalid,s_axis_data_tready,s_axis_data_tdata[79:0],m_axis_data_tvalid,m_axis_data_tdata[799:0]" */;
  input aresetn;
  input aclk;
  input s_axis_data_tvalid;
  output s_axis_data_tready;
  input [79:0]s_axis_data_tdata;
  output m_axis_data_tvalid;
  output [799:0]m_axis_data_tdata;
endmodule
