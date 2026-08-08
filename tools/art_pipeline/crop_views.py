#!/usr/bin/env python3
"""Cut clean multi-view generator inputs out of the production reference sheets.

    tools/art_pipeline/crop_views.py            # write all four species' crops
    tools/art_pipeline/crop_views.py --check    # plus a contact sheet of every crop
    tools/art_pipeline/crop_views.py --grid     # coordinate overlays, for retuning views.json

Image-to-3D generators reconcile several pictures of one subject by assuming
the subject is the only thing in frame and does not change size between views.
A Tetherbound reference sheet violates both: it carries a head close-up, an
expression row, a swatch strip, detail panels, action poses, a silhouette row
and a scale chart alongside the turnaround the generator actually wants.
Feeding the whole sheet asks it to decide which of eleven pictures of a badger
is the badger.

So this cuts the four-view turnaround out and throws the rest away.

WHAT IT PRESERVES, AND WHY EACH MATTERS

  Scale. All four views of a species are cut at ONE square size and emitted at
  ONE resolution. They already share a scale on the sheet, and that is the
  signal multi-view reconstruction uses to know the front and the side are the
  same animal. Normalising each view to its own bounding box would destroy it.

  Framing. Every crop is the same square with the figure centred, so the
  generator sees a turntable rather than a collage.

  Colour. The background is flattened to one flat grey and NOTHING else is
  touched. That restraint is deliberate: Ripplet's fins are translucent and
  Galewisp is largely cream, and any background removal aggressive enough to
  matte those cleanly also eats the character. A flat neutral field is all a
  generator needs and it cannot cost us a feature.

The source sheets are never modified. Bands and centres live in views.json, so
a bad crop is a one-line fix and a rerun rather than an argument with this file.
"""

import argparse
import json
import pathlib
import sys

try:
    from PIL import Image, ImageDraw
    import numpy as np
except ImportError:
    sys.exit("needs Pillow and numpy:  pip install pillow numpy")

ROOT = pathlib.Path(__file__).resolve().parents[2]
SHEETS = ROOT / "docs" / "art" / "reference"
CONFIG = pathlib.Path(__file__).with_name("views.json")

## How far from the sampled background colour a pixel may be and still count as
## background. Low on purpose, and used for two different jobs at two different
## strengths — see SNAP_TOLERANCE.
##
## At 26 this flattens the panels' soft vignette and nothing else. At 60 it
## would start eating Galewisp's cream down, which sits about 54 away from the
## panel grey.
BACKGROUND_TOLERANCE = 26

## The strict threshold used to LOCATE a figure — its confidently opaque core.
## High, so soft shadow and antialiased fringe cannot drag the search onto a
## neighbour.
SNAP_TOLERANCE = 110

## The loose threshold used to EXTEND that core out to the figure's true edges,
## once the search window has already established which figure we are on.
##
## Two thresholds rather than one because Ripplet's tail fin and ear frills are
## translucent and Galewisp's down is nearly the panel's own grey. At 110 those
## are invisible and get cropped off — which would remove the single most
## distinctive feature of each creature from its own reference. At 40 they are
## kept, and the neighbour that 40 would otherwise reach is already excluded by
## the window.
EDGE_TOLERANCE = 40

## Columns and rows holding less than this fraction of ink are empty. Above
## zero because compression ringing leaves stray pixels in genuinely blank
## columns, and one stray pixel would weld a figure to its neighbour.
INK_THRESHOLD = 0.05

## Columns of smoothing applied to the density profile before looking for the
## divider between two figures. Wide enough that one noisy column cannot win the
## argmin, narrow enough not to blur a real trough away.
##
## The boundary between two touching figures is a NARROW notch — Ripplet's is
## about six columns wide — while the false trough inside a figure is broad. At
## 9 the smoothing filled the notch in and the broad waist won.
DIVIDER_SMOOTHING = 5

