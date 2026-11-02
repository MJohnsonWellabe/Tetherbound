"""Coat value lift for dark creatures (CREATURES-F36, 31 Oct 2026).

GPU ROSTER-1 High (31 Oct) and CPU r5 judges: dark coats merge with the ground
and hide the face (duskhush "near-black plumage, no visible eyes", cindercub
and ashtusk "rim light and value lift", thundertunnel "a dark mound with no
readable face" even after its first lift). Thundertunnel's own first lift
gained +0.8 on the GPU, so this applies the same grade to each species' live
ordinary coat: dark, low-saturation coat texels gain value (x SCALE plus FLOOR),
feathered; the darkest texels (eyes, mouth line) and saturated accents (embers,
quills, arcs) keep their exact pixels. Each graded file sits beside its
source as <stem>_coat_lift.png and is selected only by the flag
creatures_f36_coat_lift in data/config/creature_coat_flags.json (OFF by
default). Mesh, rig, UVs, clips and the source files are untouched.

    python3 tools/art_pipeline/grade_coat_value.py [species ...]
"""
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import shift_reserved_red as T  # noqa: E402  (HSV helpers)

C = "assets/creatures/tetherbound/"
# source (the live ordinary albedo, probed in engine), value band lifted
# (full below the first, none above the second), saturation band kept out,
# scale, floor, saturation scale on lifted texels.
SPECIES = {
    "duskhush": (C + "duskhush/models/creature_duskhush_lod0_base_color_vivid.png", (0.32, 0.45), (0.50, 0.65), 1.6, 0.03, 0.95),
    "cindercub": (C + "cindercub/candidate_nat1024b/models/creature_cindercub_nat1024b_Image_0.jpg", (0.30, 0.42), (0.55, 0.70), 1.45, 0.02, 1.0),
    "ashtusk": (C + "ashtusk_native/models/ashtusk_native_extracted_base_color_ashtusk.png", (0.30, 0.42), (0.55, 0.70), 1.5, 0.03, 1.0),
    "thundertunnel": (C + "thundertunnel/models/thundertunnel_extracted_base_color_vivid.png", (0.38, 0.50), (0.45, 0.58), 1.25, 0.02, 0.9),
    # Batch 2 (flag creatures_f36_coat_lift_2). GPU roster 24 Oct: shadelet
    # "near-black, no rim light; silhouette dissolves", stormtrail "flat black
    # placeholder dog", nightburrow (CO12 31 Oct) "coat noisy". The night and
    # storm variants keep a darker coat than their bases (gentler lift).
    "shadelet": (C + "shadelet/models/creature_shadelet_lod0_base_color.jpg", (0.30, 0.42), (0.55, 0.70), 1.5, 0.03, 1.0),
    "stormtrail": (C + "trailpup/candidate_nat1024/models/creature_trailpup_nat1024_Image_0_stormtrail.png", (0.34, 0.46), (0.40, 0.55), 1.35, 0.03, 1.0),
    "nightburrow": (C + "burrowback/candidate_nat1024/models/creature_burrowback_nat1024_Image_0_nightburrow.png", (0.32, 0.45), (0.40, 0.55), 1.4, 0.03, 1.0),
    # Batch 3 (flag remake_owner1101_dark_lift, cause-remakes 1 Nov). GPU
    # creature stage: the owner-rule remakes Brooktail (black river otter) and
    # Voltarach (dark spider) sink into dark ground. A gentle lift keeps the
    # black identity; the aqua spots and blue sparks (saturated) keep their pixels.
    "brooktail_owner1101": (C + "brooktail/candidate_owner1101/models/creature_brooktail_owner1101_Image_0.jpg", (0.26, 0.40), (0.45, 0.60), 1.35, 0.03, 1.0),
    "voltarach_owner1101": (C + "voltarach/candidate_owner1101/models/creature_voltarach_owner1101_Image_0.jpg", (0.28, 0.42), (0.45, 0.60), 1.4, 0.03, 1.0),
}
BATCH_2 = ("shadelet", "stormtrail", "nightburrow")
BATCH_3 = ("brooktail_owner1101", "voltarach_owner1101")
KEEP_DARKEST = (0.03, 0.06)


def _ramp(lo, hi, x):
    u = np.clip((x - lo) / (hi - lo), 0.0, 1.0)
    return u * u * (3.0 - 2.0 * u)


def target(source):
    # JPEG sources (Meshy remakes, 2048 px) stay JPEG: a lossless 2048 PNG is 5-8 MB.
    stem, ext = os.path.splitext(source)
    return stem + ("_coat_lift.jpg" if ext == ".jpg" and "_owner1101_" in stem else "_coat_lift.png")


def grade(rgb, val_band, sat_band, scale, floor, sat_scale):
    h, s, v = T._hsv(rgb)
    w = (1.0 - _ramp(*val_band, v)) * (1.0 - _ramp(*sat_band, s)) * _ramp(*KEEP_DARKEST, v)
    out_v = v + ((v * scale + floor) - v) * w
    out_s = s * (1.0 - (1.0 - sat_scale) * w)
    return np.clip(T._rgb(h, np.clip(out_s, 0, 1), np.clip(out_v, 0, 1)), 0, 1), w


def main():
    for name in sys.argv[1:] or sorted(SPECIES):
        source, val_band, sat_band, scale, floor, sat_scale = SPECIES[name]
        image = Image.open(os.path.join(ROOT, source))
        alpha = image.getchannel("A") if image.mode == "RGBA" else None
        rgb = np.asarray(image.convert("RGB")).astype(np.float64) / 255.0
        out, w = grade(rgb, val_band, sat_band, scale, floor, sat_scale)
        h, s, v = T._hsv(out)
        signed = np.where(h > 180.0, h - 360.0, h)
        red = (signed >= -15.0) & (signed <= 26.0) & (s >= 0.55) & (v >= 0.12)
        graded = Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGB")
        if alpha is not None:
            graded.putalpha(alpha)
        graded.save(os.path.join(ROOT, target(source)), **({"quality": 90} if target(source).endswith(".jpg") else {}))
        print("%s: lifted %.1f%% of texels (w > 0.5), median value %.2f -> %.2f, reserved red %.3f%% -> %s"
              % (name, (w > 0.5).mean() * 100, np.median(rgb.max(-1)), np.median(out.max(-1)),
                 red.mean() * 100, target(source)))


if __name__ == "__main__":
    main()
