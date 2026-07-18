`timescale 1ns/1ps

module ALU_tb;

reg [3:0] opcode; // Updated to 4 bits to match the new ALU design
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

// Generate waveform for GTKWave
initial begin
    $dumpfile("alu.vcd");
    $dumpvars(0, ALU_tb);
end

initial begin

    // ADD
    opcode = 4'b0000;
    A = 20;
    B = 10;
    #10;
    $display("ADD  : %d + %d = %d", A, B, ANS);

    // SUB
    opcode = 4'b0001;
    A = 20;
    B = 5;
    #10;
    $display("SUB  : %d - %d = %d", A, B, ANS);

    // AND
    opcode = 4'b0010;
    A = 32'hF0F0;
    B = 32'h0FF0;
    #10;
    $display("AND  : %h", ANS);

    // OR
    opcode = 4'b0011;
    #10;
    $display("OR   : %h", ANS);

    // XOR
    opcode = 4'b0100;
    #10;
    $display("XOR  : %h", ANS);

    // Arithmetic Right Shift
    opcode = 4'b0101;
    A = 32'h80000000;
    B = 4;
    #10;
    $display("SRA  : %h", ANS);

    // DIV
    opcode = 4'b0110;
    A = 100;
    B = 5;
    #10;
    $display("DIV  : %d", ANS);

    // DIV BY ZERO
    B = 0;
    #10;
    $display("DIV0 : Flag = %b", div_by_zero);

    // MULTIPLICATION
    opcode = 4'b0111;
    A = 50;
    B = 4;
    #10;
    $display("MUL  : %d * %d = %d", A, B, ANS);

    // Logical Shift Left
    opcode = 4'b1000;
    A = 32'h0000000F;
    B = 4;
    #10;
    $display("SLL  : %h", ANS);

    // Logical Shift Right
    opcode = 4'b1001;
    A = 32'hF0000000;
    B = 4;
    #10;
    $display("SRL  : %h", ANS);

    // NOT
    opcode = 4'b1010;
    A = 32'hAAAA_AAAA;
    #10;
    $display("NOT  : ~%h = %h", A, ANS);

    $finish;

end

endmodule

