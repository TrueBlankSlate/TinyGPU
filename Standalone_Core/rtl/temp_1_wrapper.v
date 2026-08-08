//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Sat Aug  8 12:22:41 2026
//Host        : AthOS-II running 64-bit major release  (build 9200)
//Command     : generate_target temp_1_wrapper.bd
//Design      : temp_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module temp_1_wrapper
   (acc_rst_0,
    clk_0,
    instruction_0,
    mat_a_0,
    mat_b_0,
    rst_0,
    vd_0,
    vd_1,
    vd_2,
    vd_3,
    we_0,
    we_1);
  input acc_rst_0;
  input clk_0;
  input [31:0]instruction_0;
  input [127:0]mat_a_0;
  input [127:0]mat_b_0;
  input rst_0;
  output [31:0]vd_0;
  output [31:0]vd_1;
  output [31:0]vd_2;
  output [31:0]vd_3;
  input we_0;
  input we_1;

  wire acc_rst_0;
  wire clk_0;
  wire [31:0]instruction_0;
  wire [127:0]mat_a_0;
  wire [127:0]mat_b_0;
  wire rst_0;
  wire [31:0]vd_0;
  wire [31:0]vd_1;
  wire [31:0]vd_2;
  wire [31:0]vd_3;
  wire we_0;
  wire we_1;

  temp_1 temp_1_i
       (.acc_rst_0(acc_rst_0),
        .clk_0(clk_0),
        .instruction_0(instruction_0),
        .mat_a_0(mat_a_0),
        .mat_b_0(mat_b_0),
        .rst_0(rst_0),
        .vd_0(vd_0),
        .vd_1(vd_1),
        .vd_2(vd_2),
        .vd_3(vd_3),
        .we_0(we_0),
        .we_1(we_1));
endmodule
