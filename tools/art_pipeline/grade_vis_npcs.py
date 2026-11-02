"""Face and body readability grade for four installed NPC bodies (VIS-CREATURES, 1 Nov 2026).

F36 (0) #26/#28/#29/#30 (wandering trainer, young trainer, trader, innkeeper)
sit at 5.7-6.0 on GPU frames; the NPC face round (ralph/reports/CREATURES/
close-1020/f36-0-ledger.md) put the ceiling in the baked albedo: "low-resolution
eyes and mouths, blotches, chalky skin", and the bodies' cloth is dark (mean
value 0.20-0.33). Identity is kept: same atlas, same hues, same rig. The grade:
- skin (warm low-saturation texels) loses its chalk: highlights come down a
  little and saturation rises, blotches are evened by a light median blend;
- local value contrast and a fine unsharp mask crisp eyes, brows and mouths;
- the darkest cloth lifts a step so the silhouette separates from the ground.
Each graded file sits beside its source as <stem>_vis1.png and is selected only
by the flag npc_vis_body_<character> in data/config/character_body_flags.json
(OFF by default). No red is introduced (Team Tether's reserve).

    python3 tools/art_pipeline/grade_vis_npcs.py [character ...]
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import grade_coat_value as G  # noqa: E402
sys.path.insert(0, os.path.join(ROOT, "tools"))
import shift_reserved_red as T  # noqa: E402

CHARACTERS = ("wandering_trainer", "young_trainer", "trader", "innkeeper")
CATCHLIGHTS = True


def source(name):
    return "assets/characters/%s/%s_lod0_texture_0.png" % (name, name)


def target(src):
    return os.path.splitext(src)[0] + "_vis1.png"


def _blur(x, radius):
    img = Image.fromarray(np.clip(x * 255.0, 0, 255).astype(np.uint8), "L")
    return np.asarray(img.filter(ImageFilter.GaussianBlur(radius))).astype(np.float64) / 255.0


def grade(rgb):
    h, s, v = T._hsv(rgb)
    # Skin: warm hue, low-to-mid saturation, mid-to-high value.
    skin = G._ramp(8.0, 16.0, h) * (1.0 - G._ramp(34.0, 44.0, h)) \
        * G._ramp(0.12, 0.20, s) * (1.0 - G._ramp(0.42, 0.52, s)) * G._ramp(0.40, 0.55, v)
    smooth = np.asarray(Image.fromarray((rgb * 255).astype(np.uint8), "RGB").filter(
        ImageFilter.MedianFilter(5))).astype(np.float64) / 255.0
    out = rgb + (smooth - rgb) * (0.5 * skin)[..., None]
    h, s, v = T._hsv(np.clip(out, 0, 1))
    s = s + (np.minimum(s * 1.22, 0.52) - s) * skin
    v = v - 0.07 * skin * G._ramp(0.70, 0.90, v)
    # Features: local value contrast plus a fine unsharp on value.
    v = v + 0.35 * (v - _blur(v, 10))
    v = v + 0.6 * (v - _blur(v, 1.6))
    # Dark cloth: one gentle step up, darkest texels (eyes, seams) kept.
    lift = (1.0 - G._ramp(0.18, 0.32, v)) * G._ramp(0.03, 0.06, v) * (1.0 - skin)
    # Never lift saturated red-hue cloth into view: red is Team Tether's.
    signed = np.where(h > 180.0, h - 360.0, h)
    lift *= 1.0 - (G._ramp(-22.0, -15.0, signed) * (1.0 - G._ramp(26.0, 33.0, signed)) * G._ramp(0.45, 0.55, s))
    v = v + ((v * 1.25 + 0.02) - v) * lift
    return np.clip(T._rgb(h, np.clip(s, 0, 1), np.clip(v, 0, 1)), 0, 1)


def catchlights(rgb, glb):
    """Eye catchlights (GPU anchors, 1 Nov: 'tiny dot eyes and no catchlight').
    Pupils are the few most locally-dark texels in the forward-facing head of
    the character's own glb (anatomy rasterised from its UVs, rest pose); a
    small near-white highlight is painted on the upper part of each."""
    import grade_vis_traits as VT
    size = rgb.shape[0]
    anatomy = VT.anatomy_for(glb, size)
    h, s, v = T._hsv(rgb)
    unit, nrm = anatomy["unit"], anatomy["nrm"]
    face = anatomy["valid"] & (unit[..., 1] > 0.86) & (np.abs(nrm[..., 2]) > 0.55)
    if face.sum() < 50:
        return rgb, 0
    k = max(1, size // 1024)
    local = _blur(v, 4 * k)
    score = np.where(face & (v < 0.32), local - v, -1.0)
    budget = max(12, int(size * size * 0.00002))
    flat = score.ravel()
    if (flat > 0.1).sum() == 0:
        return rgb, 0
    cut = max(0.1, float(np.partition(flat, -budget)[-budget]))
    pupils = (score >= cut).astype(np.float64)
    # The upper-right quarter of each pupil: the pupil mask shifted by one step
    # (texture rows go down the face on these atlases) and kept inside it.
    shifted = np.roll(np.roll(pupils, -k, axis=0), k, axis=1)
    glint = _blur(pupils * shifted, 0.6 * k)
    out = rgb + (np.array([0.96, 0.95, 0.92]) - rgb) * np.clip(glint * 1.4, 0, 1)[..., None]
    return np.clip(out, 0, 1), int(pupils.sum())


GLBS = {
    "kael": "kael", "sera": "sera", "lyra": "lyra", "villager_female": "villager_female", "villager_male": "villager_male",
    "warden": "warden", "grunt": "grunt", "grunt_a": "grunt_a", "grunt_b": "grunt_b", "grunt_c": "grunt_c",
    "officer_a": "officer_a", "officer_b": "officer_b", "captain_a": "captain_a", "captain_b": "captain_b",
    "innkeeper": "innkeeper", "inn_helper": "inn_helper", "trader": "trader", "creature_caretaker": "creature_caretaker",
    "farmer": "farmer", "local_historian": "local_historian", "young_trainer": "young_trainer",
    "rival_trainer": "rival_trainer", "field_researcher": "field_researcher", "wandering_trainer": "wandering_trainer",
    "lost_traveler": "lost_traveler", "alpha_tracker": "alpha_tracker", "courier": "courier",
    "former_tether_member": "former_tether_member",
}


def main():
    names = [a for a in sys.argv[1:] if not a.startswith("--")]
    for name in names or CHARACTERS:
        src = source(name)
        image = Image.open(os.path.join(ROOT, src))
        alpha = image.getchannel("A") if image.mode == "RGBA" else None
        rgb = np.asarray(image.convert("RGB")).astype(np.float64) / 255.0
        out = grade(rgb)
        glb = "assets/characters/%s/%s_lod0.glb" % (name, name)
        pupils = 0
        if "--catchlights" in sys.argv or CATCHLIGHTS:
            out, pupils = catchlights(out, glb)
        h0, s0, v0 = T._hsv(rgb)
        hh, ss, vv = T._hsv(out)
        sg = lambda h: np.where(h > 180.0, h - 360.0, h)  # noqa: E731
        red = lambda h, s, v: ((sg(h) >= -15.0) & (sg(h) <= 26.0) & (s >= 0.55) & (v >= 0.12)).mean()  # noqa: E731
        graded = Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGB")
        if alpha is not None:
            graded.putalpha(alpha)
        graded.save(os.path.join(ROOT, target(src)), optimize=True)
        print("%s: mean value %.3f -> %.3f, reserved-red texels %.4f -> %.4f, pupils %d -> %s" % (
            name, v0.mean(), vv.mean(), red(h0, s0, v0), red(hh, ss, vv), pupils, target(src)))


if __name__ == "__main__":
    main()
