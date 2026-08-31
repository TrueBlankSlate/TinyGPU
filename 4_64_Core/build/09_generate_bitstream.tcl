# 09_generate_bitstream.tcl -- run after 08_launch_impl.tcl shows
# route_design Complete!. Recommend eyeballing the timing summary
# (report_timing_summary) and DRC (report_drc) before this step, though
# neither is a hard gate here.

set impl_status [get_property STATUS [get_runs impl_1]]
puts "\n==== impl_1 status: $impl_status ===="
if {![string match "*route_design*Complete*" $impl_status] && ![string match "*Complete!*" $impl_status]} {
    puts "STOP: impl_1 hasn't finished routing yet (or failed). Check the Design Runs tab / runme.log."
    return
}

launch_runs impl_1 -to_step write_bitstream -jobs 8

puts "\n==== Bitstream generation launched (write_bitstream step), not waiting. ===="
puts "Watch the Design Runs tab or runme.log -- look for \"Bitgen Completed Successfully\"."
puts "Next: 10_export_hardware.tcl"
