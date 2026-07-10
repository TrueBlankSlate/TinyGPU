module RegisterFile(
    input wire clk,
    input wire we,
    input rst,

    input wire [4:0] rs1_addr,
    input wire [4:0] rs2_addr,
    input wire [4:0] write_addr,

    input wire [31:0] data,

    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    // 32 registers, each 32 bits
    reg [31:0] registers [0:31];

    assign read_data1 = registers[rs1_addr];
    assign read_data2 = registers[rs2_addr];
    
    integer i;
    always @(posedge clk) begin

        if (rst) begin
            for(i = 0; i < 32; i=i+1) begin
                registers[i] = 32'b0;
            end
        end

        else if (we) begin
            registers[write_addr] <= data;
        end
    end
endmodule
