# rebuild_after_ram_fix.tcl -- run in the Vivado Tcl console, 0_2_CVA6
# project open, zynq_system block design current.
#
# Picks up the axi4_bram_slave.v RTL fix (mem[] split into mem_a/mem_b so
# Port A and Port B each stay a clean 1-write/1-read BRAM inference,
# instead of 3 accesses into one array forcing a 32768-LUTRAM fallback --
# confirmed via utilization_det8.rpt: u_mem showed 32768 LUTRAMs, 0
# RAMB36/RAMB18). Re-synthesizes from scratch and checks BOTH open
# problems in one pass:
#   1. the axi_smc_0/bd_2cb5 black box (should already be gone -- this
#      just re-confirms it stays gone through a clean rebuild)
#   2. the LUT blowup from the broken BRAM inference (should now be fixed)
#
# Stops and prints a clear FAIL message at the first failed step instead
# of plowing ahead into a doomed implementation run.

# ---- 1. Force Vivado to notice the RTL file changed on disk ----
update_compile_order -fileset sources_1
reset_target all [get_files zynq_system.bd]
generate_target all [get_files zynq_system.bd] -force
export_ip_user_files -of_objects [get_files zynq_system.bd] -no_script -sync -force -quiet

# ---- 2. Full re-synth of the top level (forces the fpga_top_0 OOC run
#         to re-run too, since fpga_top.v/axi4_bram_slave.v changed) ----
reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "\n==== synth_1 status: $synth_status ===="
if {![string match "*Complete*" $synth_status]} {
    puts "FAIL: synth_1 did not complete. Open D:/Vivado_Projects/0_2_CVA6/0_2_CVA6.runs/synth_1/runme.log and find the first ERROR line."
    return
}

open_run synth_1

# ---- 3. Check #1: black box must be gone ----
set bb [get_cells -quiet -hierarchical -filter {REF_NAME =~ "*bd_2cb5*" || NAME =~ "*axi_smc*"}]
if {[llength $bb]} {
    puts "FAIL: black box still present: $bb"
} else {
    puts "PASS: no axi_smc_0/bd_2cb5 black box."
}

# ---- 4. Check #2: LUT count, with a breakdown of u_mem specifically so
#         we can see straight away whether mem_a/mem_b inferred as BRAM
#         (RAMB36/RAMB18 > 0, LUTRAMs ~0) or fell back to LUTRAM again ----
report_utilization -hierarchical -hierarchical_depth 8 -file utilization_after_ram_fix.rpt
puts "\n==== Wrote utilization_after_ram_fix.rpt -- top-level totals below ===="
report_utilization

puts "\n==== u_mem hierarchy row (LUTRAMs should now be near 0, RAMB36/RAMB18 should be > 0) ===="
report_utilization -hierarchical -hierarchical_depth 8 -cells [get_cells -hierarchical -filter {NAME =~ "*u_mem*"}]

close_design

puts "\n==== Done. Review PASS/FAIL lines above and the u_mem breakdown before proceeding to impl_1. ===="
