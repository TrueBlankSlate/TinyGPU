module decoder(
    input clk, rst,

    input  [31:0] instruction,

    output [6:0] opcode,
    output reg [5:0] instr_id,   // func6
    output reg vm,
    output reg [4:0] vs1,
    output reg [4:0] vs2,
    output reg [4:0] vd,
    output reg [2:0] func3_out,
    output reg matmul_out
);

assign opcode = instruction[6:0];

wire [5:0] func6 = instruction[31:26];


always @(*) begin
    instr_id = 6'd0;
    vm = 1'b0;
    vs1 = 5'd0;
    vs2 = 5'd0;
    vd = 5'd0;
    func3_out = instruction[14:12];
    matmul_out = 1'b0;

    if (opcode == 7'b1010111) begin
        case (func3_out)
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
                if(func6 == 6'b101101 && func3_out == 3'b010) begin //this IP hasnt been updated.
                    matmul_out = 1'b1;
                end
            end

            default: vd = 5'd0;

        endcase 
    end
end
endmodule
