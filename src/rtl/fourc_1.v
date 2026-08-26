//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Fri Aug 14 15:27:16 2026
//Host        : AthOS-II running 64-bit major release  (build 9200)
//Command     : generate_target fourc_1.bd
//Design      : fourc_1
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "fourc_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=fourc_1,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=6,numReposBlks=6,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "fourc_1.hwdef" *) 
module fourc_1
   (acc_rst_0_0,
    clk_0,
    instruction_0,
    pass_0,
    rst_0,
    vd_0_0,
    vd_0_1,
    vd_0_2,
    vd_0_3,
    vd_1_0,
    vd_1_1,
    vd_1_2,
    vd_1_3,
    vd_2_0,
    vd_2_1,
    vd_2_2,
    vd_2_3,
    vd_3_0,
    vd_3_1,
    vd_3_2,
    vd_3_3,
    w_data_0,
    we_0,
    we_1,
    l3_ready);
  input acc_rst_0_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CLK_0 CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CLK_0, ASSOCIATED_RESET rst_0, CLK_DOMAIN fourc_1_clk_0, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input clk_0;
  input [31:0]instruction_0;
  input [1:0]pass_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.RST_0 RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.RST_0, INSERT_VIP 0, POLARITY ACTIVE_HIGH" *) input rst_0;
  output [63:0]vd_0_0;
  output [63:0]vd_0_1;
  output [63:0]vd_0_2;
  output [63:0]vd_0_3;
  output [63:0]vd_1_0;
  output [63:0]vd_1_1;
  output [63:0]vd_1_2;
  output [63:0]vd_1_3;
  output [63:0]vd_2_0;
  output [63:0]vd_2_1;
  output [63:0]vd_2_2;
  output [63:0]vd_2_3;
  output [63:0]vd_3_0;
  output [63:0]vd_3_1;
  output [63:0]vd_3_2;
  output [63:0]vd_3_3;
  input [2047:0]w_data_0;
  input we_0;
  input we_1;
  output l3_ready;
  wire acc_rst_0_0;
  wire clk_0;
  wire [31:0]instruction_0;
  wire [255:0]l3_cache_1_core0_a;
  wire [255:0]l3_cache_1_core0_b;
  wire [255:0]l3_cache_1_core1_a;
  wire [255:0]l3_cache_1_core1_b;
  wire [255:0]l3_cache_1_core2_a;
  wire [255:0]l3_cache_1_core2_b;
  wire [255:0]l3_cache_1_core3_a;
  wire [255:0]l3_cache_1_core3_b;
  wire [1:0]pass_0;
  wire rst_0;
  wire [2:0]tinygpu_decoder_0_func3_out;
  wire [5:0]tinygpu_decoder_0_instr_id;
  wire [4:0]tinygpu_decoder_0_vs1;
  wire [4:0]tinygpu_decoder_0_vs2;
  wire [63:0]vd_0_0;
  wire [63:0]vd_0_1;
  wire [63:0]vd_0_2;
  wire [63:0]vd_0_3;
  wire [63:0]vd_1_0;
  wire [63:0]vd_1_1;
  wire [63:0]vd_1_2;
  wire [63:0]vd_1_3;
  wire [63:0]vd_2_0;
  wire [63:0]vd_2_1;
  wire [63:0]vd_2_2;
  wire [63:0]vd_2_3;
  wire [63:0]vd_3_0;
  wire [63:0]vd_3_1;
  wire [63:0]vd_3_2;
  wire [63:0]vd_3_3;
  wire [2047:0]w_data_0;
  wire we_0;
  wire we_1;
  wire l3_ready;

  design_1_wrapper design_1_wrapper_0
       (.acc_rst_0(acc_rst_0_0),
        .clk_0(clk_0),
        .func3_0(tinygpu_decoder_0_func3_out),
        .instr_id_0(tinygpu_decoder_0_instr_id),
        .mat_a_0(l3_cache_1_core0_a),
        .mat_b_0(l3_cache_1_core0_b),
        .pass_0(pass_0),
        .rst_0(rst_0),
        .vd_0(vd_0_0),
        .vd_1(vd_1_0),
        .vd_2(vd_2_0),
        .vd_3(vd_3_0),
        .we_0(we_0));
  design_1_wrapper design_1_wrapper_1
       (.acc_rst_0(acc_rst_0_0),
        .clk_0(clk_0),
        .func3_0(tinygpu_decoder_0_func3_out),
        .instr_id_0(tinygpu_decoder_0_instr_id),
        .mat_a_0(l3_cache_1_core1_a),
        .mat_b_0(l3_cache_1_core1_b),
        .pass_0(pass_0),
        .rst_0(rst_0),
        .vd_0(vd_0_1),
        .vd_1(vd_1_1),
        .vd_2(vd_2_1),
        .vd_3(vd_3_1),
        .we_0(we_0));
  design_1_wrapper design_1_wrapper_2
       (.acc_rst_0(acc_rst_0_0),
        .clk_0(clk_0),
        .func3_0(tinygpu_decoder_0_func3_out),
        .instr_id_0(tinygpu_decoder_0_instr_id),
        .mat_a_0(l3_cache_1_core2_a),
        .mat_b_0(l3_cache_1_core2_b),
        .pass_0(pass_0),
        .rst_0(rst_0),
        .vd_0(vd_0_2),
        .vd_1(vd_1_2),
        .vd_2(vd_2_2),
        .vd_3(vd_3_2),
        .we_0(we_0));
  design_1_wrapper design_1_wrapper_3
       (.acc_rst_0(acc_rst_0_0),
        .clk_0(clk_0),
        .func3_0(tinygpu_decoder_0_func3_out),
        .instr_id_0(tinygpu_decoder_0_instr_id),
        .mat_a_0(l3_cache_1_core3_a),
        .mat_b_0(l3_cache_1_core3_b),
        .pass_0(pass_0),
        .rst_0(rst_0),
        .vd_0(vd_0_3),
        .vd_1(vd_1_3),
        .vd_2(vd_2_3),
        .vd_3(vd_3_3),
        .we_0(we_0));
  l3_cache l3_cache_1
       (.clk(clk_0),
        .core0_a(l3_cache_1_core0_a),
        .core0_b(l3_cache_1_core0_b),
        .core1_a(l3_cache_1_core1_a),
        .core1_b(l3_cache_1_core1_b),
        .core2_a(l3_cache_1_core2_a),
        .core2_b(l3_cache_1_core2_b),
        .core3_a(l3_cache_1_core3_a),
        .core3_b(l3_cache_1_core3_b),
        .func3(tinygpu_decoder_0_func3_out),
        .instr_id(tinygpu_decoder_0_instr_id),
        .pass(pass_0),
        .rst(rst_0),
        .vs1(tinygpu_decoder_0_vs1),
        .vs2(tinygpu_decoder_0_vs2),
        .w_data(w_data_0),
        .req(we_1),
        .ready(l3_ready));
  tinygpu_decoder tinygpu_decoder_0
       (.clk(clk_0),
        .func3_out(tinygpu_decoder_0_func3_out),
        .instr_id(tinygpu_decoder_0_instr_id),
        .instruction(instruction_0),
        .rst(rst_0),
        .vs1(tinygpu_decoder_0_vs1),
        .vs2(tinygpu_decoder_0_vs2));
endmodule
