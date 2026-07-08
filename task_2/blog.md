# Vector Architectures
___
Vector architectures grab sets of data elements scattered about memory, place them into large, sequential register files, operate on data in those register files,
and then disperse the results back into memory.  

A single instruction operates on
vectors of data, which results in dozens of register–register operations on independent data elements.  

## 1. VMIPS:   
Vector Million Instruction Per second is a vector architecture mentioned in the book.  
Vector here means a 1-Dimensional Array of FP values.  
It has 4 main parts:

* Vector Registers - stores data on fast on chip memory
* Vector Functional Units
  * FP Add / Subtract
  * FP Multiply
  * FP Divide
  * FP Load / Store
* Vector Load Store units
* Scalar registers

<img width="403" height="386" alt="image" src="https://github.com/user-attachments/assets/903acc34-0339-4ab3-9b30-a5befd6d84e5" />  
<p align="center">Image 1: VMIPS pipeline </p>  

## 2. Vector Operation  
A typical vector problem looks like <mark>Y = a*X + Y</mark>. this is called a fused multiply add (like seen in matrix multiplication).  
SAXYPY stands for single precision AX+Y. DAXPY is double precision.  

**Why use VMIPS**?  
Because it allows for less instruction size. for a normal DAXPY operation MIPS code takes nearly 600 instructions but VMIPS requires only 6.  

## 3. Vector Execution
We used some terms in vector execution:
1. Convoy: set of all instructions that can be coupled together without a hazard in between.
2. Chaining: chaining is a data-forwarding technique that allows dependent vector instructions to execute concurrently.
3. Chime: the unit of time taken to execute one convoy

**How are convoys laid out**:
Example:

LV V1,Rx ;load vector X  
MULVS.D V2,V1,F0 ;vector-scalar multiply  
LV V3,Ry ;load vector Y  
ADDVV.D V4,V2,V3 ;add two vectors  
SV V4,Ry ;store the sum  

Answer:
1) LV V1,Rx ;load vector X MULVS.D V2,V1,F0 ;vector-scalar multiply
2) LV V3,Ry ;load vector Y  ADDVV.D V4,V2,V3 ;add two vectors
3) SV V4,Ry ;store the sum

Therefore there are 3 convoys. The chime = number of convoys * size of the vector + some overhead (which I am not discussing)  
there for Chime = 3*n ===> where n could be size of the vector.  

## 4. How to handle unkown vector size?
If we have a vector that is of size 'n' and the maximum vector size possible (ie the length of all the registers we have) is MVL.  
Then we use something called strip mining or tiling.  

### Case 1: vector length (n) < MVL
Normal case. We create a vector length register and completely run the instruction on all elements in usual Y = AX+Y format.

### Case 2: vector length (n) > MVL
In this case n-MVL elements will not fit in the register. To correct this we tile the vector into multiple of MVL + remainder.  
which means n = (n/MVL) * MWL + n%MVL. We make a loop that loops (n/MVL) times and and an extra n%MVL times to fit the whole vector.  
<img width="917" height="270" alt="image" src="https://github.com/user-attachments/assets/996102a5-b47e-4da7-92b7-03f249b36540" />
<p align="center">Image 2: Strip Mining or Tiling in SAXPY </p>  

___
# SIMD Instruction Set Extension for Multimedia
They started with the simple observation that many of the operations needed to be performed were smaller than 64-bit. Unlike vector machines that can store as many 64 bit elements in each of 8 vector registers, SIMD instructions tend to specify fewer operands and hence use much smaller register files.  

## A) Weakness of SIMD compared to Vector Architecture
1. Multimedia SIMD extensions fix the number of data operands in the opcode, which has led to the addition of hundreds of instruction. <mark> More instruction = More time taken. </mark>
2. Multimedia SIMD does not offer the more sophisticated addressing modes of vector architectures, namely <mark> strided accesses and gather-scatter accesses. </mark>
3. Multimedia SIMD usually does not offer the mask registers to support conditional execution of elements as in vector architectures.

