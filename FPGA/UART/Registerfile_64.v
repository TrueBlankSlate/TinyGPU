module RegisterFile(
    input clk,
    input rst,
    input we,
    input [63:0] vs1_in,                // #changed
    input [63:0] vs2_in,                // #changed
    output reg [63:0] vs1_out,          // #changed
    output reg [63:0] vs2_out           // #changed
);

always @(posedge clk) begin
    if (rst) begin       // #changed
        vs2_out <= 64'd0;        
        vs1_out <= 64'd0;               // #changed
    end
    else if (we) begin
        vs1_out <= vs1_in;
        vs2_out <= vs2_in;
    end
end

endmodule