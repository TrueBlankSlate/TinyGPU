module cache(
    input clk,
    input rst,
    input we,
    input [2:0] func3,
    input [5:0] instr_id,

    // data comes from L3
    input [255:0] mat_a,  // 2x2 quadrant of A
    input [255:0] mat_b,  // 2x2 quadrant of B

    output wire [63:0] a0, a1, a2, a3,
    output wire [63:0] b0, b1, b2, b3
);

reg [255:0] reg_a;
reg [255:0] reg_b;

always @(posedge clk) begin
    if (rst) begin
        reg_a <= 256'd0;
        reg_b <= 256'd0;
    end
    else begin
        reg_a <= mat_a;
        reg_b <= mat_b;
    end
end

// L3 (cache_l3.v) already resolves row-vs-column addressing per instruction
// type (vmacc vs. normal SIMD); this stage just registers whatever 256-bit
// quadrant it was handed and slices it into four 64-bit elements.
assign a0 = reg_a[63:0];
assign a1 = reg_a[127:64];
assign a2 = reg_a[191:128];
assign a3 = reg_a[255:192];

assign b0 = reg_b[63:0];
assign b1 = reg_b[127:64];
assign b2 = reg_b[191:128];
assign b3 = reg_b[255:192];

endmodule