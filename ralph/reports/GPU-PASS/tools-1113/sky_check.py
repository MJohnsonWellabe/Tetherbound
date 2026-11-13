"""Flag frames that are sky and little else, which blank_scan's flat-fill test passes (coordinator 8 Nov).

    python sky_check.py <frames root> [--all]

sky_stats(path) returns (sky_fraction, low_edges): sky_fraction is the share of pixels that are blue-dominant or pale, in smooth areas;
low_edges is the share of pixels in the lower half with a visible local contrast step. is_sky(...) applies the thresholds."""
import os
import sys

sys.path.append(r"C:\Users\mattj\AppData\Roaming\Python\Python312\site-packages")
from PIL import Image

SKY_MAX, EDGE_MIN = 0.85, 0.01


def sky_stats(path):
    with Image.open(path) as im:
        small = im.convert("RGB").resize((320, 180), Image.BILINEAR)
    px, grey = small.load(), small.convert("L").load()
    w, h = small.size
    sky = lower = edges = 0
    for y in range(h - 1):
        for x in range(w - 1):
            step = max(abs(grey[x, y] - grey[x + 1, y]), abs(grey[x, y] - grey[x, y + 1]))
            r, g, b = px[x, y]
            if step < 6 and b >= r and b >= g - 6:
                sky += 1
            if y >= h / 2:
                lower += 1
                if step >= 12:
                    edges += 1
    return sky / ((w - 1) * (h - 1)), edges / lower


def is_sky(sky_fraction, low_edges):
    return sky_fraction > SKY_MAX or low_edges < EDGE_MIN


if __name__ == "__main__":
    rows, show_all = [], "--all" in sys.argv
    for r, _, fs in os.walk(sys.argv[1]):
        for f in fs:
            if f.lower().endswith((".jpg", ".png")):
                p = os.path.join(r, f)
                rows.append(sky_stats(p) + (os.path.relpath(p, sys.argv[1]),))
    flagged = [x for x in rows if is_sky(x[0], x[1])]
    for s, e, rel in sorted(flagged if not show_all else rows, key=lambda x: x[1]):
        print(f"SKY {s:.3f} edges {e:.4f} {rel}")
    print(f"sky frames {len(flagged)} of {len(rows)}")
    if rows:
        print("highest sky fraction:", ", ".join(f"{x[0]:.3f} {os.path.basename(x[2])}" for x in sorted(rows, key=lambda x: -x[0])[:5]))
        print("lowest lower-half edges:", ", ".join(f"{x[1]:.4f} {os.path.basename(x[2])}" for x in sorted(rows, key=lambda x: x[1])[:5]))
