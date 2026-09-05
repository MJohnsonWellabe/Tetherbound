#!/usr/bin/env python3
"""W05-TREELINE-0904. Skyline-profile measure of tree-line silhouette variety.

Axis under test: does the tree-line read as varied, or as one shape repeated?
Operationalised, and fixed BEFORE any after-frame was looked at:

  sky pixel   : blue is the dominant-or-equal channel and the pixel is bright
                (r+g+b > 300), OR it is a near-neutral bright cloud
                (r+g+b > 540, max-min < 30). Calibrated against sampled pixels
                from the before frames: sky reads ~(108,143,161), cloud
                ~(192,194,194), foliage ~(3,31,6) / (15,50,4).
  skyline t(x): for each column, the topmost NON-sky row.
  columns used: only those containing at least one sky pixel -- a fully
                occluded column carries no silhouette information.

  sky_frac : fraction of the frame classified sky. Growing the canopy eats sky.
  relief   : standard deviation of t(x) in pixels over the used columns. A row
             of identical trees at identical scale gives a flat profile (low
             relief); a wood with a real age range gives peaks and shoulders.
  p05/p50  : 5th and 50th percentile of t(x). p05 is how high the tallest
             silhouettes reach (smaller row index = higher in frame).

Nothing here judges. It reports.
"""
import sys
from PIL import Image


def is_sky(r, g, b):
    if b >= r and b >= g and (r + g + b) > 300:
        return True
    lo, hi = min(r, g, b), max(r, g, b)
    return (r + g + b) > 540 and (hi - lo) < 30


def profile(path):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    px = im.load()
    tops, sky_px = [], 0
    for x in range(w):
        top, saw_sky = None, False
        for y in range(h):
            if is_sky(*px[x, y]):
                sky_px += 1
                saw_sky = True
            elif top is None:
                top = y
        if saw_sky and top is not None:
            tops.append(top)
    if not tops:
        return None
    mean = sum(tops) / len(tops)
    var = sum((t - mean) ** 2 for t in tops) / len(tops)
    tops.sort()
    q = lambda f: tops[int(f * (len(tops) - 1))]
    return dict(cols=len(tops), width=w, sky_frac=sky_px / (w * h),
                relief=var ** 0.5, p05=q(0.05), p50=q(0.50), mean=mean)


for path in sys.argv[1:]:
    s = profile(path)
    tag = path.split("/")[-1].replace(".png", "")
    side = path.split("/")[-2]
    if s is None:
        print("%-24s %-7s no sky-bearing column" % (tag, side))
        continue
    print("%-24s %-7s cols %4d/%4d  sky %.3f  relief %6.1f px  p05 %4d  p50 %4d" % (
        tag, side, s["cols"], s["width"], s["sky_frac"], s["relief"], s["p05"], s["p50"]))
