#!/usr/bin/env bash
# build.sh -- real riscv64-unknown-elf-gcc toolchain build of the boot
# program(s). Replaces the old hand-spliced boot_image.hex this repo
# previously maintained by hand: this script is now the ONLY thing that
# should ever write ../boot_image.hex or ../bench_image.hex (files
# axi4_bram_slave.v $readmemh's, at repo root, imported by
# build/import_sources.tcl). Do not hand-edit those files.
#
#   ./build.sh          -> builds boot_matmul.S  -> ../boot_image.hex   (plain demo)
#   ./build.sh bench     -> builds bench_matmul.S -> ../bench_image.hex  (mcycle benchmark)
#
# Requires a RISC-V toolchain on PATH -- confirmed working with the xPack
# GNU RISC-V Embedded GCC prebuilt for Windows/Linux/macOS
# (https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases --
# that distribution's binaries are prefixed riscv-none-elf-, not
# riscv64-unknown-elf-; pass --cross-prefix accordingly, or set
# CROSS_PREFIX below, e.g. `CROSS_PREFIX=riscv-none-elf- ./build.sh`).
set -euo pipefail

TARGET="${1:-boot}"
CROSS_PREFIX="${CROSS_PREFIX:-riscv64-unknown-elf-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"

case "$TARGET" in
    # bench_matmul.S uses `csrr` (mcycle, 0xb00) to bracket its timed windows --
    # modern binutils gas requires the Zicsr extension named explicitly in
    # -march for CSR instructions (older toolchains assumed it came free with
    # the base I extension). Zicsr is orthogonal to the vector-autogen concern
    # boot_matmul.S's header warns about -- it adds no vector/vsetvli risk.
    boot)  SRC="boot_matmul.S";  ELF="boot_matmul.elf";  HEX="$REPO_ROOT/boot_image.hex";  MARCH="rv64im" ;;
    bench) SRC="bench_matmul.S"; ELF="bench_matmul.elf"; HEX="$REPO_ROOT/bench_image.hex"; MARCH="rv64im_zicsr" ;;
    *) echo "usage: $0 [boot|bench]" >&2; exit 2 ;;
esac

CC="${CROSS_PREFIX}gcc"
OBJDUMP="${CROSS_PREFIX}objdump"

if ! command -v "$CC" >/dev/null 2>&1; then
    echo "error: $CC not found on PATH. Install a RISC-V toolchain and/or set CROSS_PREFIX." >&2
    exit 1
fi

# -march=$MARCH (NOT rv64gcv, and never with 'v' added) -- deliberately
# excludes the 'v' vector extension so the compiler can never auto-generate
# a vsetvli or real vector-register code for this program. See
# boot_matmul.S's header comment for why that would silently compute wrong
# results on this hardware even after the tinygpu_fsm.v is_vec_arith/funct3
# fix.
"$CC" -march=$MARCH -mabi=lp64 -nostdlib -nostartfiles -static \
    -T "$HERE/link.ld" -o "$HERE/$ELF" "$HERE/$SRC"

echo "== disassembly ($SRC): verify x1 holds the correct address before each"
echo "   vector-space .word, and that the 4 custom .word encodings appear"
echo "   byte-identical to I_VLE64/I_VMACC/I_VADD/I_VSE64 in src/tb/tb_cva6_boot.v =="
"$OBJDUMP" -d "$HERE/$ELF"

python3 "$HERE/elf2hex.py" "$HERE/$ELF" "$HEX" \
    --cross-prefix "$CROSS_PREFIX"

echo
if [ "$TARGET" = "bench" ]; then
    echo "Next steps (bench):"
    echo "  1. Confirm above disassembly: a 'csrr <rd>,mcycle' (csr 0xb00) brackets"
    echo "     both the scalar matmul loop and the offload sequence; x1 = 0x80001000"
    echo "     before vle64.v/vmacc, 0x80002000 before the first vse64.v, 0x80003000"
    echo "     before the second."
    echo "  2. Run src/tb/tb_bench_image.v (in Vivado) -- it \$readmemh's the"
    echo "     $HEX this script just wrote and confirms C_mul[3][3]==600 /"
    echo "     C_add[3][3]==32, both mcycle-delta words non-zero, and"
    echo "     scalar_delta > offload_delta, before touching synthesis/hardware."
    echo "  3. To benchmark on hardware: import bench_image.hex (not boot_image.hex)"
    echo "     as the Memory Initialization File, full OOC bitstream rebuild,"
    echo "     re-export .xsa, rebuild the Vitis app, boot, read the UART benchmark"
    echo "     lines printed by vitis/main.c."
else
    echo "Next steps (boot):"
    echo "  1. Confirm above disassembly: x1 = 0x80001000 before vle64.v/vmacc,"
    echo "     0x80002000 before the first vse64.v, 0x80003000 before the second."
    echo "  2. Run src/tb/tb_boot_image.v (in Vivado) -- it \$readmemh's the"
    echo "     $HEX this script just wrote and confirms"
    echo "     MUL_RESULT_ADDR+15 == 600 / RESULT_ADDR+15 == 32, i.e. that this"
    echo "     compiler-produced program still computes the right thing, before"
    echo "     touching synthesis/hardware."
fi
