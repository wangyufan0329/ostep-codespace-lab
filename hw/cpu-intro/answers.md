## Q1
- Prediction / 预测: Total Time 10, CPU Busy 10 (100%), IO Busy 0 (0%) / 总时间10，CPU利用率100%，I/O利用率0%
- Reasoning / 理由: Both processes only use the CPU (5:100,5:100) with no I/O, so the CPU never goes idle. PID 0 runs its 5 instructions first, then PID 1 runs its 5, for 10 ticks total. / 两个进程都是纯CPU指令(5:100,5:100)，没有I/O操作，所以CPU从头到尾不会空闲。PID 0先跑完5条指令，再轮到PID 1跑5条，共10个tick。
- Verified result / 验证结果:
- Analysis / 分析:

## Q2
- Prediction / 预测: Total Time 11, CPU Busy 6 (54.55%), IO Busy 5 (45.45%) / 总时间11，CPU利用率54.55%，I/O利用率45.45%
- Reasoning / 理由: PID 0 runs its 4 CPU instructions first (ticks 1-4) since it has no I/O to trigger a switch. Then PID 1 starts its I/O: 1 tick to issue it (RUN:io), 5 ticks BLOCKED while the device works, 1 tick to handle completion (RUN:io_done). Since PID 0 already finished, the CPU sits idle during the 5 BLOCKED ticks. / PID 0没有I/O触发切换，所以先连续跑完4条CPU指令(tick1-4)。然后PID 1开始I/O：1个tick发起(RUN:io)，5个tick设备工作期间BLOCKED，1个tick处理完成(RUN:io_done)。由于PID 0已经跑完，BLOCKED的5个tick期间CPU处于空闲状态。
- Verified result / 验证结果:
- Analysis / 分析:

## Q3
- Prediction / 预测: Total Time 7, CPU Busy 6 (85.71%), IO Busy 5 (71.43%) / 总时间7，CPU利用率85.71%，I/O利用率71.43%
- Reasoning / 理由: PID 0 issues I/O first (tick 1), then switches to PID 1 (default SWITCH_ON_IO) during the 5-tick BLOCKED period (ticks 2-6). PID 1's 4 CPU instructions fit into ticks 2-5, leaving tick 6 idle since PID 0's I/O hasn't finished yet. PID 0 handles completion at tick 7. Unlike Q2, the CPU is idle for only 1 tick instead of 5, because PID 1 can fill most of the I/O wait time. / PID 0先发起I/O(tick1)，然后因为默认SWITCH_ON_IO立刻切给PID1，在PID0的5个tick BLOCKED期间(tick2-6)运行。PID1的4条CPU指令刚好占满tick2-5，tick6因为PID0的I/O还没完成而空闲。PID0在tick7处理完成。和Q2不同，这里CPU只空闲1个tick而不是5个，因为PID1能填满大部分I/O等待时间。
- Verified result / 验证结果:
- Analysis / 分析:

## Q4
- Prediction / 预测: Total Time 11, CPU Busy 6 (54.55%), IO Busy 5 (45.45%) / 总时间11，CPU利用率54.55%，I/O利用率45.45%
- Reasoning / 理由: With SWITCH_ON_END, the CPU never switches to another process until the current one is fully DONE, even during I/O wait. So while PID 0 is BLOCKED for 5 ticks (ticks 2-6), the CPU sits idle since PID 1 isn't allowed to run yet. Only after PID 0 finishes at tick 7 does PID 1 get to run its 4 instructions (ticks 8-11). / 在SWITCH_ON_END下，即使在I/O等待期间，CPU也不会切换给其他进程，直到当前进程彻底DONE。所以PID 0在BLOCKED的5个tick(tick2-6)里，CPU处于空闲状态，因为PID1还不被允许运行。只有当PID0在tick7结束后，PID1才能开始跑它的4条指令(tick8-11)。
- Verified result / 验证结果:
- Analysis / 分析:

## Q5
- Prediction / 预测: Total Time 7, CPU Busy 6 (85.71%), IO Busy 5 (71.43%) / 总时间7，CPU利用率85.71%，I/O利用率71.43%
- Reasoning / 理由: This is the same process setup as Q3 (1:0,4:100) but with SWITCH_ON_IO explicitly set, which is also the default. So the result should match Q3 exactly: PID 0 issues I/O and immediately switches to PID 1, which fills most of the wait time, leaving only 1 idle tick instead of the 4 wasted in Q4. / 这和Q3的进程设置完全相同(1:0,4:100)，只是显式指定了SWITCH_ON_IO（这也是默认值）。所以结果应该和Q3完全一致：PID0发起I/O后立刻切换给PID1，PID1填满了大部分等待时间，只剩1个tick空闲，而不是Q4里浪费的4个tick。
- Verified result / 验证结果:
- Analysis / 分析:

