#!/usr/bin/env python3
"""Rank candidate ground textures on the defects the critic actually named.

    tools/rank_ground_textures.py <colour.jpg> [more.jpg ...]

The blind critic's verdict on the ground in use was specific and measured, and
it is the reason this script exists rather than a look at the thumbnails:

    The ground texture is cracked lichen-covered rock, not grass. Brightened
    crops show fractured plates with dark fissure lines between them. Measured:
    1-2px dark filaments persisting over 300 rows at multiple x positions in
    every frame. It is a stone texture tinted green and stretched over the
    terrain at one scale with no variation. This single asset is doing more
    damage than anything else in the exploration frames.

Picking the replacement by eye is how the current one got chosen. So each
candidate is scored on the three things that actually decide whether a tile
reads as grass at gameplay distance:

  fissure    Long thin dark filaments — the "cracked plates" signature. The
             single most diagnostic number here. Lower is better.
  flat       Fraction of the image with almost no local variation. This is the
             critic's "featureless tiles" measure, taken on the source rather
             than on a frame. Lower is better.
  greenness  How far the hue sits from grass-green, weighted by saturation. A
             photo of dry stone tinted green still measures badly here, which
             is the trap the current texture fell into.

Also reported, not scored: mean luminance and saturation, because a texture
that scores well and arrives near-black still has to be tinted back up and the
value structure was the OTHER half of the critic's ground complaint.
"""

import sys
import numpy as np
from PIL import Image


def load(path, size=512):
    im = Image.open(path).convert("RGB").resize((size, size), Image.LANCZOS)
    return np.asarray(im, dtype=np.float32) / 255.0


def to_hsv(rgb):
    mx, mn = rgb.max(axis=2), rgb.min(axis=2)
    delta = mx - mn
    sat = np.where(mx > 1e-6, delta / np.maximum(mx, 1e-6), 0.0)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    nz = delta > 1e-6
    hue = np.where(mx == r, ((g - b) / np.maximum(delta, 1e-6)) % 6,
          np.where(mx == g, ((b - r) / np.maximum(delta, 1e-6)) + 2,
                            ((r - g) / np.maximum(delta, 1e-6)) + 4)) * 60.0
    return np.where(nz, hue % 360.0, 0.0), sat, mx


def fissure_score(luma):
    """Long thin dark filaments, the cracked-plate signature.

    A crack is dark relative to its NEIGHBOURS and survives being smeared along
    one axis while vanishing when smeared along the other — that anisotropy is
    what separates a fissure from ordinary grass shadow, which is dark in every
    direction at once.
    """
    k = 9
    pad = k // 2
    p = np.pad(luma, pad, mode="reflect")
    horiz = np.mean([p[pad:pad + luma.shape[0], i:i + luma.shape[1]] for i in range(k)], axis=0)
    vert = np.mean([p[i:i + luma.shape[0], pad:pad + luma.shape[1]] for i in range(k)], axis=0)
    # Dark against the local average, in either direction.
    dark_h = np.clip(horiz - luma, 0, None)
    dark_v = np.clip(vert - luma, 0, None)
    ridge = np.maximum(dark_h, dark_v)
    return 100.0 * float((ridge > 0.09).mean())


def flat_score(luma):
    """Fraction with almost no local variation — the critic's featureless measure."""
    k = 5
    pad = k // 2
    p = np.pad(luma, pad, mode="reflect")
    win = np.stack([p[i:i + luma.shape[0], j:j + luma.shape[1]]
                    for i in range(k) for j in range(k)], axis=0)
    return 100.0 * float((win.std(axis=0) < 0.025).mean())


def greenness(hue, sat):
    """Distance from grass-green, weighted by how colourful the pixel is.

    Weighted, because a desaturated stone pixel has a meaningless hue and
    should not be allowed to vote — that is exactly how a grey rock texture
    passes a naive hue check once it has been tinted.
    """
    target = 95.0
    d = np.abs(((hue - target + 180.0) % 360.0) - 180.0)
    w = sat + 1e-6
    return float((d * w).sum() / w.sum())


def main():
    paths = sys.argv[1:]
    if not paths:
        print(__doc__)
        return
    print("%-34s %8s %7s %8s %7s %7s   %s" % (
        "texture", "fissure", "flat%", "off-hue", "luma", "sat", "verdict"))
    print("-" * 104)
    rows = []
    for p in paths:
        rgb = load(p)
        luma = rgb @ np.array([0.2126, 0.7152, 0.0722])
        hue, sat, _ = to_hsv(rgb)
        f, fl, g = fissure_score(luma), flat_score(luma), greenness(hue, sat)
        # Fissure dominates because it is the defect the critic actually named.
        rows.append((f * 2.0 + fl * 0.6 + g * 0.25, p, f, fl, g,
                     float(luma.mean()), float(sat.mean())))
    rows.sort()
    for i, (score, p, f, fl, g, l, s) in enumerate(rows):
        mark = "  <-- best" if i == 0 else ""
        print("%-34s %8.2f %7.1f %8.1f %7.3f %7.3f   %.1f%s" % (
            p.split("/")[-1], f, fl, g, l, s, score, mark))


if __name__ == "__main__":
    main()
