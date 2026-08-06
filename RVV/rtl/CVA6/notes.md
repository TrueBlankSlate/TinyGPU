# cva6 
cva6 implements 64-bit RISCV instruction set.
It has a configurable size, separate TLBs, a hardware PTW and <mark> branch-prediction </mark>(branch target buffer and branch history table).


CVA6 is a RISC-V compatible application processor core that can be configured as a 32- or 64-bit core (RV32 or RV64). It includes L1 caches, optional MMU, optional PMP and optional FPU.
(Source: https://docs.openhwgroup.org/projects/cva6-user-manual/02_cva6_requirements/cva6_requirements_specification.html)

# Ara
Ara is a modular, open-source vector processing unit designed to augment RISC-V processors 

### 1. Dispatcher 
Ara also has it's own dispatcher. Why did shri say we dont need a decoder?
(Source: https://pulp-platform.github.io/ara/modules/ara_dispatcher.html)

The decoding is done inside it's input:
acc_req_i -> struct -> Incoming request from scalar core
(file name: dispatcher.sv in ara repo/hardware/src)

the sturct looks like this:
/* typedef struct packed {
    logic        valid;        // Request is valid
    logic [31:0] insn;         // Entire 32-bit RVV instruction

    logic [63:0] rs1;          // Value of scalar register rs1
    logic [63:0] rs2;          // Value of scalar register rs2

    logic [4:0]  rd;           // Scalar destination register
    logic [31:0] trans_id;     // Transaction ID

    logic        store_pending;
    logic        load_pending;

    ...
} accelerator_req_t;
*/

<mark> RVV compiler support has been developed primarily for RV64 targets. </mark>