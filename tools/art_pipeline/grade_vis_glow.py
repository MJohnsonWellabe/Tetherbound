"""Glowing eyes plus elemental vein markings (VIS-CREATURES group 4, 1 Nov 2026).

Owner creature rule (settled, via the coordinator, 1 Nov): a believable adult
animal plus ONE elemental trait -- glowing eyes plus glowing lines, veins or
markings in the creature's element (optionally partial natural plates). Never
mascot proportions, full-body overgrowth or big floating effects. Emission eyes
and vein/marking masks are the highest-value lift for species without a Meshy
remake.

Writes one glow map per species, <live albedo stem>_glow2.png, used as the
emission texture by creatures_vis_glow_<species> in creature_coat_flags.json
(OFF). The flag's albedo is the species' group-3 trait texture (or its group-1
grade, or the live albedo), so this flag supersedes those when on.

- Eyes: small locally-dark pinpoints (pupils) inside a per-species head zone,
  grown into an iris ring and lit in the element colour.
- Veins: a ridged model-space noise network (continuous across UV seams) inside
  an anatomy region, thin and broken up, lit in the element colour.

    python3 tools/art_pipeline/grade_vis_glow.py [species ...]
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "tools"))
import grade_vis_traits as T  # noqa: E402
import creature_overlays as O  # noqa: E402
from repaint_creature_textures import rgb_to_hsv  # noqa: E402

C = "assets/creatures/tetherbound/"
AMBER, CYAN, GOLD, VOLT_BLUE, SKY = "#ffb24a", "#6fe8ff", "#ffe07a", "#7fb8ff", "#cfeeff"

SPECIES = {
    "mudsnout": {"src": "mudsnout", "eyes": {"where": {"z_min": 0.6, "y_min": 0.5}, "color": AMBER},
                 "veins": {"where": {"y_min": 0.6, "up_min": 0.2, "z_max": 0.7}, "color": AMBER}},
    "mirejaw": {"src": "mirejaw", "eyes": {"where": {"z_min": 0.75, "y_min": 0.45}, "color": CYAN},
                "veins": {"where": {"y_min": 0.5, "up_min": 0.3, "z_max": 0.8}, "color": CYAN}},
    "cannonback": {"src": "cannonback", "eyes": {"where": {"z_min": 0.75, "y_min": 0.3}, "color": CYAN},
                   "veins": {"where": {"y_min": 0.6, "up_min": 0.35}, "color": CYAN}},
    "fulgocobra": {"src": "fulgocobra", "eyes": {"where": {"z_min": 0.75, "y_min": 0.7}, "color": GOLD},
                   "keep_glow": True},
    "riverdrake": {"src": "riverdrake", "eyes": {"where": {"z_min": 0.8, "y_min": 0.6}, "color": CYAN},
                   "veins": {"where": {"y_min": 0.45, "up_min": 0.25, "z_max": 0.85}, "color": CYAN},
                   "keep_glow": True},
    "solmane": {"src": "solmane", "eyes": {"where": {"z_min": 0.8, "y_min": 0.5}, "color": SKY},
                "veins": {"where": {"y_min": 0.75, "radial_min": 0.45}, "color": SKY}},
    "voltarach": {"glb": C + "voltarach/candidate/models/creature_voltarach_native.glb",
                  "albedo": C + "voltarach/candidate/models/creature_voltarach_native_Image_0.jpg",
                  "eyes": {"where": {}, "match_blue": True, "color": VOLT_BLUE}},
}


def _filter(mask, filt):
    img = Image.fromarray((np.clip(mask, 0, 1) * 255).astype(np.uint8), "L").filter(filt)
    return np.asarray(img).astype(np.float64) / 255.0


def _blur(mask, r):
    return _filter(mask, ImageFilter.GaussianBlur(r))


def eye_mask(rgb, anatomy, spec, size):
    h, s, v = rgb_to_hsv(rgb)
    region = O.anatomy_mask(spec.get("where", {}), anatomy, 0.04) > 0.5
    k = max(1, size // 512)
    if spec.get("match_blue"):
        # Voltarach's board eyes are painted saturated blue: light those.
        hue = (h >= 205) & (h <= 250) & (s >= 0.5) & (v >= 0.25)
        pupils = (hue & anatomy["valid"]).astype(np.float64)
        return _blur(_filter(pupils, ImageFilter.MaxFilter(2 * k + 1)), k)
    local = _blur(v, 6 * k)
    dark = ((v < local - 0.16) & (v < 0.28) & region & anatomy["valid"]).astype(np.float64)
    # Keep pinpoints only: anything that survives an erode-then-grow is a seam
    # or a patch, not a pupil.
    big = _filter(_filter(dark, ImageFilter.MinFilter(4 * k + 1)), ImageFilter.MaxFilter(6 * k + 1))
    pupils = np.clip(dark - big, 0, 1)
    ring = _filter(pupils, ImageFilter.MaxFilter(4 * k + 1))
    return _blur(np.clip(ring - 0.6 * pupils, 0, 1), k)


def vein_mask(anatomy, spec, name):
    region = O.anatomy_mask(spec.get("where", {}), anatomy, 0.08)
    seed = O.zlib.crc32(("veins|" + name).encode("utf-8"))
    n = O._value_noise_3d(anatomy["unit"], float(spec.get("grain", 9.0)), seed, 3)
    med = float(np.median(n[anatomy["valid"]]))
    ridge = 1.0 - O._smoothstep(0.0, float(spec.get("width", 0.022)), np.abs(n - med))
    breakup = O._value_noise_3d(anatomy["unit"], 3.0, seed + 7, 2)
    cut = float(np.quantile(breakup[anatomy["valid"]], 1.0 - float(spec.get("coverage", 0.6))))
    return ridge * region * O._smoothstep(cut - 0.05, cut + 0.05, breakup) * anatomy["valid"]


def paths(name, spec):
    if "src" in spec:
        base = T.SPECIES[spec["src"]]
        return base["glb"], base["albedo"]
    return spec["glb"], spec["albedo"]


def albedo_for(live):
    stem = os.path.splitext(live)[0]
    for candidate in (stem + "_trait1.png", stem + "_vis1.png", live):
        if os.path.exists(os.path.join(ROOT, candidate)):
            return candidate
    return live


def main():
    for name in sys.argv[1:] or sorted(SPECIES):
        spec = SPECIES[name]
        glb, live = paths(name, spec)
        base = albedo_for(live)
        image = Image.open(os.path.join(ROOT, base)).convert("RGB")
        size = image.size[0]
        rgb = np.asarray(image).astype(np.float64) / 255.0
        anatomy = T.anatomy_for(glb, size)
        canvas = np.zeros((size, size, 3))
        notes = []
        if "eyes" in spec:
            eyes = eye_mask(rgb, anatomy, spec["eyes"], size)
            canvas = np.maximum(canvas, eyes[..., None] * O._hex_to_rgb(spec["eyes"]["color"])[None, None, :])
            notes.append("eyes %.3f%%" % (100.0 * float((eyes > 0.3).mean())))
        if "veins" in spec:
            veins = vein_mask(anatomy, spec["veins"], name) * float(spec["veins"].get("intensity", 0.9))
            canvas = np.maximum(canvas, veins[..., None] * O._hex_to_rgb(spec["veins"]["color"])[None, None, :])
            notes.append("veins %.2f%%" % (100.0 * float((veins > 0.3).mean())))
        stem = os.path.splitext(live)[0]
        if spec.get("keep_glow") and os.path.exists(os.path.join(ROOT, stem + "_trait1_glow.png")):
            prior = np.asarray(Image.open(os.path.join(ROOT, stem + "_trait1_glow.png")).convert("RGB").resize((size, size))) / 255.0
            canvas = np.maximum(canvas, prior)
            notes.append("kept the group-3 glow")
        Image.fromarray((np.clip(canvas, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB").save(
            os.path.join(ROOT, stem + "_glow2.png"), optimize=True)
        print("%s: albedo %s; %s" % (name, os.path.basename(base), ", ".join(notes)))


if __name__ == "__main__":
    main()
