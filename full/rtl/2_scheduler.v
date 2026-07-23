module scheduler(

    input  wire clk,
    input  wire rst,

    input  wire dispatch_req,

    input  wire [31:0] instr,
    input  wire [4:0]  vec_rs1_addr, // from cache
    input  wire [4:0]  vec_rs2_addr, //from cache
    input  wire [4:0]  vec_rd_addr, //writing from cache? 

    input  wire [3:0]  cores_idle, //for scheduling 0 = not idle 1 = idle

    output reg fetch_req, //to fetcher 

    output reg [31:0]  out_instr, // to fetcher
    output reg [4:0]   out_rs1_addr, //
    output reg [4:0]   out_rs2_addr, // 
    output reg [4:0]   out_rd_addr //

);

always @(posedge clk or posedge rst) begin

    if(rst) begin
        fetch_req    <= 1'b0;
        out_instr    <= 32'd0;
        out_rs1_addr <= 5'd0;
        out_rs2_addr <= 5'd0;
        out_rd_addr  <= 5'd0;
    end

    else begin

        fetch_req <= 1'b0;

        if(dispatch_req && (&cores_idle)) begin

            fetch_req    <= 1'b1;
            out_instr    <= instr;
            out_rs1_addr <= vec_rs1_addr;
            out_rs2_addr <= vec_rs2_addr;
            out_rd_addr  <= vec_rd_addr;

        end
    end
end
endmodule
