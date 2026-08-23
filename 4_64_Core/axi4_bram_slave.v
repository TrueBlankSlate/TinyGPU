`timescale 1ns / 1ps
// Synthesizable, BRAM-backed AXI4 slave for FPGA bring-up.
//
// Same single-outstanding-transaction AR/R and AW/W/B protocol behavior as
// sim/axi4_mem_slave.v (that model is simulation-only -- a plain `reg`
// array with testbench-driven `initial` preloads, no synthesis intent).
// This is the real-hardware counterpart: sized to comfortably fit on-chip
// block RAM (default 8192 x 64-bit = 64 KiB) and preloaded via $readmemh,
// which Vivado bakes directly into the bitstream's BRAM initialization --
// no external boot ROM, SD card, or JTAG memory write needed for a first
// bring-up.
//
// Address decode uses the SAME low-bits-only masking as the sim model
// (widx() below), so it doesn't matter that the logical address space
// starts at 0x8000_0000 (matching CVA6Cfg.CachedRegionAddrBase) -- only
// the low bits of the address select a word here, exactly like the
// simulation memory already proven correct in tb_cva6_boot.v.
//
// mem[]'s read and write each live in their OWN minimal always block below
// (read_en/read_addr in, r_data out; write_en/w_addr_q/w_data/w_strb in,
// mem written) -- nothing else touches them. The rest of the AXI handshake
// FSM only ever produces those control signals, never references mem[]
// directly. Mixing memory access into the same multi-state always block as
// unrelated handshake regs (ar_ready/r_valid/aw_ready/b_valid/w_state...)
// is what silently defeated Vivado's BRAM inference before (confirmed:
// synthesis fell back to 32768 LUTRAM cells instead of block RAM) -- this
// split matches Vivado's canonical simple-dual-port-RAM template exactly.
module axi4_bram_slave #(
    parameter ID_WIDTH   = 5,
    parameter ADDR_WIDTH = 64,
    parameter DATA_WIDTH = 64,
    parameter MEM_WORDS  = 8192,      // 64 KiB, power of 2 for address masking
    parameter INIT_FILE  = "boot_image.hex"
)(
    input  wire                        clk,
    input  wire                        rst_ni,

    input  wire [ID_WIDTH-1:0]         ar_id,
    input  wire [ADDR_WIDTH-1:0]       ar_addr,
    input  wire [7:0]                  ar_len,
    input  wire                        ar_valid,
    output reg                         ar_ready,

    output reg  [ID_WIDTH-1:0]         r_id,
    output reg  [DATA_WIDTH-1:0]       r_data,
    output reg  [1:0]                  r_resp,
    output reg                         r_last,
    output reg                         r_valid,
    input  wire                        r_ready,

    input  wire [ID_WIDTH-1:0]         aw_id,
    input  wire [ADDR_WIDTH-1:0]       aw_addr,
    input  wire                        aw_valid,
    output reg                         aw_ready,

    input  wire [DATA_WIDTH-1:0]       w_data,
    input  wire [(DATA_WIDTH/8)-1:0]   w_strb,
    input  wire                        w_last,
    input  wire                        w_valid,
    output reg                         w_ready,

    output reg  [ID_WIDTH-1:0]         b_id,
    output reg  [1:0]                  b_resp,
    output reg                         b_valid,
    input  wire                        b_ready
);

  (* ram_style = "block" *) reg [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];

  initial begin
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem);
    end
  end

  function [$clog2(MEM_WORDS)-1:0] widx;
    input [ADDR_WIDTH-1:0] addr;
    begin
      widx = addr[$clog2(MEM_WORDS)+2:3]; // 8 bytes/word, masked by width
    end
  endfunction

  // ---------------- Read channel (AR/R) ----------------
  localparam R_IDLE = 1'b0, R_DATA = 1'b1;
  reg       r_state;
  reg [ID_WIDTH-1:0] r_id_q;
  reg [ADDR_WIDTH-1:0] r_addr_q;
  reg [7:0] r_len_q;
  reg [7:0] r_cnt;

  // Clean, combinational read-port control: "read this cycle?" / "from
  // which address?" -- consumed only by the dedicated read-port always
  // block further down. Beat 1 reads the just-latched r_addr_q; beat 2+
  // reads r_addr_q+8 the same cycle r_addr_q itself advances (matches the
  // original same-cycle-advance-and-read timing exactly).
  wire read_en   = (r_state == R_DATA) &&
                    (!r_valid || (r_valid && r_ready && r_cnt != r_len_q));
  wire [ADDR_WIDTH-1:0] read_addr = r_valid ? (r_addr_q + (DATA_WIDTH/8))
                                             : r_addr_q;

  always @(posedge clk) begin
    if (!rst_ni) begin
      ar_ready <= 1'b0;
      r_valid  <= 1'b0;
      r_state  <= R_IDLE;
    end else begin
      ar_ready <= 1'b0;
      case (r_state)

        R_IDLE: begin
          r_valid <= 1'b0;
          if (ar_valid) begin
            ar_ready <= 1'b1;
            r_id_q   <= ar_id;
            r_addr_q <= ar_addr;
            r_len_q  <= ar_len;
            r_cnt    <= 8'd0;
            r_state  <= R_DATA;
          end
        end

        R_DATA: begin
          if (!r_valid) begin
            r_id    <= r_id_q;
            r_resp  <= 2'b00;
            r_last  <= (r_cnt == r_len_q);
            r_valid <= 1'b1;
          end else if (r_valid && r_ready) begin
            if (r_cnt == r_len_q) begin
              r_valid <= 1'b0;
              r_state <= R_IDLE;
            end else begin
              r_cnt    <= r_cnt + 8'd1;
              r_addr_q <= r_addr_q + (DATA_WIDTH/8);
              r_last   <= (r_cnt + 8'd1 == r_len_q);
              r_id     <= r_id_q;
              r_resp   <= 2'b00;
              r_valid  <= 1'b1;
            end
          end
        end

      endcase
    end
  end

  // Dedicated read port: touches mem[] and r_data only.
  always @(posedge clk) begin
    if (read_en)
      r_data <= mem[widx(read_addr)];
  end

  // ---------------- Write channel (AW/W/B) ----------------
  localparam W_IDLE = 2'd0, W_DATA = 2'd1, W_RESP = 2'd2;
  reg [1:0] w_state;
  reg [ID_WIDTH-1:0] w_id_q;
  reg [ADDR_WIDTH-1:0] w_addr_q;
  integer bi;

  wire write_en = (w_state == W_DATA) && w_valid && w_ready;

  always @(posedge clk) begin
    if (!rst_ni) begin
      aw_ready <= 1'b0;
      w_ready  <= 1'b0;
      b_valid  <= 1'b0;
      w_state  <= W_IDLE;
    end else begin
      aw_ready <= 1'b0;
      w_ready  <= 1'b0;

      case (w_state)
        W_IDLE: begin
          b_valid <= 1'b0;
          if (aw_valid) begin
            aw_ready <= 1'b1;
            w_id_q   <= aw_id;
            w_addr_q <= aw_addr;
            w_state  <= W_DATA;
          end
        end

        W_DATA: begin
          w_ready <= 1'b1;
          if (w_valid && w_ready) begin
            if (w_last) begin
              w_state <= W_RESP;
            end else begin
              w_addr_q <= w_addr_q + (DATA_WIDTH/8);
            end
          end
        end

        W_RESP: begin
          b_id    <= w_id_q;
          b_resp  <= 2'b00;
          b_valid <= 1'b1;
          if (b_valid && b_ready) begin
            b_valid <= 1'b0;
            w_state <= W_IDLE;
          end
        end

      endcase
    end
  end

  // Dedicated write port: touches mem[] only.
  always @(posedge clk) begin
    if (write_en)
      for (bi = 0; bi < DATA_WIDTH/8; bi = bi + 1)
        if (w_strb[bi])
          mem[widx(w_addr_q)][bi*8 +: 8] <= w_data[bi*8 +: 8];
  end

endmodule
