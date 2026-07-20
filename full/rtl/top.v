module top(

    input wire clk,
    input wire rst,
    input wire we,

    input wire [31:0] instr,

    output wire [31:0] out0,
    output wire [31:0] out1,
    output wire [31:0] out2,
    output wire [31:0] out3

);

    //==============================
    // Decoder Outputs
    //==============================

    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [6:0] opcode;

    decoder DEC(
        .instr(instr),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .opcode(opcode)
    );

    //==============================
    // Register File Outputs
    //==============================

    wire [31:0] a0,b0;
    wire [31:0] a1,b1;
    wire [31:0] a2,b2;
    wire [31:0] a3,b3;

    //==============================
    // ALU Outputs
    //==============================

    wire [31:0] result0;
    wire [31:0] result1;
    wire [31:0] result2;
    wire [31:0] result3;

    //==============================
    // Core 0
    //==============================

    RegisterFile RF0(
        .clk(clk),
        .we(we),
        .rst(rst),

        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .write_addr(rd),

        .data(result0),

        .read_data1(a0),
        .read_data2(b0)
    );

    ALU ALU0(
        .a(a0),
        .b(b0),
        .opcode(opcode),
        .x(result0)
    );

    //==============================
    // Core 1
    //==============================

    RegisterFile RF1(
        .clk(clk),
        .we(we),
        .rst(rst),

        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .write_addr(rd),

        .data(result1),

        .read_data1(a1),
        .read_data2(b1)
    );

    ALU ALU1(
        .a(a1),
        .b(b1),
        .opcode(opcode),
        .x(result1)
    );

    //==============================
    // Core 2
    //==============================

    RegisterFile RF2(
        .clk(clk),
        .we(we),
        .rst(rst),

        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .write_addr(rd),

        .data(result2),

        .read_data1(a2),
        .read_data2(b2)
    );

    ALU ALU2(
        .a(a2),
        .b(b2),
        .opcode(opcode),
        .x(result2)
    );

    //==============================
    // Core 3
    //==============================

    RegisterFile RF3(
        .clk(clk),
        .we(we),
        .rst(rst),

        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .write_addr(rd),

        .data(result3),

        .read_data1(a3),
        .read_data2(b3)
    );

    ALU ALU3(
        .a(a3),
        .b(b3),
        .opcode(opcode),
        .x(result3)
    );

    assign out0 = result0;
    assign out1 = result1;
    assign out2 = result2;
    assign out3 = result3;

endmodule
