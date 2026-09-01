`timescale 1ns / 1ps
// tb_boot_image.v -- unlike tb_cva6_boot.v (which pokes a hand-written
// instruction/matrix stream directly into axi4_mem_slave.v's memory array
// in an `initial` block, never touching boot_image.hex at all), THIS
// testbench instantiates the real, synthesizable axi4_bram_slave.v and
// lets it $readmemh the exact same boot_image.hex file real hardware
// would load -- the only way to actually simulate "does the
// compiler-produced boot_image.hex work" before ever touching hardware,
// as opposed to just diffing/disassembling it offline.
//
// Wiring mirrors fpga_top.v's own cva6_tinygpu_soc <-> axi4_bram_slave
// connection exactly (same noc_* port names/widths) -- this is the real
// hardware datapath, not a simulation-only shortcut.
//
// Option B (matmul-then-matadd, two writebacks: MUL_RESULT_ADDR for
// C_mul, RESULT_ADDR for C_add) -- matches fw/boot_matmul.S's
// program. If you point INIT_FILE at an Option A (single-writeback)
// boot_image.hex instead, the MUL_RESULT_ADDR poll below will simply
// never complete (TIMEOUT) -- that's expected, not a bug in this
// testbench.
module tb_boot_image;

  localparam [63:0] BOOT_ADDR        = 64'h0000_0000_8000_0000;
  localparam [63:0] MUL_RESULT_ADDR  = 64'h0000_0000_8000_2000;
  localparam [63:0] RESULT_ADDR      = 64'h0000_0000_8000_3000;

  // Relative filename -- same convention as axi4_bram_slave.v's own
  // INIT_FILE default and fpga_top.v's instantiation of it. Vivado copies
  // boot_image.hex (added via import_sources.tcl as a "Memory
  // Initialization File") into the sim snapshot dir next to the compiled
  // sources, so xsim resolves this without needing an absolute,
  // clone-location-specific path.
  localparam INIT_FILE = "boot_image.hex";

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

  // ---- Real, synthesizable memory backend, $readmemh-loaded from the
  // compiler-produced boot_image.hex -- exactly what real hardware runs.
  // Port B (PS7 GP0-facing) tied off/unused here -- this testbench only
  // exercises Port A (the noc_* bus CVA6+TinyGPU share).
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

  reg [63:0] c_mul [0:3][0:3];
  reg [63:0] c_add [0:3][0:3];

  initial begin
    rst_ni = 1'b0;
    repeat (10) @(posedge clk);
    rst_ni = 1'b1;

    $display("[%0t] Reset released, CVA6 booting from 0x%h (boot_image.hex = %s)", $time, BOOT_ADDR, INIT_FILE);

    while (dut.u_gpu.vd_0_0 !== 64'd90) @(posedge clk);
    $display("[%0t] vd_0_0 == 90 -- vmacc appears to have completed.", $time);
    c_mul[0][0]=dut.u_gpu.vd_0_0; c_mul[0][1]=dut.u_gpu.vd_0_1; c_mul[0][2]=dut.u_gpu.vd_0_2; c_mul[0][3]=dut.u_gpu.vd_0_3;
    c_mul[1][0]=dut.u_gpu.vd_1_0; c_mul[1][1]=dut.u_gpu.vd_1_1; c_mul[1][2]=dut.u_gpu.vd_1_2; c_mul[1][3]=dut.u_gpu.vd_1_3;
    c_mul[2][0]=dut.u_gpu.vd_2_0; c_mul[2][1]=dut.u_gpu.vd_2_1; c_mul[2][2]=dut.u_gpu.vd_2_2; c_mul[2][3]=dut.u_gpu.vd_2_3;
    c_mul[3][0]=dut.u_gpu.vd_3_0; c_mul[3][1]=dut.u_gpu.vd_3_1; c_mul[3][2]=dut.u_gpu.vd_3_2; c_mul[3][3]=dut.u_gpu.vd_3_3;
    $display("vmacc result C_mul (compiler-produced program):");
    $display("  %0d %0d %0d %0d", c_mul[0][0], c_mul[0][1], c_mul[0][2], c_mul[0][3]);
    $display("  %0d %0d %0d %0d", c_mul[1][0], c_mul[1][1], c_mul[1][2], c_mul[1][3]);
    $display("  %0d %0d %0d %0d", c_mul[2][0], c_mul[2][1], c_mul[2][2], c_mul[2][3]);
    $display("  %0d %0d %0d %0d", c_mul[3][0], c_mul[3][1], c_mul[3][2], c_mul[3][3]);

    while (dut.u_gpu.vd_0_0 !== 64'd2) @(posedge clk);
    $display("[%0t] vd_0_0 == 2 -- vadd.vv appears to have completed.", $time);
    c_add[0][0]=dut.u_gpu.vd_0_0; c_add[0][1]=dut.u_gpu.vd_0_1; c_add[0][2]=dut.u_gpu.vd_0_2; c_add[0][3]=dut.u_gpu.vd_0_3;
    c_add[1][0]=dut.u_gpu.vd_1_0; c_add[1][1]=dut.u_gpu.vd_1_1; c_add[1][2]=dut.u_gpu.vd_1_2; c_add[1][3]=dut.u_gpu.vd_1_3;
    c_add[2][0]=dut.u_gpu.vd_2_0; c_add[2][1]=dut.u_gpu.vd_2_1; c_add[2][2]=dut.u_gpu.vd_2_2; c_add[2][3]=dut.u_gpu.vd_2_3;
    c_add[3][0]=dut.u_gpu.vd_3_0; c_add[3][1]=dut.u_gpu.vd_3_1; c_add[3][2]=dut.u_gpu.vd_3_2; c_add[3][3]=dut.u_gpu.vd_3_3;
    $display("vadd.vv result C_add (compiler-produced program):");
    $display("  %0d %0d %0d %0d", c_add[0][0], c_add[0][1], c_add[0][2], c_add[0][3]);
    $display("  %0d %0d %0d %0d", c_add[1][0], c_add[1][1], c_add[1][2], c_add[1][3]);
    $display("  %0d %0d %0d %0d", c_add[2][0], c_add[2][1], c_add[2][2], c_add[2][3]);
    $display("  %0d %0d %0d %0d", c_add[3][0], c_add[3][1], c_add[3][2], c_add[3][3]);

    // Writeback bursts are strictly in-order -- once word +15 (the last
    // element) shows its final value, the whole 16-word burst landed.
    while (u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+15] !== 64'd600) @(posedge clk);
    $display("[%0t] MUL_RESULT_ADDR+15 == 600 -- vmacc's vse64.v writeback completed.", $time);
    $display("Writeback contents at MUL_RESULT_ADDR (read directly out of DRAM):");
    $display("  %0d %0d %0d %0d", u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+0], u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+1], u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+2], u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+3]);
    $display("  %0d %0d %0d %0d", u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+4], u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+5], u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+6], u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+7]);
    $display("  %0d %0d %0d %0d", u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+8], u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+9], u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+10], u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+11]);
    $display("  %0d %0d %0d %0d", u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+12], u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+13], u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+14], u_mem.mem_a[u_mem.widx(MUL_RESULT_ADDR)+15]);

    while (u_mem.mem_a[u_mem.widx(RESULT_ADDR)+15] !== 64'd32) @(posedge clk);
    $display("[%0t] RESULT_ADDR+15 == 32 -- vadd.vv's vse64.v writeback completed.", $time);
    $display("Writeback contents at RESULT_ADDR (read directly out of DRAM):");
    $display("  %0d %0d %0d %0d", u_mem.mem_a[u_mem.widx(RESULT_ADDR)+0], u_mem.mem_a[u_mem.widx(RESULT_ADDR)+1], u_mem.mem_a[u_mem.widx(RESULT_ADDR)+2], u_mem.mem_a[u_mem.widx(RESULT_ADDR)+3]);
    $display("  %0d %0d %0d %0d", u_mem.mem_a[u_mem.widx(RESULT_ADDR)+4], u_mem.mem_a[u_mem.widx(RESULT_ADDR)+5], u_mem.mem_a[u_mem.widx(RESULT_ADDR)+6], u_mem.mem_a[u_mem.widx(RESULT_ADDR)+7]);
    $display("  %0d %0d %0d %0d", u_mem.mem_a[u_mem.widx(RESULT_ADDR)+8], u_mem.mem_a[u_mem.widx(RESULT_ADDR)+9], u_mem.mem_a[u_mem.widx(RESULT_ADDR)+10], u_mem.mem_a[u_mem.widx(RESULT_ADDR)+11]);
    $display("  %0d %0d %0d %0d", u_mem.mem_a[u_mem.widx(RESULT_ADDR)+12], u_mem.mem_a[u_mem.widx(RESULT_ADDR)+13], u_mem.mem_a[u_mem.widx(RESULT_ADDR)+14], u_mem.mem_a[u_mem.widx(RESULT_ADDR)+15]);

    repeat (20) @(posedge clk);
    $finish;
  end

  initial begin
    #200000;
    $display("[%0t] TIMEOUT -- matmul/matadd never completed against %s.", $time, INIT_FILE);
    $display("If this is an Option A (single-writeback) hex, the MUL_RESULT_ADDR");
    $display("poll never completes -- that's expected, not a bug in this testbench.");
    $finish;
  end

endmodule
