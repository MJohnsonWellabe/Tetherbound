"""Ripplet matte-fur grade (CLOSE-OUT, 27 Oct 2026).

GPU F36 main-1024: Ripplet maps 7.26, and the judges read its coat as a "flat,
plastic-smooth cyan material". The albedo already carries painted fur strands,
but they sit inside one saturated teal (median saturation 0.57), and the
roughness map holds the whole body near 0.68, so the coat takes a smooth sheen.

This grades main's own maps (main_albedo.jpg and main_mr.jpg, byte-identical to
main's Image_0 and Image_1):
- roughness (glTF green channel) is remapped toward fur, 0.68 -> 0.88, keeping
  its variation; occlusion and metallic channels are untouched;
- in the teal coat only (hue 170-230, saturation above 0.2), saturation is
  eased by SAT_SCALE, toward a naturalistic slate-teal otter pelt;
- the coat's painted strands get their value contrast back: a high-pass of
  value (blur radius STRAND_RADIUS) is amplified by STRAND_GAIN.
r1 (b60, CPU) mapped +0.27; all three judges still read "one flat cyan value",
no darker back or lighter belly. r2 adds countershading, as a real otter has:
- per coat texel, the surface normal in the model's bind pose (from
  tools/creature_anatomy_maps.py) sets a value scale, BACK_VAL on upward-facing
  fur (normal y above 0.35) through 1.0 on the flanks to BELLY_VAL facing down,
  and the back shifts BACK_HUE degrees toward a deeper blue. Gutter texels take
  their nearest covered texel's scale.
GPU CO11 (27 Oct): r2 maps 7.26 / 7.01; the judges still ask for a lighter
belly, toward the Sirenseal board's grey-white. r3 (CREATURES-F36 arm 1) lifts
the underside further (BELLY_VAL), starts it higher up the flank (BELLY_NY),
and drains its teal toward grey-white (BELLY_SAT) so the otter reads as a dark
back over a pale belly at roster distance.
The cream belly patch keeps its value and eases its yellow toward the same
grey-white (CREAM_SAT); eyes, nose and dark paws keep their exact pixels. Mesh, rig,
UVs and clips are untouched. Deterministic.

    python3 assets/creatures/tetherbound/ripplet/candidate_nat1024b/retex/grade_matte.py [--preview out.png]
"""
import io
import os
import sys

import numpy as np
from PIL import Image, ImageFilter
from scipy.ndimage import distance_transform_edt

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "art_pipeline"))
import shift_reserved_red as T  # noqa: E402  (HSV helpers and GLB writer)
sys.path.insert(0, os.path.join(ROOT, "tools"))
from creature_anatomy_maps import build as build_anatomy  # noqa: E402

SOURCE = os.path.join(HERE, "main_albedo.jpg")
SOURCE_MR = os.path.join(HERE, "main_mr.jpg")
MODELS = os.path.join(HERE, "..", "models")
GLB = os.path.join(MODELS, "creature_ripplet_nat1024b.glb")
JPG = os.path.join(MODELS, "creature_ripplet_nat1024b_Image_0.jpg")
JPG_MR = os.path.join(MODELS, "creature_ripplet_nat1024b_Image_1.jpg")
ROUGH_FROM = 0.675  # main's median roughness
ROUGH_TO = 0.88
COAT_HUE = (170.0, 230.0)
COAT_SAT_MIN = (0.15, 0.25)  # feathered: the cream belly stays out
SAT_SCALE = 0.72
STRAND_RADIUS = 3.0
STRAND_GAIN = 1.0  # added share of the high-pass (1.0 doubles strand contrast)
ANATOMY_KEY = "ripplet/candidate_nat1024b"
BACK_VAL = 0.70
BELLY_VAL = 1.40
BACK_NY = (0.0, 0.35)  # full back scale above the second
BELLY_NY = (-0.45, 0.1)  # full belly scale below the first
BACK_HUE = 6.0
BELLY_SAT = 0.45
CREAM_HUE = (30.0, 75.0)
CREAM_SAT = 0.55  # cream belly saturation scale
CREAM_MIN_VAL = (0.45, 0.6)  # belly saturation scale: teal toward grey-white