## B) But SIMD is still popular. Why?
1. Because they are easier to implement than Vector Architecture
2. They require little extra state compared to vector architectures, which is always a concern for context switch times
3. Vector architecture needs more memory bandwidth than SIMD which most computers or FPGA might not have.
4. SIMD does not have to deal with problems in virtual memory when a single instruction that can generate 64 memory accesses can get a page fault in the middle of the vector.

## Which architecture should be used for TinyGPU?
SIMD is the better choice because it is easier to build, can run faster on constrained hardware. Also if we use SIMD we will replicate the core of an actual GPU and because the only major task for it to solve is matrix multiplication we do not need a heavy vector architecture. Also the above 4 advantages highlight that SIMD is more popularly used and is easier to scale than vector architecture.
___

## Roofline Visual Model
Roofline model ties together floating point performance, arithmetic performance and memory performance in a 2 Dimensional plot.  
Arithmetic Intensity is the ratio of floating-point operations per byte of memory accessed.  It can be calculated by taking the total number of floating-point operations for a program divided by the total number of data bytes transferred to main memory during program execution.  

<img width="489" height="408" alt="image" src="https://github.com/user-attachments/assets/545bde04-2132-498f-a495-e2f795c63a0d" />
<p align="center"> Image 3: Arithmetic Itensity with regions </p>
___

# GPUs 
## 1. NVIDIA CUDA C/C++
This is a language designed by Nvidia with a C or C++ like syntax to access the capabilities of the GPU.  CUDA is the bridge between the CPU (host) and the GPU (device)  
* for the GPU code: __ device__ or __ global__ is used.
* for the CPU code: normal C++ functions like syntax.

### CUDA Hardware layout:

<img width="412" height="338" alt="image" src="https://github.com/user-attachments/assets/3e46a024-0b05-473b-99cd-fcfb60fc33de" />
<p align="center">Image 4: CUDA model , Source: Modal GPU Glossary</p>  

### Compute Capabilty:
in CUDA the lowest unit of compute is called a thread. a group of threads arranged together is called a block. A block can have a maximum of 1024 threads. When calling a kernel (GPU code) we arrange blocks in the GPU and this term if called grids.  
Maximum blocks in a grid is around 2^16. CUDA uses special datatype called dim3 which allows you to order blocks according to (x,y,z) format.  

### Analogy between CUDA and SIMD
<img width="1492" height="525" alt="image" src="https://github.com/user-attachments/assets/1163b840-6ed8-4d79-b31c-0550d2716b8d" />
<img width="1511" height="505" alt="image" src="https://github.com/user-attachments/assets/57bd6c3a-b2ae-4e85-94db-982a54e06b0e" />
<img width="1495" height="380" alt="image" src="https://github.com/user-attachments/assets/51a05ad3-68ee-4111-9822-ba1b85796e50" />
<p align="center"> Image 5: Software level Abstraction </p> 
<img width="509" height="602" alt="image" src="https://github.com/user-attachments/assets/04799296-ef62-4966-9015-7c6b8681b5b5" />
<p align="center"> Image 6: CUDA Hierarchy </p> 

### CUDA Memory Hierarchy

Since each thread does some computational work and we like to reuse data in high speed memory, CUDA introduces various levels of memory which is faster as close it is to each thread thus allowing for very fast parallel processing.  

<img width="763" height="402" alt="image" src="https://github.com/user-attachments/assets/6ecf48a7-d0f0-46ab-ba0d-40855523066e" />
<p align="center"> Image 7: CUDA memory hierarchy</p>

In this, RMEM is the register memory so it is fastest.  
L1 cache is accessible by all threads in an SM (called __ shared__ in CUDA syntax)
L2 is slower and accessible by all blocks and SM (cant directly call)
and VRAM is the slowest but largest capacity memory there is.  

