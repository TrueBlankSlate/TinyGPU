module register_file(

    input wire clk,
    input wire rst,
    input wire we, //input it takes is called dispatch from core.v

    input wire [31:0] data_a,
    input wire [31:0] data_b,

    output reg [31:0] reg_a,
    output reg [31:0] reg_b

);

always @(posedge clk or posedge rst) begin

    if(rst) begin
        reg_a <= 0;
        reg_b <= 0;
    end
    else if(we) begin
        reg_a <= data_a; //double read for less cycle count
        reg_b <= data_b;
    end

end

endmodule
