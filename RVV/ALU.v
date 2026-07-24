module ALU(
    input [5:0] instr_id,
    input [2:0] func3,
    input [31:0] vs1,
    input [31:0] vs2,
    output reg [31:0] vd
);

wire signed [31:0] s_vs1 = vs1;
wire signed [31:0] s_vs2 = vs2;

wire signed [63:0] signed_prod = s_vs1 * s_vs2;
wire [63:0] unsigned_prod = vs1 * vs2;

always @(*) begin
    vd = 32'd0;

    case(func3)
    // OPIVV
    3'b000: begin
        case(instr_id)

            6'h00: vd = s_vs1 + s_vs2; // vadd.vv
            6'h02: vd = s_vs2 - s_vs1; // vsub.vv

            6'h25: vd = signed_prod[31:0]; // vmul.vv, lower 32 
            6'h27: vd = signed_prod[63:32]; // vmulh.vv, upper 32
            6'h29: vd = unsigned_prod[63:32]; // vmulhu.vv, unsigned upper 32

            6'h21: vd = (s_vs1 != 0) ? (s_vs2 / s_vs1) : 32'd0; // vdiv.vv
            6'h23: vd = s_vs2 % s_vs1; // vrem.vv

            6'h09: vd = vs2 & vs1; // vand.vv
            6'h0A: vd = vs2 | vs1; // vor.vv
            6'h0B: vd = vs2 ^ vs1; // vxor.vv

            6'h04: vd = vs2 << vs1[4:0]; // vsll.vv
            6'h05: vd = vs2 >> vs1[4:0]; // vsrl.vv
            6'h07: vd = s_vs2 >>> vs1[4:0]; // vsra.vv

            default: vd = 32'd0;

        endcase
    end

    // OPFVV
    3'b001: begin
        // Floating-point instructions.
        // Implement later using IEEE-754 FP units.
        vd = 32'd0;
    end

    // OPIVI
    3'b011: begin
        case(instr_id)

            6'h00: vd = s_vs2 + s_vs1;          // vadd.vi
            6'h09: vd = vs2 & vs1;              // vand.vi
            6'h0A: vd = vs2 | vs1;              // vor.vi
            6'h0B: vd = vs2 ^ vs1;              // vxor.vi

            6'h04: vd = vs2 << vs1[4:0];        // vsll.vi
            6'h05: vd = vs2 >> vs1[4:0];        // vsrl.vi
            6'h07: vd = s_vs2 >>> vs1[4:0];     // vsra.vi

            default: vd = 32'd0;

        endcase
    end

    default: vd = 32'd0; //flat

    endcase
end
endmodule
