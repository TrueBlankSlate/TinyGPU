module l3_cache(
    input clk,
    input rst,
    input we,

    input [4:0] vs1,
    input [4:0] vs2,

    input [511:0] w_data,

    input [1:0] pass,
    input func3,
    input [5:0] instr_id,

    output reg [127:0] core0_a,
    output reg [127:0] core0_b,
    output reg [127:0] core1_a,
    output reg [127:0] core1_b,
    output reg [127:0] core2_a,
    output reg [127:0] core2_b,
    output reg [127:0] core3_a,
    output reg [127:0] core3_b
);

reg [127:0] mat_mem [0:31];
reg write_sel;

integer i;

always @(posedge clk) begin
    if (rst) begin
        write_sel <= 1'b0;

        for (i = 0; i < 32; i = i + 1)
            mat_mem[i] <= 128'd0;
    end
    else if (we) begin
        if (!write_sel) begin
            mat_mem[vs1 + 0] <= w_data[127:0];
            mat_mem[vs1 + 1] <= w_data[255:128];
            mat_mem[vs1 + 2] <= w_data[383:256];
            mat_mem[vs1 + 3] <= w_data[511:384];
        end
        else begin
            mat_mem[vs2 + 0] <= w_data[127:0];
            mat_mem[vs2 + 1] <= w_data[255:128];
            mat_mem[vs2 + 2] <= w_data[383:256];
            mat_mem[vs2 + 3] <= w_data[511:384];
        end

        write_sel <= ~write_sel;
    end
end

always @(*) begin
    core0_a = mat_mem[vs1 + 0];
    core0_b = mat_mem[vs2 + 0];

    core1_a = mat_mem[vs1 + 1];
    core1_b = mat_mem[vs2 + 1];

    core2_a = mat_mem[vs1 + 2];
    core2_b = mat_mem[vs2 + 2];

    core3_a = mat_mem[vs1 + 3];
    core3_b = mat_mem[vs2 + 3];
end

endmodule