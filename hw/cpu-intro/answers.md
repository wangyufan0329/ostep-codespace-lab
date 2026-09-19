# CPU-Intro Homework - Q3

## Q3: swap the order to -l 4:100,1:0. Does order matter? Why?

### Original order: -l 1:0,4:100
- Total Time: 7
- CPU Busy: 6 (85.71%)
- IO Busy: 5 (71.43%)

### Swapped order: -l 4:100,1:0
- Total Time: 11
- CPU Busy: 6 (54.55%)
- IO Busy: 5 (45.45%)

### Answer
Yes, order matters. The scheduler always dispatches the first-listed process (PID 0) 
to run first. In the original order, the short CPU-only process (1:0) runs first and 
quickly yields the CPU, allowing the I/O-heavy process to run efficiently, finishing 
in 7 time units with 85.71% CPU utilization.

When swapped, the I/O-heavy process (4:100) runs first, repeatedly blocking on I/O 
while the CPU sits idle waiting. This delays the short process and drags the total 
runtime out to 11 time units, dropping CPU utilization to 54.55%. Putting the 
I/O-intensive process first wastes more CPU idle time.
