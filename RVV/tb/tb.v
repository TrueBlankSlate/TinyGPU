`timescale 1ps/1ps
module tb;

    reg clk, rst, gw_we, we_0;
    reg [31:0] instruction;
    reg [4:0]  gw_addr;
    reg [127:0] gw_data;
    wire [31:0] vd_0, vd_1, vd_2, vd_3;

    design_1_wrapper dut(
        .clk_0(clk), .rst_0(rst),
        .gw_we_0(gw_we), .we_0(we_0),
        .gw_addr_0(gw_addr), .gw_data_0(gw_data),
        .instruction_0(instruction),
        .vd_0(vd_0), .vd_1(vd_1),
        .vd_2(vd_2), .vd_3(vd_3)
    );

    always #5 clk=~clk;

    initial begin
        clk=0; rst=1; gw_we=0; we_0=0;
        instruction=0; gw_addr=0; gw_data=0;
        #2; rst=0;
        @(posedge clk); #1;

        // write A=[1,2,3,4] to cache[1]
        gw_addr=5'd1; gw_data={32'd4,32'd3,32'd2,32'd1};
        gw_we=1; @(posedge clk); #1; gw_we=0;

        // write B=[10,20,30,40] to cache[2]
        gw_addr=5'd2; gw_data={32'd40,32'd30,32'd20,32'd10};
        gw_we=1; @(posedge clk); #1; gw_we=0;

        // vadd.vv vs1=1,vs2=2,vd=3 → expect [11,22,33,44]
        instruction = 32'b000000_1_00010_00001_000_00011_1010111;
        @(posedge clk); #1;
        we_0=1; @(posedge clk); #1; we_0=0;
        @(posedge clk); #1;
        $display("vadd: [%0d,%0d,%0d,%0d]", vd_0,vd_1,vd_2,vd_3);

        // vsub.vv → expect [9,18,27,36]
        instruction = 32'b000010_1_00010_00001_000_00011_1010111;
        @(posedge clk); #1;
        we_0=1; @(posedge clk); #1; we_0=0;
        @(posedge clk); #1;
        $display("vsub: [%0d,%0d,%0d,%0d]", vd_0,vd_1,vd_2,vd_3);

        // vmul.vv → expect [10,40,90,160]
        instruction = 32'b100101_1_00010_00001_000_00011_1010111;
        @(posedge clk); #1;
        we_0=1; @(posedge clk); #1; we_0=0;
        @(posedge clk); #1;
        $display("vmul: [%0d,%0d,%0d,%0d]", vd_0,vd_1,vd_2,vd_3);

        // vmulh.vv → expect [0,0,0,0]
        instruction = 32'b100111_1_00010_00001_000_00011_1010111;
        @(posedge clk); #1;
        we_0=1; @(posedge clk); #1; we_0=0;
        @(posedge clk); #1;
        $display("vmulh: [%0d,%0d,%0d,%0d]", vd_0,vd_1,vd_2,vd_3);

        #10 $finish;
    end

endmodule