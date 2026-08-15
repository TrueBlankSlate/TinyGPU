//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Fri Aug 14 15:27:17 2026
//Host        : AthOS-II running 64-bit major release  (build 9200)
//Command     : generate_target fourc_1_wrapper.bd
//Design      : fourc_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module fourc_1_wrapper
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
  input clk_0;
  input [31:0]instruction_0;
  input [1:0]pass_0;
  input rst_0;
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
  wire [1:0]pass_0;
  wire rst_0;
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

  fourc_1 fourc_1_i
       (.acc_rst_0_0(acc_rst_0_0),
        .clk_0(clk_0),
        .instruction_0(instruction_0),
        .pass_0(pass_0),
        .rst_0(rst_0),
        .l3_ready(l3_ready),
        .vd_0_0(vd_0_0),
        .vd_0_1(vd_0_1),
        .vd_0_2(vd_0_2),
        .vd_0_3(vd_0_3),
        .vd_1_0(vd_1_0),
        .vd_1_1(vd_1_1),
        .vd_1_2(vd_1_2),
        .vd_1_3(vd_1_3),
        .vd_2_0(vd_2_0),
        .vd_2_1(vd_2_1),
        .vd_2_2(vd_2_2),
        .vd_2_3(vd_2_3),
        .vd_3_0(vd_3_0),
        .vd_3_1(vd_3_1),
        .vd_3_2(vd_3_2),
        .vd_3_3(vd_3_3),
        .w_data_0(w_data_0),
        .we_0(we_0),
        .we_1(we_1));
endmodule
