#!/usr/bin/env python3
"""Build the "tried and failed" register for the coordinator board.

Owner, 13 Nov 2026: "Is there any documentation of everything we have tried
that hasn't worked so it doesn't get tried again" -> "Fix it".

Generated, never hand-edited. It gathers every approach that did not ship from
the places lanes already write to, and indexes it by acceptance row:
  1. LANE-JUDGE verdict lines (VERDICT-LINES.md on tb/judge and on main):
     DO NOT SHIP, level, parked.
  2. The coordinator's GPU queue (gpu_queue.json): withdrawn, parked, held,
     do-not-ship and level entries, with their reason.
  3. Lane notes and arm write-ups (NOTE.md, ARM.md, READY.md) on main and on
     every active lane branch: bullets and headings that say parked, held,
     dropped, ruled out, did not work, no change, wrong cause or similar.

Run from the repo root after `git fetch` of main, tb/judge and the lane
branches:  python3 ralph/reports/COORDINATOR/dashboard/tried_failed.py
Writes tried_failed.json (read by build_dashboard.py) and
ralph/reports/COORDINATOR/TRIED_AND_FAILED.md (for lanes to grep).
"""
import json
import re
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUT_JSON = HERE / "tried_failed.json"
OUT_MD = HERE.parent / "TRIED_AND_FAILED.md"
QUEUE = HERE.parent / "gpu_queue.json"

LANE_REFS = ["origin/tb/land-mt", "origin/tb/land-cs", "origin/tb/beings",
             "origin/tb/scene", "origin/tb/places", "origin/tb/judge"]
VERDICT_PATH = "ralph/reports/GPU-PASS/1108/VERDICT-LINES.md"

ROW_RE = re.compile(r"\b(F\d{2}#\d+|F36 \(\d\) #\d+|CARD-\w+)")
VERDICT_FAIL = re.compile(r"DO NOT SHIP|\(level\)|\blevel\b|\bPARK|NOT CLOSED|WITHDRAWN", re.I)
QUEUE_FAIL = re.compile(r"WITHDRAWN|PARKED|HELD|DO NOT SHIP|\bLEVEL\b|not shipped", re.I)
NOTE_FAIL = re.compile(
    r"\bPARKED\b|\bparked\b|\bHELD\b|\bheld\b by|not shipped|did not work|"
    r"ruled out|tried and dropped|\bdropped\b|no visible change|changed nothing|"
    r"no change|wrong cause|DO NOT SHIP|lost \d|loses|level on GPU|"
    r"round \d (missed|failed)|failed attempts?|two (failed|weak) rounds", re.I)
HEADING_FAIL = re.compile(
    r"tried|dropped|parked|ruled out|did not work|what was tried|losing|not shipped", re.I)
# Retry status: "parked" means the approach is closed until a new idea;
# "held" means the arm exists and may run again after a named fix.
PARKED_WORDS = re.compile(r"PARK|ruled out|dropped|did not work|wrong cause|not shipped|DO NOT SHIP|LEVEL|WITHDRAWN|loses|lost", re.I)


def git(*args):
    r = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else ""


def rows_of(text):
    seen = []
    for m in ROW_RE.findall(text):
        if m not in seen:
            seen.append(m)
    return seen


def clip(text, n=420):
    text = re.sub(r"\s+", " ", text).strip()
    return text if len(text) <= n else text[: n - 1] + "…"


def status_of(text):
    if re.search(r"\bHELD\b|\bheld\b", text) and not re.search(r"PARK", text, re.I):
        return "held"
    return "parked" if PARKED_WORDS.search(text) else "held"


entries = []
seen_keys = set()


def add(rows, approach, result, source, status):
    key = (tuple(rows), clip(result, 160))
    if key in seen_keys:
        return
    seen_keys.add(key)
    entries.append({"rows": rows or ["(no row named)"], "approach": approach,
                    "result": clip(result), "source": source, "status": status})


