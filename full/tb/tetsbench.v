`timescale 1ns/1ps

module gpu_tb;

    //--------------------------------------------------
    // Clock / Reset
    //--------------------------------------------------

    reg clk = 0;
    reg rst;

    always #5 clk = ~clk;

    //--------------------------------------------------
    // Host Interface
    //--------------------------------------------------

    reg         host_mem_we;
    reg [4:0]   host_mem_waddr;
    reg [127:0] host_mem_wdata;

    reg         host_dispatch;
    reg [31:0]  host_instr;
    reg [4:0]   host_rs1_addr;
    reg [4:0]   host_rs2_addr;
    reg [4:0]   host_rd_addr;

    //--------------------------------------------------
    // DUT Outputs
    //--------------------------------------------------

    wire [127:0] result_vec;
    wire         done;

    //--------------------------------------------------
    // DUT
    //--------------------------------------------------

    gpu_top dut (
        .clk(clk),
        .rst(rst),

        .host_mem_we(host_mem_we),
        .host_mem_waddr(host_mem_waddr),
        .host_mem_wdata(host_mem_wdata),

        .host_dispatch(host_dispatch),
        .host_instr(host_instr),

        .host_rs1_addr(host_rs1_addr),
        .host_rs2_addr(host_rs2_addr),
        .host_rd_addr(host_rd_addr),

        .result_vec(result_vec),
        .done(done)
    );

    //--------------------------------------------------
    // Instructions
    //--------------------------------------------------

    localparam ADD =
        {7'h00,5'd0,5'd0,3'b000,5'd0,7'b0110011};
       //func7 rs1  rs2  func3  rd   opcode 

    //--------------------------------------------------
    // Tasks
    //--------------------------------------------------

    task write_vector;
        input [4:0] addr;
        input [127:0] vec;
        begin
            @(posedge clk);
            host_mem_we    <= 1'b1;
            host_mem_waddr <= addr;
            host_mem_wdata <= vec;

            @(posedge clk);
            host_mem_we    <= 1'b0;
        end
    endtask

    task execute;
        input [31:0] instr;
        input [4:0] rs1;
        input [4:0] rs2;
        input [4:0] rd;
        begin
            @(posedge clk);

            host_instr    <= instr;
            host_rs1_addr <= rs1;
            host_rs2_addr <= rs2;
            host_rd_addr  <= rd;
            host_dispatch <= 1'b1;

            @(posedge clk);
            host_dispatch <= 1'b0;
        end
    endtask

    task print_result;
        begin
            $display("\n========== RESULT ==========\n");
            $display("Lane3 : %0d", result_vec[127:96]);
            $display("Lane2 : %0d", result_vec[95:64]);
            $display("Lane1 : %0d", result_vec[63:32]);
            $display("Lane0 : %0d", result_vec[31:0]);
            $display("============================\n");
        end
    endtask

    //--------------------------------------------------
    // Test
    //--------------------------------------------------

    initial begin

        $display("\n========== GPU TEST ==========\n");

        $dumpfile("gpu_tb.vcd");
        $dumpvars(0, gpu_tb);

        // Default values
        rst            = 1'b1;
        host_mem_we    = 1'b0;
        host_dispatch  = 1'b0;
        host_mem_waddr = 5'd0;
        host_mem_wdata = 128'd0;
        host_instr     = 32'd0;
        host_rs1_addr  = 5'd0;
        host_rs2_addr  = 5'd0;
        host_rd_addr   = 5'd0;

        repeat (4) @(posedge clk); //why <------
        rst = 1'b0;

        // Vector 0 = {40,30,20,10}
        write_vector(
            5'd0,
            {32'd40,32'd30,32'd20,32'd10}
        );

        // Vector 1 = {4,3,2,1}
        write_vector(
            5'd1,
            {32'd4,32'd3,32'd2,32'd1}
        );

        // Execute ADD
        execute( //this why <------ 
            ADD,
            5'd0,
            5'd1,
            5'd2
        );

        wait(done);
        @(posedge clk);

        print_result();

        #20;
        $finish;
    end

    //--------------------------------------------------
    // Debug Monitor
    //--------------------------------------------------

    always @(posedge clk) begin

        $display(
            "T=%0t fetch=%b cache=%b dispatch=%b done=%b",
            $time,
            dut.fetch_req,
            dut.cache_valid,
            dut.dec_dispatch,
            done
        );

        $display(
            "laneA=%032h laneB=%032h",
            dut.lane_a_flat,
            dut.lane_b_flat
        );

        $display(
            "ALU=%032h\n",
            dut.core_result_flat
        );

    end

endmodule
