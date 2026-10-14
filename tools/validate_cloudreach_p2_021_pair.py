#!/usr/bin/env python3
"""Validate the exact four-leg F40/P2-021 Cloudreach evidence set."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
import sys
import zlib
from pathlib import Path
from typing import Any

TIMES = ("dawn", "day", "golden", "night")
WEATHER = ("clear", "rain")
VIEWS = ("approach", "gameplay", "reverse", "detail")
COUNT = 384
PNG = b"\x89PNG\r\n\x1a\n"
HEX40 = re.compile(r"^[0-9a-f]{40}$")
HEX64 = re.compile(r"^[0-9a-f]{64}$")
MATCHED = ("destination_index", "position_xz", "view_heading_deg", "time", "weather",
           "view", "player_position", "camera_position", "camera_rig_transform",
           "camera_transform", "camera_player_distance_m", "observed_clock",
           "observed_weather", "on_floor")


class ReceiptError(ValueError):
    pass


def require(ok: bool, message: str) -> None:
    if not ok:
        raise ReceiptError(message)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def validate_png(path: Path, label: str) -> str:
    try:
        data = path.read_bytes()
    except OSError as exc:
        raise ReceiptError(f"{label} image unavailable at {path}: {exc}") from exc
    require(data.startswith(PNG), f"{label} image is not a PNG")
    cursor, width, height, saw_idat, saw_iend = len(PNG), 0, 0, False, False
    while cursor + 12 <= len(data):
        size = struct.unpack(">I", data[cursor:cursor + 4])[0]
        end = cursor + 12 + size
        require(end <= len(data), f"{label} PNG has a truncated chunk")
        kind, payload = data[cursor + 4:cursor + 8], data[cursor + 8:cursor + 8 + size]
        expected_crc = struct.unpack(">I", data[cursor + 8 + size:end])[0]
        require(zlib.crc32(kind + payload) & 0xffffffff == expected_crc,
                f"{label} PNG chunk CRC is invalid")
        if kind == b"IHDR":
            require(size == 13 and cursor == len(PNG), f"{label} PNG has an invalid IHDR")
            width, height = struct.unpack(">II", payload[:8])
        elif kind == b"IDAT":
            saw_idat = True
        elif kind == b"IEND":
            require(size == 0 and end == len(data), f"{label} PNG has an invalid IEND/trailing bytes")
            saw_iend = True
            break
        cursor = end
    require((width, height) == (1920, 1080), f"{label} PNG is {width}x{height}, expected 1920x1080")
    require(saw_idat and saw_iend, f"{label} PNG lacks image data or IEND")
    return hashlib.sha256(data).hexdigest()


def image_path(value: Any, project_root: Path, manifest: Path) -> Path:
    require(isinstance(value, str) and bool(value), f"invalid image path in {manifest}")
    if value.startswith("res://"):
        return project_root / value[6:]
    path = Path(value)
    return path if path.is_absolute() else manifest.parent / path


def read_leg(path: Path, variant: str, preset: str, project_root: Path,
             expected_source: str) -> tuple[dict[str, Any], dict[str, dict[str, Any]]]:
    try:
        manifest = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ReceiptError(f"cannot read {variant}/{preset} manifest {path}: {exc}") from exc
    require(isinstance(manifest, dict), f"{variant}/{preset} manifest root is not an object")
    require(manifest.get("complete") is True and manifest.get("failures") == [],
            f"{variant}/{preset} capture is incomplete or contains failures")
    graphics = manifest.get("graphics_capture")
    require(isinstance(graphics, dict), f"{variant}/{preset} has no graphics receipt")
    require(graphics.get("preset") == preset and graphics.get("renderer") == "forward_plus",
            f"{variant}/{preset} renderer/preset mismatch")
    require(graphics.get("resolution") == [1920, 1080]
            and manifest.get("resolution") == [1920, 1080],
            f"{variant}/{preset} is not 1920x1080")
    require(graphics.get("source_commit") == expected_source and HEX40.fullmatch(expected_source),
            f"{variant}/{preset} source pin differs from requested {expected_source}")
    require(HEX64.fullmatch(str(graphics.get("graphics_config_sha256", ""))),
            f"{variant}/{preset} graphics config hash is invalid")
    require(isinstance(graphics.get("adapter"), str) and graphics["adapter"].strip(),
            f"{variant}/{preset} adapter receipt is missing")
    require(manifest.get("biome_id") == "cloudreach", f"{variant}/{preset} is not Cloudreach")

    candidate = variant == "p2_021_candidate"
    require(manifest.get("candidate_preview") is candidate,
            f"{variant}/{preset} candidate_preview does not match variant")
    require(manifest.get("p2_021_open_terrain_candidate_preview") is candidate,
            f"{variant}/{preset} P2-021 preview flag does not match variant")
    for flag in ("f40_visual_candidate_preview", "p2_030_surface_candidate_preview"):
        require(manifest.get(flag) is False, f"{variant}/{preset} has unrelated candidate flag {flag}")
    require(manifest.get("p2_033_pickup_candidate_preview") is False,
            f"{variant}/{preset} has unrelated P2-033 candidate flag")
    for key in ("candidate_config_sha256", "p2_021_candidate_config_sha256"):
        require(HEX64.fullmatch(str(manifest.get(key, ""))),
                f"{variant}/{preset} has invalid {key}")
    require(isinstance(manifest.get("f40_revision"), str) and manifest["f40_revision"].strip(),
            f"{variant}/{preset} has no F40 revision")
    save = manifest.get("f40_isolated_save_fixture")
    require(isinstance(save, str) and save.startswith("user://f40_capture_") and save.endswith("/"),
            f"{variant}/{preset} lacks an isolated capture save")

    plan = manifest.get("capture_plan")
    require(isinstance(plan, dict), f"{variant}/{preset} has no capture plan")
    require(plan.get("times") == list(TIMES) and plan.get("weather") == list(WEATHER)
            and plan.get("views") == list(VIEWS), f"{variant}/{preset} matrix sets differ")
    require(plan.get("minimum_frames") == COUNT and plan.get("weather_settle_frames", 0) >= 24,
            f"{variant}/{preset} plan requires wrong frame count or weather settling")
    ids, frames = manifest.get("planned_frame_ids"), manifest.get("frames")
    require(isinstance(ids, list) and isinstance(frames, list)
            and len(ids) == COUNT and len(frames) == COUNT,
            f"{variant}/{preset} does not contain exactly 384 planned and captured frames")
    require(manifest.get("planned_frame_count") == COUNT
            and manifest.get("captured_frame_count") == COUNT,
            f"{variant}/{preset} frame counters differ from 384")
    require(all(isinstance(frame_id, str) and frame_id for frame_id in ids)
            and len(set(ids)) == COUNT, f"{variant}/{preset} frame IDs are empty or duplicated")
    require([row.get("frame_id") for row in frames if isinstance(row, dict)] == ids,
            f"{variant}/{preset} captured IDs do not match planned order")

    expected = {(d, t, w, v) for d in range(1, 13) for t in TIMES for w in WEATHER for v in VIEWS}
    found: set[tuple[int, str, str, str]] = set()
    records: dict[str, dict[str, Any]] = {}
    for row in frames:
        require(isinstance(row, dict), f"{variant}/{preset} has malformed frame metadata")
        frame_id = row.get("frame_id")
        key = (row.get("destination_index"), row.get("time"), row.get("weather"), row.get("view"))
        require(key in expected, f"{variant}/{preset} invalid matrix coordinates for {frame_id}")
        require(key not in found, f"{variant}/{preset} duplicate matrix coordinates {key}")
        found.add(key)
        require(row.get("observed_weather") == row.get("weather") and row.get("on_floor") is True,
                f"{variant}/{preset} weather/ground observation failed for {frame_id}")
        clock = row.get("observed_clock")
        require(isinstance(clock, dict), f"{variant}/{preset} has no observed clock for {frame_id}")
        observed_time = clock.get("time_of_day", clock.get("requested", clock.get("time")))
        require(observed_time == row.get("time"),
                f"{variant}/{preset} observed time {observed_time!r} differs at {frame_id}")
        image = image_path(row.get("file"), project_root, path)
        image_sha = validate_png(image, f"{variant}/{preset}/{frame_id}")
        records[frame_id] = {"variant": variant, "preset": preset, "frame_id": frame_id,
                             "png_sha256": image_sha, "image": str(image.resolve()),
                             "destination_index": key[0], "time": key[1], "weather": key[2], "view": key[3]}
    require(found == expected, f"{variant}/{preset} misses rows in the complete 12x4x2x4 matrix")
    return manifest, records


def validate(args: argparse.Namespace) -> dict[str, Any]:
    expected_source = args.source_commit.lower()
    require(HEX40.fullmatch(expected_source) is not None, "--source-commit must be a full lowercase 40-hex SHA")
    manifests = {
        ("baseline", "High"): args.baseline_high,
        ("baseline", "Medium"): args.baseline_medium,
        ("p2_021_candidate", "High"): args.candidate_high,
        ("p2_021_candidate", "Medium"): args.candidate_medium,
    }
    legs: dict[tuple[str, str], dict[str, Any]] = {}
    frame_rows: dict[tuple[str, str], dict[str, dict[str, Any]]] = {}
    records: dict[tuple[str, str], dict[str, dict[str, Any]]] = {}
    for key, path in manifests.items():
        legs[key], records[key] = read_leg(path, key[0], key[1], args.project_root, expected_source)
        frame_rows[key] = {row["frame_id"]: row for row in legs[key]["frames"]}

    baseline_pin: tuple[Any, ...] | None = None
    all_ids: set[str] | None = None
    for variant in ("baseline", "p2_021_candidate"):
        high, medium = legs[(variant, "High")], legs[(variant, "Medium")]
        for field in ("candidate_config_sha256", "p2_021_candidate_config_sha256", "f40_revision",
                      "capture_plan", "planned_frame_ids"):
            require(high.get(field) == medium.get(field), f"{variant} High/Medium {field} differs")
        for field in ("source_commit", "graphics_config_sha256", "adapter"):
            require(high["graphics_capture"].get(field) == medium["graphics_capture"].get(field),
                    f"{variant} High/Medium graphics {field} differs")
        require(high.get("f40_isolated_save_fixture") != medium.get("f40_isolated_save_fixture"),
                f"{variant} High and Medium reused an isolated save fixture")
        if all_ids is None:
            all_ids = set(records[(variant, "High")])
        require(set(records[(variant, "High")]) == all_ids == set(records[(variant, "Medium")]),
                f"{variant} frame ID coverage differs")
        for frame_id in all_ids:
            for field in MATCHED:
                hrow = frame_rows[(variant, "High")][frame_id]
                mrow = frame_rows[(variant, "Medium")][frame_id]
                require(hrow.get(field) == mrow.get(field), f"{variant} High/Medium {field} differs for {frame_id}")
        pin = (high["graphics_capture"]["source_commit"], high["graphics_capture"]["graphics_config_sha256"],
               high.get("candidate_config_sha256"), high.get("p2_021_candidate_config_sha256"),
               high.get("f40_revision"), high.get("capture_plan"), high.get("planned_frame_ids"))
        if baseline_pin is None:
            baseline_pin = pin
        else:
            require(pin == baseline_pin, "baseline and candidate source/config/plan pins differ")
    # Pairing requires the same stand/time/weather/frame map in both variants.
    for frame_id in all_ids or ():
        for preset in ("High", "Medium"):
            b = frame_rows[("baseline", preset)][frame_id]
            c = frame_rows[("p2_021_candidate", preset)][frame_id]
            for field in MATCHED:
                require(b.get(field) == c.get(field), f"baseline/candidate {field} differs for {preset}/{frame_id}")
    return {"schema": "cloudreach-p2-021-four-leg-audit-v1", "complete": True,
            "source_commit": expected_source, "expected_frames_per_leg": COUNT,
            "validator_sha256": sha256(Path(__file__).resolve()),
            "legs": {f"{variant}/{preset}": {"manifest": str(path.resolve()),
                    "manifest_sha256": sha256(path), "frame_ids": sorted(records[(variant, preset)]),
                    "frames": records[(variant, preset)]}
                     for (variant, preset), path in manifests.items()}}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", type=Path, required=True)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--output", type=Path, required=True, help="fresh audit JSON output")
    parser.add_argument("baseline_high", type=Path)
    parser.add_argument("baseline_medium", type=Path)
    parser.add_argument("candidate_high", type=Path)
    parser.add_argument("candidate_medium", type=Path)
    args = parser.parse_args()
    try:
        require(not args.output.exists(), f"audit output already exists: {args.output}")
        audit = validate(args)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("x", encoding="utf-8", newline="\n") as stream:
            json.dump(audit, stream, indent=2, sort_keys=True)
            stream.write("\n")
    except (ReceiptError, OSError) as exc:
        print(f"P2-021 FOUR-LEG FAIL: {exc}", file=sys.stderr)
        return 1
    print(f"P2-021 FOUR-LEG PASS: 4 x {COUNT} matched frames; source {audit['source_commit']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
