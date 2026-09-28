"""Index pinned Stormwood named-wild fight frames from the installed recorder."""

from __future__ import annotations

import argparse
import csv
import json
import shutil
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw


FIELDS = [
    "id", "biome", "category", "subject", "location_id", "route",
    "time_of_day", "weather_or_phase", "pose_or_state", "camera",
    "frame_path", "repro", "commit", "render_path",
]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--render-path", required=True)
    parser.add_argument("--seed", type=int, default=2042)
    args = parser.parse_args()
    repo = args.repo.resolve()
    if len(args.commit) != 40 or subprocess.run(
        ["git", "-C", str(repo), "cat-file", "-e", f"{args.commit}^{{commit}}"],
        capture_output=True,
    ).returncode:
        raise SystemExit("Pinned commit must resolve in the report repository")
    source = args.source.resolve()
    frames = sorted(source.glob("*.png"))
    if not frames or not (source / "capture_log.json").is_file():
        raise SystemExit("Missing source frames or capture log")
    base = repo / "ralph/reports/VISUAL/phase2/stormwood"
    dest = base / "systems"
    dest.mkdir(exist_ok=True)
    shutil.copy2(source / "capture_log.json", dest / f"engine_log_{source.name}.json")
    manifest = base / "manifest.csv"
    with manifest.open(newline="", encoding="utf-8") as stream:
        existing = {row["id"]: row for row in csv.DictReader(stream)}
    thumbnails = []
    for origin in frames:
        named, _, tag = origin.stem.partition("-")
        if not tag:
            raise SystemExit(f"Unrecognized fight filename: {origin.name}")
        frame_id = f"stormwood__fight__{origin.stem}"
        output = dest / f"{frame_id}.png"
        with Image.open(origin) as image:
            image.verify()
        shutil.copy2(origin, output)
        existing[frame_id] = {
            "id": frame_id, "biome": "stormwood", "category": "systems",
            "subject": "fights", "location_id": named, "route": "main",
            "time_of_day": "day", "weather_or_phase": "Calm",
            "pose_or_state": tag, "camera": "normal",
            "frame_path": output.relative_to(repo).as_posix(),
            "repro": (
                "godot --path . --rendering-driver opengl3 --resolution 1920x1080 "
                "--script tools/phase2_capture_stormwood_fights.gd -- "
                f"--out={repo.as_posix()}/ralph/reports/VISUAL/phase2/stormwood/repro/{named} "
                f"--ids={named} --seconds=18 --interval=1.0 --seed={args.seed}"
            ),
            "commit": args.commit, "render_path": args.render_path,
        }
        with Image.open(output) as image:
            thumb = image.convert("RGB")
            thumb.thumbnail((360, 203))
            thumbnails.append((frame_id, thumb.copy()))
    with manifest.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(sorted(existing.values(), key=lambda row: row["id"]))
    for start in range(0, len(thumbnails), 20):
        group = thumbnails[start : start + 20]
        sheet = Image.new("RGB", (4 * 380, 5 * 245), "#17212a")
        draw = ImageDraw.Draw(sheet)
        for index, (frame_id, thumb) in enumerate(group):
            x = index % 4 * 380
            y = index // 4 * 245
            sheet.paste(thumb, (x, y))
            draw.text((x + 3, y + 206), frame_id[-48:], fill="white")
        sheet.save(base / f"contact_sheet_systems_stormfight_{start // 20 + 1:02}.jpg", quality=87)
    print(f"Indexed {len(frames)} Stormwood fight frames; {len(existing)} biome frames total")


if __name__ == "__main__":
    main()
