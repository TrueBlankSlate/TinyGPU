module decoder(
    input clk, rst

    input  [31:0] instruction,

    output [6:0] opcode,
    output reg [5:0] instr_id,   // func6
    output reg vm,
    output reg [4:0] vs1,
    output reg [4:0] vs2,
    output reg [4:0] vd
);

assign opcode = instruction[6:0];

wire [5:0] func6 = instruction[31:26];
wire [2:0] func3 = instruction[14:12];

always @(*) begin
    instr_id = 6'd0;
    vm = 1'b0;
    vs1 = 5'd0;
    vs2 = 5'd0;
    vd = 5'd0;

    if (opcode == 7'b1010111) begin
        case (func3)
            3'b000, // OPIVV
            3'b001, // OPFVV
            3'b010, //OPMVV
            3'b011, //OPIVI 
            3'b100 : begin //OPIVX
                instr_id = func6;
                vm = instruction[25];
                vs2 = instruction[24:20]; 
                vs1 = instruction[19:15];  //in OPIVI this is imm [4:0] //in OPIVX this is rs1
                vd = instruction[11:7];  //address in register file.
            end

            default: vd = 32'd0;

        endcase 
    end
end
endmodule
