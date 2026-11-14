#!/usr/bin/env python3
"""BEINGS-RIPPLET-DEEP (F39#19 Venn fight; Ripplet roster row): deeper sea-teal fur with grain.

G-land-mt-cragcut (3/3): Ripplet is "flat, glossy cyan with a toy-like plastic
finish", little fur detail, and "its pale value nearly merges with the pale
sand". The live albedo (creature_ripplet_owner1101_Image_0.jpg) is a light teal
(mean value 0.58) with cream patches. This keeps Ripplet's own teal-and-cream
identity (an earlier natural-otter recolour lost and stays off) and:
- moves only the teal fur (hue 160-205) to a deeper sea-teal: value x0.72,
  saturation x1.12, so the body separates from pale sand;
- sharpens the fur grain on the whole coat (unsharp mask on value), so it reads
  as fur rather than a smooth shell;
- leaves the cream belly, eyes, claws and the cyan glow marks alone.
Run from the repo root:
    python3 ralph/reports/LANES/BEINGS-RIPPLET-DEEP/derive_deep_teal.py
"""
import os

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".."))
D = "assets/creatures/tetherbound/ripplet/candidate_owner1101/models/"
SRC = D + "creature_ripplet_owner1101_Image_0.jpg"
OUT = D + "creature_ripplet_owner1101_Image_0_deep.png"


def main():
    image = Image.open(os.path.join(ROOT, SRC)).convert("RGB")
    hsv = np.asarray(image.convert("HSV")).astype(np.float64) / 255.0
    h, s, v = hsv[..., 0] * 360.0, hsv[..., 1], hsv[..., 2]
    # Teal fur, not the saturated cyan glow marks (s > 0.55) or the cream.
    teal = (h > 160.0) & (h < 205.0) & (s > 0.18) & (s < 0.55)
    weight = teal.astype(np.float64)
    weight = np.asarray(Image.fromarray((weight * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.5))).astype(np.float64) / 255.0
    v2 = v * (1.0 - 0.28 * weight)
    s2 = np.clip(s * (1.0 + 0.12 * weight), 0.0, 1.0)
    detail = np.asarray(image.convert("L").filter(ImageFilter.UnsharpMask(radius=2, percent=160, threshold=0))).astype(np.float64) / 255.0
    base = np.asarray(image.convert("L")).astype(np.float64) / 255.0
    v2 = np.clip(v2 + 0.6 * (detail - base), 0.0, 1.0)
    out = np.stack([h / 360.0, s2, v2], axis=-1)
    Image.fromarray((out * 255.0 + 0.5).astype(np.uint8), "HSV").convert("RGB").save(os.path.join(ROOT, OUT))
    print("teal texels %.1f%%; mean value %.3f -> %.3f" % (100.0 * teal.mean(), v.mean(), v2.mean()))


if __name__ == "__main__":
    main()
