set_property board_part xilinx.com:zc702:part0:1.4 [current_project]

create_bd_design "zynq_system"

# - PS7, board-preset-configured, 25MHz FPGA clock set from the start -
set ps7 [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7 processing_system7_0]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable"} \
    $ps7

set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {25} \
] $ps7

# - fpga_top as a plain RTL module in the block design -
# (resolved by name from sources already added via import_sources.tcl --
# no path needed here)
set fpga_top [create_bd_cell -type module -reference fpga_top fpga_top_0]

# - Clock/reset: PL clock comes from PS7's FCLK_CLK0, not a board pin -
connect_bd_net [get_bd_pins $ps7/FCLK_CLK0]   [get_bd_pins $fpga_top/clk_i]
set rst_inv [create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic rst_inv_0]
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not}] $rst_inv
connect_bd_net [get_bd_pins $ps7/FCLK_RESET0_N] [get_bd_pins $rst_inv/Op1]
connect_bd_net [get_bd_pins $rst_inv/Res]       [get_bd_pins $fpga_top/rst_i]

# - GP0 direct wiring happens in connect_gp0_direct.tcl, run next.
# (No axi_smc_0 created here at all - unlike the original build_zynq_bd.tcl,
# we skip the SmartConnect detour from the start since we already know it
# black-boxes and gets deleted anyway.)

regenerate_bd_layout
save_bd_design

puts "\n==== PS7 + fpga_top_0 created, 25MHz set. ===="
puts "Next: source connect_gp0_direct.tcl to wire GP0 directly to fpga_top_0."