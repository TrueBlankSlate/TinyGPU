module global_mem(
    input  wire         clk,
    input  wire         we,

    input  wire [4:0]   w_addr,
    input  wire [127:0] w_data,

    input  wire [4:0]   r_addr_a,
    input  wire [4:0]   r_addr_b,

    output wire [127:0] r_data_a,
    output wire [127:0] r_data_b
);

reg [127:0] mem [0:31]; //32 vectors of 128 bit can fit in it.
integer i;

initial begin
    for(i=0;i<32;i=i+1)
        mem[i] = 128'd0; //set all to zero first
end

always @(posedge clk) begin
    if(we)
        mem[w_addr] <= w_data; //writing (from host hoga ye in later stage)
end

// asynchronous read
assign r_data_a = mem[r_addr_a];
assign r_data_b = mem[r_addr_b];

endmodule
