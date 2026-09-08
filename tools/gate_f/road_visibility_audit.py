#!/usr/bin/env python3
"""Static mirror of the committed CP-2 road-creature visibility gate.

This is intentionally data-only so encounter authors can iterate while another
lane owns Godot's import cache. The shipping gate remains the GDScript model.
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
STEP = 10.0
REQUIRED = 2
CLOUDREACH_ROUTE_IDS = {
    "arrival_gate_road",
    "lower_cliff_road",
    "broken_causeway_main",
    "windscar_floor_loop",
    "windscar_counterweight_pass",
    "upper_summit_road",
}


def load(relative: str) -> dict[str, Any]:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def xyz(raw: list[float]) -> tuple[float, float, float]:
    return float(raw[0]), float(raw[1]), float(raw[2])


def xz(raw: list[float]) -> tuple[float, float, float]:
    return float(raw[0]), 0.0, float(raw[1])


def points_xyz(raw: list[Any]) -> list[tuple[float, float, float]]:
    out: list[tuple[float, float, float]] = []
    for encoded in raw:
        values = encoded.split() if isinstance(encoded, str) else encoded
        if len(values) >= 3:
            out.append(xyz(values))
    return out


def sample_route(points: list[tuple[float, float, float]]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    walked = 0.0
    next_distance = 0.0
    last_forward = (0.0, 0.0, -1.0)
    for a, b in zip(points, points[1:]):
        delta = tuple(b[i] - a[i] for i in range(3))
        length = math.sqrt(sum(v * v for v in delta))
        if length <= 0.001:
            continue
        forward = tuple(v / length for v in delta)
        last_forward = forward
        while next_distance < walked + length:
            along = next_distance - walked
            if along >= 0.0:
                out.append({
                    "at": tuple(a[i] + forward[i] * along for i in range(3)),
                    "forward": forward,
                })
            next_distance += STEP
        walked += length
    if not out or math.dist(out[-1]["at"], points[-1]) > 0.01:
        out.append({"at": points[-1], "forward": last_forward})
    return out


def visible(body: dict[str, Any], sample: dict[str, Any]) -> bool:
    dx = body["at"][0] - sample["at"][0]
    dz = body["at"][2] - sample["at"][2]
    if dx * sample["forward"][0] + dz * sample["forward"][2] < 0.0:
        return False
    return math.hypot(dx, dz) <= 40.0 * body["height_m"]


def evaluate_route(route_id: str, points: list[tuple[float, float, float]], bodies: list[dict[str, Any]]) -> dict[str, Any]:
    samples = sample_route(points)
    counts = [sum(body["count"] for body in bodies if visible(body, sample)) for sample in samples]
    failing = [sample for sample, count in zip(samples, counts) if count < REQUIRED]
    longest = current = 0
    for count in counts:
        current = current + 1 if count < REQUIRED else 0
        longest = max(longest, current)
    return {
        "id": route_id,
        "samples": len(samples),
        "minimum_visible": min(counts, default=0),
        "failing_samples": len(failing),
        "longest_failing_run_m": longest * STEP,
        "failing_positions": [[round(v, 1) for v in sample["at"]] for sample in failing],
        "counts": counts,
    }


def table_min(entries: list[dict[str, Any]], heights: dict[str, float], *keys: str) -> float:
    values = []
    for entry in entries:
        species_id = next((str(entry[key]) for key in keys if entry.get(key)), "")
        values.append(max(0.1, heights.get(species_id, 1.0)))
    return min(values, default=1.0)


def evaluate() -> dict[str, list[dict[str, Any]]]:
    species_rows = load("data/creatures/species.json")["species"]
    heights = {key: float(row["placeholder"]["height"]) for key, row in species_rows.items()}
    result: dict[str, list[dict[str, Any]]] = {}

    tables = load("data/config/spawn_tables.json")["tables"]
    bodies = []
    for path in sorted((ROOT / "data/config/bands").glob("*/spawns.json")):
        for row in json.loads(path.read_text(encoding="utf-8"))["spawns"]:
            if row.get("time", "day") == "night":
                continue
            if row.get("weather") and "clear" not in row["weather"]:
                continue
            height = heights.get(row.get("species", ""), 1.0)
            if row.get("table"):
                height = table_min(tables.get(row["table"], {}).get("entries", []), heights, "species")
            bodies.append({"at": xyz(row["centre"]), "count": int(row.get("count", 1)), "height_m": height})
    terrain = load("data/config/terrain_playground.json")
    result["meadows"] = [evaluate_route(row["id"], [xz(p) for p in row["points"]], bodies) for row in terrain["trail"]["bands"]]

    chapter = load("data/config/cloudreach_chapter.json")
    tables_by_id = {row["id"]: row for row in chapter["encounter_tables"]}
    bodies = []
    for row in load("data/config/cloudreach_encounters.json")["wild_sites"]:
        table = tables_by_id.get(row["table_id"], {})
        height = table_min(table.get("entries", []), heights, "species", "placeholder_species")
        bodies.append({"at": xyz(row["position"]), "count": int(row.get("count", 1)), "height_m": height})
    world = load("data/config/cloudreach_world.json")
    result["cloudreach"] = [evaluate_route(row["id"], points_xyz(row["polyline"]), bodies) for row in world["routes"] if row["id"] in CLOUDREACH_ROUTE_IDS]

    encounters = load("data/config/stormwood_encounters.json")
    tables_by_id = {row["id"]: row for row in encounters["tables"]}
    bodies = []
    for row in encounters["wild_clusters"]:
        table = tables_by_id.get(row["calm_table_id"], {})
        height = table_min(table.get("roles", []), heights, "species", "placeholder_species")
        bodies.append({"at": xyz(row["position"]), "count": 2, "height_m": height})
    world = load("data/config/stormwood_world.json")
    result["stormwood"] = [evaluate_route(row["id"], [xz(p) for p in row["points"]], bodies) for row in world["routes"] if row.get("kind") == "critical"]

    roster_rows = load("data/config/water_roster.json")["species"]
    water_heights = {key: float(row["placeholder"]["target_height_m"]) for key, row in roster_rows.items()}
    encounters = load("data/config/water_encounters.json")
    tables_by_id = {row["id"]: row for row in encounters["tables"]}
    bodies = []
    for row in encounters["wild_sites"]:
        table = tables_by_id.get(row["table_id"], {})
        height = table_min(table.get("entries", []), water_heights, "species_id", "placeholder_species")
        bodies.append({"at": xyz(row["position"]), "count": int(row.get("count", 1)), "height_m": height})
    world = load("data/config/water_world.json")
    routes = [row for group in ("land_routes", "water_routes") for row in world[group] if row.get("main_path", False)]
    result["water"] = [evaluate_route(row["id"], points_xyz(row["polyline"]), bodies) for row in routes]
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    result = evaluate()
    failing = 0
    for realm, routes in result.items():
        print(f"[{realm}]")
        for route in routes:
            failing += route["failing_samples"]
            print(f"  {route['id']} samples={route['samples']} min={route['minimum_visible']} failing={route['failing_samples']} longest={route['longest_failing_run_m']:.0f}m")
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"ROAD static audit: {failing} failing samples")
    return 0 if failing == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
