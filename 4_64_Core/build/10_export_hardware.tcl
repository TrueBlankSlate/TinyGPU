# 10_export_hardware.tcl -- run after 09_generate_bitstream.tcl shows
# "Bitgen Completed Successfully" in runme.log. Writes a fixed (bitstream-
# included) hardware platform .xsa for Vitis -- the scripted equivalent of
# File -> Export -> Export Hardware (include bitstream) in the GUI.

set impl_status [get_property STATUS [get_runs impl_1]]
puts "\n==== impl_1 status: $impl_status ===="
if {![string match "*write_bitstream*Complete*" $impl_status]} {
    puts "STOP: bitstream generation hasn't completed yet (or failed). Check runme.log."
    return
}

set proj_dir [get_property DIRECTORY [current_project]]
set proj_name [get_property NAME [current_project]]
set xsa_path [file join $proj_dir "$proj_name.xsa"]

write_hw_platform -fixed -include_bit -force -file $xsa_path

puts "\n==== Exported hardware platform: $xsa_path ===="
puts "Next: open Vitis, create a platform component from this .xsa, add"
puts "vitis/main.c to a new application component, build, program the"
puts "device, and open a UART terminal (115200 8N1) -- see the repo README's"
puts "Vitis section for the full sequence."
