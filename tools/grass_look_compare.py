#!/usr/bin/env python3
"""GRASS-REROLL. Did the LOOK survive the placement change?

    python3 tools/grass_look_compare.py shots/reroll_before/held-00.png \
                                        shots/reroll_after/held-00.png

The owner's instruction on 2026-08-28 was two-sided: stop the field
re-rendering as you walk, and "don't change the look of my grass, it's
awesome". The re-roll fix moves every tuft off a random disc and onto a world
lattice, so the two frames CANNOT be compared pixel for pixel -- no individual
tuft is in the same place, by construction, and a pixel diff would be large and
say nothing.

What has to be preserved is the statistics, so those are what this measures,
in horizontal bands because the field's whole point is that it is denser near
the camera:

  value / hue     the palette. `data/config/grass_field.json` derives its tints
                  from a measurement (meadow ground #798732 against the owner
                  reference's #7c8737), so a drift here is a real regression.
  edge energy     mean absolute luminance gradient. This is the density and
                  silhouette proxy: a blade against ground is an edge, so
                  thinner grass, shorter grass or fewer blades all read as less
                  edge energy per square of image.
  dark fraction   pixels below mid luminance, which is the shaded base of the
                  carpet -- it drops when you start seeing ground between the
                  tufts.

Neither frame's numbers mean anything alone. The comparison does.
"""
import sys
import numpy as np
from PIL import Image

BANDS = [("sky/far  ", 0.00, 0.35), ("mid      ", 0.35, 0.60),
         ("near     ", 0.60, 0.82), ("foreground", 0.82, 1.00)]


def stats(path):
    img = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32) / 255.0
    h = img.shape[0]
    lum = img @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    gy = np.abs(np.diff(lum, axis=0, prepend=lum[:1]))
    gx = np.abs(np.diff(lum, axis=1, prepend=lum[:, :1]))
    edge = gx + gy
    mx, mn = img.max(2), img.min(2)
    out = []
    for name, a, b in BANDS:
        s = slice(int(h * a), int(h * b))
        px = img[s]
        # hue in degrees, only where the pixel is coloured enough to have one
        sat = (mx[s] - mn[s])
        ok = sat > 0.06
        r, g, bl = px[..., 0], px[..., 1], px[..., 2]
        hue = np.degrees(np.arctan2(np.sqrt(3) * (g - bl), 2 * r - g - bl)) % 360
        out.append(dict(
            band=name,
            value=float(lum[s].mean()),
            hue=float(hue[ok].mean()) if ok.any() else float("nan"),
            sat=float(sat.mean()),
            edge=float(edge[s].mean()),
            dark=float((lum[s] < 0.45).mean()),
        ))
    return out


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        raise SystemExit(2)
    a, b = stats(sys.argv[1]), stats(sys.argv[2])
    print(f"{sys.argv[1]}  ->  {sys.argv[2]}\n")
    print(f"{'band':11s} {'value':>16s} {'hue':>16s} {'sat':>16s} "
          f"{'edge energy':>18s} {'dark frac':>16s}")
    for x, y in zip(a, b):
        def cell(k, fmt="{:.4f}"):
            u, v = x[k], y[k]
            d = "" if u == 0 else f" {v / u - 1:+5.0%}"
            return (fmt.format(u) + "->" + fmt.format(v) + d)
        print(f"{x['band']:11s} {cell('value'):>16s} {cell('hue', '{:.1f}'):>16s} "
              f"{cell('sat'):>16s} {cell('edge'):>18s} {cell('dark'):>16s}")
