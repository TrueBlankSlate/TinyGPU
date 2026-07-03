# Overview

Synapse32 is a cpu made using riscV ISA  

In this blog I'll try to explain what each part of pipeline tries to do and co-relate the pipeline abstraction and the actual verilog modules.  
I will also identify which parts are going to be used in TinyGPU and which probably won't.  

Part C and D: Hazard Handling, CSR

It has the following pipeline:

* Instruction Fetch
* Instruction Decode
* Execute
* Memory Access
* Write Back

### A) Pipeline
This part explains what the pipeline used is and what components are in the pipeline.
___
> #### **1. Instruction fetch** 
takes next instruction from Instruction Memory module.  
It updates the  program counter to move to next "PID"  
<img width="213" height="307" alt="image" src="https://github.com/user-attachments/assets/9285a481-8d40-4f6b-b4de-36ef6cbd1e5b" />


___

> #### **2. Instruction Decode**
<img width="1283" height="415" alt="image-1" src="https://github.com/user-attachments/assets/b65fa37f-35a7-46dd-a598-5b2e593bf2a5" />

<p align="center">Image 2: Different instruction fomrats in 32 bit architecture </p>
                      

**R, I, SB, UJ are RISC Instruction formats**  
each letter designates how the 32 bit stream is arranged and what it contains
* R = Register               (For math and logic between 2 registers)
* I = Immediate             (For math between register and a constant number)
* S/B = Store / Branch      (For conditional loops and logic jumps)   
* J = Jump                  (For something like a function call?)
* U = Upper Intermediate    (For something like a function call?)  

<mark> **1. Decoder**: from this 32 bit format the decoder separates rs2, rs2, rd, imm and opcode and sends it to the Register module or the control unit. </mark>

1. Sent to Control Unit: rs1 value, rs2 value, imm constant, instruction from **decoder**
2. Sent to ALU: rs1 value, rs2 value, imm constant, instruction from **CU**

<mark> **2. Creation of instruction ID which is sent to ALU: VVV IMP**:  </mark>

The original 32 bit format has func7 (bits 31-25) and func3 (bits 14-12)  
The instr_id is generated from a combination of these 2.
<br><br>
<img width="510" height="467" alt="image-5" src="https://github.com/user-attachments/assets/75e41782-7212-4d49-9816-ebf9ea1a9488" />

<p align="left"> Image 3: encoding using func7 and func3 from bit format </p>

For example if func7 = 7'h0 and func3 = 3'h0 then we represent it in the 10 bit as 0000000 000 and this case is given as instr_id = INSTR_ADD  
            if func7 = 7'h2 and func3 = 3'h4 then we represent it in 10 but as 0000001 100 and this case is given as instr_id = INSTR_XOR  
            (Note that INSTR_ADD and INSTR_XOR come from the instr_define.vh file)

The same is repeated for other formats (like Immediate, S, B, J, U)



___  

> #### **3. Execute**
The execute step of the pipeline consists of the ALU. All the mathe and logic happen inside the ALU
ALU receives the Instruction from the CU  
it also receives the rs1 and rs2 variables (even imm) and those are the "operands" in an instruction.

1. Instruction ID:  
The instruction ID are given instr_defines.vh   
The ALU uses a switch case to choose between a range of tasks (I think in GPUs this if else would be very slow)
<img width="670" height="220" alt="image-4" src="https://github.com/user-attachments/assets/02ac520f-1786-41e3-9fe8-e241930e0012" />

<p align="center"> Image 4: combinational logic block to give output in ALU </p>
<br>

___
> #### **4: Memory Access** 

This is made if some data in the control unit is too big for the register to hold then it is stored here and accessed when we need it  
Unlike Imem, Data Memory is Read/ Write. Instruction Memory is used to decode the instruction memory value (Read only)  
[ Step 1: LOAD ]     DMem (RAM) -----------> Register (e.g., x1)
[ Step 2: EXECUTE]   ALU adds/manipulates the data inside x1
[ Step 3: STORE ]    Register (x1) ------> DMem (RAM)    

<img width="295" height="247" alt="image-6" src="https://github.com/user-attachments/assets/e765fa9a-ed0c-4bf9-89e8-19f6b3491184" />
<p align="left"> Image 5: Data Memory sends the big data to and from control unit. control unit will pass it to a register inside the ALU </p>  

