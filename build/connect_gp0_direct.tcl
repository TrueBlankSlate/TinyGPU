set ps7  [get_bd_cells processing_system7_0]
set top  [get_bd_cells fpga_top_0]

if {[llength [get_bd_cells -quiet axi_smc_0]]} {
    delete_bd_objs [get_bd_cells axi_smc_0]
}

proc safe_connect {pinA pinB} {
    set netA [get_bd_nets -quiet -of_objects $pinA]
    if {$netA ne ""} {
        if {[lsearch -exact [get_bd_pins -quiet -of_objects $netA] $pinB] >= 0} {
            return
        }
    }
    foreach p [list $pinA $pinB] {
        set n [get_bd_nets -quiet -of_objects $p]
        if {$n eq ""} { continue }
        if {[llength [get_bd_pins -quiet -of_objects $n]] == 1} {
            delete_bd_objs $n
        }
    }
    connect_bd_net $pinA $pinB
}

safe_connect [get_bd_pins $ps7/FCLK_CLK0] [get_bd_pins $ps7/M_AXI_GP0_ACLK]

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

if {[llength [get_bd_cells -quiet gnd_gp0_wr]] == 0} {
    set gnd [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant gnd_gp0_wr]
    set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0}] $gnd
} else {
    set gnd [get_bd_cells gnd_gp0_wr]
}
safe_connect [get_bd_pins $gnd/dout] [get_bd_pins $ps7/M_AXI_GP0_AWREADY]
safe_connect [get_bd_pins $gnd/dout] [get_bd_pins $ps7/M_AXI_GP0_WREADY]
safe_connect [get_bd_pins $gnd/dout] [get_bd_pins $ps7/M_AXI_GP0_BVALID]

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
