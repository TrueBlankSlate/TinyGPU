module decoder(
    input wire [31:0] instr,
    output wire [4:0] rs1,      // sent to reg file
    output wire [4:0] rs2,      // sent to reg file
    output wire [4:0] rd,       // sent to reg file
    output wire [6:0] opcode,   // sent to ALU
    output reg  [3:0] instr_id  // fixed missing 'output' keyword
);
    wire [2:0] func3;
    wire [6:0] func7;

    // Bit extractions from RISC-V instruction format
    assign opcode = instr[6:0];   // Added missing assignment
    assign rd     = instr[11:7];  // Added missing assignment
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign func3  = instr[14:12];
    assign func7  = instr[31:25];

    always @(*) begin
        instr_id = 4'b1111;

        case (opcode) //for now only 1 type opcode (R type)
            7'b0110011: begin 
                case ({func7, func3})
                    {7'h00, 3'h0} : instr_id = 4'b0000; // div a by b
                    {7'h20, 3'h0} : instr_id = 4'b0001; // add
                    {7'h00, 3'h4} : instr_id = 4'b0010; // sub
                    {7'h00, 3'h6} : instr_id = 4'b0011; // or
                    {7'h00, 3'h7} : instr_id = 4'b0100; // xor
                    {7'h00, 3'h1} : instr_id = 4'b0101; // and
                    {7'h00, 3'h5} : instr_id = 4'b0110; // nand
                    {7'h20, 3'h5} : instr_id = 4'b0111; // nor
                    {7'h00, 3'h2} : instr_id = 4'b1000; // right shift
                    {7'h00, 3'h3} : instr_id = 4'b1001; // left shift
                    default:        instr_id = 4'b1111; // fallback
                endcase
            end
            default: instr_id = 4'b1111; 
        endcase
    end
endmodule
