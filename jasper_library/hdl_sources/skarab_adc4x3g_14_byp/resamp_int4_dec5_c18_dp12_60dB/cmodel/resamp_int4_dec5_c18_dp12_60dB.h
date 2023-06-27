
//------------------------------------------------------------------------------
// (c) Copyright 2014 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//------------------------------------------------------------------------------ 
//
// C Model configuration for the "resamp_int4_dec5_c18_dp12_60dB" instance.
//
//------------------------------------------------------------------------------
//
// coefficients: -28,444,581,745,745,510,55,-506,-978,-1152,-891,-202,723,1556,1930,1593,538,-949,-2343,-3055,-2661,-1113,1175,3409,4669,4265,2057,-1389,-4904,-7075,-6773,-3650,1575,7206,11045,11157,6659,-1720,-11573,-19320,-21187,-14396,1812,25664,53065,78520,96519,103014,96519,78520,53065,25664,1812,-14396,-21187,-19320,-11573,-1720,6659,11157,11045,7206,1575,-3650,-6773,-7075,-4904,-1389,2057,4265,4669,3409,1175,-1113,-2661,-3055,-2343,-949,538,1593,1930,1556,723,-202,-891,-1152,-978,-506,55,510,745,745,581,444,-28
// chanpats: 173
// name: resamp_int4_dec5_c18_dp12_60dB
// filter_type: 1
// rate_change: 0
// interp_rate: 4
// decim_rate: 1
// zero_pack_factor: 1
// coeff_padding: 0
// num_coeffs: 95
// coeff_sets: 1
// reloadable: 0
// is_halfband: 0
// quantization: 0
// coeff_width: 18
// coeff_fract_width: 0
// chan_seq: 0
// num_channels: 1
// num_paths: 1
// data_width: 12
// data_fract_width: 0
// output_rounding_mode: 0
// output_width: 30
// output_fract_width: 0
// config_method: 0

const double resamp_int4_dec5_c18_dp12_60dB_coefficients[95] = {-28,444,581,745,745,510,55,-506,-978,-1152,-891,-202,723,1556,1930,1593,538,-949,-2343,-3055,-2661,-1113,1175,3409,4669,4265,2057,-1389,-4904,-7075,-6773,-3650,1575,7206,11045,11157,6659,-1720,-11573,-19320,-21187,-14396,1812,25664,53065,78520,96519,103014,96519,78520,53065,25664,1812,-14396,-21187,-19320,-11573,-1720,6659,11157,11045,7206,1575,-3650,-6773,-7075,-4904,-1389,2057,4265,4669,3409,1175,-1113,-2661,-3055,-2343,-949,538,1593,1930,1556,723,-202,-891,-1152,-978,-506,55,510,745,745,581,444,-28};

const xip_fir_v7_2_pattern resamp_int4_dec5_c18_dp12_60dB_chanpats[1] = {P_BASIC};

static xip_fir_v7_2_config gen_resamp_int4_dec5_c18_dp12_60dB_config() {
  xip_fir_v7_2_config config;
  config.name                = "resamp_int4_dec5_c18_dp12_60dB";
  config.filter_type         = 1;
  config.rate_change         = XIP_FIR_INTEGER_RATE;
  config.interp_rate         = 4;
  config.decim_rate          = 1;
  config.zero_pack_factor    = 1;
  config.coeff               = &resamp_int4_dec5_c18_dp12_60dB_coefficients[0];
  config.coeff_padding       = 0;
  config.num_coeffs          = 95;
  config.coeff_sets          = 1;
  config.reloadable          = 0;
  config.is_halfband         = 0;
  config.quantization        = XIP_FIR_INTEGER_COEFF;
  config.coeff_width         = 18;
  config.coeff_fract_width   = 0;
  config.chan_seq            = XIP_FIR_BASIC_CHAN_SEQ;
  config.num_channels        = 1;
  config.init_pattern        = resamp_int4_dec5_c18_dp12_60dB_chanpats[0];
  config.num_paths           = 1;
  config.data_width          = 12;
  config.data_fract_width    = 0;
  config.output_rounding_mode= XIP_FIR_FULL_PRECISION;
  config.output_width        = 30;
  config.output_fract_width  = 0,
  config.config_method       = XIP_FIR_CONFIG_SINGLE;
  return config;
}

const xip_fir_v7_2_config resamp_int4_dec5_c18_dp12_60dB_config = gen_resamp_int4_dec5_c18_dp12_60dB_config();

