#!/usr/bin/env python3
"""Median / min / max of each pattern across the runs in a profile.sh .counts.txt file."""
import sys, collections, statistics as s
vals = collections.defaultdict(list)
for line in open(sys.argv[1]):
    if "\t" in line:
        k, v = line.rstrip().split("\t"); vals[k].append(int(v))
    elif line.startswith("main_samples"):
        vals["main_samples"].append(int(line.split()[1]))
for k, v in vals.items():
    if k != "main_samples" and max(v) == 0: continue
    print(f"{k}: runs={len(v)} median={s.median(v)} min={min(v)} max={max(v)}")
