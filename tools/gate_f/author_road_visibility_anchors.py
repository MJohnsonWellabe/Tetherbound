#!/usr/bin/env python3
"""Author deterministic ecology pairs for the owner ROAD visibility contract.

The tool only adds/removes rows carrying its reserved IDs. Existing ecology is
never moved, rerolled or replaced. Anchors sit on the future authored route
sample (not a made-up radius/draw-distance increase), and a small alternating
cross-road offset keeps the pair readable without blocking the trainer path.
"""

from __future__ import annotations

import json
import math
import os
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import road_visibility_audit as audit  # noqa: E402

PREFIX = "road_visibility_"


def load(relative: str) -> dict[str, Any]:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def write(relative: str, data: dict[str, Any]) -> None:
    path = ROOT / relative
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    os.replace(temp, path)


def body(position: list[float], height: float, count: int = 2) -> dict[str, Any]:
    return {"at": tuple(float(v) for v in position), "height_m": height, "count": count}


def existing_meadows(heights: dict[str, float]) -> list[dict[str, Any]]:
    tables = load("data/config/spawn_tables.json")["tables"]
    result = []
    for path in sorted((ROOT / "data/config/bands").glob("*/spawns.json")):
        for row in json.loads(path.read_text(encoding="utf-8"))["spawns"]:
            if row.get("_why_road_visibility_0907") or row.get("time", "day") == "night":
                continue
            if row.get("weather") and "clear" not in row["weather"]:
                continue
            height = heights.get(row.get("species", ""), 1.0)
            if row.get("table"):
                height = audit.table_min(tables.get(row["table"], {}).get("entries", []), heights, "species")
            result.append(body(row["centre"], height, int(row.get("count", 1))))
    return result


def add_route_anchors(
    route_id: str,
    points: list[tuple[float, float, float]],
    bodies: list[dict[str, Any]],
    height: float,
) -> list[dict[str, Any]]:
    """Greedily place the farthest useful future pair for each failing sample."""
    samples = audit.sample_route(points)
    added: list[dict[str, Any]] = []
    for index, sample in enumerate(samples):
        if sum(item["count"] for item in bodies if audit.visible(item, sample)) >= audit.REQUIRED:
            continue
        maximum = height * 40.0 * 0.78
        selected = sample
        for future in samples[index:]:
            dx = future["at"][0] - sample["at"][0]
            dz = future["at"][2] - sample["at"][2]
            if dx * sample["forward"][0] + dz * sample["forward"][2] < 0.0:
                continue
            if math.hypot(dx, dz) <= maximum:
                selected = future
        forward = selected["forward"]
        lateral = (-forward[2], forward[0])
        side = -1.0 if len(added) % 2 else 1.0
        # 5.5m clears a 4m road plus shoulders, while remaining on authored
        # route terrain closely enough for later ground/navigation validation.
        position = [
            round(selected["at"][0] + forward[0] * 2.0 + lateral[0] * 5.5 * side, 3),
            round(selected["at"][1], 3),
            round(selected["at"][2] + forward[2] * 2.0 + lateral[1] * 5.5 * side, 3),
        ]
        new_body = body(position, height)
        if not audit.visible(new_body, sample):
            position = [round(v, 3) for v in selected["at"]]
            new_body = body(position, height)
        bodies.append(new_body)
        added.append({"route_id": route_id, "position": position})
    return added


def author_meadows(heights: dict[str, float]) -> int:
    terrain = load("data/config/terrain_playground.json")
    band_specs = [
        ("band1_lower_meadows", "meadowhart", 1910),
        ("band2_stone_and_root", "burrowback", 2910),
        ("band3_the_river_lock", "meadowhart", 3910),
        ("band4_upper_meadows_ironwood", "galecrest", 4910),
        ("band5_stronghold_approach", "burrowback", 5910),
    ]
    bodies = existing_meadows(heights)
    total = 0
    for band, species_id, start_order in band_specs:
        relative = f"data/config/bands/{band}/spawns.json"
        data = load(relative)
        data["spawns"] = [row for row in data["spawns"] if int(row.get("order", -1)) < start_order]
        route = next(row for row in terrain["trail"]["bands"] if row["id"] == band)
        anchors = add_route_anchors(band, [audit.xz(p) for p in route["points"]], bodies, heights[species_id])
        for index, anchor in enumerate(anchors):
            data["spawns"].append({
                "order": start_order + index,
                "species": species_id,
                "count": 2,
                "centre": anchor["position"],
                "radius": 3.0,
                "habitat": "roadside_sightline",
                "_why_road_visibility_0907": f"ROAD CP-2 authored pair for {band}; forward-visible at the preceding 10m sample. Alternating 5.5m shoulder offset preserves the player line and existing off-road ecology.",
            })
        write(relative, data)
        total += len(anchors)
    return total


