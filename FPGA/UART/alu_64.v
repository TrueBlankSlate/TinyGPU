module ALU(
    input clk,
    input rst,      // system reset
    input acc_rst,  // clear accumulator between matmuls
    input we,
    input [5:0] instr_id,
    input [2:0] func3,
    input [63:0] vs1, vs2,                     // #changed
    output reg [63:0] vd                       // #changed
);

                // #changed
    wire signed [63:0] signed_prod = vs1 * vs2;   // #changed
           // #changed
    (*use_dsp="yes"*)
reg [63:0] acc;                                // #changed

always @(posedge clk) begin
    if (rst || acc_rst)
        acc <= 64'd0;                          // #changed
    else if (we && func3 == 3'b010 && instr_id == 6'h2D)
        acc <= acc + signed_prod[63:0];        // #changed
end

always @(*) begin
    vd = 64'd0;                                // #changed
    case(func3)
    3'b000: begin
        case(instr_id)
            6'h00: vd = vs1 + vs2;
                  // #changed
            default: vd = 64'd0;                       // #changed
        endcase
    end
    3'b010: begin
        case(instr_id)
            6'h2D: vd = acc; // show result combinationally
            default: vd = 64'd0;                      // #changed
        endcase
    end
    3'b011: begin
        case(instr_id)
                      // #changed
            default: vd = 64'd0;                      // #changed
        endcase
    end
    default: vd = 64'd0;                              // #changed
    endcase
end

endmodule
