-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
-- Date        : Tue May 30 14:21:14 2023
-- Host        : gavin-win10 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               W:/VHDL/Proj/FRM123701U1R4_2019_1/Vivado/IP/resamp_int4_dec5_c18_dp12_60dB/resamp_int4_dec5_c18_dp12_60dB_stub.vhdl
-- Design      : resamp_int4_dec5_c18_dp12_60dB
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7vx690tffg1927-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity resamp_int4_dec5_c18_dp12_60dB is
  Port ( 
    aresetn : in STD_LOGIC;
    aclk : in STD_LOGIC;
    s_axis_data_tvalid : in STD_LOGIC;
    s_axis_data_tready : out STD_LOGIC;
    s_axis_data_tdata : in STD_LOGIC_VECTOR ( 159 downto 0 );
    m_axis_data_tvalid : out STD_LOGIC;
    m_axis_data_tdata : out STD_LOGIC_VECTOR ( 1279 downto 0 )
  );

end resamp_int4_dec5_c18_dp12_60dB;

architecture stub of resamp_int4_dec5_c18_dp12_60dB is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "aresetn,aclk,s_axis_data_tvalid,s_axis_data_tready,s_axis_data_tdata[159:0],m_axis_data_tvalid,m_axis_data_tdata[1279:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "fir_compiler_v7_2_12,Vivado 2019.1";
begin
end;