## Q6
- Prediction / 预测: Since -I IO_RUN_LATER means a process that just finished an I/O goes to the back of the ready queue instead of running immediately, PID 0 will likely get delayed behind the CPU-bound processes after each I/O completes, finishing last despite having the fewest instructions. / 由于-I IO_RUN_LATER意味着刚完成I/O的进程会排到就绪队列末尾而不是立刻运行，PID0在每次I/O完成后很可能会被排在纯CPU进程后面，尽管它指令数最少，却会最后结束。
- Reasoning / 理由: PID 0 issues an I/O, switches away (SWITCH_ON_IO), and while it's BLOCKED, the other processes use the CPU. Because of IO_RUN_LATER, once PID 0's I/O finishes, it doesn't jump the queue — it waits behind whichever CPU-bound process is currently running or next in line. This repeats for each of PID 0's 3 I/O instructions, pushing PID 0's completion further back each time. / PID0发起I/O后切换走(SWITCH_ON_IO)，在它BLOCKED期间，其他进程使用CPU。由于IO_RUN_LATER，PID0的I/O一旦完成，并不会插队，而是要排在当前运行或排队中的CPU进程后面。PID0的3次I/O每次都会重复这个过程，使PID0的结束时间一再推迟。
- Verified result / 验证结果:
- Analysis / 分析:

## Q7
- Prediction / 预测: With IO_RUN_IMMEDIATE, PID 0 can issue its next I/O right after the previous one finishes, without waiting behind the other CPU-bound processes. This should keep the I/O device constantly busy and shrink the total time compared to Q6. / 使用IO_RUN_IMMEDIATE，PID0在上一次I/O完成后可以立刻发起下一次I/O，不用排在其他CPU进程后面等待。这应该能让I/O设备持续忙碌，相比Q6缩短总时间。
- Reasoning / 理由: Unlike IO_RUN_LATER (Q6), where PID 0 goes to the back of the ready queue after each I/O, IO_RUN_IMMEDIATE lets PID 0 jump straight back onto the CPU to issue its next I/O as soon as the current one completes. This keeps PID 0's three I/O calls close together instead of spread out, and the I/O device stays busy sooner. / 与IO_RUN_LATER（Q6）不同——PID0每次I/O后都要排到就绪队列末尾——IO_RUN_IMMEDIATE让PID0在当前I/O一完成就能立刻抢回CPU、发起下一次I/O。这让PID0的三次I/O调用更紧凑，而不是分散开，I/O设备也能更早、更持续地忙碌起来。
- Verified result / 验证结果:
- Analysis / 分析:

## Q8
- Prediction / 预测: Since the process instructions are randomly determined by the seed, the exact outcome is hard to predict precisely beforehand, but SWITCH_ON_END should generally perform worse than the default/IO_RUN_IMMEDIATE, since it can never overlap I/O wait with other work. / 由于进程的具体指令是由种子随机决定的，事先很难精确预测确切结果，但SWITCH_ON_END通常应该表现得比default/IO_RUN_IMMEDIATE更差，因为它永远无法让I/O等待和其他工作重叠。
- Reasoning / 理由: With seed 1, PID 0's 3 instructions turned out to be CPU, I/O, I/O, while PID 1's turned out to be 3 CPU instructions. Under default/IO_RUN_IMMEDIATE, PID 1 can run during PID 0's first I/O wait, but PID 1 finishes (tick 6) before PID 0's I/O completes (tick 8), so there's no process left to compete for the CPU when PID 0's I/O finishes — meaning IO_RUN_LATER vs IO_RUN_IMMEDIATE makes no difference here. Under SWITCH_ON_END, PID 1 isn't allowed to run until PID 0 is fully DONE, wasting the overlap opportunity entirely. / 在种子1下，PID0的3条指令实际是CPU、I/O、I/O，PID1的3条则都是CPU指令。在default/IO_RUN_IMMEDIATE下，PID1可以在PID0的第一次I/O等待期间运行，但PID1在tick6就结束了，早于PID0在tick8完成的I/O，所以PID0的I/O完成时已经没有进程跟它竞争CPU——这意味着IO_RUN_LATER和IO_RUN_IMMEDIATE在这个场景下没有区别。而在SWITCH_ON_END下，PID1直到PID0完全DONE才被允许运行，完全浪费了本可重叠的机会。
- Verified result / 验证结果:
- Analysis / 分析:

