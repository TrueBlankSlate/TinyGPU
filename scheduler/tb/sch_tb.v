module scheduler_tb;
    reg clk, rst;
    reg [5:0] instr [0:4];

    scheduler dut (
        .clk(clk),
        .rst(rst),
        .instr(instr)
    );
    always #5 clk = ~clk;

    initial begin
        // waveform dump
        $dumpfile("scheduler.vcd");
        $dumpvars(0, scheduler_tb);

        clk = 0; rst = 1;
        #10 rst = 0;

        // t1 - majority is true state
        instr[0] = 6'b000001;
        instr[1] = 6'b000001;
        instr[2] = 6'b000001;
        instr[3] = 6'b000000;
        instr[4] = 6'b000000;
        #10;
        // t2 - majority take false path
        instr[0] = 6'b000000;
        instr[1] = 6'b000000;
        instr[2] = 6'b000000;
        instr[3] = 6'b000000;
        instr[4] = 6'b000001;
        #10;

        // t3 - majority false 3/5
        instr[0] = 6'b000001;
        instr[1] = 6'b000001;
        instr[2] = 6'b000000;
        instr[3] = 6'b000000;
        instr[4] = 6'b000000;
        #10;

        // t4 - all true (simplest)
        instr[0] = 6'b000001;
        instr[1] = 6'b000001;
        instr[2] = 6'b000001;
        instr[3] = 6'b000001;
        instr[4] = 6'b000001;
        #10;

        $finish;
    end
endmodule