#!/usr/bin/env python3
"""N06-MAP-UI — assemble one contact sheet from this lane's four map stands.

    python3 tools/_sheet_map_ui_0905.py <in_dir> <out.png>

COMMON.md allows one contact sheet per judging round, named `_sheet*.png`, and
no per-frame PNGs. Seeing the four stands at once is the point: whether the fog
reads the same way at 0.4% and at 1.4% surveyed, and whether the full map and
the HUD minimap agree about it, are questions a single frame cannot answer.
"""

import sys

from PIL import Image

STANDS = [
    ("map_fresh", "full map - fresh save, 0.42% surveyed"),
    ("map_day1", "full map - day-1 footprint, 0.42% surveyed"),
    ("map_surveyed", "full map - 1.42% surveyed"),
    ("hud_minimap", "in-world HUD, minimap top right"),
]
COLUMNS = 2
SCALE = 0.5


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 1
    in_dir, out_path = sys.argv[1], sys.argv[2]

    tiles = []
    for name, _caption in STANDS:
        image = Image.open("%s/%s.png" % (in_dir, name)).convert("RGB")
        tiles.append(image.resize(
            (int(image.width * SCALE), int(image.height * SCALE)), Image.LANCZOS))

    tile_w = max(t.width for t in tiles)
    tile_h = max(t.height for t in tiles)
    rows = (len(tiles) + COLUMNS - 1) // COLUMNS
    sheet = Image.new("RGB", (tile_w * COLUMNS, tile_h * rows), (10, 12, 14))
    for index, tile in enumerate(tiles):
        sheet.paste(tile, ((index % COLUMNS) * tile_w, (index // COLUMNS) * tile_h))
    sheet.save(out_path)
    print("wrote %s at %dx%d" % (out_path, sheet.width, sheet.height))
    return 0


if __name__ == "__main__":
    sys.exit(main())
