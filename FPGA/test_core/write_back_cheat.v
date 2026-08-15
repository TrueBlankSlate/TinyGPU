module writeback #(
    
    parameter CLK_FREQ = 100_000_000 
)(
    input wire [63:0] v0, 
    input wire [63:0] v1,
    input wire [63:0] v2,
    input wire [63:0] v3,
    input wire clk,
    input wire rst,
    output reg [3:0] led  
);


reg [31:0] counter;

always @(posedge clk) begin
    if (rst) begin
      
        counter <= 32'd0;
        led <= 4'b0000;
    end else begin
       //CLK_FREQ=100,000,000
        if (counter < (12 * CLK_FREQ)) begin
            counter <= counter + 1;
        end
        if (counter < (3 * CLK_FREQ)) begin
            led <= v0[3:0]; 
        end 
        else if (counter < (6 * CLK_FREQ)) begin
            led <= v1[3:0]; 
        end 
        else if (counter < (9 * CLK_FREQ)) begin
            led <= v2[3:0]; 
        end 
        else if (counter < (12 * CLK_FREQ)) begin
            led <= v3[3:0]; 
        end 
        else begin
            led <= 4'b0000; 
        end
    end
end

endmodule
