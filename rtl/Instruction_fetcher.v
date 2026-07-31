module(
    input wire clk
    input wire rst

    output reg [7:0]pc 
    input reg [31:0]instruction_data 
    input reg [31:0]instructions

    input wire jump
    input reg [31:0] pc_after_jump
)

always @(posdge clk) begin

  
    
  
  if(rst) begin
pc <= 0;
instruction <= 0;
  end

  else begin

if (jump) begin
  pc<=pc_after_jump;
  instruction<=instruction_data;
  end

  else begin
    pc<= pc+1;
    instruction<=instruction_data;
  end

  end



 
    
end

endmodule