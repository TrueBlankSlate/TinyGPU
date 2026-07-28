module tb;
    reg clk, rst, we_0, we_1;
    reg [31:0] instruction;
    reg [4:0]  w_addr;
    reg [127:0] w_data;

    // visible output wires
    wire [31:0] vd0,vd1,vd2,vd3;
    wire [127:0] wb_out;

    top dut(.clk(clk),.rst(rst),.we_0(we_0),.we_1(we_1),
        .instruction(instruction),.w_addr(w_addr),.w_data(w_data));

    // connect to internal wires for waveform visibility
    assign vd0   = dut.vd0;
    assign vd1   = dut.vd1;
    assign vd2   = dut.vd2;
    assign vd3   = dut.vd3;
    assign wb_out = dut.wb_out;

    always #5 clk=~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);
        clk=0; rst=0; we_0=0; we_1=0;
        instruction=0; w_addr=0; w_data=0;
        #2; rst=1;
        @(posedge clk); #1;

        w_addr=5'd1; w_data={32'd4,32'd3,32'd2,32'd1};
        we_1=1; @(posedge clk); #1; we_1=0;

        w_addr=5'd2; w_data={32'd40,32'd30,32'd20,32'd10};
        we_1=1; @(posedge clk); #1; we_1=0;

        // vadd.vv expect [11,22,33,44]
        instruction = 32'b000000_1_00010_00001_000_00011_1010111;
        @(posedge clk); #1;
        we_0=1; @(posedge clk); #1; we_0=0;
        @(posedge clk); #1;
        $display("vadd: [%0d,%0d,%0d,%0d] wb=%h", vd0,vd1,vd2,vd3,wb_out);

        // vsub.vv expect [9,18,27,36]
        instruction = 32'b000010_1_00010_00001_000_00011_1010111;
        we_0=1; @(posedge clk); #1; we_0=0;
        @(posedge clk); #1;
        $display("vsub: [%0d,%0d,%0d,%0d] wb=%h", vd0,vd1,vd2,vd3,wb_out);

        // vmul.vv expect [0,0,0,0]
        instruction = 32'b100101_1_00010_00001_000_00011_1010111;
        we_0=1; @(posedge clk); #1; we_0=0;
        @(posedge clk); #1;
        $display("vmulh: [%0d,%0d,%0d,%0d] wb=%h", vd0,vd1,vd2,vd3,wb_out);

        #20 $finish;
    end

    initial begin
        $monitor("t=%0t clk=%b | instr=%h | vd=[%0d,%0d,%0d,%0d]",
            $time, clk, instruction, vd0,vd1,vd2,vd3);
    end
endmodule