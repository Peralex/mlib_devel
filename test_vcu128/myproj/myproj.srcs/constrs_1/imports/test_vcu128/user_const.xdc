set_property PACKAGE_PIN BG22 [get_ports test_vcu128_gbe_tx_p]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports test_vcu128_gbe_tx_p]
set_property PACKAGE_PIN BH22 [get_ports test_vcu128_gbe_tx_n]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports test_vcu128_gbe_tx_n]
set_property PACKAGE_PIN BH21 [get_ports test_vcu128_gbe_rx_p]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports test_vcu128_gbe_rx_p]
set_property PACKAGE_PIN BJ21 [get_ports test_vcu128_gbe_rx_n]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports test_vcu128_gbe_rx_n]
set_property PACKAGE_PIN U65.19 [get_ports phy_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports phy_rst_n]
set_property PACKAGE_PIN BF22 [get_ports phy_pdown_n]
set_property IOSTANDARD LVCMOS18 [get_ports phy_pdown_n]
set_property PACKAGE_PIN BG23 [get_ports phy_mdio]
set_property IOSTANDARD LVCMOS18 [get_ports phy_mdio]
set_property PACKAGE_PIN BN27 [get_ports phy_mdc]
set_property IOSTANDARD LVCMOS18 [get_ports phy_mdc]
set_property PACKAGE_PIN BK23 [get_ports test_vcu128_gbe_refclk625_p]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports test_vcu128_gbe_refclk625_p]
set_property PACKAGE_PIN BK22 [get_ports test_vcu128_gbe_refclk625_n]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports test_vcu128_gbe_refclk625_n]
set_property PACKAGE_PIN BH24 [get_ports test_vcu128_led_ext[0]]
set_property IOSTANDARD LVCMOS18 [get_ports test_vcu128_led_ext[0]]
set_property PACKAGE_PIN F36 [get_ports sys_clk_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports sys_clk_n]
set_property PACKAGE_PIN F35 [get_ports sys_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports sys_clk_p]
set_property PACKAGE_PIN AW25 [get_ports UART_rxd]
set_property IOSTANDARD LVCMOS18 [get_ports UART_rxd]
set_property PACKAGE_PIN BB21 [get_ports UART_txd]
set_property IOSTANDARD LVCMOS18 [get_ports UART_txd]
create_clock -period 10.000 -name sys_clk_p_CLK -waveform {0.000 5.000} [get_ports {sys_clk_p}]
set_max_delay 1.0 -to [get_ports {test_vcu128_led_ext[*]}]
set_min_delay 1.0 -to [get_ports {test_vcu128_led_ext[*]}]
set_false_path -from [get_clocks -of_objects [get_pins vcu128_infrastructure_inst/MMCM_BASE_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins test_vcu128_gbe_pcs_pma/inst/clock_reset_i/Clk_Rst_I_Plle3_Tx/CLKOUT1]]
set_false_path -from [get_clocks -of_objects [get_pins test_vcu128_gbe_pcs_pma/inst/clock_reset_i/Clk_Rst_I_Plle3_Tx/CLKOUT1]] -to [get_clocks -of_objects [get_pins vcu128_infrastructure_inst/MMCM_BASE_inst/CLKOUT1]]
set_false_path -from [get_clocks -of_objects [get_pins vcu128_infrastructure_inst/MMCM_BASE_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins test_vcu128_gbe_pcs_pma/inst/clock_reset_i/Clk_Rst_I_Plle3_Tx/CLKOUT1]]
set_false_path -from [get_clocks -of_objects [get_pins test_vcu128_gbe_pcs_pma/inst/clock_reset_i/Clk_Rst_I_Plle3_Tx/CLKOUT1]] -to [get_clocks -of_objects [get_pins vcu128_infrastructure_inst/MMCM_BASE_inst/CLKOUT1]]
set_false_path -to [get_ports {test_vcu128_led_ext[*]}]
set_property CONFIG_VOLTAGE 1.8 [current_design]
