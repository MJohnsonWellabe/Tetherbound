"""Index the production input and camera Cloudreach riding sequence."""

from __future__ import annotations

import argparse
import csv
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
    parser.add_argument("--tag", default="phase2")
    args = parser.parse_args()
    repo = args.repo.resolve()
    if len(args.commit) != 40 or subprocess.run(
        ["git", "-C", str(repo), "cat-file", "-e", f"{args.commit}^{{commit}}"],
        capture_output=True,
    ).returncode:
        raise SystemExit("Pinned commit must resolve in the report repository")
    source = args.source.resolve()
    frames = sorted(source.glob("*.png"))
    if not frames:
        raise SystemExit("No riding frames")
    base = repo / "ralph/reports/VISUAL/phase2/cloudreach"
    dest = base / "systems"
    dest.mkdir(exist_ok=True)
    manifest = base / "manifest.csv"
    with manifest.open(newline="", encoding="utf-8") as stream:
        existing = {row["id"]: row for row in csv.DictReader(stream)}
    thumbs = []
    for origin in frames:
        frame_id = f"cloudreach__riding__{origin.stem}"
        output = dest / f"{frame_id}.png"
        with Image.open(origin) as picture:
            picture.verify()
        shutil.copy2(origin, output)
        location = "terrace" if "terrace" in origin.stem else "ledge"
        state = origin.stem.split("_", 2)[-1]
        existing[frame_id] = {
            "id": frame_id, "biome": "cloudreach", "category": "systems",
            "subject": "riding", "location_id": location, "route": "main",
            "time_of_day": "day", "weather_or_phase": "clear",
            "pose_or_state": state, "camera": "normal",
            "frame_path": output.relative_to(repo).as_posix(),
            "repro": (
                "godot --path . --rendering-driver opengl3 --resolution 1920x1080 "
                "--script tools/phase2_capture_cloudreach_ride.gd -- "
                f"--tag={args.tag} --seed={args.seed}"
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
    for start in range(0, len(thumbs), 20):
        group = thumbs[start : start + 20]
        sheet = Image.new("RGB", (4 * 420, 5 * 260), "#17212a")
        draw = ImageDraw.Draw(sheet)
        for index, (frame_id, thumb) in enumerate(group):
            x, y = index % 4 * 420, index // 4 * 260
            sheet.paste(thumb, (x, y))
            draw.text((x + 3, y + 230), frame_id[-51:], fill="white")
        sheet.save(base / f"contact_sheet_systems_ride_{start // 20 + 1:02}.jpg", quality=87)
    print(f"Indexed {len(frames)} Cloudreach riding frames; {len(existing)} biome frames total")


if __name__ == "__main__":
    main()
