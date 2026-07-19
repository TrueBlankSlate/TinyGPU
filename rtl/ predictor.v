module scheduler(
    input clk,
    input rst,
    input [29:0] instr_flat  // 6 bits x 5 threads
);
    wire [5:0] instr [0:4];
    genvar g;
    generate
        for (g = 0; g < 5; g = g + 1)
            assign instr[g] = instr_flat[6*g +: 6];  //de flatten
    endgenerate

    reg [1:0] bht [0:4];  //branch history table. 00 01 10 11 (not all taken ---> always taken)
    reg [5:0] reg_predicted    [0:4];
    reg [5:0] reg_mispredicted [0:4];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 5; i = i + 1) begin
                bht[i]             <= 2'b01;
                reg_predicted[i]   <= 6'b0;
                reg_mispredicted[i] <= 6'b0;
            end
        end
        else begin
            for (i = 0; i < 5; i = i + 1) begin
                if (instr[i][0]) begin
                    if (bht[i] != 2'b11) bht[i] <= bht[i] + 1; //if anything other than always taken update to next branch being taken as well
                end
                else begin
                    if (bht[i] != 2'b00) bht[i] <= bht[i] - 1; //if anything other than not taken always then reduce from 11 -> 10 -> 00 as a prediction for next branch also being not taken
                end

                if (bht[i][1] == instr[i][0])
                    reg_predicted[i]    <= instr[i];
                else
                    reg_mispredicted[i] <= instr[i];
            end
        end
    end
endmodule
