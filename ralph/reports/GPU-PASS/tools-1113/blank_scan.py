"""Flag frames whose 3D view is near-uniform: the world never drew (local GPU-pass guard, 1 Nov).

    python blank_scan.py <frames root> [--std 10]

Looks at the middle of the picture (x 25-75 %, y 30-80 %), away from the HUD corners and bottom bar; a grey-level standard deviation
under --std means a flat fill (sky colour or clear colour) with nothing rendered. Prints one line per flagged frame and a per-set count.
"""
import collections
import os
import sys

sys.path.append(r"C:\Users\mattj\AppData\Roaming\Python\Python312\site-packages")
from PIL import Image, ImageStat


def main(root, thr):
    flagged = collections.Counter()
    total = collections.Counter()
    for r, _, fs in os.walk(root):
        for f in fs:
            if not f.lower().endswith((".jpg", ".png")):
                continue
            p = os.path.join(r, f)
            rel = os.path.relpath(p, root)
            key = os.path.dirname(rel)
            total[key] += 1
            with Image.open(p) as im:
                w, h = im.size
                g = im.convert("L").crop((int(w * .25), int(h * .30), int(w * .75), int(h * .80)))
                sd = ImageStat.Stat(g).stddev[0]
            if sd < thr:
                flagged[key] += 1
                print(f"BLANK {sd:5.1f} {rel}")
    for k in sorted(flagged):
        print(f"SET {k}: {flagged[k]}/{total[k]} blank")
    print(f"blank frames {sum(flagged.values())} of {sum(total.values())}")


if __name__ == "__main__":
    args = sys.argv[1:]
    thr = float(args[args.index("--std") + 1]) if "--std" in args else 10.0
    main(args[0], thr)
