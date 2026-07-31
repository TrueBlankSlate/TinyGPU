module cache(
    input wire clk,
    input wire rst,
    input wire [4:0] vs1,
    input wire [4:0] vs2,

    input wire matmul,

    input wire gw_we,
    input wire [4:0]  gw_addr,
    input wire [127:0] gw_data,

    output reg [31:0] a0,
    output reg [31:0] b0,
    output reg [31:0] c0,
    output reg [31:0] d0,

    output reg [31:0] a1,
    output reg [31:0] b1,
    output reg [31:0] c1,
    output reg [31:0] d1,

    output reg [31:0] a2,
    output reg [31:0] b2,
    output reg [31:0] c2,
    output reg [31:0] d2,

    output reg [31:0] a3,
    output reg [31:0] b3,
    output reg [31:0] c3,
    output reg [31:0] d3
);

reg [127:0] vector_cache [0:31];

integer i;

    always @(posedge clk) begin
        if (rst) begin
            for(i = 0; i < 32; i = i + 1)
                vector_cache[i] <= 128'd0;
        end
        else if(gw_we) begin
            vector_cache[gw_addr] <= gw_data;
        end
    end

    always @(*) begin
        a0 = 32'd0; b0 = 32'd0; c0 = 32'd0; d0 = 32'd0;
        a1 = 32'd0; b1 = 32'd0; c1 = 32'd0; d1 = 32'd0;
        a2 = 32'd0; b2 = 32'd0; c2 = 32'd0; d2 = 32'd0;
        a3 = 32'd0; b3 = 32'd0; c3 = 32'd0; d3 = 32'd0;

        if(matmul) begin

            // RF0 -> ALU0 computes C00
            a0 = vector_cache[vs1][31:0];
            b0 = vector_cache[vs1][63:32];
            c0 = vector_cache[vs2][31:0]; 
            d0 = vector_cache[vs2][95:64];

            // RF1 -> ALU1 computes C01
            a1 = vector_cache[vs1][31:0]; 
            b1 = vector_cache[vs1][63:32];
            c1 = vector_cache[vs2][63:32];
            d1 = vector_cache[vs2][127:96];

            // RF2 -> ALU2 computes C10
            a2 = vector_cache[vs1][95:64];
            b2 = vector_cache[vs1][127:96];
            c2 = vector_cache[vs2][31:0];
            d2 = vector_cache[vs2][95:64];
            
            // RF3 -> ALU3 computes C11
            a3 = vector_cache[vs1][95:64];
            b3 = vector_cache[vs1][127:96];
            c3 = vector_cache[vs2][63:32];
            d3 = vector_cache[vs2][127:96];

        end
        else begin
            // RF0
            a0 = vector_cache[vs1][31:0];
            c0 = vector_cache[vs2][31:0];
            // RF1
            a1 = vector_cache[vs1][63:32];
            c1 = vector_cache[vs2][63:32];
            // RF2
            a2 = vector_cache[vs1][95:64];
            c2 = vector_cache[vs2][95:64];
            // RF3
            a3 = vector_cache[vs1][127:96];
            c3 = vector_cache[vs2][127:96];
        end
    end

endmodule