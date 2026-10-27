"""Mirejaw dark-fill grade (CLOSE-OUT, 27 Oct 2026).

GPU CO8 (tb/gpu-pass 41b922661): main's Mirejaw maps 6.53; the r2 retexture
(grade_retex.py) lost -1.08 because it replaced the reticulated pattern. The
coordinator's brief: keep main's reticulated pattern, warm its dark fill
toward olive-umber, and lift the back's values so the top-down faint end reads.

This touches only the near-black cell fill inside the tan net, on main's own
albedo (main_albedo_regions.jpg, byte-identical to main's Image_0):
- texels darker than value 0.36 and not strongly saturated move toward an
  olive-umber hue (42 degrees) at saturation 0.34 and gain value (x1.45 plus a
  small floor), feathered out between value 0.26 and 0.36 so the tan net, the
  cream belly and the amber frills keep their exact pixels;
- the very darkest texels (value under 0.08: pupils, nostrils, mouth line)
  are left alone.
It writes the result into the model's embedded Image_0 and the extracted jpg
beside it; mesh, rig, UVs and clips are untouched. Deterministic.

    python3 assets/creatures/tetherbound/mirejaw/candidate/retex/grade_fill.py [--preview out.png]
"""
import io
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "art_pipeline"))
import shift_reserved_red as T  # noqa: E402  (HSV helpers and GLB writer)

SOURCE = os.path.join(HERE, "main_albedo_regions.jpg")
MODELS = os.path.join(HERE, "..", "models")
GLB = os.path.join(MODELS, "creature_mirejaw_native.glb")
JPG = os.path.join(MODELS, "creature_mirejaw_native_Image_0.jpg")
FILL_VAL = (0.26, 0.36)  # full grade below the first, none above the second
KEEP_DARKEST = (0.06, 0.10)  # pupils and mouth line stay black
FILL_SAT_MAX = 0.45  # the amber frills and tan net are more saturated
OLIVE_UMBER_HUE = 42.0
OLIVE_UMBER_SAT = 0.34
VAL_SCALE = 1.45
VAL_FLOOR = 0.03


def _ramp(lo, hi, x):
    u = np.clip((x - lo) / (hi - lo), 0.0, 1.0)
    return u * u * (3.0 - 2.0 * u)


def grade(rgb):
    h, s, v = T._hsv(rgb)
    w = (1.0 - _ramp(*FILL_VAL, v)) * _ramp(*KEEP_DARKEST, v) * (1.0 - _ramp(FILL_SAT_MAX - 0.05, FILL_SAT_MAX + 0.05, s))
    out_h = h + (OLIVE_UMBER_HUE - h) * w
    out_s = s + (OLIVE_UMBER_SAT - s) * w
    out_v = v + ((v * VAL_SCALE + VAL_FLOOR) - v) * w
    print("graded share (w > 0.5): %.1f%%" % ((w > 0.5).mean() * 100))
    return np.clip(T._rgb(out_h, np.clip(out_s, 0, 1), np.clip(out_v, 0, 1)), 0, 1)


def main():
    rgb = np.asarray(Image.open(SOURCE).convert("RGB")).astype(np.float64) / 255.0
    out = grade(rgb)
    h, s, v = T._hsv(out)
    signed = np.where(h > 180.0, h - 360.0, h)
    red = (signed >= -15.0) & (signed <= 26.0) & (s >= 0.55) & (v >= 0.12)
    print("reserved red band texels: %.3f%%" % (red.mean() * 100))
    image = Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGB")
    if "--preview" in sys.argv:
        image.save(sys.argv[sys.argv.index("--preview") + 1])
        return
    buf = io.BytesIO()
    image.save(buf, "JPEG", quality=92)
    data = buf.getvalue()
    open(JPG, "wb").write(data)
    gltf, views = T._read_glb(GLB)
    target = next(i for i in gltf["images"] if i.get("name") == "Image_0")
    views[target["bufferView"]] = data
    target["mimeType"] = "image/jpeg"
    T._write_glb(GLB, gltf, views)
    print("graded into", os.path.relpath(GLB, ROOT))


if __name__ == "__main__":
    main()
