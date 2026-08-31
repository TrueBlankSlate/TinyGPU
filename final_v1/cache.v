module cache(
    input clk,
    input rst,
    input we,
    input [2:0] func3,
    input [5:0] instr_id,

    // data comes from L3
    input [255:0] mat_a,  // row from A [i]
    input [255:0] mat_b,  // col from B [j]

    output wire [63:0] a0, a1, a2, a3,
    output wire [63:0] b0, b1, b2, b3
);

// sent all the pass logic to L3 cache so this cache becomes purely combinational.
assign a0 = mat_a[63:0];
assign a1 = mat_a[127:64];
assign a2 = mat_a[191:128];
assign a3 = mat_a[255:192];

assign b0 = mat_b[63:0];
assign b1 = mat_b[127:64];
assign b2 = mat_b[191:128];
assign b3 = mat_b[255:192];

endmodule