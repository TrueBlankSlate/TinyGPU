`timescale 1ns / 1ps

module UART_TX #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input clk,
    input rst,

    input [7:0] data,
    input start,

    output reg tx,
    output reg done,
    output reg stop   // NEW: pulses for one cycle the moment we enter the STOP state
);

localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

localparam IDLE  = 2'd0;
localparam START = 2'd1;
localparam DATA  = 2'd2;
localparam STOP  = 2'd3;

reg [1:0] state;
reg [7:0] shift_reg;
reg [13:0] clock_count;
reg [2:0] bit_count;

always @(posedge clk or posedge rst) begin

    if (rst) begin

        state       <= IDLE;
        tx          <= 1'b1;
        done        <= 1'b0;
        stop        <= 1'b0;

        shift_reg   <= 8'd0;
        clock_count <= 0;
        bit_count   <= 0;

    end

    else begin

        done <= 1'b0;
        stop <= 1'b0;

        case (state)
            IDLE: begin

                tx <= 1'b1;
                clock_count <= 0;

                if (start) begin

                    shift_reg <= data;
                    bit_count <= 0;

                    state <= START;

                end

            end

            START: begin

                tx <= 1'b0;

                if (clock_count == CLKS_PER_BIT - 1) begin

                    clock_count <= 0;
                    bit_count <= 0;

                    state <= DATA;

                end

                else begin

                    clock_count <= clock_count + 1;

                end

            end

            DATA: begin

                tx <= shift_reg[0];

        if (clock_count == CLKS_PER_BIT - 1) begin

                    clock_count <= 0;

                    if (bit_count == 3'd7) begin

                        state <= STOP;
                        stop  <= 1'b1;   // one-cycle pulse: just entered STOP

                    end

                    else begin

                        bit_count <= bit_count + 1;
                        shift_reg <= shift_reg >> 1;

                    end

                end

                else begin

                    clock_count <= clock_count + 1;

                end

            end

            STOP: begin

                tx <= 1'b1;

                if (clock_count == CLKS_PER_BIT - 1) begin

                    clock_count <= 0;
                    done <= 1'b1;

                    state <= IDLE;
                  
        end

                else begin

                    clock_count <= clock_count + 1;

                end

            end

            default: begin

                state <= IDLE;
                
end

endcase
end

end

endmodule
