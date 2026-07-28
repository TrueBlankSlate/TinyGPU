//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Tue Jul 28 18:11:36 2026
//Host        : AthOS-II running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (clk_0,
    instruction_0,
    rst_0,
    we_0,
    we_1);
  input clk_0;
  input [31:0]instruction_0;
  input rst_0;
  input we_0;
  input we_1;

  wire clk_0;
  wire [31:0]instruction_0;
  wire rst_0;
  wire we_0;
  wire we_1;

  design_1 design_1_i
       (.clk_0(clk_0),
        .instruction_0(instruction_0),
        .rst_0(rst_0),
        .we_0(we_0),
        .we_1(we_1));
endmodule
