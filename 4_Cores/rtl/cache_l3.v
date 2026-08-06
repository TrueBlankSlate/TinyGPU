module L3_cache(
    input wire clk,
    input wire rst,

    input wire [4:0] vs1,
    input wire [4:0] vs2,
    input wire [2:0] func3,
    input wire [5:0] instr_id,
    input wire we,

    input wire gw_we,
    input wire [4:0] gw_addr,
    input wire [511:0] gw_data,

    output wire [127:0] a0,
    output wire [127:0] a1,
    output wire [127:0] a2,
    output wire [127:0] a3,

    output wire [127:0] b0,
    output wire [127:0] b1,
    output wire [127:0] b2,
    output wire [127:0] b3
);

reg [511:0] vector_cache [0:31];

integer i;

always @(posedge clk) begin
    if(rst) begin
        for(i = 0; i < 32; i = i + 1)
            vector_cache[i] <= 512'd0;
    end
    else begin
        if(gw_we)
            vector_cache[gw_addr] <= gw_data;
    end
end

// VS1 distribution
assign a0 = vector_cache[vs1][127:0];
assign a1 = vector_cache[vs1][255:128];
assign a2 = vector_cache[vs1][383:256];
assign a3 = vector_cache[vs1][511:384];

// VS2 distribution
assign b0 = vector_cache[vs2][127:0];
assign b1 = vector_cache[vs2][255:128];
assign b2 = vector_cache[vs2][383:256];
assign b3 = vector_cache[vs2][511:384];

endmodule