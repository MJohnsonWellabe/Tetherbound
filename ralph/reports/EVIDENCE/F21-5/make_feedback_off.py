#!/usr/bin/env python3
"""F21#5 'before' variant (disclosed, same-commit pair): neutralise impact.feedback
in data/config/combat.json of a SCRATCH worktree only. Usage:
  python3 -I make_feedback_off.py <worktree root>
Weights (hitstop/knockback/recoil) -> 0, shake_scale -> 0, critical hitstop -> 0,
rumble -> 0, damage numbers off, class flashes -> the ordinary flash."""
import json, sys, pathlib
path = pathlib.Path(sys.argv[1]) / "data/config/combat.json"
d = json.loads(path.read_text())
fb = d["impact"]["feedback"]
for w in fb["weights"].values():
    for k in list(w):
        if not k.startswith("_") and isinstance(w[k], (int, float)): w[k] = 0
for k in fb["shake_scale"]: fb["shake_scale"][k] = 0
for r in fb.get("rumble", {}).values():
    for k in r: r[k] = 0
fb["critical_hitstop_seconds"] = 0
fb["numbers"]["enabled"] = False
ordinary = fb["flashes"]["ordinary"]
for k in list(fb["flashes"]):
    if k != "ordinary": fb["flashes"][k] = dict(ordinary)
path.write_text(json.dumps(d, indent=2) + "\n")
print("feedback neutralised in", path)
