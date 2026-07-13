# TinyGPU

## Overview

Modern CPUs execute instructions at very high speeds, but they are fundamentally optimized for sequential execution. GPUs take a different approach by executing the same instruction across many processing elements simultaneously, allowing them to accelerate workloads such as graphics rendering, scientific computing, and machine learning.

TinyGPU is an educational hardware project that introduces the core architectural concepts behind modern GPUs through the design of a simple parallel processor. Starting from basic digital logic, the project gradually builds a functional SIMD (Single Instruction, Multiple Data) accelerator that integrates with a RISC-V processor and runs on an FPGA.

Rather than simulating GPU concepts, TinyGPU implements them directly in hardware, providing hands-on experience with the design decisions that underpin real-world GPU architectures.

---

## Objectives

By completing this project, you will:

- Learn the fundamentals of digital hardware design using Verilog.
- Build a simple GPU execution model based on SIMD principles.
- Design multiple parallel Processing Elements (PEs).
- Develop a scheduler that distributes work across processing elements.
- Handle control-flow divergence between parallel execution units.
- Integrate the accelerator with a RISC-V processor.
- Deploy and verify the design on an FPGA.
- Measure and analyze performance improvements over CPU execution.

---

## Architecture

TinyGPU consists of four primary components:

```
                RISC-V CPU
                     │
                     │
             GPU Command Interface
                     │
                     ▼
            +--------------------+
            | TinyGPU Controller |
            +--------------------+
                     │
        Broadcast Instruction
                     │
      ┌────────┬────────┬────────┬────────┐
      ▼        ▼        ▼        ▼
     PE0      PE1      PE2      PE3
      │        │        │        │
      └────────┴────────┴────────┴────────┘
                     │
               Shared Memory
```

Each Processing Element receives the same instruction while operating on different data, implementing the SIMD execution model used by modern GPUs.

---

## Features

- Four parallel Processing Elements
- SIMD instruction execution
- Hardware scheduler for workload distribution
- Shared memory interface
- Support for branch divergence handling
- RISC-V processor integration
- FPGA implementation
- Performance benchmarking

---

## Project Workflow

The project is divided into several stages:

### 1. Digital Logic Fundamentals

Develop the essential hardware building blocks:

- Registers
- Multiplexers
- Decoders
- ALU
- Counters
- Finite State Machines
- Memory modules

---

### 2. Processing Element Design

Each Processing Element includes:

- Instruction Decoder
- Arithmetic Logic Unit (ALU)
- Register File
- Memory Interface
- Control Logic

---

### 3. SIMD Execution

Implement a Single Instruction, Multiple Data architecture where one instruction is broadcast to all Processing Elements while each processes independent data.

Example:

```
Instruction: ADD

PE0 → A0 + B0
PE1 → A1 + B1
PE2 → A2 + B2
PE3 → A3 + B3
```

---

### 4. Work Scheduler

Design a scheduler responsible for:

- Distributing workloads
- Managing execution order
- Coordinating Processing Elements
- Preventing idle hardware

---

### 5. Branch Divergence

Implement logic to manage situations where Processing Elements follow different execution paths.

Example:

```
if (x > 5)
    ADD
else
    SUB
```

Different Processing Elements may execute different branches, requiring masking or serialized execution.

---

### 6. CPU Integration

Connect TinyGPU to a RISC-V processor so that software can:

- Launch GPU kernels
- Transfer data
- Wait for execution completion
- Read computation results

---

### 7. FPGA Deployment

Synthesize the Verilog design and deploy it to an FPGA to validate the hardware in a real execution environment.

---

## Benchmark Applications

TinyGPU is evaluated using common parallel workloads such as:

- Dot Product
- Matrix-Vector Multiplication

Performance is compared against equivalent CPU implementations by measuring execution cycles and overall speedup.

---

## Learning Outcomes

This project provides practical experience with:

- Verilog HDL
- RTL Design
- Computer Architecture
- SIMD Processing
- GPU Fundamentals
- Parallel Computing
- RISC-V Integration
- FPGA Design Flow
- Hardware Verification
- Performance Analysis

---

## Technologies

- Verilog HDL
- RISC-V ISA
- FPGA Development Tools
- Simulation & Verification Environment

---



---

## Goal

TinyGPU is designed to bridge the gap between introductory digital design and modern parallel computer architecture. By the end of the project, you will have implemented a complete hardware accelerator, deployed it on an FPGA, and gained a practical understanding of the architectural principles used in contemporary GPUs.
