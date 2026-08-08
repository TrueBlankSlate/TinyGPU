`timescale 1ns/1ps

module tb;

reg clk;
reg rst;
reg acc_rst;

reg we_0;          // execute/writeback
reg we_1;          // L3 global write

reg [31:0] instruction;
reg [511:0] w_data;
reg [1:0] pass;

wire [31:0] vd0_0,vd0_1,vd0_2,vd0_3;
wire [31:0] vd1_0,vd1_1,vd1_2,vd1_3;
wire [31:0] vd2_0,vd2_1,vd2_2,vd2_3;
wire [31:0] vd3_0,vd3_1,vd3_2,vd3_3;

fourc_1_wrapper dut(
    .clk_0(clk),
    .rst_0(rst),
    .acc_rst_0_0(acc_rst),

    .instruction_0(instruction),

    .pass_0(pass),

    .w_data_0(w_data),

    .we_0(we_0),
    .we_1(we_1),

    .vd_0_0(vd0_0), .vd_0_1(vd0_1), .vd_0_2(vd0_2), .vd_0_3(vd0_3),
    .vd_1_0(vd1_0), .vd_1_1(vd1_1), .vd_1_2(vd1_2), .vd_1_3(vd1_3),
    .vd_2_0(vd2_0), .vd_2_1(vd2_1), .vd_2_2(vd2_2), .vd_2_3(vd2_3),
    .vd_3_0(vd3_0), .vd_3_1(vd3_1), .vd_3_2(vd3_2), .vd_3_3(vd3_3)
);

always #5 clk = ~clk;

task global_write;
input [511:0] matrix;
begin
    w_data = matrix;
    we_1 = 1;
    @(posedge clk);
    we_1 = 0;
    @(posedge clk);
end
endtask

task execute;
begin
    we_0 = 1;
    @(posedge clk);
    we_0 = 0;

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
end
endtask

initial begin

    clk=0;
    rst=1;
    acc_rst=1;

    we_0=0;
    we_1=0;

    instruction=0;
    w_data=0;
    pass=0;

    repeat(2) @(posedge clk);

    rst=0;
    acc_rst=0;

    @(posedge clk);

    //////////////////////////////////////////////////////
    // VADD.VV
    //////////////////////////////////////////////////////

    instruction = {6'b000000,1'b0,5'd4,5'd0,3'b000,5'd8,7'b1010111};

    global_write({
        32'd16,32'd15,32'd14,32'd13,
        32'd12,32'd11,32'd10,32'd9,
        32'd8,32'd7,32'd6,32'd5,
        32'd4,32'd3,32'd2,32'd1
    });

    global_write({
        32'd160,32'd150,32'd140,32'd130,
        32'd120,32'd110,32'd100,32'd90,
        32'd80,32'd70,32'd60,32'd50,
        32'd40,32'd30,32'd20,32'd10
    });

    execute();

    $display("\n===== VADD =====");
    $display("Core0 : %d %d %d %d",vd0_0,vd1_0,vd2_0,vd3_0);
    $display("Core1 : %d %d %d %d",vd0_1,vd1_1,vd2_1,vd3_1);
    $display("Core2 : %d %d %d %d",vd0_2,vd1_2,vd2_2,vd3_2);
    $display("Core3 : %d %d %d %d",vd0_3,vd1_3,vd2_3,vd3_3);

    //////////////////////////////////////////////////////
    // VSUB.VV
    //////////////////////////////////////////////////////

    instruction = {6'b000010,1'b0,5'd4,5'd0,3'b000,5'd8,7'b1010111};

    execute();

    $display("\n===== VSUB =====");
    $display("Core0 : %d %d %d %d",vd0_0,vd1_0,vd2_0,vd3_0);
    $display("Core1 : %d %d %d %d",vd0_1,vd1_1,vd2_1,vd3_1);
    $display("Core2 : %d %d %d %d",vd0_2,vd1_2,vd2_2,vd3_2);
    $display("Core3 : %d %d %d %d",vd0_3,vd1_3,vd2_3,vd3_3);

    //////////////////////////////////////////////////////
    // VMUL.VV
    //////////////////////////////////////////////////////

    instruction = {6'b100101,1'b0,5'd4,5'd0,3'b000,5'd8,7'b1010111};

    execute();

    $display("\n===== VMUL =====");
    $display("Core0 : %d %d %d %d",vd0_0,vd1_0,vd2_0,vd3_0);
    $display("Core1 : %d %d %d %d",vd0_1,vd1_1,vd2_1,vd3_1);
    $display("Core2 : %d %d %d %d",vd0_2,vd1_2,vd2_2,vd3_2);
    $display("Core3 : %d %d %d %d",vd0_3,vd1_3,vd2_3,vd3_3);

    #20;
    $finish;

end

endmodule