`timescale 1ns / 1ps
// FPGA top level for CVA6 + TinyGPU.

module fpga_top (
    input  wire clk_i,
    input  wire rst_i,
    input  wire [11:0] ps7_ar_id,
    input  wire [31:0] ps7_ar_addr,
    input  wire [3:0] ps7_ar_len,
    input  wire ps7_ar_valid,
    output wire ps7_ar_ready,

    output wire [11:0] ps7_r_id,
    output wire [31:0] ps7_r_data,
    output wire [1:0] ps7_r_resp,
    output wire ps7_r_last,
    output wire ps7_r_valid,
    input  wire ps7_r_ready
);

  (* ASYNC_REG = "TRUE" *) reg [1:0] rst_sync_q;
  wire rst_ni = rst_sync_q[1];

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) rst_sync_q <= 2'b00;
    else       rst_sync_q <= {rst_sync_q[0], 1'b1};
  end

  //NOC/AXI4 CVA6+TinyGPU's one shared bus
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

  // ---------------- Debug-visible signals ----------------
  // Top-level bus signals worth marking for an ILA are tagged right here,
  // since they're already flat wires at this scope. Deeper internal
  // signals (u_soc.u_gpu.fsm_i.state, u_soc.u_gpu.vd_0_0, etc. -- the
  // exact same ones hierarchically peeked at throughout simulation
  // bring-up) are NOT hand-wired up through the hierarchy here -- that's
  // fragile against a mixed Verilog/SystemVerilog hierarchy and
  // unnecessary. Mark those directly on the post-synthesis netlist
  // instead (Tools -> Set Up Debug in the GUI, or `mark_debug_signals.tcl`
  // -- see the FPGA bring-up notes for the exact commands) -- Vivado can
  // reach any net at any depth that way without RTL changes.
  (* mark_debug = "true" *) wire        dbg_noc_ar_valid = noc_ar_valid;
  (* mark_debug = "true" *) wire        dbg_noc_r_valid  = noc_r_valid;
  (* mark_debug = "true" *) wire        dbg_noc_aw_valid = noc_aw_valid;
  (* mark_debug = "true" *) wire        dbg_noc_b_valid  = noc_b_valid;
  (* mark_debug = "true" *) wire [63:0] dbg_noc_r_data   = noc_r_data;
  (* mark_debug = "true" *) wire [63:0] dbg_noc_w_data   = noc_w_data;

  cva6_tinygpu_soc u_soc (
    .clk        (clk_i),
    .rst_ni     (rst_ni),
    .boot_addr  (64'h0000_0000_8000_0000),
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

  // ---------------- On-chip BRAM memory ----------------
  // Real, synthesizable memory backend - see axi4_bram_slave.v. Preloaded
  // with the same boot program + matrices tb_cva6_boot.v used, via
  // $readmemh (boot_image.hex), baked into the bitstream at synthesis
  // time. No DDR needed for this first bring-up.
  axi4_bram_slave #(
    .ID_WIDTH   (5),
    .ADDR_WIDTH (64),
    .DATA_WIDTH (64),
    .MEM_WORDS  (8192),
    .INIT_FILE  ("boot_image.hex")
  ) u_mem (
    .clk(clk_i), .rst_ni(rst_ni),
    .ar_id(noc_ar_id), .ar_addr(noc_ar_addr), .ar_len(noc_ar_len),
    .ar_valid(noc_ar_valid), .ar_ready(noc_ar_ready),
    .r_id(noc_r_id), .r_data(noc_r_data), .r_resp(noc_r_resp),
    .r_last(noc_r_last), .r_valid(noc_r_valid), .r_ready(noc_r_ready),
    .aw_id(noc_aw_id), .aw_addr(noc_aw_addr),
    .aw_valid(noc_aw_valid), .aw_ready(noc_aw_ready),
    .w_data(noc_w_data), .w_strb(noc_w_strb), .w_last(noc_w_last),
    .w_valid(noc_w_valid), .w_ready(noc_w_ready),
    .b_id(noc_b_id), .b_resp(noc_b_resp), .b_valid(noc_b_valid), .b_ready(noc_b_ready),

    .ar2_id(ps7_ar_id), .ar2_addr(ps7_ar_addr), .ar2_len(ps7_ar_len),
    .ar2_valid(ps7_ar_valid), .ar2_ready(ps7_ar_ready),
    .r2_id(ps7_r_id), .r2_data(ps7_r_data), .r2_resp(ps7_r_resp),
    .r2_last(ps7_r_last), .r2_valid(ps7_r_valid), .r2_ready(ps7_r_ready)
  );

endmodule
