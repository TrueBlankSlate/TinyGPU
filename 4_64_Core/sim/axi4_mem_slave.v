`timescale 1ns / 1ps
// Minimal single-outstanding-transaction AXI4 slave, behavioral only.
//
// Sized for CVA6's actual traffic pattern (cv64a6_imafdc_sv39, confirmed by
// reading core/cache_subsystem/cva6_icache_axi_wrapper.sv and
// wt_axi_adapter.sv): icache misses issue a 2-beat INCR burst (len=1,
// size=3) at AXI ID 0; dcache scalar loads/stores are single-beat (len=0)
// with per-access size/wstrb; dcache line-fills are 2-beat. Burst type is
// always INCR. This model doesn't care which master an ID belongs to -- it
// just accepts len in {0,1,...}, echoes id on the response, and returns
// exactly arlen+1 beats with rlast on the final one.
//
// AR/R and AW/W/B run as two independent state machines sharing one `mem`
// array, since CVA6 can have a read and a write in flight at once.
module axi4_mem_slave #(
    parameter ID_WIDTH   = 4,
    parameter ADDR_WIDTH = 64,
    parameter DATA_WIDTH = 64,
    parameter MEM_WORDS  = 65536   // 512 KiB, power of 2 for address masking
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

  reg [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];

  function [$clog2(MEM_WORDS)-1:0] widx;
    input [ADDR_WIDTH-1:0] addr;
    begin
      widx = addr[$clog2(MEM_WORDS)+2:3]; // 8 bytes/word, masked by width
    end
  endfunction

  // ---------------- Read channel (AR/R) ----------------
  localparam R_IDLE = 1'b0, R_DATA = 1'b1;
  reg               r_state;
  reg [ID_WIDTH-1:0]   r_id_q;
  reg [ADDR_WIDTH-1:0] r_addr_q;
  reg [7:0]            r_len_q;
  reg [7:0]            r_cnt;

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
            // first beat: load using the address/count as captured from AR
            r_id    <= r_id_q;
            r_data  <= mem[widx(r_addr_q)];
            r_resp  <= 2'b00;
            r_last  <= (r_cnt == r_len_q);
            r_valid <= 1'b1;
          end else if (r_valid && r_ready) begin
            if (r_cnt == r_len_q) begin
              r_valid <= 1'b0;
              r_state <= R_IDLE;
            end else begin
              // load the NEXT beat's data/last using the incremented
              // address/count directly, in the same cycle -- computing
              // it from the pre-increment r_addr_q here (and updating
              // r_addr_q separately below) would duplicate this beat's
              // data one cycle later and never assert r_last on the
              // true final beat.
              r_cnt    <= r_cnt + 8'd1;
              r_addr_q <= r_addr_q + (DATA_WIDTH/8);
              r_data   <= mem[widx(r_addr_q + (DATA_WIDTH/8))];
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

  // ---------------- Write channel (AW/W/B) ----------------
  localparam W_IDLE = 2'd0, W_DATA = 2'd1, W_RESP = 2'd2;
  reg [1:0]            w_state;
  reg [ID_WIDTH-1:0]   w_id_q;
  reg [ADDR_WIDTH-1:0] w_addr_q;
  integer bi;

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
            for (bi = 0; bi < DATA_WIDTH/8; bi = bi + 1)
              if (w_strb[bi])
                mem[widx(w_addr_q)][bi*8 +: 8] <= w_data[bi*8 +: 8];
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

endmodule
