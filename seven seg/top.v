module top (
    input  wire CLK100MHZ,
    input  wire btn_rst,
    output wire [6:0] seg
);

    // 0.5s tick at 100MHz
    reg [26:0] tick_cnt = 0;
    reg        tick     = 0;

    always @(posedge CLK100MHZ) begin
        if (btn_rst) begin
            tick_cnt <= 0;
            tick <= 0;
        end else if (tick_cnt == 27'd49_999_999) begin
            tick_cnt <= 0;
            tick <= 1;
        end else begin
            tick_cnt <= tick_cnt + 1;
            tick <= 0;
        end
    end

    // 0-9 counter
    reg [3:0] digit = 0;
    always @(posedge CLK100MHZ) begin
        if (btn_rst)
            digit <= 0;
        else if (tick)
            digit <= (digit == 9) ? 0 : digit + 1;
    end

    // instantiate your decoder
    seven_seg u_seg (
        .num (digit),
        .seg (seg)
    );

endmodule
