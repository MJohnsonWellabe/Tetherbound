"""Per-species coat grades for the VIS-CREATURES lane (1 Nov 2026).

Each grade answers the GPU judges' named defect for one F36 (0) species on its
live ordinary albedo (paths probed on a spawned CreatureBody). Every graded file
sits beside its source as <stem>_vis1.png and is selected only by the flag
creatures_vis_coat_1 in data/config/creature_coat_flags.json (OFF by default).
Mesh, rig, UVs, clips and the source files are untouched. Grades stay subtle
(owner, 24 Oct: "Don't go overboard"); no red is introduced.

    python3 tools/art_pipeline/grade_vis_creatures.py [species ...]
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import grade_coat_value as G  # noqa: E402
import shift_reserved_red as T  # noqa: E402

C = "assets/creatures/tetherbound/"
SOURCES = {
    "fulgocobra": C + "fulgocobra/models/fulgocobra_extracted_base_color_vivid.png",
    "mirejaw": C + "mirejaw/candidate/models/creature_mirejaw_native_Image_0.jpg",
    "cannonback": C + "cannonback/models/cannonback_extracted_base_color_vivid.png",
    "abyssal_guardian": C + "abyssal_guardian/candidate_installed_retex/models/creature_abyssal_guardian_installed_retex_r6_lod0_base_color_r6.png",
    "veridian": C + "veridian/candidate_nat1024/models/creature_veridian_nat1024_Image_0.jpg",
    "voltarach": C + "voltarach/candidate/models/creature_voltarach_native_Image_0.jpg",
    "mudsnout": C + "mudsnout/candidate_nat1024t/models/creature_mudsnout_nat1024t_Image_0.jpg",
    "solmane": C + "solmane/models/solmane_extracted_base_color_vivid.png",
}


def target(source):
    return os.path.splitext(source)[0] + "_vis1.png"


def _blur(x, radius):
    img = Image.fromarray(np.clip(x * 255.0, 0, 255).astype(np.uint8), "L")
    return np.asarray(img.filter(ImageFilter.GaussianBlur(radius))).astype(np.float64) / 255.0


def _hue_w(h, lo, hi, feather=8.0):
    return G._ramp(lo - feather, lo, h) * (1.0 - G._ramp(hi, hi + feather, h))


def fulgocobra(rgb):
    # GPU roster: "dark brown on stage" (R2 value and rim). Same lift as the
    # landed coat lifts, so the scales and hood separate from the ground.
    return G.grade(rgb, (0.32, 0.46), (0.55, 0.70), 1.45, 0.03, 1.0)[0]


def mirejaw(rgb):
    # "Dark faint blob; stretched dark bar on the tail": lift the darkest
    # hide a step, keep the scutes' pattern.
    return G.grade(rgb, (0.26, 0.40), (0.55, 0.70), 1.3, 0.025, 1.0)[0]


def cannonback(rgb):
    # "Brass-gear machinery shell reads as kitbash" (R4): the brass/olive
    # plating loses most of its saturation and some value, toward weathered
    # shell horn; the blue plates and the face keep their pixels.
    h, s, v = T._hsv(rgb)
    w = _hue_w(h, 32.0, 75.0) * G._ramp(0.25, 0.40, s)
    out_s = s * (1.0 - 0.7 * w)
    out_v = v * (1.0 - 0.12 * w)
    return T._rgb(h, out_s, out_v)


def abyssal_guardian(rgb):
    # "Glossy vinyl-blue skin with regular dots; toy-like": the bright cyan
    # dots blend most of the way into the surrounding hide, and the vinyl blue
    # is a little less saturated and darker (a deep-water hide).
    h, s, v = T._hsv(rgb)
    local = np.stack([_blur(rgb[..., c], 20) for c in range(3)], -1)
    lh, ls, lv = T._hsv(local)
    dots = _hue_w(h, 170.0, 200.0) * G._ramp(0.04, 0.14, v - lv)
    out = rgb + (local - rgb) * (0.7 * dots)[..., None]
    h2, s2, v2 = T._hsv(np.clip(out, 0, 1))
    blue = _hue_w(h2, 185.0, 235.0)
    s2 = s2 * (1.0 - 0.15 * blue)
    v2 = v2 * (1.0 - 0.06 * blue)
    return T._rgb(h2, s2, v2)


def veridian(rgb):
    # "Bone-white bands read as a skeleton; moss noise": the white bands drop
    # to a warm ivory, and the moss is smoothed so its noise reads as growth.
    h, s, v = T._hsv(rgb)
    white = (1.0 - G._ramp(0.30, 0.42, s)) * G._ramp(0.62, 0.75, v)
    v = v - (v - (0.62 + (v - 0.62) * 0.45)) * white
    s = s + (0.22 - s) * white * 0.6
    h = h + (38.0 - h) * white * (G._ramp(0.0, 1.0, white))
    out = T._rgb(np.mod(h, 360.0), np.clip(s, 0, 1), np.clip(v, 0, 1))
    soft = np.asarray(Image.fromarray((out * 255).astype(np.uint8), "RGB").filter(
        ImageFilter.MedianFilter(5))).astype(np.float64) / 255.0
    moss = _hue_w(h, 70.0, 150.0) * G._ramp(0.25, 0.40, s)
    return out + (soft - out) * (0.6 * moss)[..., None]


def voltarach(rgb):
    # "Chrome-gold statue; face lost" and its board: "a dark bronze/black base
    # with thin gold arcs and readable blue eyes. Today the gold covers most of
    # the body." The wide gold glow halo darkens toward bronze while the bright
    # arc cores keep their value; the black base lifts to dark bronze; the blue
    # eyes brighten.
    h, s, v = T._hsv(rgb)
    gold = _hue_w(h, 25.0, 60.0) * G._ramp(0.35, 0.50, s)
    halo = gold * (1.0 - G._ramp(0.80, 0.92, v))
    v_out = v - (v - v ** 2.0) * halo
    base = (1.0 - G._ramp(0.10, 0.20, v)) * G._ramp(0.02, 0.05, v)
    v_out = v_out + 0.035 * base
    s_out = s + (0.45 - s) * base * 0.5
    h_out = h + (32.0 - h) * base * (1.0 - G._ramp(0.0, 0.3, s))
    eyes = _hue_w(h, 205.0, 250.0) * G._ramp(0.45, 0.60, s)
    v_out = v_out * (1.0 + 0.35 * eyes)
    return T._rgb(np.mod(h_out, 360.0), np.clip(s_out, 0, 1), np.clip(v_out, 0, 1))


def mudsnout(rgb):
    # "Single tan value flattens the face": local value contrast (a wide
    # unsharp on value only) so muzzle, eyes and bristle blocks separate.
    h, s, v = T._hsv(rgb)
    v_out = v + 0.55 * (v - _blur(v, 18))
    return T._rgb(h, s, np.clip(v_out, 0, 1))


def solmane(rgb):
    # Pale washed tan at small size: modest local contrast and a darker mane
    # band so the head reads against a bright sky (no hue change).
    h, s, v = T._hsv(rgb)
    v_out = v + 0.45 * (v - _blur(v, 14))
    v_out = v_out * (1.0 - 0.08 * G._ramp(0.75, 0.95, v))
    return T._rgb(h, s, np.clip(v_out, 0, 1))


def main():
    for name in sys.argv[1:] or sorted(SOURCES):
        source = SOURCES[name]
        image = Image.open(os.path.join(ROOT, source))
        alpha = image.getchannel("A") if image.mode == "RGBA" else None
        rgb = np.asarray(image.convert("RGB")).astype(np.float64) / 255.0
        out = np.clip(globals()[name](rgb), 0.0, 1.0)
        hh, ss, vv = T._hsv(out)
        signed = np.where(hh > 180.0, hh - 360.0, hh)
        red_after = ((signed >= -15.0) & (signed <= 26.0) & (ss >= 0.55) & (vv >= 0.12)).mean()
        h0, s0, v0 = T._hsv(rgb)
        sg0 = np.where(h0 > 180.0, h0 - 360.0, h0)
        red_before = ((sg0 >= -15.0) & (sg0 <= 26.0) & (s0 >= 0.55) & (v0 >= 0.12)).mean()
        graded = Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGB")
        if alpha is not None:
            graded.putalpha(alpha)
        graded.save(os.path.join(ROOT, target(source)), optimize=True)
        print("%s: mean value %.3f -> %.3f, reserved-red texels %.4f -> %.4f -> %s" % (
            name, v0.mean(), vv.mean(), red_before, red_after, target(source)))


if __name__ == "__main__":
    main()
