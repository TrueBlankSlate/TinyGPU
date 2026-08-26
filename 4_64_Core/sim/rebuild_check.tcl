# rebuild_check.tcl -- run AFTER synth_1 (launched by rebuild_launch.tcl)
# shows Complete in the Design Runs tab / runme.log.
#
# Checks both open problems in one pass:
#   1. axi_smc_0/bd_2cb5 black box -- should already be gone, this just
#      re-confirms it stays gone through the clean rebuild.
#   2. the LUT blowup from the broken BRAM inference in axi4_bram_slave.v
#      (mem_a/mem_b split + Port B half-select moved out of the memory
#      read) -- should now be fixed.

set synth_status [get_property STATUS [get_runs synth_1]]
puts "\n==== synth_1 status: $synth_status ===="
if {![string match "*Complete*" $synth_status]} {
    puts "STOP: synth_1 hasn't completed yet (or failed). Check the Design Runs tab / runme.log before running this."
    return
}

set bb [get_cells -quiet -hierarchical -filter {REF_NAME =~ "*bd_2cb5*" || NAME =~ "*axi_smc*"}]
if {[llength $bb]} {
    puts "FAIL: black box still present: $bb"
} else {
    puts "PASS: no axi_smc_0/bd_2cb5 black box."
}

report_utilization -hierarchical -hierarchical_depth 8 -file utilization_after_ram_fix.rpt
puts "\n==== Wrote utilization_after_ram_fix.rpt -- top-level totals below ===="
report_utilization

puts "\n==== u_mem hierarchy row (LUTRAMs should now be near 0, RAMB36/RAMB18 should be > 0) ===="
report_utilization -hierarchical -hierarchical_depth 8 -cells [get_cells -hierarchical -filter {NAME =~ "*u_mem*"}]

close_design

puts "\n==== Done. Review PASS/FAIL and the u_mem breakdown above. ===="
