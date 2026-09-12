 * Memory map (matches sim/tb_cva6_boot.v / tb_speedup_cycles.v):
 *   0x8000_1000  A (16 dwords) + B=A dup (16 dwords), from .matrix
 *   0x8000_2000  C_mul = A x A   (offload vse64.v)
 *   0x8000_3000  C_add = A + A   (offload vse64.v)
 *   0x8000_4000  scalar  mcycle delta (1 dword)   <- new
 *   0x8000_4008  offload mcycle delta (1 dword)   <- new
 *   0x8000_5000  scalar  C_s = A x A              (RV64IM sd loop)
 */

    .section .text
    .global _start
_start:

    /* =====================================================================
     * Phase A -- scalar RV64IM baseline: C_s = A x A
     * ===================================================================== */
    li      a0, 0x80001000          /* A base (also B, since B == A) */
    li      a1, 0x80005000          /* C_s base (SCALAR_RESULT) */

    csrr    t6, 0xb00               /* mcycle -- scalar START (next mem op is the first ld) */

    li      t0, 0                   /* i = 0 */
.a_i:
    li      t1, 0                   /* j = 0 */
.a_j:
    li      t2, 0                   /* k = 0 */
    li      t3, 0                   /* acc = 0 */
.a_k:
    slli    t4, t0, 2               /* i*4 */
    add     t4, t4, t2              /* i*4 + k */
    slli    t4, t4, 3              /* (i*4+k)*8 */
    add     t4, t4, a0
    ld      t4, 0(t4)              /* A[i][k] */

    slli    t5, t2, 2              /* k*4 */
    add     t5, t5, t1             /* k*4 + j */
    slli    t5, t5, 3            /* (k*4+j)*8 */
    add     t5, t5, a0
    ld      t5, 0(t5)             /* A[k][j]  (B == A) */

    mul     t4, t4, t5
    add     t3, t3, t4            /* acc += A[i][k] * A[k][j] */

    addi    t2, t2, 1
    li      t4, 4
    bne     t2, t4, .a_k

    slli    t4, t0, 2              /* store C_s[i][j] = acc  ->  a1 + (i*4+j)*8 */
    add     t4, t4, t1
    slli    t4, t4, 3
    add     t4, t4, a1
    sd      t3, 0(t4)

    addi    t1, t1, 1
    li      t4, 4
    bne     t1, t4, .a_j

    addi    t0, t0, 1
    li      t4, 4
    bne     t0, t4, .a_i

    csrr    t5, 0xb00              /* mcycle -- scalar END (loop exited) */
    sub     t4, t5, t6            /* scalar cycle delta */
    li      t3, 0x80004000        /* SCALAR_CYC */
    sd      t4, 0(t3)

    /* =====================================================================
     * Phase B -- offload: C_mul = A x A (vmacc), C_add = A + A (vadd.vv)
     * ===================================================================== */
    li      x1, 0x80001000        /* MAT_ADDR -- issue_rs1 for vle64.v (address setup,
                                   * OUTSIDE the timed window -- mirrors the scalar
                                   * phase, whose csrr is after its li a0/a1 setup) */

    csrr    t6, 0xb00             /* mcycle -- offload START (next op is vle64.v) */

    .word   0x0020F007            /* vle64.v  vs1=1,vs2=2 -- A -> L3 line1, B(=A) -> line2 */
    .word   0xB420A057            /* vmacc    vs1=1,vs2=2 -- C_mul = A x A (funct6=0x2D) */

    li      x1, 0x80002000        /* MUL_RESULT_ADDR -- dest for C_mul, before vadd.vv */
    .word   0x0000F027            /* vse64.v  rs1=x1 -- writes C_mul */

    .word   0x002081D7            /* vadd.vv  vs1=1,vs2=2 -- C_add = A + A (OPIVV, funct6=0x00) */

    li      x1, 0x80003000        /* RESULT_ADDR -- dest for C_add */
    .word   0x0000F027            /* vse64.v  rs1=x1 -- writes C_add */

    csrr    t5, 0xb00             /* mcycle -- offload END (right after the last
                                    * vse64.v -- no poll, see header comment: never
                                    * have CVA6 read back a TinyGPU-written address) */
    sub     t4, t5, t6           /* offload cycle delta */
    li      t3, 0x80004008       /* OFFLOAD_CYC */
    sd      t4, 0(t3)

park:
    jal     x0, park              /* infinite self-loop, park the core */

    /*
     * Matrix A at MAT_ADDR (0x8000_1000), followed immediately by B = A
     * (same 16 dwords) -- vle64.v's custom lumop-as-"second matrix"
     * encoding loads both from one contiguous 32-word region (see
     * tingpu_decoder.v). Values match sim/tb_cva6_boot.v's D_A00..D_A33:
     * rows of [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]].
     */
    .section .matrix, "a"
    .align 3
matrix_a:
    .dword 1,  2,  3,  4
    .dword 5,  6,  7,  8
    .dword 9,  10, 11, 12
    .dword 13, 14, 15, 16
matrix_b_dup:
    .dword 1,  2,  3,  4
    .dword 5,  6,  7,  8
    .dword 9,  10, 11, 12
    .dword 13, 14, 15, 16
