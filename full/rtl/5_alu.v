module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [6:0]  opcode,
    output reg  [31:0] x
);
    always @(*) begin
        case (opcode)
            7'b0000001: x = $signed(a) + $signed(b);
            7'b0000010: x = $signed(a) - $signed(b);
            7'b0000011: x = a | b;
            7'b0000100: x = a ^ b;
            7'b0000101: x = a & b;
            7'b0000110: x = ~(a & b);
            7'b0000111: x = ~(a | b);
            7'b0001000: x = a >> b[4:0];
            7'b0001001: x = a << b[4:0];
            7'b0001010: x = $signed(a) >>> b[4:0];
            7'b0001011: x = $signed(a) <<< b[4:0];
            7'b0001100: x = ~a;
            7'b0001101: x = ~b;
            7'b0001111: x = $signed(a) * $signed(b);
            7'b0000000: x = (b != 0) ? ($signed(a) / $signed(b)) : 32'b0;
            default:    x = 32'b0;
        endcase
    end
endmodule
