`timescale 1ns/1ps

module ALU_tb;

reg [2:0] opcode;
reg [31:0] A, B;

wire [32:0] ANS;
wire overflow, zero, div_by_zero;

ALU uut(
    .opcode(opcode),
    .A(A),
    .B(B),
    .ANS(ANS),
    .overflow(overflow),
    .zero(zero),
    .div_by_zero(div_by_zero)
);

initial begin

    // ADD
    opcode = 3'b000;
    A = 20;
    B = 10;
    #10;
    $display("ADD : %d + %d = %d", A, B, ANS);

    // SUB
    opcode = 3'b001;
    A = 20;
    B = 5;
    #10;
    $display("SUB : %d - %d = %d", A, B, ANS);

    // AND
    opcode = 3'b010;
    A = 32'hF0F0;
    B = 32'h0FF0;
    #10;
    $display("AND : %h", ANS);

    // OR
    opcode = 3'b011;
    #10;
    $display("OR  : %h", ANS);

    // XOR
    opcode = 3'b100;
    #10;
    $display("XOR : %h", ANS);

    // SHIFT RIGHT
    opcode = 3'b101;
    A = 32'h80000000;
    B = 4;
    #10;
    $display("SHIFT : %h", ANS);

    // DIV
    opcode = 3'b110;
    A = 100;
    B = 5;
    #10;
    $display("DIV : %d", ANS);

    // DIV BY ZERO
    B = 0;
    #10;
    $display("DIV0 : Flag=%b", div_by_zero);

    $finish;

end

endmodule