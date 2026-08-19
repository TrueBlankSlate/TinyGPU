module bridge( 
    input clk,
    input reg a00,a01,a11,a10,b00,b01,b11,b10
    output reg mat_a[255:0],mat_b[255:0]  );

    always@( posedge clk) begin
        mat_a<={a00,a01,a11,a10}
        mat_b<={b00,b01,b11,b10}
    end


endmodule
