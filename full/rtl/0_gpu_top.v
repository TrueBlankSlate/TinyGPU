module gpu_top (

    input  wire         clk,
    input  wire         rst,

    input  wire         host_mem_we,
    input  wire [4:0]   host_mem_waddr,
    input  wire [127:0] host_mem_wdata,

    input  wire         host_dispatch,
    input  wire [31:0]  host_instr,
    input  wire [4:0]   host_rs1_addr,
    input  wire [4:0]   host_rs2_addr,
    input  wire [4:0]   host_rd_addr,

    output reg  [127:0] result_vec,
    output reg          done

);

wire [3:0] cores_idle;

// Scheduler
wire fetch_req;
wire [31:0] sched_instr;
wire [4:0] sched_rs1;
wire [4:0] sched_rs2;
wire [4:0] sched_rd;

// Global memory
wire [4:0] mem_addr_a;
wire [4:0] mem_addr_b;

wire [127:0] mem_data_a;
wire [127:0] mem_data_b;

// Fetcher
wire cache_load;
wire [127:0] cache_rs1;
wire [127:0] cache_rs2;

wire [31:0] fetch_instr;
wire [4:0]  fetch_rd;
wire         fetch_valid;

// Cache
wire [127:0] vec_rs1;
wire [127:0] vec_rs2;
wire         cache_valid;

// Decoder
wire [127:0] lane_a_flat;
wire [127:0] lane_b_flat;

wire [6:0] alu_op;
wire [4:0] dec_rd;
wire       dec_dispatch;

// ALU outputs
wire [127:0] core_result_flat;

reg [4:0] wb_addr;
reg wb_pending;

//////////////////////////////////////////////////////
// Memory
//////////////////////////////////////////////////////

wire mem_we = host_mem_we | done;

wire [4:0] mem_waddr =
        done ? wb_addr : host_mem_waddr;

wire [127:0] mem_wdata =
        done ? result_vec : host_mem_wdata;

global_mem GM(

    .clk(clk),
    .we(mem_we),

    .w_addr(mem_waddr),
    .w_data(mem_wdata),

    .r_addr_a(mem_addr_a),
    .r_addr_b(mem_addr_b),

    .r_data_a(mem_data_a),
    .r_data_b(mem_data_b)

);

//////////////////////////////////////////////////////
// Scheduler
//////////////////////////////////////////////////////

scheduler SCH(

    .clk(clk),
    .rst(rst),

    .dispatch_req(host_dispatch),

    .instr(host_instr),
    .vec_rs1_addr(host_rs1_addr),
    .vec_rs2_addr(host_rs2_addr),
    .vec_rd_addr(host_rd_addr),

    .cores_idle(cores_idle),

    .fetch_req(fetch_req),

    .out_instr(sched_instr),
    .out_rs1_addr(sched_rs1),
    .out_rs2_addr(sched_rs2),
    .out_rd_addr(sched_rd)

);

//////////////////////////////////////////////////////
// Fetcher
//////////////////////////////////////////////////////

fetcher F(

    .clk(clk),
    .rst(rst),

    .fetch_req(fetch_req),

    .rs1_addr(sched_rs1),
    .rs2_addr(sched_rs2),

    .instr(sched_instr),
    .rd_addr(sched_rd),

    .mem_addr_a(mem_addr_a),
    .mem_addr_b(mem_addr_b),

    .mem_data_a(mem_data_a),
    .mem_data_b(mem_data_b),

    .cache_load(cache_load),

    .cache_rs1(cache_rs1),
    .cache_rs2(cache_rs2),

    .out_instr(fetch_instr),
    .out_rd_addr(fetch_rd),
    .out_valid(fetch_valid)

);

//////////////////////////////////////////////////////
// Vector Cache
//////////////////////////////////////////////////////

vector_cache VC(

    .clk(clk),
    .rst(rst),

    .load(cache_load),

    .in_rs1(cache_rs1),
    .in_rs2(cache_rs2),

    .rs1(vec_rs1),
    .rs2(vec_rs2),

    .valid(cache_valid)

);

//////////////////////////////////////////////////////
// Decoder
//////////////////////////////////////////////////////

decoder DEC(

    .clk(clk),
    .rst(rst),

    .valid(cache_valid),

    .instr(fetch_instr),
    .rd_addr(fetch_rd),

    .vec_rs1(vec_rs1),
    .vec_rs2(vec_rs2),

    .lane_a_flat(lane_a_flat),
    .lane_b_flat(lane_b_flat),

    .alu_op(alu_op),

    .out_rd_addr(dec_rd),

    .dispatch(dec_dispatch)

);

//////////////////////////////////////////////////////
// 4 SIMD cores
//////////////////////////////////////////////////////

genvar i;

generate

for(i=0;i<4;i=i+1)

begin : CORES

core C(

    .clk(clk),
    .rst(rst),

    .dispatch(dec_dispatch),

    .data_a(lane_a_flat[i*32 +: 32]),
    .data_b(lane_b_flat[i*32 +: 32]),

    .alu_op(alu_op),

    .result(core_result_flat[i*32 +: 32]),

    .idle(cores_idle[i])

);

end

endgenerate

//////////////////////////////////////////////////////
// Writeback
//////////////////////////////////////////////////////

always @(posedge clk or posedge rst)

begin

    if(rst)

    begin

        wb_pending <= 0;
        wb_addr <= 0;

        result_vec <= 0;

        done <= 0;

    end

    else

    begin

        done <= 0;

        if(dec_dispatch)

        begin

            wb_pending <= 1;
            wb_addr <= dec_rd;

        end

        else if(wb_pending)

        begin

            result_vec <= core_result_flat;

            done <= 1;

            wb_pending <= 0;

        end

    end

end

endmodule
