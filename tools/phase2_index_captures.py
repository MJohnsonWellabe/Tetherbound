"""Import a pinned Phase 2 GPU capture and build its CSV/contact sheet.

The source is the GPU service's artifact/worktree directory. It must contain a
completed JSON manifest from phase2_capture_locations.gd. This tool never
invents a capture row for a missing or unreadable image.
"""

from __future__ import annotations

import argparse
import csv
import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw


COLUMNS = [
    "id", "biome", "category", "subject", "location_id", "route",
    "time_of_day", "weather_or_phase", "pose_or_state", "camera",
    "frame_path", "repro", "commit", "render_path",
]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--biome", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--render-path", required=True)
    args = parser.parse_args()
    repo = args.repo.resolve()
    source = args.source.resolve()
    if len(args.commit) != 40 or any(c not in "0123456789abcdef" for c in args.commit):
        raise SystemExit("--commit must be a full Git SHA")
    manifest = json.loads((source / "manifest.json").read_text(encoding="utf-8"))
    if not manifest.get("complete") or manifest.get("failures"):
        raise SystemExit("Capture manifest is incomplete; inspect its failures")
    if manifest.get("biome_id") != args.biome:
        raise SystemExit("Biome does not match capture manifest")
    if args.render_path == "native GPU Compatibility" and manifest.get("display_server") == "headless":
        raise SystemExit("GPU capture was headless")

    base = repo / "ralph" / "reports" / "VISUAL" / "phase2" / args.biome
    frames_dir = base / "locations"
    frames_dir.mkdir(parents=True, exist_ok=True)
    csv_path = base / "manifest.csv"
    existing = {}
    if csv_path.exists():
        with csv_path.open(newline="", encoding="utf-8") as stream:
            existing = {row["id"]: row for row in csv.DictReader(stream)}
    for frame in manifest["frames"]:
        frame_id = frame["frame_id"]
        src = source / f"{frame_id}.png"
        if not src.is_file():
            raise SystemExit(f"Missing {src}")
        with Image.open(src) as image:
            image.verify()
        dst = frames_dir / src.name
        shutil.copy2(src, dst)
        rel = dst.relative_to(repo).as_posix()
        view = frame.get("view", "normal")
        time = frame["time"]
        repro = (
            "godot --path . --rendering-driver opengl3 --resolution 1920x1080 "
            "--script tools/phase2_capture_locations.gd -- "
            f"--biome={args.biome} --subset={frame['identity']} "
            f"--times={time} --views={view} --seed={manifest.get('seed', 2042)} "
            f"--output=res://ralph/reports/VISUAL/phase2/{args.biome}/repro/{frame_id}"
        )
        existing[frame_id] = {
            "id": frame_id,
            "biome": args.biome,
            "category": "named_locations",
            "subject": frame["destination_display_name"],
            "location_id": frame["identity"],
            "route": "main",
            "time_of_day": "dusk" if time == "golden" else time,
            "weather_or_phase": "clear",
            "pose_or_state": view,
            "camera": "close" if view == "close" else "normal",
            "frame_path": rel,
            "repro": repro,
            "commit": args.commit,
            "render_path": args.render_path,
        }
    with csv_path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=COLUMNS)
        writer.writeheader()
        writer.writerows(existing[key] for key in sorted(existing))
    build_sheet(repo, base, list(existing.values()), "named_locations")
    print(f"Indexed {len(manifest['frames'])} captures; {len(existing)} total in {csv_path}")


def build_sheet(repo: Path, base: Path, rows: list[dict], category: str) -> None:
    rows = [r for r in rows if r["category"] == category]
    if not rows:
        return
    width, height, label_h, columns = 320, 180, 35, 4
    count_rows = (len(rows) + columns - 1) // columns
    sheet = Image.new("RGB", (width * columns, (height + label_h) * count_rows), "#15202b")
    draw = ImageDraw.Draw(sheet)
    for index, row in enumerate(rows):
        with Image.open(repo / row["frame_path"]) as image:
            image = image.convert("RGB")
            image.thumbnail((width, height))
            x, y = (index % columns) * width, (index // columns) * (height + label_h)
            sheet.paste(image, (x + (width - image.width) // 2, y))
            draw.text((x + 5, y + height + 3), row["id"][:44], fill="white")
    sheet.save(base / f"contact_sheet_{category}.jpg", quality=90)


if __name__ == "__main__":
    main()
