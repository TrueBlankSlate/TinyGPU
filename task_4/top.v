module sw_btn_led(
    input wire[3:0]btn,
    output wire[3:0]led
    );

    assign led = btn;

endmodule


/*
#10    btn: 0 1 0 1
    -> led: 0 1 0 1
#10    btn: 1 1 1 1 
    -> led: 1 1 1 1 

*/