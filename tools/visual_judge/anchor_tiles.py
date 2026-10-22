#!/usr/bin/env python3
"""Build one blind judging folder: anchor tiles and candidate pairs, same format.

Every set becomes one image with a random two-letter code: side A on the left,
side B on the right, a caption strip naming only "A" and "B", sides in random
order. Anchor pairs come from anchors.json (label strips masked first, at
least 3 pairs from at least 2 items, spread over the reference range).
Candidate pairs come from a spec file:

    [{"label": "F10#2 r9", "a": "<side image>", "b": "<side image>",
      "brief": "<what the set shows, neutral>", "defects": ["<catalog defect>"]}]

Written into the judge folder: <code>.png per set, and sets.md (one neutral
line per code, anchors and candidates shuffled together; paste it into the
prompt's [SET LIST]). Written next to --key, outside the judge folder: the key
(code -> anchor id or candidate label/side) and recorded_defects.txt (every
code's defects or "none"; paste it into [RECORDED DEFECTS]).

    python3 tools/visual_judge/anchor_tiles.py --out <judge> --key <outside>/key.json \
        --candidates <spec.json> [--pairs 3] [--include craft] [--seed N]
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
MIN_PAIRS = 3


def load(path=ANCHORS):
    return json.loads(Path(path).read_text())["anchors"]


def groups(anchors):
    out = {}
    for a in anchors:
        out.setdefault(a["group"], []).append(a)
    return out


def pair_groups(anchors):
    pairs = [g for g in groups(anchors).values() if len(g) == 2]
    pairs.sort(key=lambda g: sum(a["reference"] for a in g) / 2)
    return pairs


def pick(anchors, n_pairs, rng, include=()):
    """n_pairs anchor pairs spread over the reference range, at least two distinct items.

    Each reference-range bin contributes one pair, preferring an item not yet
    used; a bin with no unused item draws from another bin's unused item.
    Groups named in include are taken first.
    """
    pairs = pair_groups(anchors)
    if n_pairs > len(pairs):
        raise ValueError(f"--pairs {n_pairs} exceeds the {len(pairs)} anchor pairs available")
    by_name = {g[0]["group"]: g for g in pairs}
    unknown = [n for n in include if n not in by_name]
    if unknown:
        raise ValueError(f"unknown anchor group(s): {', '.join(unknown)} (choose from {', '.join(by_name)})")
    chosen = [by_name[n] for n in dict.fromkeys(include)]
    if len(chosen) > n_pairs:
        raise ValueError("more --include groups than --pairs")
    items = {g[0]["item"] for g in chosen}
    remaining = n_pairs - len(chosen)
    bins = [pairs[i * len(pairs) // remaining:(i + 1) * len(pairs) // remaining]
            for i in range(remaining)] if remaining else []
    for b in bins:
        unused = [g for g in pairs if g not in chosen]
        fresh = ([g for g in b if g in unused and g[0]["item"] not in items]
                 or [g for g in unused if g[0]["item"] not in items]
                 or [g for g in b if g in unused] or unused)
        g = rng.choice(fresh)
        chosen.append(g)
        items.add(g[0]["item"])
    if len(items) < 2:
        raise ValueError("anchor pairs must come from at least two distinct items")
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


def key_outside(out, key):
    return not (key == out or out in key.parents)


def build(out, key, n_pairs, rng, candidates=(), include=(), anchors_path=ANCHORS):
    out, key = Path(out).resolve(), Path(key).resolve()
    if not key_outside(out, key):
        raise ValueError("--key must be outside the judge folder")
    if n_pairs < MIN_PAIRS:
        raise ValueError(f"--pairs must be at least {MIN_PAIRS}")
    if (out / "sets.md").exists():
        raise ValueError(f"{out / 'sets.md'} exists; build each batch into a fresh judge folder")
    sets = []  # (image, key entry, brief, defects)
    for g in pick(load(anchors_path), n_pairs, rng, include):
        sides = g[:]
        rng.shuffle(sides)
        sets.append((compose(side_image(sides[0]), side_image(sides[1])),
                     {"anchor": True, "A": sides[0]["id"], "B": sides[1]["id"]},
                     sides[0]["judge_brief"], sides[0]["defects"]))
    for c in candidates:
        paths = [c["a"], c["b"]]
        rng.shuffle(paths)
        ims = [Image.open(p).convert("RGB") for p in paths]
        sets.append((compose(*ims), {"anchor": False, "label": c["label"], "A": paths[0], "B": paths[1]},
                     c["brief"], c.get("defects", [])))
    rng.shuffle(sets)
    out.mkdir(parents=True, exist_ok=True)
    taken = {f.stem for f in out.glob("*.png")}
    record, set_lines, defect_lines = {}, [], []
    for image, entry, brief, defects in sets:
        code = None
        while code is None or code in taken:
            code = rng.choice(string.ascii_uppercase) + rng.choice(string.ascii_lowercase)
        taken.add(code)
        image.save(out / f"{code}.png")
        record[code] = entry
        set_lines.append(f"- {code}.png: side A left, side B right. {brief}")
        defect_lines.append(f"{code}: " + ("; ".join(f'"{d}"' for d in defects) if defects else "none"))
    (out / "sets.md").write_text("\n".join(set_lines) + "\n")
    key.parent.mkdir(parents=True, exist_ok=True)
    key.write_text(json.dumps(record, indent=1) + "\n")
    (key.parent / "recorded_defects.txt").write_text("\n".join(defect_lines) + "\n")
    return record


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--out", required=True, help="judge folder (set images + sets.md)")
    p.add_argument("--key", required=True, help="key file, outside the judge folder")
    p.add_argument("--candidates", help="candidate spec JSON (see module doc)")
    p.add_argument("--pairs", type=int, default=MIN_PAIRS,
                   help=f"anchor pairs (each gives 2 tiles; min and default {MIN_PAIRS})")
    p.add_argument("--include", action="append", default=[], help="anchor group to include (repeatable)")
    p.add_argument("--seed", type=int, default=None)
    p.add_argument("--anchors", default=str(ANCHORS))
    args = p.parse_args(argv)
    cands = json.loads(Path(args.candidates).read_text()) if args.candidates else []
    try:
        record = build(args.out, args.key, args.pairs, random.Random(args.seed), cands, args.include, args.anchors)
    except ValueError as e:
        p.error(str(e))
    n_anchor = sum(1 for e in record.values() if e["anchor"])
    print(f"{n_anchor} anchor pairs ({2 * n_anchor} tiles) and {len(record) - n_anchor} candidate sets "
          f"-> {args.out}; key and recorded_defects.txt -> {Path(args.key).resolve().parent}")


if __name__ == "__main__":
    main()
