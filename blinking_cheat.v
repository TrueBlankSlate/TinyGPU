module blink(
    input wire clk,
    output reg red
);

reg [26:0] reg_counter = 0;

always @(posedge clk) begin
    if (reg_counter >= 100_000_000 - 1) begin
        reg_counter <= 0;
    end
    else begin
        reg_counter <= reg_counter + 1;
    end

    if (reg_counter < 50_000_000)
        red <= 1'b0;
    else
        red <= 1'b1;
end

endmodule