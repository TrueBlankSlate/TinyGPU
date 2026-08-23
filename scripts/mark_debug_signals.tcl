# mark_debug_signals.tcl -- run AFTER `synth_design` (in the synthesized,
# open netlist), BEFORE `opt_design`/implementation.
#
# Marks the same signals that were hierarchically peeked at throughout
# simulation bring-up (dut.u_gpu.fsm_i.state, dut.u_gpu.vd_0_0, etc.) for
# debug, then inserts an ILA core so they're visible as a live hardware
# waveform over JTAG -- the direct hardware equivalent of those sim peeks.
#
# Usage (Tcl console, after synth_design has completed on fpga_top):
#   source {D:/TinyGPU/TinyGPU/scripts/mark_debug_signals.tcl}
#   opt_design
#   place_design
#   route_design
#   write_bitstream -force fpga_top.bit
#
# (write_debug_probes is called automatically as part of the debug core
# insertion below; its .ltx file is what Vivado's hardware manager needs
# to actually decode the ILA capture once the bitstream is programmed.)

set nets [list \
  [get_nets -hierarchical -filter {NAME =~ "*u_soc/u_gpu/fsm_i/state*"}] \
  [get_nets -hierarchical -filter {NAME =~ "*u_soc/u_gpu/vd_0_0*"}] \
  [get_nets -hierarchical -filter {NAME =~ "*u_soc/u_gpu/fsm_i/commit_recv_q*"}] \
  [get_nets -hierarchical -filter {NAME =~ "*u_soc/u_shim/cvxif_issue_valid_o*"}] \
  [get_nets -hierarchical -filter {NAME =~ "*u_soc/u_shim/cvxif_commit_valid_o*"}] \
]

foreach n $nets {
  if {[llength $n] > 0} {
    set_property MARK_DEBUG true $n
  } else {
    puts "WARNING: one of the requested debug nets was not found -- it may"
    puts "have been optimized away, or the hierarchy path changed. Check"
    puts "with: get_nets -hierarchical -filter {NAME =~ \"*fsm_i*\"}"
  }
}

# The 4 top-level bus signals already marked in fpga_top.v (dbg_noc_*) are
# picked up automatically since MARK_DEBUG is set directly in the RTL.
puts "Nets marked. Now run Tools -> Set Up Debug in the GUI (or"
puts "'set_property C_CLK_INPUT_FREQ_HZ ... [get_debug_cores dbg_hub]' +"
puts "the Debug Wizard's own generated commands if scripting end-to-end) --"
puts "it will find every MARK_DEBUG net above, build a correctly-sized ILA"
puts "automatically (multi-bit signals like fsm_i/state need per-probe"
puts "widths matched exactly, which the wizard handles; hand-writing"
puts "create_debug_core/connect_debug_port for each one is easy to get"
puts "subtly wrong), and connect its clock for you."
puts "Implementation must be (re-)run after debug core insertion either"
puts "way, and write_bitstream will also produce fpga_top.ltx alongside"
puts "the .bit -- both are needed to open the live waveform in Vivado's"
puts "Hardware Manager after programming."
