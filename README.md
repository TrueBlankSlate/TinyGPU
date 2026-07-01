# TinyGPU - Eklavya

Your CPU handles tasks one after another, quickly but sequentially. A GPU does something fundamentally different, it runs thousands of operations at the same instant, across hundreds of small processors working in coordination. That single architectural decision is what makes real-time gaming, video rendering, and modern AI possible.

But how does something like that actually get built?

In TinyGPU, you will find out. Starting from digital logic fundamentals, you will design and implement a small but complete parallel processor, four processing units that receive the same instruction simultaneously but each operate on their own data. You will build the scheduler that decides which work runs when, handle the edge cases that arise when parallel units need to make independent decisions, and wire the whole thing into a RISC-V processor so it can be controlled by real software.

The final test is straightforward: take two standard computations, dot product and matrix-vector multiplication, run them on the CPU, then run them on what you built, and compare the cycle counts. The gap tells you exactly what you achieved.

By the end, you will have gone from writing your first hardware module to having a working accelerator running on an FPGA. More importantly, you will understand the architectural ideas that sit at the core of every GPU ever made, not because you read about them, but because you made the same design decisions yourself.
