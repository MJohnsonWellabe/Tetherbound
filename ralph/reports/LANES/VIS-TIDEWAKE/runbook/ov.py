#!/usr/bin/env python3
"""apply <overlay.json> | revert -- RFC7386 merge patch over data/config files; revert = git checkout."""
import json, sys, subprocess
ROOT = "/home/user/Tetherbound"; STATE = "/dev/shm/run/ov_applied.json"
def merge(a, b):
    if not isinstance(b, dict): return b
    a = dict(a) if isinstance(a, dict) else {}
    for k, v in b.items():
        if v is None: a.pop(k, None)
        else: a[k] = merge(a.get(k), v)
    return a
if sys.argv[1] == "apply":
    ov = json.load(open(sys.argv[2])); json.dump(list(ov), open(STATE, "w"))
    for f, patch in ov.items():
        p = f"{ROOT}/{f}"; merged = merge(json.load(open(p)), patch)
        open(p, "w").write(json.dumps(merged, indent=2) + "\n")
else:
    subprocess.run(["git", "checkout", "--"] + json.load(open(STATE)), cwd=ROOT, check=True)
