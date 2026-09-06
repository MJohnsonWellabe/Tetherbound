#!/usr/bin/env python3
"""Generate comparison-candidate meshes from the reference crops, via the
Tripo CLI (https://www.npmjs.com/package/tripo-cli).

    npm install -g tripo-cli      # once per machine; tools/art_pipeline/setup.sh does this
    tripo login --region ov       # once per machine; interactive, never run headless-blind
    tools/art_pipeline/tripo.py check
    tools/art_pipeline/tripo.py balance
    tools/art_pipeline/tripo.py generate terrapup --candidates 3
    tools/art_pipeline/tripo.py status @last
    tools/art_pipeline/tripo.py fetch <task_id> --out assets_raw/terrapup/tripo_a

WHY THIS EXISTS. TETHERBOUND_3D_ART_PIPELINE.md's candidate order (section 2,
"Generate multiple candidates") has always named a third rung: "Tripo
comparison candidate if Meshy results are inadequate". This is that rung,
wired up the same way `meshy.py` is: a committed script rather than an MCP
server, because an MCP server config is session-local and dies with the
session while a committed script survives it (docs/decisions/D11). See
docs/decisions/ for the entry recording this specific addition.

THIS DOES NOT REPLACE MESHY. Meshy multi-image-to-3D stays the default per
the pipeline doc's preferred order (multi-image > image > text-to-3D). Reach
for this script only when Meshy's own candidates are inadequate, or for a
deliberate side-by-side comparison — never as a way to spend a second
generation on the same asset "just in case".

SAME HARD RULES AS MESHY. CLAUDE.md's asset rules ("Never spend a Meshy
generation without owner-supplied reference art", "Meshy is reserved for Team
Tether hero objects", "No new creature meshes or Meshy generations for the
Meadows") govern *any* AI 3D generation service, Tripo included, not the word
"Meshy" specifically. Do not use this script to spend a generation the
project's Meshy rules would refuse.

WHY A THIN WRAPPER, NOT A REST CLIENT. Unlike `meshy.py`, this script does not
reimplement the provider's HTTP API. `tripo make` already submits, polls,
downloads and writes a `preview.png` in one blocking call — re-implementing
that polling loop is exactly what the CLI's own bundled docs (`tripo docs`)
tell an agent not to do. This wrapper's job is narrower: resolve Tetherbound's
own reference crops the same way `meshy.py` does, enforce this project's
candidate-count budget guard, and land output in the same
`assets_raw/<species>/<candidate>/` layout with a `provenance.json` the asset
ledger can cite — so a Tripo candidate looks, on disk, exactly like a Meshy
one.

SECRETS. The API key lives in `~/.tripo` (or `TRIPO_API_KEY`), managed entirely
by the `tripo` CLI itself via `tripo login` / `tripo logout`. This script never
reads, writes, or echoes it, and never runs `tripo login` on the owner's
behalf — that command is interactive by design (it prints a URL and a code and
waits for a human to approve in a browser), so it must be run by a human at a
keyboard, not fired blind from an agent session. See TETHERBOUND_3D_ART_PIPELINE.md
section 0.5's rule: ask the owner only at genuine credential boundaries.

DEFAULT CANDIDATE BUDGET. Tripo does not publish a fixed per-call credit cost
the way Meshy's pricing page does (models/tiers/regions vary it), so this
script does not fabricate one the way it would if it invented a number. It
guards on *candidate count* instead: section 25's "at least three, cheap tier
first" rule is exactly three, so `--candidates` above `DEFAULT_BUDGET` refuses
without `--yes` — a typo guard, same spirit as `meshy.py`'s `--budget`, sized
to what is actually known. Each candidate's own `credits_consumed` (measured,
from the CLI's result JSON, never estimated) is reported before and after so
the real cost is visible from the first run onward.
"""

import argparse
import datetime
import json
import pathlib
import shutil
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import meshy  # noqa: E402  (reuses reference_views/VIEWS/ROOT/RAW_ROOT — no species/view table twice)

TRIPO_BIN = "tripo"
DEFAULT_BUDGET = 3

# Tripo's own multiview generation wants 2-4 images. meshy.reference_views()
# already returns whatever views a species actually has, in VIEWS order; if a
# species carries all six (including head/top, which multi-image-to-3D never
# used), keep only the four Tripo's own limit allows and in priority order.
MAX_MULTIVIEW = 4


def run_tripo(*args: str, check: bool = True) -> dict:
    """Run one `tripo` subcommand, always with --json, and parse its one line
    of stdout. Progress/logs go to stderr per the CLI's own contract and are
    passed through live rather than captured, so a human watching a long
    `make` call still sees it working."""
    proc = subprocess.run(
        [TRIPO_BIN, *args, "--json"],
        cwd=meshy.ROOT,
        stdout=subprocess.PIPE,
        text=True,
    )
    try:
        result = json.loads(proc.stdout.strip().splitlines()[-1]) if proc.stdout.strip() else {}
    except (json.JSONDecodeError, IndexError):
        result = {}
    if check and proc.returncode != 0:
        detail = result.get("error") or result.get("suggestion") or proc.stdout
        sys.exit(f"tripo {' '.join(args)} failed (exit {proc.returncode}): {detail}")
    return result


