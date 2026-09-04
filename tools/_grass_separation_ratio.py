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

import colorsys
import sys
import numpy as np
from PIL import Image

LUMA = np.array([0.2126, 0.7152, 0.0722])


def luma_of(img, box):
    x0, y0, x1, y1 = box
    crop = np.asarray(img.crop((x0, y0, x1, y1)).convert("RGB"), dtype=np.float32) / 255.0
    return float((crop @ LUMA).mean())


def hsv_of(img, box):
    """Mean RGB and the hue/saturation of that mean colour, Rec.709 luma.

    G3-CREATURE-COLOUR-0904: the ratio this script was written for answers
    "is it bright enough", not "does it read pink" -- the GATE2-EVIDENCE-0903
    judge's "candy pink" complaint is a HUE/saturation finding a luminance
    ratio alone cannot see (a magenta-shifted creature and its hue-neutral
    original can share the same luma). Reported alongside the ratio so a
    tuning pass can check both bars from one measurement instead of eyeballing
    a screenshot for pinkness.
    """
    x0, y0, x1, y1 = box
    crop = np.asarray(img.crop((x0, y0, x1, y1)).convert("RGB"), dtype=np.float32) / 255.0
    mean_rgb = crop.reshape(-1, 3).mean(axis=0)
    h, s, v = colorsys.rgb_to_hsv(*mean_rgb)
    return {"rgb": mean_rgb, "hue_deg": h * 360.0, "saturation": s, "value": v}


def parse_box(s):
    return tuple(int(v) for v in s.split(","))


def main():
    path, creature_box, grass_box = sys.argv[1], parse_box(sys.argv[2]), parse_box(sys.argv[3])
    img = Image.open(path)
    creature_luma = luma_of(img, creature_box)
    grass_luma = luma_of(img, grass_box)
    print("%-40s creature=%.4f grass=%.4f ratio=%.4f" % (
        path, creature_luma, grass_luma, creature_luma / grass_luma))
    hsv = hsv_of(img, creature_box)
    r, g, b = hsv["rgb"] * 255.0
    print("%-40s creature mean RGB=(%.1f,%.1f,%.1f) hue=%.1fdeg sat=%.3f val=%.3f" % (
        path, r, g, b, hsv["hue_deg"], hsv["saturation"], hsv["value"]))


if __name__ == "__main__":
    main()
