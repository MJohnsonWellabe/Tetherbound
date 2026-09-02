#!/usr/bin/env python3
"""Fill template.html with data/*.json and write dashboard.html.

Usage: python3 generate_ledger.py
Reads/writes relative to this script's own directory, so it works from
any cwd. See REGENERATE.md for the full regeneration procedure (this
script only does the last, mechanical steps: filling the template and
merging held leases against the tracked-area watchlist).
"""
import json
import pathlib

HERE = pathlib.Path(__file__).parent
DATA = HERE / "data"


def load(name):
    return json.loads((DATA / name).read_text())


def merge_leases(held, areas):
    """Held-only rows (from STATUS.md) + a free row for every watched
    area with nothing currently held, in areas.json's own order."""
    held_by_area = {row["area"]: row for row in held}
    merged = []
    for area in areas:
        row = held_by_area.get(area)
        if row:
            merged.append({**row, "free": False})
        else:
            merged.append({"area": area, "task": "free", "state": "", "when": "", "free": True})
    return merged


def main():
    template = (HERE / "template.html").read_text()
    phases = load("phases.json")
    categories = load("categories.json")
    held_leases = load("leases.json")
    areas = load("areas.json")
    blocked = load("blocked.json")
    gates = load("gates.json")
    meta = load("meta.json")

    leases = merge_leases(held_leases, areas)

    out = template
    out = out.replace("__PHASES_JSON__", json.dumps(phases))
    out = out.replace("__CATEGORIES_JSON__", json.dumps(categories))
    out = out.replace("__LEASES_JSON__", json.dumps(leases))
    out = out.replace("__BLOCKED_JSON__", json.dumps(blocked))
    out = out.replace("__GATES_JSON__", json.dumps(gates))
    out = out.replace("__META_SHA__", meta["sha"])
    out = out.replace("__META_SNAPSHOT__", meta["snapshot"])

    if "__" in out and any(tok in out for tok in (
        "__PHASES_JSON__", "__CATEGORIES_JSON__", "__LEASES_JSON__",
        "__BLOCKED_JSON__", "__GATES_JSON__", "__META_SHA__", "__META_SNAPSHOT__",
    )):
        raise SystemExit("unfilled placeholder remains in output — check data/*.json")

    (HERE / "dashboard.html").write_text(out)
    open_count = sum(len(p["items"]) for p in phases)
    closed_count = sum(p["closed"] for p in phases)
    held_count = sum(1 for row in leases if not row["free"])
    print(f"wrote dashboard.html — {open_count} open, {closed_count} shipped, "
          f"{len(categories)} feature categories, "
          f"{held_count}/{len(areas)} areas held, {len(blocked)} blocked-on-owner")


if __name__ == "__main__":
    main()
