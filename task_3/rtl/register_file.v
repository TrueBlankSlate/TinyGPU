module register_file(
    input wire clk,
    input wire we,
    input wire [4:0] rs1_addr,
    input wire [4:0] rs2_addr,
    input wire [4:0] write_addr,

    input wire [31:0] write_data,

    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    reg [31:0] registers [31:0];

    assign read_data1 = registers[rs1_addr];
    assign read_data2 = registers[rs2_addr];

    always @(posedge clk) begin
        if (we)
            registers[write_addr] <= write_data;
    end

endmodule