def _ramp(lo, hi, x):
    u = np.clip((x - lo) / (hi - lo), 0.0, 1.0)
    return u * u * (3.0 - 2.0 * u)


def _countershade(size):
    anatomy, _cache = build_anatomy(ANATOMY_KEY, size=size)
    ny = anatomy["nrm"][..., 1].astype(np.float64)
    _, (iy, ix) = distance_transform_edt(~anatomy["valid"], return_indices=True)
    ny = ny[iy, ix]
    back = _ramp(*BACK_NY, ny)
    belly = 1.0 - _ramp(*BELLY_NY, ny)
    return 1.0 + (BACK_VAL - 1.0) * back + (BELLY_VAL - 1.0) * belly, back, belly


def grade(rgb):
    h, s, v = T._hsv(rgb)
    scale, back, belly = _countershade(rgb.shape[0])
    hue_w = _ramp(COAT_HUE[0] - 8, COAT_HUE[0], h) * (1.0 - _ramp(COAT_HUE[1], COAT_HUE[1] + 8, h))
    w = hue_w * _ramp(*COAT_SAT_MIN, s)
    blur = np.asarray(Image.fromarray((v * 255 + 0.5).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(STRAND_RADIUS))).astype(np.float64) / 255.0
    out_v = (v + (v - blur) * STRAND_GAIN * w) * (1.0 + (scale - 1.0) * w)
    h = h + BACK_HUE * back * w
    out_s = s * (1.0 - (1.0 - SAT_SCALE) * w) * (1.0 - (1.0 - BELLY_SAT) * belly * w)
    cream = _ramp(CREAM_HUE[0] - 8, CREAM_HUE[0], h) * (1.0 - _ramp(CREAM_HUE[1], CREAM_HUE[1] + 8, h)) \
        * _ramp(*CREAM_MIN_VAL, v) * (1.0 - w)
    out_s = out_s * (1.0 - (1.0 - CREAM_SAT) * cream)
    print("coat share (w > 0.5): %.1f%%" % ((w > 0.5).mean() * 100))
    return np.clip(T._rgb(h, np.clip(out_s, 0, 1), np.clip(out_v, 0, 1)), 0, 1)


def grade_mr(mr):
    out = mr.copy()
    g = mr[..., 1]
    out[..., 1] = np.clip(ROUGH_TO + (g - ROUGH_FROM) * 0.6, 0.0, 1.0)
    return out


def _jpeg(arr):
    buf = io.BytesIO()
    Image.fromarray((arr * 255 + 0.5).astype(np.uint8), "RGB").save(buf, "JPEG", quality=92)
    return buf.getvalue()


def main():
    rgb = np.asarray(Image.open(SOURCE).convert("RGB")).astype(np.float64) / 255.0
    out = grade(rgb)
    mr = grade_mr(np.asarray(Image.open(SOURCE_MR).convert("RGB")).astype(np.float64) / 255.0)
    h, s, v = T._hsv(out)
    signed = np.where(h > 180.0, h - 360.0, h)
    red = (signed >= -15.0) & (signed <= 26.0) & (s >= 0.55) & (v >= 0.12)
    print("reserved red band texels: %.3f%%" % (red.mean() * 100))
    if "--preview" in sys.argv:
        Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGB").save(sys.argv[sys.argv.index("--preview") + 1])
        return
    data, data_mr = _jpeg(out), _jpeg(mr)
    open(JPG, "wb").write(data)
    open(JPG_MR, "wb").write(data_mr)
    gltf, views = T._read_glb(GLB)
    for name, blob in (("Image_0", data), ("Image_1", data_mr)):
        target = next(i for i in gltf["images"] if i.get("name") == name)
        views[target["bufferView"]] = blob
        target["mimeType"] = "image/jpeg"
    T._write_glb(GLB, gltf, views)
    print("graded into", os.path.relpath(GLB, ROOT))


if __name__ == "__main__":
    main()
