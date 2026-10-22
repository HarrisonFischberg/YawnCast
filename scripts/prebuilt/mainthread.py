#!/usr/bin/env python3
"""Count main-thread Time Profiler samples (1 sample = 1 ms) whose stack contains a frame
matching each regex. Inclusive: a sample counts once per regex however deep the frame is.
usage: mainthread.py <exported time-profile xml> <regex> [<regex> ...]"""
import re, sys
import xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
ids = {el.get("id"): el for el in root.iter() if el.get("id")}
R = lambda el: ids[el.get("ref")] if el.get("ref") is not None else el
pats = [re.compile(p) for p in sys.argv[2:]]
counts = [0] * len(pats); total = 0
for row in root.findall(".//row"):
    th = bt = None
    for c in row:
        c2 = R(c)
        if c2.tag == "thread": th = c2.get("fmt")
        elif c2.tag in ("backtrace", "tagged-backtrace"): bt = c2
    if not th or "Main Thread" not in th or bt is None: continue
    total += 1
    names = [(R(f).get("name") or "") for f in bt.findall("frame")]
    for i, p in enumerate(pats):
        if any(p.search(n) for n in names): counts[i] += 1
print("main_samples", total)
for p, c in zip(sys.argv[2:], counts): print(f"{p}\t{c}")
