`timescale 1ns/1ps
module tb;

reg clk, rst, acc_rst, gw_we, we;
reg [4:0]   gw_addr;
reg [127:0] gw_data;
reg [31:0]  instruction;

wire [31:0] vd0, vd1, vd2, vd3;

design_1_wrapper dut(
    .clk_0(clk), .rst_0(rst),
    .acc_rst_0(acc_rst),
    .gw_we_0(gw_we), .we_0(we),
    .gw_addr_0(gw_addr), .gw_data_0(gw_data),
    .instruction_0(instruction),
    .vd_0(vd0), .vd_1(vd1),
    .vd_2(vd2), .vd_3(vd3)
);

always #5 clk = ~clk;

initial begin
    clk=0; rst=1; acc_rst=1;
    gw_we=0; we=0;
    gw_addr=0; gw_data=0;
    instruction=0;

    @(posedge clk); @(posedge clk);
    rst=0; acc_rst=0;
    @(posedge clk);

    // A row-major: cache[1]=[1,2,3,4]
    gw_addr=5'd1; gw_data={32'd4,32'd3,32'd2,32'd1};
    gw_we=1; @(posedge clk); gw_we=0;

    // B column-major: cache[2]=[5,7,6,8]
    gw_addr=5'd2; gw_data={32'd8,32'd7,32'd6,32'd5};
    gw_we=1; @(posedge clk); gw_we=0;

    instruction = {6'b101101,1'b0,5'd2,5'd1,3'b010,5'd0,7'b1010111};
    @(posedge clk); @(posedge clk);

    // pass1: expect acc=[5,6,15,18]
    we=1; @(posedge clk); we=0;
    @(posedge clk); @(posedge clk); @(posedge clk);
    $display("after pass1: [%0d,%0d,%0d,%0d] expect [5,6,15,18]",vd0,vd1,vd2,vd3);

    // pass2: expect acc=[19,22,43,50]
    we=1; @(posedge clk); we=0;
    @(posedge clk); @(posedge clk); @(posedge clk);
    $display("after pass2: [%0d,%0d,%0d,%0d] expect [19,22,43,50]",vd0,vd1,vd2,vd3);

    // pass3: expect acc=[19+?,22+?,43+?,50+?] (should not change if pass resets)
    we=1; @(posedge clk); we=0;
    @(posedge clk); @(posedge clk); @(posedge clk);
    $display("after pass3: [%0d,%0d,%0d,%0d] should wrap or stop",vd0,vd1,vd2,vd3);

    #20; $finish;
end

endmodule