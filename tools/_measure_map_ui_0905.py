#!/usr/bin/env python3
"""N06-MAP-UI — measure the map screen's value ladder off a rendered frame.

    python3 tools/_measure_map_ui_0905.py <frame.png> [<frame.png> ...]

Prints, per frame: the dominant flat fields and the contrast ratios this lane's
acceptance is argued in. Numbers decided BEFORE the render (COMMON.md: "prove by
number where you can, decided before the render") — this only reports them.

The judge that produced this lane's brief reported "RGB(5,5,7) vs RGB(17,26,31),
1.16:1 in the wrong direction", so the same two quantities are what is measured
here: the largest flat fields on the screen, and how far apart they are.
"""

import sys
from collections import Counter

from PIL import Image


def relative_luminance(rgb):
    out = []
    for c in rgb[:3]:
        c = c / 255.0
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * out[0] + 0.7152 * out[1] + 0.0722 * out[2]


def contrast(a, b):
    la, lb = relative_luminance(a), relative_luminance(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def luma8(rgb):
    return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]


def report(path):
    image = Image.open(path).convert("RGB")
    pixels = list(image.getdata())
    counts = Counter(pixels)
    total = len(pixels)

    print(f"\n=== {path}  ({image.width}x{image.height}) ===")
    print("  largest flat fields:")
    fields = counts.most_common(6)
    for rgb, n in fields:
        print(
            "    RGB%-16s %6.2f%%  luma %3.0f/255  rel.lum %.4f"
            % (str(rgb), 100.0 * n / total, luma8(rgb), relative_luminance(rgb))
        )

    if len(fields) >= 2:
        print("  pairwise contrast between the largest fields:")
        for i in range(min(3, len(fields))):
            for j in range(i + 1, min(4, len(fields))):
                a, b = fields[i][0], fields[j][0]
                lighter = "first" if relative_luminance(a) > relative_luminance(b) else "second"
                print(
                    "    RGB%-16s vs RGB%-16s  %5.2f:1  (%s is lighter)"
                    % (str(a), str(b), contrast(a, b), lighter)
                )


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    for path in sys.argv[1:]:
        report(path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
