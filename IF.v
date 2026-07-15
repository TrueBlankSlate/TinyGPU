`default_nettype none
`timescale 1ns/1ps

module fetcher #(

    parameter PROGRAM_MEM_ADDR_BITS = 8,
    parameter PROGRAM_MEM_DATA_BITS = 32

)(

    input wire clk,
    input wire reset,

    // execution control
    input wire fetch_enable,
    input wire stall,

    // jump/branch
    input wire jump,
    input wire [PROGRAM_MEM_ADDR_BITS-1:0] jump_addr,

    // instruction memory interface
    output reg [PROGRAM_MEM_ADDR_BITS-1:0] instr_addr,
    input wire [PROGRAM_MEM_DATA_BITS-1:0] instr_data,

    // decoder interface
    output reg [PROGRAM_MEM_DATA_BITS-1:0] instruction,
    output reg [PROGRAM_MEM_ADDR_BITS-1:0] pc

);

always @(posedge clk) begin

    if(reset) begin

        pc <= 0;
        instr_addr <= 0;
        instruction <= 0;

    end

    else if(fetch_enable) begin

        if(!stall) begin

            // fetch current instruction
            instruction <= instr_data;
            instr_addr <= pc;

            // update PC
            if(jump)
                pc <= jump_addr;
            else
                pc <= pc + 1;

        end

    end

end

endmodule