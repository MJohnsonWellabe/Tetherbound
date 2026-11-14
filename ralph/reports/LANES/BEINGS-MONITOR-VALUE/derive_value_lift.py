#!/usr/bin/env python3
"""BEINGS-MONITOR-VALUE (F36#50, F36#92): value-lifted copies of both monitors' live albedos.

The recipe that shipped for sixteen dark creatures (v1/b21-b28, e.g.
creatures_ralph_paddlenewt_value_lift): midtone gamma on value, a small
saturation gain, hue untouched, so the pattern and colours stay the species'
own. Nothing else changes. Run from the repo root:

    python3 ralph/reports/LANES/BEINGS-MONITOR-VALUE/derive_value_lift.py
"""
import colorsys
import os

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".."))
C = "assets/creatures/tetherbound/mangrove_monitor/"
# source (the albedo the game shows today), output, value gamma, saturation gain
JOBS = [
    (C + "candidate_r9/models/creature_mangrove_monitor_r9_Image_0_olive.jpg",
     C + "candidate_r9/models/creature_mangrove_monitor_r9_Image_0_olive_value_lift.png", 0.66, 1.15),
    (C + "models/mangrove_monitor_extracted_base_color_vivid.png",
     C + "models/mangrove_monitor_extracted_base_color_vivid_value_lift.png", 0.80, 1.05),
]


def lift(rgb, gamma, sat_gain):
    mx = rgb.max(axis=2)
    mn = rgb.min(axis=2)
    value = mx
    sat = np.where(mx > 1e-6, (mx - mn) / np.maximum(mx, 1e-6), 0.0)
    new_value = np.power(value, gamma)
    new_sat = np.clip(sat * sat_gain, 0.0, 1.0)
    # Rebuild RGB keeping hue: scale chroma and value per texel.
    scale = np.where(mx > 1e-6, new_value / np.maximum(mx, 1e-6), 1.0)[..., None]
    grey = mx[..., None]
    chroma = rgb - grey  # <= 0, hue-bearing part
    ratio = np.where(sat > 1e-6, new_sat / np.maximum(sat, 1e-6), 1.0)[..., None]
    return np.clip((grey + chroma * ratio) * scale, 0.0, 1.0)


def main():
    for source, out, gamma, sat_gain in JOBS:
        image = Image.open(os.path.join(ROOT, source))
        alpha = image.getchannel("A") if image.mode == "RGBA" else None
        rgb = np.asarray(image.convert("RGB")).astype(np.float64) / 255.0
        graded = lift(rgb, gamma, sat_gain)
        result = Image.fromarray((graded * 255.0 + 0.5).astype(np.uint8))
        if alpha is not None:
            result.putalpha(alpha)
        result.save(os.path.join(ROOT, out))
        print("%s: mean value %.3f -> %.3f" % (os.path.basename(out), rgb.max(axis=2).mean(), graded.max(axis=2).mean()))


if __name__ == "__main__":
    main()
