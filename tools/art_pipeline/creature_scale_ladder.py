#!/usr/bin/env python3
"""Apply/check the owner-directed four-biome creature scale ladder.

The 1.80 m trainer is fixed. Every creature is deliberately larger: the
smallest class begins at 1.90 m, medium bodies clear 2.30 m, large bodies
clear 3.25 m, and regional apex/legendary bodies reach 4.15-7.20 m.

Radii and mount geometry move by the same ratio as height so the rendered
body, collision, hit/catch reach, rider seat and dismount clearance remain
one physical fact. This tool is idempotent and refuses an incomplete roster.
"""
from __future__ import annotations

import argparse
import json
import math
import os
import struct
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPECIES_PATH = ROOT / "data" / "creatures" / "species.json"
WATER_ROSTER_PATH = ROOT / "data" / "config" / "water_roster.json"
WATER_MOUNTS_PATH = ROOT / "data" / "config" / "water_mounts.json"
TRAINER_HEIGHT_M = 1.80
DEFAULT_FOOTPRINT_ALLOWANCE = 2.4


TARGET_HEIGHTS = {
    "pipwing": 1.90,
    "sparkit": 1.95,
    "mudsnout": 2.00,
    "bramblebun": 2.05,
    "brooktail": 2.10,
    "paddlenewt": 2.15,
    "riftfrill": 2.15,
    "duskhush": 2.30,
    "trailpup": 2.30,
    "cindercub": 2.50,
    "mosshell": 2.50,
    "stormtrail": 2.55,
    "reedwing": 2.65,
    "mirejaw": 2.80,
    "shadelet": 2.80,
    "thundertunnel": 2.80,
    "burrowback": 2.95,
    "cragclaw": 2.95,
    "mosshock": 2.95,
    "glimmermoth": 3.10,
    "breezetail": 3.25,
    "cliffspike": 3.25,
    "galewisp": 3.25,
    "pebbik": 3.25,
    "sirenseal": 3.25,
    "skyrill": 3.25,
    "staticub": 3.25,
    "stormbrush": 3.25,
    "torrentoad": 3.25,
    "voltwig": 3.25,
    "aquaryn": 3.40,
    "frostclaw": 3.40,
    "mangrove_monitor": 3.40,
    "stormraven": 3.40,
    "tanglevolt": 3.40,
    "meadowhart": 3.45,
    "craghorn": 3.50,
    "galecrest": 3.50,
    "nightburrow": 3.50,
    "ashtusk": 3.60,
    "ripplet": 3.60,
    "tuskroot": 3.60,
    "cannonback": 3.70,
    "ribbonray": 3.70,
    "cloudfang": 3.85,
    "stormcapra": 3.85,
    "terrapup": 3.85,
    "aeriex": 4.00,
    "riverdrake": 4.00,
    "tempestwing": 4.15,
    "riptusk": 4.25,
    "voltarach": 4.25,
    "fulgocobra": 5.20,
    "tidecoil": 5.50,
    "veridian": 5.80,
    "solmane": 6.70,
    "abyssal_guardian": 7.20,
}


WATER_TARGET_HEIGHTS = {
    "cannonback": 4.15,
    "riptusk": 4.45,
    "aquaryn": 5.00,
    "tidecoil": 5.50,
    "mirejaw": 3.55,
    "torrentoad": 3.70,
    "cragclaw": 3.70,
    "riverdrake": 4.15,
    "sirenseal": 3.70,
    "mangrove_monitor": 3.85,
    "mosshell": 2.50,
    "abyssal_guardian": 7.20,
}

# CreatureBody intentionally clamps long/wide meshes to a per-species
# footprint allowance. These values are measured facts about the installed
# silhouettes, not a way around the fit: each is the smallest rounded-up
# allowance that lets the rendered mesh reach its declared height. Water
# namespaced bodies inherit the source species' allowance, hence the four
# Meadows source bodies in this map.
FIT_ALLOWANCE_OVERRIDES = {
    "bramblebun": 5.8,
    "brooktail": 8.6,
    "galewisp": 4.5,
    "mosshell": 5.8,
    "paddlenewt": 4.8,
    "ripplet": 3.6,
    "mirejaw": 4.5,
    "riverdrake": 3.2,
    "sirenseal": 3.5,
    "mangrove_monitor": 3.8,
    "abyssal_guardian": 3.7,
    "mosshock": 3.2,
    "fulgocobra": 3.8,
    "stormbrush": 3.2,
    "tanglevolt": 3.4,
    "skyrill": 5.8,
}


