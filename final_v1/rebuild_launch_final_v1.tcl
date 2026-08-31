# rebuild_launch_final_v1.tcl -- run in the Vivado Tcl console, final_v1
# project open, zynq_system_wrapper set as top (after finalize_bd_final_v1.tcl).
#
# Deliberately does NOT call wait_on_run, so the Tcl console stays free --
# watch progress live in the Design Runs tab (bottom panel) or by tailing
# D:/Vivado_Projects/final_v1/final_v1.runs/synth_1/runme.log yourself.
# Run rebuild_check_final_v1.tcl once synth_1 shows "synth_design Complete!".

update_compile_order -fileset sources_1
reset_target all [get_files zynq_system.bd]
generate_target all [get_files zynq_system.bd] -force
export_ip_user_files -of_objects [get_files zynq_system.bd] -no_script -sync -force -quiet

reset_run synth_1
launch_runs synth_1 -jobs 8

puts "\n==== synth_1 launched, not waiting. Watch the Design Runs tab or runme.log. ===="
puts "==== Run rebuild_check_final_v1.tcl once it shows Complete. ===="
