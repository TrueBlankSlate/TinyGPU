`timescale 1ns/1ps

module tb;

reg clk;
reg rst;
reg we;

reg [4:0] rs1;
reg [4:0] rs2;
reg [4:0] rd;

reg [31:0] write_data;
reg [3:0] opcode;

wire [31:0] alu_out;
wire [31:0] a;
wire [31:0] b;

Top top_inst_1(

    .clk(clk),
    .rst(rst),
    .we(we),

    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),

    .write_data(write_data),

    .opcode(opcode),

    .alu_out(alu_out),

    .a(a),
    .b(b)

);

always #5 clk = ~clk;

initial begin

    $dumpfile("dump.vcd");
    $dumpvars(0, top_inst_1);

    clk = 0;
    we = 0;

    rs1 = 0;
    rs2 = 0;
    rd = 0;
    write_data = 0;
    opcode = 0;

    // Write 25 into R1
    #10; we = 1; rd = 5'b00001; write_data = 32'd45; 

    // Write 15 into R2
    #10; rd = 5'b00010; write_data = 32'd15;

    // Read registers
    #10 we = 0; rs1 = 5'b00001; rs2 = 5'd2;

    #10 opcode = 4'b0001;   // ADD

    #10 opcode = 4'b0010;   // SUB

    #10 opcode = 4'b0101;   // AND

    #10 opcode = 4'b0011;   // OR

    #10 opcode = 4'b0100;   // XOR

    #10 opcode = 4'b1111;   // MUL

    #10 opcode = 4'b0000;   // DIV

    #10 $finish;


end
  initial $monitor("t=%0t opcode=%b a=%d b=%d output_alu=%d", $time, opcode, a, b, alu_out);

endmodule
