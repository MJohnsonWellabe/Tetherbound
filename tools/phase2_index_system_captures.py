"""Index native-GPU system sequence frames into the Phase 2 manifest."""

from __future__ import annotations

import argparse
import csv
import json
import shutil
import subprocess
from pathlib import Path

from PIL import Image

from phase2_index_captures import COLUMNS, build_sheet


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--biome", required=True)
    parser.add_argument("--system", required=True)
    parser.add_argument("--script", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--seed", type=int, default=2042)
    parser.add_argument("--camera", choices=("normal", "close", "ui"), default="normal")
    parser.add_argument("--render-path", default="native GPU Compatibility")
    parser.add_argument("--allow-partial", action="store_true")
    parser.add_argument("--repro-extra", action="append", default=[], help="Additional pinned capture argument")
    args = parser.parse_args()
    if len(args.commit) != 40:
        raise SystemExit("A full pinned commit SHA is required")
    repo = args.repo.resolve()
    if subprocess.run(["git", "-C", str(repo), "cat-file", "-e", f"{args.commit}^{{commit}}"], capture_output=True).returncode:
        raise SystemExit("Pinned commit does not resolve locally")
    source = args.source.resolve()
    engine = json.loads((source / "manifest.json").read_text(encoding="utf-8"))
    if not engine.get("complete") and not args.allow_partial:
        raise SystemExit("System capture is incomplete")
    base = repo / "ralph/reports/VISUAL/phase2" / args.biome
    frames_dir = base / "systems"
    frames_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source / "manifest.json", frames_dir / f"engine_manifest_{args.system}.json")
    csv_path = base / "manifest.csv"
    with csv_path.open(newline="", encoding="utf-8") as stream:
        existing = {row["id"]: row for row in csv.DictReader(stream)}
    for frame in engine["frames"]:
        source_id = str(frame.get("id", frame.get("frame", "")))
        if not source_id:
            raise SystemExit("System frame has no ID")
        frame_system = str(frame.get("system", args.system))
        frame_id = f"{args.biome}__{frame_system}__{source_id}"
        src = source / Path(frame["file"]).name
        if not src.is_file():
            raise SystemExit(f"Missing {src}")
        with Image.open(src) as image:
            image.verify()
        dst = frames_dir / f"{frame_id}{src.suffix.lower()}"
        shutil.copy2(src, dst)
        replay_args = args.repro_extra + engine.get("repro_args", [f"--seed={args.seed}"])
        output_option = engine.get("output_option", "--output")
        repro = (
            "godot --path . --rendering-driver opengl3 --resolution 1920x1080 "
            f"--script {args.script} -- " + " ".join(replay_args) + " "
            f"{output_option}=res://ralph/reports/VISUAL/phase2/{args.biome}/repro_{args.system}_{source_id}"
        )
        existing[frame_id] = {
            "id": frame_id, "biome": args.biome, "category": "systems",
            "subject": frame_system, "location_id": str(engine.get("named_location", "")),
            "route": "main", "time_of_day": frame.get("time", "day"),
            "weather_or_phase": "clear", "pose_or_state": frame.get("state", source_id),
            "camera": args.camera, "frame_path": dst.relative_to(repo).as_posix(),
            "repro": repro, "commit": args.commit, "render_path": args.render_path,
        }
    with csv_path.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=COLUMNS)
        writer.writeheader()
        writer.writerows(existing[key] for key in sorted(existing))
    build_sheet(repo, base, list(existing.values()), "systems")
    print(f"Indexed {len(engine['frames'])} {args.system} frames; {len(existing)} total")


if __name__ == "__main__":
    main()
