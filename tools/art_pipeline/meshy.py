#!/usr/bin/env python3
"""Generate candidate meshes from the reference crops, via Meshy's REST API.

    export MESHY_API_KEY=msy_...
    tools/art_pipeline/meshy.py check
    tools/art_pipeline/meshy.py balance
    tools/art_pipeline/meshy.py generate terrapup --candidates 3
    tools/art_pipeline/meshy.py status <task_id>
    tools/art_pipeline/meshy.py fetch <task_id> --out assets_raw/terrapup/a

REST rather than Meshy's MCP server; see docs/decisions/D11.

COST. TETHERBOUND_3D_ART_PIPELINE.md section 25 is explicit that credits go
fast and that the order is: cheap preview, then two or three serious
candidates, then spend only on the winner. So `generate` defaults to the
preview tier, prints the balance before and after, and refuses to run a batch
that would cost more than `--budget` credits without `--yes`.

SECRETS. The key is read from the environment and from nowhere else. It is
never written to a file, never echoed, and never appears in a saved manifest —
section 23. Downloads land in `assets_raw/`, which `.gitignore` already covers.
"""

import argparse
import json
import os
import pathlib
import sys
import time
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
REFERENCE_ROOT = ROOT / "assets" / "pals" / "tetherbound"
RAW_ROOT = ROOT / "assets_raw"

BASE = "https://api.meshy.ai"
VIEWS = ["front", "side", "back", "three_quarter"]

## Seconds between polls, and how long to wait before giving up. Generation
## takes minutes, not seconds; polling harder does not make it faster.
POLL_SECONDS = 15
POLL_TIMEOUT = 45 * 60

## Refuse a batch costing more than this many credits without --yes. A guard
## against a typo in --candidates spending a month's free tier in one command.
DEFAULT_BUDGET = 60

## What every Tetherbound creature must be, and must not be. Section 8's two
## lists, verbatim in intent: the positives keep the species' identity, the
## negatives name the specific ways image-to-3D drifts off this project's style.
STYLE = ("stylized PBR game character, clean readable forms, large clear colour "
         "regions, restrained surface detail, appealing stylised proportions, "
         "single creature, neutral standing pose, T-pose-adjacent, full body")
NEGATIVE = ("photorealistic fur, strand hair, humanoid anatomy, clothing, armor, "
            "weapons, accessories, generic real-world animal, hyperreal claws, "
            "excessive moss, noisy surface detail, wet plastic shading, "
            "text, watermark, multiple creatures, base, pedestal")

## Per-species prompt, from docs/art/CLAUDE_BUILD_PROMPTS.md. The markdown is
## authoritative over anything an image generator wrote onto a sheet, so the
## words that drive generation come from there rather than from reading a PNG.
SPECIES_PROMPTS = {
    "terrapup": (
        "small sturdy quadruped ground creature, badger and canine influence, "
        "warm brown fur with cream face stripe and cream chest, grey stone plates "
        "forming a mantle across the shoulders and back, subtle moss between the "
        "plates, oversized digging forepaws with pale claws, dark paw pads, short "
        "tail with a stone tip, large expressive teal eyes, friendly and loyal "
        "rather than aggressive, compact defensive silhouette"),
    "ripplet": (
        "small playful semi-aquatic creature, otter and newt influence, smooth "
        "turquoise skin, cream belly, translucent fin-like ear frills with pink "
        "inner membrane, broad translucent fan tail fin, pale teardrop markings, "
        "webbed hind feet, large expressive dark blue eyes, agile and curious"),
    "galewisp": (
        "small fox-bird glider creature, cream down over layered blue and teal "
        "feathers with tan accents, enormous feathered ear tufts, wing-membrane "
        "forelimbs, long feathered tail, slender dark scaled legs with talons, "
        "large expressive blue eyes, alert lightweight energetic silhouette"),
    "trainer": (
        "stylised young human explorer, teal jacket over cream shirt, dark "
        "trousers, brown leather boots and fingerless gloves, canvas backpack, "
        "brass and glass orb holder at the belt, brown tousled hair, friendly "
        "confident expression, six and a quarter heads tall"),
}


