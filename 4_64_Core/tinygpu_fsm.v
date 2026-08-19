`timescale 1ns / 1ps
// CV-X-IF command lifetime FSM.
// States: IDLE -> LOAD (vle64 only) -> L3_WRITE -> WAIT_COMMIT -> COMPUTE
// pass_0 is auto-incremented here for vmacc multi-pass.
module tinygpu_fsm (
    input              clk,
    input              rst_ni,        // active-low sync reset

    // CV-X-IF issue channel (from CVA6)
    input              issue_valid,
    input      [31:0]  issue_instr,
    input      [2:0]   issue_id,
    input      [63:0]  issue_rs1,     // base address for vle64 <=========
    output             issue_ready,
    output             issue_accept,

    // CV-X-IF commit channel (from CVA6)
    input              commit_valid,
    input      [2:0]   commit_id,
    input              commit_kill,

    // CV-X-IF result channel (to CVA6)
    input              result_ready,
    output reg         result_valid,
    output     [2:0]   result_id,

    // Real AXI4 read master (for vle64 memory loads) -- same channel shape
    // as CVA6's own noc_ar_*/noc_r_* so this can be arbitered onto the
    // same physical memory with axi_mux, not a separate fake protocol.
    // One burst of 32 x 64-bit beats (2048 bits total) per vle64.v, not
    // 8 hand-rolled 256-bit requests.
    output reg [3:0]   ar_id,
    output reg [63:0]  ar_addr,
    output reg [7:0]   ar_len,
    output reg [2:0]   ar_size,
    output reg [1:0]   ar_burst,
    output reg         ar_valid,
    input              ar_ready,
    input      [3:0]   r_id,
    input      [63:0]  r_data,
    input      [1:0]   r_resp,
    input              r_last,
    input              r_valid,
    output             r_ready,

    // To fourc_1_wrapper
    output reg [31:0]  instruction_0,
    output reg [2047:0] w_data_0,
    output reg         we_0,          // compute/ALU strobe
    output reg         we_1,          // L3 cache write request
    input              l3_ready,      // L3 cache write-accept pulse
    output reg [1:0]   pass_0,        // vmacc pass counter
    output reg         acc_rst_out    // reset accumulator between vmacc ops
);

// Instruction decode
wire [6:0] opcode   = issue_instr[6:0];
wire [2:0] funct3   = issue_instr[14:12];
// RVV width field: 3'b111 = 64-bit element width (vle64.v)
wire       is_vle64    = (opcode == 7'b0000111) && (funct3 == 3'b111);
wire       is_vec_arith = (opcode == 7'b1010111);
wire       is_vmacc    = is_vec_arith && (issue_instr[31:26] == 6'h2D);
wire       is_mine     = is_vle64 | is_vec_arith;

// State encoding
localparam IDLE        = 3'd0;
localparam LOAD        = 3'd1;
localparam L3_WRITE    = 3'd2;
localparam WAIT_COMMIT = 3'd3;
localparam COMPUTE     = 3'd4;

reg [2:0]  state;

// Captured instruction fields
reg [2:0]  id_q;
reg        is_vle64_q; //queue
reg        is_vmacc_q; //queue
reg [31:0] instr_q; //queue

// vmacc pass tracking (4 passes: pass 0..3, one output row per pass,
// one we_0 fire per clock cycle -- cache.v is purely combinational so a
// new pass_0's row is visible to RegisterFile the same cycle it changes)
reg [1:0]  pass_q;
reg        pass_done;

// Latches a commit pulse that matches our tracked transaction, even if it
// arrives before we reach WAIT_COMMIT. CVA6's cvxif_issue_register_commit_
// if_driver.sv drives commit_valid_o = issue_valid_o && issue_ready_i --
// i.e. synchronously with issue, not as a separate later event (this
// config never speculates, so it always commits immediately). Since
// issue_ready is tied high, commit_valid for a given id can pulse the
// exact same cycle issue_accept fires for it, long before the LOAD/
// L3_WRITE burst (32 beats) finishes and WAIT_COMMIT is even entered --
// a live-only check in WAIT_COMMIT misses that pulse entirely and the FSM
// hangs forever.
reg        commit_recv_q;

assign issue_ready  = (state == IDLE);
assign issue_accept = (state == IDLE) && issue_valid && is_mine;
assign result_id    = id_q;
// Always ready to accept beats once the burst is under way -- real AXI4
// bursts auto-increment addressing on the interconnect side, so unlike
// the old 8-beat scheme we don't need to gate readiness on a per-beat
// address handshake.
assign r_ready       = (state == LOAD);

always @(posedge clk) begin
    if (!rst_ni) begin
        state       <= IDLE;
        id_q        <= 3'd0;
        is_vle64_q  <= 1'b0;
        is_vmacc_q  <= 1'b0;
        instr_q     <= 32'd0;
        w_data_0    <= 2048'd0;
        ar_id       <= 4'd0;
        ar_addr     <= 64'd0;
        ar_len      <= 8'd0;
        ar_size     <= 3'd0;
        ar_burst    <= 2'd0;
        ar_valid    <= 1'b0;
        we_0        <= 1'b0;
        we_1        <= 1'b0;
        pass_0      <= 2'd0;
        pass_q      <= 2'd0;
        pass_done   <= 1'b0;
        acc_rst_out <= 1'b0;
        result_valid<= 1'b0;
        instruction_0 <= 32'd0;
        commit_recv_q <= 1'b0;
    end else begin
        // Default pulse signals low every cycle
        we_0        <= 1'b0;
        we_1        <= 1'b0;
        acc_rst_out <= 1'b0;

        // Capture a matching commit pulse the instant it appears, whatever
        // state we're in -- see commit_recv_q's declaration comment above.
        // Checked against issue_id during the same-cycle accept (id_q isn't
        // latched yet then) and against id_q afterwards. WAIT_COMMIT below
        // can still override this back to 0 in the same cycle it consumes
        // the commit (case runs after this, so its assignment wins).
        if (state == IDLE && issue_accept) begin
            commit_recv_q <= commit_valid && (commit_id == issue_id);
        end else if (commit_valid && (commit_id == id_q)) begin
            commit_recv_q <= 1'b1;
        end

        case (state)
            IDLE: begin
                result_valid <= 1'b0;
                pass_q       <= 2'd0;
                pass_0       <= 2'd0;
                pass_done    <= 1'b0;

                // when the issue is accepted
                if (issue_accept) begin
                    id_q       <= issue_id;
                    instr_q    <= issue_instr;
                    is_vle64_q <= is_vle64;
                    is_vmacc_q <= is_vmacc;
                    instruction_0 <= issue_instr;

                    if (is_vle64) begin
                        // One AXI4 burst: 32 beats x 8 bytes = 2048 bits.
                        // The interconnect auto-increments the address per
                        // beat -- no manual per-beat address math needed.
                        ar_id    <= 4'd0;
                        ar_addr  <= issue_rs1;
                        ar_len   <= 8'd31;
                        ar_size  <= 3'd3;   // 8 bytes/beat
                        ar_burst <= 2'b01;  // INCR
                        ar_valid <= 1'b1;
                        state    <= LOAD;
                    end else begin
                        state   <= WAIT_COMMIT;
                    end
                end
            end

            LOAD: begin
                // One-shot address phase for the whole burst
                if (ar_valid && ar_ready) begin
                    ar_valid <= 1'b0;
                end

                // Data phase: shift each 64-bit beat in; r_last (real AXI4)
                // tells us the burst is done instead of counting to a fixed
                // beat number ourselves.
                if (r_valid && r_ready) begin
                    w_data_0 <= {r_data, w_data_0[2047:64]};
                    if (r_last) begin
                        we_1  <= 1'b1;
                        state <= L3_WRITE;
                    end
                end
            end

            L3_WRITE: begin
                // we_1 was pulsed for one cycle on entry; wait for L3 to
                // acknowledge the write before proceeding to commit.
                if (l3_ready) begin
                    state <= WAIT_COMMIT;
                end
            end

            WAIT_COMMIT: begin
                if (commit_recv_q || (commit_valid && (commit_id == id_q))) begin
                    commit_recv_q <= 1'b0;
                    if (commit_kill) begin
                        state <= IDLE;
                    end else if (is_vle64_q) begin
                        // Load done, no compute needed
                        result_valid <= 1'b1;
                        state        <= IDLE;
                    end else begin
                        // Kick compute
                        we_0  <= 1'b1;
                        state <= COMPUTE;
                    end
                end
            end

            COMPUTE: begin
                // Wait one cycle for ALUs to latch (we_0 was pulsed last cycle)
                // Then signal result
                if (!result_valid) begin
                    if (is_vmacc_q && !pass_done) begin
                        // vmacc (4x4 matmul) needs 4 passes: pass i broadcasts
                        // row i of A to every core, which already holds a
                        // fixed column of B, producing that pass's output row.
                        // pass 0 was already fired by WAIT_COMMIT's we_0 pulse.
                        // One we_0 fire per cycle -- cache.v is combinational,
                        // so the new pass_0's row is visible to RegisterFile
                        // the same cycle pass_0 changes, no settle cycle needed.
                        if (pass_q == 2'd3) begin
                            pass_done   <= 1'b1;
                            acc_rst_out <= 1'b1; // reset acc for next vmacc op
                            // result_valid deliberately not set here --
                            // this we_0 pulse's dot_reg[3] capture lands
                            // one cycle later; the (!pass_done) check
                            // failing next cycle falls through to the
                            // else branch below, giving that cycle to land.
                        end else begin
                            pass_q <= pass_q + 2'd1;
                            pass_0 <= pass_q + 2'd1;
                            we_0   <= 1'b1;      // fire immediately for the new pass
                        end
                    end else begin
                        result_valid <= 1'b1;
                    end
                end

                if (result_valid && result_ready) begin
                    result_valid <= 1'b0;
                    state        <= IDLE;
                end
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule