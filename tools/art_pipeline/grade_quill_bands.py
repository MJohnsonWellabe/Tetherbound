#!/usr/bin/env python3
"""Two-tone quills for a quilled remake (Creatures-ralph, 2 Nov 2026).

Batch-4 GPU judges on Cliffspike's remake: "grey porcupine hides its face under
the quills", one flat pale value over body and quills. A real porcupine's
quills are banded: dark at the base, pale toward the tip, over a dark body.
Each texel's 3D distance from the body centre (anatomy map,
tools/creature_anatomy_maps.py) grades it from a dark warm base tone (body and
quill roots) to a pale cream tip; the legs keep the base tone and the face
(front, below the quill line) a lighter warm grey so it separates from the
quills. Fine detail keeps its local value ratio; saturated element pixels
(the glowing eyes and lines) keep their exact values. Writes
<stem>_Image_0_bands.jpg beside the source; selected only by a coat flag in
data/config/creature_coat_flags.json.

    python3 tools/art_pipeline/grade_quill_bands.py cliffspike/candidate_owner1101
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from creature_anatomy_maps import build  # noqa: E402
from repaint_creature_textures import rgb_to_hsv  # noqa: E402

BASE = (32.0, 0.22, 0.30)   # hue, sat, val: dark warm brown-grey
TIP = (42.0, 0.12, 0.86)    # pale cream
FACE = (34.0, 0.16, 0.52)   # warm mid grey
CENTRE = np.array([0.5, 0.45, 0.5])


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def hsv_to_rgb(h, s, v):
    h = (h % 360.0) / 60.0
    i = np.floor(h).astype(int) % 6
    f = h - np.floor(h)
    p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    r = np.choose(i, [v, q, p, p, t, v])
    g = np.choose(i, [t, v, v, q, p, p])
    b = np.choose(i, [p, p, t, v, v, q])
    return np.stack([r, g, b], -1)


def main():
    folder = sys.argv[1]
    models = os.path.join(ROOT, "assets", "creatures", "tetherbound", folder, "models")
    stem = sorted(f for f in os.listdir(models) if f.endswith(".glb"))[0][:-4]
    src_path = os.path.join(models, stem + "_Image_0.jpg")
    img = Image.open(src_path).convert("RGB")
    size = img.width
    anatomy, _ = build(folder, size=size)
    if int(anatomy["size"]) != size:
        anatomy, _ = build(folder, size=size, force=True)
    unit, valid = anatomy["unit"], anatomy["valid"]
    rgb = np.asarray(img).astype(np.float64) / 255.0
    h, s, v = rgb_to_hsv(rgb)
    r = np.linalg.norm((unit - CENTRE) * 2.0, axis=-1)
    tip = smooth(0.58, 0.9, r) * smooth(0.22, 0.4, unit[..., 1])
    face = smooth(0.8, 0.9, unit[..., 2]) * (1.0 - smooth(0.55, 0.7, unit[..., 1]))
    tip *= 1.0 - face
    lum = Image.fromarray((v * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(6))
    local = np.asarray(lum).astype(np.float64) / 255.0
    detail = np.clip(v / np.maximum(local, 0.04), 0.55, 1.6)
    th = BASE[0] + (TIP[0] - BASE[0]) * tip
    ts = BASE[1] + (TIP[1] - BASE[1]) * tip
    tv = BASE[2] + (TIP[2] - BASE[2]) * tip
    th = th * (1 - face) + FACE[0] * face
    ts = ts * (1 - face) + FACE[1] * face
    tv = tv * (1 - face) + FACE[2] * face
    out = hsv_to_rgb(th, ts, np.clip(tv * detail, 0.0, 1.0))
    keep = (s > 0.3) & (h > 150) & (h < 215) | ~valid
    out[keep] = rgb[keep]
    dst = os.path.join(models, stem + "_Image_0_bands.jpg")
    Image.fromarray((out * 255).round().astype(np.uint8)).save(dst, quality=90)
    print("%s: bands -> %s (tip share %.0f%%, face %.1f%%)" % (
        folder, os.path.relpath(dst, ROOT), 100 * tip[valid].mean(), 100 * face[valid].mean()))


if __name__ == "__main__":
    main()
