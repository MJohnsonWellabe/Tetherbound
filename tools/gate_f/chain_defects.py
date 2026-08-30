#!/usr/bin/env python3
"""Pull every FAILed step out of a chained run's notes/ and group them.

`notes/<segment>.md` is the only artefact that carries a step's TITLE beside its
verdict -- events.jsonl has the expected/actual pair but not the human name, and
INVENTORY.json has only counts. Ranking defects by player impact needs the
title, so this reads the notes.

    tools/gate_f/chain_defects.py <run-dir> [--all]

Default output groups identical failure shapes so a fight that fails the same
assertion nine times is one line with a count, not nine lines.
"""

import os
import re
import sys
from collections import defaultdict

CHAIN = ["S01", "S02", "S03", "S04", "S05", "S06", "S07", "S08", "S09",
         "S10a", "S10b", "S10c", "S10d", "S10e"]

STEP = re.compile(r"^### (\S+) — (.*)$")


def parse(path):
    """-> [{id, title, expected, actual, verdict, t}]"""
    out, cur = [], None
    if not os.path.exists(path):
        return out
    for line in open(path, encoding="utf-8", errors="replace"):
        line = line.rstrip("\n")
        m = STEP.match(line)
        if m:
            if cur:
                out.append(cur)
            cur = {"id": m.group(1), "title": m.group(2), "expected": "",
                   "actual": "", "verdict": "", "t": ""}
            continue
        if cur is None:
            continue
        for key in ("expected", "actual", "verdict", "events"):
            pre = "- %s: " % key
            if line.startswith(pre):
                cur["t" if key == "events" else key] = line[len(pre):]
    if cur:
        out.append(cur)
    return out


def shape(actual):
    """Collapse a failure message to its reusable shape.

    Numbers, coordinates and entity ids differ between two occurrences of the
    same defect; the words around them do not. Without this the same missing
    objective reported at nine anchors reads as nine defects.
    """
    s = re.sub(r"-?\d+\.\d+", "#", actual)
    s = re.sub(r"\b\d+\b", "#", s)
    s = re.sub(r"\(.*?\)", "(...)", s)
    return s[:150]


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: chain_defects.py <run-dir> [--all]")
    run_dir = sys.argv[1]
    show_all = "--all" in sys.argv

    groups = defaultdict(list)
    order = []
    total_fail = 0
    for seg in CHAIN:
        steps = parse(os.path.join(run_dir, seg, "notes", "%s.md" % seg))
        for s in steps:
            if s["verdict"] not in ("FAIL", "SKIP") and not show_all:
                continue
            if s["verdict"] == "FAIL":
                total_fail += 1
            key = (seg, s["verdict"], shape(s["actual"]))
            if key not in groups:
                order.append(key)
            groups[key].append(s)

    print("# failures — %s" % run_dir)
    print()
    print("%d failing steps in %d distinct shapes." % (total_fail, len(order)))
    print()
    for key in order:
        seg, verdict, sh = key
        hits = groups[key]
        print("## %s · %s · x%d" % (seg, verdict, len(hits)))
        print("- steps: %s" % ", ".join(h["id"] for h in hits[:8])
              + (" …" if len(hits) > 8 else ""))
        print("- first: **%s**" % hits[0]["title"])
        print("- expected: %s" % hits[0]["expected"][:400])
        print("- actual: %s" % hits[0]["actual"][:500])
        print()


if __name__ == "__main__":
    main()
