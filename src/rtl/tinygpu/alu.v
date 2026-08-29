module ALU(
    input clk,
    input rst,      // system reset
    input acc_rst,  // clear accumulator between matmuls
    input we,
    input [5:0] instr_id,
    input [2:0] func3,
    input [63:0] vs1, vs2,
    output reg [63:0] vd
);

wire [127:0] unsigned_prod = vs1 * vs2;

reg [127:0] acc;

always @(posedge clk) begin
    if (rst || acc_rst)
        acc <= 32'd0;
    else if (we && func3 == 3'b010 && instr_id == 6'h2D)
        acc <= acc + unsigned_prod[63:0];
end

always @(*) begin
    vd = 64'd0;
    case(func3)
    3'b000: begin
        case(instr_id)
            6'h00: vd = vs1 + vs2;
            default: vd = 64'd0;
        endcase
    end
    3'b010: begin
        case(instr_id)
            // matmul: plain per-element product; the cross-ALU sum that
            // turns 4 products into one dot-product term happens in
            // design_1.v, not here (acc/acc_rst above are unused for vmacc).
            6'h2D: vd = unsigned_prod[63:0];
            default: vd = 64'd0;
        endcase
    end
    default: vd = 64'd0;
    endcase
end
endmodule
