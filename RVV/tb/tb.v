`timescale 1ps/1ps
module tb;

    reg clk, rst, we_0, we_1;
    reg [31:0] instruction;

    design_1_wrapper dut(
        .clk_0(clk),
        .rst_0(rst),
        .instruction_0(instruction),
        .we_0(we_0),
        .we_1(we_1)
    );

    always #5 clk = ~clk;

    initial begin
        clk=0; rst=0; we_0=0; we_1=0; instruction=0;
        #2; rst=1;
        @(posedge clk); #1;

        // write A=[1,2,3,4] to cache register 1
        // need to force w_addr and w_data then pulse we_1
        force dut.design_1_i.cache_0.inst.w_addr = 5'd1;
        force dut.design_1_i.cache_0.inst.w_data = {32'd4,32'd3,32'd2,32'd1};
        we_1=1; @(posedge clk); #1; we_1=0;
        release dut.design_1_i.cache_0.inst.w_addr;
        release dut.design_1_i.cache_0.inst.w_data;

        // write B=[10,20,30,40] to cache register 2
        force dut.design_1_i.cache_0.inst.w_addr = 5'd2;
        force dut.design_1_i.cache_0.inst.w_data = {32'd40,32'd30,32'd20,32'd10};
        we_1=1; @(posedge clk); #1; we_1=0;
        release dut.design_1_i.cache_0.inst.w_addr;
        release dut.design_1_i.cache_0.inst.w_data;

        $display("cache[1]=%h cache[2]=%h",
            dut.design_1_i.cache_0.inst.vector_cache[1],
            dut.design_1_i.cache_0.inst.vector_cache[2]);

        // vadd.vv vs1=1,vs2=2,vd=3
        instruction = 32'b000000_1_00010_00001_000_00011_1010111;
        @(posedge clk); #1;
        we_0=1; @(posedge clk); #1; we_0=0;
        @(posedge clk); #1;

        $display("RF0: vs1=%0d vs2=%0d",
            dut.design_1_i.RegisterFile_0.inst.vs1_out,
            dut.design_1_i.RegisterFile_0.inst.vs2_out);
        $display("vadd: vd=[%0d,%0d,%0d,%0d]",
            dut.design_1_i.ALU_0_vd, dut.design_1_i.ALU_1_vd,
            dut.design_1_i.ALU_2_vd, dut.design_1_i.ALU_3_vd);

        #10 $finish;
    end

endmodule