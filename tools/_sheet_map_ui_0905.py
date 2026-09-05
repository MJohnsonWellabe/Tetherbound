#!/usr/bin/env python3
"""N06-MAP-UI — assemble one contact sheet from this lane's stands.

    python3 tools/_sheet_map_ui_0905.py <out.png> <frame.png> [<frame.png> ...]

COMMON.md allows one contact sheet per judging round, named `_sheet*.png`, and
no per-frame PNGs. Seeing every stand at once is the point: whether the fog
reads the same way at 0.4% and at 1.4% surveyed, and whether the full map and
the HUD minimap agree about it, are questions a single frame cannot answer.

Tiles are laid out three to a row at half scale, each padded to the widest and
tallest tile so a 240px widget render and a 1280x800 screen sit on one sheet
without either being stretched.
"""

import sys

from PIL import Image

COLUMNS = 3
SCALE = 0.5
GROUND = (10, 12, 14)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    out_path, paths = sys.argv[1], sys.argv[2:]

    tiles = []
    for path in paths:
        image = Image.open(path).convert("RGB")
        tiles.append(image.resize(
            (max(1, int(image.width * SCALE)), max(1, int(image.height * SCALE))),
            Image.LANCZOS))

    tile_w = max(t.width for t in tiles)
    tile_h = max(t.height for t in tiles)
    rows = (len(tiles) + COLUMNS - 1) // COLUMNS
    sheet = Image.new("RGB", (tile_w * COLUMNS, tile_h * rows), GROUND)
    for index, tile in enumerate(tiles):
        x = (index % COLUMNS) * tile_w + (tile_w - tile.width) // 2
        y = (index // COLUMNS) * tile_h + (tile_h - tile.height) // 2
        sheet.paste(tile, (x, y))
    sheet.save(out_path)
    print("wrote %s at %dx%d from %d frame(s)" % (out_path, sheet.width, sheet.height, len(tiles)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
