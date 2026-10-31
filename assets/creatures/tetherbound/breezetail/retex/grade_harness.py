"""Breezetail harness calm (CREATURES-F36 arm 1, 31 Oct 2026).

GPU CO8 (26 Oct): Breezetail maps 6.77 / 6.89 with the grounded flinch; the
judges' remaining defect is a "busy blue harness print". The board draws a blue
harness, so it stays blue: inside the blue texels only, the mottled print is
flattened toward one woven-strap tone (a mask-weighted blur of value and
saturation, so no brown fur bleeds in), eased slightly darker and less
saturated, toward a weathered canvas strap. Fur, face, ears and eyes keep their
exact pixels. Mesh, rig, UVs and clips are untouched. Deterministic.

The game renders the ordinary "vivid" colourway, so this grades main's own
vivid map (main_vivid.png, byte-identical to main's
breezetail_extracted_base_color_vivid.png).

    python3 assets/creatures/tetherbound/breezetail/retex/grade_harness.py [--preview out.png]
"""
import os
import sys

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "art_pipeline"))
import shift_reserved_red as T  # noqa: E402  (HSV helpers)

SOURCE = os.path.join(HERE, "main_vivid.png")
VIVID = os.path.join(HERE, "..", "models", "breezetail_extracted_base_color_vivid.png")
BLUE_HUE = (190.0, 240.0)
BLUE_SAT = (0.08, 0.18)  # feathered: grey-brown fur stays out
BLUR = 12.0  # texels, at 1024
FLATTEN = 1.0  # share of the blurred (calm) value/saturation taken
VAL_SCALE = 0.85
SAT_SCALE = 0.8


def _ramp(lo, hi, x):
    u = np.clip((x - lo) / (hi - lo), 0.0, 1.0)
    return u * u * (3.0 - 2.0 * u)


def _masked_blur(x, w):
    num = gaussian_filter(x * w, BLUR)
    den = gaussian_filter(w, BLUR)
    return np.where(den > 1e-4, num / np.maximum(den, 1e-4), x)


def grade(rgb):
    h, s, v = T._hsv(rgb)
    hue_w = _ramp(BLUE_HUE[0] - 8, BLUE_HUE[0], h) * (1.0 - _ramp(BLUE_HUE[1], BLUE_HUE[1] + 8, h))
    w = hue_w * _ramp(*BLUE_SAT, s)
    calm_v = _masked_blur(v, w)
    calm_s = _masked_blur(s, w)
    out_v = v + ((calm_v * VAL_SCALE) - v) * FLATTEN * w + (v * VAL_SCALE - v) * (1 - FLATTEN) * w
    out_s = s + ((calm_s * SAT_SCALE) - s) * FLATTEN * w + (s * SAT_SCALE - s) * (1 - FLATTEN) * w
    print("harness share (w > 0.5): %.1f%%" % ((w > 0.5).mean() * 100))
    return np.clip(T._rgb(h, np.clip(out_s, 0, 1), np.clip(out_v, 0, 1)), 0, 1)


def main():
    src = Image.open(SOURCE)
    alpha = src.getchannel("A") if src.mode == "RGBA" else None
    rgb = np.asarray(src.convert("RGB")).astype(np.float64) / 255.0
    out = grade(rgb)
    image = Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGB")
    if alpha is not None:
        image.putalpha(alpha)
    target = sys.argv[sys.argv.index("--preview") + 1] if "--preview" in sys.argv else VIVID
    image.save(target)
    print("graded into", os.path.relpath(target, ROOT))


if __name__ == "__main__":
    main()
