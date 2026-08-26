# rebuild_launch.tcl -- run in the Vivado Tcl console, 0_2_CVA6 project
# open, zynq_system block design current.
#
# Picks up the axi4_bram_slave.v RTL fix (mem_a/mem_b split, plus the
# Port B half-select moved out of the memory-read expression) and
# launches synth_1. Deliberately does NOT call wait_on_run, so the Tcl
# console stays free -- watch progress live in the Vivado GUI's
# "Design Runs" tab (bottom panel) or Tools -> Run Log, or just tail
# D:/Vivado_Projects/0_2_CVA6/0_2_CVA6.runs/synth_1/runme.log yourself.
# Run rebuild_check.tcl once synth_1 shows "synth_design Complete!".

update_compile_order -fileset sources_1
reset_target all [get_files zynq_system.bd]
generate_target all [get_files zynq_system.bd] -force
export_ip_user_files -of_objects [get_files zynq_system.bd] -no_script -sync -force -quiet

reset_run synth_1
launch_runs synth_1 -jobs 8

puts "\n==== synth_1 launched, not waiting. Watch the Design Runs tab or runme.log. ===="
puts "==== Run rebuild_check.tcl once it shows Complete. ===="
