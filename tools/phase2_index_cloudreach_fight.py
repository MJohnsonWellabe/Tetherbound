"""Index a pinned, successful Cloudreach production-camera fight capture."""

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
    args = parser.parse_args()
    repo = args.repo.resolve()
    source = args.source.resolve()
    if len(args.commit) != 40 or subprocess.run(
        ["git", "-C", str(repo), "cat-file", "-e", f"{args.commit}^{{commit}}"],
        capture_output=True,
    ).returncode:
        raise SystemExit("Pinned commit must resolve in the report repository")
    manifest = json.loads((source / "manifest.json").read_text(encoding="utf-8"))
    if manifest["biome"] != "cloudreach" or not manifest["complete"]:
        raise SystemExit("Cloudreach fight manifest is not complete")
    base = repo / "ralph/reports/VISUAL/phase2/cloudreach"
    dest = base / "systems"
    dest.mkdir(exist_ok=True)
    shutil.copy2(source / "manifest.json", dest / f"engine_manifest_{source.name}.json")
    csv_path = base / "manifest.csv"
    with csv_path.open(newline="", encoding="utf-8") as stream:
        existing = {row["id"]: row for row in csv.DictReader(stream)}
    thumbnails = []
    for frame in manifest["frames"]:
        stem = frame["id"]
        frame_id = f"cloudreach__fight__veyra_live__{stem}"
        origin = source / f"{stem}.png"
        if not origin.is_file():
            raise SystemExit(f"Missing source {origin}")
        with Image.open(origin) as image:
            image.verify()
        target = dest / f"{frame_id}.png"
        shutil.copy2(origin, target)
        existing[frame_id] = {
            "id": frame_id, "biome": "cloudreach", "category": "systems",
            "subject": "fights", "location_id": "captain_veyra_storm_anchor",
            "route": "main", "time_of_day": "day", "weather_or_phase": "clear",
            "pose_or_state": stem, "camera": "normal",
            "frame_path": target.relative_to(repo).as_posix(),
            "repro": (
                "godot --path . --rendering-driver opengl3 --resolution 1920x1080 "
                "--script tools/phase2_capture_cloudreach_live_fight.gd -- "
                "--output=res://ralph/reports/VISUAL/phase2/cloudreach/"
                f"repro_veyra_live --seed={manifest['seed']}"
            ),
            "commit": args.commit, "render_path": args.render_path,
        }
        with Image.open(target) as image:
            thumb = image.convert("RGB")
            thumb.thumbnail((360, 203))
            thumbnails.append((frame_id, thumb.copy()))
    with csv_path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(sorted(existing.values(), key=lambda row: row["id"]))
    for start in range(0, len(thumbnails), 20):
        sheet = Image.new("RGB", (1520, 1225), "#17212a")
        draw = ImageDraw.Draw(sheet)
        for index, (frame_id, thumb) in enumerate(thumbnails[start : start + 20]):
            x, y = index % 4 * 380, index // 4 * 245
            sheet.paste(thumb, (x, y))
            draw.text((x + 3, y + 206), frame_id[-48:], fill="white")
        sheet.save(base / f"contact_sheet_systems_veyra_live_{start // 20 + 1:02}.jpg", quality=87)
    print(f"Indexed {len(thumbnails)} Cloudreach fight frames; {len(existing)} total")


if __name__ == "__main__":
    main()
