#!/usr/bin/env python3
"""Rec.709 exposure statistics for a rendered frame, so a lane can measure what
the blind visual judge will measure BEFORE spending a judging round on it.

    python3 tools/measure/frame_stats.py shots/hall_before/*.png

Prints, per frame: whole-frame median luma, the floor band (bottom 38% of rows)
median and its left/centre/right thirds, the crushed-black share, the warm/cool
split, the shadow tier's mean RGB and R/B ratio, and the brightest cluster's
centroid and colour -- the exact quantities the HALL-STAGING-0906 verdicts are
argued in, so before/after numbers are comparable to those reports.
"""
import sys
import numpy as np
from PIL import Image


def stats(path: str) -> None:
    img = np.asarray(Image.open(path).convert("RGB")).astype(np.float64)
    h, w, _ = img.shape
    r, g, b = img[..., 0], img[..., 1], img[..., 2]
    y = 0.2126 * r + 0.7152 * g + 0.0722 * b

    band = y[int(h * 0.62):, :]
    thirds = [band[:, i * w // 3:(i + 1) * w // 3] for i in range(3)]
    shadow = y < 8.0
    warm = (r > b + 30.0)
    cool = (b > r + 20.0)
    bright = y >= np.percentile(y, 99.9)
    ys, xs = np.nonzero(bright)

    print(f"\n{path}   {w}x{h}")
    print(f"  full-frame median Y      {np.median(y):7.1f}   mean {y.mean():6.1f}")
    print(f"  floor band median Y      {np.median(band):7.1f}   "
          f"L/C/R {np.median(thirds[0]):.1f} / {np.median(thirds[1]):.1f} / {np.median(thirds[2]):.1f}")
    print(f"  bottom 60 rows median    {np.median(y[-60:, :]):7.1f}")
    print(f"  %% frame below Y=8        {100.0 * shadow.mean():7.1f}%")
    print(f"  %% floor band below Y=8   {100.0 * (band < 8.0).mean():7.1f}%")
    print(f"  %% frame below Y=16       {100.0 * (y < 16.0).mean():7.1f}%")
    print(f"  warm px / warm luma      {100.0 * warm.mean():6.1f}% / "
          f"{100.0 * y[warm].sum() / max(y.sum(), 1.0):.1f}%")
    print(f"  cool px / cool luma      {100.0 * cool.mean():6.1f}% / "
          f"{100.0 * y[cool].sum() / max(y.sum(), 1.0):.1f}%")
    if shadow.any():
        sr, sg, sb = r[shadow].mean(), g[shadow].mean(), b[shadow].mean()
        print(f"  shadow tier mean RGB     {sr:.1f} / {sg:.1f} / {sb:.1f}   "
              f"R/B {sr / max(sb, 0.05):.1f}")
    print(f"  max Y                    {y.max():7.1f}")
    if len(xs):
        print(f"  top 0.1%% centroid        ({int(xs.mean())},{int(ys.mean())})   "
              f"RGB {r[bright].mean():.0f}/{g[bright].mean():.0f}/{b[bright].mean():.0f}")


if __name__ == "__main__":
    for arg in sys.argv[1:]:
        stats(arg)
