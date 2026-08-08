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
VIEWS = ["front", "side", "back", "three_quarter", "head"]

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
## Two negative lists, because the creature one bans "humanoid anatomy" and
## "clothing" — which, sent with a HUMAN character, tells the generator to
## fight the subject itself. The first trainer batch went out with exactly
## that mistake and was resubmitted.
NEGATIVE_CREATURE = ("photorealistic fur, strand hair, humanoid anatomy, clothing, armor, "
            "weapons, accessories, generic real-world animal, hyperreal claws, "
            "excessive moss, noisy surface detail, wet plastic shading, "
            "text, watermark, multiple creatures, base, pedestal, "
            # Round-2 additions, each one a specific invention the blind critique
            # found in a round-1 candidate.
            "bushy tail, upturned tail, paddle tail, beaver tail, long legs, "
            "tall slender body, fox proportions")
NEGATIVE_HUMAN = ("photorealistic skin, realistic human proportions, armor, weapons, "
            "sword, staff, gun, cape, robe, extra fingers, fused fingers, "
            "noisy surface detail, wet plastic shading, "
            "text, watermark, multiple people, base, pedestal")
HUMANS = {"trainer", "grandpa", "warden"}


## The legendary is made OF plants, so the creature list's "excessive moss"
## and the style line's "restrained surface detail" would fight its design.
NEGATIVE_PLANT = ("photorealistic bark, realistic deer, scary, skeletal, "
            "humanoid anatomy, clothing, armor, weapons, rider, saddle, "
            "wet plastic shading, text, watermark, multiple creatures, "
            "base, pedestal")


def negative_for(species: str) -> str:
    if species == "veridian":
        return NEGATIVE_PLANT
    return NEGATIVE_HUMAN if species in HUMANS else NEGATIVE_CREATURE

