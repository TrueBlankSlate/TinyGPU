`timescale 1ns / 1ps
// Top-level SoC in plain Verilog-2001.
// CVA6 is accessed via cva6_sv_shim.sv which handles all SV struct unpacking.
// AXI widths below match cv64a6_imafdc_sv39_config_pkg.sv: AxiAddrWidth=64,
// AxiDataWidth=64, AxiUserWidth=64.

module cva6_tinygpu_soc (
    input  wire clk,
    input  wire rst_ni,
    input  wire [63:0] boot_addr,
    input  wire [63:0] hart_id,
    input  wire [1:0] irq,
    input  wire ipi,
    input  wire time_irq,
    input  wire debug_req,

    // NOC/AXI4 (connect to your DRAM controller / interconnect) --
    // shared by CVA6 and TinyGPU, arbitrated inside u_shim.
    output wire [4:0] noc_aw_id,
    output wire [63:0] noc_aw_addr,
    output wire [7:0] noc_aw_len,
    output wire [2:0] noc_aw_size,
    output wire [1:0] noc_aw_burst,
    output wire noc_aw_lock,
    output wire [3:0] noc_aw_cache,
    output wire [2:0] noc_aw_prot,
    output wire [3:0] noc_aw_qos,
    output wire [3:0] noc_aw_region,
    output wire [5:0] noc_aw_atop,
    output wire [63:0] noc_aw_user,
    output wire noc_aw_valid,
    input wire noc_aw_ready,

    output wire [4:0] noc_ar_id,
    output wire [63:0] noc_ar_addr,
    output wire [7:0] noc_ar_len,
    output wire [2:0] noc_ar_size,
    output wire [1:0] noc_ar_burst,
    output wire noc_ar_lock,
    output wire [3:0] noc_ar_cache,
    output wire [2:0] noc_ar_prot,
    output wire [3:0] noc_ar_qos,
    output wire [3:0] noc_ar_region,
    output wire [63:0] noc_ar_user,
    output wire noc_ar_valid,
    input wire noc_ar_ready,

    output wire [63:0] noc_w_data,
    output wire [7:0] noc_w_strb,
    output wire noc_w_last,
    output wire [63:0] noc_w_user,
    output wire noc_w_valid,
    input  wire noc_w_ready,

    input wire [4:0] noc_b_id,
    input wire [1:0] noc_b_resp,
    input wire [63:0] noc_b_user,
    input wire noc_b_valid,
    output wire noc_b_ready,

    input wire [4:0] noc_r_id,
    input wire [63:0] noc_r_data,
    input wire [1:0] noc_r_resp,
    input wire noc_r_last,
    input wire [63:0] noc_r_user,
    input wire noc_r_valid,
    output wire noc_r_ready
);

  // CV-X-IF flat wires between shim and GPU wrapper
  wire issue_valid;
  wire [31:0] issue_instr;
  wire [2:0] issue_id;
  wire [63:0] issue_rs1;
  wire issue_ready;
  wire issue_accept;
  wire issue_writeback;
  wire commit_valid;
  wire [2:0]  commit_id;
  wire commit_kill;
  wire result_ready;
  wire result_valid;
  wire [2:0] result_id;
  wire [63:0] result_data;
  wire [4:0] result_rd;
  wire result_we;

  // TinyGPU's real AXI4 read master - internal only, arbitered onto
  // noc_* inside u_shim (see axi_mux there). ID width is 4 bits here
  // (pre-arbitration, matching CVA6Cfg.AxiIdWidth).
  wire [3:0]  gpu_ar_id;
  wire [63:0] gpu_ar_addr;
  wire [7:0]  gpu_ar_len;
  wire [2:0]  gpu_ar_size;
  wire [1:0]  gpu_ar_burst;
  wire        gpu_ar_valid;
  wire        gpu_ar_ready;
  wire [3:0]  gpu_r_id;
  wire [63:0] gpu_r_data;
  wire [1:0]  gpu_r_resp;
  wire        gpu_r_last;
  wire        gpu_r_valid;
  wire        gpu_r_ready;

  // TinyGPU's real AXI4 write master (vse64.v writeback) - internal only,
  // same arbitration/ID-width story as the read master above.
  wire [3:0] gpu_aw_id;
  wire [63:0] gpu_aw_addr;
  wire [7:0] gpu_aw_len;
  wire [2:0] gpu_aw_size;
  wire [1:0] gpu_aw_burst;
  wire gpu_aw_valid;
  wire gpu_aw_ready;
  wire [63:0] gpu_w_data;
  wire [7:0] gpu_w_strb;
  wire gpu_w_last;
  wire gpu_w_valid;
  wire gpu_w_ready;
  wire [3:0] gpu_b_id;
  wire [1:0] gpu_b_resp;
  wire gpu_b_valid;
  wire gpu_b_ready;

  cva6_sv_shim u_shim (
    .clk_i (clk),
    .rst_ni (rst_ni),
    .boot_addr_i (boot_addr),
    .hart_id_i (hart_id),
    .irq_i (irq),
    .ipi_i (ipi),
    .time_irq_i (time_irq),
    .debug_req_i (debug_req),
    .noc_aw_id_o (noc_aw_id),
    .noc_aw_addr_o (noc_aw_addr),
    .noc_aw_len_o (noc_aw_len),
    .noc_aw_size_o (noc_aw_size),
    .noc_aw_burst_o (noc_aw_burst),
    .noc_aw_lock_o (noc_aw_lock),
    .noc_aw_cache_o (noc_aw_cache),
    .noc_aw_prot_o (noc_aw_prot),
    .noc_aw_qos_o (noc_aw_qos),
    .noc_aw_region_o (noc_aw_region),
    .noc_aw_atop_o (noc_aw_atop),
    .noc_aw_user_o (noc_aw_user),
    .noc_aw_valid_o (noc_aw_valid),
    .noc_aw_ready_i (noc_aw_ready),

    .noc_ar_id_o (noc_ar_id),
    .noc_ar_addr_o (noc_ar_addr),
    .noc_ar_len_o (noc_ar_len),
    .noc_ar_size_o (noc_ar_size),
    .noc_ar_burst_o (noc_ar_burst),
    .noc_ar_lock_o (noc_ar_lock),
    .noc_ar_cache_o (noc_ar_cache),
    .noc_ar_prot_o (noc_ar_prot),
    .noc_ar_qos_o (noc_ar_qos),
    .noc_ar_region_o (noc_ar_region),
    .noc_ar_user_o (noc_ar_user),
    .noc_ar_valid_o (noc_ar_valid),
    .noc_ar_ready_i (noc_ar_ready),

    .noc_w_data_o (noc_w_data),
    .noc_w_strb_o (noc_w_strb),
    .noc_w_last_o (noc_w_last),
    .noc_w_user_o (noc_w_user),
    .noc_w_valid_o (noc_w_valid),
    .noc_w_ready_i (noc_w_ready),

    .noc_b_id_i (noc_b_id),
    .noc_b_resp_i (noc_b_resp),
    .noc_b_user_i (noc_b_user),
    .noc_b_valid_i (noc_b_valid),
    .noc_b_ready_o (noc_b_ready),

    .noc_r_id_i (noc_r_id),
    .noc_r_data_i (noc_r_data),
    .noc_r_resp_i (noc_r_resp),
    .noc_r_last_i (noc_r_last),
    .noc_r_user_i (noc_r_user),
    .noc_r_valid_i (noc_r_valid),
    .noc_r_ready_o (noc_r_ready),

    .gpu_ar_id_i (gpu_ar_id),
    .gpu_ar_addr_i (gpu_ar_addr),
    .gpu_ar_len_i (gpu_ar_len),
    .gpu_ar_size_i (gpu_ar_size),
    .gpu_ar_burst_i(gpu_ar_burst),
    .gpu_ar_valid_i(gpu_ar_valid),
    .gpu_ar_ready_o(gpu_ar_ready),
    .gpu_r_id_o (gpu_r_id),
    .gpu_r_data_o (gpu_r_data),
    .gpu_r_resp_o (gpu_r_resp),
    .gpu_r_last_o (gpu_r_last),
    .gpu_r_valid_o (gpu_r_valid),
    .gpu_r_ready_i (gpu_r_ready),

    .gpu_aw_id_i   (gpu_aw_id),
    .gpu_aw_addr_i (gpu_aw_addr),
    .gpu_aw_len_i  (gpu_aw_len),
    .gpu_aw_size_i (gpu_aw_size),
    .gpu_aw_burst_i(gpu_aw_burst),
    .gpu_aw_valid_i(gpu_aw_valid),
    .gpu_aw_ready_o(gpu_aw_ready),
    .gpu_w_data_i (gpu_w_data),
    .gpu_w_strb_i (gpu_w_strb),
    .gpu_w_last_i (gpu_w_last),
    .gpu_w_valid_i (gpu_w_valid),
    .gpu_w_ready_o (gpu_w_ready),
    .gpu_b_id_o (gpu_b_id),
    .gpu_b_resp_o (gpu_b_resp),
    .gpu_b_valid_o (gpu_b_valid),
    .gpu_b_ready_i (gpu_b_ready),

    .cvxif_issue_valid_o (issue_valid),
    .cvxif_issue_instr_o (issue_instr),
    .cvxif_issue_id_o (issue_id),
    .cvxif_issue_rs1_o (issue_rs1),
    .cvxif_issue_ready_i (issue_ready),
    .cvxif_issue_accept_i (issue_accept),
    .cvxif_issue_writeback_i(issue_writeback),
    .cvxif_commit_valid_o (commit_valid),
    .cvxif_commit_id_o (commit_id),
    .cvxif_commit_kill_o (commit_kill),
    .cvxif_result_ready_o (result_ready),
    .cvxif_result_valid_i (result_valid),
    .cvxif_result_id_i (result_id),
    .cvxif_result_data_i (result_data),
    .cvxif_result_rd_i (result_rd),
    .cvxif_result_we_i (result_we)
  );

  tinygpu_cvxif_wrap u_gpu (
    .clk             (clk),
    .rst_ni          (rst_ni),
    .issue_valid     (issue_valid),
    .issue_instr     (issue_instr),
    .issue_id        (issue_id),
    .issue_rs1       (issue_rs1),
    .issue_ready     (issue_ready),
    .issue_accept    (issue_accept),
    .issue_writeback (issue_writeback),
    .commit_valid    (commit_valid),
    .commit_id       (commit_id),
    .commit_kill     (commit_kill),
    .result_ready    (result_ready),
    .result_valid    (result_valid),
    .result_id       (result_id),
    .result_data     (result_data),
    .result_rd       (result_rd),
    .result_we       (result_we),
    .ar_id           (gpu_ar_id),
    .ar_addr         (gpu_ar_addr),
    .ar_len          (gpu_ar_len),
    .ar_size         (gpu_ar_size),
    .ar_burst        (gpu_ar_burst),
    .ar_valid        (gpu_ar_valid),
    .ar_ready        (gpu_ar_ready),
    .r_id            (gpu_r_id),
    .r_data          (gpu_r_data),
    .r_resp          (gpu_r_resp),
    .r_last          (gpu_r_last),
    .r_valid         (gpu_r_valid),
    .r_ready         (gpu_r_ready),
    .aw_id           (gpu_aw_id),
    .aw_addr         (gpu_aw_addr),
    .aw_len          (gpu_aw_len),
    .aw_size         (gpu_aw_size),
    .aw_burst        (gpu_aw_burst),
    .aw_valid        (gpu_aw_valid),
    .aw_ready        (gpu_aw_ready),
    .w_data          (gpu_w_data),
    .w_strb          (gpu_w_strb),
    .w_last          (gpu_w_last),
    .w_valid         (gpu_w_valid),
    .w_ready         (gpu_w_ready),
    .b_id            (gpu_b_id),
    .b_resp          (gpu_b_resp),
    .b_valid         (gpu_b_valid),
    .b_ready         (gpu_b_ready)
  );

endmodule