## Fraction of the span between two centres excluded from the divider search at
## each end. A hard guard against a divider landing on top of a figure's core.
DIVIDER_INSET = 0.15

## How strongly the divider search prefers the middle of the span over the
## emptiest column, as density units across the full span.
##
## Needed because depth alone is genuinely ambiguous on this art. Measured on
## Ripplet, between the side and back views: the real boundary at x=475 has
## column density 0.104, and the waist between the side view's own body and the
## base of its tail fin, at x=405, has 0.101. The wrong answer is DEEPER than
## the right one, by half a percent. No threshold separates those.
##
## What does separate them is that a boundary between two figures sits near the
## middle of the gap and a waist sits close to one of them. So pay for distance
## from the middle, and a trough that is genuinely much emptier still wins from
## further out.
##
## Swept against all four sheets with the expected boundaries written down
## first. With the bias, 52 of 75 combinations of smoothing, inset and bias put
## every divider in the right place; without it, three did. These values sit in
## the middle of that block rather than at its edge, which is the difference
## between a rule and a coincidence.
DIVIDER_CENTRE_BIAS = 0.15

## Fraction of the figure's larger dimension left as margin. Generators frame
## better with a little air; too much and the subject is small in its own image.
PADDING = 0.06

## Extra source pixels kept either side of a measured figure edge, so a soft
## outline or a whisker that fell just under EDGE_TOLERANCE is not sliced off.
MARGIN = 8


def load_config() -> dict:
    return json.loads(CONFIG.read_text())


def sheets(config: dict) -> dict:
    """The species entries, without the notes sitting beside them.

    views.json documents itself in `_comment` keys, and the wild roster's
    entries needed two of those INSIDE `sheets` — the layout is shared by
    thirteen species, so the explanation belongs with them and not in a
    preamble a hundred lines away. Anything underscore-prefixed is prose.
    """
    return {name: spec for name, spec in config["sheets"].items()
            if not name.startswith("_")}


## How many pixels either side of a mask rectangle are sampled to find the
## colour to fill it with. Wide enough to survive JPEG ringing around text,
## narrow enough not to reach the figure the mask sits next to.
MASK_RING = 5


def apply_masks(sheet: Image.Image, spec: dict) -> Image.Image:
    """Paint declared rectangles out in the local panel colour, before any cropping.

    The wild sheets put each species' NAME and role line inside the same panel
    as its hero illustration, close enough that no rectangle contains the
    figure and excludes the words. Grandpa is the precedent for what happens
    then: his crops each carried a sliver of a neighbouring figure and the
    blind critique traced a floating dagger in one candidate straight back to
    it. A generator models whatever is in frame, including letterforms.

    Filled with the colour sampled from a ring just OUTSIDE each rectangle
    rather than a constant, because the panels are not all the same grey and a
    hard-coded fill would show as a patch — which the generator would then
    model as a plate on the creature's flank.
    """
    rects = spec.get("mask")
    if not rects:
        return sheet
    sheet = sheet.copy()
    pixels = np.asarray(sheet)
    height, width = pixels.shape[:2]
    draw = ImageDraw.Draw(sheet)
    for x0, y0, x1, y1 in rects:
        ox0, oy0 = max(0, x0 - MASK_RING), max(0, y0 - MASK_RING)
        ox1, oy1 = min(width, x1 + MASK_RING), min(height, y1 + MASK_RING)
        ring = np.concatenate([
            pixels[oy0:y0, ox0:ox1].reshape(-1, 3),
            pixels[y1:oy1, ox0:ox1].reshape(-1, 3),
            pixels[oy0:oy1, ox0:x0].reshape(-1, 3),
            pixels[oy0:oy1, x1:ox1].reshape(-1, 3),
        ])
        if ring.size == 0:
            raise SystemExit(f"mask {[x0, y0, x1, y1]} has no surrounding pixels to sample")
        fill = tuple(int(c) for c in np.median(ring, axis=0))
        draw.rectangle([x0, y0, x1 - 1, y1 - 1], fill=fill)
    return sheet


