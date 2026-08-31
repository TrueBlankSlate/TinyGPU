# 08_launch_impl.tcl -- run after 07_check_synth.tcl shows PASS.
#
# Runs implementation through route_design only (NOT bitstream yet -- that
# is 09_generate_bitstream.tcl, kept separate so you can inspect timing/
# DRC after routing before committing to bitgen). Non-blocking, same
# pattern as synth -- watch the Design Runs tab or runme.log.

reset_run impl_1
launch_runs impl_1 -to_step route_design -jobs 8

puts "\n==== impl_1 launched (through route_design), not waiting. ===="
puts "Watch the Design Runs tab or <proj>.runs/impl_1/runme.log."
puts "Run 09_generate_bitstream.tcl once it shows route_design Complete!."
