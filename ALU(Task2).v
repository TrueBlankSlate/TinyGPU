module ALU(
    input [3:0] opcode, // Expanded to 4 bits to accommodate more operations
    input [31:0] A,
    input [31:0] B,
    output reg [32:0] ANS,
    output reg overflow,
    output reg zero,
    output reg div_by_zero
);

wire signed [31:0] sA = A;

always @(*) begin
    // Defaults
    ANS = 33'd0;
    overflow = 1'b0;
    zero = 1'b0;
    div_by_zero = 1'b0;

    case(opcode)
        // ADD
        4'b0000: begin
            ANS = A + B;
            overflow = (A[31] == B[31]) && (ANS[31] != A[31]);
        end
        
        // SUB
        4'b0001: begin
            ANS = A - B;
            overflow = (A[31] != B[31]) && (ANS[31] != A[31]);
        end
        
        // AND
        4'b0010:ANS = {1'b0, A & B};
        
        // OR
        4'b0011:ANS = {1'b0, A | B};
        
        // XOR
        4'b0100:ANS = {1'b0, A ^ B};
        
        // Arithmetic Right Shift
        4'b0101:ANS = {1'b0, sA >>> B[4:0]};
        
        // Division
        4'b0110: begin
            if(B==0) begin
                div_by_zero = 1;
                ANS = 33'h1FFFFFFFF;
            end
            else ANS = {1'b0, A / B};
        end
        
        // Multiplication
        4'b0111: begin
            ANS = A * B; 
        end
        
        // Logical Shift Left
        4'b1000:ANS = {1'b0, A << B[4:0]};
        
        // Logical Shift Right
        4'b1001:ANS = {1'b0, A >> B[4:0]};
        
        // NOT (
        4'b1010:ANS = {1'b0, ~A};

        default: ANS = 0;
    endcase

    zero = (ANS[31:0] == 0);
end

endmodule
