`timescale 1ns / 1ps
// CV-X-IF boundary module.
// Receives cvxif_req_o fields from CVA6, drives cvxif_resp_i fields back.
// Instantiates tinygpu_fsm and fourc_1_wrapper.
// No scalar writeback to CVA6 register file (vec arith results stay in GPU VRF).
module tinygpu_cvxif_wrap (
    input  wire        clk,
    input  wire        rst_ni,         // active-low

    // ---- CV-X-IF issue channel (from CVA6 cvxif_req_o) ----
    input  wire        issue_valid,
    input  wire [31:0] issue_instr,
    input  wire [2:0]  issue_id,
    input  wire [63:0] issue_rs1,      // scalar rs1 = vle64 base address

    // ---- CV-X-IF issue response (to CVA6 cvxif_resp_i) ----
    output wire        issue_ready,
    output wire        issue_accept,
    output wire        issue_writeback, // always 0: no scalar writeback

    // ---- CV-X-IF commit channel (from CVA6 cvxif_req_o) ----
    input  wire        commit_valid,
    input  wire [2:0]  commit_id,
    input  wire        commit_kill,

    // ---- CV-X-IF result channel (to CVA6 cvxif_resp_i) ----
    input  wire        result_ready,
    output wire        result_valid,
    output wire [2:0]  result_id,
    output wire [63:0] result_data,    // tied 0, no scalar result
    output wire [4:0]  result_rd,      // tied 0
    output wire        result_we,      // tied 0

    // ---- Real AXI4 read master (for vle64 loads) -- same channel shape
    // CVA6's own noc_ar_*/noc_r_* use, so it can be arbitered onto the
    // same physical memory instead of driving a separate fake protocol ----
    output wire [3:0]  ar_id,
    output wire [63:0] ar_addr,
    output wire [7:0]  ar_len,
    output wire [2:0]  ar_size,
    output wire [1:0]  ar_burst,
    output wire        ar_valid,
    input  wire        ar_ready,
    input  wire [3:0]  r_id,
    input  wire [63:0] r_data,
    input  wire [1:0]  r_resp,
    input  wire        r_last,
    input  wire        r_valid,
    output wire        r_ready,

    // ---- Real AXI4 write master (for vse64.v writeback) -- same shape,
    // arbitered onto the same shared bus ----
    output wire [3:0]  aw_id,
    output wire [63:0] aw_addr,
    output wire [7:0]  aw_len,
    output wire [2:0]  aw_size,
    output wire [1:0]  aw_burst,
    output wire        aw_valid,
    input  wire        aw_ready,
    output wire [63:0] w_data,
    output wire [7:0]  w_strb,
    output wire        w_last,
    output wire        w_valid,
    input  wire        w_ready,
    input  wire [3:0]  b_id,
    input  wire [1:0]  b_resp,
    input  wire        b_valid,
    output wire        b_ready
);

// No scalar writeback or result data — GPU keeps results internally // <=========
assign issue_writeback = 1'b0;
assign result_data     = 64'd0;
assign result_rd       = 5'd0;
assign result_we       = 1'b0;

// Internal wires from FSM to fourc_1_wrapper
wire [31:0]  fsm_instruction;
wire [2047:0] fsm_w_data;
wire          fsm_we_0;
wire          fsm_we_1;
wire [1:0]    fsm_pass; //for vmacc.vv <=====
wire          fsm_acc_rst;
wire          fsm_l3_ready;

// Packed last-compute-result, for vse64.v's writeback (see writeback.v)
wire [1023:0] fsm_wb_data;

tinygpu_fsm fsm_i (
    .clk            (clk),
    .rst_ni         (rst_ni),
    // issue
    .issue_valid    (issue_valid),
    .issue_instr    (issue_instr),
    .issue_id       (issue_id),
    .issue_rs1      (issue_rs1),
    .issue_ready    (issue_ready),
    .issue_accept   (issue_accept),
    // commit
    .commit_valid   (commit_valid),
    .commit_id      (commit_id),
    .commit_kill    (commit_kill),
    // result
    .result_ready   (result_ready),
    .result_valid   (result_valid),
    .result_id      (result_id),
    // AXI read (vle64.v)
    .ar_id          (ar_id),
    .ar_addr        (ar_addr),
    .ar_len         (ar_len),
    .ar_size        (ar_size),
    .ar_burst       (ar_burst),
    .ar_valid       (ar_valid),
    .ar_ready       (ar_ready),
    .r_id           (r_id),
    .r_data         (r_data),
    .r_resp         (r_resp),
    .r_last         (r_last),
    .r_valid        (r_valid),
    .r_ready        (r_ready),
    // AXI write (vse64.v)
    .aw_id          (aw_id),
    .aw_addr        (aw_addr),
    .aw_len         (aw_len),
    .aw_size        (aw_size),
    .aw_burst       (aw_burst),
    .aw_valid       (aw_valid),
    .aw_ready       (aw_ready),
    .w_data         (w_data),
    .w_strb         (w_strb),
    .w_last         (w_last),
    .w_valid        (w_valid),
    .w_ready        (w_ready),
    .b_id           (b_id),
    .b_resp         (b_resp),
    .b_valid        (b_valid),
    .b_ready        (b_ready),
    .wb_data        (fsm_wb_data),
    // GPU controls
    .instruction_0  (fsm_instruction),
    .w_data_0       (fsm_w_data),
    .we_0           (fsm_we_0),
    .we_1           (fsm_we_1),
    .pass_0         (fsm_pass),
    .acc_rst_out    (fsm_acc_rst),
    .l3_ready       (fsm_l3_ready)
);

// vd outputs stay internal (no scalar writeback to CVA6's GPRs), but now
// feed writeback.v so vse64.v can push the last compute result out to
// DRAM over TinyGPU's own AXI4 write master.
wire [63:0] vd_0_0, vd_0_1, vd_0_2, vd_0_3;
wire [63:0] vd_1_0, vd_1_1, vd_1_2, vd_1_3;
wire [63:0] vd_2_0, vd_2_1, vd_2_2, vd_2_3;
wire [63:0] vd_3_0, vd_3_1, vd_3_2, vd_3_3;

fourc_1_wrapper gpu_i (
    .clk_0          (clk),
    .rst_0          (~rst_ni),
    .acc_rst_0_0    (fsm_acc_rst),
    .instruction_0  (fsm_instruction),
    .w_data_0       (fsm_w_data),
    .we_0           (fsm_we_0),
    .we_1           (fsm_we_1),
    .pass_0         (fsm_pass),
    .l3_ready       (fsm_l3_ready),
    .vd_0_0         (vd_0_0), .vd_0_1(vd_0_1), .vd_0_2(vd_0_2), .vd_0_3(vd_0_3),
    .vd_1_0         (vd_1_0), .vd_1_1(vd_1_1), .vd_1_2(vd_1_2), .vd_1_3(vd_1_3),
    .vd_2_0         (vd_2_0), .vd_2_1(vd_2_1), .vd_2_2(vd_2_2), .vd_2_3(vd_2_3),
    .vd_3_0         (vd_3_0), .vd_3_1(vd_3_1), .vd_3_2(vd_3_2), .vd_3_3(vd_3_3)
);

// Row-major pack: c0..c15 = vd_0_0..vd_3_3 = C[0][0]..C[3][3].
writeback wb_i (
    .c0  (vd_0_0), .c1  (vd_0_1), .c2  (vd_0_2), .c3  (vd_0_3),
    .c4  (vd_1_0), .c5  (vd_1_1), .c6  (vd_1_2), .c7  (vd_1_3),
    .c8  (vd_2_0), .c9  (vd_2_1), .c10 (vd_2_2), .c11 (vd_2_3),
    .c12 (vd_3_0), .c13 (vd_3_1), .c14 (vd_3_2), .c15 (vd_3_3),
    .c_out (fsm_wb_data)
);

endmodule