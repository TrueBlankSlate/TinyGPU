module decoder(
    input wire [31:0] instr,
    output wire [4:0] rs1, 
    output wire [4:0] rs2,
    output wire [4:0] rd,
    output wire [6:0] opcode,
    
    reg [3:0] instr_id //in synapse or in riscv this is 5 bit
);
    wire [2:0] func3;
    wire [6:0] func7;

    //i have given space for different type of riscv operation by specifying opcode
    //however in this file i am only going to take register type.decoder

    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];

    assign func7 = instr[31:25];
    assign func3 = instr[14:12];

    always @(*) begin
        case (opcode) 
            7'b0110011 begin:
            case ({
                    func7, func3
                })
                    {7'h00, 3'h0} : instr_id = 4'b0000; //div a by b
                    {7'h20, 3'h0} : instr_id = 4'b0001; //add
                    {7'h00, 3'h4} : instr_id = 4'b0010; //sub
                    {7'h00, 3'h6} : instr_id = 4'b0011; //or
                    {7'h00, 3'h7} : instr_id = 4'b0100; //xor
                    {7'h00, 3'h1} : instr_id = 4'b0101; //and
                    {7'h00, 3'h5} : instr_id = 4'b0110; //nand
                    {7'h20, 3'h5} : instr_id = 4'b0111; //nor
                    {7'h00, 3'h2} : instr_id = 4'b1000; //right shift
                    {7'h00, 3'h3} : instr_id = 4'b1001; //left shift
                    default:        instr_id = 4'b1111; //multiply
                endcase
            endcase
        end
endmodule
