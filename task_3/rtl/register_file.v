module RegisterFile(
    input wire clk,
    input wire we,

    input wire [4:0] read_addr1,
    input wire [4:0] read_addr2,
    input wire [4:0] write_addr,

    input wire [31:0] write_data,

    output wire [31:0] read_data1,
    output wire [31:0] read_data2
    );

    reg [31:0] registers [0:31];

    assign read_data1 = registers[read_addr1];
    assign read_data2 = registers[read_addr2];

    always @(posedge clk) begin
        if (we)
            registers[write_addr] <= write_data;
    end

endmodule
