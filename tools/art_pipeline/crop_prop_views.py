#!/usr/bin/env python3
"""Cut generator inputs for the PROP hero objects out of their reference boards.

    tools/art_pipeline/crop_prop_views.py            # write every prop's crops
    tools/art_pipeline/crop_prop_views.py --check    # plus a contact sheet to judge
    tools/art_pipeline/crop_prop_views.py relay_apparatus

The sibling of `crop_views.py`, for the objects rather than the creatures.
Same job, same output contract — clean square views at one shared scale, in
`assets/creatures/tetherbound/<name>/reference/`, which is where `meshy.py`'s
`reference_views()` looks — but driven by explicit per-view boxes in
`prop_views.json` rather than by a band and four centres.

WHY A SECOND TOOL RATHER THAN A WIDER views.json

`crop_views.py` encodes the shape of a creature sheet: one horizontal
turnaround row, described as a band plus four x centres. That is a real
property of sheets 01-05 and its narrowness is a feature there. The prop
boards do not share it — board 14 keeps its TOP VIEW in a separate block below
the row, and board 15 arranges its views around a large beauty render rather
than in a row at all. Widening the creature model to cover both would make it
describe neither well.

WHAT IT PRESERVES

  Scale. Views are PADDED onto a common square, never rescaled individually.
  Multi-image-to-3D reconciles views by apparent size, and normalising each
  view to its own bounding box destroys exactly that signal. A view is only
  ever resized once, at the end, by the same factor as its siblings.

  Framing. Every emitted view is the same square with the object centred, so
  the generator sees a turntable rather than a collage.

  Colour. The pad is the board's own paper colour, sampled per board and
  recorded in `prop_views.json`. Nothing inside the box is touched.

The source boards are never modified.
"""

import argparse
import colorsys
import json
import pathlib
import sys

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
BOARDS = ROOT / "docs" / "art" / "reference"
OUT_ROOT = ROOT / "assets" / "creatures" / "tetherbound"
SPEC = pathlib.Path(__file__).resolve().parent / "prop_views.json"


def load() -> dict:
    return json.loads(SPEC.read_text())


## How far the morphological close reaches, and how much of a neighbourhood has
## to be occupant before a pixel joins it. Tuned on board 15: large enough to
## swallow the speckle left where the creature's darkest scales fall outside the
## hue window, small enough that the ring arms — whose neighbours are
## overwhelmingly unmasked structure — survive untouched.
CLOSE_RADIUS = 4
CLOSE_MAJORITY = 0.55


def lift_occupant(tile: Image.Image, cage: list[int], paper: tuple) -> int:
    """Erase the bound creature from inside the cage, leaving the cage.

    `D24` licenses board 15's MACHINE and not the legendary chained inside it,
    and `D23` section 20 forbids generating a creature mesh at any credit
    balance. A text negative is weak insurance for image-to-3D, which follows
    its pictures far more closely than its words — so the occupant comes out of
    the PICTURES.

    It comes out by colour, inside a box, because inside the cage the only
    bright saturated cyan in the drawing IS the creature: the machine's own
    runic glow is thin lines on dark stone and lives outside that box. Anything
    cruder — blanking the whole box — would take the containment rings and the
    clamp arms with it, and those are the object's signature.

    Returns the number of pixels lifted, so a caller can print it and a human
    can notice when a retuned board silently stops matching.
    """
    px = tile.load()
    x0, y0, x1, y1 = cage
    x1, y1 = min(x1, tile.width), min(y1, tile.height)

    def occupant(x: int, y: int) -> bool:
        r, g, b = px[x, y]
        h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
        glow = 0.34 <= h <= 0.60 and s >= 0.08 and v >= 0.40
        hottest = v >= 0.78 and s <= 0.25 and g >= r
        return glow or hottest

    mask = {(x, y) for y in range(y0, y1) for x in range(x0, x1) if occupant(x, y)}
    for _ in range(2):
        grown = set()
        for y in range(y0, y1):
            for x in range(x0, x1):
                if (x, y) in mask:
                    continue
                near = [(a, b)
                        for b in range(y - CLOSE_RADIUS, y + CLOSE_RADIUS + 1)
                        for a in range(x - CLOSE_RADIUS, x + CLOSE_RADIUS + 1)
                        if x0 <= a < x1 and y0 <= b < y1]
                if near and sum(p in mask for p in near) / len(near) >= CLOSE_MAJORITY:
                    grown.add((x, y))
        mask |= grown

    for x, y in mask:
        px[x, y] = paper
    return len(mask)


def crop_prop(name: str, spec: dict, size: int) -> list[tuple[str, Image.Image]]:
    board_path = BOARDS / spec["file"]
    if not board_path.exists():
        sys.exit(f"{name}: no board at {board_path}")
    board = Image.open(board_path).convert("RGB")
    pad = int(spec["pad"])
    background = tuple(spec["background"])

    cages = spec.get("lift_occupant", {})
    cut = []
    for view, box in spec["views"].items():
        tile = board.crop(tuple(box))
        if view in cages:
            lifted = lift_occupant(tile, cages[view], background)
            print(f"  {name}/{view}: lifted {lifted} occupant px "
                  f"(D24 — the board licenses the machine, not its prisoner)")
        if tile.width > pad or tile.height > pad:
            sys.exit(f"{name}/{view}: box is {tile.width}x{tile.height}, larger than "
                     f"pad {pad}. Raise `pad` rather than shrinking the box — the box "
                     f"is the art and the pad is only canvas.")
        # Pad, never rescale: this is the step that keeps the four views on one
        # scale, which is the whole reason multi-view reconstruction works.
        square = Image.new("RGB", (pad, pad), background)
        square.paste(tile, ((pad - tile.width) // 2, (pad - tile.height) // 2))
        cut.append((view, square.resize((size, size), Image.LANCZOS)))
    if len(cut) < 2:
        sys.exit(f"{name}: {len(cut)} view(s); meshy.py needs at least 2.")
    return cut


def contact_sheet(name: str, cut: list[tuple[str, Image.Image]]) -> pathlib.Path:
    thumbs = [(v, i.copy()) for v, i in cut]
    for _, t in thumbs:
        t.thumbnail((420, 420))
    width = sum(t.width for _, t in thumbs) + 20 * (len(thumbs) + 1)
    sheet = Image.new("RGB", (width, thumbs[0][1].height + 40), (250, 250, 250))
    x = 20
    for _, t in thumbs:
        sheet.paste(t, (x, 20))
        x += t.width + 20
    path = ROOT / "shots" / f"_prop_views_{name}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)
    return path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("prop", nargs="?", help="one prop, or all of them")
    parser.add_argument("--check", action="store_true",
                        help="also write a contact sheet of every crop")
    args = parser.parse_args()

    spec = load()
    size = int(spec.get("output_size", 1024))
    props = spec["props"]
    wanted = [args.prop] if args.prop else list(props)
    for name in wanted:
        if name not in props:
            sys.exit(f"no prop '{name}'. Known: {', '.join(props)}.")
        cut = crop_prop(name, props[name], size)
        out = OUT_ROOT / name / "reference"
        out.mkdir(parents=True, exist_ok=True)
        for view, image in cut:
            image.save(out / f"{view}.png")
        print(f"{name}: {len(cut)} view(s) -> {out.relative_to(ROOT)} "
              f"({', '.join(v for v, _ in cut)})")
        if args.check:
            print(f"  contact sheet: {contact_sheet(name, cut).relative_to(ROOT)}")


if __name__ == "__main__":
    main()
