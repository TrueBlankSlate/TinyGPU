//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Thu Aug 13 16:23:46 2026
//Host        : AthOS-II running 64-bit major release  (build 9200)
//Command     : generate_target design_1.bd
//Design      : design_1
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=design_1,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=9,numReposBlks=9,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "design_1.hwdef" *) 
module design_1
   (acc_rst_0,
    clk_0,
    func3_0,
    instr_id_0,
    mat_a_0,
    mat_b_0,
    pass_0,
    rst_0,
    vd_0,
    vd_1,
    vd_2,
    vd_3,
    we_0);
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.ACC_RST_0 RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.ACC_RST_0, INSERT_VIP 0, POLARITY ACTIVE_HIGH" *) input acc_rst_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CLK_0 CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CLK_0, ASSOCIATED_RESET rst_0, CLK_DOMAIN design_1_clk_0, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input clk_0;
  input [2:0]func3_0;
  input [5:0]instr_id_0;
  input [255:0]mat_a_0;
  input [255:0]mat_b_0;
  input [1:0]pass_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.RST_0 RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.RST_0, INSERT_VIP 0, POLARITY ACTIVE_HIGH" *) input rst_0;
  output [63:0]vd_0;
  output [63:0]vd_1;
  output [63:0]vd_2;
  output [63:0]vd_3;
  input we_0;

  wire [63:0]RegisterFile_0_vs1_out;
  wire [63:0]RegisterFile_0_vs2_out;
  wire [63:0]RegisterFile_1_vs1_out;
  wire [63:0]RegisterFile_1_vs2_out;
  wire [63:0]RegisterFile_2_vs1_out;
  wire [63:0]RegisterFile_2_vs2_out;
  wire [63:0]RegisterFile_3_vs1_out;
  wire [63:0]RegisterFile_3_vs2_out;
  wire acc_rst_0;
  wire [63:0]cache_0_a0;
  wire [63:0]cache_0_a1;
  wire [63:0]cache_0_a2;
  wire [63:0]cache_0_a3;
  wire [63:0]cache_0_b0;
  wire [63:0]cache_0_b1;
  wire [63:0]cache_0_b2;
  wire [63:0]cache_0_b3;
  wire clk_0;
  wire [2:0]func3_0;
  wire [5:0]instr_id_0;
  wire [255:0]mat_a_0;
  wire [255:0]mat_b_0;
  wire [1:0]pass_0;
  wire rst_0;
  wire [63:0]vd_0;
  wire [63:0]vd_1;
  wire [63:0]vd_2;
  wire [63:0]vd_3;
  wire we_0;

  // Raw per-ALU products (element-wise A[pass][k] * B[k][core]).
  wire [63:0] alu_vd_0, alu_vd_1, alu_vd_2, alu_vd_3;

  // matmul (vmacc): the 4 ALUs' products for this pass are one dot-product
  // term each; sum them into this pass's output element, then latch that
  // into dot_reg[pass] once the operands have actually propagated through
  // (RegisterFile + ALU take 1 cycle after we_0, hence the _d1 delay below).
  wire is_vmacc = (instr_id_0 == 6'h2D) && (func3_0 == 3'b010);
  wire [63:0] dot_sum = alu_vd_0 + alu_vd_1 + alu_vd_2 + alu_vd_3;

  reg          we_0_d1;
  reg  [1:0]   pass_0_d1;
  reg  [63:0]  dot_reg [0:3];
  integer      dr_i;

  // Non-vmacc ops used to expose alu_vd_k live (pure combinational, no
  // registration at all). The instant a NEW instruction is accepted,
  // instruction_0/func3_0/instr_id_0 switch immediately, flipping is_vmacc
  // and re-evaluating the ALU's op -- but RegisterFile hasn't been reloaded
  // with the new instruction's operands yet (that takes 1 cycle via we_0).
  // For that one gap cycle, the ALU combinationally computed [new op] on
  // [old op]'s still-registered operands, e.g. vmacc's last-pass row/column
  // added together under vadd.vv's opcode -- a real, visible garbage value.
  // Fix: latch alu_vd_k the same way dot_reg latches dot_sum -- only on
  // we_0_d1 (exactly the cycle RegisterFile+ALU have settled for the
  // CURRENT instruction), holding steady otherwise instead of tracking
  // combinationally at all times.
  reg  [63:0]  alu_settled_0, alu_settled_1, alu_settled_2, alu_settled_3;

  // OPTION B FIX (final_v1 only, 4_64_Core untouched): the vd_0..vd_3
  // MUX SELECT itself was still combinational off live is_vmacc (which
  // tracks instruction_0, i.e. ANY accepted instruction, not just compute
  // ones). A vse64.v accepted right after a vmacc -- which Option B's
  // boot program now does, to save C_mul before vadd.vv overwrites it --
  // is not a compute op, but accepting it still updates instruction_0,
  // flips is_vmacc false, and swaps the mux from dot_reg (correct C_mul)
  // to alu_settled (still holding vmacc's last-pass raw per-lane
  // products, not a dot-product) for as long as vse64.v's WRITEBACK is
  // in flight -- a real, visible glitch on vd_* itself (confirmed in the
  // waveform), not just in the AXI writeback data (already separately
  // fixed via tinygpu_fsm.v's wb_data_q snapshot). Fix: latch the mux
  // SELECT the same way dot_reg/alu_settled latch their DATA -- only on
  // we_0_d1 (an actual compute settle), so vd_* holds its previous valid
  // value steady across any number of non-compute instructions in
  // between, instead of re-deciding which register to show on every
  // instruction_0 change.
  reg          is_vmacc_q;

  always @(posedge clk_0) begin
    if (rst_0) begin
      we_0_d1   <= 1'b0;
      pass_0_d1 <= 2'd0;
      for (dr_i = 0; dr_i < 4; dr_i = dr_i + 1)
        dot_reg[dr_i] <= 64'd0;
      alu_settled_0 <= 64'd0;
      alu_settled_1 <= 64'd0;
      alu_settled_2 <= 64'd0;
      alu_settled_3 <= 64'd0;
      is_vmacc_q    <= 1'b0;
    end else begin
      we_0_d1   <= we_0;
      pass_0_d1 <= pass_0;
      if (we_0_d1) begin
        dot_reg[pass_0_d1] <= dot_sum;
        alu_settled_0 <= alu_vd_0;
        alu_settled_1 <= alu_vd_1;
        alu_settled_2 <= alu_vd_2;
        alu_settled_3 <= alu_vd_3;
        is_vmacc_q    <= is_vmacc;
      end
    end
  end

  assign vd_0 = is_vmacc_q ? dot_reg[0] : alu_settled_0;
  assign vd_1 = is_vmacc_q ? dot_reg[1] : alu_settled_1;
  assign vd_2 = is_vmacc_q ? dot_reg[2] : alu_settled_2;
  assign vd_3 = is_vmacc_q ? dot_reg[3] : alu_settled_3;

  // keep_hierarchy="yes" on these 8 instances: diagnostic, not a functional
  // change. Default synthesis has been merging/moving logic across these
  // specific module boundaries, which is why RegisterFile (confirmed
  // trivial 2-register RTL) and ALU have been reporting wildly
  // inconsistent per-instance utilization numbers across otherwise-
  // identical siblings. This forces each instance to keep its own true
  // boundary, so report_utilization's numbers for these actually mean
  // what they say.
  (* keep_hierarchy = "yes" *) ALU ALU_0
       (.acc_rst(acc_rst_0),
        .clk(clk_0),
        .func3(func3_0),
        .instr_id(instr_id_0),
        .rst(rst_0),
        .vd(alu_vd_0),
        .vs1(RegisterFile_0_vs1_out),
        .vs2(RegisterFile_0_vs2_out),
        .we(we_0));
  (* keep_hierarchy = "yes" *) ALU ALU_1
       (.acc_rst(acc_rst_0),
        .clk(clk_0),
        .func3(func3_0),
        .instr_id(instr_id_0),
        .rst(rst_0),
        .vd(alu_vd_1),
        .vs1(RegisterFile_1_vs1_out),
        .vs2(RegisterFile_1_vs2_out),
        .we(we_0));
  (* keep_hierarchy = "yes" *) ALU ALU_2
       (.acc_rst(acc_rst_0),
        .clk(clk_0),
        .func3(func3_0),
        .instr_id(instr_id_0),
        .rst(rst_0),
        .vd(alu_vd_2),
        .vs1(RegisterFile_2_vs1_out),
        .vs2(RegisterFile_2_vs2_out),
        .we(we_0));
  (* keep_hierarchy = "yes" *) ALU ALU_3
       (.acc_rst(acc_rst_0),
        .clk(clk_0),
        .func3(func3_0),
        .instr_id(instr_id_0),
        .rst(rst_0),
        .vd(alu_vd_3),
        .vs1(RegisterFile_3_vs1_out),
        .vs2(RegisterFile_3_vs2_out),
        .we(we_0));
  (* keep_hierarchy = "yes" *) RegisterFile RegisterFile_0
       (.clk(clk_0),
        .rst(rst_0),
        .vs1_in(cache_0_a0),
        .vs1_out(RegisterFile_0_vs1_out),
        .vs2_in(cache_0_b0),
        .vs2_out(RegisterFile_0_vs2_out),
        .we(we_0));
  (* keep_hierarchy = "yes" *) RegisterFile RegisterFile_1
       (.clk(clk_0),
        .rst(rst_0),
        .vs1_in(cache_0_a1),
        .vs1_out(RegisterFile_1_vs1_out),
        .vs2_in(cache_0_b1),
        .vs2_out(RegisterFile_1_vs2_out),
        .we(we_0));
  (* keep_hierarchy = "yes" *) RegisterFile RegisterFile_2
       (.clk(clk_0),
        .rst(rst_0),
        .vs1_in(cache_0_a2),
        .vs1_out(RegisterFile_2_vs1_out),
        .vs2_in(cache_0_b2),
        .vs2_out(RegisterFile_2_vs2_out),
        .we(we_0));
  (* keep_hierarchy = "yes" *) RegisterFile RegisterFile_3
       (.clk(clk_0),
        .rst(rst_0),
        .vs1_in(cache_0_a3),
        .vs1_out(RegisterFile_3_vs1_out),
        .vs2_in(cache_0_b3),
        .vs2_out(RegisterFile_3_vs2_out),
        .we(we_0));
  cache cache_0
       (.a0(cache_0_a0),
        .a1(cache_0_a1),
        .a2(cache_0_a2),
        .a3(cache_0_a3),
        .b0(cache_0_b0),
        .b1(cache_0_b1),
        .b2(cache_0_b2),
        .b3(cache_0_b3),
        .clk(clk_0),
        .func3(func3_0),
        .instr_id(instr_id_0),
        .mat_a(mat_a_0),
        .mat_b(mat_b_0),
        .rst(rst_0),
        .we(we_0));
endmodule
