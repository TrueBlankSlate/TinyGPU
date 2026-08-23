# fpga_top.xdc -- constraints for fpga_top.v.
#
# The clock constraint below is real and needed regardless of board choice
# -- adjust PERIOD to match whatever clk_i actually is (board oscillator
# directly, or a Clocking Wizard IP's output once you add one). 100MHz
# (10ns) matches what simulation used; back it off if timing doesn't close
# at that frequency once you have a real implementation run's numbers.
#
# Pin constraints (clk_i/rst_i package pins, IOSTANDARD) are board-specific
# and deliberately left as placeholders -- fill these in once a target
# board/part is chosen. Get exact pin names/standards from your board's
# reference XDC (every Xilinx dev board ships one).

create_clock -period 10.000 -name clk_i [get_ports clk_i]

# ---- Fill in once a board is chosen ----
# set_property PACKAGE_PIN <pin>      [get_ports clk_i]
# set_property IOSTANDARD  LVCMOS33   [get_ports clk_i]
# set_property PACKAGE_PIN <pin>      [get_ports rst_i]
# set_property IOSTANDARD  LVCMOS33   [get_ports rst_i]

# rst_i is asynchronous by design (see fpga_top.v's reset synchronizer) --
# tell the tools not to try to time it as a synchronous path.
set_false_path -from [get_ports rst_i]
