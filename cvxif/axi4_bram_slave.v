`timescale 1ns / 1ps
// Synthesizable, BRAM-backed AXI4 slave for FPGA bring-up.

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
    input  wire                        b_ready,

    input  wire [11:0]                 ar2_id,
    input  wire [31:0]                 ar2_addr,
    input  wire [3:0]                  ar2_len,
    input  wire                        ar2_valid,
    output reg                         ar2_ready,

    output reg  [11:0]                 r2_id,
    output reg  [31:0]                 r2_data,
    output reg  [1:0]                  r2_resp,
    output reg                         r2_last,
    output reg                         r2_valid,
    input  wire                        r2_ready
);

  (* ram_style = "block" *) reg [DATA_WIDTH-1:0] mem_a [0:MEM_WORDS-1];
  (* ram_style = "block" *) reg [DATA_WIDTH-1:0] mem_b [0:MEM_WORDS-1];

  initial begin
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem_a);
      $readmemh(INIT_FILE, mem_b);
    end
  end

  function [$clog2(MEM_WORDS)-1:0] widx;
    input [ADDR_WIDTH-1:0] addr;
    begin
      widx = addr[$clog2(MEM_WORDS)+2:3]; // 8 bytes/word, masked by width
    end
  endfunction

  // - Read channel (AR/R) -
  localparam R_IDLE = 1'b0, R_DATA = 1'b1;
  reg       r_state;
  reg [ID_WIDTH-1:0] r_id_q;
  reg [ADDR_WIDTH-1:0] r_addr_q;
  reg [7:0] r_len_q;
  reg [7:0] r_cnt;

  wire read_en   = (r_state == R_DATA) && (!r_valid || (r_valid && r_ready && r_cnt != r_len_q));
  wire [ADDR_WIDTH-1:0] read_addr = r_valid ? (r_addr_q + (DATA_WIDTH/8)) : r_addr_q;

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

  // Dedicated read port: touches mem_a[] and r_data only.
  always @(posedge clk) begin
    if (read_en)
      r_data <= mem_a[widx(read_addr)];
  end

  localparam R2_IDLE = 1'b0, R2_DATA = 1'b1;
  reg       r2_state;
  reg [11:0] r2_id_q;
  reg [31:0] r2_addr_q;
  reg [3:0] r2_len_q;
  reg [3:0] r2_cnt;

  wire read2_en   = (r2_state == R2_DATA) &&
                     (!r2_valid || (r2_valid && r2_ready && r2_cnt != r2_len_q));
  wire [31:0] read2_addr = r2_valid ? (r2_addr_q + 32'd4) : r2_addr_q;
  // mem_b[] stays 64-bit/word (Port A's native width) - Port B picks the
  // low or high 32-bit half of the same 64-bit word based on addr[2].
  wire [$clog2(MEM_WORDS)-1:0] read2_word = read2_addr[$clog2(MEM_WORDS)+2:3];
  wire                          read2_half = read2_addr[2];

  reg [DATA_WIDTH-1:0] r2_word_q;
  reg                   r2_half_q;

  always @(posedge clk) begin
    if (!rst_ni) begin
      ar2_ready <= 1'b0;
      r2_valid  <= 1'b0;
      r2_state  <= R2_IDLE;
    end else begin
      ar2_ready <= 1'b0;
      case (r2_state)

        R2_IDLE: begin
          r2_valid <= 1'b0;
          if (ar2_valid) begin
            ar2_ready <= 1'b1;
            r2_id_q   <= ar2_id;
            r2_addr_q <= ar2_addr;
            r2_len_q  <= ar2_len;
            r2_cnt    <= 4'd0;
            r2_state  <= R2_DATA;
          end
        end

        R2_DATA: begin
          if (!r2_valid) begin
            r2_id    <= r2_id_q;
            r2_resp  <= 2'b00;
            r2_last  <= (r2_cnt == r2_len_q);
            r2_valid <= 1'b1;
          end else if (r2_valid && r2_ready) begin
            if (r2_cnt == r2_len_q) begin
              r2_valid <= 1'b0;
              r2_state <= R2_IDLE;
            end else begin
              r2_cnt    <= r2_cnt + 4'd1;
              r2_addr_q <= r2_addr_q + 32'd4;
              r2_last   <= (r2_cnt + 4'd1 == r2_len_q);
              r2_id     <= r2_id_q;
              r2_resp   <= 2'b00;
              r2_valid  <= 1'b1;
            end
          end
        end

      endcase
    end
  end

  // Dedicated Port B read port: touches mem_b[] and r2_word_q only -
  // clean single-port template, same shape as Port A's mem_a read.
  always @(posedge clk) begin
    if (read2_en) begin
      r2_word_q <= mem_b[read2_word];
      r2_half_q <= read2_half;
    end
  end

  // Half-select, entirely downstream of the memory read - never touches
  // mem_b[].
  always @(*) begin
    r2_data = r2_half_q ? r2_word_q[63:32] : r2_word_q[31:0];
  end

  // - Write channel (AW/W/B) -
  localparam W_IDLE = 2'd0, W_DATA = 2'd1, W_RESP = 2'd2;
  reg [1:0] w_state;
  reg [ID_WIDTH-1:0] w_id_q;
  reg [ADDR_WIDTH-1:0] w_addr_q;
  integer bi;
  integer bi2;

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

  // Dedicated write port: touches mem_a[] only.
  always @(posedge clk) begin
    if (write_en)
      for (bi = 0; bi < DATA_WIDTH/8; bi = bi + 1)
        if (w_strb[bi])
          mem_a[widx(w_addr_q)][bi*8 +: 8] <= w_data[bi*8 +: 8];
  end

  always @(posedge clk) begin
    if (write_en)
      for (bi2 = 0; bi2 < DATA_WIDTH/8; bi2 = bi2 + 1)
        if (w_strb[bi2])
          mem_b[widx(w_addr_q)][bi2*8 +: 8] <= w_data[bi2*8 +: 8];
  end

endmodule
