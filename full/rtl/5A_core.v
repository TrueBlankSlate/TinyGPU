module core(

    input wire clk,
    input wire rst,

    input wire dispatch,

    input wire [31:0] data_a,
    input wire [31:0] data_b,

    input wire [6:0] alu_op,

    output wire [31:0] result,
    output reg idle

);

    wire [31:0] reg_a;
    wire [31:0] reg_b;

    register_file rf(

    .clk(clk),
    .rst(rst),
    .we(dispatch),

    .data_a(data_a),
    .data_b(data_b),

    .reg_a(reg_a),
    .reg_b(reg_b)

    );

    alu alu_inst(

    .a(reg_a),
    .b(reg_b),
    .opcode(alu_op),
    .x(result)

    );

    always @(posedge clk or posedge rst) begin

    if(rst)
        idle <= 1'b1;
    else if(dispatch)
        idle <= 1'b0;
    else
        idle <= 1'b1;
    end
endmodule