def sample_background(pixels: np.ndarray) -> np.ndarray:
    """The panel colour, taken from the crop's own border.

    Sampled rather than assumed because the four sheets are not the same grey
    and a hard-coded value would silently stop matching if a sheet is redrawn.
    The border of a turnaround band is always panel; the figures are inset.
    """
    edges = np.concatenate([
        pixels[0, :].reshape(-1, 3), pixels[-1, :].reshape(-1, 3),
        pixels[:, 0].reshape(-1, 3), pixels[:, -1].reshape(-1, 3),
    ])
    return np.median(edges, axis=0)


def distance_from(pixels: np.ndarray, background: np.ndarray) -> np.ndarray:
    return np.abs(pixels.astype(int) - background).sum(axis=2)


def snap_to_content(distance: np.ndarray, centre: int, low: int, high: int
                    ) -> tuple[int, int]:
    """Tighten a divider-bounded region to the real extent of the figure inside it.

    Two passes. The first finds the figure's opaque core at SNAP_TOLERANCE,
    which proves a figure is there at all. The second re-measures at
    EDGE_TOLERANCE to pick up translucent fins and pale feathers.
    """
    window = distance[:, low:high]
    core = np.where((window > SNAP_TOLERANCE).mean(axis=0) > INK_THRESHOLD)[0]
    if core.size == 0:
        raise SystemExit(
            f"no figure found near x={centre} (searched {low}-{high} within the band).\n"
            f"Fix `centres` in views.json — run with --grid to read the right value off "
            f"an overlay."
        )
    edge = np.where((window > EDGE_TOLERANCE).mean(axis=0) > INK_THRESHOLD)[0]
    return low + int(min(core[0], edge[0])), low + int(max(core[-1], edge[-1]))


def divider(density: np.ndarray, left: int, right: int) -> int:
    """The column between two figures where the sheet is emptiest.

    Cutting at the sparsest column rather than at a fixed offset, because on
    these sheets adjacent figures do not reliably have a gap between them at
    all. Measured across Terrapup's side and back views, column ink density
    never once reaches zero: the side view's tail runs straight into the back
    view's tail with only a dip between them. Every fixed rule tried against
    that either clipped the side view's tail — a defining feature, the sheet
    gives it its own detail panel — or delivered a slice of it floating beside
    the back view.

    A trough is what actually separates two drawings that touch, so find the
    trough — the one nearest the middle, per DIVIDER_CENTRE_BIAS, because on
    this art the deepest trough is not reliably the right one.
    """
    inset = int((right - left) * DIVIDER_INSET)
    low, high = left + inset, right - inset
    span = density[low:high]
    if span.size == 0:
        return (left + right) // 2

    width = min(DIVIDER_SMOOTHING, span.size)
    smoothed = np.convolve(span, np.ones(width) / width, mode="same")

    middle = (span.size - 1) / 2.0
    offset = np.abs(np.arange(span.size) - middle) / max(span.size, 1)
    return low + int(np.argmin(smoothed + offset * DIVIDER_CENTRE_BIAS))


def content_rows(distance: np.ndarray) -> tuple[int, int]:
    """Top and bottom of all content in the band, so crops waste no height."""
    rows = np.where((distance > SNAP_TOLERANCE).mean(axis=1) > INK_THRESHOLD)[0]
    if rows.size == 0:
        raise SystemExit("the band contains no content at all; check views.json")
    return int(rows[0]), int(rows[-1])


def figure_bounds(distance: np.ndarray, centres: list[int]) -> list[tuple[int, int]]:
    """Snapped left/right edges for every declared centre, left to right.

    Each figure owns the region between the troughs on either side of it, and is
    then tightened to the content actually in that region.
    """
    width = distance.shape[1]
    density = (distance > EDGE_TOLERANCE).mean(axis=0)

    edges = [0]
    for left, right in zip(centres, centres[1:]):
        edges.append(divider(density, left, right))
    edges.append(width)

    return [snap_to_content(distance, centre, low, high)
            for centre, low, high in zip(centres, edges, edges[1:])]


