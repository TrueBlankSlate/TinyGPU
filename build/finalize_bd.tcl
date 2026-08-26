set wrapper_file [make_wrapper -files [get_files zynq_system.bd] -top]
add_files -norecurse $wrapper_file
set_property top zynq_system_wrapper [current_fileset]
update_compile_order -fileset sources_1

puts "\n==== zynq_system_wrapper generated and set as top. ===="
puts "Next: verify the PS7 clock period, then run rebuild_launch.tcl."