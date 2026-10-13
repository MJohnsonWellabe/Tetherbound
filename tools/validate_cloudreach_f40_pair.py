#!/usr/bin/env python3
"""Validate the High/Medium F40 Cloudreach catalogue capture pair."""

from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path
from typing import Any


EXPECTED_TIMES = ["dawn", "day", "golden", "night"]
EXPECTED_WEATHER = ["clear", "rain"]
EXPECTED_VIEWS = ["approach", "gameplay", "reverse", "detail"]
EXPECTED_DESTINATIONS = 12
EXPECTED_FRAMES = 384
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
MATCHED_FRAME_FIELDS = (
    "destination_index",
    "position_xz",
    "view_heading_deg",
    "time",
    "weather",
    "view",
    "player_position",
    "camera_position",
    "camera_rig_transform",
    "camera_transform",
    "camera_player_distance_m",
    "observed_clock",
    "observed_weather",
    "on_floor",
)


class ValidationError(Exception):
    pass


def fail(message: str) -> None:
    raise ValidationError(message)


def is_hex_digest(value: Any, length: int) -> bool:
    return (isinstance(value, str) and len(value) == length
            and all(character in "0123456789abcdef" for character in value))


def load_manifest(path: Path, expected_preset: str) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot read {expected_preset} manifest {path}: {exc}")
    if not isinstance(value, dict):
        fail(f"{expected_preset} manifest root is not an object")
    if value.get("complete") is not True or value.get("failures") != []:
        fail(f"{expected_preset} capture is incomplete or reports failures")
    graphics = value.get("graphics_capture")
    if not isinstance(graphics, dict):
        fail(f"{expected_preset} manifest has no graphics_capture receipt")
    if graphics.get("preset") != expected_preset:
        fail(f"expected preset {expected_preset}, found {graphics.get('preset')!r}")
    if graphics.get("renderer") != "forward_plus":
        fail(f"{expected_preset} did not use Forward+")
    if graphics.get("resolution") != [1920, 1080] or value.get("resolution") != [1920, 1080]:
        fail(f"{expected_preset} did not capture at 1920x1080")
    if not is_hex_digest(graphics.get("source_commit"), 40):
        fail(f"{expected_preset} has no valid pinned source commit")
    if not is_hex_digest(graphics.get("graphics_config_sha256"), 64):
        fail(f"{expected_preset} has no valid graphics configuration hash")
    if not isinstance(graphics.get("adapter"), str) or not graphics["adapter"].strip():
        fail(f"{expected_preset} has no graphics adapter receipt")
    if value.get("biome_id") != "cloudreach":
        fail(f"{expected_preset} manifest is not for Cloudreach")
    if value.get("candidate_preview") is not False:
        fail(f"{expected_preset} capture is not the default production presentation")
    plan = value.get("capture_plan")
    if not isinstance(plan, dict):
        fail(f"{expected_preset} manifest has no capture plan")
    if not is_hex_digest(value.get("candidate_config_sha256"), 64):
        fail(f"{expected_preset} has no valid F40 configuration hash")
    if not isinstance(value.get("f40_revision"), str) or not value["f40_revision"].strip():
        fail(f"{expected_preset} has no F40 revision receipt")
    save_fixture = value.get("f40_isolated_save_fixture")
    if not isinstance(save_fixture, str) or not save_fixture.startswith("user://f40_capture_"):
        fail(f"{expected_preset} has no isolated F40 capture save")
    for key, expected in (("times", EXPECTED_TIMES), ("weather", EXPECTED_WEATHER), ("views", EXPECTED_VIEWS)):
        if plan.get(key) != expected:
            fail(f"{expected_preset} capture plan {key} differs from the required matrix")
    if int(plan.get("minimum_frames", 0)) < 200:
        fail(f"{expected_preset} capture plan requires fewer than 200 frames")
    if int(plan.get("weather_settle_frames", 0)) < 24:
        fail(f"{expected_preset} capture plan settles weather for fewer than 24 frames")

    planned = value.get("planned_frame_ids")
    frames = value.get("frames")
    count = value.get("planned_frame_count")
    if not isinstance(planned, list) or not isinstance(frames, list):
        fail(f"{expected_preset} manifest has no planned or captured frame list")
    if count != EXPECTED_FRAMES or len(planned) != EXPECTED_FRAMES:
        fail(f"{expected_preset} planned {count!r} frames; expected exactly {EXPECTED_FRAMES}")
    if value.get("captured_frame_count") != EXPECTED_FRAMES or len(frames) != EXPECTED_FRAMES:
        fail(f"{expected_preset} did not capture exactly {EXPECTED_FRAMES} frames")
    if len(set(planned)) != EXPECTED_FRAMES:
        fail(f"{expected_preset} planned frame IDs contain duplicates")
    captured_ids = [row.get("frame_id") for row in frames if isinstance(row, dict)]
    if captured_ids != planned:
        fail(f"{expected_preset} captured frame IDs do not exactly match the plan")
    expected_rows = {
        (destination, time_name, weather_name, view_name)
        for destination in range(1, EXPECTED_DESTINATIONS + 1)
        for time_name in EXPECTED_TIMES
        for weather_name in EXPECTED_WEATHER
        for view_name in EXPECTED_VIEWS
    }
    actual_rows: set[tuple[int, str, str, str]] = set()
    for row in frames:
        if not isinstance(row, dict):
            fail(f"{expected_preset} contains a malformed frame receipt")
        destination = row.get("destination_index")
        time_name = row.get("time")
        weather_name = row.get("weather")
        view_name = row.get("view")
        if (not isinstance(destination, int) or isinstance(destination, bool)
                or not isinstance(time_name, str) or not isinstance(weather_name, str)
                or not isinstance(view_name, str)):
            fail(f"{expected_preset} has invalid matrix metadata for {row.get('frame_id')}")
        actual_rows.add((destination, time_name, weather_name, view_name))
        if row.get("observed_weather") != row.get("weather"):
            fail(f"{expected_preset} weather did not match for {row.get('frame_id')}")
        if row.get("on_floor") is not True:
            fail(f"{expected_preset} trainer was not grounded for {row.get('frame_id')}")
    if actual_rows != expected_rows:
        fail(f"{expected_preset} does not contain the complete 12-destination time/weather/view matrix")
    return value


