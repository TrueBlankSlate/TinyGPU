module fetcher(

    input  wire         clk,
    input  wire         rst,

    input  wire         fetch_req, //from scheduler
    input  wire [4:0]   rs1_addr, //
    input  wire [4:0]   rs2_addr, //
    input  wire [31:0]  instr, //
    input  wire [4:0]   rd_addr, //

    output reg  [4:0]   mem_addr_a, //to decoder
    input  wire [4:0]   rs1_addr,
    input  wire [4:0]   rs2_addr,
    input  wire [31:0]  instr,
    input  wire [4:0]   rd_addr,

    output reg  [4:0]   mem_addr_a, //to global memory
    output reg  [4:0]   mem_addr_b,

    input  wire [127:0] mem_data_a, //to vc
    input  wire [127:0] mem_data_b,

    output reg cache_load, //telling vc to load
    output reg  [127:0] cache_rs1,
    output reg  [127:0] cache_rs2,

    output reg  [31:0]  out_instr,  //to decoder
    output reg  [4:0]   out_rd_addr, //to decoder
    output reg out_valid
    output reg          cache_load, //write enable for vector cache
    output reg  [127:0] cache_rs1,
    output reg  [127:0] cache_rs2,

    output reg  [31:0]  out_instr, //to decoder
    output reg  [4:0]   out_rd_addr,
    output reg          out_valid
);

reg pending;

always @(posedge clk or posedge rst) begin

    if(rst) begin
        mem_addr_a <= 0;
        mem_addr_b <= 0;
        cache_rs1  <= 0;
        cache_rs2  <= 0;
        cache_load <= 0;
        out_instr  <= 0;
        out_rd_addr<= 0;
        out_valid  <= 0;
        pending    <= 0;
    end
    else begin

        cache_load <= 0;
        out_valid  <= 0;

        if(fetch_req) begin //if 1 meaning fetch from top
            mem_addr_a <= rs1_addr;
            mem_addr_b <= rs2_addr;
            out_instr  <= instr;
            out_rd_addr<= rd_addr;
            pending    <= 1;
        end
        else if(pending) begin //stall
            cache_rs1  <= mem_data_a;
            cache_rs2  <= mem_data_b;
            cache_load <= 1;
            out_valid  <= 1;
            pending    <= 0;
        end

    end

end

endmodule
