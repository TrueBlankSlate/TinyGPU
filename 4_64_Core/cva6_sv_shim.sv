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

  // AXI / NoC interface (full AXI4, flattened for the plain-Verilog top).
  // ID width is CVA6Cfg.AxiIdWidth+1: this is the ARBITRATED (post-axi_mux)
  // bus shared between CVA6's own traffic and TinyGPU's, and axi_mux widens
  // the ID by clog2(NoSlvPorts)=1 bit to disambiguate the two masters'
  // responses. CVA6 itself still only ever sees AxiIdWidth-wide IDs
  // internally -- the extra bit only exists on this shared, external side.
  output logic [CVA6Cfg.AxiIdWidth:0]       noc_aw_id_o,
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

  output logic [CVA6Cfg.AxiIdWidth:0]       noc_ar_id_o,
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

  input  logic [CVA6Cfg.AxiIdWidth:0]       noc_b_id_i,
  input  logic [1:0]                        noc_b_resp_i,
  input  logic [CVA6Cfg.AxiUserWidth-1:0]   noc_b_user_i,
  input  logic                              noc_b_valid_i,
  output logic                              noc_b_ready_o,

  input  logic [CVA6Cfg.AxiIdWidth:0]       noc_r_id_i,
  input  logic [CVA6Cfg.AxiDataWidth-1:0]   noc_r_data_i,
  input  logic [1:0]                        noc_r_resp_i,
  input  logic                              noc_r_last_i,
  input  logic [CVA6Cfg.AxiUserWidth-1:0]   noc_r_user_i,
  input  logic                              noc_r_valid_i,
  output logic                              noc_r_ready_o,

  // TinyGPU's own real AXI4 read master -- arbitered onto the SAME
  // noc_* bus above via axi_mux, not a separate memory path. Only AR/R
  // are needed since TinyGPU never writes to system memory. ID width here
  // is CVA6Cfg.AxiIdWidth (pre-arbitration, matching CVA6's own internal
  // width) -- axi_mux is what widens it onto the shared noc_* side.
  input  logic [CVA6Cfg.AxiIdWidth-1:0]   gpu_ar_id_i,
  input  logic [CVA6Cfg.AxiAddrWidth-1:0] gpu_ar_addr_i,
  input  logic [7:0]                      gpu_ar_len_i,
  input  logic [2:0]                      gpu_ar_size_i,
  input  logic [1:0]                      gpu_ar_burst_i,
  input  logic                            gpu_ar_valid_i,
  output logic                            gpu_ar_ready_o,

  output logic [CVA6Cfg.AxiIdWidth-1:0]   gpu_r_id_o,
  output logic [CVA6Cfg.AxiDataWidth-1:0] gpu_r_data_o,
  output logic [1:0]                      gpu_r_resp_o,
  output logic                            gpu_r_last_o,
  output logic                            gpu_r_valid_o,
  input  logic                            gpu_r_ready_i,

  // TinyGPU's own real AXI4 write master -- for vse64.v writeback, same
  // arbitration story as the read master above.
  input  logic [CVA6Cfg.AxiIdWidth-1:0]   gpu_aw_id_i,
  input  logic [CVA6Cfg.AxiAddrWidth-1:0] gpu_aw_addr_i,
  input  logic [7:0]                      gpu_aw_len_i,
  input  logic [2:0]                      gpu_aw_size_i,
  input  logic [1:0]                      gpu_aw_burst_i,
  input  logic                            gpu_aw_valid_i,
  output logic                            gpu_aw_ready_o,

  input  logic [CVA6Cfg.AxiDataWidth-1:0]     gpu_w_data_i,
  input  logic [(CVA6Cfg.AxiDataWidth/8)-1:0] gpu_w_strb_i,
  input  logic                                gpu_w_last_i,
  input  logic                                gpu_w_valid_i,
  output logic                                gpu_w_ready_o,

  output logic [CVA6Cfg.AxiIdWidth-1:0]   gpu_b_id_o,
  output logic [1:0]                      gpu_b_resp_o,
  output logic                            gpu_b_valid_o,
  input  logic                            gpu_b_ready_i,

  // CVXIF -> TinyGPU
  output logic                    cvxif_issue_valid_o, //is the instruction valid to send? <=====
  output logic [31:0]             cvxif_issue_instr_o, //issue instruction <====
  output logic [CVA6Cfg.X_ID_WIDTH-1:0] cvxif_issue_id_o,
  output logic [CVA6Cfg.XLEN-1:0] cvxif_issue_rs1_o, //<===== base address

  // TinyGPU -> CVXIF
  input  logic                    cvxif_issue_ready_i, // is TinyGPU free to accept a new instruction (state==IDLE)?
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
  // Widened (post-axi_mux) AXI/NOC types -- ID field is one bit wider
  // than the slave-side types above, per axi_mux's own widening rule
  // (SlvAxiIDWidth + clog2(NoSlvPorts), NoSlvPorts=2 here). These describe
  // the single arbitrated bus shared between CVA6 and TinyGPU that
  // actually leaves this module as noc_*_o/noc_*_i.
  // ------------------------------------------------------------
  localparam type mst_axi_ar_chan_t = struct packed {
    logic [CVA6Cfg.AxiIdWidth:0]     id;
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

  localparam type mst_axi_aw_chan_t = struct packed {
    logic [CVA6Cfg.AxiIdWidth:0]     id;
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

  localparam type mst_b_chan_t = struct packed {
    logic [CVA6Cfg.AxiIdWidth:0] id;
    axi_pkg::resp_t resp;
    logic [CVA6Cfg.AxiUserWidth-1:0] user;
  };

  localparam type mst_r_chan_t = struct packed {
    logic [CVA6Cfg.AxiIdWidth:0] id;
    logic [CVA6Cfg.AxiDataWidth-1:0] data;
    axi_pkg::resp_t resp;
    logic last;
    logic [CVA6Cfg.AxiUserWidth-1:0] user;
  };

  localparam type mst_noc_req_t = struct packed {
    mst_axi_aw_chan_t aw;
    logic             aw_valid;
    axi_w_chan_t      w;
    logic             w_valid;
    logic             b_ready;
    mst_axi_ar_chan_t ar;
    logic             ar_valid;
    logic             r_ready;
  };

  localparam type mst_noc_resp_t = struct packed {
    logic        aw_ready;
    logic        ar_ready;
    logic        w_ready;
    logic        b_valid;
    mst_b_chan_t b;
    logic        r_valid;
    mst_r_chan_t r;
  };

  // ------------------------------------------------------------
  // Internal CVXIF / AXI signals
  // ------------------------------------------------------------
  cvxif_req_t  cvxif_req;
  cvxif_resp_t cvxif_resp; //this is a struct from CVA repo <========

  noc_req_t    noc_req;    // CVA6's own request (slave port 0 into axi_mux)
  noc_resp_t   noc_resp;

  noc_req_t    gpu_req;    // TinyGPU's request (slave port 1 into axi_mux)
  noc_resp_t   gpu_resp;

  mst_noc_req_t  mst_noc_req;  // single arbitrated bus (leaves this module)
  mst_noc_resp_t mst_noc_resp;

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
  // TinyGPU's real AXI4 read+write request, packed into the same struct
  // type CVA6 uses. AW/W/B carry vse64.v's writeback traffic now.
  // ------------------------------------------------------------
  always_comb begin
    gpu_req = '0;
    gpu_req.ar.id    = gpu_ar_id_i;
    gpu_req.ar.addr  = gpu_ar_addr_i;
    gpu_req.ar.len   = gpu_ar_len_i;
    gpu_req.ar.size  = gpu_ar_size_i;
    gpu_req.ar.burst = gpu_ar_burst_i;
    gpu_req.ar_valid = gpu_ar_valid_i;
    gpu_req.r_ready  = gpu_r_ready_i;

    gpu_req.aw.id    = gpu_aw_id_i;
    gpu_req.aw.addr  = gpu_aw_addr_i;
    gpu_req.aw.len   = gpu_aw_len_i;
    gpu_req.aw.size  = gpu_aw_size_i;
    gpu_req.aw.burst = gpu_aw_burst_i;
    gpu_req.aw_valid = gpu_aw_valid_i;

    gpu_req.w.data   = gpu_w_data_i;
    gpu_req.w.strb   = gpu_w_strb_i;
    gpu_req.w.last   = gpu_w_last_i;
    gpu_req.w_valid  = gpu_w_valid_i;

    gpu_req.b_ready  = gpu_b_ready_i;
  end

  assign gpu_ar_ready_o = gpu_resp.ar_ready;
  assign gpu_r_id_o     = gpu_resp.r.id;
  assign gpu_r_data_o   = gpu_resp.r.data;
  assign gpu_r_resp_o   = gpu_resp.r.resp;
  assign gpu_r_last_o   = gpu_resp.r.last;
  assign gpu_r_valid_o  = gpu_resp.r_valid;

  assign gpu_aw_ready_o = gpu_resp.aw_ready;
  assign gpu_w_ready_o  = gpu_resp.w_ready;
  assign gpu_b_id_o     = gpu_resp.b.id;
  assign gpu_b_resp_o   = gpu_resp.b.resp;
  assign gpu_b_valid_o  = gpu_resp.b_valid;

  // ------------------------------------------------------------
  // Arbiter: CVA6's own noc_req (slave 0) + TinyGPU's gpu_req (slave 1)
  // share one physical memory port (mst_noc_req/mst_noc_resp) instead of
  // being two separate, unconnected masters.
  // ------------------------------------------------------------
  noc_req_t  [1:0] axi_mux_slv_reqs;
  noc_resp_t [1:0] axi_mux_slv_resps;
  assign axi_mux_slv_reqs[0] = noc_req;
  assign axi_mux_slv_reqs[1] = gpu_req;
  assign noc_resp = axi_mux_slv_resps[0];
  assign gpu_resp = axi_mux_slv_resps[1];

  axi_mux #(
    .SlvAxiIDWidth (CVA6Cfg.AxiIdWidth),
    .slv_aw_chan_t (axi_aw_chan_t),
    .mst_aw_chan_t (mst_axi_aw_chan_t),
    .w_chan_t      (axi_w_chan_t),
    .slv_b_chan_t  (b_chan_t),
    .mst_b_chan_t  (mst_b_chan_t),
    .slv_ar_chan_t (axi_ar_chan_t),
    .mst_ar_chan_t (mst_axi_ar_chan_t),
    .slv_r_chan_t  (r_chan_t),
    .mst_r_chan_t  (mst_r_chan_t),
    .slv_req_t     (noc_req_t),
    .slv_resp_t    (noc_resp_t),
    .mst_req_t     (mst_noc_req_t),
    .mst_resp_t    (mst_noc_resp_t),
    .NoSlvPorts    (2)
  ) i_axi_mux (
    .clk_i       (clk_i),
    .rst_ni      (rst_ni),
    .test_i      (1'b0),
    .slv_reqs_i  (axi_mux_slv_reqs),
    .slv_resps_o (axi_mux_slv_resps),
    .mst_req_o   (mst_noc_req),
    .mst_resp_i  (mst_noc_resp)
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

    // Must reflect TinyGPU's real busy/idle state, not a hardcoded 1 --
    // cvxif_issue_register_commit_if_driver.sv commits unconditionally
    // as soon as issue_valid_o && issue_ready_i, regardless of accept, so
    // a stuck-high issue_ready would let CVA6 consider a second cvxif
    // instruction (e.g. vmacc) "committed" while TinyGPU is still mid-
    // burst on the first one (vle64's 32-beat AXI4 load), silently
    // dropping it.
    cvxif_resp.issue_ready = cvxif_issue_ready_i;
    cvxif_resp.issue_resp.accept = cvxif_issue_accept_i;
    cvxif_resp.issue_resp.writeback[0] = cvxif_issue_writeback_i;
    // Tell CVA6's issue_read_operands we DO need rs1's actual register
    // value (vle64.v's base address comes from x[rs1]). Without this,
    // issue_read_operands.sv (line ~616) treats register_read[0]==0 as
    // "coprocessor doesn't need rs1" and strips the RAW-hazard stall/
    // forward for it, so cvxif_req.register.rs[0] reads whatever is
    // sitting in the architectural regfile at issue time instead of the
    // freshly-forwarded value -- e.g. a preceding `lui x1,...` hasn't
    // committed yet, and rs1 reads back 0.
    cvxif_resp.issue_resp.register_read[0] = 1'b1;
    cvxif_resp.register_ready = 1'b1;

    cvxif_resp.result_valid = cvxif_result_valid_i;
    cvxif_resp.result.id    = cvxif_result_id_i;
    cvxif_resp.result.data  = cvxif_result_data_i;
    cvxif_resp.result.rd    = cvxif_result_rd_i;
    cvxif_resp.result.we[0] = cvxif_result_we_i;

    cvxif_result_ready_o = cvxif_req.result_ready;
  end

  // ------------------------------------------------------------
  // AXI / NOC pass-through (full channels) -- this is now the ARBITRATED
  // bus (mst_noc_req/mst_noc_resp from axi_mux above), shared by CVA6 and
  // TinyGPU, not CVA6's raw noc_req/noc_resp directly.
  // ------------------------------------------------------------
  assign noc_aw_id_o     = mst_noc_req.aw.id;
  assign noc_aw_addr_o   = mst_noc_req.aw.addr;
  assign noc_aw_len_o    = mst_noc_req.aw.len;
  assign noc_aw_size_o   = mst_noc_req.aw.size;
  assign noc_aw_burst_o  = mst_noc_req.aw.burst;
  assign noc_aw_lock_o   = mst_noc_req.aw.lock;
  assign noc_aw_cache_o  = mst_noc_req.aw.cache;
  assign noc_aw_prot_o   = mst_noc_req.aw.prot;
  assign noc_aw_qos_o    = mst_noc_req.aw.qos;
  assign noc_aw_region_o = mst_noc_req.aw.region;
  assign noc_aw_atop_o   = mst_noc_req.aw.atop;
  assign noc_aw_user_o   = mst_noc_req.aw.user;
  assign noc_aw_valid_o  = mst_noc_req.aw_valid;

  assign noc_ar_id_o     = mst_noc_req.ar.id;
  assign noc_ar_addr_o   = mst_noc_req.ar.addr;
  assign noc_ar_len_o    = mst_noc_req.ar.len;
  assign noc_ar_size_o   = mst_noc_req.ar.size;
  assign noc_ar_burst_o  = mst_noc_req.ar.burst;
  assign noc_ar_lock_o   = mst_noc_req.ar.lock;
  assign noc_ar_cache_o  = mst_noc_req.ar.cache;
  assign noc_ar_prot_o   = mst_noc_req.ar.prot;
  assign noc_ar_qos_o    = mst_noc_req.ar.qos;
  assign noc_ar_region_o = mst_noc_req.ar.region;
  assign noc_ar_user_o   = mst_noc_req.ar.user;
  assign noc_ar_valid_o  = mst_noc_req.ar_valid;

  assign noc_w_data_o  = mst_noc_req.w.data;
  assign noc_w_strb_o  = mst_noc_req.w.strb;
  assign noc_w_last_o  = mst_noc_req.w.last;
  assign noc_w_user_o  = mst_noc_req.w.user;
  assign noc_w_valid_o = mst_noc_req.w_valid;

  assign noc_b_ready_o = mst_noc_req.b_ready;
  assign noc_r_ready_o = mst_noc_req.r_ready;

  assign mst_noc_resp.aw_ready = noc_aw_ready_i;
  assign mst_noc_resp.ar_ready = noc_ar_ready_i;
  assign mst_noc_resp.w_ready  = noc_w_ready_i;

  assign mst_noc_resp.b_valid = noc_b_valid_i;
  assign mst_noc_resp.b.id    = noc_b_id_i;
  assign mst_noc_resp.b.resp  = noc_b_resp_i;
  assign mst_noc_resp.b.user  = noc_b_user_i;

  assign mst_noc_resp.r_valid = noc_r_valid_i;
  assign mst_noc_resp.r.id    = noc_r_id_i;
  assign mst_noc_resp.r.data  = noc_r_data_i;
  assign mst_noc_resp.r.resp  = noc_r_resp_i;
  assign mst_noc_resp.r.last  = noc_r_last_i;
  assign mst_noc_resp.r.user  = noc_r_user_i;

endmodule
