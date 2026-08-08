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


def flatten_background(crop: Image.Image, background: np.ndarray,
                       target: tuple[int, int, int]) -> Image.Image:
    """Replace near-background pixels with one flat colour, touching nothing else."""
    pixels = np.asarray(crop).astype(int)
    is_background = distance_from(pixels, background) <= BACKGROUND_TOLERANCE
    pixels[is_background] = target
    return Image.fromarray(pixels.astype(np.uint8))


def crop_sheet(name: str, spec: dict, config: dict,
               out_root: pathlib.Path) -> list[pathlib.Path]:
    source = SHEETS / spec["file"]
    if not source.exists():
        raise SystemExit(f"missing reference sheet: {source}")

    sheet = Image.open(source).convert("RGB")
    x0, y0, x1, y1 = spec["band"]
    band = np.asarray(sheet.crop((x0, y0, x1, y1)))

    background = sample_background(band)
    distance = distance_from(band, background)

    centres = [c - x0 for c in spec["centres"]]
    if len(centres) != len(config["views"]):
        raise SystemExit(f"{name}: {len(centres)} centres for {len(config['views'])} views")

    bounds = figure_bounds(distance, centres)
    top, bottom = content_rows(distance)

    # ONE square side for all four views, from the tallest and the widest, so
    # the set stays a turntable. See the module docstring.
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
    for view, (a, b) in zip(config["views"], bounds):
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

        canvas = Image.new("RGB", (side, side), tuple(int(c) for c in background))
        canvas.paste(figure, ((side - figure.width) // 2, (side - figure.height) // 2))
        canvas = flatten_background(canvas, background, tuple(config["background"]))

        size = config["output_size"]
        path = out_dir / f"{view}.png"
        canvas.resize((size, size), Image.LANCZOS).save(path)
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
    names = list(config["sheets"])
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
        for spec in config["sheets"].values():
            print(write_grid(spec, target).relative_to(ROOT))
        return

    total = 0
    for name, spec in config["sheets"].items():
        written = crop_sheet(name, spec, config, out_root)
        total += len(written)
        print(f"{name:10s} {len(written)} views -> {written[0].parent.relative_to(ROOT)}")

    print(f"\n{total} views written")
    if args.check:
        print(f"contact sheet: {write_check_sheet(config, out_root).relative_to(ROOT)}")


if __name__ == "__main__":
    main()