## Per-species prompt, from docs/art/CLAUDE_BUILD_PROMPTS.md. The markdown is
## authoritative over anything an image generator wrote onto a sheet, so the
## words that drive generation come from there rather than from reading a PNG.
SPECIES_PROMPTS = {
    # Round 2 wording. The round-1 prompt said "oversized digging forepaws" and
    # "short tail with a stone tip" once each, and the blind critique of the
    # three round-1 meshes found exactly those two features missing: the best
    # candidate's forepaws were "barely distinguishable from the hind paws" and
    # two of three tails were invented (one bushy up-curl, one beaver paddle).
    # What the generator under-weighted is now stated harder and earlier, and
    # the stance drift the critique named ("too leggy... fox cub") gets its own
    # clause. The features it got right unprompted (mantle, face) keep their
    # original weight.
    "terrapup": (
        "small sturdy quadruped ground creature, badger and canine influence. "
        "ENORMOUS oversized front paws, much wider and deeper than the hind "
        "paws, with long splayed digging claws nearly as tall as the forearm. "
        "Short thick legs, low-slung belly close to the ground, compact tank-"
        "like stance. Short LOW-HANGING tail capped with one large faceted "
        "stone, never bushy, never curled up. Warm brown fur with cream face "
        "stripe and cream chest, spiky fur crest on the skull, cheek ruff, "
        "grey stone plates in separate rows forming a mantle across shoulders "
        "and back with visible gaps between plates, subtle moss in the seams, "
        "dark paw pads, large expressive teal eyes, friendly and loyal, short "
        "blunt muzzle with a big round nose"),
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
    # Round 2 wording. The blind critique found four SYSTEMATIC defects across
    # all six round-1 candidates: featureless egg faces ("no eye sockets, no
    # brow ridge, no mouth... zero nose projection"), ~4.8-head chibi
    # proportions against the sheet's 6.25, no fingerless gloves anywhere, and
    # a four-digit maximum on hands. Its verdict: regenerate with those named.
    "trainer": (
        "stylised young human explorer with FULLY SCULPTED FACIAL FEATURES: "
        "defined eye sockets, eyebrows, projecting nose and mouth geometry. "
        "Slim teenage build, six and a quarter heads tall, long legs, NOT "
        "chibi. Five separated fingers on each hand, brown fingerless gloves "
        "with knuckle cuffs. Teal jacket open over cream shirt, rolled "
        "sleeves, dark cargo trousers, chunky brown leather boots, canvas "
        "backpack with visible shoulder straps, brass and glass orb holder "
        "device at the belt, brown tousled spiky hair, friendly confident "
        "expression"),
    # The twelve wild Meadows species, condensed from their sections in
    # docs/art/CLAUDE_BUILD_PROMPTS.md. Every one states its signature
    # feature in capitals and first, because five rounds of critique have
    # now shown the generator drops whatever is mentioned once in passing.
    "bramblebun": (
        "compact meadow rabbit creature, warm tan fur, pale cream belly, LONG"
        "expressive upright ears, BROAD powerful hind feet, small burr and"
        "seedpod accents and earth-tone markings, NO leaves and NO plant"
        "styling, bright alert eyes, light quick prey-animal silhouette with"
        "a friendly face"
    ),
    "tuskroot": (
        "stocky powerful boar creature with a LOW centre of gravity and a"
        "heavy front end, SHORT CURVED TUSKS jutting up from the lower jaw,"
        "coarse warm brown fur, darker ears and legs, hard stone brow ridge,"
        "dirt-caked stone plates over the shoulders, small eyes, appealing"
        "and powerful, never ugly or realistic"
    ),
    "trailpup": (
        "young prairie coyote-like canine creature, sandy coat with a darker"
        "stripe down the back, cream muzzle and chest, OVERSIZED ears and"
        "OVERSIZED paws, bright intelligent eyes, lean adventurous build,"
        "never a real-world dog breed"
    ),
    "ridgewolf": (
        "mature prairie wolf creature, sandy coat with a dark back stripe,"
        "cream muzzle and chest, TALL and LONG-LEGGED, THICK neck ruff, sharp"
        "pointed ears, subtle stone and earth ridges emerging along the"
        "shoulders and forelegs, intelligent friendly eyes, noble not"
        "monstrous, no armour"
    ),
    "meadowhart": (
        "graceful sturdy deer creature built to be ridden, warm tawny coat,"
        "cream underside, dark hooves, COMPACT branch-like antlers with"
        "subtle stone growth, expressive gentle face, strong level back, calm"
        "bearing"
    ),
    "burrowback": (
        "squat broad powerful digging badger creature, LOW to the ground and"
        "WIDE, charcoal and brown coat with a cream stripe running up the"
        "face, ENORMOUS shovel claws on the front paws, a few loose stone"
        "nodules on the back, NOT a full stone shell, small determined eyes"
    ),
    "paddlenewt": (
        "small rounded amphibious newt creature, bright aqua skin, cream"
        "underside, soft translucent frill crest along the head and back,"
        "WEBBED feet, wide friendly eyes, low four-legged stance, smooth wet-"
        "looking skin with no fur"
    ),
    "mosshell": (
        "stylised pond turtle creature, BLUE-GREEN skin, broad smooth domed"
        "shell with pond-stone patterning and restrained moss in the seams,"
        "kind patient face, sturdy legs, WATER creature first and mossy"
        "second"
    ),
    "brooktail": (
        "cheerful semi-aquatic otter creature, streamlined torso, BROAD FLAT"
        "PADDLE TAIL, chestnut and cream fur, small aqua accents on the tail"
        "and paws, whiskers, playful bright eyes, low four-legged stance"
    ),
    "reedwing": (
        "stylised water bird, duck and heron influence, TEAL-BLUE primary"
        "feathers, cream chest, warm tan accents, WEBBED FEET, broad readable"
        "wings held slightly open, long neck, alert friendly face, reads as"
        "both a swimmer and a flier"
    ),
    "pipwing": (
        "tiny round songbird creature, cream body, SKY-BLUE wings with dark"
        "tips, OVERSIZED expressive eyes, small crest on the head, short"
        "beak, plump strong silhouette that reads at very small size"
    ),
    "duskhush": (
        "medium owl creature, soft grey-blue and warm cream plumage, LARGE"
        "round eyes without any glow, prominent ear tufts, BROAD soft wings,"
        "calm and gentle expression, mysterious but never spooky, upright"
        "perching stance"
    ),
    "galecrest": (
        "larger raptor creature, hawk and eagle influence, layered slate-blue"
        "and cream feathers with gold and tan accents, BROAD powerful wings"
        "held open, STRONG talons, confident upright stance, sharp beak,"
        "proud expression, powerful but still friendly and stylised"
    ),
    # Board 06, owner-approved as the Warden's source over the earlier boards'
    # off-brief priestess (docs/art/REFERENCE_CANON.md).
    "warden": (
        "stylised human man, commanding antagonist officer. THE FACE MUST BE "
        "FULLY MODELLED: deep eye sockets with visible eyeballs and eyelids, "
        "eyebrows, projecting nose, cut mouth. A half-mask across the eyes, "
        "short swept green hair, confident upright stance, arms at his sides. "
        "Long dark forest-green military coat with gold trim and brass "
        "buttons, thick cream fur-lined collar, pale half-cape over one "
        "shoulder, dark trousers, tall leather boots, belt pouches, gloves. "
        "Five separated fingers on each hand. Seven heads tall, imposing, no "
        "visible weapon"),
    # Board 06's Veridian Stag, likewise owner-approved as the legendary.
    "veridian": (
        "majestic large forest stag guardian, four-legged deer anatomy, "
        "ENORMOUS branching antlers of twisted woody branches with green "
        "leaves growing along them, spanning wider than the body. Mantle of "
        "layered overlapping green leaves across neck and chest like a mane, "
        "body of weathered bark and wood with golden vein patterns winding "
        "along the flanks and legs, cream muzzle, leaf tuft at the tail, "
        "calm noble expression, ancient and serene, standing tall and still"),
    # From docs/art/CLAUDE_BUILD_PROMPTS.md §17. His reference is the weakest
    # in the pack — four ~90px figures cut from board 05, not a production
    # sheet — so the words carry more of the load here than for the starters.
    # Round 2 wording. The blind critique of round 1 found humanoid failures
    # on every candidate — a severed floating forearm, eye regions with "no
    # lids, no sockets, no brow break", elf ears, mitten hands — so the round-2
    # prompt names each of those as a requirement, the same move that fixed
    # Terrapup's paws.
    "grandpa": (
        "stylised elderly human man, late 60s, retired explorer. DETAILED "
        "FACE with clearly sculpted eyes, eyelids and brow, kind warm "
        "expression, ROUND human ears, VOLUMETRIC full white beard and "
        "moustache, swept white hair. Both arms complete and symmetrical, "
        "relaxed A-pose slightly away from the body, five separated fingers "
        "on each hand. Muted green vest layered over cream shirt with rolled "
        "sleeves, brown trousers, sturdy leather boots, green neck scarf, "
        "small belt pouches, old field satchel, empty hands, no armor, no "
        "weapon, no staff, six heads tall, gentle grandfather posture"),
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
    """Whatever views this species actually has, in VIEWS order.

    Not all of them, for everyone. The Warden's board gives three turnarounds
    and a bust; the legendary's gives two clean hero views among two
    contaminated thumbnails; Grandpa's gives three plus a face portrait.
    Demanding a fixed set either fabricates a view or blocks a character whose
    reference is simply smaller, and multi-image-to-3D reconciles two good
    images better than four bad ones.
    """
    directory = REFERENCE_ROOT / species / "reference"
    found = {view: directory / f"{view}.png"
             for view in VIEWS if (directory / f"{view}.png").exists()}
    if len(found) < 2:
        sys.exit(f"{species} has {len(found)} reference view(s) in {directory}; "
                 f"need at least 2.\nRun tools/art_pipeline/crop_views.py first.")
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
        "image_urls": [data_uri(p) for p in views.values()],
        "prompt": prompt,
        "negative_prompt": negative_for(species),
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
        "negative_prompt": negative_for(species),
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


## Task endpoints, by the stage that created the task. Every Meshy task type
## lives under its own path and none of them answer for another's ids.
ENDPOINTS = {
    "generate": "/openapi/v1/multi-image-to-3d",
    "text": "/openapi/v2/text-to-3d",
    "texture": "/openapi/v1/retexture",
    "rig": "/openapi/v1/rigging",
    "animate": "/openapi/v1/animations",
}


def poll(task_id: str, endpoint: str, quiet: bool = False) -> dict:
    deadline = time.time() + POLL_TIMEOUT
    while time.time() < deadline:
        task = request("GET", f"{endpoint}/{task_id}")
        status = task.get("status", "?")
        if status in ("SUCCEEDED", "FAILED", "CANCELED", "EXPIRED"):
            return task
        if not quiet:
            print(f"  {status} {task.get('progress', 0)}%", flush=True)
        time.sleep(POLL_SECONDS)
    sys.exit(f"{task_id} did not finish within {POLL_TIMEOUT // 60} minutes")


def cmd_status(args) -> None:
    task = request("GET", f"{ENDPOINTS[args.stage]}/{args.task_id}")
    print(f"{args.task_id}: {task.get('status')} {task.get('progress', 0)}%")
    if task.get("task_error"):
        print(f"  error: {task['task_error']}")
    for name, url in (task.get("model_urls") or {}).items():
        print(f"  {name}: {'ready' if url else '-'}")


def cmd_fetch(args) -> None:
    task = poll(args.task_id, ENDPOINTS[args.stage])
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
        "endpoint": ENDPOINTS[args.stage].rsplit("/", 1)[-1],
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


def cmd_text(args) -> None:
    """Generate from the written spec alone, for a species with no sheet.

    The three starters, the trainer, Grandpa, the Warden and the legendary all
    have drawn reference. The twelve wild Meadows species do not — they exist
    as prose in docs/art/CLAUDE_BUILD_PROMPTS.md and as scattered silhouette
    donors on the exploration boards, which is not enough to reconcile a
    multi-view reconstruction.

    So: text-to-3D for the FORM, then `texture` against a starter's concept
    crop for the STYLE. That second half is the important half. Style cohesion
    is the complaint that survived two blind reviews of the old roster —
    "two assets from two different pipelines" — and pointing every wild
    creature's texture pass at the same drawn reference is what stops thirteen
    independently-generated animals from looking like thirteen packs.
    """
    prompt = prompt_for(args.species)
    before = request("GET", "/openapi/v1/balance").get("balance", 0)
    estimate = args.candidates * 5
    print(f"{args.species}: {args.candidates} candidate(s), text-to-3D preview")
    print(f"balance {before} credits, this will cost roughly {estimate}")
    if estimate > args.budget and not args.yes:
        sys.exit(f"estimate {estimate} exceeds --budget {args.budget}.")

    manifest = {"species": args.species, "mode": "text-to-3d", "prompt": prompt,
                "negative_prompt": negative_for(args.species), "tasks": []}
    for index in range(args.candidates):
        result = request("POST", ENDPOINTS["text"], {
            "mode": "preview",
            "prompt": prompt,
            "negative_prompt": negative_for(args.species),
            "art_style": "realistic",
            "should_remesh": True,
            "topology": "quad",
            "target_polycount": args.polycount,
            "symmetry_mode": "auto",
        })
        task_id = result.get("result") or result.get("id")
        letter = chr(ord("a") + index)
        manifest["tasks"].append({"candidate": letter, "task_id": task_id})
        print(f"  candidate {letter}: {task_id}")

    out = RAW_ROOT / args.species
    out.mkdir(parents=True, exist_ok=True)
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2))


