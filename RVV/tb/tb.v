`timescale 1ps/1ps
module tb;

    reg clk, rst, we;
    reg [31:0] instruction, vs1_in, vs2_in;
    wire [31:0] vd;

    design_1_wrapper dut(
        .clk_0(clk), 
        .rst_0(rst), 
        .we_0(we),
        .instruction_0(instruction),
        .vs1_in_0(vs1_in), 
        .vs2_in_0(vs2_in),
        .vd_0(vd)
    );

    always #5 clk = ~clk;

    initial begin
        clk=0; rst=1; we=0;
        instruction=0; vs1_in=0; vs2_in=0;
        @(posedge clk); #1; rst=0;

        we=1; vs1_in=32'd10; vs2_in=32'd5;
        @(posedge clk); #1; we=0;

        // vadd.vv 
        instruction = 32'b000000_1_00001_00010_000_00011_1010111;
        @(posedge clk); #1; @(posedge clk); #1;

        // vsub.vv 
        instruction = 32'b000010_1_00001_00010_000_00011_1010111;
        @(posedge clk); #1; @(posedge clk); #1;

        // vmul.vv
    instruction = 32'b100101_1_00001_00010_000_00011_1010111;
    @(posedge clk); #1; @(posedge clk); #1;

    // vmulh.vv 
    instruction = 32'b100111_1_00001_00010_000_00011_1010111;
    @(posedge clk); #1; @(posedge clk); #1;
    
        #10 $finish;
    end

    initial begin
        $monitor("instr=%b | vs1=%0d vs2=%0d | vd=%0d",
                  instruction, vs1_in, vs2_in, vd);
    end

endmodule