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

wire signed [63:0] s_vs1 = vs1;                // #changed
wire signed [63:0] s_vs2 = vs2;                // #changed
wire signed [127:0] signed_prod = s_vs1 * s_vs2;   // #changed
wire [127:0] unsigned_prod = vs1 * vs2;            // #changed

reg [63:0] acc;                                // #changed

always @(posedge clk) begin
    if (rst)
        acc <= 64'd0;                          // #changed
    else if (acc_rst) begin
        if (we && func3 == 3'b010 && instr_id == 6'h2D)
            acc <= signed_prod[63:0];          // start new accumulation with this cycle's product
        else
            acc <= 64'd0;                      // plain clear, no MAC this cycle
    end
    else if (we && func3 == 3'b010 && instr_id == 6'h2D)
        acc <= acc + signed_prod[63:0];        // #changed
end

always @(*) begin
    vd = 64'd0;                                // #changed
    case(func3)
    3'b000: begin
        case(instr_id)
            6'h00: vd = s_vs1 + s_vs2;
            6'h02: vd = s_vs2 - s_vs1;
            6'h25: vd = signed_prod[63:0];             // #changed
            6'h27: vd = signed_prod[127:64];           // #changed
            6'h29: vd = unsigned_prod[127:64];         // #changed
            6'h21: vd = (s_vs1!=0) ? (s_vs2/s_vs1) : 64'd0; // #changed
            6'h23: vd = s_vs2 % s_vs1;
            6'h09: vd = vs2 & vs1;
            6'h0A: vd = vs2 | vs1;
            6'h0B: vd = vs2 ^ vs1;
            6'h04: vd = vs2 << vs1[5:0];               // #changed
            6'h05: vd = vs2 >> vs1[5:0];               // #changed
            6'h07: vd = s_vs2 >>> vs1[5:0];            // #changed
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
            6'h00: vd = s_vs2 + s_vs1;
            6'h09: vd = vs2 & vs1;
            6'h0A: vd = vs2 | vs1;
            6'h0B: vd = vs2 ^ vs1;
            6'h04: vd = vs2 << vs1[5:0];              // #changed
            6'h05: vd = vs2 >> vs1[5:0];              // #changed
            6'h07: vd = s_vs2 >>> vs1[5:0];           // #changed
            default: vd = 64'd0;                      // #changed
        endcase
    end
    default: vd = 64'd0;                              // #changed
    endcase
end

endmodule
    
