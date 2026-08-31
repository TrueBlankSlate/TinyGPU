#!/usr/bin/env bash
# build.sh -- real riscv64-unknown-elf-gcc toolchain build of boot_matmul.S,
# replacing the hand-spliced boot_image.hex this repo previously maintained
# by hand. Requires a RISC-V toolchain on PATH (see README note below) --
# NOT present on the machine this was authored on, so this script has not
# been run or verified end-to-end yet. Run it yourself once a toolchain is
# installed, and diff/sim-check the output before trusting it (see the
# repo's plan notes / full_pipeline.md for the verification steps).
#
# Toolchain: any riscv64-unknown-elf-gcc distribution works (e.g. the
# xPack GNU RISC-V Embedded GCC prebuilt for Windows/Linux/macOS,
# https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases --
# note that distribution's binaries are prefixed riscv-none-elf-, not
# riscv64-unknown-elf-; pass --cross-prefix accordingly, or set CROSS_PREFIX
# below).
set -euo pipefail

CROSS_PREFIX="${CROSS_PREFIX:-riscv64-unknown-elf-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
echo "   byte-identical to I_VLE64/I_VMACC/I_VADD/I_VSE64 below) =="
"$OBJDUMP" -d "$HERE/boot_matmul.elf"

python3 "$HERE/elf2hex.py" "$HERE/boot_matmul.elf" "$HERE/boot_image.hex" \
    --cross-prefix "$CROSS_PREFIX"

echo
echo "Next steps (see plan verification section):"
echo "  1. Confirm above disassembly: x1 = 0x80001000 before vle64.v/vmacc,"
echo "     0x80002000 before the first vse64.v, 0x80003000 before the second."
echo "  2. diff $HERE/boot_image.hex against the hand-written"
echo "     ../boot_image.hex -- the 4 custom .word lines should be"
echo "     byte-identical; the li-generated address-setup instructions may"
echo "     legitimately differ in encoding (different but equally correct"
echo "     lui/addi sequence) -- that's expected, not a bug."
echo "  3. Run 4_64_Core/sim/tb_cva6_boot.v (in Vivado, as before) against"
echo "     this new boot_image.hex and confirm identical C_mul/C_add output"
echo "     to today's hand-assembled run, before attempting hardware again."
