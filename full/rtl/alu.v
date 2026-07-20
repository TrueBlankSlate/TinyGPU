module ALU(
    input wire [31:0] a,
    input wire [31:0] b,
    input [6:0] opcode,
    output reg [31:0] x
);
    always @(*) begin
        case (opcode)
            7'b0000001: x = $signed(a) + $signed(b); //add
            7'b0000010: x = $signed(a) - $signed(b); //subtract
            7'b0000011: x = a|b; //or
            7'b0000100: x = a^b; //xor
            7'b0000101: x = a&b; //and
            7'b0000110: x = ~(a&b); //nand
          	7'b0000111: x = ~(a|b); //nor
            7'b0001000: x = a>>b[4:0]; //right shift
            7'b0001001: x = a<<b[4:0]; //left shift
          	7'b0001010: x = a>>>b[4:0]; //arithmetic right shift
          	7'b0001011: x = a<<<b[4:0]; //arightmetic left shift
            7'b0001100: x = ~a; //not of a
            7'b0001101: x = ~b; //not of b
            7'b0001111: x = $signed(a)*$signed(b); //multiply
            7'b0000000: x = (b!=0)?($signed(a)/$signed(b)):32'b0; //divide a by b
            default: x = 0;
        endcase
    end
endmodule
