`timescale 1ns / 1ps
// 4x4 matmul (vmacc) testbench for tinygpu_cvxif_wrap.
//
// Loads A into L3 line 1 and B (=A here, so C=A*A) into L3 line 2 via a
// single vle64.v, then issues the matmul (opcode=1010111, func3=3'b010,
// funct6=6'h2D, vs1=1, vs2=2) and checks all 16 output elements against
// the hand-computed C = A x A.
//
// A = [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]]
// C = A x A =
//   [ 90 100 110 120]
//   [202 228 254 280]
//   [314 356 398 440]
//   [426 484 542 600]
//
// vd_<pass>_<core> holds C[pass][core] once the matmul completes.
module tb_matmul;

  reg clk = 0;
  reg rst_ni = 0;
  always #5 clk = ~clk;

  reg         issue_valid;
  reg  [31:0] issue_instr;
  reg  [2:0]  issue_id;
  reg  [63:0] issue_rs1;
  wire        issue_ready;
  wire        issue_accept;
  wire        issue_writeback;

  reg         commit_valid;
  reg  [2:0]  commit_id;
  reg         commit_kill;

  reg         result_ready;
  wire        result_valid;
  wire [2:0]  result_id;
  wire [63:0] result_data;
  wire [4:0]  result_rd;
  wire        result_we;

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
  // tinygpu_fsm.v's ar_len=31). Word w (0..31) returns (w%16)+1, so
  // words 0-15 give matrix A = 1..16 and words 16-31 repeat 1..16 for
  // matrix B, giving B = A -- same data pattern as before, just delivered
  // as 32 real 64-bit beats instead of 8 hand-rolled 256-bit ones.
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
            r_data  <= (r_cnt % 8'd16) + 64'd1;
            r_resp  <= 2'b00;
            r_last  <= (r_cnt == r_len_q);
            r_valid <= 1'b1;
          end else if (r_valid && r_ready) begin
            if (r_cnt == r_len_q) begin
              r_valid <= 1'b0;
              r_state <= R_IDLE;
            end else begin
              r_cnt   <= r_cnt + 8'd1;
              r_data  <= ((r_cnt + 8'd1) % 8'd16) + 64'd1;
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
  reg [31:0] matmul_instr;
  reg [63:0] expected [0:3][0:3];
  integer p, c;

  initial begin
    errors = 0;
    issue_valid  = 1'b0;
    issue_instr  = 32'd0;
    issue_id     = 3'd0;
    issue_rs1    = 64'd0;
    commit_valid = 1'b0;
    commit_id    = 3'd0;
    commit_kill  = 1'b0;
    result_ready = 1'b0;

    // vle64.v: vs1=1 (A's L3 line), vs2=2 (B's L3 line)
    vle64_instr  = {7'b0000000, 5'd2, 5'd1, 3'b111, 5'd0, 7'b0000111};
    // vmacc: opcode=1010111, func3=010, funct6=6'h2D, vs2=2, vs1=1
    matmul_instr = {6'h2D, 1'b0, 5'd2, 5'd1, 3'b010, 5'd0, 7'b1010111};

    expected[0][0]=90;  expected[0][1]=100; expected[0][2]=110; expected[0][3]=120;
    expected[1][0]=202; expected[1][1]=228; expected[1][2]=254; expected[1][3]=280;
    expected[2][0]=314; expected[2][1]=356; expected[2][2]=398; expected[2][3]=440;
    expected[3][0]=426; expected[3][1]=484; expected[3][2]=542; expected[3][3]=600;

    repeat (5) @(posedge clk);
    rst_ni = 1'b1;
    repeat (2) @(posedge clk);

    $display("[%0t] Loading A into line1, B(=A) into line2 ...", $time);
    issue_and_commit(vle64_instr, 64'h0000_0000_0000_2000, 3'd1);

    repeat (3) @(posedge clk);

    $display("[%0t] Issuing matmul (vs1=1, vs2=2) ...", $time);
    issue_and_commit(matmul_instr, 64'd0, 3'd2);
    $display("[%0t] matmul result_valid seen.", $time);

    $display("Result C (vd_<pass>_<core>):");
    $display("  %0d %0d %0d %0d", dut.vd_0_0, dut.vd_0_1, dut.vd_0_2, dut.vd_0_3);
    $display("  %0d %0d %0d %0d", dut.vd_1_0, dut.vd_1_1, dut.vd_1_2, dut.vd_1_3);
    $display("  %0d %0d %0d %0d", dut.vd_2_0, dut.vd_2_1, dut.vd_2_2, dut.vd_2_3);
    $display("  %0d %0d %0d %0d", dut.vd_3_0, dut.vd_3_1, dut.vd_3_2, dut.vd_3_3);

    if (dut.vd_0_0 !== expected[0][0]) begin errors=errors+1; $display("FAIL vd_0_0: got %0d expect %0d", dut.vd_0_0, expected[0][0]); end
    if (dut.vd_0_1 !== expected[0][1]) begin errors=errors+1; $display("FAIL vd_0_1: got %0d expect %0d", dut.vd_0_1, expected[0][1]); end
    if (dut.vd_0_2 !== expected[0][2]) begin errors=errors+1; $display("FAIL vd_0_2: got %0d expect %0d", dut.vd_0_2, expected[0][2]); end
    if (dut.vd_0_3 !== expected[0][3]) begin errors=errors+1; $display("FAIL vd_0_3: got %0d expect %0d", dut.vd_0_3, expected[0][3]); end
    if (dut.vd_1_0 !== expected[1][0]) begin errors=errors+1; $display("FAIL vd_1_0: got %0d expect %0d", dut.vd_1_0, expected[1][0]); end
    if (dut.vd_1_1 !== expected[1][1]) begin errors=errors+1; $display("FAIL vd_1_1: got %0d expect %0d", dut.vd_1_1, expected[1][1]); end
    if (dut.vd_1_2 !== expected[1][2]) begin errors=errors+1; $display("FAIL vd_1_2: got %0d expect %0d", dut.vd_1_2, expected[1][2]); end
    if (dut.vd_1_3 !== expected[1][3]) begin errors=errors+1; $display("FAIL vd_1_3: got %0d expect %0d", dut.vd_1_3, expected[1][3]); end
    if (dut.vd_2_0 !== expected[2][0]) begin errors=errors+1; $display("FAIL vd_2_0: got %0d expect %0d", dut.vd_2_0, expected[2][0]); end
    if (dut.vd_2_1 !== expected[2][1]) begin errors=errors+1; $display("FAIL vd_2_1: got %0d expect %0d", dut.vd_2_1, expected[2][1]); end
    if (dut.vd_2_2 !== expected[2][2]) begin errors=errors+1; $display("FAIL vd_2_2: got %0d expect %0d", dut.vd_2_2, expected[2][2]); end
    if (dut.vd_2_3 !== expected[2][3]) begin errors=errors+1; $display("FAIL vd_2_3: got %0d expect %0d", dut.vd_2_3, expected[2][3]); end
    if (dut.vd_3_0 !== expected[3][0]) begin errors=errors+1; $display("FAIL vd_3_0: got %0d expect %0d", dut.vd_3_0, expected[3][0]); end
    if (dut.vd_3_1 !== expected[3][1]) begin errors=errors+1; $display("FAIL vd_3_1: got %0d expect %0d", dut.vd_3_1, expected[3][1]); end
    if (dut.vd_3_2 !== expected[3][2]) begin errors=errors+1; $display("FAIL vd_3_2: got %0d expect %0d", dut.vd_3_2, expected[3][2]); end
    if (dut.vd_3_3 !== expected[3][3]) begin errors=errors+1; $display("FAIL vd_3_3: got %0d expect %0d", dut.vd_3_3, expected[3][3]); end

    if (errors == 0) $display("TB PASS - matmul correct");
    else $display("TB FAIL: %0d mismatched element(s)", errors);

    repeat (5) @(posedge clk);
    $finish;
  end

  initial begin
    #200000;
    $display("TIMEOUT waiting for DUT");
    $finish;
  end

endmodule
