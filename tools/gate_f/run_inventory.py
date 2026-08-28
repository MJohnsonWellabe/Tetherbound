#!/usr/bin/env python3
"""Gate F run-level inventory: does every prescribed frame the run PLANNED
exist somewhere in the run directory?

    tools/gate_f/run_inventory.py ralph/reports/gate-f-run-<stamp>

Why this exists, and why it is a level above `INVENTORY.json`
-------------------------------------------------------------
CD-2 made the per-segment inventory a harness step rather than an operator
promise: a capture is "completed" only when its file exists on disk, read off
disk, not copied from the manifest row. That is the right check and it is asked
at the right place -- the segment that wrote the file.

The evidence split (owner decision, 2026-08-27) moves one thing out of a
segment's reach. A logic-lane segment runs the journey headless for mechanics,
telemetry and step verdicts, and hands its prescribed frames to a named capture
lane. The logic lane is complete when it has done what its lane owes; it is not
"capture-incomplete forever" for a frame it never undertook to take. But the
frame is still owed -- by the RUN.

So the debt is transferred and recorded, never erased, and this is what checks
it was paid. It is the FAIL-vs-SKIP distinction round 1 drew, one level up:

  * a capture a lane OWED and did not take is a FAIL, at the segment
    (`INVENTORY.json`, unchanged);
  * a capture a lane HANDED OVER is a DELEGATION, and a delegation nobody paid
    is a run-level deficiency, here.

What it reads
-------------
Only artefacts, never claims:

  <run>/<segment>/INVENTORY.json   -- planned/present/absent, delegated, owes
  <run>/<segment>/shots/*.png      -- checked on disk, by size

A frame counted as present must exist AND be non-empty AND its segment's own
inventory must agree it exists. A manifest that names a file which is not there
is exactly the claim CD-2 found, and this does not repeat it in aggregate.

Exit status is 0 only when every planned id was taken somewhere and every
delegation was honoured. Anything else exits 1 and writes RUN_INCOMPLETE.md.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys


def _read_json(path: str) -> dict:
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, ValueError):
        return {}


def _git_ignored(paths: list[str]) -> dict[str, str]:
    """Which of these files will git refuse to carry, and under which rule.

    Asked of `git check-ignore` for the same reason the harness does: every
    subtlety that made CD-2 possible -- a bare directory pattern matching at any
    depth, negations, precedence between .gitignore files -- lives in that
    command, and a second implementation of it here would be a second set of
    answers. A git that cannot answer is reported as unknown, never as clean.
    """
    if not paths:
        return {}
    try:
        done = subprocess.run(
            ["git", "check-ignore", "-v", *paths],
            capture_output=True, text=True, check=False)
    except OSError:
        return {}
    if done.returncode not in (0, 1):
        return {}
    out: dict[str, str] = {}
    for line in done.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) == 2:
            out[parts[1]] = parts[0]
    return out


def collect(run_dir: str) -> dict:
    segments: dict[str, dict] = {}
    for name in sorted(os.listdir(run_dir)):
        seg_dir = os.path.join(run_dir, name)
        inv_path = os.path.join(seg_dir, "INVENTORY.json")
        if not os.path.isfile(inv_path):
            continue
        segments[name] = _read_json(inv_path)

    # Who took what, on disk.
    taken: dict[str, dict] = {}
    for seg, inv in segments.items():
        for row in (inv.get("captures", {}) or {}).get("rows", []) or []:
            shot_id = str(row.get("id", ""))
            if not shot_id or not row.get("exists"):
                continue
            rel = str(row.get("file", ""))
            abs_path = os.path.join(run_dir, seg, rel) if rel else ""
            size = os.path.getsize(abs_path) if abs_path and os.path.isfile(abs_path) else 0
            if size <= 0:
                # The inventory said it exists and it does not. Not counted as
                # taken; reported below as a contradiction, which is worse than
                # a plain absence and must not be quieter than one.
                taken.setdefault(shot_id, {"segments": [], "contradicted_by": []})
                taken[shot_id]["contradicted_by"].append(f"{seg}:{rel}")
                continue
            entry = taken.setdefault(shot_id, {"segments": [], "contradicted_by": []})
            entry["segments"].append({"segment": seg, "file": os.path.join(seg, rel),
                                      "bytes": size})

    # Who owes what.
    owed: dict[str, dict] = {}
    for seg, inv in segments.items():
        caps = inv.get("captures", {}) or {}
        lane = str(inv.get("evidence_lane", "both"))
        for shot_id in [str(r.get("id", "")) for r in caps.get("rows", []) or []]:
            if shot_id:
                owed.setdefault(shot_id, {"owed_by": [], "delegated_by": []})
                owed[shot_id]["owed_by"].append(seg)
        for shot_id in caps.get("delegated", []) or []:
            shot_id = str(shot_id)
            owed.setdefault(shot_id, {"owed_by": [], "delegated_by": []})
            owed[shot_id]["delegated_by"].append(
                {"segment": seg, "to": str(caps.get("delegated_to", "")), "lane": lane})

    rows = []
    for shot_id in sorted(owed):
        entry = owed[shot_id]
        got = taken.get(shot_id, {"segments": [], "contradicted_by": []})
        rows.append({
            "id": shot_id,
            "owed_by": entry["owed_by"],
            "delegated_by": entry["delegated_by"],
            "taken_by": got["segments"],
            "contradicted_by": got["contradicted_by"],
            "present": bool(got["segments"]),
        })

    # A delegation whose target segment never ran at all is the case this whole
    # file exists to make visible: the logic lane is complete, the frame is
    # nowhere, and no per-segment artefact says so.
    unpaid = []
    for row in rows:
        if row["present"] or not row["delegated_by"]:
            continue
        for d in row["delegated_by"]:
            target = d["to"]
            unpaid.append({
                "id": row["id"], "delegated_by": d["segment"], "to": target,
                "target_ran": target in segments,
            })

    # And the CD-2 half: evidence that exists and git will not carry is, from
    # the run's point of view, evidence that does not exist -- it lives on a
    # container that gets reclaimed.
    files = [os.path.join(run_dir, s["file"]) for row in rows for s in row["taken_by"]]
    ignored = _git_ignored(files)

    planned = len(rows)
    present = sum(1 for r in rows if r["present"])
    return {
        "run_dir": run_dir,
        "segments": sorted(segments),
        "segments_incomplete": sorted(s for s, i in segments.items() if not i.get("complete")),
        "captures": {"planned": planned, "present": present, "absent": planned - present,
                     "rows": rows},
        "unpaid_delegations": unpaid,
        "uncommittable": [{"file": os.path.relpath(f, run_dir), "rule": r}
                          for f, r in sorted(ignored.items())],
        "complete": planned == present and not unpaid and not ignored,
    }


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__.strip().splitlines()[2].strip(), file=sys.stderr)
        print("usage: tools/gate_f/run_inventory.py <run-dir>", file=sys.stderr)
        return 2
    run_dir = argv[1].rstrip("/")
    if not os.path.isdir(run_dir):
        print(f"run_inventory: no such run directory: {run_dir}", file=sys.stderr)
        return 2
    report = collect(run_dir)
    out_path = os.path.join(run_dir, "RUN_INVENTORY.json")
    with open(out_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
        handle.write("\n")

    caps = report["captures"]
    print(f"run_inventory: {len(report['segments'])} segment(s); "
          f"{caps['present']}/{caps['planned']} prescribed frames present on disk")
    if report["complete"]:
        marker = os.path.join(run_dir, "RUN_INCOMPLETE.md")
        if os.path.exists(marker):
            os.remove(marker)
        print(f"run_inventory: run is COMPLETE for its planned evidence -> {out_path}")
        return 0

    lines = [f"# {os.path.basename(run_dir)} is INCOMPLETE", ""]
    if caps["absent"]:
        lines.append(f"- {caps['absent']} of {caps['planned']} prescribed frame(s) exist nowhere "
                     "in this run directory:")
        for row in caps["rows"]:
            if row["present"]:
                continue
            who = ", ".join(row["owed_by"]) or "-"
            hand = ", ".join(f"{d['segment']} -> {d['to']}" for d in row["delegated_by"]) or "-"
            lines.append(f"  - {row['id']}  (owed by: {who}; delegated: {hand})")
    for entry in report["unpaid_delegations"]:
        why = ("the capture lane never ran in this run directory" if not entry["target_ran"]
               else "the capture lane ran and did not produce it")
        lines.append(f"- UNPAID DELEGATION: {entry['delegated_by']} handed {entry['id']} to "
                     f"{entry['to']} and {why}.")
    if report["uncommittable"]:
        lines.append("- evidence exists on disk that git WILL NOT CARRY; `git add <dir>` skips it "
                     "silently and exits 0:")
        for row in report["uncommittable"]:
            lines.append(f"  - {row['file']}  (ignored by {row['rule']})")
    if report["segments_incomplete"]:
        lines.append("- segment(s) whose own INVENTORY.json says INCOMPLETE: "
                     + ", ".join(report["segments_incomplete"]))
    lines.append("")
    lines.append("See RUN_INVENTORY.json for the per-frame ledger.")
    with open(os.path.join(run_dir, "RUN_INCOMPLETE.md"), "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")
    print(f"run_inventory: run is INCOMPLETE -- see {run_dir}/RUN_INCOMPLETE.md", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
