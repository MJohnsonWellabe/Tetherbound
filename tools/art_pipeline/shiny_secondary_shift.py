#!/usr/bin/env python3
"""Paint a remake's shiny albedo as a hue shift on its warm secondary regions.

Creatures-ralph (4 Nov 2026), F39#4 ("several shiny variants become
near-uniform hot magenta and lose their ordinary species material and pattern
identity"; NEAR6-TW judges: "a colour shift on shell or plates, not a
whole-body violet"). The remakes carry two tones plus cyan glow lines: a
primary (teal, slate) and a warm cream/tan secondary (fins, spines, plates).
This keeps every pixel's value and texture and the primary and glow regions as
they are, and moves only the warm secondary hue band to a new hue, weighted by
a soft mask, so the species pattern survives and the shiny reads on its
secondary regions. Never red or oxblood (Team Tether only): targets are
checked against the red band.

    python3 tools/art_pipeline/shiny_secondary_shift.py in.jpg out.png \
        --hue=46 [--sat=1.6] [--band=12,60] [--min-sat=0.10]
"""
import colorsys  # noqa: F401  (documentation: HSV as in colorsys)
import sys

import numpy as np
from PIL import Image


def rgb_to_hsv(rgb):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx = rgb.max(-1); mn = rgb.min(-1); d = mx - mn
    h = np.zeros_like(mx)
    m = d > 1e-6
    rm = m & (mx == r); gm = m & (mx == g) & ~rm; bm = m & ~rm & ~gm
    h[rm] = ((g - b)[rm] / d[rm]) % 6
    h[gm] = (b - r)[gm] / d[gm] + 2
    h[bm] = (r - g)[bm] / d[bm] + 4
    h = h * 60.0
    s = np.where(mx > 1e-6, d / np.maximum(mx, 1e-6), 0)
    return h, s, mx


def hsv_to_rgb(h, s, v):
    c = v * s
    hp = (h % 360) / 60.0
    x = c * (1 - np.abs(hp % 2 - 1))
    z = np.zeros_like(h)
    conds = [(hp < 1), (hp < 2), (hp < 3), (hp < 4), (hp < 5), (hp >= 5)]
    rgbs = [(c, x, z), (x, c, z), (z, c, x), (z, x, c), (x, z, c), (c, z, x)]
    out = np.zeros(h.shape + (3,))
    done = np.zeros(h.shape, bool)
    for cond, (r, g, b) in zip(conds, rgbs):
        sel = cond & ~done
        out[sel] = np.stack([r[sel], g[sel], b[sel]], -1)
        done |= sel
    return out + (v - c)[..., None]


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def main():
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    src, out = args[0], args[1]
    target = float(opts["hue"])
    if target < 20 or target > 340:
        raise SystemExit("hue %.0f is in the red band (reserved for Team Tether)" % target)
    sat_mult = float(opts.get("sat", 1.6))
    lo, hi = (float(x) for x in opts.get("band", "12,60").split(","))
    min_sat = float(opts.get("min-sat", "0.10"))
    rgb = np.asarray(Image.open(src).convert("RGB"), float) / 255.0
    h, s, v = rgb_to_hsv(rgb)
    feather = 8.0
    w = smoothstep(lo - feather, lo, h) * (1 - smoothstep(hi, hi + feather, h))
    w *= smoothstep(min_sat * 0.5, min_sat, s)
    s2 = np.clip(s * sat_mult, 0, 0.85)
    shifted = hsv_to_rgb(np.full_like(h, target), s2, v)
    res = rgb * (1 - w[..., None]) + shifted * w[..., None]
    Image.fromarray((np.clip(res, 0, 1) * 255 + 0.5).astype(np.uint8)).save(out)
    print("%s: %.1f%% of pixels in the secondary band (weight > 0.5), hue -> %.0f" % (
        out, 100.0 * float((w > 0.5).mean()), target))


if __name__ == "__main__":
    main()
