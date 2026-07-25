module RegisterFile(
    input wire clk,
    input wire rst,
    input wire we,

    input wire [31:0] vs1_in,  // a_n from cache
    input wire [31:0] vs2_in,  // b_n from cache

    output reg [31:0] vs1_out,
    output reg [31:0] vs2_out
);

    always @(posedge clk) begin
        if (rst) begin
            vs1_out <= 32'b0;
            vs2_out <= 32'b0;
        end
        else if (we) begin
            vs1_out <= vs1_in;
            vs2_out <= vs2_in;
        end
    end

endmodule