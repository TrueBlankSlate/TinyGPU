# connect_gp0_direct.tcl -- run in the Vivado Tcl console, zynq_system
# block design current.
#
# Replaces the axi_smc_0 SmartConnect (which was generating an empty,
# black-boxing nested block design because it couldn't infer fpga_top's
# raw RTL port widths -- confirmed via bd_2cb5.v showing numBlks=0,
# synth_mode=None, M00_AXI silently mirroring S00_AXI's 32-bit width).
# fpga_top's ps7_ar_*/ps7_r_* ports are now resized to match PS7's GP0
# exactly (ARADDR[31:0], ARID[11:0], ARLEN[3:0], RDATA[31:0], RID[11:0] --
# confirmed via get_bd_pins), so GP0 connects straight to them net-by-net.
# No converter IP, nothing that can black-box.
#
# Idempotent: safe to re-run after a partial failure. connect_bd_net
# errors (rather than no-ops) on a pin that already has a net -- deleting
# axi_smc_0 leaves its old nets dangling on GP0's pins, so every connect
# below clears any existing net on both endpoints first.

set ps7  [get_bd_cells processing_system7_0]
set top  [get_bd_cells fpga_top_0]

# ---- Remove the old SmartConnect ----
if {[llength [get_bd_cells -quiet axi_smc_0]]} {
    delete_bd_objs [get_bd_cells axi_smc_0]
}

proc safe_connect {pinA pinB} {
    # Already wired to each other (directly, or as two of a net's several
    # fanout pins, e.g. a ground net already feeding three PS7 pins) --
    # nothing to do. Checking net-name equality alone isn't enough: it
    # misses "pinB is already one of pinA's net's several fanout pins".
    set netA [get_bd_nets -quiet -of_objects $pinA]
    if {$netA ne ""} {
        if {[lsearch -exact [get_bd_pins -quiet -of_objects $netA] $pinB] >= 0} {
            return
        }
    }
    # Only clear a TRULY dangling net (exactly one pin left on it -- e.g.
    # axi_smc_0's old nets after it was deleted). Never touch a net that
    # still has other live loads (like FCLK_CLK0 feeding clk_i, rst_inv_0,
    # and M_AXI_GP0_ACLK) -- deleting that breaks every other load on it.
    foreach p [list $pinA $pinB] {
        set n [get_bd_nets -quiet -of_objects $p]
        if {$n eq ""} { continue }
        if {[llength [get_bd_pins -quiet -of_objects $n]] == 1} {
            delete_bd_objs $n
        }
    }
    connect_bd_net $pinA $pinB
}

# ---- GP0 needs its own AXI clock driven -- tie it to the same FCLK_CLK0 ----
# already feeding fpga_top_0 and rst_inv_0.
safe_connect [get_bd_pins $ps7/FCLK_CLK0] [get_bd_pins $ps7/M_AXI_GP0_ACLK]

# ---- Read channel: GP0 (master, AR* outputs / R* inputs) -> fpga_top (slave) ----
safe_connect [get_bd_pins $ps7/M_AXI_GP0_ARADDR]  [get_bd_pins $top/ps7_ar_addr]
safe_connect [get_bd_pins $ps7/M_AXI_GP0_ARID]    [get_bd_pins $top/ps7_ar_id]
safe_connect [get_bd_pins $ps7/M_AXI_GP0_ARLEN]   [get_bd_pins $top/ps7_ar_len]
safe_connect [get_bd_pins $ps7/M_AXI_GP0_ARVALID] [get_bd_pins $top/ps7_ar_valid]
safe_connect [get_bd_pins $top/ps7_ar_ready]      [get_bd_pins $ps7/M_AXI_GP0_ARREADY]

safe_connect [get_bd_pins $top/ps7_r_id]          [get_bd_pins $ps7/M_AXI_GP0_RID]
safe_connect [get_bd_pins $top/ps7_r_data]        [get_bd_pins $ps7/M_AXI_GP0_RDATA]
safe_connect [get_bd_pins $top/ps7_r_resp]        [get_bd_pins $ps7/M_AXI_GP0_RRESP]
safe_connect [get_bd_pins $top/ps7_r_last]        [get_bd_pins $ps7/M_AXI_GP0_RLAST]
safe_connect [get_bd_pins $top/ps7_r_valid]       [get_bd_pins $ps7/M_AXI_GP0_RVALID]
safe_connect [get_bd_pins $ps7/M_AXI_GP0_RREADY]  [get_bd_pins $top/ps7_r_ready]

# ---- GP0's write channel is unused (fpga_top's port is read-only by
# design) -- tie off what PS7 needs driven so nothing is left floating
# on an output PS7 expects a response on. AWREADY/WREADY/BVALID must
# never be left unconnected on a live AXI master or it can hang if
# software ever issues a write -- tie AWREADY/WREADY low (never accept)
# and BVALID low (never claim a response), which makes any accidental
# write to this address range simply stall harmlessly instead of behaving
# unpredictably.
if {[llength [get_bd_cells -quiet gnd_gp0_wr]] == 0} {
    set gnd [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant gnd_gp0_wr]
    set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0}] $gnd
} else {
    set gnd [get_bd_cells gnd_gp0_wr]
}
safe_connect [get_bd_pins $gnd/dout] [get_bd_pins $ps7/M_AXI_GP0_AWREADY]
safe_connect [get_bd_pins $gnd/dout] [get_bd_pins $ps7/M_AXI_GP0_WREADY]
safe_connect [get_bd_pins $gnd/dout] [get_bd_pins $ps7/M_AXI_GP0_BVALID]

# BID/BRESP are PS7 inputs with no driver now -- tie them off too so
# nothing is left floating (avoids an unconnected-input DRC warning).
# Separate constants, since they're different widths (12-bit vs 2-bit) --
# connect_bd_net ties one net to matching-width pins only.
if {[llength [get_bd_cells -quiet gnd_gp0_bid]] == 0} {
    set gnd_bid [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant gnd_gp0_bid]
    set_property -dict [list CONFIG.CONST_WIDTH {12} CONFIG.CONST_VAL {0}] $gnd_bid
} else {
    set gnd_bid [get_bd_cells gnd_gp0_bid]
}
safe_connect [get_bd_pins $gnd_bid/dout] [get_bd_pins $ps7/M_AXI_GP0_BID]

if {[llength [get_bd_cells -quiet gnd_gp0_bresp]] == 0} {
    set gnd_bresp [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant gnd_gp0_bresp]
    set_property -dict [list CONFIG.CONST_WIDTH {2} CONFIG.CONST_VAL {0}] $gnd_bresp
} else {
    set gnd_bresp [get_bd_cells gnd_gp0_bresp]
}
safe_connect [get_bd_pins $gnd_bresp/dout] [get_bd_pins $ps7/M_AXI_GP0_BRESP]

validate_bd_design
save_bd_design
