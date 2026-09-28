"""Index production-camera Aquaryn mount, swimming and dismount views."""

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
    if len(args.commit) != 40 or subprocess.run(
        ["git", "-C", str(repo), "cat-file", "-e", f"{args.commit}^{{commit}}"],
        capture_output=True,
    ).returncode:
        raise SystemExit("Pinned commit must resolve in the report repository")
    source = args.source.resolve()
    engine = json.loads((source / "manifest.json").read_text(encoding="utf-8"))
    if not engine.get("complete") or not engine.get("records"):
        raise SystemExit("Mounted swim capture incomplete")
    base = repo / "ralph/reports/VISUAL/phase2/tidewake"
    dest = base / "systems"
    dest.mkdir(exist_ok=True)
    shutil.copy2(source / "manifest.json", dest / f"engine_manifest_{source.name}.json")
    manifest = base / "manifest.csv"
    with manifest.open(newline="", encoding="utf-8") as stream:
        existing = {row["id"]: row for row in csv.DictReader(stream)}
    thumbs = []
    for record in engine["records"]:
        origin = source / Path(str(record["file"])).name
        if not origin.is_file():
            raise SystemExit(f"Missing mounted swim frame {origin}")
        name = str(record["frame_id"])
        frame_id = f"tidewake__system__{name}"
        output = dest / f"{frame_id}.png"
        with Image.open(origin) as picture:
            picture.verify()
        shutil.copy2(origin, output)
        subject = "riding" if record["mounted"] else "swimming"
        existing[frame_id] = {
            "id": frame_id, "biome": "tidewake", "category": "systems",
            "subject": subject, "location_id": "first_shore_swim_lesson",
            "route": "main", "time_of_day": "day", "weather_or_phase": "low_current",
            "pose_or_state": f"{record['mode'].lower()}_{record['time_s']}s",
            "camera": "normal", "frame_path": output.relative_to(repo).as_posix(),
            "repro": (
                "godot --path . --rendering-driver opengl3 --resolution 1920x1080 "
                "--script tools/phase2_capture_tidewake_mounted_swim.gd -- "
                "--output=res://ralph/reports/VISUAL/phase2/tidewake/repro/mounted_swim --seed=2042"
            ),
            "commit": args.commit, "render_path": args.render_path,
        }
        with Image.open(output) as picture:
            thumb = picture.convert("RGB")
            thumb.thumbnail((400, 225))
            thumbs.append((frame_id, thumb.copy()))
    with manifest.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(sorted(existing.values(), key=lambda row: row["id"]))
    sheet = Image.new("RGB", (4 * 420, 4 * 260), "#17212a")
    draw = ImageDraw.Draw(sheet)
    for index, (frame_id, thumb) in enumerate(thumbs[:16]):
        x, y = index % 4 * 420, index // 4 * 260
        sheet.paste(thumb, (x, y))
        draw.text((x + 3, y + 230), frame_id[-48:], fill="white")
    sheet.save(base / "contact_sheet_systems_mounted_swim.jpg", quality=87)
    print(f"Indexed {len(thumbs)} Tidewake mounted-swim frames; {len(existing)} biome frames total")


if __name__ == "__main__":
    main()
