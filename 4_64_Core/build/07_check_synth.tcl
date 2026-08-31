# 07_check_synth.tcl -- run AFTER synth_1 (launched by 06_launch_synth.tcl)
# shows Complete in the Design Runs tab / runme.log.
#
# Checks for the known axi_smc_0/bd_2cb5 black-box failure mode (should be
# impossible now since 03_build_bd.tcl never creates axi_smc_0 at all, but
# worth confirming on a fresh project) and reports utilization.

set synth_status [get_property STATUS [get_runs synth_1]]
puts "\n==== synth_1 status: $synth_status ===="
if {![string match "*Complete*" $synth_status]} {
    puts "STOP: synth_1 hasn't completed yet (or failed). Check the Design Runs tab / runme.log before running this."
    return
}
    
set bb [get_cells -quiet -hierarchical -filter {REF_NAME =~ "*bd_2cb5*" || NAME =~ "*axi_smc*"}]
if {[llength $bb]} {
    puts "FAIL: black box present: $bb"
} else {
    puts "PASS: no axi_smc_0/black box."
}

report_utilization -hierarchical -hierarchical_depth 8 -file utilization_report.rpt
puts "\n==== Wrote utilization_report.rpt -- top-level totals below ===="
report_utilization

puts "\n==== u_mem hierarchy row (LUTRAMs should be near 0, RAMB36/RAMB18 should be > 0) ===="
report_utilization -hierarchical -hierarchical_depth 8 -cells [get_cells -hierarchical -filter {NAME =~ "*u_mem*"}]

close_design

puts "\n==== Done. Review PASS/FAIL and the u_mem breakdown above. ===="
puts "If PASS and utilization looks clean: 08_launch_impl.tcl"