def author_cloudreach(heights: dict[str, float]) -> int:
    relative = "data/config/cloudreach_encounters.json"
    data = load(relative)
    data["wild_sites"] = [row for row in data["wild_sites"] if not str(row["id"]).startswith(PREFIX)]
    chapter = load("data/config/cloudreach_chapter.json")
    tables = {row["id"]: row for row in chapter["encounter_tables"]}
    table_for_route = {
        "arrival_gate_road": "cloudreach_lower_wild",
        "lower_cliff_road": "cloudreach_lower_wild",
        "broken_causeway_main": "cloudreach_causeway_wild",
        "windscar_floor_loop": "cloudreach_windscar_wild",
        "windscar_counterweight_pass": "cloudreach_high_roost_wild",
        "upper_summit_road": "cloudreach_summit_wild",
    }
    bodies = []
    for row in data["wild_sites"]:
        height = audit.table_min(tables[row["table_id"]]["entries"], heights, "species", "placeholder_species")
        bodies.append(body(row["position"], height, int(row.get("count", 1))))
    world = load("data/config/cloudreach_world.json")
    total = 0
    for route in world["routes"]:
        if route["id"] not in audit.CLOUDREACH_ROUTE_IDS:
            continue
        table_id = table_for_route[route["id"]]
        height = audit.table_min(tables[table_id]["entries"], heights, "species", "placeholder_species")
        anchors = add_route_anchors(route["id"], audit.points_xyz(route["polyline"]), bodies, height)
        for index, anchor in enumerate(anchors, 1):
            data["wild_sites"].append({
                "id": f"{PREFIX}{route['id']}_{index:02d}",
                "table_id": table_id,
                "position": anchor["position"],
                "count": 2,
                "radius_m": 3.0,
                "purpose": "roadside creature sightline pair",
                "_why_road_visibility_0907": "ROAD CP-2 authored pair on the route shoulder. Uses the route's native encounter table; no global radius, draw-distance or spawn-budget inflation.",
            })
        total += len(anchors)
    write(relative, data)
    return total


def storm_region(z: float) -> tuple[str, str, str]:
    if z < 1050:
        return "cinder_verge", "verge_calm", "verge_surge"
    if z < 2150:
        return "glowmoss_hollows", "hollows_calm", "hollows_surge"
    if z < 3550:
        return "conductor_run", "run_calm", "run_surge"
    if z < 4950:
        return "deepwood", "deepwood_calm", "deepwood_surge"
    return "dynamo", "dynamo_calm", "dynamo_surge"


def author_stormwood(heights: dict[str, float]) -> int:
    relative = "data/config/stormwood_encounters.json"
    data = load(relative)
    data["wild_clusters"] = [row for row in data["wild_clusters"] if not str(row["id"]).startswith(PREFIX)]
    tables = {row["id"]: row for row in data["tables"]}
    bodies = []
    for row in data["wild_clusters"]:
        height = audit.table_min(tables[row["calm_table_id"]]["roles"], heights, "species", "placeholder_species")
        bodies.append(body(row["position"], height))
    world = load("data/config/stormwood_world.json")
    total = 0
    for route in world["routes"]:
        if route.get("kind") != "critical":
            continue
        # Conservative route-specific height is the smallest calm-table body
        # across every region this road enters.
        route_heights = []
        for point in route["points"]:
            _, calm, _ = storm_region(float(point[1]))
            route_heights.append(audit.table_min(tables[calm]["roles"], heights, "species", "placeholder_species"))
        anchor_height = min(route_heights)
        anchors = add_route_anchors(route["id"], [audit.xz(p) for p in route["points"]], bodies, anchor_height)
        for index, anchor in enumerate(anchors, 1):
            region_id, calm, surge = storm_region(float(anchor["position"][2]))
            data["wild_clusters"].append({
                "id": f"{PREFIX}{route['id']}_{index:02d}",
                "region_id": region_id,
                "position": anchor["position"],
                "radius": 3.0,
                "calm_table_id": calm,
                "surge_table_id": surge,
                "replacement_point": f"wild_clusters.{PREFIX}{route['id']}_{index:02d}",
                "purpose": "roadside creature sightline pair",
                "_why_road_visibility_0907": "ROAD CP-2 authored pair on the critical-road shoulder. Stormwood runtime already expands every cluster to exactly two bodies.",
            })
        total += len(anchors)
    data["wild_cluster_count_contract"] = len(data["wild_clusters"])
    write(relative, data)
    return total


