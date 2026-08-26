#include <stdio.h>
#include "xil_io.h"

// PS7 GP0's fixed PL-facing AXI aperture on Zynq-7000.
#define GP0_BASE            0x40000000U

// axi4_bram_slave.v's widx() only decodes the LOW address bits, so
// software reads at GP0_BASE + (low bits of the real address TinyGPU
// wrote to), not the CVA6-side address (0x8000_xxxx) directly.
//   MUL_RESULT_ADDR = 0x8000_2000  (vse64.v writeback of C_mul, Option B)
//   RESULT_ADDR     = 0x8000_3000  (vse64.v writeback of C_add)
#define MUL_RESULT_OFFSET   0x2000U
#define RESULT_OFFSET       0x3000U

#define MATRIX_DIM          4
#define NUM_ELEMS           (MATRIX_DIM * MATRIX_DIM)  // 16 x 64-bit words per matrix

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
            u32 addr_lo = GP0_BASE + base_offset + idx * 8;
            u32 addr_hi = addr_lo + 4;

            u32 lo = Xil_In32(addr_lo);
            u32 hi = Xil_In32(addr_hi);
            vals[row][col] = ((unsigned long long)hi << 32) | lo;
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

    printf("\r\n---- Done ----\r\n");
    while (1) {}
    return 0;
}
