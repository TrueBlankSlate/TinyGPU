module cache(
    input clk,
    input rst,
    input we,
    input [2:0] func3,
    input [5:0] instr_id,

    input [255:0] mat_a,  // current row from L3 (changes per pass)
    input [255:0] mat_b,  // fixed col for this core

    output wire [63:0] a0, a1, a2, a3,
    output wire [63:0] b0, b1, b2, b3
);

reg [255:0] reg_a;
reg [255:0] reg_b;

wire vmacc = (func3 == 3'b010 && instr_id == 6'h2D);

always @(posedge clk) begin
    if(rst) begin
        reg_a <= 256'd0;
        reg_b <= 256'd0;
    end
    else begin
        reg_a <= mat_a;
        if(!vmacc || reg_b == 128'd0)  // only load col once
            reg_b <= mat_b;
    end
end

// each lane gets one element of row and one element of col
assign a0 = reg_a[63:0];
assign a1 = reg_a[127:64];
assign a2 = reg_a[191:128];
assign a3 = reg_a[255:192];

assign b0 = reg_b[63:0];
assign b1 = reg_b[127:63];
assign b2 = reg_b[191:128];
assign b3 = reg_b[255:192];

endmodule