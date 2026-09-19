#!/usr/bin/env python3
"""Roster diff across a chained run — A2, A8 and section 5's "team progression".

Each segment's exit save is the chapter's state at that point, so reading the
`party` array out of every one of them gives the roster's whole history: who
joined, who was replaced, what levels they reached, and how much of the five the
player was actually carrying at each band.

    tools/gate_f/chain_party.py <run-dir>
"""

import glob
import json
import os
import sys
from chain_evidence import executions, safe_id, SEMANTICS

CHAIN = ["S01", "S02", "S03", "S04", "S05", "S06", "S07", "S08", "S09",
         "S10a", "S10b", "S10c", "S10d", "S10e"]


def load(run_dir, seg, output_save=None):
    if output_save:
        safe_id(output_save)
    hits = ([os.path.join(run_dir, seg, "saves", output_save)] if output_save else
            glob.glob(os.path.join(run_dir, seg, "saves", "*-exit.json")))
    if len(hits) != 1:
        return None
    try:
        with open(hits[0], encoding="utf-8") as handle:
            return json.load(handle)
    except (ValueError, OSError):
        return None


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: chain_party.py <run-dir>")
    run_dir = sys.argv[1]

    print("# roster history —", run_dir)
    print()
    print(SEMANTICS)
    print("Rows show exported save snapshots, including incomplete executions; existence is not a PASS verdict.")
    print()
    print("| after | size | day | roster (nickname species L·hp/max · bond) | flags |")
    print("|---|---|---|---|---|")
    seen = {}
    for entry in executions(run_dir):
        seg = entry["id"]
        save = load(run_dir, seg, entry["phase"].get("output_save"))
        if save is None:
            print("| %s | — | — | _no exit save_ | — |" % seg)
            continue
        party = save.get("party") or []
        prog = save.get("progression") or {}
        flags = prog.get("flags") if isinstance(prog, dict) else None
        nflags = len(flags) if isinstance(flags, (list, dict)) else "?"
        cells = []
        for c in party:
            tag = "%s(%s) L%s %.0f/%.0f b%s%s" % (
                c.get("nickname") or c.get("display_name"), c.get("species_id"),
                c.get("level"), c.get("hp", 0), c.get("max_hp", 0),
                c.get("bond"), " **FAINTED**" if c.get("fainted") else "")
            cells.append(tag)
            seen.setdefault(c.get("nickname") or c.get("species_id"), seg)
        print("| %s | %d/5 | %s | %s | %s |" % (
            seg, len(party), save.get("day", "?"),
            "<br>".join(cells) or "_empty_", nflags))

    print()
    print("## when each creature joined")
    for who, seg in seen.items():
        print("- **%s** — first present in %s's exit save" % (who, seg))


if __name__ == "__main__":
    main()
