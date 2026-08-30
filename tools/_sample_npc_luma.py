#!/usr/bin/env python3
"""Measure a rendered character's own mean luminance against a magenta
background probe frame (tools/_probe_grunt_luminance.gd).

    tools/_sample_npc_luma.py shots/_diag/grunt_luminance_day_grunt.png

The background colour is SAMPLED from the image's own corner rather than
hardcoded, because world_look.gd's adjustment_saturation/brightness/contrast
pass (Godot's Environment colour-grade layer) runs on the WHOLE framebuffer,
background included -- a fixed magenta drifts to a different rendered colour
at every time-of-day preset (measured: (0.88,0,0.83) at day, (0.95,0.32,0.88)
at night), so a single hardcoded tolerance band either lets the whole night
background through as "day-shifted magenta" or excludes real dark uniform
pixels. Sampling the actual corner per-image sidesteps that entirely.
"""
import sys
import numpy as np
from PIL import Image

BG_DISTANCE_FLOOR = 0.12  # in 0..1 RGB space, per-channel Euclidean-ish


def main() -> None:
    for path in sys.argv[1:]:
        img = Image.open(path).convert("RGB")
        arr = np.asarray(img, dtype=np.float32) / 255.0
        bg = arr[0, 0].copy()  # top-left corner, background by construction
        dist = np.sqrt(((arr - bg) ** 2).sum(axis=2))
        mask = dist > BG_DISTANCE_FLOOR
        n = int(mask.sum())
        if n == 0:
            print(f"{path}: NO subject pixels found (bg={bg}) -- framing miss")
            continue
        luma = (arr[..., 0] * 0.2126 + arr[..., 1] * 0.7152 + arr[..., 2] * 0.0722)
        mean_luma = float(luma[mask].mean())
        print(f"{path}: bg={tuple(round(float(c),3) for c in bg)} "
              f"n={n} mean_luma={mean_luma:.4f} ({mean_luma*255:.1f}/255)")


if __name__ == "__main__":
    main()
