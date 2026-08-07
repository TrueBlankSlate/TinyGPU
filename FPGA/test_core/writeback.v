module writeback(
    input wire v0,
    input wire v1,
    input wire v2,
    input wire v3,
    input clk,
    input rst,
    output wire [3:0] led
)

reg counter;

always@(posedge clk) begin
    if(counter)begin 
        led[3:0]<=v0[3:0];
    end
    if(counter)begin 
        led[3:0]<=v1[3:0];
    end
    if(counter)begin 
        led[3:0]<=v2[3:0];
    end
    if(counter)begin 
        led[3:0]<=v3[3:0];
    end
    if(rst)begin 
        led[3:0]<=4b'0;
    end

end
endmodule