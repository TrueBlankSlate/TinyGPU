`include "cvxif_types.svh"
`include "rvfi_types.svh"

module cva6_sv_shim #(
  parameter config_pkg::cva6_cfg_t CVA6Cfg =
      build_config_pkg::build_config(cva6_config_pkg::cva6_cfg)
)(
  input  logic                    clk_i,
  input  logic                    rst_ni,
  input  logic [CVA6Cfg.VLEN-1:0] boot_addr_i, //64
  input  logic [CVA6Cfg.XLEN-1:0] hart_id_i, //64
  input  logic [1:0]              irq_i,
  input  logic                    ipi_i,
  input  logic                    time_irq_i,
  input  logic                    debug_req_i,

  // AXI / NoC interface (full AXI4, flattened for the plain-Verilog top)
  output logic [CVA6Cfg.AxiIdWidth-1:0]     noc_aw_id_o,
  output logic [CVA6Cfg.AxiAddrWidth-1:0]   noc_aw_addr_o,
  output logic [7:0]                        noc_aw_len_o,
  output logic [2:0]                        noc_aw_size_o,
  output logic [1:0]                        noc_aw_burst_o,
  output logic                              noc_aw_lock_o,
  output logic [3:0]                        noc_aw_cache_o,
  output logic [2:0]                        noc_aw_prot_o,
  output logic [3:0]                        noc_aw_qos_o,
  output logic [3:0]                        noc_aw_region_o,
  output logic [5:0]                        noc_aw_atop_o,
  output logic [CVA6Cfg.AxiUserWidth-1:0]   noc_aw_user_o,
  output logic                              noc_aw_valid_o,
  input  logic                              noc_aw_ready_i,

  output logic [CVA6Cfg.AxiIdWidth-1:0]     noc_ar_id_o,
  output logic [CVA6Cfg.AxiAddrWidth-1:0]   noc_ar_addr_o,
  output logic [7:0]                        noc_ar_len_o,
  output logic [2:0]                        noc_ar_size_o,
  output logic [1:0]                        noc_ar_burst_o,
  output logic                              noc_ar_lock_o,
  output logic [3:0]                        noc_ar_cache_o,
  output logic [2:0]                        noc_ar_prot_o,
  output logic [3:0]                        noc_ar_qos_o,
  output logic [3:0]                        noc_ar_region_o,
  output logic [CVA6Cfg.AxiUserWidth-1:0]   noc_ar_user_o,
  output logic                              noc_ar_valid_o,
  input  logic                              noc_ar_ready_i,

  output logic [CVA6Cfg.AxiDataWidth-1:0]     noc_w_data_o,
  output logic [(CVA6Cfg.AxiDataWidth/8)-1:0] noc_w_strb_o,
  output logic                                noc_w_last_o,
  output logic [CVA6Cfg.AxiUserWidth-1:0]     noc_w_user_o,
  output logic                                noc_w_valid_o,
  input  logic                                noc_w_ready_i,

  input  logic [CVA6Cfg.AxiIdWidth-1:0]     noc_b_id_i, //AxiId width, maximum = 16?
  input  logic [1:0]                        noc_b_resp_i,
  input  logic [CVA6Cfg.AxiUserWidth-1:0]   noc_b_user_i,
  input  logic                              noc_b_valid_i,
  output logic                              noc_b_ready_o,

  input  logic [CVA6Cfg.AxiIdWidth-1:0]     noc_r_id_i,
  input  logic [CVA6Cfg.AxiDataWidth-1:0]   noc_r_data_i,
  input  logic [1:0]                        noc_r_resp_i,
  input  logic                              noc_r_last_i,
  input  logic [CVA6Cfg.AxiUserWidth-1:0]   noc_r_user_i,
  input  logic                              noc_r_valid_i,
  output logic                              noc_r_ready_o,

  // CVXIF -> TinyGPU
  output logic                    cvxif_issue_valid_o, //is the instruction valid to send? <=====
  output logic [31:0]             cvxif_issue_instr_o, //issue instruction <====
  output logic [CVA6Cfg.X_ID_WIDTH-1:0] cvxif_issue_id_o,
  output logic [CVA6Cfg.XLEN-1:0] cvxif_issue_rs1_o, //<===== base address

  // TinyGPU -> CVXIF
  input  logic                    cvxif_issue_accept_i, // response <====
  input  logic                    cvxif_issue_writeback_i, 

  // Commit
  output logic                    cvxif_commit_valid_o,
  output logic [CVA6Cfg.X_ID_WIDTH-1:0] cvxif_commit_id_o,
  output logic                    cvxif_commit_kill_o,

  // Result
  output logic                    cvxif_result_ready_o,
  input  logic                    cvxif_result_valid_i,
  input  logic [CVA6Cfg.X_ID_WIDTH-1:0] cvxif_result_id_i,
  input  logic [CVA6Cfg.XLEN-1:0]  cvxif_result_data_i,
  input  logic [4:0]              cvxif_result_rd_i,
  input  logic                    cvxif_result_we_i
);

  // ------------------------------------------------------------
  // CVXIF types - EXACTLY from current cvxif_types.svh
  // ------------------------------------------------------------
  localparam type readregflags_t  = `READREGFLAGS_T(CVA6Cfg);
  localparam type writeregflags_t = `WRITEREGFLAGS_T(CVA6Cfg);
  localparam type id_t            = `ID_T(CVA6Cfg);
  localparam type hartid_t        = `HARTID_T(CVA6Cfg);

  localparam type x_compressed_req_t =
      `X_COMPRESSED_REQ_T(CVA6Cfg, hartid_t); //hardware thread id <=====

  localparam type x_compressed_resp_t =
      `X_COMPRESSED_RESP_T(CVA6Cfg);

  localparam type x_issue_req_t =
      `X_ISSUE_REQ_T(CVA6Cfg, hartid_t, id_t);

  localparam type x_issue_resp_t =
      `X_ISSUE_RESP_T(CVA6Cfg, writeregflags_t, readregflags_t);

  localparam type x_register_t =
      `X_REGISTER_T(CVA6Cfg, hartid_t, id_t, readregflags_t);

  localparam type x_commit_t =
      `X_COMMIT_T(CVA6Cfg, hartid_t, id_t);

  localparam type x_result_t =
      `X_RESULT_T(CVA6Cfg, hartid_t, id_t, writeregflags_t);

  localparam type cvxif_req_t =
      `CVXIF_REQ_T(
        CVA6Cfg,
        x_compressed_req_t,
        x_issue_req_t,
        x_register_t,
        x_commit_t
      );

  localparam type cvxif_resp_t =
      `CVXIF_RESP_T(
        CVA6Cfg,
        x_compressed_resp_t,
        x_issue_resp_t,
        x_result_t
      );

  // ------------------------------------------------------------
  // AXI/NOC types - same definitions used by current cva6.sv
  // ------------------------------------------------------------
  localparam type axi_ar_chan_t = struct packed {
    logic [CVA6Cfg.AxiIdWidth-1:0]   id;
    logic [CVA6Cfg.AxiAddrWidth-1:0] addr;
    axi_pkg::len_t                   len;
    axi_pkg::size_t                  size;
    axi_pkg::burst_t                 burst;
    logic                            lock;
    axi_pkg::cache_t                 cache;
    axi_pkg::prot_t                  prot;
    axi_pkg::qos_t                   qos;
    axi_pkg::region_t                region;
    logic [CVA6Cfg.AxiUserWidth-1:0] user;
  };

  localparam type axi_aw_chan_t = struct packed {
    logic [CVA6Cfg.AxiIdWidth-1:0]   id;
    logic [CVA6Cfg.AxiAddrWidth-1:0] addr;
    axi_pkg::len_t                   len;
    axi_pkg::size_t                  size;
    axi_pkg::burst_t                 burst;
    logic                            lock;
    axi_pkg::cache_t                 cache;
    axi_pkg::prot_t                  prot;
    axi_pkg::qos_t                   qos;
    axi_pkg::region_t                region;
    axi_pkg::atop_t                  atop;
    logic [CVA6Cfg.AxiUserWidth-1:0] user;
  };

  localparam type axi_w_chan_t = struct packed {
    logic [CVA6Cfg.AxiDataWidth-1:0] data;
    logic [(CVA6Cfg.AxiDataWidth/8)-1:0] strb;
    logic last;
    logic [CVA6Cfg.AxiUserWidth-1:0] user;
  };

  localparam type b_chan_t = struct packed {
    logic [CVA6Cfg.AxiIdWidth-1:0] id;
    axi_pkg::resp_t resp;
    logic [CVA6Cfg.AxiUserWidth-1:0] user;
  };

  localparam type r_chan_t = struct packed {
    logic [CVA6Cfg.AxiIdWidth-1:0] id;
    logic [CVA6Cfg.AxiDataWidth-1:0] data;
    axi_pkg::resp_t resp;
    logic last;
    logic [CVA6Cfg.AxiUserWidth-1:0] user;
  };

  localparam type noc_req_t = struct packed {
    axi_aw_chan_t aw;
    logic         aw_valid;
    axi_w_chan_t  w;
    logic         w_valid;
    logic         b_ready;
    axi_ar_chan_t ar;
    logic         ar_valid;
    logic         r_ready;
  };

  localparam type noc_resp_t = struct packed {
    logic    aw_ready;
    logic    ar_ready;
    logic    w_ready;
    logic    b_valid;
    b_chan_t b;
    logic    r_valid;
    r_chan_t r;
  };

  // ------------------------------------------------------------
  // Internal CVXIF / AXI signals
  // ------------------------------------------------------------
  cvxif_req_t  cvxif_req;
  cvxif_resp_t cvxif_resp; //this is a struct from CVA repo <========

  noc_req_t    noc_req;
  noc_resp_t   noc_resp;

  // ------------------------------------------------------------
  // CVA6
  // ------------------------------------------------------------
  cva6 #(
    .CVA6Cfg              (CVA6Cfg),
    .cvxif_req_t          (cvxif_req_t),
    .cvxif_resp_t         (cvxif_resp_t),
    .noc_req_t            (noc_req_t),
    .noc_resp_t           (noc_resp_t)
  ) u_cva6 (
    .clk_i                (clk_i),
    .rst_ni               (rst_ni),
    .boot_addr_i          (boot_addr_i),
    .hart_id_i            (hart_id_i),
    .irq_i                (irq_i),
    .ipi_i                (ipi_i),
    .time_irq_i           (time_irq_i),
    .debug_req_i          (debug_req_i),
    .rvfi_probes_o        (),
    .cvxif_req_o          (cvxif_req),
    .cvxif_resp_i         (cvxif_resp),
    .noc_req_o            (noc_req),
    .noc_resp_i           (noc_resp)
  );

  // ------------------------------------------------------------
  // CVXIF: CVA6 -> TinyGPU
  // ------------------------------------------------------------
  assign cvxif_issue_valid_o = cvxif_req.issue_valid;
  assign cvxif_issue_instr_o = cvxif_req.issue_req.instr;
  assign cvxif_issue_id_o    = cvxif_req.issue_req.id;

  assign cvxif_commit_valid_o = cvxif_req.commit_valid;
  assign cvxif_commit_id_o    = cvxif_req.commit.id;
  assign cvxif_commit_kill_o  = cvxif_req.commit.commit_kill;

  // Current register channel
  assign cvxif_issue_rs1_o = cvxif_req.register.rs[0];

  // ------------------------------------------------------------
  // CVXIF: TinyGPU -> CVA6
  // ------------------------------------------------------------
  always_comb begin
    cvxif_resp = '0;

    cvxif_resp.issue_ready = 1'b1;
    cvxif_resp.issue_resp.accept = cvxif_issue_accept_i;
    cvxif_resp.issue_resp.writeback[0] = cvxif_issue_writeback_i;

    cvxif_resp.result_valid = cvxif_result_valid_i;
    cvxif_resp.result.id    = cvxif_result_id_i;
    cvxif_resp.result.data  = cvxif_result_data_i;
    cvxif_resp.result.rd    = cvxif_result_rd_i;
    cvxif_resp.result.we[0] = cvxif_result_we_i;

    cvxif_result_ready_o = cvxif_req.result_ready;
  end

  // ------------------------------------------------------------
  // AXI / NOC pass-through (full channels)
  // ------------------------------------------------------------
  assign noc_aw_id_o     = noc_req.aw.id;
  assign noc_aw_addr_o   = noc_req.aw.addr;
  assign noc_aw_len_o    = noc_req.aw.len;
  assign noc_aw_size_o   = noc_req.aw.size;
  assign noc_aw_burst_o  = noc_req.aw.burst;
  assign noc_aw_lock_o   = noc_req.aw.lock;
  assign noc_aw_cache_o  = noc_req.aw.cache;
  assign noc_aw_prot_o   = noc_req.aw.prot;
  assign noc_aw_qos_o    = noc_req.aw.qos;
  assign noc_aw_region_o = noc_req.aw.region;
  assign noc_aw_atop_o   = noc_req.aw.atop;
  assign noc_aw_user_o   = noc_req.aw.user;
  assign noc_aw_valid_o  = noc_req.aw_valid;

  assign noc_ar_id_o     = noc_req.ar.id;
  assign noc_ar_addr_o   = noc_req.ar.addr;
  assign noc_ar_len_o    = noc_req.ar.len;
  assign noc_ar_size_o   = noc_req.ar.size;
  assign noc_ar_burst_o  = noc_req.ar.burst;
  assign noc_ar_lock_o   = noc_req.ar.lock;
  assign noc_ar_cache_o  = noc_req.ar.cache;
  assign noc_ar_prot_o   = noc_req.ar.prot;
  assign noc_ar_qos_o    = noc_req.ar.qos;
  assign noc_ar_region_o = noc_req.ar.region;
  assign noc_ar_user_o   = noc_req.ar.user;
  assign noc_ar_valid_o  = noc_req.ar_valid;

  assign noc_w_data_o  = noc_req.w.data;
  assign noc_w_strb_o  = noc_req.w.strb;
  assign noc_w_last_o  = noc_req.w.last;
  assign noc_w_user_o  = noc_req.w.user;
  assign noc_w_valid_o = noc_req.w_valid;

  assign noc_b_ready_o = noc_req.b_ready;
  assign noc_r_ready_o = noc_req.r_ready;

  assign noc_resp.aw_ready = noc_aw_ready_i;
  assign noc_resp.ar_ready = noc_ar_ready_i;
  assign noc_resp.w_ready  = noc_w_ready_i;

  assign noc_resp.b_valid = noc_b_valid_i;
  assign noc_resp.b.id    = noc_b_id_i;
  assign noc_resp.b.resp  = noc_b_resp_i;
  assign noc_resp.b.user  = noc_b_user_i;

  assign noc_resp.r_valid = noc_r_valid_i;
  assign noc_resp.r.id    = noc_r_id_i;
  assign noc_resp.r.data  = noc_r_data_i;
  assign noc_resp.r.resp  = noc_r_resp_i;
  assign noc_resp.r.last  = noc_r_last_i;
  assign noc_resp.r.user  = noc_r_user_i;

endmodule
