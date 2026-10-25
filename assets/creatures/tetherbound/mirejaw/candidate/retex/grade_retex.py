"""Mirejaw retexture grade (25 Oct 2026). The coordinator's Meshy /retexture of
the shipped creature_mirejaw_native.glb (tb/meshy-1024 b959ba072, task ids in
provenance.jsonl, enable_original_uv) gave r2: a naturalistic brown marsh newt,
but its back is still near-black (a third of the atlas below value 0.25), the
frills came out dull tan, and the mouth interior is red. This grades r2 toward
the retexture spec (ralph/reports/CREATURES/close-1024/mirejaw-retex-spec on
tb/creatures):
- the back and flanks move to olive-umber (#4A4636, about value 0.28, never
  below 0.18), lifting the darks most and fading the lift out by value 0.7, so
  the scale pattern keeps its relief at lower contrast;
- the frills and crest (the amber regions of the shipped albedo,
  main_albedo_regions.jpg, which shares the UVs) move to amber-gold
  (#D69A3A to #E7B85A);
- the red mouth interior moves to a muted flesh-tan (no red, the hard rule);
- the cream belly, throat and inner legs are kept, a little less saturated.
It writes the graded image into the model's embedded Image_0 and the extracted
image beside it, so the mesh, rig, UVs, clips and f36 recipe are untouched
(re-pin its source_sha256). shift_reserved_red.py repaints this model from an
older original, so do not re-run it after this grade.

    python3 assets/creatures/tetherbound/mirejaw/candidate/retex/grade_retex.py [--preview out.png]
"""
import io
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "art_pipeline"))
import shift_reserved_red as T  # noqa: E402  (HSV helpers and GLB writer)

SOURCE = os.path.join(HERE, "r2_base_color.png")
REGIONS = os.path.join(HERE, "main_albedo_regions.jpg")
MODELS = os.path.join(HERE, "..", "models")
GLB = os.path.join(MODELS, "creature_mirejaw_native.glb")
JPG = os.path.join(MODELS, "creature_mirejaw_native_Image_0.jpg")
# Shipped albedo: the frills and crest are its saturated amber (hue 25-55).
FRILL_REGION = {"hue": (25.0, 55.0), "sat_min": 0.5, "val_min": 0.45}
FRILL_HUE = (33.0, 40.0)
FRILL_SAT = 0.62
FRILL_VAL_MEDIAN = 0.76
FRILL_VAL_MIN = 0.42
BODY_HUE = 46.0
BODY_SAT_SCALE = 0.5
BODY_SAT_MAX = 0.32
LIFT = 0.18  # added at value 0, fading to nothing at LIFT_TOP
LIFT_TOP = 0.7
VAL_FLOOR = 0.18
CREAM_FROM = (0.5, 0.7)  # values blend from the body grade to the source hue here
CREAM_SAT_MAX = 0.24
RED = {"hue": (-20.0, 26.0), "sat_min": 0.35}
MOUTH_HUE = 30.0
MOUTH_SAT_SCALE = 0.45


def _hsv_of(path):
    rgb = np.asarray(Image.open(path).convert("RGB")).astype(np.float64) / 255.0
    return rgb, T._hsv(rgb)


def grade(rgb):
    h, s, v = T._hsv(rgb)
    _, (mh, ms, mv) = _hsv_of(REGIONS)
    frill_raw = ((mh >= FRILL_REGION["hue"][0]) & (mh <= FRILL_REGION["hue"][1])
                 & (ms >= FRILL_REGION["sat_min"]) & (mv >= FRILL_REGION["val_min"]))
    soft = Image.fromarray((frill_raw * 255).astype(np.uint8), "L").filter(ImageFilter.MaxFilter(3))
    frill_w = np.asarray(soft.filter(ImageFilter.GaussianBlur(1.5))).astype(np.float64) / 255.0
    signed = np.where(h > 180.0, h - 360.0, h)
    red = (signed >= RED["hue"][0]) & (signed <= RED["hue"][1]) & (s >= RED["sat_min"])

    # Body: olive-umber, darks lifted, fading back to the source toward the cream.
    t = np.clip((v - CREAM_FROM[0]) / (CREAM_FROM[1] - CREAM_FROM[0]), 0.0, 1.0)
    body_h = BODY_HUE * (1 - t) + h * t
    body_s = np.where(t < 1.0, np.minimum(s * BODY_SAT_SCALE, BODY_SAT_MAX), np.minimum(s, CREAM_SAT_MAX))
    body_s = body_s * (1 - t) + np.minimum(s, CREAM_SAT_MAX) * t
    body_v = np.maximum(v + LIFT * np.clip(1.0 - v / LIFT_TOP, 0.0, 1.0), VAL_FLOOR)

    # Frills: amber-gold, the source's structure kept as value.
    fmed = np.median(v[frill_raw]) if frill_raw.any() else 0.5
    fv = np.clip(v * (FRILL_VAL_MEDIAN / max(fmed, 1e-6)), FRILL_VAL_MIN, 0.95)
    fh = FRILL_HUE[0] + (FRILL_HUE[1] - FRILL_HUE[0]) * np.clip((fv - FRILL_VAL_MIN) / (0.95 - FRILL_VAL_MIN), 0, 1)
    fs = np.full_like(s, FRILL_SAT)

    out_h = body_h * (1 - frill_w) + fh * frill_w
    out_s = body_s * (1 - frill_w) + fs * frill_w
    out_v = body_v * (1 - frill_w) + fv * frill_w
    mouth = red & (frill_w < 0.5)
    out_h[mouth] = MOUTH_HUE
    out_s[mouth] = s[mouth] * MOUTH_SAT_SCALE
    out_v[mouth] = np.maximum(v[mouth], VAL_FLOOR)
    print("frills %.1f%%, mouth %.2f%%, source below 0.25: %.1f%%" % (
        frill_raw.mean() * 100, mouth.mean() * 100, (v < 0.25).mean() * 100))
    return np.clip(T._rgb(out_h, out_s, out_v), 0, 1)


def main():
    rgb = np.asarray(Image.open(SOURCE).convert("RGB")).astype(np.float64) / 255.0
    out = grade(rgb)
    h, s, v = T._hsv(out)
    signed = np.where(h > 180.0, h - 360.0, h)
    red = (signed >= -15.0) & (signed <= 26.0) & (s >= 0.55) & (v >= 0.12)
    print("reserved red band texels: %.3f%%; value p10/p50 %.2f/%.2f" % (
        red.mean() * 100, np.percentile(v, 10), np.percentile(v, 50)))
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
