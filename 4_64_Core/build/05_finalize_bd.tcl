# 05_finalize_bd.tcl -- run after 04_connect_gp0.tcl has validated and
# saved the block design. Generates the HDL wrapper and sets it as the
# top-level for synthesis/implementation.

set wrapper_file [make_wrapper -files [get_files zynq_system.bd] -top]
add_files -norecurse $wrapper_file
set_property top zynq_system_wrapper [current_fileset]
update_compile_order -fileset sources_1

puts "\n==== zynq_system_wrapper generated and set as top. ===="
puts "Next: 06_launch_synth.tcl"
