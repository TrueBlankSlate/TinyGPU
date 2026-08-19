module bridge( 
    input clk,
    input reg [63:0]a00,a01,a11,a10,b00,b01,b11,b10,
    output reg [255:0]mat_a,mat_b );

    always@( posedge clk) begin
        mat_a<={a00,a01,a11,a10};
        mat_b<={b00,b01,b11,b10};
    end


endmodule
