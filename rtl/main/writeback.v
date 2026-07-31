module writeback(
    input [4:0] vd_addr,
    input [31:0] c0, c1, c2, c3,
    output [127:0] vd_out,
    output [4:0] vd_addr_out
);
    assign vd_out[31:0]   = c0;
    assign vd_out[63:32]  = c1;
    assign vd_out[95:64]  = c2;
    assign vd_out[127:96] = c3;
    assign vd_addr_out    = vd_addr;

endmodule