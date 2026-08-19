module ascii_translator(
    input clk,
    input [7:0]recieved,
    output reg translated,
    input valid
);
always@(  posedge clk) begin

if(valid) begin
    if(recieved==8'h30) begin
        translated<= 0;
    end
    else begin
        translated<= 1;
    end

end


end
endmodule