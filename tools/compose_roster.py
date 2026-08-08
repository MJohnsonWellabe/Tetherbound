#!/usr/bin/env python3
"""Composite the per-creature tiles from tools/preview_roster.gd into one sheet.

    python3 tools/compose_roster.py

Godot renders one tile per candidate, each framed on the same 2.2m-tall window
with a 1.80m trainer bar in it. This lays them out in a labelled grid so the
roster can actually be LOOKED AT — which `tools/preview_creatures.gd` has never
managed (`docs/reviews/MA-04`: "_creatures.png contains no creatures").

Labels carry the measured posed height, so the sheet is evidence and not just a
picture.
"""

import os
import sys

from PIL import Image, ImageDraw, ImageFont

TILES = "shots/_roster_tiles"
OUT = "shots/_roster_sheet.png"
COLS = 5
LABEL_H = 34

# name -> (measured metres, role note). Heights come from the Godot run; they
# are printed there and copied here so the sheet is self-describing.
ORDER = [
    ("knight", 1.80, "TRAINER — the ruler"),
    ("mage", 1.96, "Warden candidate"),
    ("dwarf", 1.53, "Warden alt"),
    ("Rat", 0.45, "small ground / tutorial?"),
    ("Frog", 0.55, "WATER common"),
    ("Fox", 0.79, "badger-role stand-in"),
    ("Wolf", 0.80, "EVOLVED form"),
    ("ShibaInu", 0.94, "young canine"),
    ("Husky", 0.96, "young canine alt"),
    ("Donkey", 1.15, "rideable"),
    ("Stag", 1.18, "rideable / legendary?"),
    ("Deer", 1.27, "rideable"),
    ("Bull", 1.27, "bulky aggressive / boar role"),
    ("Cow", 1.27, "bulky peaceful"),
    ("Horse", 1.45, "rideable"),
    ("Horse_White", 1.45, "rideable / legendary?"),
    ("Alpaca", 1.62, "rideable, tallest"),
]


def font(size):
    for path in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def main():
    tiles = []
    for name, height, role in ORDER:
        path = os.path.join(TILES, name + ".png")
        if not os.path.exists(path):
            print("missing tile: %s" % path, file=sys.stderr)
            continue
        tiles.append((Image.open(path).convert("RGB"), name, height, role))
    if not tiles:
        print("no tiles; run tools/preview_roster.gd first", file=sys.stderr)
        return 1

    tw, th = tiles[0][0].size
    rows = (len(tiles) + COLS - 1) // COLS
    sheet = Image.new("RGB", (COLS * tw, rows * (th + LABEL_H)), (20, 22, 24))
    draw = ImageDraw.Draw(sheet)
    big, small = font(19), font(15)

    for i, (img, name, height, role) in enumerate(tiles):
        x = (i % COLS) * tw
        y = (i // COLS) * (th + LABEL_H)
        sheet.paste(img, (x, y))
        draw.rectangle([x, y + th, x + tw - 1, y + th + LABEL_H - 1], fill=(20, 22, 24))
        draw.text((x + 8, y + th + 3), "%s  %.2fm" % (name, height), font=big,
                  fill=(240, 238, 232))
        draw.text((x + 8, y + th + 20), role, font=small, fill=(150, 158, 150))
        draw.rectangle([x, y, x + tw - 1, y + th + LABEL_H - 1], outline=(52, 56, 58))

    sheet.save(OUT)
    print("wrote %s  (%dx%d, %d tiles)" % (OUT, sheet.width, sheet.height, len(tiles)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
