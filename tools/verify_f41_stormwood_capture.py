"""Verify matched F41 Stormwood capture receipts without judging their images."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
import sys
from typing import Any


PHASES = ("calm", "building", "break", "fading")
EXPECTED_FRAMES = 200
EXPECTED_VIEWS = 50
EXPECTED_RESOLUTION = [1920, 1080]
JPEG_START_OF_FRAME = {0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF}


def _jpeg_dimensions(path: Path) -> tuple[int, int] | None:
    """Read JPEG dimensions and require a nonempty scan ending with EOI."""
    try:
        with path.open("rb") as image:
            if image.read(2) != b"\xff\xd8":
                return None
            dimensions: tuple[int, int] | None = None
            while True:
                if image.read(1) != b"\xff":
                    return None
                marker = image.read(1)
                while marker == b"\xff":
                    marker = image.read(1)
                if not marker or marker == b"\x00":
                    return None
                code = marker[0]
                if code in {0xD8, 0xD9, 0x01} or 0xD0 <= code <= 0xD7:
                    continue
                raw_length = image.read(2)
                if len(raw_length) != 2:
                    return None
                segment_length = int.from_bytes(raw_length, "big")
                payload_length = segment_length - 2
                if payload_length < 0:
                    return None
                if code in JPEG_START_OF_FRAME:
                    if payload_length < 5:
                        return None
                    raw_dimensions = image.read(5)
                    if len(raw_dimensions) != 5:
                        return None
                    height = int.from_bytes(raw_dimensions[1:3], "big")
                    width = int.from_bytes(raw_dimensions[3:5], "big")
                    if width <= 0 or height <= 0:
                        return None
                    dimensions = (width, height)
                    image.seek(payload_length - 5, 1)
                    continue
                if code == 0xDA:
                    if dimensions is None or payload_length < 6:
                        return None
                    image.seek(payload_length, 1)
                    if image.tell() >= path.stat().st_size - 2:
                        return None
                    image.seek(-2, 2)
                    if image.read(2) != b"\xff\xd9":
                        return None
                    return dimensions
                image.seek(payload_length, 1)
    except OSError:
        return None


def _read_receipt(directory: Path, label: str, preset: str, source_commit: str) -> tuple[dict[str, Any] | None, list[str]]:
    problems: list[str] = []
    path = directory / f"frames_{label}.json"
    try:
        receipt = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return None, [f"{preset}: cannot read {path}: {error}"]

    if not isinstance(receipt, dict):
        return None, [f"{preset}: receipt root is not an object"]
    if receipt.get("label") != label:
        problems.append(f"{preset}: receipt label is {receipt.get('label')!r}, expected {label!r}")
    failures = receipt.get("failures")
    if not isinstance(failures, list) or failures:
        problems.append(f"{preset}: capture reports failures: {failures!r}")

    graphics = receipt.get("graphics_capture")
    if not isinstance(graphics, dict):
        problems.append(f"{preset}: graphics capture metadata is missing")
    else:
        if graphics.get("preset") != preset:
            problems.append(f"{preset}: declared graphics preset is {graphics.get('preset')!r}")
        if graphics.get("renderer") != "forward_plus":
            problems.append(f"{preset}: renderer is {graphics.get('renderer')!r}, expected 'forward_plus'")
        if graphics.get("resolution") != EXPECTED_RESOLUTION:
            problems.append(f"{preset}: resolution is {graphics.get('resolution')!r}, expected {EXPECTED_RESOLUTION!r}")

    frames = receipt.get("frames")
    if not isinstance(frames, list):
        problems.append(f"{preset}: frames is not an array")
        return receipt, problems
    if len(frames) != EXPECTED_FRAMES:
        problems.append(f"{preset}: has {len(frames)} frames, expected {EXPECTED_FRAMES}")

    view_phase_keys: set[tuple[str, str]] = set()
    views_by_phase = {phase: set() for phase in PHASES}
    shelter_counts = {phase: {"inside": 0, "outside": 0} for phase in PHASES}
    for index, frame in enumerate(frames):
        where = f"{preset} frame {index}"
        if not isinstance(frame, dict):
            problems.append(f"{where}: frame is not an object")
            continue

        phase = frame.get("surge_phase")
        valid_phase = isinstance(phase, str) and phase in PHASES
        view_id = frame.get("f41_view_id")
        key = (str(view_id), phase if valid_phase else str(phase))
        if not valid_phase:
            problems.append(f"{where}: invalid Surge phase {phase!r}")
        if not isinstance(view_id, str) or not view_id:
            problems.append(f"{where}: missing F41 view id")
        if key in view_phase_keys:
            problems.append(f"{where}: duplicate matched view/phase pair {key!r}")
        view_phase_keys.add(key)
        if valid_phase:
            views_by_phase[phase].add(str(view_id))

        expected_id = f"{view_id}_{phase}"
        if frame.get("id") != expected_id:
            problems.append(f"{where}: id does not match its F41 view and phase")
        if frame.get("label") != label:
            problems.append(f"{where}: frame label does not match the receipt")
        if frame.get("source_commit") != source_commit:
            problems.append(f"{where}: source commit is not {source_commit}")
        if frame.get("size") != EXPECTED_RESOLUTION:
            problems.append(f"{where}: raster size is {frame.get('size')!r}, expected {EXPECTED_RESOLUTION!r}")
        if frame.get("long_storm_ended") is not False:
            problems.append(f"{where}: aftermath flag is not explicitly false")

        per_frame_graphics = frame.get("graphics_capture")
        if not isinstance(per_frame_graphics, dict) or per_frame_graphics.get("observed_preset") != preset:
            problems.append(f"{where}: observed device preset does not match {preset}")

        filename = frame.get("file")
        if not isinstance(filename, str) or Path(filename).name != filename:
            problems.append(f"{where}: unsafe or missing image filename")
        else:
            image_path = directory / filename
            if image_path.is_symlink() or not image_path.is_file() or image_path.stat().st_size == 0:
                problems.append(f"{where}: image file is missing, empty, or symlinked: {image_path}")
            else:
                dimensions = _jpeg_dimensions(image_path)
                if dimensions != tuple(EXPECTED_RESOLUTION):
                    problems.append(f"{where}: JPEG dimensions are {dimensions!r}, expected {EXPECTED_RESOLUTION!r}")

        support = frame.get("stormwood_support_receipt")
        if not isinstance(support, dict):
            problems.append(f"{where}: direct Stormwood support receipt is missing")
            continue
        if support.get("phase") != phase or support.get("phase_at_player") != phase:
            problems.append(f"{where}: direct Surge phase receipt does not match the frame")
        info = support.get("phase_info_at_player")
        if not isinstance(info, dict) or info.get("phase") != phase:
            problems.append(f"{where}: phase_info_at_player does not match the frame")
        if support.get("phase_source") != "StormwoodSurge.phase and phase_at_position(player_position)":
            problems.append(f"{where}: phase source is not the direct StormwoodSurge query")
        if support.get("weather") != ("storm" if phase == "break" else "rain"):
            problems.append(f"{where}: direct Surge weather does not match the frame")
        if support.get("weather_source") != "StormwoodSurge.weather()":
            problems.append(f"{where}: weather source is not StormwoodSurge.weather()")
        if support.get("production_camera_current") is not True:
            problems.append(f"{where}: production CameraRig is not the current camera")
        live_sheltered = support.get("stormwood_lightning_sheltered")
        cached_sheltered = support.get("surge_cached_sheltered")
        if not isinstance(live_sheltered, bool) or not isinstance(cached_sheltered, bool) \
                or live_sheltered != cached_sheltered:
            problems.append(f"{where}: live lightning shelter and cached Surge shelter disagree")
        rain_ratio = support.get("near_rain_amount_ratio")
        if not _number_in_range(rain_ratio, 0.0, 1.0):
            problems.append(f"{where}: actual near-rain emitter ratio is missing or out of range")

        case = frame.get("f41_support_case")
        shelter_case = support.get("shelter_case")
        if case == "shelter_inside":
            if valid_phase:
                shelter_counts[phase]["inside"] += 1
            if shelter_case != "inside" or support.get("surge_roofed") is not True \
                    or support.get("stormwood_lightning_sheltered") is not True:
                problems.append(f"{where}: interior roof/shelter proof failed")
            if phase == "break" and not _number_at_most(support.get("near_rain_amount_ratio"), 0.05):
                problems.append(f"{where}: Break near rain was not suppressed inside")
        elif case == "shelter_outside":
            if valid_phase:
                shelter_counts[phase]["outside"] += 1
            if shelter_case != "outside" or support.get("surge_roofed") is not False \
                    or support.get("stormwood_lightning_sheltered") is not False:
                problems.append(f"{where}: exterior unexpectedly received roof/shelter")
            if phase == "break" and not _number_at_least(support.get("near_rain_amount_ratio"), 0.10):
                problems.append(f"{where}: Break near rain did not remain visible outside")
        elif case == "catalogue_world_view":
            if shelter_case != "world_view":
                problems.append(f"{where}: catalogue view has an unexpected shelter case")
        else:
            problems.append(f"{where}: unknown F41 support case {case!r}")

    if len(view_phase_keys) != EXPECTED_FRAMES:
        problems.append(f"{preset}: only {len(view_phase_keys)} unique view/phase pairs")
    for phase in PHASES:
        if len(views_by_phase[phase]) != EXPECTED_VIEWS:
            problems.append(f"{preset}: phase {phase} covers {len(views_by_phase[phase])} views, expected {EXPECTED_VIEWS}")
        if shelter_counts[phase] != {"inside": 1, "outside": 1}:
            problems.append(f"{preset}: phase {phase} shelter pair counts are {shelter_counts[phase]!r}")
    all_views = set.union(*views_by_phase.values())
    if len(all_views) != EXPECTED_VIEWS:
        problems.append(f"{preset}: covers {len(all_views)} distinct views, expected {EXPECTED_VIEWS}")
    if any(views_by_phase[phase] != all_views for phase in PHASES):
        problems.append(f"{preset}: phases do not cover the same 50 views")
    return receipt, problems


def _number_at_most(value: Any, limit: float) -> bool:
    return not isinstance(value, bool) and isinstance(value, (float, int)) \
        and math.isfinite(float(value)) and float(value) <= limit


def _number_at_least(value: Any, limit: float) -> bool:
    return not isinstance(value, bool) and isinstance(value, (float, int)) \
        and math.isfinite(float(value)) and float(value) >= limit


def _number_in_range(value: Any, low: float, high: float) -> bool:
    return not isinstance(value, bool) and isinstance(value, (float, int)) \
        and math.isfinite(float(value)) and low <= float(value) <= high


def _numbers_match(left: Any, right: Any, tolerance: float) -> bool:
    return _number_in_range(left, -math.inf, math.inf) and _number_in_range(right, -math.inf, math.inf) \
        and abs(float(left) - float(right)) <= tolerance


def _vectors_match(left: Any, right: Any, tolerance: float) -> bool:
    return isinstance(left, list) and isinstance(right, list) and len(left) == len(right) == 3 \
        and all(_numbers_match(a, b, tolerance) for a, b in zip(left, right))


def _basis_matches(left: Any, right: Any, tolerance: float) -> bool:
    return isinstance(left, list) and isinstance(right, list) and len(left) == len(right) == 3 \
        and all(_vectors_match(a, b, tolerance) for a, b in zip(left, right))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--high-dir", type=Path, required=True, help="directory containing frames_f41r0-high.json and its JPEGs")
    parser.add_argument("--medium-dir", type=Path, required=True, help="directory containing frames_f41r0-medium.json and its JPEGs")
    parser.add_argument("--source-commit", required=True, help="exact 40-character loaded project Git HEAD")
    args = parser.parse_args()
    if len(args.source_commit) != 40 or any(char not in "0123456789abcdef" for char in args.source_commit):
        parser.error("--source-commit must be a lowercase 40-character Git SHA")

    high, high_problems = _read_receipt(args.high_dir, "f41r0-high", "High", args.source_commit)
    medium, medium_problems = _read_receipt(args.medium_dir, "f41r0-medium", "Medium", args.source_commit)
    problems = high_problems + medium_problems
    if high is not None and medium is not None:
        high_frames = high.get("frames", [])
        medium_frames = medium.get("frames", [])
        if not isinstance(high_frames, list):
            high_frames = []
        if not isinstance(medium_frames, list):
            medium_frames = []
        high_pairs = {(str(frame.get("f41_view_id")), str(frame.get("surge_phase")))
                      for frame in high_frames if isinstance(frame, dict)}
        medium_pairs = {(str(frame.get("f41_view_id")), str(frame.get("surge_phase")))
                        for frame in medium_frames if isinstance(frame, dict)}
        if high_pairs != medium_pairs:
            problems.append("High and Medium do not contain the same matched view/phase pairs")
        high_by_pair = {
            (str(frame.get("f41_view_id")), str(frame.get("surge_phase"))): frame
            for frame in high_frames if isinstance(frame, dict)
        }
        medium_by_pair = {
            (str(frame.get("f41_view_id")), str(frame.get("surge_phase"))): frame
            for frame in medium_frames if isinstance(frame, dict)
        }
        for pair in high_pairs & medium_pairs:
            high_frame = high_by_pair[pair]
            medium_frame = medium_by_pair[pair]
            for field, tolerance in (("player", 0.01), ("camera_pos", 0.03)):
                if not _vectors_match(high_frame.get(field), medium_frame.get(field), tolerance):
                    problems.append(f"High/Medium {pair!r}: {field} transform differs by more than {tolerance} m")
            if not _basis_matches(high_frame.get("camera_basis"), medium_frame.get("camera_basis"), 0.001):
                problems.append(f"High/Medium {pair!r}: camera orientation differs")
            if high_frame.get("region") != medium_frame.get("region"):
                problems.append(f"High/Medium {pair!r}: player region differs")
            if not _numbers_match(high_frame.get("surge_elapsed"), medium_frame.get("surge_elapsed"), 1.0):
                problems.append(f"High/Medium {pair!r}: Surge elapsed time differs by more than 1 s")

    report = {
        "result": "PASS" if not problems else "FAIL",
        "source_commit": args.source_commit,
        "high_dir": str(args.high_dir),
        "medium_dir": str(args.medium_dir),
        "high_frames": len(high.get("frames", [])) if high and isinstance(high.get("frames"), list) else 0,
        "medium_frames": len(medium.get("frames", [])) if medium and isinstance(medium.get("frames"), list) else 0,
        "matched_view_phase_pairs": len({
            (str(frame.get("f41_view_id")), str(frame.get("surge_phase")))
            for frame in high.get("frames", []) if isinstance(frame, dict)
        }) if high and isinstance(high.get("frames"), list) else 0,
        "problems": problems,
        "visual_judgement": "not performed",
    }
    print(json.dumps(report, indent=2))
    return 0 if not problems else 1


if __name__ == "__main__":
    sys.exit(main())
