module sw_btn_led(
    input wire[3:0]btn,
    output wire[3:0]led
    );

    assign led = btn;

endmodule