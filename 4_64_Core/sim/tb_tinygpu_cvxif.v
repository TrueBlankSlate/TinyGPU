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

  // ---- GPU AXI4 read master (behavioral memory model below) ----
  wire [63:0] axi_araddr;
  wire        axi_arvalid;
  reg         axi_arready;
  reg  [255:0]axi_rdata;
  reg         axi_rvalid;
  wire        axi_rready;

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
    .axi_araddr      (axi_araddr),
    .axi_arvalid     (axi_arvalid),
    .axi_arready     (axi_arready),
    .axi_rdata       (axi_rdata),
    .axi_rvalid      (axi_rvalid),
    .axi_rready      (axi_rready)
  );

  // ------------------------------------------------------------
  // Behavioral AXI read-only memory model, single beat in flight.
  // Beat i (256 bits = four 64-bit elements) = {i*4+3, i*4+2, i*4+1, i*4}.
  // ------------------------------------------------------------
  reg [2:0] beat_cnt;
  reg [63:0] base_addr_q;
  reg [63:0] elem_base;

  always @(posedge clk) begin
    if (!rst_ni) begin
      axi_arready <= 1'b0;
      axi_rvalid  <= 1'b0;
      beat_cnt    <= 3'd0;
    end else begin
      axi_arready <= 1'b0;
      axi_rvalid  <= 1'b0;

      if (axi_arvalid && !axi_arready) begin
        axi_arready <= 1'b1;
        if (beat_cnt == 3'd0) base_addr_q <= axi_araddr;
      end
      if (axi_arready) begin
        // one cycle after address accept, present data: beat i holds
        // four 64-bit elements {i*4+3, i*4+2, i*4+1, i*4}.
        elem_base  = {61'd0, beat_cnt} * 64'd4;
        axi_rdata <= { elem_base + 64'd3, elem_base + 64'd2,
                       elem_base + 64'd1, elem_base + 64'd0 };
        axi_rvalid <= 1'b1;
        beat_cnt   <= beat_cnt + 3'd1;
      end
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