def cmd_texture(args) -> None:
    """Texture a local GLB against the species' own concept art.

    Retexture rather than re-generating with textures on, for two reasons.
    First, §25: form was selected at the cheap tier, and only the winner gets
    textured. Second, retexture takes `image_style_url` — the 3/4 concept crop
    itself — which aims the texturing at the drawing instead of at a text
    description of the drawing. The words come along too, but the image is the
    stronger signal and it is the exact likeness being scored.
    """
    model = pathlib.Path(args.model).resolve()
    if not model.exists():
        sys.exit(f"no such model: {model}")
    # A wild species has no crops of its own; --style-from points its texture
    # pass at a species that does, which is how thirteen separately-generated
    # animals end up looking like one pack.
    views = reference_views(args.style_from or args.species)

    payload = {
        "model_url": ("data:model/gltf-binary;base64,"
                      + __import__("base64").b64encode(model.read_bytes()).decode()),
        "text_style_prompt": prompt_for(args.species)[:600],
        "image_style_url": data_uri(views.get("three_quarter") or views.get("front")
                                   or next(iter(views.values()))),
        "enable_pbr": True,
        "enable_original_uv": False,
        "texture_resolution": args.resolution,
        "ai_model": "latest",
    }
    result = request("POST", ENDPOINTS["texture"], payload)
    task_id = result.get("result") or result.get("id")
    print(f"texture task: {task_id}")
    print(f"fetch with: tools/art_pipeline/meshy.py fetch {task_id} "
          f"--stage texture --out <dir>")


