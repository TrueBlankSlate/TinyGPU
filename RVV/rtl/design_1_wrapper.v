//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Wed Jul 29 21:36:06 2026
//Host        : AthOS-II running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (clk_0,
    gw_addr_0,
    gw_data_0,
    gw_we_0,
    instruction_0,
    rst_0,
    vd_0,
    vd_1,
    vd_2,
    vd_3,
    we_0);
  input clk_0;
  input [4:0]gw_addr_0;
  input [127:0]gw_data_0;
  input gw_we_0;
  input [31:0]instruction_0;
  input rst_0;
  output [31:0]vd_0;
  output [31:0]vd_1;
  output [31:0]vd_2;
  output [31:0]vd_3;
  input we_0;

  wire clk_0;
  wire [4:0]gw_addr_0;
  wire [127:0]gw_data_0;
  wire gw_we_0;
  wire [31:0]instruction_0;
  wire rst_0;
  wire [31:0]vd_0;
  wire [31:0]vd_1;
  wire [31:0]vd_2;
  wire [31:0]vd_3;
  wire we_0;

  design_1 design_1_i
       (.clk_0(clk_0),
        .gw_addr_0(gw_addr_0),
        .gw_data_0(gw_data_0),
        .gw_we_0(gw_we_0),
        .instruction_0(instruction_0),
        .rst_0(rst_0),
        .vd_0(vd_0),
        .vd_1(vd_1),
        .vd_2(vd_2),
        .vd_3(vd_3),
        .we_0(we_0));
endmodule
