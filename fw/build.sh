#!/usr/bin/env bash
# build.sh -- real riscv64-unknown-elf-gcc toolchain build of boot_matmul.S.
# Replaces the old hand-spliced boot_image.hex this repo previously
# maintained by hand: this script is now the ONLY thing that should ever
# write ../boot_image.hex (the file axi4_bram_slave.v $readmemh's, at repo
# root, imported by build/import_sources.tcl). Do not hand-edit that file.
#
# Requires a RISC-V toolchain on PATH -- confirmed working with the xPack
# GNU RISC-V Embedded GCC prebuilt for Windows/Linux/macOS
# (https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases --
# that distribution's binaries are prefixed riscv-none-elf-, not
# riscv64-unknown-elf-; pass --cross-prefix accordingly, or set
# CROSS_PREFIX below, e.g. `CROSS_PREFIX=riscv-none-elf- ./build.sh`).
set -euo pipefail

CROSS_PREFIX="${CROSS_PREFIX:-riscv64-unknown-elf-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"

CC="${CROSS_PREFIX}gcc"
OBJDUMP="${CROSS_PREFIX}objdump"

if ! command -v "$CC" >/dev/null 2>&1; then
    echo "error: $CC not found on PATH. Install a RISC-V toolchain and/or set CROSS_PREFIX." >&2
    exit 1
fi

# -march=rv64im (NOT rv64gcv) -- deliberately excludes the 'v' vector
# extension so the compiler can never auto-generate a vsetvli or real
# vector-register code for this program. See boot_matmul.S's header
# comment for why that would silently compute wrong results on this
# hardware even after the tinygpu_fsm.v is_vec_arith/funct3 fix.
"$CC" -march=rv64im -mabi=lp64 -nostdlib -nostartfiles -static \
    -T "$HERE/link.ld" -o "$HERE/boot_matmul.elf" "$HERE/boot_matmul.S"

echo "== disassembly (verify x1 holds the correct address before each"
echo "   vector-space .word, and that the 4 custom .word encodings appear"
echo "   byte-identical to I_VLE64/I_VMACC/I_VADD/I_VSE64 in src/tb/tb_cva6_boot.v) =="
"$OBJDUMP" -d "$HERE/boot_matmul.elf"

python3 "$HERE/elf2hex.py" "$HERE/boot_matmul.elf" "$REPO_ROOT/boot_image.hex" \
    --cross-prefix "$CROSS_PREFIX"

echo
echo "Next steps:"
echo "  1. Confirm above disassembly: x1 = 0x80001000 before vle64.v/vmacc,"
echo "     0x80002000 before the first vse64.v, 0x80003000 before the second."
echo "  2. Run src/tb/tb_boot_image.v (in Vivado) -- it \$readmemh's the"
echo "     $REPO_ROOT/boot_image.hex this script just wrote and confirms"
echo "     MUL_RESULT_ADDR+15 == 600 / RESULT_ADDR+15 == 32, i.e. that this"
echo "     compiler-produced program still computes the right thing, before"
echo "     touching synthesis/hardware."
