module rx_assembly(
    input clk,
    input valid,
    input rst,
    input translated,
    output reg [63:0] a00,
    output reg [63:0] a01,
    output reg [63:0] a11,
    output reg [63:0] a10,
    output reg [63:0] b00,
    output reg [63:0] b01,
    output reg [63:0] b11,
    output reg [63:0] b10,
    output reg [2:0] func3,
    output reg [5:0] instr_id
            );

reg [520:0] buffer=0;

reg [10:0]bit_counter=0;

always@(posedge clk) begin

    if (rst)begin
        a00<=0;
        a01<=0;
        a11<=0;
        a10<=0;
        b00<=0;
        b01<=0;
        b11<=0;
        b10<=0;
        func3<=0;
        instr_id<=0;
        bit_counter<=0;
        buffer<=0;
    end

    else begin

    if (valid) begin
        buffer[bit_counter]<=translated;
        bit_counter<=bit_counter+1;
    end

    if(bit_counter==521)begin

        a00<=buffer[63:0];
        a01<=buffer[127:64];
        a11<=buffer[191:128];
        a10<=buffer[255:192];

        b00<=buffer[319:256];
        b01<=buffer[383:320];
        b11<=buffer[447:384];
        b10<=buffer[511:448];

        func3<=buffer[514:512];

        instr_id<=buffer[520:515];

        bit_counter<=0;
       
    end

    end



end
endmodule