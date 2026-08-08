`timescale 1ps/1ps
module tb_temp_1_wrapper;

reg          clk, rst, acc_rst;
reg  [31:0]  instruction;
reg  [127:0] mat_a, mat_b;
reg          we_0, we_1;

wire [31:0] vd_0, vd_1, vd_2, vd_3;

temp_1_wrapper dut (
    .clk_0(clk), .rst_0(rst), .acc_rst_0(acc_rst),
    .instruction_0(instruction),
    .mat_a_0(mat_a), .mat_b_0(mat_b),
    .we_0(we_0), .we_1(we_1),
    .vd_0(vd_0), .vd_1(vd_1), .vd_2(vd_2), .vd_3(vd_3)
);

always #5000 clk = ~clk;

initial begin
    clk=0; rst=1; acc_rst=1;
    we_0=0; we_1=0;
    mat_a=0; mat_b=0;
    instruction=0;
    @(posedge clk); @(posedge clk);
    rst=0; acc_rst=0;
    @(posedge clk);

    // ── Load cache: a=[1,2,3,4]  b=[10,20,30,40] ──
    // {a3,a2,a1,a0} packed MSB-first → lane0=a[31:0]=1, lane3=a[127:96]=4
    mat_a = {32'd4, 32'd3, 32'd2, 32'd1};
    mat_b = {32'd40, 32'd30, 32'd20, 32'd10};
    we_0=1; @(posedge clk); we_0=0;
    @(posedge clk);

    // ── VADD.VV  funct6=000000 func3=000  expect [11,22,33,44] ──
    instruction = {6'b000000, 1'b0, 5'd2, 5'd1, 3'b000, 5'd0, 7'b1010111};
    @(posedge clk);
    we_1=1; @(posedge clk); we_1=0;
    @(posedge clk); @(posedge clk);
    $display("VADD: [%0d,%0d,%0d,%0d] expect [11,22,33,44]", vd_0,vd_1,vd_2,vd_3);

    // ── VSUB.VV  funct6=000010  expect [9,18,27,36]  (b-a) ──
    instruction = {6'b000010, 1'b0, 5'd2, 5'd1, 3'b000, 5'd0, 7'b1010111};
    @(posedge clk);
    we_1=1; @(posedge clk); we_1=0;
    @(posedge clk); @(posedge clk);
    $display("VSUB: [%0d,%0d,%0d,%0d] expect [9,18,27,36]", vd_0,vd_1,vd_2,vd_3);

    // ── VMUL.VV  funct6=100101  expect [10,40,90,160] ──
    instruction = {6'b100101, 1'b0, 5'd2, 5'd1, 3'b000, 5'd0, 7'b1010111};
    @(posedge clk);
    we_1=1; @(posedge clk); we_1=0;
    @(posedge clk); @(posedge clk);
    $display("VMUL: [%0d,%0d,%0d,%0d] expect [10,40,90,160]", vd_0,vd_1,vd_2,vd_3);

    #20000; $finish;
end

endmodule