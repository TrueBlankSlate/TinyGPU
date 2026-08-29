module l3_cache(
    input clk,
    input rst,
    input req,      // write request from tinygpu_fsm
    output reg ready, // 1-cycle pulse: request accepted, write landed

    input [1:0] vs1,
    input [1:0] vs2,

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
reg [1023:0] mat_mem [0:3];

integer i;

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < 4; i = i + 1)
            mat_mem[i] <= 1024'd0;
        ready <= 1'b0;
    end
    else if (req) begin
        // One cache-line fill installs both source matrices atomically.
        mat_mem[vs1] <= w_data[1023:0];
        mat_mem[vs2] <= w_data[2047:1024];
        ready <= 1'b1;
    end
    else begin
        ready <= 1'b0;
    end
end

wire is_vmacc = (func3 == 3'b010) && (instr_id == 6'h2D);

always @(*) begin
    if (is_vmacc) begin
        core0_a = mat_mem[vs1][pass*256 +: 256];
        core1_a = mat_mem[vs1][pass*256 +: 256];
        core2_a = mat_mem[vs1][pass*256 +: 256];
        core3_a = mat_mem[vs1][pass*256 +: 256];

        core0_b = { mat_mem[vs2][12*64 +: 64], mat_mem[vs2][8*64 +: 64], mat_mem[vs2][4*64 +: 64], mat_mem[vs2][0*64 +: 64] };
        core1_b = { mat_mem[vs2][13*64 +: 64], mat_mem[vs2][9*64 +: 64], mat_mem[vs2][5*64 +: 64], mat_mem[vs2][1*64 +: 64] };
        core2_b = { mat_mem[vs2][14*64 +: 64], mat_mem[vs2][10*64 +: 64], mat_mem[vs2][6*64 +: 64], mat_mem[vs2][2*64 +: 64] };
        core3_b = { mat_mem[vs2][15*64 +: 64], mat_mem[vs2][11*64 +: 64], mat_mem[vs2][7*64 +: 64], mat_mem[vs2][3*64 +: 64] };
    end else begin
        
        core0_a = { mat_mem[vs1][12*64 +: 64], mat_mem[vs1][8*64 +: 64], mat_mem[vs1][4*64 +: 64], mat_mem[vs1][0*64 +: 64] };
        core0_b = { mat_mem[vs2][12*64 +: 64], mat_mem[vs2][8*64 +: 64], mat_mem[vs2][4*64 +: 64], mat_mem[vs2][0*64 +: 64] };
        core1_a = { mat_mem[vs1][13*64 +: 64], mat_mem[vs1][9*64 +: 64], mat_mem[vs1][5*64 +: 64], mat_mem[vs1][1*64 +: 64] };
        core1_b = { mat_mem[vs2][13*64 +: 64], mat_mem[vs2][9*64 +: 64], mat_mem[vs2][5*64 +: 64], mat_mem[vs2][1*64 +: 64] };
        core2_a = { mat_mem[vs1][14*64 +: 64], mat_mem[vs1][10*64 +: 64], mat_mem[vs1][6*64 +: 64], mat_mem[vs1][2*64 +: 64] };
        core2_b = { mat_mem[vs2][14*64 +: 64], mat_mem[vs2][10*64 +: 64], mat_mem[vs2][6*64 +: 64], mat_mem[vs2][2*64 +: 64] };
        core3_a = { mat_mem[vs1][15*64 +: 64], mat_mem[vs1][11*64 +: 64], mat_mem[vs1][7*64 +: 64], mat_mem[vs1][3*64 +: 64] };
        core3_b = { mat_mem[vs2][15*64 +: 64], mat_mem[vs2][11*64 +: 64], mat_mem[vs2][7*64 +: 64], mat_mem[vs2][3*64 +: 64] };
    end
end

endmodule
