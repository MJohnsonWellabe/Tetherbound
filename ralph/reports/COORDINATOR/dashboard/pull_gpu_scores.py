#!/usr/bin/env python3
"""Collect GPU High mapped scores from LANE-SCOUT's GPU-PASS reports into status.json.

Reads ralph/reports/GPU-PASS/1108/{A,B,F-*}.md from the scout branch (git show) and
stores {row: {"gpu": score, "src": file}} under status.json "gpu_scores". The board
uses these over older GPU and CPU figures. Usage: pull_gpu_scores.py <git-ref>
"""
import json, re, subprocess, sys
from pathlib import Path
HERE = Path(__file__).parent
ref = sys.argv[1] if len(sys.argv) > 1 else "origin/tb/item-scout-1108"
names = subprocess.run(["git", "ls-tree", "--name-only", f"{ref}:ralph/reports/GPU-PASS/1108/"],
                       capture_output=True, text=True).stdout.split()
rows = {}
for n in names:
    if not re.match(r"^(A|B|F-[a-z]+)\.md$", n):
        continue
    txt = subprocess.run(["git", "show", f"{ref}:ralph/reports/GPU-PASS/1108/{n}"], capture_output=True, text=True).stdout
    for m in re.finditer(r"^\|\s*(F\d+#\d+)\s*\|\s*\*\*(\d+\.\d+)\*\*", txt, re.M):
        rows[m.group(1)] = {"gpu": float(m.group(2)), "src": f"GPU High 8-9 Nov ({n[:-3]})"}
p = HERE / "status.json"
d = json.loads(p.read_text(encoding="utf-8"))
d["gpu_scores"] = dict(sorted(rows.items()))
p.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(len(rows), "GPU rows")
