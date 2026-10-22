#!/usr/bin/env python3
"""Pool the raw iteration values of several measure.sh runs: median, min, max per metric.
usage: pool.py <log> [<log> ...]"""
import re, sys, statistics as s, collections
vals = collections.defaultdict(list)
for path in sys.argv[1:]:
    for line in open(path):
        m = re.search(r"Test Case '-\[\S+\.\w+ (\w+)\]' measured \[(.+?)\].*?values: \[(.*?)\]", line)
        if m: vals[(m.group(1), re.sub(r" \(\w+\)", "", m.group(2)))] += [float(v) for v in m.group(3).split(",")]
for (t, metric), v in sorted(vals.items()):
    if "Instructions" in metric or "AppLaunch" in metric or "Clock" in metric or "CPU Time" in metric or "Peak" in metric:
        print(f"{t} | {metric} | n={len(v)} | median {s.median(v):.3f} | min {min(v):.3f} | max {max(v):.3f}")
