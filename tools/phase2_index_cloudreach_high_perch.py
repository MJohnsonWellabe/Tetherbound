"""Index the pinned production-camera High Perches flight sequence."""

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
    engine = json.loads((source / "manifest.json").read_text(encoding="utf-8"))
    if not engine.get("records"):
        raise SystemExit("High Perches production-camera sequence has no frames")
    base = repo / "ralph/reports/VISUAL/phase2/cloudreach"
    dest = base / "systems"
    dest.mkdir(exist_ok=True)
    shutil.copy2(source / "manifest.json", dest / f"engine_manifest_{source.name}.json")
    manifest = base / "manifest.csv"
    with manifest.open(newline="", encoding="utf-8") as stream:
        existing = {row["id"]: row for row in csv.DictReader(stream)}
    thumbs = []
    for record in engine["records"]:
        name = str(record["frame_id"])
        original = source / Path(str(record["file"])).name
        if not original.is_file():
            raise SystemExit(f"Missing engine frame {original}")
        frame_id = f"cloudreach__flying__{name}"
        output = dest / f"{frame_id}{original.suffix.lower()}"
        with Image.open(original) as picture:
            picture.verify()
        shutil.copy2(original, output)
        time = "night" if name.endswith("-night") else "day"
        state = name.removeprefix("high-perches-").removesuffix(f"-{time}")
        existing[frame_id] = {
            "id": frame_id, "biome": "cloudreach", "category": "systems",
            "subject": "flying", "location_id": "high_perches", "route": "main",
            "time_of_day": time, "weather_or_phase": "clear",
            "pose_or_state": state, "camera": "normal",
            "frame_path": output.relative_to(repo).as_posix(),
            "repro": (
                "godot --path . --rendering-driver opengl3 --resolution 1920x1080 "
                "--script tools/phase2_capture_cloudreach_high_perch.gd -- "
                "--output=res://ralph/reports/VISUAL/phase2/cloudreach/repro/high_perch "
                f"--seed={args.seed}"
            ),
            "commit": args.commit, "render_path": args.render_path,
        }
        with Image.open(output) as picture:
            thumb = picture.convert("RGB")
            thumb.thumbnail((480, 270))
            thumbs.append((frame_id, thumb.copy()))
    with manifest.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(sorted(existing.values(), key=lambda row: row["id"]))
    sheet = Image.new("RGB", (3 * 500, 4 * 310), "#17212a")
    draw = ImageDraw.Draw(sheet)
    for index, (frame_id, thumb) in enumerate(thumbs):
        x, y = (index % 3) * 500, (index // 3) * 310
        sheet.paste(thumb, (x, y))
        draw.text((x + 3, y + 275), frame_id[-53:], fill="white")
    sheet.save(base / "contact_sheet_systems_high_perch.jpg", quality=87)
    print(f"Indexed {len(thumbs)} High Perches frames; {len(existing)} Cloudreach frames total")


if __name__ == "__main__":
    main()
