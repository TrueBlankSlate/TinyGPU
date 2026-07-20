`timescale 1ns/1ps

module tb_top;

reg clk;
reg rst;
reg we;
reg [31:0] instr;

wire [31:0] out0;
wire [31:0] out1;
wire [31:0] out2;
wire [31:0] out3;

top top_inst(
    .clk(clk),
    .rst(rst),
    .we(we),
    .instr(instr),
    .out0(out0),
    .out1(out1),
    .out2(out2),
    .out3(out3)
);

// Clock
always #5 clk = ~clk;


initial begin

    clk = 0;
    rst = 1;
    we  = 0;
    instr = 32'd0;

    #20;
    rst = 0;

    top_inst.RF0.registers[1] = 32'd1;
    top_inst.RF0.registers[2] = 32'd10;

    top_inst.RF1.registers[1] = 32'd2;
    top_inst.RF1.registers[2] = 32'd20;

    top_inst.RF2.registers[1] = 32'd3;
    top_inst.RF2.registers[2] = 32'd30;

    top_inst.RF3.registers[1] = 32'd4;
    top_inst.RF3.registers[2] = 32'd40;

    // ADD x3, x1, x2

    instr[6:0]   = 7'b0001111;
    instr[11:7]  = 5'd3;
    instr[19:15] = 5'd1;
    instr[24:20] = 5'd2;

    #20;

    $display("--------------------------");
    $display("Core0 = %d", out0);
    $display("Core1 = %d", out1);
    $display("Core2 = %d", out2);
    $display("Core3 = %d", out3);
    $display("--------------------------");

    #20;
    $finish;

end

endmodule
