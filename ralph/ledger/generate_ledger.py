#!/usr/bin/env python3
"""Fill template.html with data/*.json and write dashboard.html.

Usage: python3 generate_ledger.py
Reads/writes relative to this script's own directory, so it works from
any cwd. See REGENERATE.md for the full regeneration procedure (this
script only does the last, mechanical step).
"""
import json
import pathlib

HERE = pathlib.Path(__file__).parent
DATA = HERE / "data"


def load(name):
    return json.loads((DATA / name).read_text())


def main():
    template = (HERE / "template.html").read_text()
    phases = load("phases.json")
    leases = load("leases.json")
    blocked = load("blocked.json")
    info_strip = load("info_strip.json")
    meta = load("meta.json")

    out = template
    out = out.replace("__PHASES_JSON__", json.dumps(phases))
    out = out.replace("__LEASES_JSON__", json.dumps(leases))
    out = out.replace("__BLOCKED_JSON__", json.dumps(blocked))
    out = out.replace("__INFO_STRIP_JSON__", json.dumps(info_strip))
    out = out.replace("__META_MAIN_SHA__", meta["main_sha"])
    out = out.replace("__META_STATUS_SHA__", meta["status_sha"])
    out = out.replace("__META_DATE__", meta["date"])

    if "__META_" in out or "__PHASES_JSON__" in out or "__LEASES_JSON__" in out \
            or "__BLOCKED_JSON__" in out or "__INFO_STRIP_JSON__" in out:
        raise SystemExit("unfilled placeholder remains in output — check data/*.json")

    (HERE / "dashboard.html").write_text(out)
    open_count = sum(len(p["open_items"]) for p in phases)
    closed_count = sum(p["closed_count"] for p in phases)
    print(f"wrote dashboard.html — {open_count} open, {closed_count} shipped, "
          f"{len(leases)} leases, {len(blocked)} blocked-on-owner")


if __name__ == "__main__":
    main()
