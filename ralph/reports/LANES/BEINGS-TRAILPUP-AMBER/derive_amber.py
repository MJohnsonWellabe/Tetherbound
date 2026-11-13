#!/usr/bin/env python3
"""BEINGS-TRAILPUP-AMBER (F36#83): amber paws and eyes for the live Trailpup.

Owner pick (1 Nov 2026): "Trailpup concept 1 (nearly real coyote, glowing amber
paws and eyes)". Derived from the live nat1024 albedo and the model's own UVs
(tools/art_pipeline/grade_vis_traits.py anatomy_for); no new art, no Meshy.

- Paws: everything below 6% of standing height glows fully, fading out by 15%.
- Eyes: texels within EYE_R of the two eye centres in model space (read off the
  texture's two iris texels; they mirror about the centre line).
Writes <stem>_amber.png (albedo: paws warmed, irises amber) and
<stem>_amber_glow.png (emission). Run from the repo root:

    python3 ralph/reports/LANES/BEINGS-TRAILPUP-AMBER/derive_amber.py
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
sys.path.insert(0, os.path.join(ROOT, "tools", "art_pipeline"))
import grade_vis_traits as G  # noqa: E402

D = "assets/creatures/tetherbound/trailpup/candidate_nat1024/models/"
STEM = D + "creature_trailpup_nat1024_Image_0"
AMBER = np.array([1.0, 0.48, 0.07])
EYES = [np.array([0.618, 0.776, 0.921]), np.array([0.335, 0.784, 0.915])]
EYE_R = 0.026
PAW_FULL, PAW_END = 0.06, 0.15


def smooth(x):
    x = np.clip(x, 0.0, 1.0)
    return x * x * (3.0 - 2.0 * x)


def main():
    albedo = np.asarray(Image.open(os.path.join(ROOT, STEM + ".jpg")).convert("RGB")).astype(np.float64) / 255.0
    size = albedo.shape[0]
    anatomy = G.anatomy_for(D + "creature_trailpup_nat1024.glb", size)
    unit, valid = anatomy["unit"].astype(np.float64), anatomy["valid"] > 0
    lum = albedo.mean(axis=2)
    paws = np.where(valid, 1.0 - smooth((unit[..., 1] - PAW_FULL) / (PAW_END - PAW_FULL)), 0.0)
    eyes = np.zeros_like(paws)
    for centre in EYES:
        d = np.linalg.norm((unit - centre) * np.array([1.0, 1.0, 1.6]), axis=-1)
        eyes = np.maximum(eyes, np.where(valid, 1.0 - smooth(d / EYE_R), 0.0))
    # Fur grain stays visible in the glow: brighter hairs glow more.
    grain = 0.55 + 0.45 * np.clip(lum / max(np.percentile(lum[paws > 0.5], 90), 1e-3), 0.0, 1.0)
    glow = np.clip(paws * grain, 0.0, 1.0)[..., None] * AMBER + (eyes[..., None] * np.array([1.0, 0.6, 0.12]))
    glow = np.clip(glow, 0.0, 1.0)
    out = albedo.copy()
    warm = (0.35 + 0.65 * lum[..., None] / max(lum.max(), 1e-3)) * AMBER
    out = out * (1.0 - 0.6 * paws[..., None]) + warm * 0.6 * paws[..., None]
    out = out * (1.0 - 0.8 * eyes[..., None]) + np.array([0.95, 0.6, 0.12]) * 0.8 * eyes[..., None]
    Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8)).save(os.path.join(ROOT, STEM + "_amber.png"))
    glow_image = Image.fromarray((glow * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))
    glow_image.save(os.path.join(ROOT, STEM + "_amber_glow.png"))
    print("paw texels %.2f%%, eye texels %.3f%% of the surface"
          % (100.0 * (paws > 0.5).sum() / valid.sum(), 100.0 * (eyes > 0.5).sum() / valid.sum()))


if __name__ == "__main__":
    main()
