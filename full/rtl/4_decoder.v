module decoder(

    input  wire clk,
    input  wire rst,

    input  wire valid,
    input  wire [31:0]  instr, //32 bit instruction
    input  wire [4:0] rd_addr,

    input  wire [127:0] vec_rs1, //cache
    input  wire [127:0] vec_rs2,

    output reg [127:0]  lane_a_flat,
    output reg [127:0]  lane_b_flat,
    output reg [6:0]    alu_op,
    output reg [4:0]    out_rd_addr,
    output reg dispatch //
);

wire [6:0] func7  = instr[31:25];
wire [2:0] func3  = instr[14:12]; //do i use this for predictor
wire [6:0] opcode = instr[6:0];

function [6:0] decode;
input [6:0] f7;
input [2:0] f3;
begin
    case({f7,f3})
        {7'h00,3'b000}: decode = 7'b0000001; // ADD
        {7'h20,3'b000}: decode = 7'b0000010; // SUB
        {7'h00,3'b110}: decode = 7'b0000011; // OR
        {7'h00,3'b100}: decode = 7'b0000100; // XOR
        {7'h00,3'b111}: decode = 7'b0000101; // AND
        {7'h01,3'b000}: decode = 7'b0001111; // MUL
        default:        decode = 7'b0000000;
    endcase
end
endfunction

always @(posedge clk or posedge rst) begin

    if(rst) begin
        lane_a_flat <= 0;
        lane_b_flat <= 0;
        alu_op <= 0;
        out_rd_addr <= 0;
        dispatch <= 0;
    end
    else begin

        dispatch <= 0;

        if(valid && opcode==7'b0110011) begin
            lane_a_flat <= vec_rs1;
            lane_b_flat <= vec_rs2;
            alu_op <= decode(func7,func3);
            out_rd_addr <= rd_addr;
            dispatch <= 1;
        end
    end
end
endmodule
