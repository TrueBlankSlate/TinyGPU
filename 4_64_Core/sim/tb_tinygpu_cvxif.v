`timescale 1ns / 1ps
// CVXIF-level testbench for tinygpu_cvxif_wrap.
//
// Drives the issue/commit/result ports directly, as CVA6's cvxif_fu would,
// without booting a real CVA6 or modeling its icache/dcache AXI protocol.
// Exercises: vle64.v (funct3=3'b111, opcode 0000111) -> LOAD -> L3_WRITE
// (req/ready handshake) -> WAIT_COMMIT -> result_valid, then a vector-add
// (opcode 1010111, funct3=3'b000, instr_id=6'h00) over the just-loaded data.
//
// Run in Vivado: Add Sources -> Simulation Sources -> this file, then
// set as simulation top and run behavioral simulation.
module tb_tinygpu_cvxif;

  reg clk = 0;
  reg rst_ni = 0;
  always #5 clk = ~clk; // 100 MHz

  // ---- CVXIF issue ----
  reg         issue_valid;
  reg  [31:0] issue_instr;
  reg  [2:0]  issue_id;
  reg  [63:0] issue_rs1;
  wire        issue_ready;
  wire        issue_accept;
  wire        issue_writeback;

  // ---- CVXIF commit ----
  reg         commit_valid;
  reg  [2:0]  commit_id;
  reg         commit_kill;

  // ---- CVXIF result ----
  reg         result_ready;
  wire        result_valid;
  wire [2:0]  result_id;
  wire [63:0] result_data;
  wire [4:0]  result_rd;
  wire        result_we;

  // ---- GPU's real AXI4 read master (behavioral memory model below) ----
  wire [3:0]  ar_id;
  wire [63:0] ar_addr;
  wire [7:0]  ar_len;
  wire [2:0]  ar_size;
  wire [1:0]  ar_burst;
  wire        ar_valid;
  reg         ar_ready;
  reg  [3:0]  r_id;
  reg  [63:0] r_data;
  reg  [1:0]  r_resp;
  reg         r_last;
  reg         r_valid;
  wire        r_ready;

  integer errors;

  tinygpu_cvxif_wrap dut (
    .clk             (clk),
    .rst_ni          (rst_ni),
    .issue_valid     (issue_valid),
    .issue_instr     (issue_instr),
    .issue_id        (issue_id),
    .issue_rs1       (issue_rs1),
    .issue_ready     (issue_ready),
    .issue_accept    (issue_accept),
    .issue_writeback (issue_writeback),
    .commit_valid    (commit_valid),
    .commit_id       (commit_id),
    .commit_kill     (commit_kill),
    .result_ready    (result_ready),
    .result_valid    (result_valid),
    .result_id       (result_id),
    .result_data     (result_data),
    .result_rd       (result_rd),
    .result_we       (result_we),
    .ar_id           (ar_id),
    .ar_addr         (ar_addr),
    .ar_len          (ar_len),
    .ar_size         (ar_size),
    .ar_burst        (ar_burst),
    .ar_valid        (ar_valid),
    .ar_ready        (ar_ready),
    .r_id            (r_id),
    .r_data          (r_data),
    .r_resp          (r_resp),
    .r_last          (r_last),
    .r_valid         (r_valid),
    .r_ready         (r_ready)
  );

  // ------------------------------------------------------------
  // Behavioral real-AXI4 memory: one 32-beat burst per vle64.v (matches
  // tinygpu_fsm.v's ar_len=31). Word w (0..31) returns value w directly --
  // same 0..31 sequential pattern as the old hand-rolled 8x256-bit model,
  // just delivered as 32 real 64-bit beats.
  // ------------------------------------------------------------
  localparam R_IDLE = 1'b0, R_DATA = 1'b1;
  reg       r_state;
  reg [3:0] r_id_q;
  reg [7:0] r_len_q;
  reg [7:0] r_cnt;

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
            r_len_q  <= ar_len;
            r_cnt    <= 8'd0;
            r_state  <= R_DATA;
          end
        end
        R_DATA: begin
          if (!r_valid) begin
            r_id    <= r_id_q;
            r_data  <= {56'd0, r_cnt};
            r_resp  <= 2'b00;
            r_last  <= (r_cnt == r_len_q);
            r_valid <= 1'b1;
          end else if (r_valid && r_ready) begin
            if (r_cnt == r_len_q) begin
              r_valid <= 1'b0;
              r_state <= R_IDLE;
            end else begin
              r_cnt   <= r_cnt + 8'd1;
              r_data  <= {56'd0, r_cnt + 8'd1};
              r_last  <= (r_cnt + 8'd1 == r_len_q);
              r_id    <= r_id_q;
              r_resp  <= 2'b00;
              r_valid <= 1'b1;
            end
          end
        end
      endcase
    end
  end

  // ------------------------------------------------------------
  // Stimulus
  // ------------------------------------------------------------
  task issue_and_commit(input [31:0] instr, input [63:0] rs1_val, input [2:0] id);
    begin
      @(posedge clk);
      issue_valid <= 1'b1;
      issue_instr <= instr;
      issue_rs1   <= rs1_val;
      issue_id    <= id;
      @(posedge clk);
      while (!issue_accept) @(posedge clk);
      issue_valid <= 1'b0;

      // wait until FSM is ready for commit (WAIT_COMMIT reached) --
      // simplest robust approach: just hold commit_valid high with the
      // matching id and let the FSM consume it whenever it reaches
      // WAIT_COMMIT.
      commit_valid <= 1'b1;
      commit_id    <= id;
      commit_kill  <= 1'b0;

      result_ready <= 1'b1;
      wait (result_valid);
      @(posedge clk);
      commit_valid <= 1'b0;
      @(posedge clk);
    end
  endtask

  reg [31:0] vle64_instr;
  reg [31:0] vadd_instr;

  initial begin
    errors       = 0;
    issue_valid  = 1'b0;
    issue_instr  = 32'd0;
    issue_id     = 3'd0;
    issue_rs1    = 64'd0;
    commit_valid = 1'b0;
    commit_id    = 3'd0;
    commit_kill  = 1'b0;
    result_ready = 1'b0;

    // vle64.v: opcode=0000111, funct3=111, vs1(rs1 field)=x1 (cache line 1),
    // vs2 field=x2 (cache line 2). rd/funct7 bits unused, tied 0.
    vle64_instr = {7'b0000000, 5'd2, 5'd1, 3'b111, 5'd0, 7'b0000111};

    // vector add: opcode=1010111 (OP-V), funct3=000, instr_id(func6)=6'h00,
    // vs2=x2, vs1=x1, vm=0, vd=x3 (unused by hardware, sink only).
    vadd_instr = {6'h00, 1'b0, 5'd2, 5'd1, 3'b000, 5'd3, 7'b1010111};

    repeat (5) @(posedge clk);
    rst_ni = 1'b1;
    repeat (2) @(posedge clk);

    $display("[%0t] Issuing vle64.v (base addr = 64'h1000) ...", $time);
    issue_and_commit(vle64_instr, 64'h0000_0000_0000_1000, 3'd1);
    $display("[%0t] vle64.v result_valid seen. result_data=%h (expect 0, no scalar writeback)",
              $time, result_data);
    if (result_data !== 64'd0 || result_we !== 1'b0)
      begin errors = errors + 1; $display("  FAIL: unexpected scalar writeback on load"); end

    repeat (3) @(posedge clk);

    $display("[%0t] Issuing vector-add over loaded data ...", $time);
    issue_and_commit(vadd_instr, 64'd0, 3'd2);
    $display("[%0t] vector-add result_valid seen.", $time);

    // core0 uses mat_mem[vs1=1] elements 0..3 as 'a', mat_mem[vs2=2] as 'b'.
    // Loaded beats: elem(vs1=1) row = elements 4..7 (mat_mem index 1 is
    // written from w_data[1023:0], i.e. beats 0-3 -> elements 0..15;
    // mat_mem[2] from w_data[2047:1024], beats 4-7 -> elements 16..31).
    // core0_a/core0_b take [255:0] slice = first 4 elements of each row.
    // ALU func3=000 instr_id=6'h00 computes vd = s_vs1 + s_vs2.
    $display("[%0t] vd_0_0=%0d vd_0_1=%0d vd_0_2=%0d vd_0_3=%0d",
              $time, dut.vd_0_0, dut.vd_0_1, dut.vd_0_2, dut.vd_0_3);

    if (errors == 0) $display("TB PASS");
    else $display("TB FAIL: %0d error(s)", errors);

    repeat (5) @(posedge clk);
    $finish;
  end

  initial begin
    #200000;
    $display("TIMEOUT waiting for DUT");
    $finish;
  end

endmodule
