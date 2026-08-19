module cache(
    input clk,
    input rst,
    input we,
    input [2:0] func3,
    input [5:0] instr_id,

    // data comes from L3
    input [255:0] mat_a,  // 2x2 quadrant of A  // #changed
    input [255:0] mat_b,  // 2x2 quadrant of B  // #changed

    output wire [63:0] a0, a1, a2, a3,         // #changed
    output wire [63:0] b0, b1, b2, b3,         // #changed
    output wire acc_rst                        // pulses one cycle at the start of a new matmul accumulation
);

reg [255:0] reg_a;                             // #changed
reg [255:0] reg_b;                             // #changed
reg [1:0] pass;
reg we_prev;
reg vmacc_prev;                                // tracks vmacc to detect the start of a new matmul stream

wire vmacc = (func3 == 3'b010 && instr_id == 6'h2D);

always @(posedge clk) begin
    if (rst) begin
        reg_a      <= 256'd0;                  // #changed
        reg_b      <= 256'd0;                  // #changed
        pass       <= 2'd0;
        we_prev    <= 1'b0;
        vmacc_prev <= 1'b0;
    end
    else begin
        reg_a <= mat_a;
        reg_b <= mat_b;
        we_prev <= we;
        vmacc_prev <= vmacc;

        if(vmacc && we_prev && !we) begin
            if(pass == 2'd1)
                pass <= 2'd0;
            else
                pass <= pass + 1;
        end
        else if(!vmacc)
            pass <= 2'd0;
    end
end

// acc_rst fires for exactly one cycle on the rising edge of vmacc,
// i.e. the first cycle of a new matmul instruction stream. It does NOT
// fire on the pass 0<->1 toggle within a stream, since those passes
// belong to the same accumulation.
assign acc_rst = vmacc && !vmacc_prev;

// normal mode
assign a0 = !vmacc ? reg_a[63:0]      : reg_a[pass*64 +: 64];          // #changed
assign a1 = !vmacc ? reg_a[127:64]    : reg_a[pass*64 +: 64];          // #changed
assign a2 = !vmacc ? reg_a[191:128]   : reg_a[(pass+2)*64 +: 64];      // #changed
assign a3 = !vmacc ? reg_a[255:192]   : reg_a[(pass+2)*64 +: 64];      // #changed

assign b0 = !vmacc ? reg_b[63:0]      : reg_b[(pass*2)*64   +: 64];    // #changed
assign b1 = !vmacc ? reg_b[127:64]    : reg_b[(pass*2+1)*64 +: 64];    // #changed
assign b2 = !vmacc ? reg_b[191:128]   : reg_b[(pass*2)*64   +: 64];    // #changed
assign b3 = !vmacc ? reg_b[255:192]   : reg_b[(pass*2+1)*64 +: 64];    // #changed

endmodule
