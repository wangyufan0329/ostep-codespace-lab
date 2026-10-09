# Chapter 7: CPU Scheduling - Introduction

Simulator: ext/ostep-homework/cpu-sched/scheduler.py
Written answers: analysis.md
Raw simulator output (run with -c): data/

## Summary of results / 结果概述

| Question | Workload | Result |
|---|---|---|
| Q1 | 200,200,200 | FIFO = SJF: response 200.00, turnaround 400.00 |
| Q2 | 100,200,300 | FIFO = SJF: response 133.33, turnaround 333.33 |
| Q3 | 100,200,300, RR q=1 | response 1.00, turnaround 465.67 |
| Q4 | 300,200,100 | FIFO turnaround 466.67 vs SJF 333.33 |
| Q5 | 100,200,300, RR q=200 / q=100 | response 133.33 (same as SJF) / 100.00 (differs) |
| Q6 | SJF, lengths x10 each time | response 13.33 / 133.33 / 1333.33 (linear) |
| Q7 | 100,100,100, RR q=1/10/50/100 | response 1 / 10 / 50 / 100; worst case (N-1) * q |