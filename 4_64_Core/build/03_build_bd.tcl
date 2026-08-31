# 03_build_bd.tcl -- run after 02_import_sources.tcl.
#
# Builds the PS7 + fpga_top block design directly, skipping the axi_smc_0
# SmartConnect detour entirely -- confirmed (in this repo's earlier
# bring-up) to silently black-box itself against fpga_top's raw RTL ports
# (numBlks=0, M00_AXI mirroring S00_AXI's 32-bit width, no error). GP0 is
# wired straight to fpga_top in 04_connect_gp0.tcl instead.

set_property board_part xilinx.com:zc702:part0:1.4 [current_project]

create_bd_design "zynq_system"

# ---- PS7, board-preset-configured, 25MHz FPGA clock set from the start ----
set ps7 [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7 processing_system7_0]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable"} \
    $ps7

set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {25} \
] $ps7

# ---- fpga_top as a plain RTL module in the block design ----
# (resolved by module name from sources already added by
# 02_import_sources.tcl -- no path needed here)
set fpga_top [create_bd_cell -type module -reference fpga_top fpga_top_0]

# ---- Clock/reset: PL clock comes from PS7's FCLK_CLK0, not a board pin ----
connect_bd_net [get_bd_pins $ps7/FCLK_CLK0]   [get_bd_pins $fpga_top/clk_i]
# rst_i is active-HIGH on fpga_top but FCLK_RESET0_N is active-LOW -- invert
# it (util_vector_logic, op NOT) rather than assuming polarity matches.
set rst_inv [create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic rst_inv_0]
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not}] $rst_inv
connect_bd_net [get_bd_pins $ps7/FCLK_RESET0_N] [get_bd_pins $rst_inv/Op1]
connect_bd_net [get_bd_pins $rst_inv/Res]       [get_bd_pins $fpga_top/rst_i]

regenerate_bd_layout
save_bd_design

puts "\n==== PS7 + fpga_top_0 created, 25MHz set. ===="
puts "Next: 04_connect_gp0.tcl (wires GP0 directly to fpga_top_0)."
