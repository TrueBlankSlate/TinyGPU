set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { CLK100MHZ }];

set_property -dict { PACKAGE_PIN D9  IOSTANDARD LVCMOS33 } [get_ports { btn_rst }];

set_property -dict { PACKAGE_PIN G13 IOSTANDARD LVCMOS33 } [get_ports { seg[0] }]; # a
set_property -dict { PACKAGE_PIN B11 IOSTANDARD LVCMOS33 } [get_ports { seg[1] }]; # b
set_property -dict { PACKAGE_PIN A11 IOSTANDARD LVCMOS33 } [get_ports { seg[2] }]; # c
set_property -dict { PACKAGE_PIN D12 IOSTANDARD LVCMOS33 } [get_ports { seg[3] }]; # d
set_property -dict { PACKAGE_PIN D13 IOSTANDARD LVCMOS33 } [get_ports { seg[4] }]; # e
set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports { seg[5] }]; # f
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports { seg[6] }]; # g

set_property CFGBVS VCCO [current_design];
set_property CONFIG_VOLTAGE 3.3 [current_design];