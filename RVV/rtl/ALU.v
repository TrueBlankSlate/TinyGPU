module ALU(
    input [5:0] instr_id,
    input [2:0] func3,

    input [31:0] a1,
    input [31:0] a2,
    input [31:0] b1,
    input [31:0] b2,

    output reg [31:0] vd
);

wire signed [31:0] s_a1 = a1;
wire signed [31:0] s_a2 = a2;
wire signed [31:0] s_b1 = b1;
wire signed [31:0] s_b2 = b2;

wire signed [63:0] sp1 = s_a1 * s_b1;
wire signed [63:0] sp2 = s_a2 * s_b2;

wire [63:0] up1 = a1 * b1;
wire [63:0] up2 = a2 * b2;

always @(*) begin
    vd = 32'd0;

    case(func3)

    // OPIVV
    3'b000: begin
        case(instr_id)
            6'b000000: vd = s_b1 + s_a1; //vadd.vv
            6'h02: vd = s_b1 - s_a1; //vsub.vv
            6'h25: vd = sp1[31:0]; //vmul.vv
            6'h27: vd = sp1[63:32];//vmulh.vv
            6'h29: vd = up1[63:32];//vmulhu.vv
            6'h21: vd = (s_a1 != 0) ? (s_b1 / s_a1) : 32'd0; //vdiv.vv
            6'h23: vd = s_b1 % s_a1; //random filler
            6'h09: vd = b1 & a1;
            6'h0A: vd = b1 | a1;
            6'h0B: vd = b1 ^ a1;
            6'h04: vd = b1 << a1[4:0];
            6'h05: vd = b1 >> a1[4:0];
            6'h07: vd = s_b1 >>> a1[4:0];
            default: vd = 32'd0;
        endcase
    end

    // vmacc.vv used as Matrix Multiply
    3'b010: begin
        case(instr_id)
            // Dot product
            6'h2D: vd = sp1[31:0] + sp2[31:0]; //matmul done on hardware level!!! :)))
            default: vd = 32'd0;
        endcase
    end

    // OPFVV //floating point arithmetic. not in use rn
    3'b011: begin
        case(instr_id)
            6'h00: vd = s_b1 + s_a1;
            6'h09: vd = b1 & a1;
            6'h0A: vd = b1 | a1;
            6'h0B: vd = b1 ^ a1;
            6'h04: vd = b1 << a1[4:0];
            6'h05: vd = b1 >> a1[4:0];
            6'h07: vd = s_b1 >>> a1[4:0];
            default: vd = 32'd0;
        endcase
    end

    default: vd = 32'd0;

    endcase
end
endmodule
