# 01_create_project.tcl -- run in Vivado's Tcl console with NO project open
# (Tools -> Run Tcl Script, or paste into the Tcl console after a fresh
# `vivado` launch). Creates a brand-new RTL project targeting the same
# ZC702 part/board preset every other script in this repo assumes.
#
# Edit proj_name/proj_dir below if you want a different location -- every
# later script in this folder resolves everything else (source paths,
# CVA6_ROOT) from the project's own state, not from this variable, so
# changing it here is safe and needs no other edits.

set proj_name "TinyGPU_Compiler"
set proj_dir  "D:/Vivado_Projects/$proj_name"

create_project $proj_name $proj_dir -part xc7z020clg484-1 -force
set_property board_part xilinx.com:zc702:part0:1.4 [current_project]
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]

puts "\n==== Project '$proj_name' created at $proj_dir ===="
puts "Part: xc7z020clg484-1, board: xilinx.com:zc702:part0:1.4 (matches"
puts "zynq_tut's proven Hello World config and every other script in this repo)."
puts "Next: 02_import_sources.tcl"
