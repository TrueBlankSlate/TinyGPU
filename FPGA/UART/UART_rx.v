`timescale 1ns / 1ps

module UART_RX #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input clk,
    input rst,
    

    input rx,

    output reg [7:0] data,
    output reg       valid
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

            data        <= 8'd0;
            valid       <= 1'b0;

            shift_reg   <= 8'd0;
            clock_count <= 14'd0;
            bit_count   <= 3'd0;

        end

        else begin

            valid <= 1'b0;

            case (state)




                IDLE: begin

                    clock_count <= 0;
                    bit_count   <= 0;


                    if (rx == 1'b0) begin

                        clock_count <= 0;
                        state <= START;

                    end

                end

                START: begin

                 

                    if (clock_count == (CLKS_PER_BIT / 2) - 1) begin

                        clock_count <= 0;

                        if (rx == 1'b0) begin

                            bit_count <= 0;
                            state <= DATA;

                        end

                        else begin

                            state <= IDLE;

                        end

                    end

                    else begin

                        clock_count <= clock_count + 1;

                    end

                end




                DATA: begin



                    if (clock_count == CLKS_PER_BIT - 1) begin

                        clock_count <= 0;


                        shift_reg[bit_count] <= rx;


                        if (bit_count == 3'd7) begin

                            state <= STOP;

                        end

                        else begin

                            bit_count <= bit_count + 1;

                        end

                    end

                    else begin

                        clock_count <= clock_count + 1;

                    end

                end


   


                STOP: begin


                    if (clock_count == CLKS_PER_BIT - 1) begin

                        clock_count <= 0;


                        if (rx == 1'b1) begin

                            data <= shift_reg;
                            valid <= 1'b1;

                        end

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
               
