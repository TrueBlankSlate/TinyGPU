`timescale 1ns / 1ps

//VERY IMPORTANT: in tcl console: run 4000ns minimum. CVA6 boot takes 3345ns


// Full-pipeline boot test: real CVA6 fetches a real boot program from a
// behavioral AXI4 memory, hits the illegal-instruction->CVXIF offload path
// for real, and drives cva6_sv_shim.sv's actual struct-packed ports.
//
// Both CVA6's own fetch/load-store traffic AND TinyGPU's vle64 loads now
// share ONE arbitrated AXI4 bus (noc_*, 5-bit ID -- axi_mux inside
// cva6_sv_shim.sv widens CVA6Cfg.AxiIdWidth=4 by 1 bit to disambiguate the
// two masters). One axi4_mem_slave instance services both, same as a real
// DRAM controller would -- there is no separate GPU memory port anymore.
//
// Boot program (at BOOT_ADDR = 0x8000_0000). This testbench acts as the
// last stage of a toolchain (assembler + linker): the localparams below
// (I_LUI, I_SLLI, ...) are plain pre-encoded 32-bit machine words -- the
// same thing `objdump -d` would print, or what a real assembler would hand
// off -- not built up from field concatenation in RTL. No toolchain is
// actually invoked; the encodings were derived by hand once and are held
// fixed as literals from here on:
//   lui   x1, 0x80001     x1 = 0xFFFFFFFF80001000 (RV64 lui sign-extends
//                          since imm bit31 is set here)
//   slli  x1, x1, 32      x1 = 0x8000100000000000
//   srli  x1, x1, 32      x1 = 0x0000000080001000 (matrix base addr,
//                          zero-extend idiom -- standard RV64 pattern for
//                          loading a 32-bit constant with bit31 set)
//   vle64.v (vs1=1,vs2=2)  load A into L3 line1, B(=A) into line2
//   vmacc   (vs1=1,vs2=2)  C_mul = A x A
//   vadd.vv (vs1=1,vs2=2)  C_add = A + A (same original A/B lines, no reload)
//   lui/slli/srli (x1)     x1 = 0x0000000080003000 (RESULT_ADDR, writeback dest)
//   vse64.v (rs1=1)        write C_add (the last compute result) out to
//                          RESULT_ADDR over TinyGPU's own AXI4 write master
//                          (see tinygpu_fsm.v's WRITEBACK state, writeback.v)
//   jal   x0, 0            infinite self-loop (park the core)
//
// BOOT_ADDR/MAT_ADDR deliberately sit inside CVA6Cfg.CachedRegionAddrBase/
// Length (0x8000_0000, length 0x40000000 -- see cv64a6_imafdc_sv39_config_
// pkg.sv). Addresses outside that region hit cva6_icache.sv's non-cacheable
// bypass path, which behaves differently from the normal cache-line-fill
// path our AXI4 slave models.
//
// Matrix data preloaded directly into memory at MAT_ADDR = 0x8000_1000:
//   A = [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]], B = A (same bytes
//   repeated), matching the same C = A x A used in tb_matmul.v so results
//   are directly comparable.
//
// vd_<i>_<j> = C[i][j] (i=row, j=col) uniformly for every op, vmacc
// included. cache_l3.v's non-vmacc branch used to give each "core" a full
// ROW of both A and B (making vd_i_j transposed relative to vmacc's own
// convention there); it was changed to give each core a COLUMN of both A
// and B instead -- the same transpose-read vmacc already used for B --
// so "core N" means the same thing (column N) regardless of op.
module tb_cva6_boot;

  localparam [63:0] BOOT_ADDR    = 64'h0000_0000_8000_0000;
  localparam [63:0] MAT_ADDR     = 64'h0000_0000_8000_1000;

  localparam [63:0] MUL_RESULT_ADDR = 64'h0000_0000_8000_2000; // vse64.v writeback dest for C_mul (NEW)
  localparam [63:0] RESULT_ADDR  = 64'h0000_0000_8000_3000; // vse64.v writeback destination for C_add

  reg clk = 0;
  reg rst_ni = 0;
  always #5 clk = ~clk; // 100 MHz

  // ---- NOC/AXI4 -- ONE shared, arbitrated bus. ID is 5 bits now
  // (CVA6Cfg.AxiIdWidth=4 + 1 bit axi_mux adds for 2 masters). ----
  wire [4:0]  noc_aw_id;   wire [63:0] noc_aw_addr; wire [7:0] noc_aw_len;
  wire [2:0]  noc_aw_size; wire [1:0]  noc_aw_burst;wire       noc_aw_lock;
  wire [3:0]  noc_aw_cache;wire [2:0]  noc_aw_prot; wire [3:0] noc_aw_qos;
  wire [3:0]  noc_aw_region;wire [5:0] noc_aw_atop; wire [63:0]noc_aw_user;
  wire        noc_aw_valid; wire       noc_aw_ready;

  wire [4:0]  noc_ar_id;   wire [63:0] noc_ar_addr; wire [7:0] noc_ar_len;
  wire [2:0]  noc_ar_size; wire [1:0]  noc_ar_burst;wire       noc_ar_lock;
  wire [3:0]  noc_ar_cache;wire [2:0]  noc_ar_prot; wire [3:0] noc_ar_qos;
  wire [3:0]  noc_ar_region;wire [63:0]noc_ar_user;
  wire        noc_ar_valid; wire       noc_ar_ready;

  wire [63:0] noc_w_data;  wire [7:0]  noc_w_strb;  wire       noc_w_last;
  wire [63:0] noc_w_user;  wire        noc_w_valid; wire       noc_w_ready;

  wire [4:0]  noc_b_id;    wire [1:0]  noc_b_resp;  wire [63:0]noc_b_user;
  wire        noc_b_valid; wire        noc_b_ready;

  wire [4:0]  noc_r_id;    wire [63:0] noc_r_data;  wire [1:0] noc_r_resp;
  wire        noc_r_last;  wire [63:0] noc_r_user;
  wire        noc_r_valid; wire        noc_r_ready;

  cva6_tinygpu_soc dut (
    .clk        (clk),
    .rst_ni     (rst_ni),
    .boot_addr  (BOOT_ADDR),
    .hart_id    (64'd0),
    .irq        (2'b00),
    .ipi        (1'b0),
    .time_irq   (1'b0),
    .debug_req  (1'b0),

    .noc_aw_id(noc_aw_id), .noc_aw_addr(noc_aw_addr), .noc_aw_len(noc_aw_len),
    .noc_aw_size(noc_aw_size), .noc_aw_burst(noc_aw_burst), .noc_aw_lock(noc_aw_lock),
    .noc_aw_cache(noc_aw_cache), .noc_aw_prot(noc_aw_prot), .noc_aw_qos(noc_aw_qos),
    .noc_aw_region(noc_aw_region), .noc_aw_atop(noc_aw_atop), .noc_aw_user(noc_aw_user),
    .noc_aw_valid(noc_aw_valid), .noc_aw_ready(noc_aw_ready),

    .noc_ar_id(noc_ar_id), .noc_ar_addr(noc_ar_addr), .noc_ar_len(noc_ar_len),
    .noc_ar_size(noc_ar_size), .noc_ar_burst(noc_ar_burst), .noc_ar_lock(noc_ar_lock),
    .noc_ar_cache(noc_ar_cache), .noc_ar_prot(noc_ar_prot), .noc_ar_qos(noc_ar_qos),
    .noc_ar_region(noc_ar_region), .noc_ar_user(noc_ar_user),
    .noc_ar_valid(noc_ar_valid), .noc_ar_ready(noc_ar_ready),

    .noc_w_data(noc_w_data), .noc_w_strb(noc_w_strb), .noc_w_last(noc_w_last),
    .noc_w_user(noc_w_user), .noc_w_valid(noc_w_valid), .noc_w_ready(noc_w_ready),

    .noc_b_id(noc_b_id), .noc_b_resp(noc_b_resp), .noc_b_user(noc_b_user),
    .noc_b_valid(noc_b_valid), .noc_b_ready(noc_b_ready),

    .noc_r_id(noc_r_id), .noc_r_data(noc_r_data), .noc_r_resp(noc_r_resp),
    .noc_r_last(noc_r_last), .noc_r_user(noc_r_user),
    .noc_r_valid(noc_r_valid), .noc_r_ready(noc_r_ready)
  );

  // ---- ONE real AXI4 slave services BOTH CVA6's own traffic and
  // TinyGPU's arbitrated vle64 loads, same as a real DRAM controller
  // would see one arbitrated bus, not two separate masters. ----
  axi4_mem_slave #(.ID_WIDTH(5), .ADDR_WIDTH(64), .DATA_WIDTH(64)) u_noc_mem (
    .clk(clk), .rst_ni(rst_ni),
    .ar_id(noc_ar_id), .ar_addr(noc_ar_addr), .ar_len(noc_ar_len),
    .ar_valid(noc_ar_valid), .ar_ready(noc_ar_ready),
    .r_id(noc_r_id), .r_data(noc_r_data), .r_resp(noc_r_resp),
    .r_last(noc_r_last), .r_valid(noc_r_valid), .r_ready(noc_r_ready),
    .aw_id(noc_aw_id), .aw_addr(noc_aw_addr),
    .aw_valid(noc_aw_valid), .aw_ready(noc_aw_ready),
    .w_data(noc_w_data), .w_strb(noc_w_strb), .w_last(noc_w_last),
    .w_valid(noc_w_valid), .w_ready(noc_w_ready),
    .b_id(noc_b_id), .b_resp(noc_b_resp), .b_valid(noc_b_valid), .b_ready(noc_b_ready)
  );

  localparam [31:0] I_LUI   = 32'h800010B7; // lui   x1, 0x80001      -> x1 = 0xFFFFFFFF80001000 (RV64 lui sign-extends since imm bit31 is set)
  localparam [31:0] I_SLLI  = 32'h02009093; // slli  x1, x1, 32       -> x1 = 0x8000100000000000
  localparam [31:0] I_SRLI  = 32'h0200D093; // srli  x1, x1, 32       -> x1 = 0x0000000080001000 (zero-extend idiom, real matrix base addr)
  localparam [31:0] I_VLE64 = 32'h0020F007; // vle64.v vs1=1, vs2=2   (custom opcode 0000111, funct3=111 width tag) -- load A into L3 line1, B(=A) into line2
  localparam [31:0] I_VMACC = 32'hB420A057; // vmacc   vs1=1, vs2=2   (custom opcode 1010111, funct6=0x2D)          -- C_mul = A x A
  localparam [31:0] I_VADD  = 32'h002081D7; // vadd.vv vs1=1, vs2=2   (real RVV encoding: opcode 1010111, funct3=000/OPIVV, funct6=0x00) -- C_add = A + A
  localparam [31:0] I_LUI_MUL = 32'h800020B7; // lui x1, 0x80002      -> x1 = 0xFFFFFFFF80002000 (NEW: MUL_RESULT_ADDR, same sign-extend pattern as I_LUI/I_LUI2)
  localparam [31:0] I_LUI2  = 32'h800030B7; // lui   x1, 0x80003      -> x1 = 0xFFFFFFFF80003000 (writeback dest addr, same sign-extend situation as I_LUI)
  localparam [31:0] I_VSE64 = 32'h0000F027; // vse64.v rs1=1          (real RVV store opcode 0100111, funct3=111 width tag) -- writes the last compute result (C_add) to x1 = RESULT_ADDR
  localparam [31:0] I_JAL   = 32'h0000006F; // jal   x0, 0             infinite self-loop (park the core once done)
  localparam [31:0] I_NOP   = 32'h00000013; // addi  x0, x0, 0         real RV64I nop, pad word only, never reached

  localparam [63:0] D_A00 = 64'd1,  D_A01 = 64'd2,  D_A02 = 64'd3,  D_A03 = 64'd4;
  localparam [63:0] D_A10 = 64'd5,  D_A11 = 64'd6,  D_A12 = 64'd7,  D_A13 = 64'd8;
  localparam [63:0] D_A20 = 64'd9,  D_A21 = 64'd10, D_A22 = 64'd11, D_A23 = 64'd12;
  localparam [63:0] D_A30 = 64'd13, D_A31 = 64'd14, D_A32 = 64'd15, D_A33 = 64'd16;

  reg [63:0] c_mul [0:3][0:3];
  reg [63:0] c_add [0:3][0:3];

  initial begin
    // BOOT_ADDR is 16B-aligned -> all 16 instructions/pad words land in 8
    // consecutive 64-bit words (2 x 32-bit instrs/word, little-endian word
    // pairing).
    u_noc_mem.mem[u_noc_mem.widx(BOOT_ADDR)]   = {I_SLLI,    I_LUI};    // +0x00 lui,      +0x04 slli
    u_noc_mem.mem[u_noc_mem.widx(BOOT_ADDR)+1] = {I_VLE64,   I_SRLI};   // +0x08 srli,     +0x0c vle64
    u_noc_mem.mem[u_noc_mem.widx(BOOT_ADDR)+2] = {I_LUI_MUL, I_VMACC};  // +0x10 vmacc,    +0x14 lui_mul (NEW)
    u_noc_mem.mem[u_noc_mem.widx(BOOT_ADDR)+3] = {I_SRLI,    I_SLLI};   // +0x18 slli,     +0x1c srli (NEW, reused ops)
    u_noc_mem.mem[u_noc_mem.widx(BOOT_ADDR)+4] = {I_VADD,    I_VSE64};  // +0x20 vse64.v (writes C_mul, NEW), +0x24 vadd.vv
    u_noc_mem.mem[u_noc_mem.widx(BOOT_ADDR)+5] = {I_SLLI,    I_LUI2};   // +0x28 lui2,     +0x2c slli (reused)
    u_noc_mem.mem[u_noc_mem.widx(BOOT_ADDR)+6] = {I_VSE64,   I_SRLI};   // +0x30 srli (reused), +0x34 vse64.v (writes C_add)
    u_noc_mem.mem[u_noc_mem.widx(BOOT_ADDR)+7] = {I_NOP,     I_JAL};    // +0x38 jal (self-loop), +0x3c nop (unreachable pad)

    // Matrix A at words [MAT_ADDR+0 .. +15]; matrix B is the same 16 words
    // repeated at [MAT_ADDR+16 .. +31].
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+0]  = D_A00;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+1]  = D_A01;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+2]  = D_A02;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+3]  = D_A03;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+4]  = D_A10;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+5]  = D_A11;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+6]  = D_A12;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+7]  = D_A13;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+8]  = D_A20;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+9]  = D_A21;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+10] = D_A22;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+11] = D_A23;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+12] = D_A30;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+13] = D_A31;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+14] = D_A32;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+15] = D_A33;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+16] = D_A00;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+17] = D_A01;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+18] = D_A02;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+19] = D_A03;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+20] = D_A10;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+21] = D_A11;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+22] = D_A12;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+23] = D_A13;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+24] = D_A20;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+25] = D_A21;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+26] = D_A22;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+27] = D_A23;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+28] = D_A30;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+29] = D_A31;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+30] = D_A32;
    u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR)+31] = D_A33;

    rst_ni = 1'b0;
    repeat (10) @(posedge clk);
    rst_ni = 1'b1;

    $display("[%0t] Reset released, CVA6 booting from 0x%h", $time, BOOT_ADDR);

    // ---- vmacc: poll for C_mul[0][0] landing in the GPU's output
    // registers. vd_0_0 starts at 0 and becomes 90 once it lands.
    // Clocked polling loop instead of `wait (...)` -- a bare `wait` on a
    // cross-hierarchy dotted reference relies on the simulator building a
    // correct implicit sensitivity list across module scopes, which this
    // XSim environment has already shown to be unreliable for signals deep
    // inside optimized instances (see the `get_objects -r` failures earlier
    // in this bring-up). An explicit @(posedge clk) poll has no such
    // dependency and behaves identically across simulators.
    while (dut.u_gpu.vd_0_0 !== 64'd90) @(posedge clk);
    $display("[%0t] vd_0_0 == 90 -- vmacc appears to have completed.", $time);

    // Snapshot immediately -- CVA6 can issue and finish vadd.vv (only a
    // handful of cycles once TinyGPU is idle) faster than any fixed delay
    // here, so anything read later than THIS instant risks reading
    // vadd.vv's result instead of vmacc's.
    c_mul[0][0]=dut.u_gpu.vd_0_0; c_mul[0][1]=dut.u_gpu.vd_0_1; c_mul[0][2]=dut.u_gpu.vd_0_2; c_mul[0][3]=dut.u_gpu.vd_0_3;
    c_mul[1][0]=dut.u_gpu.vd_1_0; c_mul[1][1]=dut.u_gpu.vd_1_1; c_mul[1][2]=dut.u_gpu.vd_1_2; c_mul[1][3]=dut.u_gpu.vd_1_3;
    c_mul[2][0]=dut.u_gpu.vd_2_0; c_mul[2][1]=dut.u_gpu.vd_2_1; c_mul[2][2]=dut.u_gpu.vd_2_2; c_mul[2][3]=dut.u_gpu.vd_2_3;
    c_mul[3][0]=dut.u_gpu.vd_3_0; c_mul[3][1]=dut.u_gpu.vd_3_1; c_mul[3][2]=dut.u_gpu.vd_3_2; c_mul[3][3]=dut.u_gpu.vd_3_3;

    $display("vmacc result C_mul (vd_<row>_<col> = C_mul[row][col]):");
    $display("  %0d %0d %0d %0d", c_mul[0][0], c_mul[0][1], c_mul[0][2], c_mul[0][3]);
    $display("  %0d %0d %0d %0d", c_mul[1][0], c_mul[1][1], c_mul[1][2], c_mul[1][3]);
    $display("  %0d %0d %0d %0d", c_mul[2][0], c_mul[2][1], c_mul[2][2], c_mul[2][3]);
    $display("  %0d %0d %0d %0d", c_mul[3][0], c_mul[3][1], c_mul[3][2], c_mul[3][3]);

    // ---- vadd.vv: poll for C_add[0][0] landing. Different expected value
    // (2, not 90) so we can tell it apart from vmacc's leftover result on
    // the same wires. CVA6 won't even issue vadd.vv until TinyGPU returns
    // to IDLE after vmacc (issue_ready enforces that -- see cva6_sv_shim.sv),
    // so no extra synchronization is needed here beyond the poll itself.
    while (dut.u_gpu.vd_0_0 !== 64'd2) @(posedge clk);
    $display("[%0t] vd_0_0 == 2 -- vadd.vv appears to have completed.", $time);

    c_add[0][0]=dut.u_gpu.vd_0_0; c_add[0][1]=dut.u_gpu.vd_0_1; c_add[0][2]=dut.u_gpu.vd_0_2; c_add[0][3]=dut.u_gpu.vd_0_3;
    c_add[1][0]=dut.u_gpu.vd_1_0; c_add[1][1]=dut.u_gpu.vd_1_1; c_add[1][2]=dut.u_gpu.vd_1_2; c_add[1][3]=dut.u_gpu.vd_1_3;
    c_add[2][0]=dut.u_gpu.vd_2_0; c_add[2][1]=dut.u_gpu.vd_2_1; c_add[2][2]=dut.u_gpu.vd_2_2; c_add[2][3]=dut.u_gpu.vd_2_3;
    c_add[3][0]=dut.u_gpu.vd_3_0; c_add[3][1]=dut.u_gpu.vd_3_1; c_add[3][2]=dut.u_gpu.vd_3_2; c_add[3][3]=dut.u_gpu.vd_3_3;

    // vd_i_j = C_add[i][j] uniformly now (cache_l3.v's non-vmacc branch was
    // fixed to give each core a COLUMN of both A and B, matching vmacc's
    // convention) -- same straightforward reading as the vmacc block above.
    $display("vadd.vv result C_add (vd_<row>_<col> = C_add[row][col]):");
    $display("  %0d %0d %0d %0d", c_add[0][0], c_add[0][1], c_add[0][2], c_add[0][3]);
    $display("  %0d %0d %0d %0d", c_add[1][0], c_add[1][1], c_add[1][2], c_add[1][3]);
    $display("  %0d %0d %0d %0d", c_add[2][0], c_add[2][1], c_add[2][2], c_add[2][3]);
    $display("  %0d %0d %0d %0d", c_add[3][0], c_add[3][1], c_add[3][2], c_add[3][3]);

    // ---- OPTION B FIX: C_mul's own vse64.v ran BEFORE vadd.vv in program
    // order (see the instruction packing above), so by the time we've
    // already confirmed vadd.vv completed (the vd_0_0==2 poll above), this
    // write is long done -- no extra synchronization needed, just read it.
    // Expected: C_mul[3][3] = 13*4 + 14*8 + 15*12 + 16*16 = 600 (row3 of A
    // dot column3 of B=A), the same in-order-write-completion logic as the
    // RESULT_ADDR check below applied to word +15.
    while (u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+15] !== 64'd600) @(posedge clk);
    $display("[%0t] MUL_RESULT_ADDR+15 == 600 -- vmacc's vse64.v writeback appears to have completed.", $time);

    $display("Writeback contents at MUL_RESULT_ADDR (read directly out of DRAM, vd_<row>_<col> = C_mul[row][col]):");
    $display("  %0d %0d %0d %0d",
        u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+0], u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+1],
        u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+2], u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+3]);
    $display("  %0d %0d %0d %0d",
        u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+4], u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+5],
        u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+6], u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+7]);
    $display("  %0d %0d %0d %0d",
        u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+8], u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+9],
        u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+10], u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+11]);
    $display("  %0d %0d %0d %0d",
        u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+12], u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+13],
        u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+14], u_noc_mem.mem[u_noc_mem.widx(MUL_RESULT_ADDR)+15]);

    // ---- vse64.v: real CVA6 issues the store, TinyGPU streams C_add out
    // over its OWN AXI4 write master (tinygpu_fsm.v's WRITEBACK state) to
    // RESULT_ADDR. Poll the memory model directly, not any internal GPU
    // signal -- this is the same check real DRAM contents would get on an
    // actual board, and it's a clean way to know the whole 16-beat burst
    // landed: AXI4 writes are strictly in-order, so once the LAST element
    // (word +15, C_add[3][3]=32) shows its final value, every earlier word
    // in the burst is already there too.
    while (u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+15] !== 64'd32) @(posedge clk);
    $display("[%0t] RESULT_ADDR+15 == 32 -- vse64.v writeback appears to have completed.", $time);

    $display("Writeback contents at RESULT_ADDR (read directly out of DRAM, vd_<row>_<col> = C_add[row][col]):");
    $display("  %0d %0d %0d %0d",
        u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+0], u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+1],
        u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+2], u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+3]);
    $display("  %0d %0d %0d %0d",
        u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+4], u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+5],
        u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+6], u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+7]);
    $display("  %0d %0d %0d %0d",
        u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+8], u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+9],
        u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+10], u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+11]);
    $display("  %0d %0d %0d %0d",
        u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+12], u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+13],
        u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+14], u_noc_mem.mem[u_noc_mem.widx(RESULT_ADDR)+15]);

    repeat (20) @(posedge clk);
    $finish;
  end

  initial begin
    #200000;
    $display("[%0t] TIMEOUT -- matmul never completed. Check whether CVA6 ever", $time);
    $display("issued the coprocessor instructions (look at u_gpu.fsm_i.state,");
    $display("issue_valid/issue_accept, and noc_ar_valid/noc_r_valid activity).");
    $finish;
  end

endmodule
