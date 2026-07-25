`timescale 1ps/1ps

module tb;

reg clk;
reg rst;
reg we_0_1;          // core register write enable
reg we_1;            // cache write enable
reg [31:0] instruction;

design_1_wrapper dut (
    .clk_0(clk),
    .rst_0(rst),
    .instruction_0(instruction),
    .we_0_1(we_0_1),
    .we_1(we_1)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    we_0_1 = 0;
    we_1 = 0;
    instruction = 32'd0;

    // Reset
    @(posedge clk);
    #1 rst = 0;

    // Allow cache writeback (if required)
    we_1 = 1;
    @(posedge clk);
    #1 we_1 = 0;

    // Load operands into the four cores
    we_0_1 = 1;
    @(posedge clk);
    #1 we_0_1 = 0;

    //-------------------------
    // vadd.vv
    //-------------------------
    instruction = 32'b000000_1_00001_00010_000_00011_1010111;
    @(posedge clk); #1;
    @(posedge clk); #1;

    //-------------------------
    // vsub.vv
    //-------------------------
    instruction = 32'b000010_1_00001_00010_000_00011_1010111;
    @(posedge clk); #1;
    @(posedge clk); #1;

    //-------------------------
    // vmul.vv
    //-------------------------
    instruction = 32'b100101_1_00001_00010_000_00011_1010111;
    @(posedge clk); #1;
    @(posedge clk); #1;

    //-------------------------
    // vmulh.vv
    //-------------------------
    instruction = 32'b100111_1_00001_00010_000_00011_1010111;
    @(posedge clk); #1;
    @(posedge clk); #1;

    #20;
    $finish;
end

initial begin
    $monitor(
        "T=%0t instr=%h | ",
        "A={%0d,%0d,%0d,%0d} ",
        "B={%0d,%0d,%0d,%0d} | ",
        "CoreOut={%0d,%0d,%0d,%0d} | ",
        "WB=%h",
        $time,
        instruction,

        dut.design_1_i.cache_0_a0,
        dut.design_1_i.cache_0_a1,
        dut.design_1_i.cache_0_a2,
        dut.design_1_i.cache_0_a3,

        dut.design_1_i.cache_0_b0,
        dut.design_1_i.cache_0_b1,
        dut.design_1_i.cache_0_b2,
        dut.design_1_i.cache_0_b3,

        dut.design_1_i.design_1_core_wrapper_0_vd_0,
        dut.design_1_i.design_1_core_wrapper_1_vd_0,
        dut.design_1_i.design_1_core_wrapper_2_vd_0,
        dut.design_1_i.design_1_core_wrapper_3_vd_0,

        dut.design_1_i.writeback_0_vd_out
    );
end

endmodule