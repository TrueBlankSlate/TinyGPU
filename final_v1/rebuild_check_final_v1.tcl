# rebuild_check_final_v1.tcl -- run AFTER synth_1 (launched by
# rebuild_launch_final_v1.tcl) shows Complete in the Design Runs tab /
# runme.log.
#
# Checks the same two things that bit us in 0_2_CVA6, since this project
# shares the same IP/RTL structure:
#   1. no axi_smc_0/black box (should never appear -- this project never
#      creates axi_smc_0 in the first place).
#   2. clean BRAM inference in axi4_bram_slave.v's u_mem (LUTRAMs ~0,
#      RAMB36/RAMB18 > 0) -- confirms the same mem_a/mem_b split still
#      infers correctly with an unchanged RTL structure.

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

report_utilization -hierarchical -hierarchical_depth 8 -file utilization_final_v1.rpt
puts "\n==== Wrote utilization_final_v1.rpt -- top-level totals below ===="
report_utilization

puts "\n==== u_mem hierarchy row (LUTRAMs should be near 0, RAMB36/RAMB18 should be > 0) ===="
report_utilization -hierarchical -hierarchical_depth 8 -cells [get_cells -hierarchical -filter {NAME =~ "*u_mem*"}]

close_design

puts "\n==== Done. Review PASS/FAIL and the u_mem breakdown above. ===="
puts "If PASS and utilization looks clean: reset_run impl_1; launch_runs impl_1 -jobs 8"
puts "(non-blocking, same as synth_1 -- watch impl_1/runme.log)."
