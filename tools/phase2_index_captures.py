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
    parser.add_argument("--report-biome", help="Evidence label when the game's realm ID differs (water -> tidewake)")
    parser.add_argument("--commit", required=True)
    parser.add_argument("--render-path", required=True)
    parser.add_argument("--category", choices=("locations", "routes", "ui", "creatures"), default="locations")
    parser.add_argument("--allow-partial", action="store_true")
    args = parser.parse_args()
    report_biome = args.report_biome or args.biome
    repo = args.repo.resolve()
    source = args.source.resolve()
    if len(args.commit) != 40 or any(c not in "0123456789abcdef" for c in args.commit):
        raise SystemExit("--commit must be a full Git SHA")
    manifest = json.loads((source / "manifest.json").read_text(encoding="utf-8"))
    if (not manifest.get("complete") or manifest.get("failures")) and not args.allow_partial:
        raise SystemExit("Capture manifest is incomplete; inspect its failures")
    if manifest.get("biome_id", manifest.get("biome")) != args.biome:
        raise SystemExit("Biome does not match capture manifest")
    if args.render_path == "native GPU Compatibility" and manifest.get("display_server") == "headless":
        raise SystemExit("GPU capture was headless")

    base = repo / "ralph" / "reports" / "VISUAL" / "phase2" / report_biome
    frames_dir = base / args.category
    frames_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source / "manifest.json", frames_dir / "engine_manifest.json")
    if manifest.get("failures"):
        (frames_dir / "open_capture_failures.json").write_text(
            json.dumps(manifest["failures"], indent=2) + "\n", encoding="utf-8"
        )
    csv_path = base / "manifest.csv"
    existing = {}
    if csv_path.exists():
        with csv_path.open(newline="", encoding="utf-8") as stream:
            existing = {row["id"]: row for row in csv.DictReader(stream)}
    for frame in manifest["frames"]:
        if args.category == "creatures":
            source_id = frame["id"]
            frame_id = source_id.replace(f"{args.biome}__", f"{report_biome}__", 1)
            src = source / f"{source_id}.jpg"
            if not src.is_file():
                raise SystemExit(f"Missing {src}")
            with Image.open(src) as image:
                image.verify()
            dst = frames_dir / f"{frame_id}.jpg"
            shutil.copy2(src, dst)
            existing[frame_id] = {
                "id": frame_id, "biome": report_biome, "category": "creatures",
                "subject": frame["species"], "location_id": "capture_stage",
                "route": "off", "time_of_day": "day", "weather_or_phase": "clear",
                "pose_or_state": frame["pose"], "camera": "normal",
                "frame_path": dst.relative_to(repo).as_posix(),
                "repro": (
                    "godot --path . --rendering-driver opengl3 --resolution 1920x1080 "
                    "--script tools/phase2_capture_creatures.gd -- "
                    f"--biome={args.biome} --only={frame['species']} --seed={manifest['seed']} "
                    f"--output=res://ralph/reports/VISUAL/phase2/{report_biome}/creature_repro_{frame['species']}"
                ),
                "commit": args.commit, "render_path": args.render_path,
            }
            continue
        if args.category == "ui":
            frame_id = f"{report_biome}__{frame['id']}"
            src = source / f"{frame['id']}.jpg"
            if not src.is_file():
                raise SystemExit(f"Missing {src}")
            with Image.open(src) as image:
                image.verify()
            dst = frames_dir / src.name
            shutil.copy2(src, dst)
            existing[frame_id] = {
                "id": frame_id, "biome": report_biome, "category": "ui",
                "subject": frame["subject"], "location_id": "",
                "route": "main", "time_of_day": "day", "weather_or_phase": "clear",
                "pose_or_state": frame["id"], "camera": "ui",
                "frame_path": dst.relative_to(repo).as_posix(),
                "repro": (
                    "godot --path . --rendering-driver opengl3 --resolution 1920x1080 "
                    "--script tools/phase2_capture_ui.gd -- "
                    f"--biome={args.biome} --seed={manifest['seed']} "
                    f"--output=res://ralph/reports/VISUAL/phase2/{report_biome}/ui_repro"
                ),
                "commit": args.commit, "render_path": args.render_path,
            }
            continue
        source_id = frame["frame_id"]
        frame_id = source_id.replace(f"{args.biome}__", f"{report_biome}__", 1)
        src = source / f"{source_id}.jpg"
        if not src.is_file():
            raise SystemExit(f"Missing {src}")
        with Image.open(src) as image:
            image.verify()
        dst = frames_dir / f"{frame_id}.jpg"
        shutil.copy2(src, dst)
        rel = dst.relative_to(repo).as_posix()
        view = frame.get("view", "normal")
        time = frame["time"]
        capture_script = "phase2_capture_routes.gd" if args.category == "routes" else "phase2_capture_locations.gd"
        selection = f"--biome={args.biome} --subset={frame['identity']} "
        if args.category != "routes":
            selection += f"--times={time} --views={view} "
        repro = (
            "godot --path . --rendering-driver opengl3 --resolution 1920x1080 "
            f"--script tools/{capture_script} -- "
            f"{selection}--seed={manifest.get('seed', 2042)} "
            f"--output=res://ralph/reports/VISUAL/phase2/{report_biome}/repro/{frame_id}"
        )
        existing[frame_id] = {
            "id": frame_id,
            "biome": report_biome,
            "category": "route_and_terrain" if args.category == "routes" else "named_locations",
            "subject": frame["destination_display_name"],
            "location_id": frame["identity"],
            "route": frame.get("route_class", "off"),
            "time_of_day": "dusk" if time == "golden" else time,
            "weather_or_phase": "clear",
            "pose_or_state": view,
            "camera": "vista" if view == "vista" else ("close" if view == "close" else "normal"),
            "frame_path": rel,
            "repro": repro,
            "commit": args.commit,
            "render_path": args.render_path,
        }
    with csv_path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=COLUMNS)
        writer.writeheader()
        writer.writerows(existing[key] for key in sorted(existing))
    sheet_category = {"ui": "ui", "creatures": "creatures", "locations": "named_locations", "routes": "route_and_terrain"}[args.category]
    build_sheet(repo, base, list(existing.values()), sheet_category)
    print(f"Indexed {len(manifest['frames'])} captures; {len(existing)} total in {csv_path}")


def build_sheet(repo: Path, base: Path, rows: list[dict], category: str) -> None:
    rows = [r for r in rows if r["category"] == category]
    if not rows:
        return
    render_sheet(repo, rows, base / f"contact_sheet_{category}.jpg")
    for page, start in enumerate(range(0, len(rows), 24), 1):
        render_sheet(repo, rows[start:start + 24], base / f"contact_sheet_{category}_{page:02d}.jpg")


def render_sheet(repo: Path, rows: list[dict], path: Path) -> None:
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
    sheet.save(path, quality=90)


if __name__ == "__main__":
    main()
