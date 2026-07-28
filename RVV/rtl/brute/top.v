`timescale 1ps/1ps

module decoder(
    input clk, rst,
    input [31:0] instruction,
    output reg [5:0] instr_id,
    output reg [2:0] func3_out,
    output reg [6:0] opcode,
    output reg vm,
    output reg [4:0] vs1, vs2, vd
);
    always @(*) begin
        opcode   = instruction[6:0];
        vd       = instruction[11:7];
        func3_out= instruction[14:12];
        vs1      = instruction[19:15];
        vs2      = instruction[24:20];
        vm       = instruction[25];
        instr_id = instruction[31:26];
    end
endmodule

module RegisterFile(
    input clk, rst, we,
    input [31:0] vs1_in, vs2_in,
    output reg [31:0] vs1_out, vs2_out
);
    always @(posedge clk) begin
        if (!rst) begin
            vs1_out <= 0; vs2_out <= 0;
        end else if (we) begin
            vs1_out <= vs1_in;
            vs2_out <= vs2_in;
        end
    end
endmodule

module ALU(
    input [5:0] instr_id,
    input [2:0] func3,
    input [31:0] vs1, vs2,
    output reg [31:0] vd
);
    wire signed [31:0] s_vs1 = vs1;
    wire signed [31:0] s_vs2 = vs2;
    wire signed [63:0] signed_prod = s_vs1 * s_vs2;
    wire [63:0] unsigned_prod = vs1 * vs2;

    always @(*) begin
        vd = 32'd0;
        case(func3)
        3'b000: begin
            case(instr_id)
                6'h00: vd = s_vs1 + s_vs2;
                6'h02: vd = s_vs2 - s_vs1;
                6'h25: vd = signed_prod[31:0];
                6'h27: vd = signed_prod[63:32];
                6'h29: vd = unsigned_prod[63:32];
                6'h21: vd = (s_vs1 != 0) ? (s_vs2 / s_vs1) : 32'd0;
                6'h23: vd = s_vs2 % s_vs1;
                6'h09: vd = vs2 & vs1;
                6'h0A: vd = vs2 | vs1;
                6'h0B: vd = vs2 ^ vs1;
                6'h04: vd = vs2 << vs1[4:0];
                6'h05: vd = vs2 >> vs1[4:0];
                6'h07: vd = s_vs2 >>> vs1[4:0];
                default: vd = 32'd0;
            endcase
        end
        3'b011: begin
            case(instr_id)
                6'h00: vd = s_vs2 + s_vs1;
                6'h09: vd = vs2 & vs1;
                6'h0A: vd = vs2 | vs1;
                6'h0B: vd = vs2 ^ vs1;
                6'h04: vd = vs2 << vs1[4:0];
                6'h05: vd = vs2 >> vs1[4:0];
                6'h07: vd = s_vs2 >>> vs1[4:0];
                default: vd = 32'd0;
            endcase
        end
        default: vd = 32'd0;
        endcase
    end
endmodule

module cache(
    input clk, rst, we,
    input [4:0] vs1, vs2,
    input [4:0] w_addr,
    input [127:0] w_data,
    output [31:0] a0, a1, a2, a3,
    output [31:0] b0, b1, b2, b3
);
    reg [127:0] vector_cache [0:31];
    integer i;
    always @(posedge clk) begin
        if (!rst) begin
            for (i = 0; i < 32; i = i+1)
                vector_cache[i] <= 128'b0;
        end else if (we) begin
            vector_cache[w_addr] <= w_data;
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

module writeback(
    input [4:0] vd_addr,
    input [31:0] c0, c1, c2, c3,
    output [127:0] vd_out,
    output [4:0] vd_addr_out
);
    assign vd_out[31:0]   = c0;
    assign vd_out[63:32]  = c1;
    assign vd_out[95:64]  = c2;
    assign vd_out[127:96] = c3;
    assign vd_addr_out    = vd_addr;
endmodule

//top
module top(
    input clk, rst,
    input we_0, we_1,
    input [31:0] instruction,
    input [4:0]  w_addr,
    input [127:0] w_data
);
    wire [5:0] instr_id;
    wire [2:0] func3;
    wire [6:0] opcode;
    wire vm;
    wire [4:0] vs1_addr, vs2_addr, vd_addr;
    wire [31:0] a0,a1,a2,a3,b0,b1,b2,b3;
    wire [31:0] rf0_vs1,rf0_vs2,rf1_vs1,rf1_vs2;
    wire [31:0] rf2_vs1,rf2_vs2,rf3_vs1,rf3_vs2;
    wire [31:0] vd0,vd1,vd2,vd3;
    wire [127:0] wb_out;
    wire [4:0]   wb_addr;

    decoder dec(.clk(clk),.rst(rst),.instruction(instruction),
        .instr_id(instr_id),.func3_out(func3),.opcode(opcode),
        .vm(vm),.vs1(vs1_addr),.vs2(vs2_addr),.vd(vd_addr));

    cache c0(.clk(clk),.rst(rst),.we(we_1),
        .vs1(vs1_addr),.vs2(vs2_addr),
        .w_addr(w_addr),.w_data(w_data),
        .a0(a0),.a1(a1),.a2(a2),.a3(a3),
        .b0(b0),.b1(b1),.b2(b2),.b3(b3));

    RegisterFile rf0(.clk(clk),.rst(rst),.we(we_0),.vs1_in(a0),.vs2_in(b0),.vs1_out(rf0_vs1),.vs2_out(rf0_vs2));
    RegisterFile rf1(.clk(clk),.rst(rst),.we(we_0),.vs1_in(a1),.vs2_in(b1),.vs1_out(rf1_vs1),.vs2_out(rf1_vs2));
    RegisterFile rf2(.clk(clk),.rst(rst),.we(we_0),.vs1_in(a2),.vs2_in(b2),.vs1_out(rf2_vs1),.vs2_out(rf2_vs2));
    RegisterFile rf3(.clk(clk),.rst(rst),.we(we_0),.vs1_in(a3),.vs2_in(b3),.vs1_out(rf3_vs1),.vs2_out(rf3_vs2));

    ALU alu0(.instr_id(instr_id),.func3(func3),.vs1(rf0_vs1),.vs2(rf0_vs2),.vd(vd0));
    ALU alu1(.instr_id(instr_id),.func3(func3),.vs1(rf1_vs1),.vs2(rf1_vs2),.vd(vd1));
    ALU alu2(.instr_id(instr_id),.func3(func3),.vs1(rf2_vs1),.vs2(rf2_vs2),.vd(vd2));
    ALU alu3(.instr_id(instr_id),.func3(func3),.vs1(rf3_vs1),.vs2(rf3_vs2),.vd(vd3));

    writeback wb(.vd_addr(vd_addr),.c0(vd0),.c1(vd1),.c2(vd2),.c3(vd3),
        .vd_out(wb_out),.vd_addr_out(wb_addr));
endmodule