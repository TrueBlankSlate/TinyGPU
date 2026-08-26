# build_zynq_bd.tcl -- run in the Vivado Tcl console, inside the open
# 0_2_CVA6 project (D:/Vivado_Projects/0_2_CVA6).
#
# Builds a block design that pairs PS7 (same board preset already proven
# working in D:/Vivado_Projects/zynq_tut's Hello World UART test) with the
# existing fpga_top.v (CVA6 + TinyGPU + dual-port BRAM), so PS7's GP0 AXI
# master can read the matmul result out of u_mem's new read-only Port B
# and print it over UART1 -- the same UART1 the Hello World already used.
#
# Board part matches zynq_tut exactly (confirmed via its .xpr):
#   xilinx.com:zc702:part0:1.4  ->  part xc7z020clg484-1
#
# What this script does NOT do, on purpose: it does not fabricate any PS7
# MIO/clock parameter -- apply_bd_automation with the board preset below
# pulls the exact same verified config zynq_tut already used, the same
# way IP integrator did there.

set_property board_part xilinx.com:zc702:part0:1.4 [current_project]

create_bd_design "zynq_system"

# ---- PS7, board-preset-configured (same as zynq_tut) ----
set ps7 [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7 processing_system7_0]
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable"} \
    $ps7

# Enable GP0 as a master (PS -> PL reads) -- everything else stays at the
# board-preset defaults already proven in zynq_tut.
set_property -dict [list CONFIG.PCW_USE_M_AXI_GP0 {1}] $ps7

# ---- fpga_top as a plain RTL module in the block design ----
# Add all the source files fpga_top.v depends on (adjust list if you add
# more later -- these are every file fpga_top.v's hierarchy currently
# needs, per the 4_64_Core directory).
set rtl_dir "D:/TinyGPU/TinyGPU/4_64_Core"
add_files -norecurse [list \
    $rtl_dir/fpga_top.v \
    $rtl_dir/cva6_tinygpu_soc.v \
    $rtl_dir/cva6_sv_shim.sv \
    $rtl_dir/tinygpu_cvxif_wrap.v \
    $rtl_dir/tinygpu_fsm.v \
    $rtl_dir/tingpu_decoder.v \
    $rtl_dir/writeback.v \
    $rtl_dir/axi4_bram_slave.v \
    $rtl_dir/alu.v \
    $rtl_dir/cache.v \
    $rtl_dir/cache_l3.v \
    $rtl_dir/register_file.v \
]
update_compile_order -fileset sources_1

set fpga_top [create_bd_cell -type module -reference fpga_top fpga_top_0]

# ---- Clock/reset: PL clock comes from PS7's FCLK_CLK0, not a board pin ----
connect_bd_net [get_bd_pins $ps7/FCLK_CLK0]   [get_bd_pins $fpga_top/clk_i]
# rst_i is active-HIGH on fpga_top but FCLK_RESET0_N is active-LOW --
# invert it (util_vector_logic, op NOT) rather than assuming polarity.
set rst_inv [create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic rst_inv_0]
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not}] $rst_inv
connect_bd_net [get_bd_pins $ps7/FCLK_RESET0_N] [get_bd_pins $rst_inv/Op1]
connect_bd_net [get_bd_pins $rst_inv/Res]       [get_bd_pins $fpga_top/rst_i]

# ---- AXI SmartConnect: GP0 (32-bit AXI3) -> fpga_top's ps7_ar/r port (64-bit AXI4) ----
# SmartConnect handles both the AXI3->AXI4 protocol conversion and the
# 32->64 bit width conversion natively -- deliberately not hand-rolled.
set smc [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smc_0]
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $smc
connect_bd_intf_net [get_bd_intf_pins $ps7/M_AXI_GP0] [get_bd_intf_pins $smc/S00_AXI]
connect_bd_net [get_bd_pins $ps7/FCLK_CLK0] [get_bd_pins $smc/aclk]
connect_bd_net [get_bd_pins $rst_inv/Res]   [get_bd_pins $smc/aresetn]

# ---- Manual step (do this one in the GUI, not scripted) ----
# fpga_top's ps7_ar_*/ps7_r_* ports are plain RTL pins, not a tagged AXI
# interface, so axi_smc_0's M00_AXI master can't be intf-connected to them
# automatically. In the block design canvas: expand axi_smc_0's M00_AXI
# pins and fpga_top_0's ps7_ar_*/ps7_r_* pins, and wire each signal
# straight across (ar*id/addr/len/valid/ready, r*id/data/resp/last/valid/
# ready -- 11 wires total). This is the one part safer done by hand than
# guessed in a script, since exact M00_AXI leaf pin names can vary by
# Vivado/SmartConnect version.

regenerate_bd_layout
save_bd_design
make_wrapper -files [get_files zynq_system.bd] -top
add_files -norecurse [get_files -of_objects [get_filesets sources_1] *zynq_system_wrapper.v]
set_property top zynq_system_wrapper [current_fileset]
update_compile_order -fileset sources_1