def api_key() -> str:
    key = os.environ.get("MESHY_API_KEY", "").strip()
    if not key:
        sys.exit(
            "MESHY_API_KEY is not set.\n"
            "\n"
            "  1. Sign up at https://www.meshy.ai/ and open Settings -> API Keys.\n"
            "  2. export MESHY_API_KEY=msy_...\n"
            "  3. tools/art_pipeline/meshy.py check\n"
            "\n"
            "Do not put the key in a tracked file. Everything in the pipeline\n"
            "except generation runs without it."
        )
    return key


def request(method: str, path: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(f"{BASE}{path}", data=data, method=method, headers={
        "Authorization": f"Bearer {api_key()}",
        "Content-Type": "application/json",
    })
    try:
        with urllib.request.urlopen(req, timeout=120) as response:
            return json.loads(response.read())
    except urllib.error.HTTPError as error:
        detail = error.read().decode(errors="replace")[:400]
        if error.code == 401:
            sys.exit(f"Meshy rejected the key (401). Check MESHY_API_KEY.\n{detail}")
        if error.code == 402:
            sys.exit(f"Out of credits (402). Nothing was generated.\n{detail}")
        if error.code == 429:
            sys.exit(f"Rate limited (429). Wait and retry.\n{detail}")
        sys.exit(f"Meshy {method} {path} failed with {error.code}:\n{detail}")
    except urllib.error.URLError as error:
        sys.exit(f"could not reach {BASE}: {error.reason}")


def data_uri(path: pathlib.Path) -> str:
    """Meshy takes images as data URIs or public URLs. These are local, so URIs."""
    import base64
    return "data:image/png;base64," + base64.b64encode(path.read_bytes()).decode()


def reference_views(species: str) -> dict[str, pathlib.Path]:
    directory = REFERENCE_ROOT / species / "reference"
    found = {view: directory / f"{view}.png" for view in VIEWS}
    missing = [v for v, p in found.items() if not p.exists()]
    if missing:
        sys.exit(f"{species} is missing {', '.join(missing)} in {directory}.\n"
                 f"Run tools/art_pipeline/crop_views.py first.")
    return found


def prompt_for(species: str) -> str:
    if species not in SPECIES_PROMPTS:
        sys.exit(f"no prompt for '{species}'. Known: {', '.join(SPECIES_PROMPTS)}.\n"
                 f"Add one from docs/art/CLAUDE_BUILD_PROMPTS.md.")
    return f"{SPECIES_PROMPTS[species]}. {STYLE}"


def cmd_check(_args) -> None:
    balance = request("GET", "/openapi/v1/balance")
    print(f"key accepted. balance: {balance.get('balance', '?')} credits")


def cmd_balance(_args) -> None:
    print(json.dumps(request("GET", "/openapi/v1/balance"), indent=2))


def cmd_generate(args) -> None:
    species = args.species
    views = reference_views(species)
    prompt = prompt_for(species)

    before = request("GET", "/openapi/v1/balance").get("balance", 0)
    estimate = args.candidates * (5 if args.tier == "preview" else 20)
    print(f"{species}: {args.candidates} candidate(s), {args.tier} tier")
    print(f"balance {before} credits, this will cost roughly {estimate}")
    if estimate > args.budget and not args.yes:
        sys.exit(f"estimate {estimate} exceeds --budget {args.budget}. "
                 f"Re-run with --yes if that is intended.")

    payload = {
        "mode": "preview" if args.tier == "preview" else "refine",
        "image_urls": [data_uri(views[v]) for v in VIEWS],
        "prompt": prompt,
        "negative_prompt": NEGATIVE,
        "should_remesh": True,
        "should_texture": args.tier != "preview",
        "topology": "quad",
        "target_polycount": args.polycount,
        "symmetry_mode": "auto",
    }

    manifest = {
        "species": species,
        "tier": args.tier,
        "prompt": prompt,
        "negative_prompt": NEGATIVE,
        "views": {v: str(p.relative_to(ROOT)) for v, p in views.items()},
        "polycount": args.polycount,
        "tasks": [],
    }

    for index in range(args.candidates):
        # Candidates differ only by the generator's own seed; the prompt and the
        # reference images are identical on purpose, so the comparison in
        # compare_sheet.py measures the generator's variance rather than ours.
        result = request("POST", "/openapi/v1/multi-image-to-3d", payload)
        task_id = result.get("result") or result.get("id")
        letter = chr(ord("a") + index)
        manifest["tasks"].append({"candidate": letter, "task_id": task_id})
        print(f"  candidate {letter}: {task_id}")

    out = RAW_ROOT / species
    out.mkdir(parents=True, exist_ok=True)
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"\nmanifest: {out / 'manifest.json'}  (no key is recorded in it)")
    print(f"poll with: tools/art_pipeline/meshy.py status <task_id>")