> #### **5: Write Back**
Write back is last part of the pipeline where the output computed from the ALU is sent to the Data Memory  


___
___
### B) What can be used in TinyGPU?
This part I want to talk about what I think the architecture of the parallel processer we are designing is and how it can be different from Synapse CPU.  

In TinyGPU we just have to do 2 tasks:
1. Matrix Multiplication
2. Vector Addition

* right off the start I dont think we need so many instruction header files for this if we need only an addition and a multiplication operation (handling float point value)  
* Even the ALU will be different and it will instead contain threads/ cores that run the multiply add operation.
The only task is to layout these cores such that they can do row - column operations.         

* Another thing that willl be different is that we will need a <mark>scheduler</mark> that schedule some threads at a time and doesnt move till next cycle till all threads return a "valid" or "ready" signal to prevent corruption.  

<img width="423" height="362" alt="image-7" src="https://github.com/user-attachments/assets/8c114f02-1e58-4b24-8928-73bb1022a312" />
<p align="center">Image 6: How a scheduler can look </p>

* Second thing we need is faster, <mark>local and private threads to each thread group similar to an register file </mark> because matrix multiplication is a Fused Multiply Add -- this means we do a set of multiply and then add. Registers might not be enought to store this data and if we dont re use it it'll lead to latency.
<img width="352" height="197" alt="image-8" src="https://github.com/user-attachments/assets/6302f21e-2be2-46c4-bc3c-2bfb4b14b4d7" />

<p align="center">Image 7: Zoom in image of SM-NVidia showing register file

* Another thing which I'm not familiar with yet is a systolic array. I think what they do is pass data as it comes without having to store and load it repeatedly which allows for data reuse (= good performance)

___
___
### C) Hazard Handling in Synapse and corelation with TinyGPU

So synapse32 handles hazard/ error handling and this part focuses on understanding the nature of hazard in comp arch and what potential hazards are in a parallel processor.  

> #### 1. Read after Write (RAW) Hazard
This is when there are multiple operations to be done (like multiply then add) and we have to wait for the threads in operation 1 to complete working before moving to next.  
<img width="922" height="477" alt="image" src="https://github.com/user-attachments/assets/09310803-86e7-44a6-aa4a-bca0fec15d59" />  
<p align="center">Image 8: RAW Hazard, source: https://www.csd.uwo.ca/~mmorenom/cs3350_moreno.Winter-2017/notes/L6-ILP-2.pdf </p>

In this if we try to do the sub instruction before the add we get wrong or garbage values.  
An example of this is matrix multiplication:  IF I forget to multiply a[0,0] * b[0,0] and directly move on to the sum a[1,1]*b[1,1] my c[0,0] will give incorrect results.

In GPU's this can be handled by <mark>__syncthreads()</mark> which is something I learnt in CUDA C++  
__syncthreads() ensures that none of the code 

Example usage:  
<img width="652" height="142" alt="image" src="https://github.com/user-attachments/assets/7b15ceec-ae6c-474c-876a-e13ae1c1fe9e" />
<p align="center"> Image 9: usage of __syncthreads() in parallel programming <br> Source: https://stackoverflow.com/questions/54825498/cuda-programming-reducing-with-complete-unrolling-without-syncthreads

in this till all threads reach a "valid" state they are not allowed to move on to the next operation, ensuring no garbage data is sent to the next operation.

____

> ####2. Warp and Branch Divergence / Control and Branch Hazards

Branch Divergence is when in the same operation a set of threads choose to take different paths. A example (tho it is not part of tiny gpu scope) is activation functions like ReLU or leaky ReLU
<img width="645" height="467" alt="image" src="https://github.com/user-attachments/assets/e8fe3865-c3ee-42d3-8a8d-e4cd8d30504a" />

<p align="center"> Image 10: Branch Divergence visualisation. Source: https://brrrviz.com/warp-divergence/conditional-branches  </p>

A few ways that I know on how to handle branch divergence is  
a. giving data properly (first 500 elements execute if() and next 500 do the else() )
b. some times when we launch threads we have a fixed launching (like 256 threads are launched) but if the input matrix/ vector is of >256 it causes stalling since only 256 threads will be used at a time.
c. tile the matrix to have only 256 threads at a time and rest are stored in a faster shared memory to improve performance