def resolve_image(path_value: Any, project_root: Path, manifest_path: Path) -> Path:
    if not isinstance(path_value, str) or not path_value:
        fail(f"invalid image path in {manifest_path}")
    if path_value.startswith("res://"):
        return project_root / path_value[6:]
    path = Path(path_value)
    return path if path.is_absolute() else manifest_path.parent / path


def verify_png(path: Path, expected: str) -> None:
    try:
        with path.open("rb") as stream:
            header = stream.read(24)
    except OSError as exc:
        fail(f"{expected} image is missing or unreadable at {path}: {exc}")
    if len(header) != 24 or header[:8] != PNG_SIGNATURE or header[12:16] != b"IHDR":
        fail(f"{expected} image has an invalid PNG header: {path}")
    width, height = struct.unpack(">II", header[16:24])
    if (width, height) != (1920, 1080):
        fail(f"{expected} image is {width}x{height}, expected 1920x1080: {path}")


def compare_pair(high: dict[str, Any], medium: dict[str, Any], high_path: Path,
                 medium_path: Path, project_root: Path) -> None:
    high_graphics = high["graphics_capture"]
    medium_graphics = medium["graphics_capture"]
    for field in ("source_commit", "graphics_config_sha256", "adapter"):
        if high_graphics.get(field) != medium_graphics.get(field):
            fail(f"High and Medium {field} pins differ")
    for field in ("candidate_config_sha256", "f40_revision", "capture_plan", "planned_frame_ids"):
        if high.get(field) != medium.get(field):
            fail(f"High and Medium {field} values differ")
    if high.get("f40_isolated_save_fixture") == medium.get("f40_isolated_save_fixture"):
        fail("High and Medium did not use separate isolated save fixtures")

    high_frames = {row["frame_id"]: row for row in high["frames"]}
    medium_frames = {row["frame_id"]: row for row in medium["frames"]}
    if high_frames.keys() != medium_frames.keys():
        fail("High and Medium frame ID sets differ")
    for frame_id in high["planned_frame_ids"]:
        high_row = high_frames[frame_id]
        medium_row = medium_frames[frame_id]
        for field in MATCHED_FRAME_FIELDS:
            if high_row.get(field) != medium_row.get(field):
                fail(f"High and Medium {field} differs for {frame_id}")
        verify_png(resolve_image(high_row.get("file"), project_root, high_path), f"High {frame_id}")
        verify_png(resolve_image(medium_row.get("file"), project_root, medium_path), f"Medium {frame_id}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", type=Path, required=True,
                        help="Godot project root used by the capture runs")
    parser.add_argument("high_manifest", type=Path)
    parser.add_argument("medium_manifest", type=Path)
    args = parser.parse_args()
    try:
        high = load_manifest(args.high_manifest, "High")
        medium = load_manifest(args.medium_manifest, "Medium")
        compare_pair(high, medium, args.high_manifest, args.medium_manifest,
                     args.project_root)
    except ValidationError as exc:
        print(f"F40 PAIR FAIL: {exc}", file=sys.stderr)
        return 1
    sha = high["graphics_capture"]["source_commit"]
    print(f"F40 PAIR PASS: {EXPECTED_FRAMES} matched High/Medium frames; source {sha}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
