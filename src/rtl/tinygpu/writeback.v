`timescale 1ns / 1ps
// Packs TinyGPU's 16 individual result registers into one 1024-bit line,
// ready to stream out over TinyGPU's own AXI4 write master (see
// tinygpu_fsm.v's WRITEBACK state) for the vse64.v instruction.
// Row-major
module writeback(
    input  [63:0] c0,  c1,  c2,  c3,
                  c4,  c5,  c6,  c7,
                  c8,  c9,  c10, c11,
                  c12, c13, c14, c15,

    output [1023:0] c_out
);

    assign c_out[ 0*64 +: 64] = c0;
    assign c_out[ 1*64 +: 64] = c1;
    assign c_out[ 2*64 +: 64] = c2;
    assign c_out[ 3*64 +: 64] = c3;
    assign c_out[ 4*64 +: 64] = c4;
    assign c_out[ 5*64 +: 64] = c5;
    assign c_out[ 6*64 +: 64] = c6;
    assign c_out[ 7*64 +: 64] = c7;
    assign c_out[ 8*64 +: 64] = c8;
    assign c_out[ 9*64 +: 64] = c9;
    assign c_out[10*64 +: 64] = c10;
    assign c_out[11*64 +: 64] = c11;
    assign c_out[12*64 +: 64] = c12;
    assign c_out[13*64 +: 64] = c13;
    assign c_out[14*64 +: 64] = c14;
    assign c_out[15*64 +: 64] = c15;

endmodule
