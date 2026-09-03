#!/usr/bin/env python3
"""NIGHT-LEGIBILITY (ROADMAP 2.7) evidence numbers: median luma in the
midground band (rows 25%-75% of frame height) of each stand, before/after.

    python3 tools/_night_legibility_stats.py shots/night_legibility/*.png

Rec. 709 luma, same weighting frame_stats.py already uses project-wide.
"""

import sys
import numpy as np
from PIL import Image

LUMA = np.array([0.2126, 0.7152, 0.0722])

# Hand-framed subject boxes (left, top, right, bottom) in the fixed camera
# poses tools/_capture_night_legibility.gd shoots -- the whole-frame midground
# median already answers "is the scene readable", these answer the sharper
# question the roadmap item actually asks: does THIS subject (the tent, the
# creature) read against the ground right next to it, the same comparison
# ROADMAP 2.4's "creature-vs-ground luminance ratio" already used.
SUBJECT_BOXES = {
    "01-unlit-camp-night.png": (500, 330, 760, 480),
    "02-creature-pair-night-mudsnout.png": (470, 120, 680, 310),
    "02-creature-pair-night-bramblebun.png": (490, 120, 670, 310),
    "02-creature-pair-night-sparkit.png": (520, 260, 800, 470),
    "03-fixed-creature-night-sparkit.png": (470, 120, 680, 310),
}


def subject_ground_ratio(path, rgb, luma):
    box = SUBJECT_BOXES.get(path.split("/")[-1])
    if box is None:
        return None
    l, t, r, b = box
    subject = luma[t:b, l:r]
    h, w = luma.shape
    # Ground sample: a same-size band directly below the subject box, clamped
    # to stay in frame -- the immediate surroundings the subject has to read
    # against, not the whole frame's average.
    gh = b - t
    gt = min(b + 10, h - gh - 1)
    gt = max(gt, 0)
    ground = luma[gt:gt + gh, l:r]
    return {
        "subject_median": float(np.median(subject)),
        "ground_median": float(np.median(ground)),
        "ratio": float((np.median(subject) + 1e-4) / (np.median(ground) + 1e-4)),
    }


def measure(path):
    img = Image.open(path).convert("RGB")
    rgb = np.asarray(img, dtype=np.float32) / 255.0
    luma = rgb @ LUMA
    h = luma.shape[0]
    mid = luma[int(h * 0.25):int(h * 0.75), :]
    return {
        "median": float(np.median(mid)),
        "mean": float(mid.mean()),
        "p10": float(np.percentile(mid, 10)),
        "p90": float(np.percentile(mid, 90)),
        "full_median": float(np.median(luma)),
    }


def main():
    print("%-34s %8s %8s %8s %8s %8s" % ("frame", "midMed", "midMean", "p10", "p90", "fullMed"))
    rows = []
    for path in sys.argv[1:]:
        s = measure(path)
        print("%-34s %8.4f %8.4f %8.4f %8.4f %8.4f" % (
            path.split("/")[-1], s["median"], s["mean"], s["p10"], s["p90"], s["full_median"]))
        img = Image.open(path).convert("RGB")
        rgb = np.asarray(img, dtype=np.float32) / 255.0
        luma = rgb @ LUMA
        sg = subject_ground_ratio(path, rgb, luma)
        if sg is not None:
            rows.append((path.split("/")[-1], sg))
    if rows:
        print("\n%-34s %10s %10s %8s" % ("frame", "subjMed", "groundMed", "ratio"))
        for name, sg in rows:
            print("%-34s %10.4f %10.4f %8.2f" % (name, sg["subject_median"], sg["ground_median"], sg["ratio"]))


if __name__ == "__main__":
    main()
