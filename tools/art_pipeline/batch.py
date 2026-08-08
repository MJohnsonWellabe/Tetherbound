#!/usr/bin/env python3
"""Drive a whole species batch through generate -> fetch -> turntable -> compare.

    tools/art_pipeline/batch.py fetch bramblebun
    tools/art_pipeline/batch.py render bramblebun
    tools/art_pipeline/batch.py sheet bramblebun

Thirteen wild species is thirteen times the same six commands with the same
paths threaded between them, and the earlier characters were driven by hand.
That was survivable for four and is not for thirteen: the interesting failure
is a candidate no one looked at, and every keystroke spent retyping a task id
is a keystroke not spent looking.

Reads the manifest `meshy.py generate` already writes, so nothing here has to
know a task id. It never SUBMITS anything -- spending credits stays an explicit
command -- and it never needs MESHY_API_KEY except in `fetch`, which shells out
to meshy.py rather than talking to the API itself.
"""

import argparse
import json
import os
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
RAW = ROOT / "assets_raw"
SHOTS = ROOT / "shots" / "candidates"
BLENDER = pathlib.Path.home() / ".cache/tetherbound-art/blender-4.2.9-linux-x64/blender"
HERE = pathlib.Path(__file__).parent


def manifest(species: str) -> dict:
    path = RAW / species / "manifest.json"
    if not path.exists():
        sys.exit(f"no manifest for {species}; run meshy.py generate first")
    return json.loads(path.read_text())


def run(command: list[str]) -> int:
    print("$", " ".join(str(c) for c in command), flush=True)
    return subprocess.call([str(c) for c in command])


def cmd_fetch(args) -> None:
    stage = args.stage
    for task in manifest(args.species)["tasks"]:
        out = RAW / args.species / task["candidate"]
        if (out / "model.glb").exists() and not args.force:
            print(f"  {task['candidate']}: already fetched")
            continue
        run([sys.executable, HERE / "meshy.py", "fetch", task["task_id"],
             "--stage", stage, "--out", out])


def cmd_render(args) -> None:
    for task in manifest(args.species)["tasks"]:
        model = RAW / args.species / task["candidate"] / "model.glb"
        if not model.exists():
            print(f"  {task['candidate']}: no model.glb, skipped")
            continue
        run([BLENDER, "--background", "--python", HERE / "blender/turntable.py",
             "--", model, "--out", SHOTS / f"{args.species}-{task['candidate']}"])


def cmd_inspect(args) -> None:
    for task in manifest(args.species)["tasks"]:
        model = RAW / args.species / task["candidate"] / "model.glb"
        if not model.exists():
            continue
        print(f"===== {args.species} {task['candidate']}")
        run([BLENDER, "--background", "--python", HERE / "blender/inspect_glb.py",
             "--", model, "--out", SHOTS / f"{args.species}-{task['candidate']}.json"])


def cmd_sheet(args) -> None:
    candidates = []
    for task in manifest(args.species)["tasks"]:
        directory = SHOTS / f"{args.species}-{task['candidate']}"
        if directory.exists():
            candidates += ["--candidate", f"{task['candidate']}={directory}"]
    if not candidates:
        sys.exit(f"no rendered candidates for {args.species}")
    run([HERE / "compare_sheet.py", args.species] + candidates)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    fetch = sub.add_parser("fetch", help="download every candidate in the manifest")
    fetch.add_argument("species")
    fetch.add_argument("--stage", default="generate")
    fetch.add_argument("--force", action="store_true")
    fetch.set_defaults(func=cmd_fetch)

    render = sub.add_parser("render", help="turntable every fetched candidate")
    render.add_argument("species")
    render.set_defaults(func=cmd_render)

    inspect = sub.add_parser("inspect", help="§11 topology report for every candidate")
    inspect.add_argument("species")
    inspect.set_defaults(func=cmd_inspect)

    sheet = sub.add_parser("sheet", help="build the comparison sheet")
    sheet.add_argument("species")
    sheet.set_defaults(func=cmd_sheet)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
