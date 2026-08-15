# How does CVA6 load data into the L3 cache?

when CVA6 sees opcode for RVV: it marks the instruction as illegal. Simultaneously, the CVXIFEnable = 1 (meaning we are using an accelerator ie TinyGPU).   
So CVA6 sends the instruction to the accelerator. The FSM (/4_64_core/tinygpu_fsm.v) reads the instruction and sees that if the opcode matches vle64.v, update the state of the FSM to l3_write.  

<img width="830" height="125" alt="image" src="https://github.com/user-attachments/assets/1ca96a7c-7b0c-44f2-9b4b-ece0a5723c54" />  

In this, if is_vle64 = 1:  
<img width="319" height="139" alt="image" src="https://github.com/user-attachments/assets/a0c7ffa6-a524-4ce1-bd0b-98f8f55dbe56" />

then this if condition updates the FSM state to "LOAD" 
the cycle of FSM is: IDLE -> LOAD -> L3_WRITE -> WAIT_COMMIT -> COMPUTE -> IDLE again

So now it moves on to L3 write here:  
<img width="895" height="802" alt="image" src="https://github.com/user-attachments/assets/f900364d-ee76-4329-b1fa-b609cff29a7c" />  

In this LOAD is for the AXI burst/ beat. Since one 4x4 matrix is of 1024 bits and AXI is sending 256 bits we need 8 beats (1 burst) which is seen here:  

<img width="1516" height="147" alt="image" src="https://github.com/user-attachments/assets/953873f5-7978-4acd-85a4-e65ee2e44742" />

From this i can show that AXI handshake = true --->>> send data to L3 cache. (beat count 0, 1, 2, 3, 4... 7) = 1 burst of data.
