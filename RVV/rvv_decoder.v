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

    // Default outputs
    instr_id = 6'd0;
    vm       = 1'b0;
    vs1      = 5'd0;
    vs2      = 5'd0;
    vd       = 5'd0;

    if (opcode == 7'b1010111) begin //later add for different opcodes too?

        case (func3) 
            // OPIVV
            3'b000: begin
                instr_id = func6;
                vm = instruction[25];
                vs2 = instruction[24:20];
                vs1 = instruction[19:15];
                vd = instruction[11:7];
            end

            // OPFVV
            3'b001: begin
                instr_id = func6;
                vm = instruction[25];
                vs2 = instruction[24:20];
                vs1 = instruction[19:15];
                vd = instruction[11:7];
            end

            // OPIVI
            3'b011: begin
                instr_id = func6;
                vm = instruction[25];
                vs2 = instruction[24:20];
                vs1 = instruction[19:15]; // immediate[4:0]
                vd = instruction[11:7];
            end

            default: begin
                instr_id = 6'd0;
                vm = 1'b0;
                vs1 = 5'd0;
                vs2 = 5'd0;
                vd = 5'd0;
            end
        endcase
    end
end
endmodule
