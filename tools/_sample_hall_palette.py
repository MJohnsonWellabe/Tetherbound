#!/usr/bin/env python3
"""T1-HALL-BUILD (2026-08-30). Pixel-sample the judge's own C-0x/S-ext-0x
frames for the HALL_DESIGN_2026-08-30.md §5 kill criteria: lit-flank patch
mean in [150,185], north/shaded-face patch mean in [95,130], patch std-dev
>= 35. Reports mean RGB and std-dev of a named box in a named frame -- coords
picked by eye against the actual PNG, not guessed from the render script.

Usage: python3 tools/_sample_hall_palette.py <shots_dir>
"""
import sys
import statistics
from pathlib import Path
from PIL import Image

# name -> (file, (x0,y0,x1,y1)) -- a ~64px box, picked from the rendered frame.
PATCHES = {
    "C-03-corner-close_lit-wall": ("C-03-corner-close.png", (560, 260, 624, 324)),
    "C-04-wall-close-ground_lit-wall": ("C-04-wall-close-ground.png", (560, 300, 624, 364)),
    "C-01-approach-gate-FIXED_lit-wall": ("C-01-approach-gate-FIXED.png", (300, 260, 364, 324)),
    "S-ext-02-flank-wide_wall": ("S-ext-02-flank-wide.png", (560, 300, 624, 364)),
    "S-ext-01-approach-ramp-foot_wall": ("S-ext-01-approach-ramp-foot.png", (500, 260, 564, 324)),
}


def sample(img: Image.Image, box):
    crop = img.convert("RGB").crop(box)
    pixels = list(crop.getdata())
    n = len(pixels)
    mean_r = sum(p[0] for p in pixels) / n
    mean_g = sum(p[1] for p in pixels) / n
    mean_b = sum(p[2] for p in pixels) / n
    lumas = [0.2126 * p[0] + 0.7152 * p[1] + 0.0722 * p[2] for p in pixels]
    mean_luma = sum(lumas) / n
    stdev_luma = statistics.pstdev(lumas)
    return mean_r, mean_g, mean_b, mean_luma, stdev_luma


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    shots_dir = Path(sys.argv[1])
    print(f"{'patch':<38} {'file':<28} {'mean RGB':<18} {'mean luma':<10} {'std-dev':<8}")
    for name, (fname, box) in PATCHES.items():
        path = shots_dir / fname
        if not path.exists():
            print(f"{name:<38} MISSING: {path}")
            continue
        img = Image.open(path)
        w, h = img.size
        x0, y0, x1, y1 = box
        if x1 > w or y1 > h:
            print(f"{name:<38} box {box} out of bounds for {w}x{h} image {fname}")
            continue
        r, g, b, luma, sd = sample(img, box)
        print(f"{name:<38} {fname:<28} ({r:5.1f},{g:5.1f},{b:5.1f})  {luma:7.1f}   {sd:6.1f}")


if __name__ == "__main__":
    main()
