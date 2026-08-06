module ALU(
    input clk,
    input rst,      // system reset
    input acc_rst,  // clear accumulator between matmuls
    input we,
    input [5:0] instr_id,
    input [2:0] func3,
    input [31:0] vs1, vs2,
    output reg [31:0] vd
);

wire signed [31:0] s_vs1 = vs1;
wire signed [31:0] s_vs2 = vs2;
wire signed [63:0] signed_prod = s_vs1 * s_vs2;
wire [63:0] unsigned_prod = vs1 * vs2;

reg [31:0] acc;

always @(posedge clk) begin
    if (rst || acc_rst)
        acc <= 32'd0;
    else if (we && func3 == 3'b010 && instr_id == 6'h2D)
        acc <= acc + signed_prod[31:0];
end

always @(*) begin
    vd = 32'd0;
    case(func3)
    3'b000: begin
        case(instr_id)
            6'h00: vd = s_vs1 + s_vs2;
            6'h02: vd = s_vs2 - s_vs1;
            6'h25: vd = signed_prod[31:0];
            6'h27: vd = signed_prod[63:32];
            6'h29: vd = unsigned_prod[63:32];
            6'h21: vd = (s_vs1!=0) ? (s_vs2/s_vs1) : 32'd0;
            6'h23: vd = s_vs2 % s_vs1;
            6'h09: vd = vs2 & vs1;
            6'h0A: vd = vs2 | vs1;
            6'h0B: vd = vs2 ^ vs1;
            6'h04: vd = vs2 << vs1[4:0];
            6'h05: vd = vs2 >> vs1[4:0];
            6'h07: vd = s_vs2 >>> vs1[4:0];
            default: vd = 32'd0;
        endcase
    end
    3'b010: begin
        case(instr_id)
            6'h2D: vd = acc; // show result combinationally
            default: vd = 32'd0;
        endcase
    end
    3'b011: begin
        case(instr_id)
            6'h00: vd = s_vs2 + s_vs1;
            6'h09: vd = vs2 & vs1;
            6'h0A: vd = vs2 | vs1;
            6'h0B: vd = vs2 ^ vs1;
            6'h04: vd = vs2 << vs1[4:0];
            6'h05: vd = vs2 >> vs1[4:0];
            6'h07: vd = s_vs2 >>> vs1[4:0];
            default: vd = 32'd0;
        endcase
    end
    default: vd = 32'd0;
    endcase
end
endmodule
