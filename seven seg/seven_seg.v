module seven_seg(
    input clk,
    input [3:0] num,
    output [6:0] seg
);

    reg [6:0] segment;
    always @(posedge clk) begin
        case (num)
            4'd0: segment = 7'b0111111;
            4'd1: segment = 7'b0000110;
            4'd2: segment = 7'b1011011;
            4'd3: segment = 7'b1001111;
            4'd4: segment = 7'b1100110;
            4'd5: segment = 7'b1101101;
            4'd6: segment = 7'b1111101;
            4'd7: segment = 7'b0000111;
            4'd8: segment = 7'b1111111;
            4'd9: segment = 7'b1101111;
            default: segment = 7'b0000000;
        endcase
    end

    assign seg = segment;
endmodule
