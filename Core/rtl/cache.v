module cache(
    input wire clk,
    input wire rst,
    input wire [4:0] vs1,
    input wire [4:0] vs2,
    input wire [2:0] func3,
    input wire [5:0] instr_id,
    input wire we,        // RF latch signal - used to advance pass
    input wire gw_we,
    input wire [4:0]  gw_addr,
    input wire [127:0] gw_data,
    output wire [31:0] a0, a1, a2, a3,
    output wire [31:0] b0, b1, b2, b3
);

reg [127:0] vector_cache [0:31];
reg [1:0] pass;
integer i;

wire vmacc = (func3 == 3'b010 && instr_id == 6'h2D);

always @(posedge clk) begin
    if (rst) begin
        for(i = 0; i < 32; i = i+1)
            vector_cache[i] <= 128'd0;
        pass <= 2'd0;
    end
    else begin
        if(gw_we)
            vector_cache[gw_addr] <= gw_data;

        if(vmacc && we) begin
            if(pass == 2'd1)
                pass <= 2'd0;  // reset after 2 passes
            else
                pass <= pass + 1;
        end
        else if(!vmacc)
            pass <= 2'd0;  // reset pass when not doing vmacc
    end
end

// normal mode: each lane gets different element
// vmacc mode: all lanes in a pair get same element (broadcast), selected by pass
assign a0 = vmacc ? vector_cache[vs1][pass*32 +: 32]     : vector_cache[vs1][31:0];
assign a1 = vmacc ? vector_cache[vs1][pass*32 +: 32]     : vector_cache[vs1][63:32];
assign a2 = vmacc ? vector_cache[vs1][(pass+2)*32 +: 32] : vector_cache[vs1][95:64];
assign a3 = vmacc ? vector_cache[vs1][(pass+2)*32 +: 32] : vector_cache[vs1][127:96];

assign b0 = vmacc ? vector_cache[vs2][(pass*2)*32    +: 32] : vector_cache[vs2][31:0];
assign b1 = vmacc ? vector_cache[vs2][(pass*2+1)*32  +: 32] : vector_cache[vs2][63:32];
assign b2 = vmacc ? vector_cache[vs2][(pass*2)*32    +: 32] : vector_cache[vs2][95:64];
assign b3 = vmacc ? vector_cache[vs2][(pass*2+1)*32  +: 32] : vector_cache[vs2][127:96];

endmodule