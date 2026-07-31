module RegisterFile(
    input wire clk,
    input wire rst,
    input wire we,

    input wire [31:0] in0,
    input wire [31:0] in1,
    input wire [31:0] in2,
    input wire [31:0] in3,

    output reg [31:0] out0,
    output reg [31:0] out1,
    output reg [31:0] out2,
    output reg [31:0] out3
);

always @(posedge clk) begin
    if (rst) begin
        out0 <= 32'd0;
        out1 <= 32'd0;
        out2 <= 32'd0;
        out3 <= 32'd0;
    end
    else if (we) begin
        out0 <= in0;
        out1 <= in1;
        out2 <= in2;
        out3 <= in3;
    end
end

endmodule