def author_water() -> tuple[int, int]:
    relative = "data/config/water_encounters.json"
    data = load(relative)
    data["wild_sites"] = [row for row in data["wild_sites"] if not str(row["id"]).startswith(PREFIX)]
    roster = load("data/config/water_roster.json")["species"]
    heights = {key: float(row["placeholder"]["target_height_m"]) for key, row in roster.items()}
    tables = {row["id"]: row for row in data["tables"]}
    bodies = []
    for row in data["wild_sites"]:
        height = audit.table_min(tables[row["table_id"]]["entries"], heights, "species_id", "placeholder_species")
        bodies.append(body(row["position"], height, int(row.get("count", 1))))
    world = load("data/config/water_world.json")
    islands = {row["id"]: row for row in world["islands"]}
    total = 0
    surface_total = 0
    per_island: dict[str, int] = {}
    for route in world["land_routes"]:
        if not route.get("main_path", False):
            continue
        island_id = route["island_id"]
        island = islands[island_id]
        region_id = island["region_id"]
        table_id = f"water_{island_id}_land"
        height = audit.table_min(tables[table_id]["entries"], heights, "species_id", "placeholder_species")
        anchors = add_route_anchors(route["id"], audit.points_xyz(route["polyline"]), bodies, height)
        centre = island["center_xz_m"]
        for index, anchor in enumerate(anchors, 1):
            position = anchor["position"]
            data["wild_sites"].append({
                "id": f"{PREFIX}{route['id']}_{index:02d}",
                "island_id": island_id,
                "region_id": region_id,
                "table_id": table_id,
                "island_local_offset": [round(position[0] - float(centre[0]), 3), position[1], round(position[2] - float(centre[1]), 3)],
                "position": position,
                "count": 2,
                "radius_m": 3.0,
                "habitat": "land",
                "activation_distance_m": 100,
                "roam_radius_m": 3.0,
                "purpose": "roadside creature sightline pair",
                "requires_aquatic_combat": False,
                "placement_status": "route_surface_authored_runtime_grounding_required",
                "_why_road_visibility_0907": "ROAD CP-2 authored pair on a main land-spine shoulder. Uses the island's native land table; the runtime adapter regrounds the centre.",
            })
        per_island[island_id] = per_island.get(island_id, 0) + len(anchors)
        total += len(anchors)
    for route in world["water_routes"]:
        if not route.get("main_path", False):
            continue
        island_id = route["from_island"]
        island = islands[island_id]
        region_id = island["region_id"]
        table_id = f"water_{island_id}_shallows"
        height = audit.table_min(tables[table_id]["entries"], heights, "species_id", "placeholder_species")
        anchors = add_route_anchors(route["id"], audit.points_xyz(route["polyline"]), bodies, height)
        centre = island["center_xz_m"]
        for index, anchor in enumerate(anchors, 1):
            position = [anchor["position"][0], 0.0, anchor["position"][2]]
            data["wild_sites"].append({
                "id": f"{PREFIX}{route['id']}_{index:02d}",
                "island_id": island_id,
                "region_id": region_id,
                "route_edge_id": route["edge_id"],
                "table_id": table_id,
                "island_local_offset": [round(position[0] - float(centre[0]), 3), 0.0, round(position[2] - float(centre[1]), 3)],
                "position": position,
                "count": 2,
                "radius_m": 6.0,
                "habitat": "open_water",
                "placement_mode": "water_surface",
                "surface_y_m": 0.0,
                "surface_submerge_fraction": 0.28,
                "activation_distance_m": 100,
                "roam_radius_m": 6.0,
                "purpose": "surface creature sightline pair beside main sailing route",
                "requires_aquatic_combat": True,
                "placement_status": "authored_surface_runtime_tether_required",
                "_why_road_visibility_0907": "ROAD CP-2 surface pair for a main sailing choice. The pair uses explicit host-owned surface placement and remains peaceful/off the exact route line; no seabed grounding or global draw-distance increase.",
            })
        per_island[island_id] = per_island.get(island_id, 0) + len(anchors)
        surface_total += len(anchors)
    census = data.get("census", {})
    census["wild_clusters"] = len(data["wild_sites"])
    census["road_visibility_land_pairs"] = total
    census["road_visibility_surface_pairs"] = surface_total
    census["per_island"] = {}
    census["dry_clusters"] = 0
    census["shallow_clusters"] = 0
    census["surface_clusters"] = 0
    for site in data["wild_sites"]:
        island_id = str(site.get("island_id", ""))
        census["per_island"][island_id] = int(census["per_island"].get(island_id, 0)) + 1
        habitat = str(site.get("habitat", ""))
        if habitat == "open_water":
            census["surface_clusters"] += 1
        elif habitat == "shallows":
            census["shallow_clusters"] += 1
        else:
            census["dry_clusters"] += 1
    census["runtime_spawned_verified"] = 0
    data["census"] = census
    data["validation_limitations"] = [
        row for row in data.setdefault("validation_limitations", [])
        if not str(row).startswith("ROAD land-spine pairs are route-surface authored")
    ]
    limitation = "ROAD land-spine pairs are route-surface authored and require fresh runtime grounding/navigation proof. Open-water pairs use explicit surface placement and require fresh runtime settle/combat proof."
    if limitation not in data.setdefault("validation_limitations", []):
        data["validation_limitations"].append(limitation)
    write(relative, data)
    return total, surface_total


def main() -> int:
    species_rows = load("data/creatures/species.json")["species"]
    heights = {key: float(row["placeholder"]["height"]) for key, row in species_rows.items()}
    water_land, water_surface = author_water()
    counts = {
        "meadows": author_meadows(heights),
        "cloudreach": author_cloudreach(heights),
        "stormwood": author_stormwood(heights),
        "water_land": water_land,
        "water_surface": water_surface,
    }
    print(json.dumps(counts, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
