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

## 5. Handling if-statements (branch conditions) using Vector Masking

