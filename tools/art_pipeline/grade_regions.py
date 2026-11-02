#!/usr/bin/env python3
"""Regional coat grade for an owner remake (Creatures-ralph, 2 Nov 2026).

Meshy remake atlases mix colours at texel scale, so a hue/value rule keeps the
"mottled collage" the batch-4 judges named, and one body-wide value hides the
face ("one mid-tone with no visible eyes", "dark mass whose face does not
read"). This grades by 3D body region instead: each texel's model-space
position and normal (anatomy map, tools/creature_anatomy_maps.py) pick a target
colour from the species' regions in data/creatures/remake_grades.json (soft
masks, later regions blend over earlier ones), and the texel keeps its own
local value ratio for fine fur, feather or scale detail. Element pixels (glowing
eyes, lines) matched by `keep` keep their exact values. Writes
<glb stem>_Image_0_<suffix>.jpg beside the source; a coat flag in
data/config/creature_coat_flags.json selects it.

Region `where` keys: x/y/z_min/max (0..1 box units), up_min/up_max (normal Y),
fwd_min/fwd_max (normal Z), lateral_min (|x-0.5|*2), radial_min/max.

    python3 tools/art_pipeline/grade_regions.py duskhush [species ...]
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from creature_anatomy_maps import build  # noqa: E402
from repaint_creature_textures import rgb_to_hsv  # noqa: E402

SPEC = os.path.join(ROOT, "data", "creatures", "remake_grades.json")


def smooth(a, b, x):
    t = np.clip((x - a) / max(b - a, 1e-9), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def region_mask(where, anatomy, soft):
    unit, nrm, radial = anatomy["unit"], anatomy["nrm"], anatomy["radial"]
    channels = {"x": unit[..., 0], "y": unit[..., 1], "z": unit[..., 2], "up": nrm[..., 1],
                "fwd": nrm[..., 2], "radial": radial, "lateral": np.abs(unit[..., 0] - 0.5) * 2.0}
    mask = np.ones(unit.shape[:2])
    for key, value in where.items():
        name, side = key.rsplit("_", 1)
        ch = channels[name]
        t = float(value)
        if side == "min":
            mask *= smooth(t - soft, t + soft, ch)
        else:
            mask *= 1.0 - smooth(t - soft, t + soft, ch)
    return mask


def hsv_to_rgb(h, s, v):
    h = (h % 360.0) / 60.0
    i = np.floor(h).astype(int) % 6
    f = h - np.floor(h)
    p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    return np.stack([np.choose(i, [v, q, p, p, t, v]), np.choose(i, [t, v, v, q, p, p]),
                     np.choose(i, [p, p, t, v, v, q])], -1)


def hue_in(h, lo, hi):
    return (h >= lo) & (h <= hi) if lo <= hi else (h >= lo) | (h <= hi)


def grade(name, entry):
    folder = entry["folder"]
    models = os.path.join(ROOT, "assets", "creatures", "tetherbound", folder, "models")
    stem = sorted(f for f in os.listdir(models) if f.endswith(".glb"))[0][:-4]
    img = Image.open(os.path.join(models, stem + "_Image_0.jpg")).convert("RGB")
    size = img.width
    anatomy, _ = build(folder, size=size)
    if int(anatomy["size"]) != size:
        anatomy, _ = build(folder, size=size, force=True)
    valid = anatomy["valid"]
    rgb = np.asarray(img).astype(np.float64) / 255.0
    h, s, v = rgb_to_hsv(rgb)
    # Hue blends on a circle: accumulate a unit vector.
    def vec(hue):
        r = np.radians(hue)
        return np.cos(r), np.sin(r)
    if "base" not in entry:
        return _glow(name, entry, models, stem, size, anatomy, valid)
    bh, bs, bv = entry["base"]
    cx, sx = [np.full(h.shape, c) for c in vec(bh)]
    ts, tv = np.full(h.shape, float(bs)), np.full(h.shape, float(bv))
    soft = float(entry.get("softness", 0.06))
    for region in entry.get("regions", []):
        m = region_mask(region.get("where", {}), anatomy, float(region.get("softness", soft)))
        m *= float(region.get("mix", 1.0))
        rh, rs, rv = region["hsv"]
        c, si = vec(rh)
        cx, sx = cx * (1 - m) + c * m, sx * (1 - m) + si * m
        ts, tv = ts * (1 - m) + rs * m, tv * (1 - m) + rv * m
    th = np.degrees(np.arctan2(sx, cx)) % 360.0
    blur = float(entry.get("detail_blur_px", 6))
    local = np.asarray(Image.fromarray((v * 255).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(blur))).astype(np.float64) / 255.0
    lo, hi = entry.get("detail_clip", [0.55, 1.6])
    detail = np.clip(v / np.maximum(local, 0.04), lo, hi) ** float(entry.get("detail_strength", 1.0))
    # Optionally keep part of the source's own hue/sat variation (natural mottling).
    keep_sat = float(entry.get("keep_source_sat", 0.0))
    ts = ts * (1 - keep_sat) + s * keep_sat
    out = hsv_to_rgb(th, np.clip(ts, 0, 1), np.clip(tv * detail, 0, 1))
    # mix_source blends part of the source colour back (its natural hue and
    # saturation variation), at the graded value.
    mix = float(entry.get("mix_source", 0.0))
    if mix > 0.0:
        src_scaled = rgb * (np.clip(tv * detail, 0, 1) / np.maximum(v, 0.02))[..., None]
        out = out * (1 - mix) + np.clip(src_scaled, 0, 1) * mix
    keep = ~valid
    for k in entry.get("keep", []):
        m = np.ones(h.shape, dtype=bool)
        if "hue" in k:
            m &= hue_in(h, *k["hue"])
        for key, ch in (("sat", s), ("val", v)):
            if key + "_min" in k:
                m &= ch >= float(k[key + "_min"])
            if key + "_max" in k:
                m &= ch <= float(k[key + "_max"])
        if "where" in k:
            m &= region_mask(k["where"], anatomy, 0.02) > 0.5
        keep |= m
    out[keep] = rgb[keep]
    suffix = entry.get("suffix", "graded")
    dst = os.path.join(models, "%s_Image_0_%s.jpg" % (stem, suffix))
    Image.fromarray((out * 255).round().astype(np.uint8)).save(dst, quality=90)
    print("%s: -> %s (kept %.1f%% element pixels)" % (name, os.path.relpath(dst, ROOT), 100 * keep[valid].mean()))
    _glow(name, entry, models, stem, size, anatomy, valid)


def _glow(name, entry, models, stem, size, anatomy, valid):
    """Optional: an emission map limited to one body region (eyes only, say),
    cut from an existing glow mask: {"from": "<suffix of stem_*.png>",
    "where": {...}, "suffix": "..."}. An entry with no `base` writes only this."""
    glow = entry.get("glow")
    if glow:
        src = Image.open(os.path.join(models, "%s_%s.png" % (stem, glow["from"]))).convert("RGB")
        if src.width != size:
            src = src.resize((size, size), Image.LANCZOS)
        g = np.asarray(src).astype(np.float64)
        g *= region_mask(glow["where"], anatomy, float(glow.get("softness", 0.02)))[..., None]
        gdst = os.path.join(models, "%s_%s.png" % (stem, glow["suffix"]))
        Image.fromarray(g.round().astype(np.uint8)).save(gdst, optimize=True)
        print("%s: glow -> %s (%.2f%% lit)" % (name, os.path.relpath(gdst, ROOT), 100 * (g.max(-1) > 20)[valid].mean()))


def main():
    spec = json.load(open(SPEC))
    for name in sys.argv[1:] or [k for k in spec if not k.startswith("_")]:
        grade(name, spec[name])


if __name__ == "__main__":
    main()
