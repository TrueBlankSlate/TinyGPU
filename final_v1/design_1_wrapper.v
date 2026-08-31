//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Thu Aug 13 16:23:47 2026
//Host        : AthOS-II running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
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
  input acc_rst_0;
  input clk_0;
  input [2:0]func3_0;
  input [5:0]instr_id_0;
  input [255:0]mat_a_0;
  input [255:0]mat_b_0;
  input [1:0]pass_0;
  input rst_0;
  output [63:0]vd_0;
  output [63:0]vd_1;
  output [63:0]vd_2;
  output [63:0]vd_3;
  input we_0;

  wire acc_rst_0;
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

  design_1 design_1_i
       (.acc_rst_0(acc_rst_0),
        .clk_0(clk_0),
        .func3_0(func3_0),
        .instr_id_0(instr_id_0),
        .mat_a_0(mat_a_0),
        .mat_b_0(mat_b_0),
        .pass_0(pass_0),
        .rst_0(rst_0),
        .vd_0(vd_0),
        .vd_1(vd_1),
        .vd_2(vd_2),
        .vd_3(vd_3),
        .we_0(we_0));
endmodule
