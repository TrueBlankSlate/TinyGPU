module Top(

    input wire clk,
    input wire we,
    input wire rst,

    input wire [4:0] rs1, //address of rs1 in top
    input wire [4:0] rs2, //address of rs2 in top
    input wire [4:0] rd,

    input wire [31:0] write_data,

    input wire [3:0] opcode,

    output wire [31:0] alu_out, //x equivalent in top
    output wire [31:0] a, //a and be in top
    output wire [31:0] b

);

RegisterFile RF(

    .clk(clk),
    .we(we),
    .rst(rst),
    .rs1_addr(rs1),
    .rs2_addr(rs2),

    .write_addr(rd),
    .data(write_data),

    .read_data1(a),
    .read_data2(b)

);

ALU alu(

    .a(a),
    .b(b),
    .opcode(opcode),
    .x(alu_out)

);

endmodule
