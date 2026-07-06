`timescale 1ns/1ps
module alu_tb;
    reg [31:0] a, b;
    reg [3:0] opcode;
    wire [31:0] x;

    ALU inst1(.a(a), .b(b), .opcode(opcode), .x(x));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, alu_tb);
        a=0; b=0; opcode=0;
        #10 a=15; b=10; opcode=4'b0001;
        #10 a=15; b=10; opcode=4'b0010;
        #10 a=32'h000A; b=32'h000B; opcode=4'b0011;
        #10 opcode=4'b0100;
        #10 opcode=4'b0101;
        #10 opcode=4'b0110;
        #10 opcode=4'b0111;
        #10 a=32'hA0; b=2; opcode=4'b1000;
        #10 opcode=4'b1001;
        #10 a=-32'd4; b=2; opcode=4'b1010;
        #10 opcode=4'b1011;
        #10 a=32'h000A; opcode=4'b1100;
        #10 b=32'h000A; opcode=4'b1101;
        #10 a=7; b=6; opcode=4'b1111;
        #10 a=123; opcode=4'b0000;
        #10 $finish;
    end

    initial $monitor("t=%0t opcode=%b a=%d b=%d x=%d", $time, opcode, a, b, x);
endmodule
