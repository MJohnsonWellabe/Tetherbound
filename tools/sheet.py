#!/usr/bin/env python3
"""Composite an arbitrary set of frames into one labelled contact sheet.

    python3 tools/sheet.py --out shots/_sheet_buildings.png shots/buildings/*.png
    python3 tools/sheet.py --cols 2 --out shots/_sheet_world.png shots/0*.png

WHY THIS EXISTS ALONGSIDE tools/contact_sheet.gd. That script reads
`shots/*.png` and nothing else, three columns, no labels — `Image` has no font
rendering in Godot, so it draws a green rule under each tile and prints the
reading order to stdout instead. That works for the five-frame survey it was
built for. It does not work when a pass has thirty frames across four
directories and a critic has to be told which frame is which: the R0.8.5 full
review hit exactly this and wrote a throwaway compositor in its own scratch
space, which then did not exist for the next pass. This is that compositor,
committed.

The labels are the point. A blind critic's findings are only actionable if it
can say "in 04-barn-cluster" rather than "in the third one on the second row",
and every rubric in `.claude/skills/visual-judge` asks it to name the frame.

Nothing here judges anything. It resizes, tiles and writes text.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

# Tile width in the sheet. 620 matches contact_sheet.gd so sheets from the two
# tools sit at the same scale when a review shows both.
TILE_W = 620
LABEL_H = 26
PAD = 8
BG = (24, 24, 26)
FG = (232, 232, 228)
RULE = (86, 132, 74)


def _font() -> ImageFont.ImageFont:
    """A real TrueType face if the box has one, else Pillow's bitmap default.

    The default is small but legible; a sheet with unreadable labels is worse
    than a sheet with ugly ones, so this never fails over to no label at all.
    """
    for candidate in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    ):
        if Path(candidate).exists():
            try:
                return ImageFont.truetype(candidate, 16)
            except OSError:
                pass
    return ImageFont.load_default()


def build(paths: list[Path], out: Path, cols: int) -> None:
    if not paths:
        raise SystemExit("sheet.py: no input frames")

    tiles = []
    for p in paths:
        img = Image.open(p).convert("RGB")
        h = max(1, round(img.height * TILE_W / img.width))
        tiles.append((p.name, img.resize((TILE_W, h), Image.LANCZOS)))

    # Rows are sized by their own tallest tile rather than one global height,
    # so mixing 16:9 survey frames with square turntables does not letterbox
    # the whole sheet down to the shortest thing in it.
    rows = [tiles[i : i + cols] for i in range(0, len(tiles), cols)]
    row_h = [max(t[1].height for t in row) + LABEL_H + PAD for row in rows]

    width = cols * TILE_W + (cols + 1) * PAD
    height = sum(row_h) + PAD
    sheet = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(sheet)
    font = _font()

    y = PAD
    for row, rh in zip(rows, row_h):
        x = PAD
        for name, img in row:
            sheet.paste(img, (x, y))
            draw.line(
                [(x, y + img.height + 1), (x + TILE_W, y + img.height + 1)],
                fill=RULE,
                width=2,
            )
            draw.text((x + 2, y + img.height + 6), name, fill=FG, font=font)
            x += TILE_W + PAD
        y += rh

    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(f"{len(tiles)} frames, {cols} cols -> {out} ({width}x{height})")
    for i, (name, _) in enumerate(tiles, 1):
        print(f"  {i:2d}. {name}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("frames", nargs="+", type=Path)
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--cols", type=int, default=3)
    args = ap.parse_args()

    # Sort by name so the sheet's reading order is stable between runs, which
    # is what makes two sheets comparable after a fix.
    build(sorted(set(args.frames)), args.out, max(1, args.cols))
    return 0


if __name__ == "__main__":
    sys.exit(main())
