## Arty A7-35T constraints for top.v
## Board: Digilent Arty A7-35T
## Only the pins this design actually uses are included.

## Clock signal - 100 MHz onboard oscillator
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

## Reset button (CK_RST) - idle=1, pressed=0 (active-low)
set_property -dict { PACKAGE_PIN C2 IOSTANDARD LVCMOS33 } [get_ports { btn_rst_n }];

## USB-UART (FTDI FT2232HQ) - this is what PuTTY talks to
set_property -dict { PACKAGE_PIN A9  IOSTANDARD LVCMOS33 } [get_ports { rx }]; # uart_txd_in  (PC -> FPGA)
set_property -dict { PACKAGE_PIN D10 IOSTANDARD LVCMOS33 } [get_ports { tx }]; # uart_rxd_out (FPGA -> PC)

## Optional debug LEDs (LD4-LD6, individual green LEDs) - comment out if unused
#set_property -dict { PACKAGE_PIN H5  IOSTANDARD LVCMOS33 } [get_ports { led_rx_valid }];
#set_property -dict { PACKAGE_PIN J5  IOSTANDARD LVCMOS33 } [get_ports { led_frame_ready }];
#set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports { led_tx_busy }];
