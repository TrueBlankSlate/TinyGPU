`timescale 1ns / 1ps

module test(

    output reg [255:0] mat_a,
    output reg [255:0] mat_b,
    output wire        we,
    output reg [5:0]   instr_id,
    output reg [2:0]   func3

);

    // Test values
    wire [63:0] mat_a1 = 64'd1;
    wire [63:0] mat_a2 = 64'd1;
    wire [63:0] mat_a3 = 64'd1;
    wire [63:0] mat_a4 = 64'd1;

    wire [63:0] mat_b1 = 64'd1;
    wire [63:0] mat_b2 = 64'd2;
    wire [63:0] mat_b3 = 64'd2;
    wire [63:0] mat_b4 = 64'd2;

    assign we = 1'b0;

    always @(*) begin

        mat_a = {mat_a1, mat_a2, mat_a3, mat_a4};
        mat_b = {mat_b1, mat_b2, mat_b3, mat_b4};

        instr_id = 6'h00;
        func3    = 3'd0;

    end

endmodule