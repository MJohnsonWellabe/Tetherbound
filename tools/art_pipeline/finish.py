#!/usr/bin/env python3
"""Take one chosen candidate from raw mesh to installed, animated game asset.

    tools/art_pipeline/finish.py clean    bramblebun b
    tools/art_pipeline/finish.py texture  bramblebun            # needs MESHY_API_KEY
    tools/art_pipeline/finish.py rig      bramblebun --kind quadruped
    tools/art_pipeline/finish.py grade    bramblebun             # needs a SPECIES entry in grade.py
    tools/art_pipeline/finish.py install  bramblebun

The steps a species goes through after its winner is picked, with the paths
threaded between them. Same reason as batch.py: this is the same six commands
thirteen times, and the mistakes that matter are the ones made while retyping
a path, not while thinking about a rabbit.

Everything lands under assets_raw/<species>/build/ until `install`, which is
the only step that writes into assets/.
"""

import argparse
import json
import os
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
RAW = ROOT / "assets_raw"
BLENDER = pathlib.Path.home() / ".cache/tetherbound-art/blender-4.2.9-linux-x64/blender"
HERE = pathlib.Path(__file__).parent

RIGS = {"quadruped": "rig_quadruped.py", "glider": "rig_glider.py",
        "bird": "rig_bird.py", "sitter": "rig_sitter.py"}


def build_dir(species: str) -> pathlib.Path:
    out = RAW / species / "build"
    out.mkdir(parents=True, exist_ok=True)
    return out


def run(command: list[str], quiet: bool = False) -> None:
    print("$", " ".join(str(c) for c in command), flush=True)
    result = subprocess.run([str(c) for c in command],
                            capture_output=quiet, text=True)
    if result.returncode:
        if quiet:
            print(result.stdout[-4000:], result.stderr[-2000:])
        sys.exit(f"failed: {command[0]}")
    if quiet:
        # Blender is loud; keep the tail, which is where every one of these
        # scripts prints its own verdict.
        print("\n".join(result.stdout.strip().splitlines()[-14:]))


def blender(script: str, *args, quiet: bool = True) -> None:
    run([BLENDER, "--background", "--python", HERE / "blender" / script, "--", *args],
        quiet=quiet)


def cmd_clean(args) -> None:
    source = RAW / args.species / args.candidate / "model.glb"
    if not source.exists():
        sys.exit(f"no such candidate: {source}")
    out = build_dir(args.species) / "clean.glb"
    blender("cleanup_mesh.py", source, "--out", out, "--target-tris", args.target_tris)
    (build_dir(args.species) / "chosen.json").write_text(
        json.dumps({"candidate": args.candidate}, indent=2))


def cmd_texture(args) -> None:
    """Submit the cleaned mesh for retexture and wait for it.

    `--style-from` is deliberately NOT used for the wild roster: unlike the
    version of the pipeline written before these sheets existed, every wild
    species now has its own drawn turnaround, so each one is textured against
    its own concept rather than borrowed from a starter's.
    """
    clean = build_dir(args.species) / "clean.glb"
    command = [sys.executable, HERE / "meshy.py", "texture", args.species, clean,
               "--resolution", args.resolution]
    print("$", " ".join(str(c) for c in command), flush=True)
    result = subprocess.run([str(c) for c in command], capture_output=True, text=True)
    print(result.stdout, result.stderr)
    task = next((line.split()[-1] for line in result.stdout.splitlines()
                 if line.startswith("texture task:")), None)
    if not task:
        sys.exit("retexture was not accepted")
    run([sys.executable, HERE / "meshy.py", "fetch", task, "--stage", "texture",
         "--out", RAW / args.species / "textured"])


def cmd_rig(args) -> None:
    build = build_dir(args.species)
    source = build / "textured.glb"
    if not source.exists():
        source = RAW / args.species / "textured" / "model.glb"
    if not source.exists():
        sys.exit(f"no textured model for {args.species}; run `texture` first")
    rigged = build / "rigged.glb"
    blender(RIGS[args.kind], source, "--out", rigged,
            "--report", build / "rig_report.json")
    if args.kind == "bird":
        # rig_bird.py authors all six standard clips itself (author_all(),
        # proved end-to-end on three winged test meshes per its own
        # docstring) -- it is not a bare rigging script the way
        # rig_quadruped.py/rig_glider.py/rig_sitter.py are. Its bone names
        # deliberately overlap animate_quadruped.py's glider layout so that
        # script "still produces something sane if it is ever pointed at a
        # bird" -- but running it here would silently re-detect the rig as
        # a glider and overwrite rig_bird.py's bird-specific animation with
        # generic glider animation, including the documented faint-spin bug
        # (animate_quadruped.py puts yaw on the root bone's local Y, which
        # is world-up on a vertical root -- the creature spins on the spot
        # instead of toppling). rigged.glb is already the finished output.
        rigged.rename(build / "animated.glb")
    else:
        blender("animate_quadruped.py", rigged, "--out", build / "animated.glb")


def cmd_grade(args) -> None:
    build = build_dir(args.species)
    source = build / "animated.glb"
    if not source.exists():
        sys.exit(f"no animated model for {args.species}; run `rig` first")
    blender("grade.py", "--species", args.species, source,
            "--out", build / "graded.glb")


def cmd_install(args) -> None:
    build = build_dir(args.species)
    source = build / "graded.glb"
    if not source.exists():
        source = build / "animated.glb"
    if not source.exists():
        sys.exit(f"nothing to install for {args.species}")
    target = (ROOT / "assets" / "pals" / "tetherbound" / args.species / "models"
              / f"pal_{args.species}_lod0.glb")
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(source.read_bytes())
    print(f"{target.relative_to(ROOT)}  {target.stat().st_size // 1024} KB")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    clean = sub.add_parser("clean")
    clean.add_argument("species")
    clean.add_argument("candidate")
    clean.add_argument("--target-tris", default="28000")
    clean.set_defaults(func=cmd_clean)

    texture = sub.add_parser("texture")
    texture.add_argument("species")
    texture.add_argument("--resolution", default="2k")
    texture.set_defaults(func=cmd_texture)

    rig = sub.add_parser("rig")
    rig.add_argument("species")
    rig.add_argument("--kind", choices=list(RIGS), default="quadruped")
    rig.set_defaults(func=cmd_rig)

    grade = sub.add_parser("grade")
    grade.add_argument("species")
    grade.set_defaults(func=cmd_grade)

    install = sub.add_parser("install")
    install.add_argument("species")
    install.set_defaults(func=cmd_install)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
