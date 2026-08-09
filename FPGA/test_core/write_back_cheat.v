module writeback #(
    // Set for Artix-7 35T standard 100 MHz clock
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

// A 32-bit register can hold up to ~4.29 billion cycles
reg [31:0] counter;

always @(posedge clk) begin
    if (rst) begin
        // Reset state
        counter <= 32'd0;
        led <= 4'b0000;
    end else begin
        // Stop counting once we hit the 12-second mark to prevent overflow
        if (counter < (12 * CLK_FREQ)) begin
            counter <= counter + 1;
        end

        // Time window multiplexer
        if (counter < (3 * CLK_FREQ)) begin
            led <= v0[3:0]; // 0 to 3 seconds
        end 
        else if (counter < (6 * CLK_FREQ)) begin
            led <= v1[3:0]; // 3 to 6 seconds
        end 
        else if (counter < (9 * CLK_FREQ)) begin
            led <= v2[3:0]; // 6 to 9 seconds
        end 
        else if (counter < (12 * CLK_FREQ)) begin
            led <= v3[3:0]; // 9 to 12 seconds
        end 
        else begin
            led <= 4'b0000; // Shut off after 12 seconds
        end
    end
end

endmodule