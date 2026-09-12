#include <stdio.h>
#include "xil_io.h"

// PS7 GP0's fixed PL-facing AXI aperture on Zynq-7000.
#define GP0_BASE            0x40000000U

// axi4_bram_slave.v's widx() only decodes the LOW address bits, so
// software reads at GP0_BASE + (low bits of the real address TinyGPU /
// CVA6 wrote to), not the CVA6-side address (0x8000_xxxx) directly.
//   MUL_RESULT_ADDR = 0x8000_2000  (vse64.v writeback of C_mul, Option B)
//   RESULT_ADDR     = 0x8000_3000  (vse64.v writeback of C_add)
//   SCALAR_CYC_ADDR = 0x8000_4000  (bench_matmul.S: scalar  mcycle delta)
//   OFFLOAD_CYC_ADDR= 0x8000_4008  (bench_matmul.S: offload mcycle delta)
//   SCALAR_RESULT   = 0x8000_5000  (bench_matmul.S: scalar C_s = A x A)
#define MUL_RESULT_OFFSET   0x2000U
#define RESULT_OFFSET       0x3000U
#define SCALAR_CYC_OFFSET   0x4000U
#define OFFLOAD_CYC_OFFSET  0x4008U

// FPGA fabric clock (FCLK_CLK0) in MHz -- README block-design section.
// mcycle counts this clock; change this if the PS7 preset's FCLK changes.
#define FCLK_MHZ            25.0

#define MATRIX_DIM          4
#define NUM_ELEMS           (MATRIX_DIM * MATRIX_DIM)  // 16 x 64-bit words per matrix

// Reads one 64-bit word out of the GP0 aperture at (GP0_BASE + offset).
static unsigned long long read_u64(u32 offset)
{
    u32 lo = Xil_In32(GP0_BASE + offset);
    u32 hi = Xil_In32(GP0_BASE + offset + 4);
    return ((unsigned long long)hi << 32) | lo;
}

// Reads one 4x4 matrix of 64-bit elements out of the GP0 aperture at
// (GP0_BASE + base_offset) and prints it as a bracketed grid, e.g.:
//   [  90  100  110  120 ]
//   [ 202  228  254  280 ]
//   [ 314  356  398  440 ]
//   [ 426  484  542  600 ]
static void print_matrix(const char *label, u32 base_offset)
{
    unsigned long long vals[MATRIX_DIM][MATRIX_DIM];

    for (int row = 0; row < MATRIX_DIM; row++) {
        for (int col = 0; col < MATRIX_DIM; col++) {
            int idx = row * MATRIX_DIM + col;
            vals[row][col] = read_u64(base_offset + idx * 8);
        }
    }

    printf("\r\n%s:\r\n", label);
    for (int row = 0; row < MATRIX_DIM; row++) {
        printf("[");
        for (int col = 0; col < MATRIX_DIM; col++) {
            printf(" %4llu", vals[row][col]);
        }
        printf(" ]\r\n");
    }
}

int main()
{
    printf("\r\n---- TinyGPU matmul + vadd readout (A = [[1..4],[5..8],[9..12],[13..16]]) ----\r\n");

    print_matrix("C_mul = A x A (vmacc)", MUL_RESULT_OFFSET);
    print_matrix("C_add = A + A (vadd.vv)", RESULT_OFFSET);

    // ---- Benchmark readout (only meaningful when booted from bench_image.hex,
    // i.e. fw/build.sh bench -- boot_image.hex never writes these words, so
    // they read 0 and we skip the math). ----
    unsigned long long scalar_cyc  = read_u64(SCALAR_CYC_OFFSET);
    unsigned long long offload_cyc = read_u64(OFFLOAD_CYC_OFFSET);

    printf("\r\n---- Benchmark (mcycle, CVA6 FCLK domain) ----\r\n");
    if (scalar_cyc == 0 || offload_cyc == 0) {
        printf("benchmark firmware not loaded -- boot with bench_image.hex\r\n");
        printf("(fw/build.sh bench), not boot_image.hex.\r\n");
    } else {
        double speedup   = (double)scalar_cyc / (double)offload_cyc;
        double scalar_us  = (double)scalar_cyc  / FCLK_MHZ;
        double offload_us = (double)offload_cyc / FCLK_MHZ;
        printf("scalar  (CVA6 RV64IM, first ld -> last add)                : %llu cycles\r\n", scalar_cyc);
        printf("offload (TinyGPU vmacc+vadd, issue -> last vse64.v commit) : %llu cycles\r\n", offload_cyc);
        printf("  (offload excludes the AXI writeback burst actually landing --\r\n");
        printf("   see fw/bench_matmul.S's header comment for why it can't be polled)\r\n");
        printf("speedup : %.2fx\r\n", speedup);
        printf("@ %.0f MHz FCLK_CLK0 : scalar %.2f us, offload %.2f us\r\n",
               FCLK_MHZ, scalar_us, offload_us);
    }

    printf("\r\n---- Done ----\r\n");
    while (1) {}
    return 0;
}
