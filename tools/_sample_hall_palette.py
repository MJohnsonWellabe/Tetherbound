#!/usr/bin/env python3
"""T1-HALL-BUILD (2026-08-30). Pixel-sample the judge's own C-0x/S-ext-0x
frames for the HALL_DESIGN_2026-08-30.md §5 kill criteria: lit-flank patch
mean in [150,185], north/shaded-face patch mean in [95,130], patch std-dev
>= 35 (luma). Rather than one hand-picked 64px box (which a single flat
stone face or a single highlight can make look better or worse than the
wall really is), each named WALL_REGION is a larger clean-stone bounding
box (no banners/merlons/openings/sky/grass), picked by eye off the actual
rendered frame, tiled into non-overlapping 64x64 cells, and every cell is
reported plus the aggregate -- so the number is the wall's real
distribution, not one lucky or unlucky sample.

Usage: python3 tools/_sample_hall_palette.py <shots_dir>
"""
import sys
import statistics
from pathlib import Path
from PIL import Image

CELL = 64

# name -> (file, (x0,y0,x1,y1)) -- a clean-stone bounding region, tiled into
# CELL x CELL cells. Region edges picked by eye from the rendered PNG.
WALL_REGIONS = {
    "C-03-corner-close_lit-wall":      ("C-03-corner-close.png", (545, 345, 760, 445)),
    "C-04-wall-close-ground_wall":     ("C-04-wall-close-ground.png", (705, 195, 900, 350)),
    "C-01-approach-gate-FIXED_wall-L": ("C-01-approach-gate-FIXED.png", (350, 330, 470, 395)),
    "C-01-approach-gate-FIXED_wall-R": ("C-01-approach-gate-FIXED.png", (760, 330, 880, 395)),
    "S-ext-02-flank-wide_wall":        ("S-ext-02-flank-wide.png", (540, 140, 660, 260)),
    "S-ext-01-approach-ramp-foot_gate-face": ("S-ext-01-approach-ramp-foot.png", (340, 20, 500, 180)),
}


def cell_stats(img, box):
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
    for name, (fname, region) in WALL_REGIONS.items():
        path = shots_dir / fname
        print(f"\n=== {name}  ({fname}, region {region}) ===")
        if not path.exists():
            print(f"  MISSING: {path}")
            continue
        img = Image.open(path)
        w, h = img.size
        x0, y0, x1, y1 = region
        if x1 > w or y1 > h:
            print(f"  region {region} out of bounds for {w}x{h} image")
            continue
        cell_means = []
        cell_sds = []
        cell_rgbs = []
        for cy in range(y0, y1 - CELL + 1, CELL):
            for cx in range(x0, x1 - CELL + 1, CELL):
                box = (cx, cy, cx + CELL, cy + CELL)
                r, g, b, luma, sd = cell_stats(img, box)
                cell_means.append(luma)
                cell_sds.append(sd)
                cell_rgbs.append((r, g, b))
                print(f"  cell {box}: RGB=({r:6.1f},{g:6.1f},{b:6.1f}) luma={luma:6.1f} sd={sd:6.1f}")
        if not cell_means:
            print("  region too small for one 64px cell")
            continue
        agg_r = sum(c[0] for c in cell_rgbs) / len(cell_rgbs)
        agg_g = sum(c[1] for c in cell_rgbs) / len(cell_rgbs)
        agg_b = sum(c[2] for c in cell_rgbs) / len(cell_rgbs)
        print(f"  -- {len(cell_means)} cells --")
        print(f"  aggregate mean RGB=({agg_r:.1f},{agg_g:.1f},{agg_b:.1f})  "
              f"mean luma={statistics.mean(cell_means):.1f} (range {min(cell_means):.1f}-{max(cell_means):.1f})  "
              f"mean sd={statistics.mean(cell_sds):.1f} (range {min(cell_sds):.1f}-{max(cell_sds):.1f})")


if __name__ == "__main__":
    main()
