import re
import statistics
import subprocess

LOTTERY = "ext/ostep-homework/cpu-sched-lottery/lottery.py"
LENGTHS = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000]
SEEDS = range(30)


def unfairness(length, seed):
    out = subprocess.run(
        ["python3", LOTTERY, "-l", f"{length}:100,{length}:100", "-s", str(seed), "-c"],
        capture_output=True, text=True,
    ).stdout
    times = [int(t) for t in re.findall(r"DONE at time (\d+)", out)]
    return min(times) / max(times)


means = []
for r in LENGTHS:
    u = statistics.mean(unfairness(r, s) for s in SEEDS)
    means.append(u)
    stride = (2 * r - 1) / (2 * r)
    print(f"length={r:5d}  lottery mean U={u:.3f}  stride (theory) U={stride:.4f}")

try:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    plt.figure(figsize=(7, 4.5))
    plt.plot(LENGTHS, means, "o-", label="lottery (30 seeds, simulator)")
    plt.plot(LENGTHS, [(2 * r - 1) / (2 * r) for r in LENGTHS], "s--", label="stride (theory)")
    plt.xscale("log")
    plt.ylim(0, 1.05)
    plt.xlabel("job length (log scale)")
    plt.ylabel("average unfairness U")
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.savefig("hw/ch9/data/q5_fairness.png", dpi=120)
    print("saved hw/ch9/data/q5_fairness.png")
except ImportError:
    print("matplotlib is not installed, table only")