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

  reg  [63:0]  alu_settled_0, alu_settled_1, alu_settled_2, alu_settled_3;

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
