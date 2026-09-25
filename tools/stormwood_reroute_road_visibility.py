#!/usr/bin/env python3
"""Re-seat Stormwood's ROAD-visibility pairs after an authored road leg moves.

`tools/gate_f/author_road_visibility_anchors.py` regenerates every reserved
`road_visibility_` row from scratch; after a local reroute that also reshuffles
rows on unchanged road (and re-derives a pair onto the Stormheart terminal road
that `test_stormwood_critical_spawn_clearance` keeps clear). This tool keeps
every committed row, drops only the named rows that lined the replaced legs,
and runs the same greedy placer (`add_route_anchors`) for just the samples that
then lack two forward-visible bodies. New rows reuse the dropped ids first.

Usage: python3 tools/stormwood_reroute_road_visibility.py <dropped_id> [...]
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools" / "gate_f"))
import author_road_visibility_anchors as author  # noqa: E402
import road_visibility_audit as audit  # noqa: E402

ENCOUNTERS = "data/config/stormwood_encounters.json"


def main(dropped: list[str]) -> int:
    species = author.load("data/creatures/species.json")["species"]
    heights = {key: float(row["placeholder"]["height"]) for key, row in species.items()}
    data = author.load(ENCOUNTERS)
    known = {str(row["id"]) for row in data["wild_clusters"]}
    missing = [row_id for row_id in dropped if row_id not in known or not row_id.startswith(author.PREFIX)]
    if missing:
        print(f"not reserved road-visibility rows: {missing}", file=sys.stderr)
        return 1
    original = list(data["wild_clusters"])
    data["wild_clusters"] = [row for row in data["wild_clusters"] if str(row["id"]) not in dropped]
    tables = {row["id"]: row for row in data["tables"]}
    bodies = [author.body(row["position"], audit.table_min(
        tables[row["calm_table_id"]]["roles"], heights, "species", "placeholder_species"))
        for row in data["wild_clusters"]]
    free_ids = {}
    for row_id in dropped:
        route_id = row_id[len(author.PREFIX):].rsplit("_", 1)[0]
        free_ids.setdefault(route_id, []).append(row_id)
    world = author.load("data/config/stormwood_world.json")
    added = 0
    for route in world["routes"]:
        if route.get("kind") != "critical":
            continue
        route_heights = [audit.table_min(tables[author.storm_region(float(p[1]))[1]]["roles"], heights,
            "species", "placeholder_species") for p in route["points"]]
        anchors = author.add_route_anchors(route["id"], [audit.xz(p) for p in route["points"]],
            bodies, min(route_heights))
        taken = {str(row["id"]) for row in data["wild_clusters"]}
        next_index = 1
        for anchor in anchors:
            ids = free_ids.get(route["id"], [])
            if ids:
                row_id = ids.pop(0)
            else:
                while f"{author.PREFIX}{route['id']}_{next_index:02d}" in taken:
                    next_index += 1
                row_id = f"{author.PREFIX}{route['id']}_{next_index:02d}"
            taken.add(row_id)
            region_id, calm, surge = author.storm_region(float(anchor["position"][2]))
            data["wild_clusters"].append({
                "id": row_id,
                "region_id": region_id,
                "position": anchor["position"],
                "radius": 3.0,
                "calm_table_id": calm,
                "surge_table_id": surge,
                "replacement_point": f"wild_clusters.{row_id}",
                "purpose": "roadside creature sightline pair",
                "_why_road_visibility_0907": "ROAD CP-2 authored pair on the critical-road shoulder. Stormwood runtime already expands every cluster to exactly two bodies.",
            })
            added += 1
    # Routes are placed one after another, so a pair added for the end of one
    # road can be made redundant by a later road's pair. Drop any such pair,
    # newest first, while every critical road still keeps zero failing samples.
    def all_pass(rows: list[dict]) -> bool:
        placed = [author.body(row["position"], audit.table_min(
            tables[row["calm_table_id"]]["roles"], heights, "species", "placeholder_species")) for row in rows]
        return all(audit.evaluate_route(route["id"], [audit.xz(p) for p in route["points"]], placed)["failing_samples"] == 0
            for route in world["routes"] if route.get("kind") == "critical")
    for row in reversed(list(data["wild_clusters"])):
        row_id = str(row["id"])
        if row_id in dropped or row_id in known:
            continue
        trial = [other for other in data["wild_clusters"] if other is not row]
        if all_pass(trial):
            data["wild_clusters"] = trial
            added -= 1
    leftover = [row_id for ids in free_ids.values() for row_id in ids]
    # Re-seated rows keep their original slot; only genuinely new rows are
    # appended, so the committed diff shows moves rather than a reshuffle.
    by_id = {str(row["id"]): row for row in data["wild_clusters"]}
    ordered = [by_id.pop(str(row["id"])) for row in original if str(row["id"]) in by_id]
    ordered.extend(by_id.values())
    data["wild_clusters"] = ordered
    data["wild_cluster_count_contract"] = len(data["wild_clusters"])
    author.write(ENCOUNTERS, data)
    print(f"dropped {len(dropped)}, added {added}, unused ids {leftover}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
