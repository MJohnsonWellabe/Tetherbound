"""Thundertunnel fur value lift (CLOSE-OUT, 27 Oct 2026).

GPU F36#1 main-1024 (6.91) and CPU b62 (3/3 judges): "a very dark
purple-black mass", "near-black body with no visible eyes merges with the
dark backdrop". 79% of main's albedo is fur below value 0.30 (median 0.22,
hue about 284 degrees).

The game renders the ordinary "vivid" colourway, not the GLB's embedded albedo
(creature_body.gd `_swap_colourway_textures("vivid")`), so this grades main's
own vivid map (main_vivid.png, byte-identical to main's
thundertunnel_extracted_base_color_vivid.png): fur texels (value under FUR_VAL, saturation under FUR_SAT_MAX,
feathered) gain value (x VAL_SCALE plus VAL_FLOOR) and ease saturation toward
a slate-violet coat, so the body separates from the ground and the face reads.
The blue quills (saturated), pink snout and paws (bright) and the storm arc
emission map are untouched. Mesh, rig and clips are untouched. Deterministic.

    python3 assets/creatures/tetherbound/thundertunnel/retex/grade_value.py [--preview out.png]
"""
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "art_pipeline"))
import shift_reserved_red as T  # noqa: E402  (HSV helpers)

SOURCE = os.path.join(HERE, "main_vivid.png")
VIVID = os.path.join(HERE, "..", "models", "thundertunnel_extracted_base_color_vivid.png")
FUR_VAL = (0.30, 0.40)  # full lift below the first, none above the second
FUR_SAT_MAX = (0.45, 0.58)  # the blue quills are more saturated
KEEP_DARKEST = (0.03, 0.06)  # eyes and mouth line stay black
VAL_SCALE = 1.55
VAL_FLOOR = 0.03
SAT_SCALE = 0.8


def _ramp(lo, hi, x):
    u = np.clip((x - lo) / (hi - lo), 0.0, 1.0)
    return u * u * (3.0 - 2.0 * u)


def grade(rgb):
    h, s, v = T._hsv(rgb)
    w = (1.0 - _ramp(*FUR_VAL, v)) * (1.0 - _ramp(*FUR_SAT_MAX, s)) * _ramp(*KEEP_DARKEST, v)
    out_v = v + ((v * VAL_SCALE + VAL_FLOOR) - v) * w
    out_s = s * (1.0 - (1.0 - SAT_SCALE) * w)
    print("fur share (w > 0.5): %.1f%%" % ((w > 0.5).mean() * 100))
    return np.clip(T._rgb(h, np.clip(out_s, 0, 1), np.clip(out_v, 0, 1)), 0, 1)


def main():
    rgb = np.asarray(Image.open(SOURCE).convert("RGB")).astype(np.float64) / 255.0
    out = grade(rgb)
    h, s, v = T._hsv(out)
    signed = np.where(h > 180.0, h - 360.0, h)
    red = (signed >= -15.0) & (signed <= 26.0) & (s >= 0.55) & (v >= 0.12)
    print("reserved red band texels: %.3f%%" % (red.mean() * 100))
    image = Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGB")
    target = sys.argv[sys.argv.index("--preview") + 1] if "--preview" in sys.argv else VIVID
    image.save(target)
    print("graded into", os.path.relpath(target, ROOT))


if __name__ == "__main__":
    main()
