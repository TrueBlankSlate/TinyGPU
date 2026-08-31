# finalize_bd_final_v1.tcl -- run AFTER connect_gp0_direct.tcl has
# validated and saved the block design (GP0 wired directly to fpga_top_0,
# no axi_smc_0). Generates the wrapper and sets it as the top-level for
# synthesis/implementation -- the same final step build_zynq_bd.tcl's
# original version did at its end, split out here since this project's
# build_zynq_bd_final_v1.tcl stops before it (no axi_smc_0 detour to wire
# around first).

# make_wrapper returns the generated wrapper's path directly -- using
# that instead of filtering get_files against sources_1, since the
# wrapper isn't registered as a project source yet at this point (that's
# what add_files below is for) and so can't be found by that filter.
set wrapper_file [make_wrapper -files [get_files zynq_system.bd] -top]
add_files -norecurse $wrapper_file
set_property top zynq_system_wrapper [current_fileset]
update_compile_order -fileset sources_1

puts "\n==== zynq_system_wrapper generated and set as top. ===="
puts "Next: verify the PS7 clock period, then run rebuild_launch_final_v1.tcl."