def trim(figure: Image.Image, background: np.ndarray) -> Image.Image:
    """Crop a view down to its own content. Only used with per_view_scale."""
    distance = distance_from(np.asarray(figure), background)
    ink = distance > EDGE_TOLERANCE
    rows = np.where(ink.mean(axis=1) > INK_THRESHOLD)[0]
    cols = np.where(ink.mean(axis=0) > INK_THRESHOLD)[0]
    if rows.size == 0 or cols.size == 0:
        return figure
    return figure.crop((int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1))


def flatten_background(crop: Image.Image, background: np.ndarray,
                       target: tuple[int, int, int]) -> Image.Image:
    """Replace near-background pixels with one flat colour, touching nothing else."""
    pixels = np.asarray(crop).astype(int)
    is_background = distance_from(pixels, background) <= BACKGROUND_TOLERANCE
    pixels[is_background] = target
    return Image.fromarray(pixels.astype(np.uint8))


## A divider column is faint but present: further from the panel than the
## panel's own noise, far nearer than any drawn line on a creature.
DIVIDER_MIN_DISTANCE = 15
DIVIDER_MAX_DISTANCE = 105
## Fraction of the band's height a column must hold at that faintness to be a
## divider. A creature makes no column that is uniformly faint top to bottom.
DIVIDER_COVERAGE = 0.42
## Widest run of such columns that is still a divider and not a drawn edge.
DIVIDER_MAX_WIDTH = 5


def erase_dividers(sheet: Image.Image, band: tuple[int, int, int, int]) -> Image.Image:
    """Paint out the thin grey rules the sheets draw between turnaround views.

    Found the expensive way. Mudsnout's crops each carried the panel divider at
    their left edge — one or two pixels of pale grey, easy to dismiss on a
    contact sheet — and one of the three candidates generated from them came
    back with a flat vertical PLANK standing behind the pig in all four views.
    The generator modelled the line, exactly as Grandpa's modelled a sliver of
    his neighbour.

    Detected rather than declared, because the rules do not sit at the same x
    on all four sheets and there are thirty-eight views. The signature is
    unmistakable and nothing a creature can produce: a run of at most a few
    columns that is faintly-but-consistently off-background down the WHOLE
    height of the band. A drawn feature that tall is not that faint, and a
    feature that faint is not that tall.
    """
    x0, y0, x1, y1 = band
    pixels = np.asarray(sheet.crop((x0, y0, x1, y1)))
    background = sample_background(pixels)
    distance = distance_from(pixels, background)
    faint = ((distance > DIVIDER_MIN_DISTANCE) & (distance < DIVIDER_MAX_DISTANCE))
    columns = [i for i, share in enumerate(faint.mean(axis=0)) if share > DIVIDER_COVERAGE]

    runs, run = [], []
    for column in columns:
        if run and column == run[-1] + 1:
            run.append(column)
        else:
            if run:
                runs.append(run)
            run = [column]
    if run:
        runs.append(run)

    sheet = sheet.copy()
    draw = ImageDraw.Draw(sheet)
    fill = tuple(int(c) for c in background)
    for run in runs:
        if len(run) > DIVIDER_MAX_WIDTH:
            continue
        draw.rectangle([x0 + run[0], y0, x0 + run[-1], y1 - 1], fill=fill)
    return sheet