def _load(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _write(path: Path, payload: dict) -> None:
    fd, temporary = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(payload, handle, indent=2, ensure_ascii=True)
            handle.write("\n")
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def _scale_vector(raw: list, factor: float) -> list:
    return [round(float(value) * factor, 6) for value in raw]


def _matmul(a: list[list[float]], b: list[list[float]]) -> list[list[float]]:
    return [[sum(a[row][k] * b[k][col] for k in range(4)) for col in range(4)] for row in range(4)]


def _node_matrix(node: dict) -> list[list[float]]:
    if "matrix" in node:
        raw = node["matrix"]
        return [[float(raw[col * 4 + row]) for col in range(4)] for row in range(4)]
    tx, ty, tz = (list(node.get("translation", [0, 0, 0])) + [0, 0, 0])[:3]
    sx, sy, sz = (list(node.get("scale", [1, 1, 1])) + [1, 1, 1])[:3]
    x, y, z, w = (list(node.get("rotation", [0, 0, 0, 1])) + [0, 0, 0, 1])[:4]
    rotation = [
        [1 - 2*y*y - 2*z*z, 2*x*y - 2*z*w, 2*x*z + 2*y*w, 0],
        [2*x*y + 2*z*w, 1 - 2*x*x - 2*z*z, 2*y*z - 2*x*w, 0],
        [2*x*z - 2*y*w, 2*y*z + 2*x*w, 1 - 2*x*x - 2*y*y, 0],
        [0, 0, 0, 1],
    ]
    scale = [[sx, 0, 0, 0], [0, sy, 0, 0], [0, 0, sz, 0], [0, 0, 0, 1]]
    result = _matmul(rotation, scale)
    result[0][3], result[1][3], result[2][3] = float(tx), float(ty), float(tz)
    return result


def _transform(matrix: list[list[float]], point: tuple[float, float, float]) -> tuple[float, float, float]:
    values = (*point, 1.0)
    return tuple(sum(matrix[row][col] * values[col] for col in range(4)) for row in range(3))


def _glb_bounds(path: Path) -> tuple[list[float], list[float]]:
    """Rest-pose bounds matching CreatureBody's imported-model fit inputs.

    Installed creature GLBs carry accessor min/max and unit-scale skins. Node
    transforms are still applied recursively so a non-unit mesh node cannot
    make a declared height look safer than its fitted world result.
    """
    raw = path.read_bytes()
    if len(raw) < 20 or struct.unpack_from("<I", raw, 0)[0] != 0x46546C67:
        raise ValueError(f"not a GLB: {path}")
    chunk_length, chunk_type = struct.unpack_from("<II", raw, 12)
    if chunk_type != 0x4E4F534A:
        raise ValueError(f"GLB JSON chunk missing: {path}")
    gltf = json.loads(raw[20:20 + chunk_length])
    identity = [[1.0 if row == col else 0.0 for col in range(4)] for row in range(4)]
    low = [math.inf, math.inf, math.inf]
    high = [-math.inf, -math.inf, -math.inf]

    def visit(index: int, parent: list[list[float]]) -> None:
        node = gltf["nodes"][index]
        world = _matmul(parent, _node_matrix(node))
        if "mesh" in node:
            mesh = gltf["meshes"][node["mesh"]]
            for primitive in mesh.get("primitives", []):
                accessor_index = primitive.get("attributes", {}).get("POSITION")
                if accessor_index is None:
                    continue
                accessor = gltf["accessors"][accessor_index]
                if "min" not in accessor or "max" not in accessor:
                    raise ValueError(f"POSITION accessor lacks bounds: {path}")
                minimum, maximum = accessor["min"], accessor["max"]
                for mask in range(8):
                    corner = tuple(float(maximum[axis] if mask & (1 << axis) else minimum[axis]) for axis in range(3))
                    transformed = _transform(world, corner)
                    for axis in range(3):
                        low[axis] = min(low[axis], transformed[axis])
                        high[axis] = max(high[axis], transformed[axis])
        for child in node.get("children", []):
            visit(int(child), world)

    child_nodes = {int(child) for node in gltf.get("nodes", []) for child in node.get("children", [])}
    roots = gltf.get("scenes", [{}])[int(gltf.get("scene", 0))].get("nodes", [])
    if not roots:
        roots = [index for index in range(len(gltf.get("nodes", []))) if index not in child_nodes]
    for root in roots:
        visit(int(root), identity)
    if not all(math.isfinite(value) for value in low + high):
        raise ValueError(f"no measurable mesh bounds: {path}")
    return low, [high[axis] - low[axis] for axis in range(3)]


def _fitted_height(species_id: str, look: dict, target_height: float, radius: float) -> dict:
    model_path = ROOT / str(look["model"]).replace("res://", "")
    _position, size = _glb_bounds(model_path)
    footprint = max(size[0], size[2])
    fit = target_height / size[1]
    allowance = float(look.get("footprint_allowance", DEFAULT_FOOTPRINT_ALLOWANCE))
    allowed = (radius * 2.0 * allowance) / footprint if footprint > 0.0001 else fit
    applied = min(fit, allowed) * max(float(look.get("model_scale", 1.0)), 0.01)
    return {
        "source_bounds_m": [round(value, 6) for value in size],
        "footprint_allowance": allowance,
        "fit_limited_by": "footprint" if allowed < fit else "height",
        "fitted_render_height_m": round(size[1] * applied, 6),
        "fitted_render_width_m": round(size[0] * applied, 6),
        "fitted_render_depth_m": round(size[2] * applied, 6),
    }


def apply_scale(species_data: dict, water_roster: dict, water_mounts: dict) -> list[dict]:
    species = species_data["species"]
    if set(species) != set(TARGET_HEIGHTS):
        missing = sorted(set(species) - set(TARGET_HEIGHTS))
        stale = sorted(set(TARGET_HEIGHTS) - set(species))
        raise ValueError(f"scale roster mismatch: missing targets={missing}, stale targets={stale}")

    changes: list[dict] = []
    for species_id, target in TARGET_HEIGHTS.items():
        look = species[species_id]["placeholder"]
        before = float(look["height"])
        factor = target / before
        if abs(factor - 1.0) > 1e-9:
            look["height"] = target
            look["radius"] = round(float(look["radius"]) * factor, 6)
            rideable = species[species_id].get("rideable")
            if isinstance(rideable, dict):
                if isinstance(rideable.get("mount_offset"), list):
                    rideable["mount_offset"] = _scale_vector(rideable["mount_offset"], factor)
                if "dismount_distance" in rideable:
                    rideable["dismount_distance"] = round(
                        float(rideable["dismount_distance"]) * factor, 6
                    )
        if species_id in FIT_ALLOWANCE_OVERRIDES:
            look["footprint_allowance"] = FIT_ALLOWANCE_OVERRIDES[species_id]
        changes.append({
            "id": species_id,
            "before_height_m": before,
            "after_height_m": target,
            "scale": round(factor, 6),
            "after_radius_m": float(look["radius"]),
        })

    water_species = water_roster["species"]
    if set(water_species) != set(WATER_TARGET_HEIGHTS):
        raise ValueError("Water scale roster does not match the twelve-species contract")
    mount_rows = water_mounts["mounts"]
    for species_id, target in WATER_TARGET_HEIGHTS.items():
        presentation = water_species[species_id]["placeholder"]
        source_id = str(presentation["source_species"])
        presentation["source_height_m"] = float(species[source_id]["placeholder"]["height"])
        before = float(presentation["target_height_m"])
        factor = target / before
        presentation["target_height_m"] = target
        runtime_id = "water_" + species_id
        if runtime_id in mount_rows and abs(factor - 1.0) > 1e-9:
            geometry = mount_rows[runtime_id]
            for key in ("mount_offset", "saddle_offset"):
                geometry[key] = _scale_vector(geometry[key], factor)
            for key in ("surface_origin_offset_m", "dismount_distance"):
                geometry[key] = round(float(geometry[key]) * factor, 6)
            measurement = geometry["measurement"]
            measurement["aabb_position"] = _scale_vector(measurement["aabb_position"], factor)
            measurement["aabb_size"] = _scale_vector(measurement["aabb_size"], factor)
            measurement["collision_radius_m"] = round(
                float(measurement["collision_radius_m"]) * factor, 6
            )
        changes.append({
            "id": runtime_id,
            "before_height_m": before,
            "after_height_m": target,
            "scale": round(factor, 6),
        })
    return changes


def validate(species_data: dict, water_roster: dict) -> list[str]:
    errors: list[str] = []
    for species_id, target in TARGET_HEIGHTS.items():
        actual = float(species_data["species"][species_id]["placeholder"]["height"])
        if abs(actual - target) > 1e-6:
            errors.append(f"{species_id}: height {actual} != target {target}")
        if actual <= TRAINER_HEIGHT_M:
            errors.append(f"{species_id}: {actual}m does not clear the 1.80m trainer")
        fitted = _fitted_height(species_id, species_data["species"][species_id]["placeholder"], actual,
                                float(species_data["species"][species_id]["placeholder"]["radius"]))
        if fitted["fitted_render_height_m"] <= TRAINER_HEIGHT_M:
            errors.append(f"{species_id}: fitted render {fitted['fitted_render_height_m']}m does not clear trainer")
        if fitted["fitted_render_height_m"] < actual - 0.01:
            errors.append(f"{species_id}: fitted render {fitted['fitted_render_height_m']}m misses declared {actual}m")
    for species_id, target in WATER_TARGET_HEIGHTS.items():
        actual = float(water_roster["species"][species_id]["placeholder"]["target_height_m"])
        if abs(actual - target) > 1e-6:
            errors.append(f"water_{species_id}: height {actual} != target {target}")
        if actual <= TRAINER_HEIGHT_M:
            errors.append(f"water_{species_id}: {actual}m does not clear the 1.80m trainer")
        presentation = water_roster["species"][species_id]["placeholder"]
        source = species_data["species"][presentation["source_species"]]["placeholder"]
        source_ratio = float(source["radius"]) / float(source["height"])
        runtime_look = source.copy()
        runtime_look.update({key: presentation[key] for key in ("model", "model_scale", "model_yaw") if key in presentation})
        fitted = _fitted_height("water_" + species_id, runtime_look, actual, actual * source_ratio)
        if fitted["fitted_render_height_m"] <= TRAINER_HEIGHT_M:
            errors.append(f"water_{species_id}: fitted render {fitted['fitted_render_height_m']}m does not clear trainer")
        if fitted["fitted_render_height_m"] < actual - 0.01:
            errors.append(f"water_{species_id}: fitted render {fitted['fitted_render_height_m']}m misses declared {actual}m")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="rewrite the three scale data files")
    parser.add_argument("--report", type=Path, help="optional JSON before/after report path")
    args = parser.parse_args()

    species_data = _load(SPECIES_PATH)
    water_roster = _load(WATER_ROSTER_PATH)
    water_mounts = _load(WATER_MOUNTS_PATH)
    changes: list[dict] = []
    if args.apply:
        changes = apply_scale(species_data, water_roster, water_mounts)
        _write(SPECIES_PATH, species_data)
        _write(WATER_ROSTER_PATH, water_roster)
        _write(WATER_MOUNTS_PATH, water_mounts)
    errors = validate(species_data, water_roster)
    if args.report:
        global_fits = {}
        for species_id, row in species_data["species"].items():
            look = row["placeholder"]
            global_fits[species_id] = _fitted_height(species_id, look, float(look["height"]), float(look["radius"]))
        water_fits = {}
        for species_id, row in water_roster["species"].items():
            look = row["placeholder"]
            source = species_data["species"][look["source_species"]]["placeholder"]
            target = float(look["target_height_m"])
            runtime_look = source.copy()
            runtime_look.update({key: look[key] for key in ("model", "model_scale", "model_yaw") if key in look})
            water_fits["water_" + species_id] = _fitted_height(
                "water_" + species_id, runtime_look, target, target * float(source["radius"]) / float(source["height"]))
        args.report.parent.mkdir(parents=True, exist_ok=True)
        _write(args.report, {
            "trainer_height_m": TRAINER_HEIGHT_M,
            "changes": changes,
            "global_fitted_world_bounds": global_fits,
            "water_fitted_world_bounds": water_fits,
            "errors": errors,
        })
    if errors:
        for error in errors:
            print("ERROR:", error)
        return 1
    heights = [float(row["placeholder"]["height"]) for row in species_data["species"].values()]
    water_heights = [float(row["placeholder"]["target_height_m"]) for row in water_roster["species"].values()]
    print(
        f"creature scale ladder OK: global={len(heights)} {min(heights):.2f}-{max(heights):.2f}m; "
        f"water={len(water_heights)} {min(water_heights):.2f}-{max(water_heights):.2f}m; "
        f"trainer={TRAINER_HEIGHT_M:.2f}m"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
