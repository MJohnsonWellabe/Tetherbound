"""Index the installed Tidewake named-fight recorder's pinned frame log."""

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
    parser.add_argument("--max-frames", type=int, default=32)
    parser.add_argument("--interval", type=float, default=1.0)
    parser.add_argument("--level", type=int, default=53)
    parser.add_argument("--pilot", default="READER")
    parser.add_argument("--cap-s", type=int, default=180)
    parser.add_argument("--tells-per-opponent", type=int, default=2)
    parser.add_argument("--hits-per-opponent", type=int, default=2)
    parser.add_argument("--run-suffix", default="")
    parser.add_argument("--only-tags", default="")
    args = parser.parse_args()
    if len(args.commit) != 40 or subprocess.run(
        ["git", "-C", str(args.repo), "cat-file", "-e", f"{args.commit}^{{commit}}"],
        capture_output=True,
    ).returncode:
        raise SystemExit("Pinned commit must resolve in the report repository")
    source = args.source.resolve()
    log = json.loads((source / "frames.json").read_text(encoding="utf-8"))
    base = args.repo.resolve() / "ralph/reports/VISUAL/phase2/tidewake"
    dest = base / "systems"
    dest.mkdir(exist_ok=True)
    shutil.copy2(source / "frames.json", dest / f"engine_frames_{source.name}.json")
    manifest = base / "manifest.csv"
    with manifest.open(newline="", encoding="utf-8") as stream:
        reader = csv.DictReader(stream)
        existing = {row["id"]: row for row in reader}
    thumbnails = []
    selected_tags = {tag.strip() for tag in args.only_tags.split(",") if tag.strip()}
    for record in log:
        if selected_tags and str(record["tag"]) not in selected_tags:
            continue
        recorded = str(record["file"]).replace("\\", "/")
        relative = "/".join(Path(recorded).parts[-2:])
        origin = source / relative
        if not origin.is_file():
            raise SystemExit(f"Frame log points to missing image: {origin}")
        trainer = Path(relative).parent.name
        state = record["tag"]
        stem = Path(relative).stem.replace(".", "_")
        frame_id = f"tidewake__fight__{trainer}{args.run_suffix}__{stem}"
        output = dest / f"{frame_id}.png"
        with Image.open(origin) as image:
            image.verify()
        shutil.copy2(origin, output)
        existing[frame_id] = {
            "id": frame_id, "biome": "tidewake", "category": "systems",
            "subject": "fights", "location_id": f"water_trainer_{trainer}",
            "route": "main", "time_of_day": "day", "weather_or_phase": "clear",
            "pose_or_state": state, "camera": "normal",
            "frame_path": output.relative_to(args.repo.resolve()).as_posix(),
            "repro": (
                "godot --path . --rendering-driver opengl3 --resolution 1920x1080 "
                "--script tools/phase2_capture_tidewake_fights.gd -- "
                f"--trainer=water_trainer_{trainer} --out=res://ralph/reports/VISUAL/phase2/tidewake/repro/{trainer} "
                f"--interval={args.interval} --max-frames={args.max_frames} "
                f"--level={args.level} --pilot={args.pilot} --cap-s={args.cap_s} "
                f"--tells-per-opponent={args.tells_per_opponent} "
                f"--hits-per-opponent={args.hits_per_opponent} "
                f"--render-only-saves --seed={args.seed}"
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
            x = (index % 4) * 380
            y = (index // 4) * 245
            sheet.paste(thumb, (x, y))
            draw.text((x + 3, y + 206), frame_id[-48:], fill="white")
        sheet.save(base / f"contact_sheet_systems_fight_{start // 20 + 1:02}.jpg", quality=87)
    print(f"Indexed {len(log)} Tidewake fight frames; {len(existing)} biome frames total")


if __name__ == "__main__":
    main()
