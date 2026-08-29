# TinyGPU

A small SIMD accelerator, attached to a [CVA6](https://github.com/openhwgroup/cva6) RISC-V core
as a custom coprocessor extension (CV-X-IF), that runs 4x4 matrix operations
(`vmacc` matrix-multiply, `vadd.vv` elementwise add) on real Zynq-7000 hardware.
CVA6 issues vector-style instructions over the CV-X-IF interface; TinyGPU
decodes them, runs four ALU lanes in parallel, and writes results back to
memory over AXI.

![Elaborated design](../Images/elaborated_design.png)

## Overview

TinyGPU is four ALU lanes (`design_1` / "the SIMD core") wrapped by a small
FSM (`tinygpu_fsm.v`) that:

- receives an offloaded instruction from CVA6 over CV-X-IF (`tinygpu_cvxif_wrap.v`,
  `cva6_sv_shim.sv`),
- pulls the operand matrices (`mat_a`, `mat_b`) into a 4-row/4-column
  register cache (`cache.v`, `register_file.v`),
- runs all 4 lanes' ALUs (`alu.v`) in parallel per pass, either as a plain
  elementwise op or, for `vmacc`, accumulating each lane's product into a
  dot-product term (`dot_reg[]` in `design_1.v`) across 4 passes to produce
  one row of a real matrix product,
- and drives an AXI4 write burst (`writeback.v`) to park the 4x4 result back
  in memory for the host to read.

The whole thing is built as a Zynq PS7 + custom PL design
(`zynq_system.bd`): CVA6 and TinyGPU live in the PL as `fpga_top`, boot
straight out of a synthesizable BRAM (`axi4_bram_slave.v`, preloaded via
`boot_image.hex`) instead of an OS, run a fixed instruction sequence (load
matrix A, `vmacc` A×A, store, `vadd.vv` A+A, store, loop), and the PS7's
ARM side (running a bare-metal Vitis app) reads the results straight out of
PL memory over the GP0 AXI port and prints them over UART.

```
                 ┌───────────────────────────── fpga_top (PL) ─────────────────────────────┐
                 │                                                                          │
PS7 (ARM) ───────┼──► GP0 AXI ──► axi4_bram_slave (dual-port: boot ROM + result RAM)         │
  Vitis app      │                        ▲                                                 │
  (prints        │                        │ AXI (CVA6 fetch/load/store)                     │
  results        │                        │                                                 │
  over UART)     │      CVA6 core ────────┴──► tinygpu_cvxif_wrap ──► tinygpu_fsm ──► design_1│
                 │   (RISC-V + CV-X-IF)      (custom instr. dispatch)   (FSM,        (4 ALU   │
                 │                                                       AXI wr.)     lanes)  │
                 └──────────────────────────────────────────────────────────────────────────┘
```

### What it does, concretely

1. On reset, CVA6 boots directly from `boot_image.hex` (no OS, no bootloader)
   and runs a short hand-assembled RISC-V program that:
   - loads a 4x4 matrix `A` (64-bit elements) via a custom `vle64.v` load,
   - issues `vmacc` (matrix multiply, A × A) and stores the 4x4 result `C_mul`,
   - issues `vadd.vv` (elementwise add, A + A) and stores the 4x4 result `C_add`,
   - jumps to itself (`jal x0,0`) to park.
2. Every custom vector instruction is caught by CVA6's CV-X-IF offload
   interface and handed to TinyGPU instead of being executed on the scalar
   pipeline.
3. TinyGPU computes the result across 4 lanes/4 passes and writes it back
   over AXI4 to a fixed address in PL memory.
4. The Zynq PS7 (a bare-metal Vitis app, `vitis/main.c`) reads both result
   matrices straight out of that PL memory through the GP0 AXI aperture
   (`0x4000_0000`+) and prints them over UART:
   ```
   C_mul = A x A (vmacc)
   [   90  100  110  120 ]
   [  202  228  254  280 ]
   [  314  356  398  440 ]
   [  426  484  542  600 ]

   C_add = A + A (vadd.vv)
   [    2    4    6    8 ]
   [   10   12   14   16 ]
   [   18   20   22   24 ]
   [   26   28   30   32 ]
   ```

### Block design (Vivado)

![TinyGPU block design](../Images/tinygpu_block_design.png)

PS7 is configured with the board preset, `M_AXI_GP0` enabled, and a 25MHz
FPGA clock. `fpga_top` is wired in as a plain RTL module (not packaged as an
IP), with GP0 connected **directly** to `axi4_bram_slave`'s AXI-lite-style
read port (no SmartConnect / interconnect in the datapath) so the PS7 can
read TinyGPU's result memory with the simplest possible address decode.

![Zynq implemented design](../Images/zynq_implemented_design.png)

## Repo layout

```
main/
  boot_image.hex   -- $readmemh preload for axi4_bram_slave (real-hardware boot program)
  build/           -- Vivado Tcl scripts (source these in order, see below)
  cvxif/           -- CV-X-IF glue: AXI slaves, CVA6<->TinyGPU shim, dispatch FSM
  src/rtl/         -- TinyGPU core: ALU lanes, cache, register file, decoder, writeback
  src/sim/         -- testbenches (tb_cva6_boot is the main boot+matmul test)
  vitis/           -- main.c for the PS7 bare-metal app (reads results, prints over UART)
```

TinyGPU expects a sibling clone of CVA6 on disk, i.e.:

```
<parent>/
  TinyGPU/...      (this repo)
  CVA6/cva6/...    (https://github.com/openhwgroup/cva6)
```

`build/import_sources.tcl` computes both `repo_root` and `CVA6_ROOT` from its
own location (`[info script]`), so as long as the two repos are siblings this
works unmodified after a fresh clone anywhere. If your CVA6 clone lives
somewhere else, edit the one `CVA6_ROOT` line at the top of
`import_sources.tcl`.

## How to build in Vivado

Tested with Vivado 2025.2, targeting a Zynq-7000 (`xc7z020clg484`, ZC702
board preset).

1. **Create a new RTL project** targeting board part `xilinx.com:zc702:part0:1.4`
   (or edit `build/build_zynq_bd.tcl` if targeting different hardware).
2. **Import sources** — open the Tcl console in Vivado and run:
   ```tcl
   source {<path-to-repo>/main/build/import_sources.tcl}
   ```
   This adds all CVA6 core files, all TinyGPU RTL/sim files, `boot_image.hex`
   (as a Memory Initialization File), and `build/fpga_top.xdc`, then sets
   `tb_cva6_boot` as the simulation top.
3. **Simulate first** (recommended, zero bitstream risk) — run behavioral
   simulation on `tb_cva6_boot` and confirm the matmul/add results land at
   the expected memory offsets before touching synthesis.
4. **Build the block design**:
   ```tcl
   source {<path-to-repo>/main/build/build_zynq_bd.tcl}
   source {<path-to-repo>/main/build/connect_gp0_direct.tcl}
   source {<path-to-repo>/main/build/finalize_bd.tcl}
   ```
   This creates the PS7 + `fpga_top` block design, wires GP0 directly to
   `fpga_top`'s AXI read port (no SmartConnect), generates the HDL wrapper,
   and sets it as the top module.
5. **Run synthesis, implementation, and generate the bitstream**:
   ```tcl
   source {<path-to-repo>/main/build/rebuild_launch.tcl}
   ```
   > **Important — out-of-context IP caching:** `fpga_top` lives inside
   > `zynq_system.bd` and gets its own cached out-of-context synthesis run,
   > separate from the top-level `synth_1`. If you ever change
   > `boot_image.hex` (or any file `fpga_top` depends on) and just
   > `reset_run synth_1`, Vivado may **not** notice the block design's
   > cached IP is stale and will silently reuse the old synthesized
   > `fpga_top`. `rebuild_launch.tcl` handles this correctly
   > (`reset_target all` + `generate_target all -force` on the `.bd` before
   > resetting `synth_1`) — always rebuild through it rather than
   > `reset_run`/`launch_runs` alone after touching a file `fpga_top` depends on.
6. `build/rebuild_check.tcl` re-runs a post-implementation utilization
   report if you need one.
7. **Export hardware** (Vivado: File → Export → Export Hardware, include
   bitstream) to produce the `.xsa` for Vitis.

## Vitis (host-side app)

1. Create a platform component from the exported `.xsa`, and an application
   component (standalone domain) pointing at that platform.
2. Copy `vitis/main.c` into the application component's `src/`.
3. Build the platform, then the application, program the device, open a
   serial terminal (UART, 115200 8N1 by default on this board), and reset
   the board — CVA6 reboots from `boot_image.hex` and the app prints
   `C_mul` and `C_add` as shown above.

If you change `boot_image.hex` or any RTL `fpga_top` depends on, you must
regenerate the bitstream (see the out-of-context caching note above),
**re-export hardware**, and rebuild the Vitis platform/application against
the fresh `.xsa` — an app built against a stale `.xsa` will boot the old
hardware even if the bitstream on disk is current.
