update_compile_order -fileset sources_1
reset_target all [get_files zynq_system.bd]
generate_target all [get_files zynq_system.bd] -force
export_ip_user_files -of_objects [get_files zynq_system.bd] -no_script -sync -force -quiet

reset_run synth_1
launch_runs synth_1 -jobs 8

puts "\n==== synth_1 launched, not waiting. Watch the Design Runs tab or runme.log. ===="
puts "==== Run rebuild_check.tcl once it shows Complete. ===="