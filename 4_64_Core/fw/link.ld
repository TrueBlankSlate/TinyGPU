/*
 * link.ld -- places boot_matmul.S's .text at BOOT_ADDR (0x8000_0000, the
 * address CVA6 boots from -- must stay inside CVA6Cfg.CachedRegionAddrBase
 * /Length, see tb_cva6_boot.v) and .matrix at MAT_ADDR (0x8000_1000),
 * matching final_v1's memory map exactly. No .data/.bss/.rodata sections
 * are used beyond .matrix -- this is a single straight-line boot program
 * with no runtime-writable state of its own (MUL_RESULT_ADDR/RESULT_ADDR
 * are write-only destinations for TinyGPU's own AXI writeback burst, not
 * ELF sections -- deliberately left out of this linker script so they
 * stay zero in the generated hex until written at runtime, exactly as
 * boot_image.hex's comments describe for those two addresses today).
 */

ENTRY(_start)

MEMORY
{
    BOOT   (rx)  : ORIGIN = 0x80000000, LENGTH = 0x1000
    MATRIX (rw)  : ORIGIN = 0x80001000, LENGTH = 0x1000
}

SECTIONS
{
    .text : { *(.text) } > BOOT
    .matrix : { *(.matrix) } > MATRIX

    /DISCARD/ : { *(.comment) *(.riscv.attributes) *(.eh_frame) }
}
