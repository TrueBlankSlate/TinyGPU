module cache(
    input clk,
    input rst,
    input we,
    input [2:0] func3,
    input [5:0] instr_id,

    // data comes from L3
    input [127:0] mat_a,  // 2x2 quadrant of A
    input [127:0] mat_b,  // 2x2 quadrant of B

    output wire [31:0] a0, a1, a2, a3,
    output wire [31:0] b0, b1, b2, b3
);

reg [127:0] reg_a;
reg [127:0] reg_b;
reg [1:0] pass;
reg we_prev;

wire vmacc = (func3 == 3'b010 && instr_id == 6'h2D);

always @(posedge clk) begin
    if (rst) begin
        reg_a   <= 128'd0;
        reg_b   <= 128'd0;
        pass    <= 2'd0;
        we_prev <= 1'b0;
    end
    else begin
        reg_a <= mat_a;
        reg_b <= mat_b;
        we_prev <= we;

        if(vmacc && we_prev && !we) begin
            if(pass == 2'd1) pass <= 2'd0;
            else             pass <= pass + 1;
        end
        else if(!vmacc)
            pass <= 2'd0;
    end
end

// normal mode
assign a0 = !vmacc ? reg_a[31:0]   : reg_a[pass*32 +: 32];
assign a1 = !vmacc ? reg_a[63:32]  : reg_a[pass*32 +: 32];
assign a2 = !vmacc ? reg_a[95:64]  : reg_a[(pass+2)*32 +: 32];
assign a3 = !vmacc ? reg_a[127:96] : reg_a[(pass+2)*32 +: 32];

assign b0 = !vmacc ? reg_b[31:0]   : reg_b[(pass*2)*32   +: 32];
assign b1 = !vmacc ? reg_b[63:32]  : reg_b[(pass*2+1)*32 +: 32];
assign b2 = !vmacc ? reg_b[95:64]  : reg_b[(pass*2)*32   +: 32];
assign b3 = !vmacc ? reg_b[127:96] : reg_b[(pass*2+1)*32 +: 32];

endmodule