# 1. Verdict lines.
for ref in ["origin/tb/judge", "origin/main"]:
    for line in git("show", f"{ref}:{VERDICT_PATH}").splitlines():
        if not line.startswith("- ") or not VERDICT_FAIL.search(line):
            continue
        parts = [p.strip() for p in line[2:].split("|")]
        if len(parts) < 3:
            continue
        name, rowtxt, verdict = parts[0], parts[1], " | ".join(parts[2:])
        failed = re.search(r"DO NOT SHIP|\(level\)|WITHDRAWN|\bPARK", verdict)
        shipped = re.match(r"\s*SHIP", verdict)
        if not failed or (shipped and not re.search(r"\bPARK", verdict)):
            continue  # ships and re-scores with gains are not failed approaches
        add(rows_of(rowtxt) or rows_of(verdict), name.replace(".md", ""), verdict,
            f"{ref.split('/')[-1]}:{VERDICT_PATH}", status_of(verdict))

# 2. GPU queue.
for e in json.loads(QUEUE.read_text(encoding="utf-8")).get("entries", []):
    st = e.get("status", "")
    if not QUEUE_FAIL.search(st) or re.match(r"(LANDED|SHIP|CLOSED|CAPTURED|JUDGED|BY-EYE PASS|READY|RUNNING)", st):
        continue
    rows = rows_of(" ".join(e.get("rows", []))) or rows_of(e.get("ask", ""))
    add(rows, e["id"], st, "COORDINATOR/gpu_queue.json", status_of(st))

# 3. Lane notes and arm write-ups, on main (archived lanes) and live lane branches.
def scan_doc(ref, path):
    text = git("show", f"{ref}:{path}")
    if not text:
        return
    lane = path.split("/")[3] if path.count("/") >= 4 else path
    in_fail_section = False
    for raw in text.splitlines():
        line = raw.rstrip()
        if line.startswith("#"):
            in_fail_section = bool(HEADING_FAIL.search(line))
            if HEADING_FAIL.search(line) and rows_of(line):
                add(rows_of(line), lane, line.lstrip("# "), f"{ref.split('/')[-1]}:{path}", status_of(line))
            continue
        if not line.lstrip().startswith(("-", "*", "1", "2", "3", "4", "5")):
            continue
        if not (NOTE_FAIL.search(line) or in_fail_section):
            continue
        if re.search(r"LANDING READY|\bships?\b|SHIP[:,]|\blanded\b|judged SHIP", line, re.I) and not re.search(r"DO NOT SHIP|\bPARK", line):
            continue
        rows = rows_of(line)
        if not rows and not NOTE_FAIL.search(line):
            continue
        add(rows, lane, line.lstrip(" -*0123456789."), f"{ref.split('/')[-1]}:{path}", status_of(line))


for ref in ["origin/main", *LANE_REFS]:
    listing = git("ls-tree", "-r", "--name-only", ref, "ralph/reports/LANES/")
    for path in listing.splitlines():
        if path.endswith(("/NOTE.md", "/ARM.md")):
            scan_doc(ref, path)

# Index by row.
by_row = {}
for e in entries:
    for r in e["rows"]:
        by_row.setdefault(r, []).append(e)


def row_key(r):
    m = re.match(r"F(\d+)#(\d+)", r)
    return (0, int(m.group(1)), int(m.group(2))) if m else (1, 0, 0) if r != "(no row named)" else (2, 0, 0)


rows_sorted = sorted(by_row, key=row_key)
OUT_JSON.write_text(json.dumps({"entries": len(entries), "rows": {r: by_row[r] for r in rows_sorted}},
                               indent=1, ensure_ascii=False), encoding="utf-8")

md = ["# Tried and failed (generated; do not edit)", "",
      "Every approach that did not ship, by acceptance row. Generated by",
      "`ralph/reports/COORDINATOR/dashboard/tried_failed.py` from LANE-JUDGE verdict lines, the",
      "coordinator's GPU queue and every lane NOTE.md / ARM.md on main and the live lane branches.",
      "",
      "**Before building an arm for a row, read its section here.** An approach marked `parked`",
      "is closed: do not retry it without a new cause or a new idea, and say in the ARM.md what",
      "is new. `held` means the arm exists and is waiting on a named fix.",
      "", f"{len(entries)} entries across {len(rows_sorted)} rows.", ""]
for r in rows_sorted:
    md.append(f"## {r}")
    for e in by_row[r]:
        md.append(f"- **{e['status']}** · {e['approach']}: {e['result']} _(source: {e['source']})_")
    md.append("")
OUT_MD.write_text("\n".join(md), encoding="utf-8")
print(f"tried_failed: {len(entries)} entries, {len(rows_sorted)} rows")
