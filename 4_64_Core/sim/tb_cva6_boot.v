`timescale 1ns / 1ps
// Full-pipeline boot test: real CVA6 fetches a real boot program from a
// behavioral AXI4 memory, hits the illegal-instruction->CVXIF offload path
// for real, and drives cva6_sv_shim.sv's actual struct-packed ports --
// nothing here is hand-driven the way tb_tinygpu_cvxif.v/tb_matmul.v were.
//
// Boot program (at BOOT_ADDR = 0x8000_0000), hand-encoded (no toolchain):
//   lui   x1, 0x80001    0x800020B7   x1 = 0x80001000 (matrix base addr)
//   vle64.v (vs1=1,vs2=2) 0x0020F007   load A into L3 line1, B(=A) into line2
//   vmacc   (vs1=1,vs2=2) computed     C = A x A
//   jal   x0, 0                       infinite self-loop (park the core)
//
// BOOT_ADDR/MAT_ADDR deliberately sit inside CVA6Cfg.CachedRegionAddrBase/
// Length (0x8000_0000, length 0x40000000 -- see cv64a6_imafdc_sv39_config_
// pkg.sv). Addresses outside that region hit cva6_icache.sv's non-cacheable
// bypass path (paddr_is_nc), which uses different transfer width/alignment
// handling than the normal cache-line-fill path our AXI4 slave models --
// confirmed by observation: at 0x1000, npc_q free-ran every cycle but
// noc_ar_valid never pulsed once, consistent with the NC path's own
// miss/request trigger (separate from the normal `miss_o`, which is
// explicitly zeroed for NC addresses) never firing against our model.
//
// Matrix data preloaded directly into memory at MAT_ADDR = 0x8000_1000:
//   A = [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]], B = A (same bytes
//   repeated), matching the same C = A x A used in tb_matmul.v so results
//   are directly comparable.
module tb_cva6_boot;

  localparam [63:0] BOOT_ADDR = 64'h0000_0000_8000_0000;
  localparam [63:0] MAT_ADDR  = 64'h0000_0000_8000_1000;

  reg clk = 0;
  reg rst_ni = 0;
  always #5 clk = ~clk; // 100 MHz

  // ---- NOC/AXI4 (CVA6's own fetch/load-store) ----
  wire [3:0]  noc_aw_id;   wire [63:0] noc_aw_addr; wire [7:0] noc_aw_len;
  wire [2:0]  noc_aw_size; wire [1:0]  noc_aw_burst;wire       noc_aw_lock;
  wire [3:0]  noc_aw_cache;wire [2:0]  noc_aw_prot; wire [3:0] noc_aw_qos;
  wire [3:0]  noc_aw_region;wire [5:0] noc_aw_atop; wire [63:0]noc_aw_user;
  wire        noc_aw_valid; wire       noc_aw_ready;

  wire [3:0]  noc_ar_id;   wire [63:0] noc_ar_addr; wire [7:0] noc_ar_len;
  wire [2:0]  noc_ar_size; wire [1:0]  noc_ar_burst;wire       noc_ar_lock;
  wire [3:0]  noc_ar_cache;wire [2:0]  noc_ar_prot; wire [3:0] noc_ar_qos;
  wire [3:0]  noc_ar_region;wire [63:0]noc_ar_user;
  wire        noc_ar_valid; wire       noc_ar_ready;

  wire [63:0] noc_w_data;  wire [7:0]  noc_w_strb;  wire       noc_w_last;
  wire [63:0] noc_w_user;  wire        noc_w_valid; wire       noc_w_ready;

  wire [3:0]  noc_b_id;    wire [1:0]  noc_b_resp;  wire [63:0]noc_b_user;
  wire        noc_b_valid; wire        noc_b_ready;

  wire [3:0]  noc_r_id;    wire [63:0] noc_r_data;  wire [1:0] noc_r_resp;
  wire        noc_r_last;  wire [63:0] noc_r_user;
  wire        noc_r_valid; wire        noc_r_ready;

  // ---- GPU's own simplified 256-bit read master (vle64 loads) ----
  wire [63:0]  gpu_araddr;
  wire         gpu_arvalid;
  reg          gpu_arready;
  reg  [255:0] gpu_rdata;
  reg          gpu_rvalid;
  wire         gpu_rready;

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
    .noc_r_valid(noc_r_valid), .noc_r_ready(noc_r_ready),

    .gpu_araddr (gpu_araddr),
    .gpu_arvalid(gpu_arvalid),
    .gpu_arready(gpu_arready),
    .gpu_rdata  (gpu_rdata),
    .gpu_rvalid (gpu_rvalid),
    .gpu_rready (gpu_rready)
  );

  // ---- Real AXI4 slave for CVA6's own icache/dcache traffic ----
  axi4_mem_slave #(.ID_WIDTH(4), .ADDR_WIDTH(64), .DATA_WIDTH(64)) u_noc_mem (
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

  // ---- Simplified 256-bit-beat model for the GPU's own load master.
  // Reads from the SAME backing memory as u_noc_mem (hierarchical ref),
  // so data CVA6's boot program points at is what the GPU actually gets.
  always @(posedge clk) begin
    if (!rst_ni) begin
      gpu_arready <= 1'b0;
      gpu_rvalid  <= 1'b0;
    end else begin
      gpu_arready <= 1'b0;
      gpu_rvalid  <= 1'b0;
      if (gpu_arvalid && !gpu_arready) begin
        gpu_arready <= 1'b1;
      end
      if (gpu_arready) begin
        gpu_rdata <= { u_noc_mem.mem[u_noc_mem.widx(gpu_araddr)+3],
                        u_noc_mem.mem[u_noc_mem.widx(gpu_araddr)+2],
                        u_noc_mem.mem[u_noc_mem.widx(gpu_araddr)+1],
                        u_noc_mem.mem[u_noc_mem.widx(gpu_araddr)+0] };
        gpu_rvalid <= 1'b1;
      end
    end
  end

  // ---- Boot program + matrix data preload ----
  reg [31:0] lui_instr, vle64_instr, vmacc_instr, jal_instr;
  integer k;

  initial begin
    lui_instr   = {20'h80001, 5'd1, 7'b0110111};                   // lui x1, 0x80001 -> x1=0x80001000
    vle64_instr = {7'b0000000, 5'd2, 5'd1, 3'b111, 5'd0, 7'b0000111}; // vle64.v vs1=1 vs2=2
    vmacc_instr = {6'h2D, 1'b0, 5'd2, 5'd1, 3'b010, 5'd0, 7'b1010111}; // vmacc  vs1=1 vs2=2
    jal_instr   = {1'b0, 10'b0, 1'b0, 8'b0, 5'd0, 7'b1101111};        // jal x0, 0 (self-loop)

    // BOOT_ADDR is 16B-aligned -> all 4 instructions land in one icache line.
    u_noc_mem.mem[u_noc_mem.widx(BOOT_ADDR)]   = {vle64_instr, lui_instr};
    u_noc_mem.mem[u_noc_mem.widx(BOOT_ADDR)+1] = {jal_instr,   vmacc_instr};

    // Matrix A at words [MAT_ADDR..+15] = 1..16 (row-major); matrix B is
    // the SAME 16 words repeated at [+16..+31], so B = A and C = A x A.
    for (k = 0; k < 16; k = k + 1) begin
      u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR) + k]      = k + 1;
      u_noc_mem.mem[u_noc_mem.widx(MAT_ADDR) + 16 + k]  = k + 1;
    end

    rst_ni = 1'b0;
    repeat (10) @(posedge clk);
    rst_ni = 1'b1;

    $display("[%0t] Reset released, CVA6 booting from 0x%h", $time, BOOT_ADDR);

    // Poll for the matmul's result landing in the GPU's output registers.
    // vd_0_0 starts at 0 and becomes 90 (see tb_matmul.v) once C[0][0] lands.
    wait (dut.u_gpu.vd_0_0 == 64'd90);
    $display("[%0t] vd_0_0 == 90 -- matmul appears to have completed.", $time);
    repeat (20) @(posedge clk);

    $display("Result C (vd_<pass>_<core>):");
    $display("  %0d %0d %0d %0d", dut.u_gpu.vd_0_0, dut.u_gpu.vd_0_1, dut.u_gpu.vd_0_2, dut.u_gpu.vd_0_3);
    $display("  %0d %0d %0d %0d", dut.u_gpu.vd_1_0, dut.u_gpu.vd_1_1, dut.u_gpu.vd_1_2, dut.u_gpu.vd_1_3);
    $display("  %0d %0d %0d %0d", dut.u_gpu.vd_2_0, dut.u_gpu.vd_2_1, dut.u_gpu.vd_2_2, dut.u_gpu.vd_2_3);
    $display("  %0d %0d %0d %0d", dut.u_gpu.vd_3_0, dut.u_gpu.vd_3_1, dut.u_gpu.vd_3_2, dut.u_gpu.vd_3_3);
    $display("Expected:");
    $display("   90 100 110 120");
    $display("  202 228 254 280");
    $display("  314 356 398 440");
    $display("  426 484 542 600");

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
