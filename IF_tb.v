`timescale 1ns/1ps

module fetcher_tb;

reg clk;
reg reset;
reg fetch_enable;
reg stall;
reg jump;
reg [7:0] jump_addr;
reg [31:0] instr_data;

wire [7:0] instr_addr;
wire [31:0] instruction;
wire [7:0] pc;

// Instantiate the DUT
fetcher uut (
    .clk(clk),
    .reset(reset),
    .fetch_enable(fetch_enable),
    .stall(stall),
    .jump(jump),
    .jump_addr(jump_addr),
    .instr_addr(instr_addr),
    .instr_data(instr_data),
    .instruction(instruction),
    .pc(pc)
);

// Clock generation (10ns period)
always #5 clk = ~clk;

// Generate waveform
initial begin
    $dumpfile("fetcher.vcd");
    $dumpvars(0, fetcher_tb);
end

initial begin

    // Initialize inputs
    clk = 0;
    reset = 1;
    fetch_enable = 0;
    stall = 0;
    jump = 0;
    jump_addr = 0;
    instr_data = 32'h00000000;

    // Apply reset
    #10;
    reset = 0;

    // -------------------------------
    // Test 1 : Normal Fetch
    // -------------------------------
    fetch_enable = 1;

    instr_data = 32'h11111111;
    #10;
    $display("FETCH1 : PC=%d Addr=%d Instr=%h",
              pc, instr_addr, instruction);

    instr_data = 32'h22222222;
    #10;
    $display("FETCH2 : PC=%d Addr=%d Instr=%h",
              pc, instr_addr, instruction);

    instr_data = 32'h33333333;
    #10;
    $display("FETCH3 : PC=%d Addr=%d Instr=%h",
              pc, instr_addr, instruction);

    // -------------------------------
    // Test 2 : Stall
    // -------------------------------
    stall = 1;
    instr_data = 32'hAAAAAAAA;
    #10;
    $display("STALL  : PC=%d Addr=%d Instr=%h",
              pc, instr_addr, instruction);

    stall = 0;

    // -------------------------------
    // Test 3 : Jump
    // -------------------------------
    jump = 1;
    jump_addr = 8'd20;
    instr_data = 32'hBBBBBBBB;
    #10;
    $display("JUMP   : PC=%d Addr=%d Instr=%h",
              pc, instr_addr, instruction);

    jump = 0;

    // -------------------------------
    // Test 4 : Fetch after Jump
    // -------------------------------
    instr_data = 32'hCCCCCCCC;
    #10;
    $display("AFTERJ : PC=%d Addr=%d Instr=%h",
              pc, instr_addr, instruction);

    // -------------------------------
    // Test 5 : Fetch Disable
    // -------------------------------
    fetch_enable = 0;
    instr_data = 32'hDDDDDDDD;
    #10;
    $display("DISABLE: PC=%d Addr=%d Instr=%h",
              pc, instr_addr, instruction);

    $finish;

end

endmodule
