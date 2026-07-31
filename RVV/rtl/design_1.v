//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Fri Jul 31 21:30:34 2026
//Host        : AthOS-II running 64-bit major release  (build 9200)
//Command     : generate_target design_1.bd
//Design      : design_1
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=design_1,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=10,numReposBlks=10,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "design_1.hwdef" *) 
module design_1
   (clk_0,
    gw_addr_0,
    gw_data_0,
    gw_we_0,
    instruction_0,
    rst_0,
    rst_1,
    vd_0,
    vd_1,
    vd_2,
    vd_3,
    we_0);
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.CLK_0 CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.CLK_0, ASSOCIATED_RESET rst_0:rst_1, CLK_DOMAIN design_1_clk_0, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input clk_0;
  input [4:0]gw_addr_0;
  input [127:0]gw_data_0;
  input gw_we_0;
  input [31:0]instruction_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.RST_0 RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.RST_0, INSERT_VIP 0, POLARITY ACTIVE_HIGH" *) input rst_0;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.RST_1 RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.RST_1, INSERT_VIP 0, POLARITY ACTIVE_HIGH" *) input rst_1;
  output [31:0]vd_0;
  output [31:0]vd_1;
  output [31:0]vd_2;
  output [31:0]vd_3;
  input we_0;

  wire [31:0]RegisterFile_0_out0;
  wire [31:0]RegisterFile_0_out1;
  wire [31:0]RegisterFile_0_out2;
  wire [31:0]RegisterFile_0_out3;
  wire [31:0]RegisterFile_1_out0;
  wire [31:0]RegisterFile_1_out1;
  wire [31:0]RegisterFile_1_out2;
  wire [31:0]RegisterFile_1_out3;
  wire [31:0]RegisterFile_2_out0;
  wire [31:0]RegisterFile_2_out1;
  wire [31:0]RegisterFile_2_out2;
  wire [31:0]RegisterFile_2_out3;
  wire [31:0]RegisterFile_3_out0;
  wire [31:0]RegisterFile_3_out1;
  wire [31:0]RegisterFile_3_out2;
  wire [31:0]RegisterFile_3_out3;
  wire [31:0]cache_0_a0;
  wire [31:0]cache_0_a1;
  wire [31:0]cache_0_a2;
  wire [31:0]cache_0_a3;
  wire [31:0]cache_0_b0;
  wire [31:0]cache_0_b1;
  wire [31:0]cache_0_b2;
  wire [31:0]cache_0_b3;
  wire [31:0]cache_0_c0;
  wire [31:0]cache_0_c1;
  wire [31:0]cache_0_c2;
  wire [31:0]cache_0_c3;
  wire [31:0]cache_0_d0;
  wire [31:0]cache_0_d1;
  wire [31:0]cache_0_d2;
  wire [31:0]cache_0_d3;
  wire clk_0;
  wire [2:0]decoder_0_func3_out;
  wire [5:0]decoder_0_instr_id;
  wire decoder_0_matmul_out;
  wire [4:0]decoder_0_vs1;
  wire [4:0]decoder_0_vs2;
  wire [4:0]gw_addr_0;
  wire [127:0]gw_data_0;
  wire gw_we_0;
  wire [31:0]instruction_0;
  wire rst_0;
  wire rst_1;
  wire [31:0]vd_0;
  wire [31:0]vd_1;
  wire [31:0]vd_2;
  wire [31:0]vd_3;
  wire we_0;

  design_1_ALU_0_0 ALU_0
       (.a1(RegisterFile_0_out0),
        .a2(RegisterFile_0_out1),
        .b1(RegisterFile_0_out2),
        .b2(RegisterFile_0_out3),
        .func3(decoder_0_func3_out),
        .instr_id(decoder_0_instr_id),
        .vd(vd_0));
  design_1_ALU_1_0 ALU_1
       (.a1(RegisterFile_1_out0),
        .a2(RegisterFile_1_out1),
        .b1(RegisterFile_1_out2),
        .b2(RegisterFile_1_out3),
        .func3(decoder_0_func3_out),
        .instr_id(decoder_0_instr_id),
        .vd(vd_1));
  design_1_ALU_2_0 ALU_2
       (.a1(RegisterFile_2_out0),
        .a2(RegisterFile_2_out1),
        .b1(RegisterFile_2_out2),
        .b2(RegisterFile_2_out3),
        .func3(decoder_0_func3_out),
        .instr_id(decoder_0_instr_id),
        .vd(vd_2));
  design_1_ALU_3_0 ALU_3
       (.a1(RegisterFile_3_out0),
        .a2(RegisterFile_3_out1),
        .b1(RegisterFile_3_out2),
        .b2(RegisterFile_3_out3),
        .func3(decoder_0_func3_out),
        .instr_id(decoder_0_instr_id),
        .vd(vd_3));
  design_1_RegisterFile_0_0 RegisterFile_0
       (.clk(clk_0),
        .in0(cache_0_a0),
        .in1(cache_0_b0),
        .in2(cache_0_c0),
        .in3(cache_0_d0),
        .out0(RegisterFile_0_out0),
        .out1(RegisterFile_0_out1),
        .out2(RegisterFile_0_out2),
        .out3(RegisterFile_0_out3),
        .rst(rst_1),
        .we(we_0));
  design_1_RegisterFile_1_0 RegisterFile_1
       (.clk(clk_0),
        .in0(cache_0_a1),
        .in1(cache_0_b1),
        .in2(cache_0_c1),
        .in3(cache_0_d1),
        .out0(RegisterFile_1_out0),
        .out1(RegisterFile_1_out1),
        .out2(RegisterFile_1_out2),
        .out3(RegisterFile_1_out3),
        .rst(rst_1),
        .we(we_0));
  design_1_RegisterFile_2_0 RegisterFile_2
       (.clk(clk_0),
        .in0(cache_0_a2),
        .in1(cache_0_b2),
        .in2(cache_0_c2),
        .in3(cache_0_d2),
        .out0(RegisterFile_2_out0),
        .out1(RegisterFile_2_out1),
        .out2(RegisterFile_2_out2),
        .out3(RegisterFile_2_out3),
        .rst(rst_1),
        .we(we_0));
  design_1_RegisterFile_3_0 RegisterFile_3
       (.clk(clk_0),
        .in0(cache_0_a3),
        .in1(cache_0_b3),
        .in2(cache_0_c3),
        .in3(cache_0_d3),
        .out0(RegisterFile_3_out0),
        .out1(RegisterFile_3_out1),
        .out2(RegisterFile_3_out2),
        .out3(RegisterFile_3_out3),
        .rst(rst_1),
        .we(we_0));
  design_1_cache_0_0 cache_0
       (.a0(cache_0_a0),
        .a1(cache_0_a1),
        .a2(cache_0_a2),
        .a3(cache_0_a3),
        .b0(cache_0_b0),
        .b1(cache_0_b1),
        .b2(cache_0_b2),
        .b3(cache_0_b3),
        .c0(cache_0_c0),
        .c1(cache_0_c1),
        .c2(cache_0_c2),
        .c3(cache_0_c3),
        .clk(clk_0),
        .d0(cache_0_d0),
        .d1(cache_0_d1),
        .d2(cache_0_d2),
        .d3(cache_0_d3),
        .gw_addr(gw_addr_0),
        .gw_data(gw_data_0),
        .gw_we(gw_we_0),
        .matmul(decoder_0_matmul_out),
        .rst(rst_0),
        .vs1(decoder_0_vs1),
        .vs2(decoder_0_vs2));
  design_1_decoder_0_0 decoder_0
       (.clk(clk_0),
        .func3_out(decoder_0_func3_out),
        .instr_id(decoder_0_instr_id),
        .instruction(instruction_0),
        .matmul_out(decoder_0_matmul_out),
        .rst(rst_0),
        .vs1(decoder_0_vs1),
        .vs2(decoder_0_vs2));
endmodule