def crop_boxes(name: str, spec: dict, config: dict,
               out_root: pathlib.Path) -> list[pathlib.Path]:
    """Cut explicitly-named boxes, bypassing band/centre/divider entirely.

    The escape hatch for a panel the automatic split cannot read — see the
    `veridian` entry in views.json for the case that earned it.
    """
    sheet = apply_masks(Image.open(SHEETS / spec["file"]).convert("RGB"), spec)
    out_dir = out_root / name / "reference"
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / ".gdignore").touch()

    written = []
    for view, box in spec["boxes"].items():
        figure = sheet.crop(tuple(box))
        background = sample_background(np.asarray(figure))
        figure = trim(figure, background)
        square = int(max(figure.size) * (1.0 + PADDING * 2))
        canvas = Image.new("RGB", (square, square), tuple(int(c) for c in background))
        canvas.paste(figure, ((square - figure.width) // 2, (square - figure.height) // 2))
        canvas = flatten_background(canvas, background, tuple(config["background"]))
        size = config["output_size"]
        path = out_dir / f"{view}.png"
        canvas.resize((size, size), Image.LANCZOS).save(path)
        written.append(path)
    return written


def crop_sheet(name: str, spec: dict, config: dict,
               out_root: pathlib.Path) -> list[pathlib.Path]:
    if "boxes" in spec:
        return crop_boxes(name, spec, config, out_root)

    source = SHEETS / spec["file"]
    if not source.exists():
        raise SystemExit(f"missing reference sheet: {source}")

    sheet = apply_masks(Image.open(source).convert("RGB"), spec)
    sheet = erase_dividers(sheet, tuple(spec["band"]))
    x0, y0, x1, y1 = spec["band"]
    band = np.asarray(sheet.crop((x0, y0, x1, y1)))

    background = sample_background(band)
    distance = distance_from(band, background)

    # A sheet may declare its own view list. Board 06's Warden has three
    # turnaround views and a bust; calling the bust "three_quarter" would feed
    # the generator a head at a different scale and call it a body.
    views = spec.get("views", config["views"])
    centres = [c - x0 for c in spec["centres"]]
    if len(centres) != len(views):
        raise SystemExit(f"{name}: {len(centres)} centres for {len(views)} views")

    bounds = figure_bounds(distance, centres)
    top, bottom = content_rows(distance)

    # ONE square side for all views, from the tallest and the widest, so the
    # set stays a turntable. See the module docstring.
    #
    # UNLESS the sheet says its views are drawn at different sizes. Then each
    # view gets its own square, because the shared-scale rule assumes a shared
    # scale exists — and letterboxing a thumbnail into a square sized for a
    # hero view tells the generator the creature shrinks when it turns.
    per_view = bool(spec.get("per_view_scale", False))
    side = int(max(bottom - top, max(b - a for a, b in bounds) + MARGIN * 2)
               * (1.0 + PADDING * 2))

    out_dir = out_root / name / "reference"
    out_dir.mkdir(parents=True, exist_ok=True)

    # These are generator inputs, not game content, and they live under assets/
    # only because the pipeline wants a creature's reference beside its model.
    # Without this marker Godot imports all sixteen as textures and the Windows
    # export packs about 16 MB of concept art into the .exe — the same mistake
    # the sheets themselves were just moved out of the root to fix.
    (out_dir / ".gdignore").touch()

    written = []
    for view, (a, b) in zip(views, bounds):
        # Take ONLY this figure's own slice of the sheet, never a square window
        # around it.
        #
        # A square tall enough to hold a standing figure is wider than the sheet
        # spaces its figures, so a naive square crop centred on the side view
        # arrives with the front and back views in frame beside it. That is
        # precisely the collage this script exists to prevent, and the first
        # version of it shipped exactly that. Cutting the figure's own column
        # range and centring it on a background square keeps the square framing
        # and the shared scale while guaranteeing one creature per image.
        slice_left = x0 + a - MARGIN
        slice_right = x0 + b + MARGIN
        figure = sheet.crop((slice_left, y0 + top, slice_right, y0 + bottom))
        if per_view:
            figure = trim(figure, background)

        square = side if not per_view else int(max(figure.size) * (1.0 + PADDING * 2))
        canvas = Image.new("RGB", (square, square), tuple(int(c) for c in background))
        canvas.paste(figure, ((square - figure.width) // 2, (square - figure.height) // 2))
        canvas = flatten_background(canvas, background, tuple(config["background"]))

        size = config["output_size"]
        path = out_dir / f"{view}.png"
        canvas.resize((size, size), Image.LANCZOS).save(path)
        written.append(path)

    for view, box in spec.get("extra_boxes", {}).items():
        figure = sheet.crop(tuple(box))
        local_bg = sample_background(np.asarray(figure))
        figure = trim(figure, local_bg)
        square = int(max(figure.size) * (1.0 + PADDING * 2))
        canvas = Image.new("RGB", (square, square), tuple(int(c) for c in local_bg))
        canvas.paste(figure, ((square - figure.width) // 2, (square - figure.height) // 2))
        canvas = flatten_background(canvas, local_bg, tuple(config["background"]))
        path = out_dir / f"{view}.png"
        canvas.resize((config["output_size"],) * 2, Image.LANCZOS).save(path)
        written.append(path)

    return written


def write_grid(spec: dict, out_dir: pathlib.Path) -> pathlib.Path:
    """A coordinate overlay of a whole sheet, for reading a band or centre by eye."""
    sheet = Image.open(SHEETS / spec["file"]).convert("RGB")
    draw = ImageDraw.Draw(sheet)
    w, h = sheet.size
    for x in range(0, w, 100):
        draw.line([(x, 0), (x, h)], fill=(255, 0, 0), width=2)
        draw.text((x + 3, 3), str(x), fill=(255, 0, 0))
    for y in range(0, h, 100):
        draw.line([(0, y), (w, y)], fill=(0, 90, 255), width=2)
        draw.text((3, y + 3), str(y), fill=(0, 90, 255))
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / f"grid_{spec['file']}"
    sheet.save(path)
    return path


def write_check_sheet(config: dict, out_root: pathlib.Path) -> pathlib.Path:
    """Every crop in one image, so a bad band or centre is visible at a glance."""
    names = list(sheets(config))
    views = config["views"]
    cell, label = 320, 26
    sheet = Image.new("RGB", (cell * len(views), (cell + label) * len(names)), (24, 24, 26))
    draw = ImageDraw.Draw(sheet)
    for row, name in enumerate(names):
        y = row * (cell + label)
        draw.text((6, y + 8), name, fill=(235, 235, 235))
        for col, view in enumerate(views):
            path = out_root / name / "reference" / f"{view}.png"
            if not path.exists():
                continue
            sheet.paste(Image.open(path).resize((cell, cell), Image.LANCZOS),
                        (col * cell, y + label))
            draw.text((col * cell + 6, y + label + 4), view, fill=(255, 220, 120))
    # Written under docs/, not beside the crops, for the same reason they carry
    # a .gdignore: docs/ is already excluded from the export, and a verification
    # artefact has no business in the shipped game.
    out = ROOT / "docs" / "art" / "reference_views.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    return out


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--grid", action="store_true",
                        help="write coordinate overlays instead of crops")
    parser.add_argument("--check", action="store_true",
                        help="also write a contact sheet of every crop")
    parser.add_argument("--out", default="assets/pals/tetherbound",
                        help="output root (default: assets/pals/tetherbound)")
    args = parser.parse_args()

    config = load_config()
    out_root = ROOT / args.out

    if args.grid:
        target = ROOT / "shots" / "reference_grids"
        for spec in sheets(config).values():
            print(write_grid(spec, target).relative_to(ROOT))
        return

    total = 0
    for name, spec in sheets(config).items():
        written = crop_sheet(name, spec, config, out_root)
        total += len(written)
        print(f"{name:10s} {len(written)} views -> {written[0].parent.relative_to(ROOT)}")

    print(f"\n{total} views written")
    if args.check:
        print(f"contact sheet: {write_check_sheet(config, out_root).relative_to(ROOT)}")


if __name__ == "__main__":
    main()
