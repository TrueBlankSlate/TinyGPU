module ALU(
    input  [2:0]  opcode,
    input  [31:0] A,
    input  [31:0] B,




    output reg [32:0] ANS,
    output reg overflow,
    output reg zero,
    output reg div_by_zero



);

wire signed [31:0] sA = A;


always @(*) begin

    // Defaults
    ANS         = 33'd0;
    overflow    = 1'b0;
    zero        = 1'b0;
    div_by_zero = 1'b0;



    case(opcode)

        // ADD
        3'b000: begin
            ANS = A + B;
            overflow = (A[31] == B[31]) && (ANS[31] != A[31]);
        end

        // SUB
        3'b001: begin
            ANS = A - B;
            overflow = (A[31] != B[31]) && (ANS[31] != A[31]);
        end

        // AND
       
        3'b010:ANS = {1'b0, A & B};

        // OR
        
        3'b011:ANS = {1'b0, A | B};

        // XOR
        
        3'b100:ANS = {1'b0, A ^ B};

        // Arithmetic Right Shift
        
        3'b101:ANS = {1'b0, sA >>> B[4:0]};

        // Division
       
        3'b110: begin
           
            if(B==0) begin
                div_by_zero = 1;
                ANS = 33'h1FFFFFFFF;
            end
           
           
            else
                ANS = {1'b0,A/B};
       
        end

        default:
            ANS = 0;

    endcase

    zero = (ANS[31:0] == 0);

end

endmodule