def cmd_check(_args) -> None:
    who = run_tripo("whoami", check=False)
    if who.get("error"):
        sys.exit(f"{who['error']}. {who.get('suggestion', 'run: tripo login --region ov')}")
    print(f"key accepted. balance: {who.get('balance', '?')} credits "
          f"(region {who.get('region', '?')})")


def cmd_balance(_args) -> None:
    print(json.dumps(run_tripo("balance"), indent=2))


def cmd_generate(args) -> None:
    species = args.species
    views = meshy.reference_views(species)  # sys.exit()s with a clear message if <2 exist
    view_paths = list(views.values())[:MAX_MULTIVIEW]

    if args.candidates > DEFAULT_BUDGET and not args.yes:
        sys.exit(f"{args.candidates} candidates exceeds the default budget of "
                 f"{DEFAULT_BUDGET} (section 25: cheap tier, three candidates). "
                 f"Re-run with --yes if that is deliberate.")

    before = run_tripo("balance").get("balance", "?")
    print(f"{species}: {args.candidates} candidate(s) via Tripo "
          f"({len(view_paths)} view(s): {', '.join(views.keys())})")
    print(f"balance before: {before} credits")

    out_root = meshy.RAW_ROOT / species
    out_root.mkdir(parents=True, exist_ok=True)
    manifest = {
        "species": species,
        "provider": "tripo",
        "views": {v: str(p.relative_to(meshy.ROOT)) for v, p in views.items() if p in view_paths},
        "for": args.for_preset,
        "candidates": [],
    }

    total_consumed = 0
    for index in range(args.candidates):
        letter = chr(ord("a") + index)
        # First candidate is a real `make`; every candidate after it reruns
        # the identical request with a fresh model_seed via `redo`, which is
        # the CLI's own documented idiom for "same input, another roll" —
        # see the module docstring on why this script does not invent its own
        # seeding scheme.
        if index == 0:
            make_args = [str(p) for p in view_paths] + [
                "--for", args.for_preset, "--yes", "--no-open",
            ]
            result = run_tripo("make", *make_args)
        else:
            result = run_tripo("redo", "@last", "--yes", "--no-open")

        consumed = result.get("credits_consumed", 0) or 0
        total_consumed += consumed
        task_id = result.get("task_id", "?")
        print(f"  candidate {letter}: task {task_id}, {consumed} credits")

        dest = out_root / f"tripo_{letter}"
        src_dir = result.get("output_dir")
        if src_dir and pathlib.Path(src_dir).is_dir():
            if dest.exists():
                shutil.rmtree(dest)
            shutil.copytree(src_dir, dest)
        else:
            print(f"    warning: no output_dir in result, nothing copied to {dest}", file=sys.stderr)

        manifest["candidates"].append({
            "candidate": letter,
            "task_id": task_id,
            "credits_consumed": consumed,
            "local_path": str(dest.relative_to(meshy.ROOT)) if dest.exists() else None,
        })
        (dest / "provenance.json").write_text(json.dumps({
            "provider": "tripo",
            "tripo_cli_version": subprocess.run(
                [TRIPO_BIN, "--version"], capture_output=True, text=True
            ).stdout.strip(),
            "species": species,
            "task_id": task_id,
            "for_preset": args.for_preset,
            "views": [str(p.relative_to(meshy.ROOT)) for p in view_paths],
            "credits_consumed": consumed,
            "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        }, indent=2)) if dest.exists() else None

    after = run_tripo("balance").get("balance", "?")
    manifest["balance_before"] = before
    manifest["balance_after"] = after
    manifest["total_credits_consumed"] = total_consumed
    (out_root / "tripo_manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"balance after: {after} credits (this run: {total_consumed})")
    print(f"manifest: {out_root / 'tripo_manifest.json'}  (no key is recorded in it)")
    print("Add a row to docs/specs/ASSET_LEDGER.md before any tripo_* candidate ships.")


def cmd_status(args) -> None:
    print(json.dumps(run_tripo("task", "get", args.task_ref), indent=2))


def cmd_fetch(args) -> None:
    result = run_tripo("task", "get", args.task_ref, "--download")
    src_dir = result.get("output_dir")
    if not src_dir or not pathlib.Path(src_dir).is_dir():
        sys.exit(f"task {args.task_ref}: no downloadable output_dir in result")
    dest = pathlib.Path(args.out).resolve()
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(src_dir, dest)
    print(f"downloaded {args.task_ref} -> {dest}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("check", help="verify the key and print the balance").set_defaults(func=cmd_check)
    sub.add_parser("balance", help="raw balance response").set_defaults(func=cmd_balance)

    gen = sub.add_parser("generate", help="submit multiview candidates for a species from its reference crops")
    gen.add_argument("species")
    gen.add_argument("--candidates", type=int, default=3)
    gen.add_argument("--for", dest="for_preset", default="game-pc",
                      choices=["game-mobile", "game-pc", "film", "print", "ar-web", "anim", "toy"])
    gen.add_argument("--yes", action="store_true", help="skip the candidate-count budget guard")
    gen.set_defaults(func=cmd_generate)

    status = sub.add_parser("status", help="one task's progress (task id or @last)")
    status.add_argument("task_ref")
    status.set_defaults(func=cmd_status)

    fetch = sub.add_parser("fetch", help="download a finished task's artifacts")
    fetch.add_argument("task_ref")
    fetch.add_argument("--out", required=True)
    fetch.set_defaults(func=cmd_fetch)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
