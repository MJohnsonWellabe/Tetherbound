#!/usr/bin/env python3
"""N06-MAP-UI — assemble one contact sheet from this lane's stands.

    python3 tools/_sheet_map_ui_0905.py <out.png> <frame.png> [<frame.png> ...]

COMMON.md allows one contact sheet per judging round, named `_sheet*.png`, and
no per-frame PNGs. Seeing every stand at once is the point: whether the fog
reads the same way at 0.4% and at 1.4% surveyed, and whether the full map and
the HUD minimap agree about it, are questions a single frame cannot answer.

Every tile is scaled to one common height and laid out in a single row, so a
240px widget render and a 1280x800 screen sit side by side at comparable
visual weight. Padding each to the widest tile instead — the obvious layout —
spends most of the sheet on empty ground when the stands differ in aspect by
4x, which is exactly the case here.
"""

import sys

from PIL import Image

TILE_HEIGHT = 400
GAP = 12
GROUND = (10, 12, 14)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    out_path, paths = sys.argv[1], sys.argv[2:]

    tiles = []
    for path in paths:
        image = Image.open(path).convert("RGB")
        scale = TILE_HEIGHT / image.height
        tiles.append(image.resize(
            (max(1, round(image.width * scale)), TILE_HEIGHT), Image.LANCZOS))

    width = sum(t.width for t in tiles) + GAP * (len(tiles) + 1)
    sheet = Image.new("RGB", (width, TILE_HEIGHT + GAP * 2), GROUND)
    x = GAP
    for tile in tiles:
        sheet.paste(tile, (x, GAP))
        x += tile.width + GAP
    sheet.save(out_path)
    print("wrote %s at %dx%d from %d frame(s)" % (out_path, sheet.width, sheet.height, len(tiles)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