def cmd_rig(args) -> None:
    """Submit a textured GLB for auto-rigging.

    Meshy documents this as HUMANOID-only, and Terrapup is a quadruped, so this
    is expected to fail or produce nonsense for creatures — it exists because
    trying costs a few credits and the answer becomes a fact in the production
    report instead of an assumption. The trainer, when its turn comes, is the
    real customer.
    """
    model = pathlib.Path(args.model).resolve()
    if not model.exists():
        sys.exit(f"no such model: {model}")
    payload = {
        "model_url": ("data:model/gltf-binary;base64,"
                      + __import__("base64").b64encode(model.read_bytes()).decode()),
        "height_meters": args.height,
    }
    result = request("POST", ENDPOINTS["rig"], payload)
    task_id = result.get("result") or result.get("id")
    print(f"rig task: {task_id}")
    print(f"fetch with: tools/art_pipeline/meshy.py fetch {task_id} --stage rig --out <dir>")


def cmd_animate(args) -> None:
    payload = {"rig_task_id": args.rig_task_id, "action_id": args.action_id}
    result = request("POST", ENDPOINTS["animate"], payload)
    task_id = result.get("result") or result.get("id")
    print(f"animation task: {task_id}")
    print(f"fetch with: tools/art_pipeline/meshy.py fetch {task_id} "
          f"--stage animate --out <dir>")


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

    text = sub.add_parser("text", help="generate from the written spec (no sheet)")
    text.add_argument("species")
    text.add_argument("--candidates", type=int, default=2)
    text.add_argument("--polycount", type=int, default=30000)
    text.add_argument("--budget", type=int, default=DEFAULT_BUDGET)
    text.add_argument("--yes", action="store_true")
    text.set_defaults(func=cmd_text)

    texture = sub.add_parser("texture", help="retexture a local GLB against the concept art")
    texture.add_argument("species")
    texture.add_argument("model", help="path to the winning candidate's GLB")
    texture.add_argument("--resolution", choices=["2k", "4k"], default="2k")
    texture.add_argument("--style-from", default=None,
                         help="take the style image from another species' crops")
    texture.set_defaults(func=cmd_texture)

    rig = sub.add_parser("rig", help="auto-rig a textured GLB (Meshy: humanoid-only)")
    rig.add_argument("model")
    rig.add_argument("--height", type=float, default=1.7)
    rig.set_defaults(func=cmd_rig)

    animate = sub.add_parser("animate", help="apply a library action to a rig task")
    animate.add_argument("rig_task_id")
    animate.add_argument("action_id", type=int)
    animate.set_defaults(func=cmd_animate)

    status = sub.add_parser("status", help="one task's progress")
    status.add_argument("task_id")
    status.add_argument("--stage", choices=list(ENDPOINTS), default="generate")
    status.set_defaults(func=cmd_status)

    fetch = sub.add_parser("fetch", help="wait for a task and download it")
    fetch.add_argument("task_id")
    fetch.add_argument("--stage", choices=list(ENDPOINTS), default="generate")
    fetch.add_argument("--out", required=True)
    fetch.set_defaults(func=cmd_fetch)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
