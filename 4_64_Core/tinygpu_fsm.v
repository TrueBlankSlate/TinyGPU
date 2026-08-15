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

    // AXI4 read master (for vle64 memory loads)
    output reg [63:0]  araddr,
    output reg         arvalid,
    input              arready,
    input      [255:0] rdata,
    input              rvalid,
    output             rready,

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
reg [63:0] base_q;
reg        is_vle64_q; //queue
reg        is_vmacc_q; //queue
reg [31:0] instr_q; //queue

// AXI beat tracking — 8 x 256-bit beats = 2048 bits
reg [2:0]  beat_q;       // 0..7
reg        ar_sent_q;

// vmacc pass tracking (4 passes: pass 0..3, one output row per pass)
reg [1:0]  pass_q;
reg        pass_done;
// cache.v re-registers mat_a/mat_b on top of RegisterFile's own capture
// register, so a new `pass_0` needs one full settle cycle before we_0
// can safely strobe RegisterFile with that pass's row. phase=0: advance
// pass_0 and wait; phase=1: row is settled, fire we_0 for it.
reg        phase;

assign issue_ready  = (state == IDLE);
assign issue_accept = (state == IDLE) && issue_valid && is_mine;
assign result_id    = id_q;
assign rready       = (state == LOAD) && ar_sent_q;

always @(posedge clk) begin
    if (!rst_ni) begin
        state       <= IDLE;
        id_q        <= 3'd0;
        base_q      <= 64'd0;
        is_vle64_q  <= 1'b0;
        is_vmacc_q  <= 1'b0;
        instr_q     <= 32'd0;
        beat_q      <= 3'd0;
        ar_sent_q   <= 1'b0;
        w_data_0    <= 2048'd0;
        araddr      <= 64'd0;
        arvalid     <= 1'b0;
        we_0        <= 1'b0;
        we_1        <= 1'b0;
        pass_0      <= 2'd0;
        pass_q      <= 2'd0;
        pass_done   <= 1'b0;
        phase       <= 1'b0;
        acc_rst_out <= 1'b0;
        result_valid<= 1'b0;
        instruction_0 <= 32'd0;
    end else begin
        // Default pulse signals low every cycle
        we_0        <= 1'b0;
        we_1        <= 1'b0;
        acc_rst_out <= 1'b0;

        case (state)
            IDLE: begin
                result_valid <= 1'b0;
                beat_q       <= 3'd0;
                ar_sent_q    <= 1'b0;
                pass_q       <= 2'd0;
                pass_0       <= 2'd0;
                pass_done    <= 1'b0;
                phase        <= 1'b0;

                // when the issue is accepted
                if (issue_accept) begin
                    id_q       <= issue_id;
                    instr_q    <= issue_instr;
                    is_vle64_q <= is_vle64;
                    is_vmacc_q <= is_vmacc;
                    instruction_0 <= issue_instr;

                    if (is_vle64) begin
                        base_q  <= issue_rs1;
                        araddr  <= issue_rs1;
                        arvalid <= 1'b1;
                        state   <= LOAD;
                    end else begin
                        state   <= WAIT_COMMIT;
                    end
                end
            end

            LOAD: begin
                // Address handshake — one address per beat
                if (arvalid && arready) begin
                    arvalid   <= 1'b0;
                    ar_sent_q <= 1'b1;
                end

                // Data handshake
                if (rvalid && rready) begin
                    // Shift new beat into top, previous data moves down
                    w_data_0  <= {rdata, w_data_0[2047:256]}; // <=========
                    ar_sent_q <= 1'b0;

                    if (beat_q == 3'd7) begin
                        // All 8 beats received — issue write request to L3
                        we_1    <= 1'b1;
                        state   <= L3_WRITE;
                    end else begin
                        // Next beat: increment address by 32 bytes (256 bits)
                        beat_q  <= beat_q + 3'd1;
                        araddr  <= base_q + {beat_q + 3'd1, 5'b00000}; // (beat+1)*32
                        arvalid <= 1'b1;
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
                if (commit_valid && (commit_id == id_q)) begin
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
                        // pass 0 was already fired by WAIT_COMMIT's we_0 pulse
                        // (its row was settled during the whole WAIT_COMMIT
                        // dwell, so no extra settle cycle was needed there).
                        if (!phase) begin
                            // advance to the next pass and let cache.v's
                            // registered mat_a/mat_b catch up for one cycle
                            pass_q <= pass_q + 2'd1;
                            pass_0 <= pass_q + 2'd1;
                            phase  <= 1'b1;
                        end else begin
                            // row is settled now; fire we_0 to capture it
                            we_0  <= 1'b1;
                            phase <= 1'b0;
                            if (pass_q == 2'd3) begin
                                pass_done   <= 1'b1;
                                acc_rst_out <= 1'b1; // reset acc for next vmacc op
                                // result_valid deliberately not set here --
                                // this we_0 pulse's dot_reg[3] capture lands
                                // one cycle later; the (!pass_done) check
                                // failing next cycle falls through to the
                                // else branch below, giving that cycle to land.
                            end
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