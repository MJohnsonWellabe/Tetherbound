"""Coat grades for the three F36 pose rows below 6 (LANE-REMAKES, 11 Nov 2026).

GPU re-score 8 Nov (ralph/reports/GPU-PASS/1108/G-rescore-tier2-batch-1/2.md):
Voltarach "chrome-gold statue, face lost", Abyssal Guardian "glossy vinyl,
toy-like", Ribbonray "saturated magenta, reads as an effect". Each grade sits
beside its source as <stem>_floor1.png (plus <stem>_floor1_glow.png where the
species gets an emission map) and is selected only by a flag in
data/config/creature_coat_flags.json (OFF by default). Mesh, rig, UVs, clips
and the source files are untouched; no red is introduced.

    python3 tools/art_pipeline/grade_remakes_floor.py [name ...]
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
    "voltarach": C + "voltarach/candidate/models/creature_voltarach_native_Image_0.jpg",
    "abyssal_guardian": C + "abyssal_guardian/candidate_owner1101/models/creature_abyssal_guardian_owner1101_Image_0.jpg",
    "ribbonray": C + "ribbonray/candidate_owner1101/models/creature_ribbonray_owner1101_Image_0.jpg",
    # LANE-BELOW6 (11 Nov): graded from the coats that ship, not the raw remake.
    "thundertunnel": C + "thundertunnel/candidate_owner1101/models/creature_thundertunnel_owner1101_Image_0_value_lift.png",
    "fulgocobra": C + "fulgocobra/candidate_owner1101/models/creature_fulgocobra_owner1101_Image_0_face.png",
}


def _f(x, kind, size):
    img = Image.fromarray(np.clip(x * 255.0, 0, 255).astype(np.uint8), "L")
    flt = {"min": ImageFilter.MinFilter, "max": ImageFilter.MaxFilter, "blur": ImageFilter.GaussianBlur}[kind]
    return np.asarray(img.filter(flt(size))).astype(np.float64) / 255.0


def _hue_w(h, lo, hi, feather=8.0):
    return G._ramp(lo - feather, lo, h) * (1.0 - G._ramp(hi, hi + feather, h))


def voltarach(rgb):
    # Board: charcoal shell, thin gold lightning cracks, blue eyes. In game the
    # gold floods whole plates ("chrome-gold statue") and the face is lost.
    # Wide bright gold fields (they survive a 19 px opening) and the dim gold halo go
    # to dark bronze; only thin bright crack cores stay gold. The charcoal
    # lifts a step so the shell models under the stage light; eyes brighten.
    h, s, v = T._hsv(rgb)
    gold = _hue_w(h, 22.0, 62.0) * G._ramp(0.35, 0.50, s) * G._ramp(0.20, 0.35, v)
    bright = gold * G._ramp(0.60, 0.80, v)
    wide = _f(_f(_f(bright, "min", 19), "max", 27), "blur", 3)
    core = bright * (1.0 - wide)
    plate = np.clip(gold - core, 0.0, 1.0)
    v_out = v * (1.0 - plate) + (0.10 + 0.24 * v) * plate
    s_out = s * (1.0 - plate) + 0.38 * plate
    h_out = h + (30.0 - h) * plate
    base = (1.0 - gold) * (1.0 - G._ramp(0.30, 0.45, s))
    v_out = v_out + (0.045 + 0.25 * v) * base * (1.0 - G._ramp(0.35, 0.6, v))
    eyes = _hue_w(h, 205.0, 255.0) * G._ramp(0.45, 0.60, s)
    v_out = v_out * (1.0 + 0.3 * eyes)
    out = T._rgb(np.mod(h_out, 360.0), np.clip(s_out, 0, 1), np.clip(v_out, 0, 1))
    glow = np.zeros_like(rgb)
    glow += rgb * (eyes * G._ramp(0.35, 0.6, v))[..., None]
    glow += rgb * (0.45 * core)[..., None]
    return out, glow


def abyssal_guardian(rgb):
    # "Glossy vinyl, toy-like": the hide is one flat saturated navy. The navy
    # loses a third of its saturation toward slate sea-blue, gains fine value
    # mottling from its own detail (so it reads as skin, not moulded plastic),
    # and the pure-white belly drops to a warm grey-cream as on the board.
    h, s, v = T._hsv(rgb)
    navy = _hue_w(h, 195.0, 250.0) * G._ramp(0.35, 0.55, s)
    s_out = s * (1.0 - 0.40 * navy)
    inner = _f(_f(navy, "min", 13), "blur", 3)
    v_out = v + 1.2 * (v - _f(v, "blur", 6)) * inner
    v_out = v_out + 0.04 * navy * (1.0 - G._ramp(0.25, 0.45, v))
    pale = (1.0 - G._ramp(0.12, 0.25, s)) * G._ramp(0.70, 0.85, v)
    v_out = v_out * (1.0 - 0.24 * pale)
    s_out = s_out + 0.10 * pale
    h = h + (38.0 - h) * pale
    return T._rgb(h, np.clip(s_out, 0, 1), np.clip(v_out, 0, 1)), None


def ribbonray(rgb):
    # "The whole body is saturated magenta, reads as an effect." Its board is a
    # blue-headed ray with blue-violet wings and a cream underside. Magenta and
    # mauve (hue 270-350) turn to deep ocean blue, darker and richer on the
    # dark scale texels, soft blue-grey on the pale ones; the cyan eyes keep
    # their pixels.
    h, s, v = T._hsv(rgb)
    mag = _hue_w(h, 262.0, 352.0, 12.0) * G._ramp(0.06, 0.16, s)
    dark = 1.0 - G._ramp(0.35, 0.75, v)
    h_t = 218.0 + 10.0 * (1.0 - dark)
    h_out = h + (h_t - h) * mag
    s_out = s + ((0.26 + 0.36 * dark) * np.clip(s / 0.30, 0.7, 1.2) - s) * mag
    v_out = v * (1.0 - (0.12 + 0.30 * dark) * mag)
    return T._rgb(np.mod(h_out, 360.0), np.clip(s_out, 0, 1), np.clip(v_out, 0, 1)), None


def thundertunnel(rgb):
    # GPU 11 Nov (5.92): "flat pinkish-tan flesh material; white cracks read as
    # mud fissures". A mole's velvet is cool brown-grey, not skin: the warm tan
    # loses most of its saturation and a third of its value, keeping its own
    # fur-stroke detail (boosted a little so it does not go flat). The thin
    # pale cracks become blue-white storm lines and get an emission map, so
    # they read as the one elemental trait instead of dried mud.
    h, s, v = T._hsv(rgb)
    tan = _hue_w(h, 8.0, 42.0) * G._ramp(0.14, 0.26, s)
    pale = (1.0 - G._ramp(0.16, 0.30, s)) * G._ramp(0.62, 0.78, v)
    thin = np.clip(pale - _f(_f(pale, "min", 5), "max", 9), 0.0, 1.0)
    crack = G._ramp(0.35, 0.7, _f(thin, "blur", 1))
    detail = v - _f(v, "blur", 5)
    v_out = v * (1.0 - 0.34 * tan) + 0.9 * detail * tan
    s_out = s * (1.0 - 0.52 * tan)
    h_out = h + (30.0 - h) * 0.5 * tan
    out = T._rgb(np.mod(h_out, 360.0), np.clip(s_out, 0, 1), np.clip(v_out, 0, 1))
    # blend the storm blue in RGB: a hue lerp from tan to blue passes through green
    line = np.array([0.62, 0.80, 1.0]) * (0.55 + 0.45 * v)[..., None]
    out = out * (1.0 - crack[..., None]) + line * crack[..., None]
    return out, line * crack[..., None]


def fulgocobra(rgb):
    # GPU 11 Nov (5.87): "the near-black body sinks into the stage; the
    # copper-brown neck plates sit near the reserved red". Blacks lift to a
    # blue-charcoal with their scale detail, and the copper plates move to the
    # same gold as the body bands.
    h, s, v = T._hsv(rgb)
    black = (1.0 - G._ramp(0.22, 0.38, v)) * (1.0 - G._ramp(0.35, 0.55, s))
    v_out = v + (0.04 + 0.2 * v) * black
    h_out = h + (222.0 - h) * black
    s_out = s + (0.18 - s) * black
    copper = _hue_w(h, 6.0, 30.0, 6.0) * G._ramp(0.38, 0.52, s) * G._ramp(0.25, 0.4, v)
    h_out = h_out + (43.0 - h_out) * copper
    s_out = s_out * (1.0 - 0.10 * copper)
    v_out = v_out * (1.0 + 0.08 * copper)
    return T._rgb(np.mod(h_out, 360.0), np.clip(s_out, 0, 1), np.clip(v_out, 0, 1)), None


def main():
    for name in sys.argv[1:] or sorted(SOURCES):
        source = SOURCES[name]
        stem = os.path.splitext(source)[0]
        rgb = np.asarray(Image.open(os.path.join(ROOT, source)).convert("RGB")).astype(np.float64) / 255.0
        out, glow = globals()[name](rgb)
        out = np.clip(out, 0.0, 1.0)
        hh, ss, vv = T._hsv(out)
        signed = np.where(hh > 180.0, hh - 360.0, hh)
        red = ((signed >= -15.0) & (signed <= 26.0) & (ss >= 0.55) & (vv >= 0.12)).mean()
        h0, s0, v0 = T._hsv(rgb)
        sg0 = np.where(h0 > 180.0, h0 - 360.0, h0)
        red0 = ((sg0 >= -15.0) & (sg0 <= 26.0) & (s0 >= 0.55) & (v0 >= 0.12)).mean()
        Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGB").save(
            os.path.join(ROOT, stem + "_floor1.png"), optimize=True)
        if glow is not None:
            Image.fromarray((np.clip(glow, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB").save(
                os.path.join(ROOT, stem + "_floor1_glow.png"), optimize=True)
        print("%s: mean value %.3f -> %.3f, reserved-red texels %.4f -> %.4f" % (
            name, v0.mean(), vv.mean(), red0, red))


if __name__ == "__main__":
    main()
