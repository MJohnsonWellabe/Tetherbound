#!/usr/bin/env python3
"""Ad hoc luminance-ratio measurement for BACKLOG-B2-GRASS-SEPARATION.

Reimplements the method `ralph/reports/audit/B-2026-08-31.md`'s addendum used
(Rec. 709 luma, same weighting as `tools/frame_stats.py`, one creature-region
crop and one grass-region crop, ratio = creature_luma / grass_luma) against a
crop box given on the command line, since the original ad hoc script that
produced the 2026-08-28 figure was never committed.

    tools/_grass_separation_ratio.py FRAME.png CX0,CY0,CX1,CY1 GX0,GY0,GX1,GY1

Box coordinates are pixel (left, top, right, bottom), end-exclusive.
"""

import sys
import numpy as np
from PIL import Image

LUMA = np.array([0.2126, 0.7152, 0.0722])


def luma_of(img, box):
    x0, y0, x1, y1 = box
    crop = np.asarray(img.crop((x0, y0, x1, y1)).convert("RGB"), dtype=np.float32) / 255.0
    return float((crop @ LUMA).mean())


def parse_box(s):
    return tuple(int(v) for v in s.split(","))


def main():
    path, creature_box, grass_box = sys.argv[1], parse_box(sys.argv[2]), parse_box(sys.argv[3])
    img = Image.open(path)
    creature_luma = luma_of(img, creature_box)
    grass_luma = luma_of(img, grass_box)
    print("%-40s creature=%.4f grass=%.4f ratio=%.4f" % (
        path, creature_luma, grass_luma, creature_luma / grass_luma))


if __name__ == "__main__":
    main()
