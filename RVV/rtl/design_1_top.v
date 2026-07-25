//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Sat Jul 25 23:27:00 2026
//Host        : AthOS-II running 64-bit major release  (build 9200)
//Command     : generate_target design_1.bd
//Design      : design_1
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=design_1,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=7,numReposBlks=7,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "design_1.hwdef" *) 
module design_1
   (clk_0,
    instruction_0,
    rst_0,
    we_0_1,
    we_1);
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CLK_0 CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CLK_0, ASSOCIATED_RESET rst_0, CLK_DOMAIN design_1_clk_0, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input clk_0;
  input [31:0]instruction_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.RST_0 RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.RST_0, INSERT_VIP 0, POLARITY ACTIVE_LOW" *) input rst_0;
  input we_0_1;
  input we_1;

  wire [31:0]cache_0_a0;
  wire [31:0]cache_0_a1;
  wire [31:0]cache_0_a2;
  wire [31:0]cache_0_a3;
  wire [31:0]cache_0_b0;
  wire [31:0]cache_0_b1;
  wire [31:0]cache_0_b2;
  wire [31:0]cache_0_b3;
  wire clk_0;
  wire [2:0]decoder_0_func3_out;
  wire [5:0]decoder_0_instr_id;
  wire [4:0]decoder_0_vd;
  wire [4:0]decoder_0_vs1;
  wire [4:0]decoder_0_vs2;
  wire [31:0]design_1_core_wrapper_0_vd_0;
  wire [31:0]design_1_core_wrapper_1_vd_0;
  wire [31:0]design_1_core_wrapper_2_vd_0;
  wire [31:0]design_1_core_wrapper_3_vd_0;
  wire [31:0]instruction_0;
  wire rst_0;
  wire we_0_1;
  wire we_1;
  wire [4:0]writeback_0_vd_addr_out;
  wire [127:0]writeback_0_vd_out;

  design_1_cache_0_0 cache_0
       (.a0(cache_0_a0),
        .a1(cache_0_a1),
        .a2(cache_0_a2),
        .a3(cache_0_a3),
        .b0(cache_0_b0),
        .b1(cache_0_b1),
        .b2(cache_0_b2),
        .b3(cache_0_b3),
        .clk(clk_0),
        .rst(rst_0),
        .vs1(decoder_0_vs1),
        .vs2(decoder_0_vs2),
        .w_addr(writeback_0_vd_addr_out),
        .w_data(writeback_0_vd_out),
        .we(we_1));
  design_1_decoder_0_2 decoder_0
       (.clk(clk_0),
        .func3_out(decoder_0_func3_out),
        .instr_id(decoder_0_instr_id),
        .instruction(instruction_0),
        .rst(rst_0),
        .vd(decoder_0_vd),
        .vs1(decoder_0_vs1),
        .vs2(decoder_0_vs2));
  design_1_design_1_core_wrapper_0_0 design_1_core_wrapper_0
       (.clk_0(clk_0),
        .func3_0(decoder_0_func3_out),
        .instr_id_0(decoder_0_instr_id),
        .rst_0(rst_0),
        .vd_0(design_1_core_wrapper_0_vd_0),
        .vs1_in_0(cache_0_a0),
        .vs2_in_0(cache_0_b0),
        .we_0(we_0_1));
  design_1_design_1_core_wrapper_1_0 design_1_core_wrapper_1
       (.clk_0(clk_0),
        .func3_0(decoder_0_func3_out),
        .instr_id_0(decoder_0_instr_id),
        .rst_0(rst_0),
        .vd_0(design_1_core_wrapper_1_vd_0),
        .vs1_in_0(cache_0_a1),
        .vs2_in_0(cache_0_b1),
        .we_0(we_0_1));
  design_1_design_1_core_wrapper_2_0 design_1_core_wrapper_2
       (.clk_0(clk_0),
        .func3_0(decoder_0_func3_out),
        .instr_id_0(decoder_0_instr_id),
        .rst_0(rst_0),
        .vd_0(design_1_core_wrapper_2_vd_0),
        .vs1_in_0(cache_0_a2),
        .vs2_in_0(cache_0_b2),
        .we_0(we_0_1));
  design_1_design_1_core_wrapper_3_0 design_1_core_wrapper_3
       (.clk_0(clk_0),
        .func3_0(decoder_0_func3_out),
        .instr_id_0(decoder_0_instr_id),
        .rst_0(rst_0),
        .vd_0(design_1_core_wrapper_3_vd_0),
        .vs1_in_0(cache_0_a3),
        .vs2_in_0(cache_0_b3),
        .we_0(we_0_1));
  design_1_writeback_0_0 writeback_0
       (.c0(design_1_core_wrapper_0_vd_0),
        .c1(design_1_core_wrapper_1_vd_0),
        .c2(design_1_core_wrapper_2_vd_0),
        .c3(design_1_core_wrapper_3_vd_0),
        .vd_addr(decoder_0_vd),
        .vd_addr_out(writeback_0_vd_addr_out),
        .vd_out(writeback_0_vd_out));
endmodule
