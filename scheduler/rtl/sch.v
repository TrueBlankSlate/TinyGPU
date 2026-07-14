module scheduler(
    input clk,
    input rst,
    input [5:0] instr [0:4]  // one instruction per thread
);
    reg [5:0] reg_true  [0:4];
    reg [5:0] reg_false [0:4];
    reg [5:0] delay_buf [0:4];  // holds delayed threads for next cycle
    reg [4:0] delayed; // which threads are currently delayed

    reg cond_for_all;
    integer i, pop;

    always @(*) begin
        pop = 0;
        for (i = 0; i < 5; i = i + 1)
            pop = pop + instr[i][0];   // count true branches (majority counter)
        cond_for_all = (pop >= 3);
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin //reset logic
            delayed <= 5'b0;
            for (i = 0; i < 5; i = i + 1) begin
                reg_true[i]  <= 6'b0;
                reg_false[i] <= 6'b0;
                delay_buf[i] <= 6'b0;
            end
        end
        else begin
            for (i = 0; i < 5; i = i + 1) begin
                if (instr[i][0] == cond_for_all) begin //executes the majority wala thread)
                    if (cond_for_all) reg_true[i]  <= instr[i];
                    else reg_false[i] <= instr[i];
                    delayed[i]   <= 0;
                end
                else begin //executing the minorty branches (saving on cycles)
                    delay_buf[i] <= instr[i];
                    delayed[i]   <= 1; //num of threads being delayde
                end
            end
        end
    end
endmodule
