#!/usr/bin/env python3
"""Summarise tests/smoke_stormwood_b_named_c2c3.gd output (c2c3_runs.json) into
SUMMARY_TABLE.md. The verdict comes from the smoke's own per-row `verdict`
(rules in the smoke header); this script only tabulates it.

    python3 ralph/reports/STORMWOOD/b/f10_2/summarize.py
"""
import json
import pathlib
import re

HERE = pathlib.Path(__file__).resolve().parent
# Godot's JSON.stringify writes an infinite ratio as a bare `inf`.
raw = re.sub(r"(?<=[:\[,\s])-?inf(?=[,\]\}\s])", "1e999", (HERE / "c2c3_runs.json").read_text())
data = json.loads(raw)

lines = [
    "# F10#2 named fights: C2 and measurable C3, per fight and starter",
    "",
    f"Seeds per policy: {data['seeds']}. Party: {data['party']}. Fixture: {data['fixture']}.",
    f"Rules: {data['rules']}.",
    "",
    "| Fight | Starter | Party L | Masher win | Masher med lead cost | Masher lead faint | Reader win | Reader med lead cost | Ratio (≤0.55) | Max single hit (<0.50) | Tell range s | Reader med s | Verdict |",
    "|---|---|---|---|---|---|---|---|---|---|---|---|---|",
]
fails = 0
for row in data["rows"]:
    m = row["pilots"]["MASHER"]
    r = row["pilots"]["READER"]
    v = row.get("verdict", {})
    ok = v.get("pass", False)
    fails += 0 if ok else 1
    ratio = v.get("ratio")
    ratio_s = "inf" if ratio is None or ratio == float("inf") or (isinstance(ratio, (int, float)) and ratio > 1e6) else f"{ratio:.2f}"
    tell_lo = min(t for t in (m["min_tell_s"], r["min_tell_s"]) if t >= 0) if max(m["min_tell_s"], r["min_tell_s"]) >= 0 else -1
    tell_hi = max(m["max_tell_s"], r["max_tell_s"])
    lines.append(
        f"| {row['case']} | {row['starter']} | {row['party_level']} | {m['win_rate']:.2f} | {m['median_lead_cost']:.3f} | "
        f"{m['lead_faint_rate']:.2f} | {r['win_rate']:.2f} | {r['median_lead_cost']:.3f} | {ratio_s} | "
        f"{v.get('max_hit', 0):.3f} | {tell_lo:.2f}–{tell_hi:.2f} | {r['median_seconds']:.1f} | "
        f"{'PASS' if ok else 'FAIL: ' + '; '.join(v.get('reasons', []))} |"
    )
lines += ["", f"Rows: {len(data['rows'])}; failing rows: {fails}; runs: {len(data['runs'])}; errors: {data['errors']}"]
(HERE / "SUMMARY_TABLE.md").write_text("\n".join(lines) + "\n")
print("\n".join(lines[-1:]))
