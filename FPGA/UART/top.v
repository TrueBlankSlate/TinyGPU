`timescale 1ns / 1ps
//======================================================================
// top.v
//
// Top-level wrapper wiring together:
//   UART_RX -> ascii_translator (rx) -> rx_assembly -> cache
//   cache -> 4x parallel (RegisterFile + ALU) -> (v00/v01/v11/v10)
//   v00/v01/v11/v10 -> tx_translator -> UART_TX
//
// ARCHITECTURE NOTE:
//   This mirrors the structure verified in top_cheat.v: cache's four
//   operand pairs (a0/b0, a1/b1, a2/b2, a3/b3) each get their own
//   RegisterFile + ALU instance (RF0..RF3, ALU0..ALU3), all driven by
//   one shared we/func3/instr_id, running in parallel rather than one
//   shared datapath looping 4 times. vd0->v00, vd1->v01, vd2->v11,
//   vd3->v10 (matches cache's own quadrant order: a0<->a00, a1<->a01,
//   a2<->a11, a3<->a10).
//
//   For elementwise ops (add/sub/and/or/xor/shift), a single pass
//   (we held high 2 cycles, then low) is enough -- each ALU's vd is
//   a plain combinational function of its RegisterFile's settled
//   output. For the accumulate-multiply opcode (func3=3'b010,
//   instr_id=6'h2D), each of the 4 ALUs has its own independent
//   accumulator, so this design does 2 passes (cache_64's pass 0
//   and pass 1), letting each ALU sum both cross-term products --
//   this is what makes a real 2x2 matrix multiply possible, unlike
//   the earlier single-shared-ALU version of this file.
//======================================================================

module top #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire clk,
    input  wire btn_rst_n,   // Arty A7 RESET button: idle=1, pressed=0

    input  wire rx,     // from PuTTY / USB-UART RXD
    output wire tx,     // to PuTTY / USB-UART TXD

    // optional board LEDs -- safe to leave unconnected in your XDC
    output wire led_rx_valid,
    output wire led_frame_ready,
    output wire led_tx_busy
);

    // all internal logic expects an active-high reset (rst=1 means "reset now"),
    // but the Arty A7's RESET button idles high and goes low when pressed
    wire rst = ~btn_rst_n;

    //------------------------------------------------------------
    // RX chain: UART_RX -> ascii_translator -> rx_assembly
    //------------------------------------------------------------
    wire [7:0] rx_data;
    wire       rx_valid;

    UART_RX #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_uart_rx (
        .clk  (clk),
        .rst  (rst),
        .rx   (rx),
        .data (rx_data),
        .valid(rx_valid)
    );

    // ascii_translator registers 'translated' one cycle after 'valid'
    // is asserted, so we delay the strobe by one cycle to line up
    // with when 'translated' actually holds the new bit.
    wire translated_bit;
    reg  rx_valid_d;

    always @(posedge clk or posedge rst) begin
        if (rst)
            rx_valid_d <= 1'b0;
        else
            rx_valid_d <= rx_valid;
    end

    ascii_translator u_ascii_rx (
        .clk       (clk),
        .recieved  (rx_data),
        .translated(translated_bit),
        .valid     (rx_valid)
    );

    wire [63:0] a00, a01, a11, a10;
    wire [63:0] b00, b01, b11, b10;
    wire [2:0]  func3_rx;
    wire [5:0]  instr_id_rx;

    rx_assembly u_rx_assembly (
        .clk       (clk),
        .valid     (rx_valid_d),
        .rst       (rst),
        .translated(translated_bit),
        .a00(a00), .a01(a01), .a11(a11), .a10(a10),
        .b00(b00), .b01(b01), .b11(b11), .b10(b10),
        .func3   (func3_rx),
        .instr_id(instr_id_rx)
    );

    // Mirror rx_assembly's own 521-bit frame counter so we know, from
    // the outside, exactly which cycle its outputs become valid.
    // (rx_assembly doesn't expose a "done" flag of its own.)
    reg [10:0] frame_bitcnt;
    wire       frame_captured = (frame_bitcnt == 11'd521);
    reg        frame_ready;   // one-cycle pulse: a00..instr_id are now valid

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_bitcnt <= 11'd0;
            frame_ready  <= 1'b0;
        end
        else begin
            frame_ready <= frame_captured;
            if (rx_valid_d)
                frame_bitcnt <= frame_bitcnt + 11'd1;
            if (frame_captured)
                frame_bitcnt <= 11'd0;
        end
    end

    //------------------------------------------------------------
    // cache: assemble the two 256-bit matrices for A and B.
    // Quadrant order matches rx_assembly's own layout, so this is
    // a straight concatenation.
    //------------------------------------------------------------
    wire [255:0] mat_a = {a10, a11, a01, a00};
    wire [255:0] mat_b = {b10, b11, b01, b00};

    wire [63:0] c_a0, c_a1, c_a2, c_a3;
    wire [63:0] c_b0, c_b1, c_b2, c_b3;

    cache u_cache (
        .clk (clk),
        .rst (rst),
        .we  (we),
        .func3   (func3_rx),
        .instr_id(instr_id_rx),
        .mat_a(mat_a),
        .mat_b(mat_b),
        .a0(c_a0), .a1(c_a1), .a2(c_a2), .a3(c_a3),
        .b0(c_b0), .b1(c_b1), .b2(c_b2), .b3(c_b3)
    );

    //------------------------------------------------------------
    // RegisterFile + ALU: 4 parallel pairs, one per cache output
    // (a0/b0, a1/b1, a2/b2, a3/b3). This mirrors the structure
    // verified in top_cheat.v -- one RegisterFile+ALU per operand
    // pair, all driven by the same we/func3/instr_id, running
    // simultaneously rather than sharing one datapath.
    //------------------------------------------------------------
    reg we;   // shared write-enable: cache, all 4 RegisterFiles, all 4 ALUs

    wire [63:0] vs1_0, vs2_0, vs1_1, vs2_1, vs1_2, vs2_2, vs1_3, vs2_3;
    wire [63:0] vd0, vd1, vd2, vd3;
    reg  alu_acc_rst;

    RegisterFile RF0 (.clk(clk), .rst(rst), .we(we), .vs1_in(c_a0), .vs2_in(c_b0), .vs1_out(vs1_0), .vs2_out(vs2_0));
    RegisterFile RF1 (.clk(clk), .rst(rst), .we(we), .vs1_in(c_a1), .vs2_in(c_b1), .vs1_out(vs1_1), .vs2_out(vs2_1));
    RegisterFile RF2 (.clk(clk), .rst(rst), .we(we), .vs1_in(c_a2), .vs2_in(c_b2), .vs1_out(vs1_2), .vs2_out(vs2_2));
    RegisterFile RF3 (.clk(clk), .rst(rst), .we(we), .vs1_in(c_a3), .vs2_in(c_b3), .vs1_out(vs1_3), .vs2_out(vs2_3));

    ALU ALU0 (.clk(clk), .rst(rst), .acc_rst(alu_acc_rst), .we(we), .instr_id(instr_id_rx), .func3(func3_rx), .vs1(vs1_0), .vs2(vs2_0), .vd(vd0));
    ALU ALU1 (.clk(clk), .rst(rst), .acc_rst(alu_acc_rst), .we(we), .instr_id(instr_id_rx), .func3(func3_rx), .vs1(vs1_1), .vs2(vs2_1), .vd(vd1));
    ALU ALU2 (.clk(clk), .rst(rst), .acc_rst(alu_acc_rst), .we(we), .instr_id(instr_id_rx), .func3(func3_rx), .vs1(vs1_2), .vs2(vs2_2), .vd(vd2));
    ALU ALU3 (.clk(clk), .rst(rst), .acc_rst(alu_acc_rst), .we(we), .instr_id(instr_id_rx), .func3(func3_rx), .vs1(vs1_3), .vs2(vs2_3), .vd(vd3));

    wire is_vmacc = (func3_rx == 3'b010) && (instr_id_rx == 6'h2D);

    //------------------------------------------------------------
    // Result registers fed to the TX side.
    // vd0->v00, vd1->v01, vd2->v11, vd3->v10 (matches cache's own
    // quadrant order: a0<->a00, a1<->a01, a2<->a11, a3<->a10).
    //------------------------------------------------------------
    reg [63:0] v00, v01, v11, v10;
    reg        tx_start_req;

    //------------------------------------------------------------
    // TX chain: tx_translator -> UART_TX
    //------------------------------------------------------------
    wire [7:0] tx_ascii;
    wire       tx_uart_start;
    wire       tx_uart_done;
    wire       tx_uart_stop;
    wire       tx_translator_busy;
    wire       tx_translator_done;

    tx_translator u_tx_translator (
        .clk (clk),
        .rst (rst),
        .v00(v00), .v01(v01), .v11(v11), .v10(v10),
        .start  (tx_start_req),
        .tx_stop(tx_uart_stop),
        .tx_done(tx_uart_done),
        .ascii_converted_bit(tx_ascii),
        .tx_start(tx_uart_start),
        .busy(tx_translator_busy),
        .done(tx_translator_done)
    );

    UART_TX #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_uart_tx (
        .clk  (clk),
        .rst  (rst),
        .data (tx_ascii),
        .start(tx_uart_start),
        .tx   (tx),
        .done (tx_uart_done),
        .stop (tx_uart_stop)
    );

    //------------------------------------------------------------
    // Compute sequencer.
    //
    // `we` is held HIGH for 2 consecutive cycles per pass (not 1):
    // cycle 1 is when RegisterFile latches cache's current a/b
    // outputs; cycle 2 is the cycle right after, when RegisterFile's
    // outputs already hold that settled pair -- holding we high
    // through that second cycle is what lets each ALU's accumulate
    // register (used only in vmacc mode) capture the right product
    // at the right time. we then drops for at least 1 cycle, which
    // for vmacc mode is also the falling edge cache_64 watches to
    // advance its internal pass counter (0->1). Elementwise ops
    // (non-vmacc) only need 1 pass; vmacc needs 2.
    //------------------------------------------------------------
    localparam ST_WAIT_RX  = 3'd0,
               ST_WE_HIGH1 = 3'd1,
               ST_WE_HIGH2 = 3'd2,
               ST_WE_LOW   = 3'd3,
               ST_CAPTURE  = 3'd4,
               ST_TX_START = 3'd5,
               ST_TX_WAIT  = 3'd6;

    reg [2:0] state;
    reg       pass_done; // 0 = first pass just finished, 1 = second (vmacc only) done

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= ST_WAIT_RX;
            we          <= 1'b0;
            alu_acc_rst <= 1'b0;
            pass_done   <= 1'b0;
            v00 <= 64'd0; v01 <= 64'd0; v11 <= 64'd0; v10 <= 64'd0;
            tx_start_req <= 1'b0;
        end
        else begin
            alu_acc_rst  <= 1'b0;
            tx_start_req <= 1'b0;

            case (state)

                ST_WAIT_RX: begin
                    pass_done <= 1'b0;
                    if (frame_ready) begin
                        alu_acc_rst <= 1'b1;   // clear all 4 accumulators for this new frame
                        we          <= 1'b1;
                        state       <= ST_WE_HIGH1;
                    end
                end

                ST_WE_HIGH1: begin
                    we    <= 1'b1;
                    state <= ST_WE_HIGH2;
                end

                ST_WE_HIGH2: begin
                    // RegisterFile outputs now hold this pass's settled
                    // pair, and we is still high -- correct window for
                    // each ALU's accumulate register (vmacc mode only).
                    we    <= 1'b0;
                    state <= ST_WE_LOW;
                end

                ST_WE_LOW: begin
                    if (is_vmacc && !pass_done) begin
                        // falling edge here bumps cache_64's pass 0->1
                        pass_done <= 1'b1;
                        state     <= ST_WE_HIGH1;
                    end
                    else begin
                        state <= ST_CAPTURE;
                    end
                end

                ST_CAPTURE: begin
                    // vd0..vd3 are now valid (elementwise: combinational
                    // result; vmacc: accumulated sum of both passes)
                    v00 <= vd0;
                    v01 <= vd1;
                    v11 <= vd2;
                    v10 <= vd3;
                    state <= ST_TX_START;
                end

                ST_TX_START: begin
                    if (!tx_translator_busy) begin
                        tx_start_req <= 1'b1;
                        state        <= ST_TX_WAIT;
                    end
                end

                ST_TX_WAIT: begin
                    if (tx_translator_done)
                        state <= ST_WAIT_RX;
                end

                default: state <= ST_WAIT_RX;

            endcase
        end
    end

    assign led_rx_valid    = rx_valid;
    assign led_frame_ready = frame_ready;
    assign led_tx_busy     = tx_translator_busy;

endmodule
