# connect_smc_to_fpga_top.tcl -- run in the Vivado Tcl console AFTER
# build_zynq_bd.tcl, with the zynq_system block design still open/current.
#
# Wires axi_smc_0's M00_AXI master leaf pins to fpga_top_0's ps7_ar_*/
# ps7_r_* ports. Written to auto-discover the exact M00_AXI pin names at
# runtime (via suffix matching) instead of hardcoding them, since exact
# SmartConnect leaf-pin capitalization/formatting can vary by Vivado
# version -- this avoids guessing wrong and silently mis-wiring the bus.
# Only the read channel is connected (fpga_top's port is read-only by
# design); any AW/W/B pins on M00_AXI are left unconnected on purpose.

# Map from SmartConnect's pin-name suffix (after the last "axi_", lower-
# cased) to the matching fpga_top_0 port.
set suffix_map [dict create \
    arid     ps7_ar_id \
    araddr   ps7_ar_addr \
    arlen    ps7_ar_len \
    arvalid  ps7_ar_valid \
    arready  ps7_ar_ready \
    rid      ps7_r_id \
    rdata    ps7_r_data \
    rresp    ps7_r_resp \
    rlast    ps7_r_last \
    rvalid   ps7_r_valid \
    rready   ps7_r_ready \
]

set smc_cell    "axi_smc_0"
set fpga_cell   "fpga_top_0"
set connected   {}
set unmatched   {}

foreach pin [get_bd_pins -of_objects [get_bd_cells $smc_cell]] {
    set pin_name [get_property NAME $pin]
    set lname [string tolower $pin_name]
    # Only look at M00 pins (skip S00_AXI, aclk, aresetn, config pins, etc).
    if {![string match "*m00*" $lname]} { continue }

    # Suffix = everything after the last "axi_" (case-insensitive).
    if {![regexp -nocase {axi_([a-z]+)$} $pin_name -> suffix]} { continue }
    set suffix [string tolower $suffix]

    if {[dict exists $suffix_map $suffix]} {
        set target_port [dict get $suffix_map $suffix]
        set target_pin [get_bd_pins -quiet $fpga_cell/$target_port]
        if {$target_pin eq ""} {
            puts "WARNING: fpga_top_0 has no pin named $target_port -- skipping $pin_name"
            continue
        }
        connect_bd_net $pin $target_pin
        lappend connected "$pin_name -> $fpga_cell/$target_port"
    } else {
        lappend unmatched $pin_name
    }
}

puts "\n---- Connected ([llength $connected]) ----"
foreach c $connected { puts "  $c" }

puts "\n---- M00 pins seen but not in the read-channel map (expected: AW/W/B write-channel pins, left unconnected) ----"
foreach u $unmatched { puts "  $u" }

if {[llength $connected] != 11} {
    puts "\nWARNING: expected 11 connections (5 AR + 6 R), got [llength $connected]."
    puts "Check the two lists above -- a target suffix may not have matched due to naming, fix manually for that one signal."
} else {
    puts "\nAll 11 read-channel signals connected."
}

validate_bd_design
save_bd_design
