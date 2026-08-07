`timescale 1ns / 1ps

module top(

    //==========================
    // Clock & Reset
    //==========================
    input wire clk,
    input wire rst,
    input wire acc_rst,

    //==========================
    // Control Signals
    //==========================
    input wire we,
    input wire [2:0] func3,
    input wire [5:0] instr_id,

    //==========================
    // Matrix Inputs
    //==========================
    input wire [255:0] mat_a,
    input wire [255:0] mat_b,

    //==========================
    // LED Outputs
    //==========================
    output wire [3:0] led

);

    //==========================================================
    // Internal Wires
    //==========================================================

    // Cache -> Register Files
    wire [63:0] a0, a1, a2, a3;
    wire [63:0] b0, b1, b2, b3;

    // Register Files -> ALUs
    wire [63:0] vs1_0, vs2_0;
    wire [63:0] vs1_1, vs2_1;
    wire [63:0] vs1_2, vs2_2;
    wire [63:0] vs1_3, vs2_3;

    // ALU Outputs
    wire [63:0] vd0, vd1, vd2, vd3;

    //==========================================================
    // Cache
    //==========================================================

    cache CACHE(

        .clk(clk),
        .rst(rst),

        .func3(func3),
        .instr_id(instr_id),
        .mat_a(mat_a),
        .mat_b(mat_b),

        .we(we),

        .a0(a0),
        .a1(a1),
        .a2(a2),
        .a3(a3),

        .b0(b0),
        .b1(b1),
        .b2(b2),
        .b3(b3)
    );

    //==========================================================
    // Register Files
    //==========================================================

    RegisterFile RF0(

        .clk(clk),
        .rst(rst),
        .we(we),

        .vs1_in(a0),
        .vs2_in(b0),

        .vs1_out(vs1_0),
        .vs2_out(vs2_0)
    );

    RegisterFile RF1(

        .clk(clk),
        .rst(rst),
        .we(we),

        .vs1_in(a1),
        .vs2_in(b1),

        .vs1_out(vs1_1),
        .vs2_out(vs2_1)
    );

    RegisterFile RF2(

        .clk(clk),
        .rst(rst),
        .we(we),

        .vs1_in(a2),
        .vs2_in(b2),

        .vs1_out(vs1_2),
        .vs2_out(vs2_2)
    );

    RegisterFile RF3(

        .clk(clk),
        .rst(rst),
        .we(we),

        .vs1_in(a3),
        .vs2_in(b3),

        .vs1_out(vs1_3),
        .vs2_out(vs2_3)
    );

    

    ALU ALU0(

        .clk(clk),
        .rst(rst),
        .acc_rst(acc_rst),

        .func3(func3),
        .instr_id(instr_id),

        .we(we),

        .vs1(vs1_0),
        .vs2(vs2_0),

        .vd(vd0)
    );

    ALU ALU1(

        .clk(clk),
        .rst(rst),
        .acc_rst(acc_rst),

        .func3(func3),
        .instr_id(instr_id),

        .we(we),

        .vs1(vs1_1),
        .vs2(vs2_1),

        .vd(vd1)
    );

    ALU ALU2(

        .clk(clk),
        .rst(rst),
        .acc_rst(acc_rst),

        .func3(func3),
        .instr_id(instr_id),

        .we(we),

        .vs1(vs1_2),
        .vs2(vs2_2),

        .vd(vd2)
    );

    ALU ALU3(

        .clk(clk),
        .rst(rst),
        .acc_rst(acc_rst),

        .func3(func3),
        .instr_id(instr_id),

        .we(we),

        .vs1(vs1_3),
        .vs2(vs2_3),

        .vd(vd3)
    );

    //==========================================================
    // Writeback
    //==========================================================

    writeback WB(

        .clk(clk),
        .rst(rst),

        .v0(vd0),
        .v1(vd1),
        .v2(vd2),
        .v3(vd3),

        .led(led)
    );

endmodule