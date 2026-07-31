`timescale 1ns/1ps

module tb;

reg clk;
reg rst_cache;
reg rst_rf;

reg        gw_we;
reg [4:0]  gw_addr;
reg [127:0] gw_data;

reg [31:0] instruction;
reg we;

wire [31:0] vd0;
wire [31:0] vd1;
wire [31:0] vd2;
wire [31:0] vd3;

design_1_wrapper dut(
    .clk_0(clk),
    .gw_addr_0(gw_addr),
    .gw_data_0(gw_data),
    .gw_we_0(gw_we),
    .instruction_0(instruction),
    .rst_0(rst_cache),
    .rst_1(rst_rf),
    .vd_0(vd0),
    .vd_1(vd1),
    .vd_2(vd2),
    .vd_3(vd3),
    .we_0(we)
);

always #5 clk = ~clk;

task write_vec;
input [4:0] addr;
input [31:0] e0,e1,e2,e3;
begin
    @(posedge clk);
    gw_we   <= 1;
    gw_addr <= addr;
    gw_data <= {e3,e2,e1,e0};
    @(posedge clk);
    gw_we <= 0;
end
endtask

task run_instr;
input [5:0] func6;
input [2:0] func3;
input [4:0] vs2;
input [4:0] vs1;
input [4:0] vd;
begin
    instruction = {func6,1'b0,vs2,vs1,func3,vd,7'b1010111};

    we = 1;
    @(posedge clk);
    we = 0;

    repeat(2) @(posedge clk);

    $display("--------------------------------");
    $display("time = %0t",$time);
    $display("instruction = %h",instruction);
    $display("vd0 = %0d",vd0);
    $display("vd1 = %0d",vd1);
    $display("vd2 = %0d",vd2);
    $display("vd3 = %0d",vd3);
end
endtask

initial begin

    clk = 0;
    rst_cache = 1;
    rst_rf = 1;

    gw_we = 0;
    gw_addr = 0;
    gw_data = 0;

    instruction = 0;
    we = 0;

    repeat(2) @(posedge clk);

    rst_cache = 0;

    write_vec(5'd1,32'd1,32'd2,32'd3,32'd4);
    write_vec(5'd2,32'd10,32'd20,32'd30,32'd40);

    rst_rf = 0;

    $display("\n===== VADD.VV =====");
    run_instr(6'b000000,3'b000,5'd2,5'd1,5'd0);

    $display("Expected:");
    $display("11 22 33 44");

    $display("\n===== VSUB.VV =====");
    run_instr(6'b000010,3'b000,5'd2,5'd1,5'd0);

    $display("Expected:");
    $display("9 18 27 36");

    $display("\n===== VMUL.VV =====");
    run_instr(6'b100101,3'b000,5'd2,5'd1,5'd0);

    $display("Expected:");
    $display("10 40 90 160");

    write_vec(5'd3,32'd1,32'd2,32'd3,32'd4);
    write_vec(5'd4,32'd5,32'd6,32'd7,32'd8);

    $display("\n===== VMACC.VV =====");
    run_instr(6'b101101,3'b010,5'd4,5'd3,5'd0);
    
    $display("matmul = %b", dut.design_1_i.decoder_0_matmul_out);
    $display("opcode=%b func3=%b func6=%b matmul=%b",
    dut.design_1_i.decoder_0.opcode,
    dut.design_1_i.decoder_0.func3_out,
    dut.design_1_i.decoder_0.instr_id,
    dut.design_1_i.decoder_0.matmul_out);

    $display("Expected:");
    $display("vd0 = 19");
    $display("vd1 = 22");
    $display("vd2 = 43");
    $display("vd3 = 50");

    #50;
    $finish;

end

endmodule
