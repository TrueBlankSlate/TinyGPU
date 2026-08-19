# CVA6 to TinyGPU full pipeline

## 1 Testbench
* The testbench in /sim/tb_cva6_boot.v is acting like the end part of the GNU RISC-V compiler. For now I have hard coded the values of vmacc, vle64, srli, slli, lui to their respective bit instructions. vmacc and vle64 are hand-encoded to match real RVV 1.0 opcode/funct fields as closely as possible (turns out the operand fields still mean different things in our hardware than in the real spec, more on that below).

* It also has the value of where CVA6 boots from in its large DRAM memory. The dram memory simulator (we need simulator for now since we arent on a real FPGA yet) is of 512 kiB.
* So CVA6 boots from 0x8000_0000 location because that address has to sit inside CVA6Cfg.CachedRegionAddrBase/Length or the icache takes the non-cacheable path instead of the normal cache-line-fill path we're simulating. 0x8000_0000 is also just the conventional place DRAM starts on RISC-V boards so it made sense to pick.
* CVA6 does NOT load matrix A into its own data memory. CVA6 only supplies the base address (x1's value) to TinyGPU over CVXIF. TinyGPU has its own AXI4 read master and does its own burst read for the matrix, arbitrated onto the same bus as CVA6's traffic. CVA6 never touches the matrix data at all. Preload is hardcoded for simulation, in /sim/tb_cva6_boot.v/ --- From here CVA6 does its own thing it goes through its pipeline of Frontend - Fetch - Decode (blackbox)

<mark> NOTE: srli, slli, lui, jal are valid in RV-I so cva6 processes those instructions normally, not through CVXIF. </mark>

* vle64.v and vmacc are actually real RVV 1.0 mnemonics, not made up. They're illegal here specifically because this CVA6 build (cv64a6_imafdc_sv39, no V extension implemented at all) doesn't know the vector ISA, so any vector-space opcode is unrecognized regardless. At the same time we have set CvxifConfigEn = 1 so this combination tells us that we can offload the instruction to TinyGPU. Also worth flagging: vsetvli (real RVV instr that a compiler would always emit before real vector code) shares our same major opcode 1010111 - our FSM only checks opcode, not funct3, so it would currently get swallowed too if it ever showed up. Need to keep this in mind if we ever move off hand-encoding.

## 2 CVXIF Files 

There are 3 files related to CVXIF and tinygpu interface. 
1. cva6_sv_shim.sv: converts the signals sent by CVA6 (SystemVerilog structs) to TinyGPU (plain verilog). It unpacks cvxif_req/cvxif_resp. It also does more than that though - it owns the AXI4 arbiter (axi_mux) that merges CVA6's own memory traffic with TinyGPU's onto one shared bus, so this file is really two jobs in one.

2. cva6_tinygpu_soc.v: (SOC = System on Chip). This is just wiring, no real logic. It instantiates the shim (which has CVA6 + the arbiter inside it) and tinygpu_cvxif_wrap as siblings and connects their ports 1:1. Its actual job is exposing one single noc_* AXI4 port to the outside world.

3. tinygpu_cvxif_wrap.v: instantiates tinygpu_fsm.v (the control FSM) and fourc_1_wrapper (the actual 4-core TinyGPU compute design).

## 3 TinyGPU FSM:
* This topic is about tinygpu_fsm.v -- this is important because it has important signals that tell the L3_cache whether to take in data from cva6 or not.
* The 5 states of the FSM are: IDLE -> LOAD -> L3_WRITE -> WAIT_COMMIT -> COMPUTE. (maybe writeback will come as well when i make it later? not sure.)
* not every instruction visits all 5 though - it's a fork. vle64.v goes IDLE -> LOAD -> L3_WRITE -> WAIT_COMMIT -> IDLE (skips COMPUTE, a load doesn't compute anything). vmacc goes IDLE -> WAIT_COMMIT -> COMPUTE -> IDLE (skips LOAD/L3_WRITE, it works off data already sitting in L3 from an earlier load).

### writing to l3_cache by cva6
* Basically, tinygpu starts off assuming it is freshly loaded which means state = idle. it then sees VLE64 coming from cva6 (via the cvxif path). when it sees vle64 the state updates to LOAD.
<mark> NOTE: i know that we cant just write to the cache every time cva6 sends something. </mark>
Harshit gave a good analogy - When you want to enter the room you dont just ring the bell and enter, you ring the bell and people inside the room check if they want you and then allow/ refuse you. To do that we have L3_WRITE stage.

* So in load state we have AXI input called r_ready and r_valid. Correction: this is the AXI read-data channel, so it's TinyGPU reading FROM memory, not CVA6 writing anything - CVA6 isn't involved here at all beyond having supplied the address earlier. r_valid && r_ready true just means one 64-bit beat landed; that happens 32 times (shifting into a 2048-bit register) while state stays LOAD. We only move to L3_WRITE once r_last is also true, on the 32nd beat.
* By the time we're in L3_WRITE the AXI burst is already fully done (all 32 beats gathered during LOAD). L3_WRITE is the separate step after that - handing the now-complete 2048 bits off to the L3 cache (we_1 pulses once) and waiting for l3_ready to ack it.
* WAIT_COMMIT state: this is where fsm takes signals --: commit_recv_q || (commit_valid && (commit_id == id_q and if TRUE then it says: OKAY i am ready to commit to an operation/ instruction.

* COMPUTE: This state tells the system that we have to do the calculation now, data is ready and we need to do computation. In this there is a condition for vmacc.vv as well - where ever we see that operation is vmacc we have to increment the pass variable by 1 (4 passes for 4x4 matrix multiplication)
