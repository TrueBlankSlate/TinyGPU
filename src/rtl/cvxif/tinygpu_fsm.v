`timescale 1ns / 1ps
// CV-X-IF command lifetime FSM.
// States: IDLE -> LOAD (vle64 only) -> L3_WRITE -> WAIT_COMMIT -> COMPUTE
//         IDLE -> WRITEBACK (vse64 only) -> WAIT_COMMIT
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

    // Real AXI4 read master (for vle64 memory loads) - same channel shape
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

    // Real AXI4 write master (for vse64.v writeback) - same channel shape
    // as the read master above, arbitered onto the same shared bus. One
    // burst of 16 x 64-bit beats (1024 bits total, one 4x4 result matrix)
    // per vse64.v, sourced from wb_data (see writeback.v).
    output reg [3:0]   aw_id,
    output reg [63:0]  aw_addr,
    output reg [7:0]   aw_len,
    output reg [2:0]   aw_size,
    output reg [1:0]   aw_burst,
    output reg         aw_valid,
    input              aw_ready,
    output reg [63:0]  w_data,
    output reg [7:0]   w_strb,
    output reg         w_last,
    output reg         w_valid,
    input              w_ready,
    input      [3:0]   b_id,
    input      [1:0]   b_resp,
    input              b_valid,
    output             b_ready,

    input      [1023:0] wb_data,

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
// RVV width field: 3'b111 = 64-bit element width (vle64.v/vse64.v)
wire       is_vle64    = (opcode == 7'b0000111) && (funct3 == 3'b111);
// Real RVV store major opcode (STORE-FP space), mirroring vle64.v's
// LOAD-FP opcode the same way real vse64.v mirrors real vle64.v.
wire       is_vse64    = (opcode == 7'b0100111) && (funct3 == 3'b111);
wire       is_vec_arith = (opcode == 7'b1010111);
wire       is_vmacc    = is_vec_arith && (issue_instr[31:26] == 6'h2D);
wire       is_mine     = is_vle64 | is_vse64 | is_vec_arith;

// State encoding
localparam IDLE        = 3'd0;
localparam LOAD        = 3'd1;
localparam L3_WRITE    = 3'd2;
localparam WAIT_COMMIT = 3'd3;
localparam COMPUTE     = 3'd4;
localparam WRITEBACK   = 3'd5;

reg [2:0]  state;

// Captured instruction fields
reg [2:0]  id_q;
reg        is_vle64_q; //queue
reg        is_vmacc_q; //queue
reg        is_vse64_q; //queue
reg [31:0] instr_q; //queue
reg [3:0]  wb_cnt;    // vse64.v write beat counter (0..15)

// vmacc pass tracking (4 passes: pass 0..3, one output row per pass,
// one we_0 fire per clock cycle - cache.v is purely combinational so a
// new pass_0's row is visible to RegisterFile the same cycle it changes)
reg [1:0]  pass_q;
reg        pass_done;

//fix for vmacc.vv stale pass
reg [1023:0] wb_data_q;
reg commit_recv_q;

assign issue_ready  = (state == IDLE);
assign issue_accept = (state == IDLE) && issue_valid && is_mine;
assign result_id    = id_q;
// Always ready to accept beats once the burst is under way - real AXI4
// bursts auto-increment addressing on the interconnect side, so unlike
// the old 8-beat scheme we don't need to gate readiness on a per-beat
// address handshake.
assign r_ready       = (state == LOAD);
assign b_ready        = (state == WRITEBACK);

always @(posedge clk) begin
    if (!rst_ni) begin
        state <= IDLE; //<===========
        id_q <= 3'd0;
        is_vle64_q  <= 1'b0;
        is_vmacc_q  <= 1'b0;
        is_vse64_q  <= 1'b0;
        instr_q     <= 32'd0;
        w_data_0 <= 2048'd0;
        ar_id    <= 4'd0;
        ar_addr  <= 64'd0;
        ar_len   <= 8'd0;
        ar_size  <= 3'd0;
        ar_burst <= 2'd0;
        ar_valid <= 1'b0;
        aw_id    <= 4'd0;
        aw_addr  <= 64'd0;
        aw_len   <= 8'd0;
        aw_size  <= 3'd0;
        aw_burst <= 2'd0;
        aw_valid <= 1'b0;
        w_data   <= 64'd0;
        w_strb   <= 8'd0;
        w_last   <= 1'b0;
        w_valid  <= 1'b0;
        wb_cnt   <= 4'd0;
        we_0     <= 1'b0;
        we_1     <= 1'b0;
        pass_0   <= 2'd0;
        pass_q   <= 2'd0;
        pass_done   <= 1'b0;
        acc_rst_out <= 1'b0;
        result_valid<= 1'b0;
        instruction_0 <= 32'd0;
        commit_recv_q <= 1'b0;
        wb_data_q   <= 1024'd0;
    end else begin
        // Default pulse signals low every cycle
        we_0        <= 1'b0;
        we_1        <= 1'b0;
        acc_rst_out <= 1'b0;

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
                    is_vse64_q <= is_vse64;
                    instruction_0 <= issue_instr;
                    
                    wb_data_q  <= wb_data;

                    if (is_vle64) begin
                        // One AXI4 burst: 32 beats x 8 bytes = 2048 bits.
                        // The interconnect auto-increments the address per
                        // beat - no manual per-beat address math needed.
                        ar_id    <= 4'd0;
                        ar_addr  <= issue_rs1;
                        ar_len   <= 8'd31;
                        ar_size  <= 3'd3;   // 8 bytes/beat
                        ar_burst <= 2'b01;  // INCR
                        ar_valid <= 1'b1;
                        state    <= LOAD;
                    end else if (is_vse64) begin
                        
                        aw_id    <= 4'd0;
                        aw_addr  <= issue_rs1;
                        aw_len   <= 8'd15;
                        aw_size  <= 3'd3;   // 8 bytes/beat
                        aw_burst <= 2'b01;  // INCR
                        aw_valid <= 1'b1;
                        w_data   <= wb_data[0*64 +: 64];
                        w_strb   <= 8'hFF;
                        w_last   <= 1'b0;
                        w_valid  <= 1'b1;
                        wb_cnt   <= 4'd0;
                        state    <= WRITEBACK;
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

                /* Data phase: shift each 64-bit beat in; r_last (real AXI4) 
                tells us the burst is done instead of counting to a fixed
                beat number ourselves. */
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

            WRITEBACK: begin
                // One-shot address phase, same shape as LOAD's AR handling.
                if (aw_valid && aw_ready) begin
                    aw_valid <= 1'b0;
                end

                // Data phase: stream 16 beats out of wb_data. We set w_last
                // ourselves (we know beat 15 is the last one), the mirror
                // image of LOAD reading r_last from the memory.
                if (w_valid && w_ready) begin
                    if (wb_cnt == 4'd15) begin
                        w_valid <= 1'b0;
                    end else begin
                        wb_cnt  <= wb_cnt + 4'd1;
                        // wb_data_q (frozen at issue_accept), not live
                        // wb_data - see wb_data_q's declaration comment.
                        w_data  <= wb_data_q[(wb_cnt + 4'd1)*64 +: 64];
                        w_last  <= (wb_cnt + 4'd1 == 4'd15);
                        w_valid <= 1'b1;
                    end
                end

                if (b_valid && b_ready) begin
                    state <= WAIT_COMMIT;
                end
            end

            WAIT_COMMIT: begin
                if (commit_recv_q || (commit_valid && (commit_id == id_q))) begin
                    commit_recv_q <= 1'b0;
                    if (commit_kill) begin
                        state <= IDLE;
                    end else if (is_vle64_q || is_vse64_q) begin
                        // Load or writeback done, no compute needed
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
                        
                        if (pass_q == 2'd3) begin
                            pass_done   <= 1'b1;
                            acc_rst_out <= 1'b1; 
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