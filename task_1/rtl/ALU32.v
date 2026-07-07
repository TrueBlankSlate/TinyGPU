// Code your design here
module ALU(
    input wire [31:0] a,
    input wire [31:0] b,
    input [3:0] opcode,
    output reg [31:0] x
);
    always @(*) begin
        case (opcode)
            4'b0001: x = $signed(a) + $signed(b); //add
            4'b0010: x = $signed(a) - $signed(b); //subtract
            4'b0011: x = a|b; //or
            4'b0100: x = a^b; //xor
            4'b0101: x = a&b; //and
            4'b0110: x = ~(a&b); //nand
          	4'b0111: x = ~(a|b); //nor
            4'b1000: x = a>>b[4:0]; //right shift
            4'b1001: x = a<<b[4:0]; //left shift
          	4'b1010: x = $signed(a)>>>b[4:0]; //arithmetic right shift
          	4'b1011: x = $signed(a)<<<b[4:0]; //arightmetic left shift
            4'b1100: x = ~a; //not of a
            4'b1101: x = ~b; //not of b
            4'b1111: x = a*b; //multiply
            4'b0000: x = (b!=0)?a/b:32'b0; //divide a by b
            default: x = 0;
        endcase
    end
endmodule
