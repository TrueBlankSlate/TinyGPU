module program_counter(
     input reg [7:0] pc,
    output reg [31:0] instruction,

    input wire clk,
    input wire rst,

    input reg [0:31] instr_holder [256:0]


)

  integer i;
always@ (posdge clk) begin

     assign instructions[31:0]<=32'b0;
       assign pc[7:0]<=8'b0;

    if (rst) begin
        instructions<=32'b0;
        pc<=8'b0;

        for (i = 0; i < 32; i = i+1)
                instr_holder[i] <= 32'b0;
        end

        instruction <=instr_holder[pc]

        
    end

endmodule