/*
 * boot_matmul.S -- real-toolchain replacement for the hand-assembled
 * Option B boot program (lui/slli/srli/vle64/vmacc/vadd.vv/vse64.v/jal)
 * currently hand-encoded in final_v1/sim/tb_cva6_boot.v and
 * final_v1/boot_image.hex.
 *
 * Assembled by a real RISC-V toolchain (see build.sh) with
 * -march=rv64im -mabi=lp64 -- DELIBERATELY NO 'v' IN -march. TinyGPU's
 * decoder does not implement real RVV vector-register/vtype semantics
 * (vs1/vs2/vd fields here are matrix/cache-line IDs, not real per-lane
 * vector registers governed by vtype/vl) -- letting a compiler
 * auto-vectorize anything, or emit a real vsetvli-driven vector body,
 * would silently compute the wrong thing even after the tinygpu_fsm.v
 * is_vec_arith/funct3 fix (that fix only makes an accidental vsetvli
 * trap safely instead of corrupting state -- it does not make real RVV
 * codegen correct on this hardware). Do not change -march to include
 * 'v' without re-deriving TinyGPU's decoder/FSM to match real RVV
 * vector-register semantics first.
 *
 * The 4 custom instructions (vle64.v / vmacc / vadd.vv / vse64.v) are
 * emitted verbatim as .word literals, byte-identical to the hand-derived
 * encodings in tb_cva6_boot.v (I_VLE64/I_VMACC/I_VADD/I_VSE64) -- these
 * are the one part of the current design already confirmed to match real
 * RVV 1.0 opcode/funct3/funct6 fields, so there is no new encoding risk
 * here, only a new toolchain producing the surrounding scalar glue
 * (address setup, jal) instead of by hand.
 *
 * Address setup (x1) uses the assembler's own `li` pseudo-op instead of
 * hand-written lui/slli/srli -- `li` is a well-tested, 64-bit-aware
 * pseudo-instruction that handles the same sign-extend concern the
 * hand-written idiom worked around (lui sign-extends since bit 31 is set
 * for every address used here, 0x8000_xxxx). Its actual instruction
 * encoding may legitimately differ from the hand-written
 * lui/slli/srli sequence (e.g. lui+addi/addiw) while producing the
 * identical 64-bit value in x1 -- verify via `objdump -d` that x1 holds
 * the correct address before each vector-space instruction, rather than
 * expecting byte-identical encoding to the old hand-assembled sequence.
 */

    .section .text
    .global _start
_start:
    /* ---- vmacc: C_mul = A x A ---- */
    li      x1, 0x80001000            /* MAT_ADDR -- real GPR read by CVA6, passed as issue_rs1 */
    .word   0x0020F007                 /* vle64.v  vs1=1,vs2=2 -- load A into L3 line1, B(=A) into line2 */
    .word   0xB420A057                 /* vmacc    vs1=1,vs2=2 -- C_mul = A x A (custom opcode 1010111, funct6=0x2D) */

    li      x1, 0x80002000            /* MUL_RESULT_ADDR -- writeback dest for C_mul, BEFORE vadd.vv overwrites vd_* */
    .word   0x0000F027                 /* vse64.v  rs1=x1 -- writes C_mul */

    /* ---- vadd.vv: C_add = A + A ---- */
    .word   0x002081D7                 /* vadd.vv  vs1=1,vs2=2 (real RVV encoding: opcode 1010111, funct3=000/OPIVV, funct6=0x00) */

    li      x1, 0x80003000            /* RESULT_ADDR -- writeback dest for C_add */
    .word   0x0000F027                 /* vse64.v  rs1=x1 -- writes C_add */

park:
    jal     x0, park                   /* infinite self-loop, park the core once done */

    /*
     * Matrix A, placed by link.ld at MAT_ADDR (0x8000_1000). Matrix B is
     * the same 16 words repeated immediately after (vle64.v's custom
     * lumop-as-"second matrix" encoding loads both from one contiguous
     * 32-word region, see tingpu_decoder.v) -- real hardware values match
     * final_v1/sim/tb_cva6_boot.v's D_A00..D_A33 (rows of
     * [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]]).
     */
    .section .matrix, "a"
    .align 3
matrix_a:
    .dword 1,  2,  3,  4
    .dword 5,  6,  7,  8
    .dword 9,  10, 11, 12
    .dword 13, 14, 15, 16
matrix_b_dup:                          /* B = A, duplicated for the vle64.v dual-line load */
    .dword 1,  2,  3,  4
    .dword 5,  6,  7,  8
    .dword 9,  10, 11, 12
    .dword 13, 14, 15, 16
