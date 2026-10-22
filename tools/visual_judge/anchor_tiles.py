#!/usr/bin/env python3
"""Cut blind anchor tiles from anchors.json into a judge folder.

Each picked anchor pair (both sides of one committed sheet row) becomes one
image: label strips blanked, the two sides placed left/right in a random
order under neutral "A"/"B" captions, and a random set code as the file name.
The key (code -> anchor ids per side) goes to --key, which must sit outside
the judge folder. sets.md in the judge folder gets one neutral line per code.

    python3 tools/visual_judge/anchor_tiles.py --out <judge>/ --key <outside>/anchor_key.json
"""
import argparse
import json
import random
import string
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
ANCHORS = Path(__file__).resolve().parent / "anchors" / "anchors.json"
CAPTION = 28
GAP = 8
BG = (30, 30, 30)


def load(path=ANCHORS):
    return json.loads(Path(path).read_text())["anchors"]


def groups(anchors):
    out = {}
    for a in anchors:
        out.setdefault(a["group"], []).append(a)
    return out


def pick(anchors, n_groups, rng):
    """Pick n_groups pairs spread over the reference range, one item each where possible."""
    pairs = [g for g in groups(anchors).values() if len(g) == 2]
    pairs.sort(key=lambda g: sum(a["reference"] for a in g) / 2)
    bins = [pairs[i * len(pairs) // n_groups:(i + 1) * len(pairs) // n_groups] for i in range(n_groups)]
    chosen, items = [], set()
    for b in bins:
        fresh = [g for g in b if g[0]["item"] not in items] or b
        g = rng.choice(fresh)
        chosen.append(g)
        items.add(g[0]["item"])
    return chosen


def side_image(a):
    im = Image.open(ROOT / a["sheet"]).convert("RGB")
    draw = ImageDraw.Draw(im)
    for m in a.get("masks", []):
        draw.rectangle([m[0], m[1], m[2] - 1, m[3] - 1], fill=BG)
    return im.crop(tuple(a["box"]))


def compose(left, right):
    h = max(left.height, right.height)
    tile = Image.new("RGB", (left.width + GAP + right.width, h + CAPTION), BG)
    tile.paste(left, (0, CAPTION))
    tile.paste(right, (left.width + GAP, CAPTION))
    d = ImageDraw.Draw(tile)
    try:
        font = ImageFont.load_default(size=20)
    except TypeError:  # Pillow < 10.1
        font = ImageFont.load_default()
    d.text((8, 3), "A", fill=(235, 235, 235), font=font)
    d.text((left.width + GAP + 8, 3), "B", fill=(235, 235, 235), font=font)
    return tile


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--out", required=True, help="judge folder (tiles + sets.md)")
    p.add_argument("--key", required=True, help="key file, outside the judge folder")
    p.add_argument("--pairs", type=int, default=3, help="anchor pairs to include (each gives 2 tiles; min 2)")
    p.add_argument("--seed", type=int, default=None)
    p.add_argument("--anchors", default=str(ANCHORS))
    args = p.parse_args(argv)
    out, key = Path(args.out).resolve(), Path(args.key).resolve()
    if out in key.parents:
        p.error("--key must be outside the judge folder")
    if args.pairs < 2:
        p.error("--pairs must be at least 2 (4 anchor tiles)")
    rng = random.Random(args.seed)
    out.mkdir(parents=True, exist_ok=True)
    taken = {f.stem for f in out.glob("*.png")}
    record, lines = {}, []
    for g in pick(load(args.anchors), args.pairs, rng):
        sides = g[:]
        rng.shuffle(sides)
        code = None
        while code is None or code in taken:
            code = rng.choice(string.ascii_uppercase) + rng.choice(string.ascii_lowercase)
        taken.add(code)
        compose(side_image(sides[0]), side_image(sides[1])).save(out / f"{code}.png")
        record[code] = {"A": sides[0]["id"], "B": sides[1]["id"]}
        brief = sides[0]["judge_brief"]
        lines.append(f"- {code}.png: side A left, side B right. {brief}")
        if sides[0]["defects"]:
            lines.append(f"  Recorded defects: " + "; ".join(f'"{d}"' for d in sides[0]["defects"]))
    with open(out / "sets.md", "a") as f:
        f.write("\n".join(lines) + "\n")
    key.parent.mkdir(parents=True, exist_ok=True)
    key.write_text(json.dumps(record, indent=1) + "\n")
    print(f"{len(record)} anchor pairs ({2 * len(record)} tiles) -> {out}; key -> {key}")


if __name__ == "__main__":
    main()
