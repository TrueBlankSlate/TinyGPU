module vector_cache(

    input  wire clk,
    input  wire rst,

    input  wire load, //from fetcher

    input  wire [127:0] in_rs1, //from global mem r_data_a, r_data_b
    input  wire [127:0] in_rs2,

    output reg [127:0] rs1,
    output reg [127:0] rs2,

    output reg valid

);

always @(posedge clk or posedge rst) begin

    if(rst) begin
        rs1   <= 128'd0;
        rs2   <= 128'd0;
        valid <= 1'b0;
    end
    else begin

        valid <= 1'b0;

        if(load) begin
            rs1   <= in_rs1;
            rs2   <= in_rs2;
            valid <= 1'b1;
        end

    end

end
endmodule