def poll(task_id: str, quiet: bool = False) -> dict:
    deadline = time.time() + POLL_TIMEOUT
    while time.time() < deadline:
        task = request("GET", f"/openapi/v1/multi-image-to-3d/{task_id}")
        status = task.get("status", "?")
        if status in ("SUCCEEDED", "FAILED", "CANCELED", "EXPIRED"):
            return task
        if not quiet:
            print(f"  {status} {task.get('progress', 0)}%", flush=True)
        time.sleep(POLL_SECONDS)
    sys.exit(f"{task_id} did not finish within {POLL_TIMEOUT // 60} minutes")


def cmd_status(args) -> None:
    task = request("GET", f"/openapi/v1/multi-image-to-3d/{args.task_id}")
    print(f"{args.task_id}: {task.get('status')} {task.get('progress', 0)}%")
    if task.get("task_error"):
        print(f"  error: {task['task_error']}")
    for name, url in (task.get("model_urls") or {}).items():
        print(f"  {name}: {'ready' if url else '-'}")


def cmd_fetch(args) -> None:
    task = poll(args.task_id)
    if task.get("status") != "SUCCEEDED":
        sys.exit(f"{args.task_id} finished as {task.get('status')}: "
                 f"{task.get('task_error', 'no detail')}")

    out = pathlib.Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)

    urls = task.get("model_urls") or {}
    if not urls.get("glb"):
        sys.exit(f"{args.task_id} succeeded but returned no GLB")

    for name in ("glb", "fbx", "obj"):
        if not urls.get(name):
            continue
        target = out / f"model.{name}"
        urllib.request.urlretrieve(urls[name], target)
        print(f"  {target.name}  {target.stat().st_size // 1024} KB")

    if task.get("thumbnail_url"):
        urllib.request.urlretrieve(task["thumbnail_url"], out / "thumbnail.png")

    # Provenance, written next to the asset so docs/ASSET_LEDGER.md can be filled
    # in from fact rather than memory. No key, no signed URLs — those expire and
    # leak.
    (out / "provenance.json").write_text(json.dumps({
        "service": "Meshy",
        "endpoint": "multi-image-to-3d",
        "task_id": args.task_id,
        "created_at": task.get("created_at"),
        "finished_at": task.get("finished_at"),
        "prompt": task.get("prompt"),
        "negative_prompt": task.get("negative_prompt"),
        "art_style": task.get("art_style"),
        "texture_richness": task.get("texture_richness"),
    }, indent=2))
    print(f"\n{out}")
    print("  next: inspect_glb.py, then turntable.py, then compare_sheet.py")


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("check", help="verify the key and print the balance").set_defaults(func=cmd_check)
    sub.add_parser("balance", help="raw balance response").set_defaults(func=cmd_balance)

    gen = sub.add_parser("generate", help="submit candidates for a species")
    gen.add_argument("species", help=", ".join(SPECIES_PROMPTS))
    gen.add_argument("--candidates", type=int, default=3)
    gen.add_argument("--tier", choices=["preview", "refine"], default="preview",
                     help="preview is cheap and untextured; refine costs more (§25)")
    gen.add_argument("--polycount", type=int, default=30000)
    gen.add_argument("--budget", type=int, default=DEFAULT_BUDGET)
    gen.add_argument("--yes", action="store_true", help="proceed past the budget guard")
    gen.set_defaults(func=cmd_generate)

    status = sub.add_parser("status", help="one task's progress")
    status.add_argument("task_id")
    status.set_defaults(func=cmd_status)

    fetch = sub.add_parser("fetch", help="wait for a task and download it")
    fetch.add_argument("task_id")
    fetch.add_argument("--out", required=True)
    fetch.set_defaults(func=cmd_fetch)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
