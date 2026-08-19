# CVA6 to TinyGPU full pipeline

## 1 Testbench
* The testbench in /sim/tb_cva6_boot.v is acting like the end part of the GNU RISC-V compiler. For now I have hard coded the values of vmacc, vle64, strli, li to their respective bit instructions according to rvv spec 1.0  

* It also has the value of where CVA6 boots from in its large DRAM memory. The dram memory simulator (we need simulator for now since we arent on a real FPGA yet) is of 512 kiB (same is used in CVA6 actually).
* So CVA6 boots from 0x8000_0000 location because this places the boot code at the top of the memory hierarchy.
* From here CVA6 also loads the matrix A into its data memory (how it does this is treated as blackbox) ; It is hardcoded for simulation and you can find it in /sim/tb_cva6_boot.v/ --- From here CVA6 does its own thing it goes through its pipeline of Frontend - Fetch - Decode (blackbox)

<mark> NOTE: strli, vli, li, jal are valid in RV - I it is not only for RVV so cva6 processes those instructions. </mark>
* Since vle64 is RVV unique: CVA6 sees it and marks it as ILLEGAL. At the same time we have set CvxifConfigEn = 1 so this combination tells us that we can offload the instruction to TinyGPU

## 2 CVXIF Files 

There are 3 files related to CVXIF and tinygpu interface. 
1. CVXIF_shim: The only purpose of this is to convert the signals sent by CVA6 (SystemVerilog) to TinyGPU (verilog). It unpacks key AXI structs like cvxif_req_o and cvxif_resp_o.

2.CVXIF_SOC: (SOC = System on Chip). The purpose of this is to take the large number of noc_req* or noc_* signals from CVA6's AXI protocol. It interacts with cvxif_shim and sends to tinygpu_cvxif_wrapper.

3. tinygpu_cvxif_wrapper.v : instantiates the tinygpu wrapper and the fourc_1_wrapper (this is tiny gpu 4 core HDL wrapper ie the actual TinyGPU design).

## 3 TinyGPU FSM:
* This topic is about tinygpu_fsm.v -- this is important because it has important signals that tell the L3_cache whether to take in data from cva6 or not.
* The 5 states of the FSM are: IDLE -> LOAD -> L3_WRITE -> WAIT_COMMIT -> COMPUTE. (maybe writeback will come as well when i make it later? not sure.)

### writing to l3_cache by cva6
* Basically, tinygpu starts off assuming it is freshly loaded which means state = idle. it then sees VLE64 coming from cva6 (via the cvxif path). when it sees vle64 the state updates to LOAD.
<mark> NOTE: i know that we cant just write to the cache every time cva6 sends something. </mark>
Harshit gave a good analogy - When you want to enter the room you dont just ring the bell and enter, you ring the bell and people inside the room check if they want you and then allow/ refuse you. To do that we have L3_WRITE stage.

* So in load state we have AXI input called r_ready and r_valid. if these both are TRUE (ie CVA6 requested a write and TinyGPU accepted), then we can shift the state to L3_WRITE.
* In L3_WRITE the entire AXI BURST of 2048 bits (entire matrix) is sent to L3 cache. Till L3_Write is true it is sending but remains in AXI (meaning data is standing outside the door, waiting till it opens).
* WAIT_COMMIT state: this is where fsm takes signals --: commit_recv_q || (commit_valid && (commit_id == id_q and if TRUE then it says: OKAY i am ready to commit to an operation/ instruction.
* COMPUTE: 
