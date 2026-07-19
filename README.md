# TinyGPU

TinyGPU is an educational GPU project written in **Verilog HDL** that aims to explore the architectural principles behind modern GPUs.

The project focuses on building a simple **SIMD (Single Instruction, Multiple Data)** processor from the ground up, starting with the core hardware blocks that make up a Processing Element (PE). Rather than modeling a complete commercial GPU, TinyGPU is intended as a learning project that gradually develops into a functional parallel accelerator.

> **Project Status:** 🚧 Early Development

---

# Overview

Modern CPUs are optimized for sequential execution, while GPUs improve performance by executing the same instruction across many processing elements simultaneously.

TinyGPU explores this execution model by building the hardware required for a simple GPU, beginning with individual RTL modules before integrating them into a complete Processing Element.

The long-term goal is to create a small SIMD accelerator that can eventually interface with a RISC-V processor and run on an FPGA.

---

# Current Progress

The following modules have been implemented:

- Program Counter / Fetch Unit
- Instruction Decoder
- Register File
- Arithmetic Logic Unit (ALU)
- Branch Predictor

These modules are currently being integrated into a Processing Element.

---

# Planned Architecture

```
                RISC-V CPU (Planned)
                       │
                       ▼
              GPU Command Interface
                       │
                       ▼
              TinyGPU Controller
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

> **Note:** This architecture is still under development and may change.

---

# Processing Element

Each Processing Element is expected to contain the following modules:

```
            Processing Element

       ┌──────────────────────────┐
       │ Program Counter          │
       ├──────────────────────────┤
       │ Instruction Fetch        │
       ├──────────────────────────┤
       │ Instruction Decoder      │
       ├──────────────────────────┤
       │ Register File            │
       ├──────────────────────────┤
       │ Arithmetic Logic Unit    │
       ├──────────────────────────┤
       │ Load Store Unit          │
       ├──────────────────────────┤
       │ Control Logic            │
       └──────────────────────────┘
```

Some of these modules are still under development.

---

# Repository Structure

```
TinyGPU/

├── alu.v
├── decoder.v
├── fetcher.v
├── predictor.v
├── register_file.v
└── README.md
```

Additional modules will be added as development progresses.

---



---

# Technologies

- Verilog HDL

Planned:

- RISC-V
- FPGA
- Cocotb
- Vivado

---

# Future Goals

The long-term objective of TinyGPU is to become a small educational GPU that demonstrates:

- RTL Design
- Computer Architecture
- SIMD Processing
- Parallel Computing
- GPU Fundamentals
- FPGA Design
