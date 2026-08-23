// Scratch diagnostic, not part of the real design. Isolates whether a
// parameterized `data_t` array type (as used in tc_sram.sv) defeats BRAM
// inference versus a literal bit-range declaration, for the exact same
// 256x64 single-port byte-write-enable shape that failed in tc_sram.sv
// (confirmed there via get_cells: sram_reg[*] synthesized as FDRE flops).
`timescale 1ns/1ps

module bram_test_typedef #(
  parameter int unsigned NumWords  = 256,
  parameter int unsigned DataWidth = 64,
  parameter int unsigned ByteWidth = 8,
  parameter int unsigned BeWidth   = (DataWidth + ByteWidth - 1) / ByteWidth,
  parameter type         data_t    = logic [DataWidth-1:0]
)(
  input  logic                          clk,
  input  logic                          req,
  input  logic                          we,
  input  logic [$clog2(NumWords)-1:0]   addr,
  input  data_t                         wdata,
  input  logic [BeWidth-1:0]            be,
  output data_t                         rdata
);
  (* ram_style = "block" *) data_t sram [NumWords-1:0];

  if (1) begin : gen_outer
    if (1) begin : gen_inner
      always_ff @(posedge clk) begin
        if (req && we) begin
          for (int unsigned j = 0; j < BeWidth; j++)
            if (be[j]) sram[addr][j*ByteWidth +: ByteWidth] <= wdata[j*ByteWidth +: ByteWidth];
        end else if (req) begin
          rdata <= sram[addr];
        end
      end
    end
  end
endmodule

module bram_test_literal #(
  parameter int unsigned NumWords  = 256,
  parameter int unsigned DataWidth = 64,
  parameter int unsigned ByteWidth = 8,
  parameter int unsigned BeWidth   = (DataWidth + ByteWidth - 1) / ByteWidth
)(
  input  logic                        clk,
  input  logic                        req,
  input  logic                        we,
  input  logic [$clog2(NumWords)-1:0] addr,
  input  logic [DataWidth-1:0]        wdata,
  input  logic [BeWidth-1:0]          be,
  output logic [DataWidth-1:0]        rdata
);
  (* ram_style = "block" *) logic [DataWidth-1:0] sram [NumWords-1:0];

  always_ff @(posedge clk) begin
    if (req && we) begin
      for (int unsigned j = 0; j < BeWidth; j++)
        if (be[j]) sram[addr][j*ByteWidth +: ByteWidth] <= wdata[j*ByteWidth +: ByteWidth];
    end else if (req) begin
      rdata <= sram[addr];
    end
  end
endmodule

module bram_test_top (
  input  logic        clk,
  input  logic        req,
  input  logic        we,
  input  logic [7:0]  addr,
  input  logic [63:0] wdata,
  input  logic [7:0]  be,
  output logic [63:0] rdata_typedef,
  output logic [63:0] rdata_literal
);
  bram_test_typedef u_typedef (
    .clk(clk), .req(req), .we(we), .addr(addr), .wdata(wdata), .be(be), .rdata(rdata_typedef)
  );
  bram_test_literal u_literal (
    .clk(clk), .req(req), .we(we), .addr(addr), .wdata(wdata), .be(be), .rdata(rdata_literal)
  );
endmodule
