module cache(
    input clk,
    input rst,
    input [4:0] vs1,  
    input [4:0] vs2,  // which vector register is operand B

    input gw_we,
    input [4:0] gw_addr,
    input [127:0] gw_data,

    output [31:0] a0, a1, a2, a3,
    output [31:0] b0, b1, b2, b3
);

    // 32 vector registers, each holding 4 x 32-bit elements
    reg [127:0] vector_cache [0:31];

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i+1)
                vector_cache[i] <= 128'b0;
        end

        else if (gw_we) begin
            vector_cache[gw_addr] <= gw_data;
        end
    end

    assign a0 = vector_cache[vs1][31:0];
    assign a1 = vector_cache[vs1][63:32];
    assign a2 = vector_cache[vs1][95:64];
    assign a3 = vector_cache[vs1][127:96];

    assign b0 = vector_cache[vs2][31:0];
    assign b1 = vector_cache[vs2][63:32];
    assign b2 = vector_cache[vs2][95:64];
    assign b3 = vector_cache[vs2][127:96];

endmodule
