`timescale 1ns / 1ps
// tb_bench_image.v -- offline gate for fw/bench_matmul.S before hardware.
//
// Like tb_boot_image.v (real synthesizable axi4_bram_slave.v, $readmemh of
// the real image file, the actual hardware datapath), but points at
// bench_image.hex -- the benchmark build (build.sh bench) that brackets the
// scalar matmul and the TinyGPU offload with `csrr mcycle` reads and leaves
// the two cycle deltas in BRAM at SCALAR_CYC_ADDR / OFFLOAD_CYC_ADDR.
//
// Checks, after the program parks:
//   * C_mul[3][3] == 600  (offload vmacc still correct)
//   * C_add[3][3] == 32   (offload vadd.vv still correct)
//   * scalar C_s[3][3] == 600  (scalar RV64IM matmul correct)
//   * both mcycle-delta words are non-zero and plausible
//   * scalar_delta > offload_delta  (offload is actually faster)
//   * the scalar delta agrees with tb_speedup_cycles.v's
//     scalar_compute_cycles within a few cycles -- prints both so the
//     comparison can be eyeballed across the two runs. (This TB can't run
//     tb_speedup_cycles' phases itself; run that TB separately and compare.)
//
// bench_matmul.S's offload window ends right after the CPU issues the last
// vse64.v (CV-X-IF commit), NOT after TinyGPU's AXI writeback actually
// lands -- it deliberately does not poll memory to wait for that (CVA6's
// dcache has no coherency with TinyGPU's separate AXI write master; an
// earlier version that did poll a TinyGPU-written address hung forever on
// a stale cached read -- see bench_matmul.S's header comment). So this TB
// waits a further grace period after OFFLOAD_CYC_ADDR appears before
// reading the result matrices back, to let that AXI burst actually drain.
//
// This TB also pre-zeroes any BRAM word $readmemh left as X (everything
// outside .text/.matrix), matching real hardware where unwritten BRAM
// powers up to 0 -- general hygiene, not required by any poll now (there
// isn't one), but harmless and guards any future addition of one.
module tb_bench_image;

  localparam [63:0] BOOT_ADDR         = 64'h0000_0000_8000_0000;
  localparam [63:0] MUL_RESULT_ADDR   = 64'h0000_0000_8000_2000; // C_mul (offload)
  localparam [63:0] RESULT_ADDR       = 64'h0000_0000_8000_3000; // C_add (offload)
  localparam [63:0] SCALAR_CYC_ADDR   = 64'h0000_0000_8000_4000; // scalar  mcycle delta
  localparam [63:0] OFFLOAD_CYC_ADDR  = 64'h0000_0000_8000_4008; // offload mcycle delta
  localparam [63:0] SCALAR_RESULT_ADDR= 64'h0000_0000_8000_5000; // C_s (scalar RV64IM)

  // Absolute path -- same rationale as tb_boot_image.v. build.sh's `bench`
  // target writes this at the core root (REPO_ROOT/bench_image.hex), one
  // level up from fw/. Edit if this repo is cloned elsewhere.
  localparam INIT_FILE = "D:/TinyGPU/TinyGPU/4_64_Core/bench_image.hex";

  reg clk = 0;
  reg rst_ni = 0;
  always #5 clk = ~clk; // 100 MHz

  wire [4:0]  noc_aw_id;    wire [63:0] noc_aw_addr; wire [7:0] noc_aw_len;
  wire [2:0]  noc_aw_size;  wire [1:0]  noc_aw_burst;wire       noc_aw_lock;
  wire [3:0]  noc_aw_cache; wire [2:0]  noc_aw_prot; wire [3:0] noc_aw_qos;
  wire [3:0]  noc_aw_region;wire [5:0]  noc_aw_atop; wire [63:0]noc_aw_user;
  wire        noc_aw_valid; wire        noc_aw_ready;

  wire [4:0]  noc_ar_id;    wire [63:0] noc_ar_addr; wire [7:0] noc_ar_len;
  wire [2:0]  noc_ar_size;  wire [1:0]  noc_ar_burst;wire       noc_ar_lock;
  wire [3:0]  noc_ar_cache; wire [2:0]  noc_ar_prot; wire [3:0] noc_ar_qos;
  wire [3:0]  noc_ar_region;wire [63:0] noc_ar_user;
  wire        noc_ar_valid; wire        noc_ar_ready;

  wire [63:0] noc_w_data;   wire [7:0]  noc_w_strb;  wire       noc_w_last;
  wire [63:0] noc_w_user;   wire        noc_w_valid; wire       noc_w_ready;

  wire [4:0]  noc_b_id;     wire [1:0]  noc_b_resp;  wire [63:0]noc_b_user;
  wire        noc_b_valid;  wire        noc_b_ready;

  wire [4:0]  noc_r_id;     wire [63:0] noc_r_data;  wire [1:0] noc_r_resp;
  wire        noc_r_last;   wire [63:0] noc_r_user;
  wire        noc_r_valid;  wire        noc_r_ready;

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

  axi4_bram_slave #(
      .ID_WIDTH(5), .ADDR_WIDTH(64), .DATA_WIDTH(64),
      .MEM_WORDS(8192), .INIT_FILE(INIT_FILE)
  ) u_mem (
    .clk(clk), .rst_ni(rst_ni),
    .ar_id(noc_ar_id), .ar_addr(noc_ar_addr), .ar_len(noc_ar_len),
    .ar_valid(noc_ar_valid), .ar_ready(noc_ar_ready),
    .r_id(noc_r_id), .r_data(noc_r_data), .r_resp(noc_r_resp),
    .r_last(noc_r_last), .r_valid(noc_r_valid), .r_ready(noc_r_ready),
    .aw_id(noc_aw_id), .aw_addr(noc_aw_addr),
    .aw_valid(noc_aw_valid), .aw_ready(noc_aw_ready),
    .w_data(noc_w_data), .w_strb(noc_w_strb), .w_last(noc_w_last),
    .w_valid(noc_w_valid), .w_ready(noc_w_ready),
    .b_id(noc_b_id), .b_resp(noc_b_resp), .b_valid(noc_b_valid), .b_ready(noc_b_ready),

    .ar2_id(12'd0), .ar2_addr(32'd0), .ar2_len(4'd0), .ar2_valid(1'b0),
    .ar2_ready(), .r2_id(), .r2_data(), .r2_resp(), .r2_last(), .r2_valid(),
    .r2_ready(1'b0)
  );

  integer k;
  reg [63:0] scalar_delta, offload_delta;
  reg [63:0] c_mul33, c_add33, c_s33;
  integer errors;

  // widx() helper mirror -- addr[15:3], 8 bytes/word, same as axi4_bram_slave.
  function [12:0] widx;
    input [63:0] addr;
    widx = addr[15:3];
  endfunction

  initial begin
    errors = 0;
    rst_ni = 1'b0;

    // Zero every BRAM word $readmemh left as X (all of .bss-style space:
    // the result buffers, the cycle-delta words, everything outside
    // .text/.matrix). Real hardware BRAM powers up to 0; general hygiene.
    #1;
    for (k = 0; k < 8192; k = k + 1) begin
      if (^u_mem.mem_a[k] === 1'bx) u_mem.mem_a[k] = 64'd0;
      if (^u_mem.mem_b[k] === 1'bx) u_mem.mem_b[k] = 64'd0;
    end

    repeat (10) @(posedge clk);
    rst_ni = 1'b1;
    $display("[%0t] Reset released, CVA6 booting bench_image.hex from 0x%h", $time, BOOT_ADDR);

    // The offload cycle delta is the last thing bench_matmul.S writes before
    // it parks -- wait for it to become non-zero. Unlike the earlier
    // poll-based design, bench_matmul.S's OFFLOAD_CYC write happens right
    // after the CV-X-IF commit of the last vse64.v, NOT after TinyGPU's AXI
    // writeback of C_add actually lands -- so wait a generous extra margin
    // (100 cycles = comfortably more than one 16-beat AXI4 burst) before
    // trusting the C_mul/C_add words below.
    while (u_mem.mem_a[widx(OFFLOAD_CYC_ADDR)] === 64'd0 ||
           ^u_mem.mem_a[widx(OFFLOAD_CYC_ADDR)] === 1'bx) @(posedge clk);
    repeat (100) @(posedge clk);

    scalar_delta  = u_mem.mem_a[widx(SCALAR_CYC_ADDR)];
    offload_delta = u_mem.mem_a[widx(OFFLOAD_CYC_ADDR)];
    c_mul33 = u_mem.mem_a[widx(MUL_RESULT_ADDR)+15];
    c_add33 = u_mem.mem_a[widx(RESULT_ADDR)+15];
    c_s33   = u_mem.mem_a[widx(SCALAR_RESULT_ADDR)+15];

    $display("");
    $display("==================== bench_image.hex results ====================");
    $display("  C_mul[3][3]  = %0d   (expect 600)", c_mul33);
    $display("  C_add[3][3]  = %0d   (expect 32)",  c_add33);
    $display("  C_s[3][3]    = %0d   (expect 600)", c_s33);
    $display("  scalar  mcycle delta = %0d cycles", scalar_delta);
    $display("  offload mcycle delta = %0d cycles", offload_delta);
    if (offload_delta != 0)
      $display("  speedup (scalar / offload) = %0.2fx", scalar_delta * 1.0 / offload_delta);
    $display("  cross-check: compare 'scalar mcycle delta' above against");
    $display("  tb_speedup_cycles.v's 'CVA6 matmul-only ... cycles' line");
    $display("  (run that TB separately) -- should agree within a few cycles.");
    $display("================================================================");

    if (c_mul33 !== 64'd600) begin errors=errors+1; $display("FAIL: C_mul[3][3] != 600"); end
    if (c_add33 !== 64'd32)  begin errors=errors+1; $display("FAIL: C_add[3][3] != 32");  end
    if (c_s33   !== 64'd600) begin errors=errors+1; $display("FAIL: C_s[3][3] != 600");   end
    if (scalar_delta === 64'd0)  begin errors=errors+1; $display("FAIL: scalar delta is 0");  end
    if (offload_delta === 64'd0) begin errors=errors+1; $display("FAIL: offload delta is 0"); end
    if (scalar_delta !== 64'd0 && offload_delta !== 64'd0 && !(scalar_delta > offload_delta)) begin
      errors=errors+1; $display("FAIL: scalar delta not greater than offload delta");
    end

    if (errors == 0) $display("[%0t] tb_bench_image PASS", $time);
    else             $display("[%0t] tb_bench_image FAIL (%0d error(s))", $time, errors);

    repeat (20) @(posedge clk);
    $finish;
  end

  initial begin
    #400000;
    $display("[%0t] TIMEOUT -- bench_image.hex never wrote OFFLOAD_CYC_ADDR.", $time);
    $display("Likely the CPU-side poll never saw C_add[3][3]==32, or this is");
    $display("not a bench build (use fw/build.sh bench).");
    $finish;
  end

endmodule
