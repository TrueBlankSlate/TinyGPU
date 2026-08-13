module l3_cache(
    input clk,
    input rst,
    input we,

    input [4:0] vs1,
    input [4:0] vs2,

    // Two 4x4 matrices of 64-bit elements: 2 * 4 * 4 * 64 = 2048 bits.
    input [2047:0] w_data,

    input [1:0] pass,
    input [2:0] func3,
    input [5:0] instr_id,

    output reg [255:0] core0_a,
    output reg [255:0] core0_b,
    output reg [255:0] core1_a,
    output reg [255:0] core1_b,
    output reg [255:0] core2_a,
    output reg [255:0] core2_b,
    output reg [255:0] core3_a,
    output reg [255:0] core3_b
);

// Each cache entry is one 4x4, 64-bit-element matrix (1024 bits).
reg [1023:0] mat_mem [0:31];

integer i;

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < 32; i = i + 1)
            mat_mem[i] <= 1024'd0;
    end
    else if (we) begin
        // One cache-line fill installs both source matrices atomically.
        mat_mem[vs1] <= w_data[1023:0];
        mat_mem[vs2] <= w_data[2047:1024];
    end
end

always @(*) begin
    // Existing SIMD primitives consume their current 128-bit quadrants.
    // The full 1024-bit matrices remain resident for future wider cores.
    core0_a = mat_mem[vs1][255:0];
    core0_b = mat_mem[vs2][255:0];
    core1_a = mat_mem[vs1][511:256];
    core1_b = mat_mem[vs2][511:256];
    core2_a = mat_mem[vs1][767:512];
    core2_b = mat_mem[vs2][767:512];
    core3_a = mat_mem[vs1][1023:768];
    core3_b = mat_mem[vs2][1023:768];
end

endmodule
