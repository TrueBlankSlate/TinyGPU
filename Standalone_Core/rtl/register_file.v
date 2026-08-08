module RegisterFile(
    input clk,
    input rst,
    input we,
    input [31:0] vs1_in,
    input [31:0] vs2_in,
    output reg [31:0] vs1_out,
    output reg [31:0] vs2_out
);

always @(posedge clk) begin
    if (rst) begin
        vs1_out <= 32'd0;
        vs2_out <= 32'd0;
    end
    else if (we) begin
        vs1_out <= vs1_in;
        vs2_out <= vs2_in;
    end
end
endmodule
