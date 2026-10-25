"""Mosshock retexture grade (25 Oct 2026). The coordinator's Meshy /retexture of
the existing creature_mosshock_lod0.glb (task ids in provenance.jsonl,
enable_original_uv) gave one even moss coat with readable eyes (r1), but too pale
and sage, with a reddish mouth line and eye rims. This grades r1 toward the
retexture spec (ralph/reports/CREATURES/close-1024/mosshock-retex-spec):
- the orange mouth line and eye rims move to olive-brown (the brighter amber
  irises are kept);
- the coat moves to a moss green at about 100 deg with lighter values (GPU
  P, 26d54b066: lighter belly and throat; CI: the coat must read as moss,
  test_stormwood_source_colourways), saturation floored so it stays moss;
- the coat's darker folds (below its median value) become olive-brown, so the
  moss reads as growth over a darker hide rather than one flat green;
- the cream belly and throat lighten and desaturate toward pale cream.
It writes the graded image into the model's embedded base colour and the
extracted image beside it, so the mesh, rig, UVs and clips are untouched.

    python3 assets/creatures/tetherbound/mosshock/retex/grade_retex.py
"""
import io
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "art_pipeline"))
import shift_reserved_red as T  # noqa: E402  (HSV helpers and GLB writer)

SOURCE = os.path.join(HERE, "r1_base_color.png")
MODELS = os.path.join(HERE, "..", "models")
GLB = os.path.join(MODELS, "creature_mosshock_lod0.glb")
JPG = os.path.join(MODELS, "creature_mosshock_lod0_Image_0.jpg")
# Measured on r1: the coat is olive-yellow (hue 35-75); the mouth line and eye
# rims are a duller orange (15-35) next to the brighter amber irises; the belly
# is a pale warm tan (35-50, value above 0.55).
ORANGE = (12.0, 35.0)
IRIS_VAL_MIN = 0.5
IRIS_SAT_MIN = 0.5
IRIS_HUE = 34.0
IRIS_SAT = 0.72
RIM_TO_HUE = 45.0
RIM_SAT = 0.32
BELLY_HUE = (35.0, 50.0)
BELLY_VAL_MIN = 0.55
COAT_HUE = 100.0
COAT_SAT_SCALE = 1.35
COAT_SAT_MIN = 0.34
COAT_SAT_MAX = 0.6
COAT_VAL_SCALE = 0.95
FOLD_HUE = 62.0
FOLD_VAL_SCALE = 0.8
BELLY_TO_HUE = 44.0
BELLY_SAT = 0.16
BELLY_VAL_SCALE = 1.08


def grade(rgb):
    h, s, v = T._hsv(rgb)
    orange = (h >= ORANGE[0]) & (h < ORANGE[1])
    # The irises are the most saturated warm texels (orange to warm tan); the
    # spec asks for clear amber eyes, so they are pushed to amber.
    iris = (h >= ORANGE[0]) & (h < BELLY_HUE[1]) & (v >= IRIS_VAL_MIN) & (s >= IRIS_SAT_MIN)
    rim = orange & ~iris
    belly = (h >= BELLY_HUE[0]) & (h < BELLY_HUE[1]) & (v >= BELLY_VAL_MIN) & ~iris
    coat = (h >= BELLY_HUE[0]) & (h <= 140.0) & ~belly & ~iris
    out_h, out_s, out_v = h.copy(), s.copy(), v.copy()
    out_h[iris] = IRIS_HUE
    out_s[iris] = np.maximum(s[iris], IRIS_SAT)
    out_h[rim] = RIM_TO_HUE
    out_s[rim] = RIM_SAT
    out_h[coat] = COAT_HUE
    out_s[coat] = np.clip(s[coat] * COAT_SAT_SCALE, COAT_SAT_MIN, COAT_SAT_MAX)
    out_v[coat] = v[coat] * COAT_VAL_SCALE
    fold = coat & (v < np.median(v[coat]))
    out_h[fold] = FOLD_HUE
    out_v[fold] = v[fold] * FOLD_VAL_SCALE
    out_h[belly] = BELLY_TO_HUE
    out_s[belly] = np.minimum(s[belly], BELLY_SAT)
    out_v[belly] = np.minimum(1.0, v[belly] * BELLY_VAL_SCALE)
    print("iris %.2f%%" % (iris.mean() * 100))
    return T._rgb(out_h, out_s, out_v), rim.mean(), coat.mean(), belly.mean()


def main():
    rgb = np.asarray(Image.open(SOURCE).convert("RGB")).astype(np.float64) / 255.0
    out, red, coat, belly = grade(rgb)
    image = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGB")
    buf = io.BytesIO()
    image.save(buf, "JPEG", quality=92)
    data = buf.getvalue()
    open(JPG, "wb").write(data)
    gltf, views = T._read_glb(GLB)
    target = next(i for i in gltf["images"] if i.get("name") == "Image_0")
    views[target["bufferView"]] = data
    target["mimeType"] = "image/jpeg"
    T._write_glb(GLB, gltf, views)
    print("graded: rims %.1f%%, coat %.1f%%, belly %.1f%%" % (red * 100, coat * 100, belly * 100))


if __name__ == "__main__":
    main()
