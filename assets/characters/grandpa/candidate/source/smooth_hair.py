"""F36#0 Grandpa hair and beard (coordinator, 25 Oct: GPU 7.20 after the eyes, 0.30
short; the judges' next lever was the noisy, felt-like hair and beard). Same
installed head, mesh, rig and UVs: only the white-grey hair and beard texels of
the albedo are smoothed. A median pass removes the felt speckle, a little of the
original is blended back so strand direction survives, and a gentle local
contrast keeps the hair from going flat. Identity and colours are unchanged.

Run after add_eye_detail.py. The albedo as it stands after the eyes is kept once
at source/hair/hair_base.png (a .gdignore folder), and every run repaints from
it, so re-running never compounds.

    python3 assets/characters/grandpa/candidate/source/smooth_hair.py
"""
import io
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import add_eye_detail as EYES  # noqa: E402  (GLB read/write and eye boxes)

BASE = os.path.join(HERE, "hair", "hair_base.png")
HAIR_SAT_MAX = 0.13
HAIR_VAL_MIN = 0.5
MEDIAN = 3          # px at 2048: pixel noise only
STRAND_RADIUS = 4.0 # px: the scale strands are drawn at
STRAND_AMOUNT = 0.6
MASK_SOFTNESS = 2.0


def main():
    png = os.path.join(EYES.MODELS, "grandpa_native_face_%s.png" % EYES.IMAGE_NAME)
    if not os.path.exists(BASE):
        os.makedirs(os.path.dirname(BASE), exist_ok=True)
        open(os.path.join(os.path.dirname(BASE), ".gdignore"), "a").close()
        Image.open(png).convert("RGB").save(BASE)
    base = Image.open(BASE).convert("RGB")
    rgb = np.asarray(base).astype(np.float64) / 255.0
    mx, mn = rgb.max(-1), rgb.min(-1)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-9), 0.0)
    hair = (sat <= HAIR_SAT_MAX) & (mx >= HAIR_VAL_MIN)
    for x0, y0, x1, y1 in EYES.EYE_BOXES:
        hair[y0:y1, x0:x1] = False
    mask = Image.fromarray((hair * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(MASK_SOFTNESS))
    m = np.asarray(mask).astype(np.float64)[..., None] / 255.0
    median = base.filter(ImageFilter.MedianFilter(MEDIAN))
    smooth = np.asarray(median).astype(np.float64) / 255.0
    soft = np.asarray(median.filter(ImageFilter.GaussianBlur(STRAND_RADIUS))).astype(np.float64) / 255.0
    cleaned = np.clip(smooth + (smooth - soft) * STRAND_AMOUNT, 0.0, 1.0)
    out = rgb * (1.0 - m) + cleaned * m
    image = Image.fromarray((out * 255).astype(np.uint8), "RGB")
    buf = io.BytesIO()
    image.save(buf, "PNG", optimize=True)
    data = buf.getvalue()
    open(png, "wb").write(data)
    gltf, blob = EYES.read_glb(EYES.GLB)
    views = [blob[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]] for v in gltf["bufferViews"]]
    target = next(i for i in gltf["images"] if i.get("name") == EYES.IMAGE_NAME)
    views[target["bufferView"]] = data
    EYES.write_glb(EYES.GLB, gltf, views)
    print("hair: cleaned %.1f%% of the albedo" % (hair.mean() * 100))


if __name__ == "__main__":
    main()
