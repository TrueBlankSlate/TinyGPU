## Clock (100 MHz)
set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0 5} [get_ports clk]

## Reset Button (CPU_RESET, active-low on Arty A7)
set_property PACKAGE_PIN C2 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## LEDs (LD4-LD7)
set_property PACKAGE_PIN H5 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN J5 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN T9 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN T10 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]