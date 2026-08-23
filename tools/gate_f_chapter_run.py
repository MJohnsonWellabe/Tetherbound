#!/usr/bin/env python3
"""GATE-F: the whole Meadows chapter, run as one record.

    python3 tools/gate_f_chapter_run.py
    python3 tools/gate_f_chapter_run.py --only corridor
    python3 tools/gate_f_chapter_run.py --godot ~/godot-bin/Godot_v4.7-stable_linux.x86_64

Prompt 70 asks for something no file in this repo produced before: the chapter
from the title screen to post-Warden world healing, measured as ONE run rather
than as a pile of green segments.  Gate B's continuous smoke proves the opening,
the D-corridor probes prove each region, and the Gate E finale smoke proves the
ending -- and each of those passing tells you nothing about the joins, which is
exactly where a 3-4 hour chapter fails.  This chains them and writes the joined
record.

## What "continuous" means here, exactly

Honesty about the seam matters more than the word.  Three things are true:

  * The RECORD is continuous.  One timestamped report covers title through
    healing, with every segment's wall time, verdict and measurements in the
    order a player meets them, so pacing and cadence can be read across the
    whole chapter instead of per-lane.
  * The WORLD is continuous inside each segment.  The corridor probe walks
    band 1 through band 5 in a single boot with one running dead-walk counter
    carried across the band handoffs -- the interval no per-band probe can see.
  * The SAVE is not yet carried BETWEEN the three segments.  Each boots its own
    process: the head starts a genuine fresh game at the title, the tail grants
    a finale-level five.  Closing that seam means having the head write a save
    at South Bridge and the tail load it, which edits
    `tests/smoke_gate_b_continuous.gd` -- a file the Gate B coordinator is
    actively rewriting on `ralph/GATEB-PATH`.  Per the claim protocol that
    branch owns it, so the hook lands when GATEB-PATH does, not before, and
    until then this report says so in its own header rather than implying a
    continuity it does not have.

## Method law

`ralph/lanes/COORDINATORS.md`: iterate on focused segment probes, never on full
runs.  `--only` exists for that -- fix one segment, re-run that segment, and
only then spend the full chapter.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import os
import re
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

#: The chapter, in the order a player plays it.  `kind` decides how a segment's
#: verdict is read: a smoke test says PASS/FAIL by exit code, a probe is
#: evidence and only fails by crashing.
SEGMENTS = [
    {
        "id": "head",
        "title": "Gate B — title through the village tournament to South Bridge",
        "script": "tests/smoke_gate_b_continuous.gd",
        "kind": "test",
        "timeout": 3600,
        "covers": "title, fresh save, opening, first catch, team, tools, gathering, "
                  "villagers, home, creature bed, sleep, tournament, South Bridge",
    },
    {
        "id": "corridor",
        "title": "D corridor — South Bridge through band 1..5 to the Hall approach",
        "script": "tools/_probe_gate_f_corridor.gd",
        "kind": "probe",
        "timeout": 3600,
        "covers": "band1 Lower Meadows, band2 Quarry/Warrens, band3 River/Relay, "
                  "band4 Upper Meadows, band5 Stronghold approach",
    },
    {
        "id": "tail",
        "title": "Gate E — Hall entry through the Warden, legendary and world healing",
        "script": "tests/smoke_gate_e_finale.gd",
        "kind": "test",
        "timeout": 3600,
        "covers": "patrol, courtyard, recovery point, elite, shutter, Warden, lever, "
                  "legendary offer, release ceremony, region answer, post-win chain end",
    },
]

METRIC_RE = re.compile(r"^GATEF-METRIC\s+(.*)$")
#: Lines a segment prints that are worth lifting into the record verbatim.
#: Deliberately narrow -- a full segment log is hundreds of lines and lives in
#: its own file beside the report.
HIGHLIGHT_RE = re.compile(
    r"^(gate B continuous:|GATE-E|gate E|corridor walked:|longest stretch|"
    r"things met|by kind:|grounding:|dead-walk intervals|FAIL|FAILURES?:)",
)


def _godot_default() -> str:
    for candidate in (
        os.environ.get("GODOT"),
        str(Path.home() / "godot-bin" / "Godot_v4.7-stable_linux.x86_64"),
        "godot",
    ):
        if candidate and (Path(candidate).exists() or candidate == "godot"):
            return candidate
    return "godot"


def run_segment(segment: dict, godot: str, logdir: Path) -> dict:
    """Run one segment to completion and return what the record needs."""
    log_path = logdir / f"{segment['id']}.log"
    cmd = [godot, "--headless", "--path", str(REPO), "--script", segment["script"]]
    started = time.time()
    try:
        proc = subprocess.run(
            cmd, cwd=REPO, capture_output=True, text=True, timeout=segment["timeout"]
        )
        out, code, timed_out = proc.stdout + proc.stderr, proc.returncode, False
    except subprocess.TimeoutExpired as exc:
        out = (exc.stdout or "") + (exc.stderr or "")
        if isinstance(out, bytes):
            out = out.decode("utf-8", "replace")
        code, timed_out = -1, True
    elapsed = time.time() - started
    log_path.write_text(out, encoding="utf-8")

    metrics, highlights = [], []
    for line in out.splitlines():
        found = METRIC_RE.match(line.strip())
        if found:
            metrics.append(found.group(1))
        elif HIGHLIGHT_RE.match(line.strip()):
            highlights.append(line.strip())

    # A probe is evidence, not a verdict: it only fails by failing to run.
    # A smoke test's exit code IS the verdict.
    passed = code == 0 and not timed_out
    return {
        **segment,
        "exit": code,
        "timed_out": timed_out,
        "elapsed": elapsed,
        "passed": passed,
        "log": log_path,
        "metrics": metrics,
        "highlights": highlights[:40],
    }


def write_report(results: list[dict], path: Path, started_at: str, godot: str) -> None:
    total = sum(r["elapsed"] for r in results)
    ran = {r["id"] for r in results}
    partial = ran != {s["id"] for s in SEGMENTS}

    lines: list[str] = []
    lines.append(f"# Gate F — full-chapter run, {started_at}")
    lines.append("")
    lines.append(f"Produced by `tools/gate_f_chapter_run.py` on `{godot}`.")
    lines.append("")
    if partial:
        lines.append(
            f"**PARTIAL RUN — segments {sorted(ran)} only.** This is a focused "
            "segment probe under the method law, not the chapter record. A "
            "chapter verdict needs all three segments in one invocation."
        )
        lines.append("")
    lines.append(
        "**Continuity of this record.** One report, three processes. The world "
        "is continuous inside each segment — in particular the corridor walks "
        "band 1 through band 5 in a single boot with one dead-walk counter "
        "carried across the band handoffs. The save is not yet carried between "
        "segments: the head starts a genuine fresh game at the title, the tail "
        "grants a finale-level five. That seam closes when `ralph/GATEB-PATH` "
        "lands and the head can write a South Bridge save for the tail to load."
    )
    lines.append("")

    lines.append("## Segments")
    lines.append("")
    lines.append("| # | segment | verdict | wall time | covers |")
    lines.append("|---|---------|---------|-----------|--------|")
    for i, r in enumerate(results, 1):
        if r["timed_out"]:
            verdict = f"**TIMEOUT** ({r['timeout']}s)"
        elif r["kind"] == "probe":
            verdict = "recorded" if r["passed"] else f"**CRASHED** (exit {r['exit']})"
        else:
            verdict = "PASS" if r["passed"] else f"**FAIL** (exit {r['exit']})"
        lines.append(
            f"| {i} | {r['title']} | {verdict} | {r['elapsed'] / 60:.1f} min | {r['covers']} |"
        )
    lines.append("")
    lines.append(f"Harness wall time: **{total / 60:.1f} min**.")
    lines.append("")
    lines.append(
        "Harness wall time is not the player's 3–4 hours and must never be "
        "reported as it: the head grants the tournament's team rather than "
        "grinding six levels, the corridor steps its route instead of walking "
        "it at 4 m/s, and the tail tops fighters up. The player-time estimate "
        "is built from the corridor's own metres and the beat table below, not "
        "from this clock."
    )
    lines.append("")

    for r in results:
        lines.append(f"## {r['id']} — {r['title']}")
        lines.append("")
        lines.append(f"`{r['script']}` → `{r['log'].name}`")
        lines.append("")
        if r["metrics"]:
            lines.append("Measurements:")
            lines.append("")
            lines.append("```")
            lines.extend(r["metrics"])
            lines.append("```")
            lines.append("")
        if r["highlights"]:
            lines.append("From the segment's own output:")
            lines.append("")
            lines.append("```")
            lines.extend(r["highlights"])
            lines.append("```")
            lines.append("")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=_godot_default())
    parser.add_argument(
        "--only",
        default="",
        help="comma-separated segment ids (%s); the method law's focused probe"
        % ",".join(s["id"] for s in SEGMENTS),
    )
    parser.add_argument("--out", default="", help="report path (default ralph/reports/)")
    args = parser.parse_args()

    wanted = [s.strip() for s in args.only.split(",") if s.strip()]
    segments = [s for s in SEGMENTS if not wanted or s["id"] in wanted]
    unknown = set(wanted) - {s["id"] for s in SEGMENTS}
    if unknown:
        print(f"unknown segment(s): {', '.join(sorted(unknown))}", file=sys.stderr)
        return 2

    stamp = _dt.datetime.now().strftime("%Y-%m-%d-%H%M")
    started_at = _dt.datetime.now().strftime("%Y-%m-%d %H:%M")
    logdir = REPO / "ralph" / "reports" / f"gate-f-run-{stamp}"
    logdir.mkdir(parents=True, exist_ok=True)
    report = Path(args.out) if args.out else logdir / "REPORT.md"

    results = []
    for segment in segments:
        print(f"[gate-f] {segment['id']}: {segment['script']} ...", flush=True)
        result = run_segment(segment, args.godot, logdir)
        state = "ok" if result["passed"] else "FAILED"
        print(
            f"[gate-f] {segment['id']}: {state} in {result['elapsed'] / 60:.1f} min "
            f"({len(result['metrics'])} metrics)",
            flush=True,
        )
        results.append(result)

    write_report(results, report, started_at, args.godot)
    print(f"[gate-f] record: {report}", flush=True)
    return 0 if all(r["passed"] for r in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
