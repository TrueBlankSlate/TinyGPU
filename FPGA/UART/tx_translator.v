`timescale 1ns / 1ps

module tx_translator(

    input clk,
    input rst,

    input [63:0] v00,
    input [63:0] v01,
    input [63:0] v11,
    input [63:0] v10,

    input start,
    input tx_stop,   // from UART_TX.stop -- pulses when UART just entered STOP
    input tx_done,   // from UART_TX.done -- pulses when UART just left STOP (back at IDLE)

    output reg [7:0] ascii_converted_bit,   // this is r1
    output reg tx_start,
    output reg busy,
    output reg done

);

reg [1:0] decider;      // which value: 0=v00, 1=v01, 2=v11, 3=v10
reg [5:0] bit_counter;  // which bit of that value, counting 0..63 (MSB first)

always @(posedge clk or posedge rst) begin

    if (rst) begin

        decider <= 0;
        bit_counter <= 0;
        ascii_converted_bit <= 8'h00;

        tx_start <= 0;
        busy <= 0;
        done <= 0;

    end

    else begin

        tx_start <= 0;
        done <= 0;

        if (start && !busy) begin

            decider <= 0;
            bit_counter <= 0;
            busy <= 1;

            if (v00[63])
                ascii_converted_bit <= 8'h31;
            else
                ascii_converted_bit <= 8'h30;

            tx_start <= 1;

        end

        else if (busy) begin

            if (tx_stop) begin
                // UART already latched this byte into its own shift
                // register when it left IDLE -- r1 isn't needed anymore
                ascii_converted_bit <= 8'h00;
            end

            if (tx_done) begin

                if (decider == 3 && bit_counter == 63) begin

                    busy <= 0;
                    done <= 1;

                end

                else if (bit_counter == 63) begin

                    bit_counter <= 0;
                    decider <= decider + 1;

                    case (decider + 1)

                        1: begin
                            if (v01[63])
                                ascii_converted_bit <= 8'h31;
                            else
                                ascii_converted_bit <= 8'h30;
                        end

                        2: begin
                            if (v11[63])
                                ascii_converted_bit <= 8'h31;
                            else
                                ascii_converted_bit <= 8'h30;
                        end

                        3: begin
                            if (v10[63])
                                ascii_converted_bit <= 8'h31;
                            else
                                ascii_converted_bit <= 8'h30;
                        end

                        default: begin
                            ascii_converted_bit <= 8'h30;
                        end

                    endcase

                    tx_start <= 1;

                end

                else begin

                    bit_counter <= bit_counter + 1;

                    case (decider)

                        0: begin
                            if (v00[63 - (bit_counter + 1)])
                                ascii_converted_bit <= 8'h31;
                            else
                                ascii_converted_bit <= 8'h30;
                        end

                        1: begin
                            if (v01[63 - (bit_counter + 1)])
                                ascii_converted_bit <= 8'h31;
                            else
                                ascii_converted_bit <= 8'h30;
                        end

                        2: begin
                            if (v11[63 - (bit_counter + 1)])
                                ascii_converted_bit <= 8'h31;
                            else
                                ascii_converted_bit <= 8'h30;
                        end

                        3: begin
                            if (v10[63 - (bit_counter + 1)])
                                ascii_converted_bit <= 8'h31;
                            else
                                ascii_converted_bit <= 8'h30;
                        end

                        default: begin
                            ascii_converted_bit <= 8'h30;
                        end

                    endcase

                    tx_start <= 1;

                end

            end

        end

    end

end

endmodule
