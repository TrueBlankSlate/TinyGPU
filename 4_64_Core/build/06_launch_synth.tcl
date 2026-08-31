# 06_launch_synth.tcl -- run after 05_finalize_bd.tcl.
#
# Deliberately does NOT call wait_on_run, so the Tcl console stays free --
# watch progress live in the Vivado GUI's "Design Runs" tab (bottom panel)
# or tail <proj_dir>/<proj_name>.runs/synth_1/runme.log yourself. Run
# 07_check_synth.tcl once synth_1 shows "synth_design Complete!".

update_compile_order -fileset sources_1
reset_target all [get_files zynq_system.bd]
generate_target all [get_files zynq_system.bd] -force
export_ip_user_files -of_objects [get_files zynq_system.bd] -no_script -sync -force -quiet

reset_run synth_1
launch_runs synth_1 -jobs 8

puts "\n==== synth_1 launched, not waiting. Watch the Design Runs tab or runme.log. ===="
puts "==== Run 07_check_synth.tcl once it shows Complete. ===="
