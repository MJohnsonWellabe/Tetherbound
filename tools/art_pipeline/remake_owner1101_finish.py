"""Owner-rule remake finish (cause lane, 1 Nov 2026): glow that reads, plates that grow.

GPU creature-stage judging of the 49 owner-rule remakes (1 Nov, three code-blind
judges): the fantasy element mostly does not read at gameplay distance. Only
Brooktail's aqua spots showed; its albedo-derived emissive map
(`arc_emission.py`) covers 2.8% of the texture at a mean lit value of 0.76,
while Terrapup's covers 0.02% (four eye dots) and Bramblebun's veins sit at a
mean of 0.52. Terrapup's stone plates "look stuck on, generated" (pale rims,
even tone); Bramblebun's bark plates read "like a plaster cast".

Two outputs, each selected only by an OFF-by-default flag in
data/config/creature_coat_flags.json, beside the live files they replace:

* glow  -> <model stem>_glow_read.png (flag remake_owner1101_glow_read). The
  existing per-species mask keeps the earlier lanes' hue choices (eyes plus the
  concept's lines, veins or spots); the core is normalised so it lights fully,
  a small halo inside the UV island widens eyes and thin veins so they survive
  distance and mip filtering, and the hue is pushed toward the element's pure
  colour so Compatibility's LDR clip keeps it (warm glows are held at hue 28+,
  clear of Team Tether red). Energy is set per species by coverage.
* plate -> <albedo stem>_plate_blend.jpg (flag remake_owner1101_plate_blend).
  Terrapup: plate rims are pulled down, the stone takes low-frequency tone
  variation between warm stone and moss, and plate edges next to fur darken to
  moss and dirt so the plates read grown into the coat. Bramblebun: the pale
  bark goes warm brown with grain variation, and moss creeps in from the veins
  and leaves. Veins, eyes and fur keep their exact pixels.

Mesh, rig, UVs, clips and the source files are untouched.

    python3 tools/art_pipeline/remake_owner1101_finish.py [glow|plate] [species ...]
"""
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import shift_reserved_red as T  # noqa: E402  (HSV helpers)

C = "assets/creatures/tetherbound/%s/candidate_owner1101/models/creature_%s_owner1101_"
CORE_NORM = 0.55  # an earlier mask value that now lights fully
WARM_HUE_FLOOR = 28.0
# Per-species overrides. `core` rebuilds the core from the albedo where the
# earlier mask caught only part of the concept's glow (Bramblebun's crevice
# veins: hue 112-155, ~3% of texels; leaves sit at 80-110 and stay unlit).
OVERRIDES = {
    "bramblebun": {"core": {"hue": (112.0, 155.0), "sat_min": 0.42, "val_min": 0.15}, "energy": 2.0},
}


def model_stem(species):
    return os.path.join(ROOT, C % (species, species))


def species_with_masks():
    rules = json.load(open(os.path.join(ROOT, "data/creatures/arc_emission.json")))["species"]
    return sorted(k[: -len("_owner1101")] for k in rules if k.endswith("_owner1101")
                  and os.path.exists(model_stem(k[: -len("_owner1101")]) + "arc_emission.png"))


def _blur(a, radius):
    """Separable Gaussian (sigma = radius px), edge-clamped."""
    r = int(np.ceil(radius * 3))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / radius) ** 2)
    k /= k.sum()
    out = np.asarray(a, np.float32)
    for axis in (0, 1):
        pad = [(0, 0), (0, 0)]
        pad[axis] = (r, r)
        p = np.pad(out, pad, mode="edge")
        acc = np.zeros_like(out)
        n = out.shape[axis]
        for i, w in enumerate(k):
            acc += w * (p[i:i + n] if axis == 0 else p[:, i:i + n])
        out = acc
    return out


def _ramp(lo, hi, x):
    u = np.clip((x - lo) / (hi - lo), 0.0, 1.0)
    return u * u * (3.0 - 2.0 * u)


def energy_for(coverage):
    """Emission energy by lit coverage (%): eye-only masks need the most push."""
    if coverage < 0.15:
        return 2.6
    if coverage < 2.0:
        return 2.0
    return 1.4


def glow(species):
    stem = model_stem(species)
    em = np.asarray(Image.open(stem + "arc_emission.png").convert("RGB")).astype(np.float64) / 255.0
    v = em.max(-1)
    core = np.clip(v / CORE_NORM, 0.0, 1.0)
    colour = em / np.maximum(v, 1e-6)[..., None]
    override = OVERRIDES.get(species, {}).get("core")
    if override:
        albedo = np.asarray(Image.open(stem + "Image_0.jpg").convert("RGB")).astype(np.float64) / 255.0
        h, s, val = T._hsv(albedo)
        lo, hi = override["hue"]
        extra = _ramp(lo - 4, lo + 4, h) * (1 - _ramp(hi - 4, hi + 4, h)) \
            * _ramp(override["sat_min"] - 0.06, override["sat_min"] + 0.06, s) \
            * _ramp(override["val_min"] - 0.05, override["val_min"] + 0.05, val)
        lit = albedo / np.maximum(albedo.max(-1), 1e-6)[..., None]
        colour = np.where((extra > core)[..., None], lit, colour)
        core = np.maximum(core, extra)
    coverage = (core > 0.1).mean() * 100.0
    # Broad masks (2%+: Brooktail's spots, which already read) get no halo:
    # widening them would turn markings into a body glow.
    radius = 7.0 if coverage < 0.15 else (4.0 if coverage < 1.0 else 2.5)
    halo = np.clip(_blur(core, radius) * 3.0, 0.0, 0.5) if coverage < 2.0 else np.zeros_like(core)
    tint = np.stack([_blur(colour[..., c] * core, radius) for c in range(3)], -1)
    tint = tint / np.maximum(tint.max(-1), 1e-6)[..., None]
    colour = np.where((core > 0.05)[..., None], colour, tint)
    mask = np.maximum(core, halo)
    # Purer hue so the LDR clip at energy > 1 keeps the element colour; warm
    # glows keep their saturation and are held clear of Team Tether red.
    h, s, val = T._hsv(np.clip(colour, 0, 1))
    signed = np.where(h > 180.0, h - 360.0, h)
    warm = (signed > -60.0) & (signed < 60.0)
    h = np.where(warm, np.maximum(np.where(signed < 0, WARM_HUE_FLOOR, h), WARM_HUE_FLOOR), h)
    s = np.where(warm, s, np.clip(s * 1.25, 0, 1))
    colour = T._rgb(h, s, np.ones_like(val))
    out = np.clip(colour * mask[..., None], 0, 1)
    target = stem + "glow_read.png"
    Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGB").save(target, optimize=True)
    final_cov = (mask > 0.1).mean() * 100.0
    return {"species": species, "coverage_before": round((v > 0.1).mean() * 100, 3),
            "coverage_after": round(final_cov, 3), "energy": OVERRIDES.get(species, {}).get("energy", energy_for((v > 0.1).mean() * 100 if not override else coverage)),
            "target": os.path.relpath(target, ROOT)}


def _noise(shape, cell, seed):
    rng = np.random.default_rng(seed)
    out = np.zeros(shape)
    for octave, weight in ((cell, 0.6), (cell / 2, 0.3), (cell / 4, 0.1)):
        gh, gw = int(shape[0] / octave) + 2, int(shape[1] / octave) + 2
        grid = Image.fromarray(rng.random((gh, gw)).astype(np.float32), "F")
        up = np.asarray(grid.resize((int(gw * octave), int(gh * octave)), Image.BICUBIC))
        out += weight * up[: shape[0], : shape[1]]
    return np.clip(out, 0, 1)


def _hsv_mix(h, s, v, th, ts, tv, w):
    """Blend toward a target hue/sat/value, hue taken the short way round."""
    dh = ((th - h + 180.0) % 360.0) - 180.0
    return (h + dh * w) % 360.0, s + (ts - s) * w, v + (tv - v) * w


def plate_terrapup(rgb):
    h, s, v = T._hsv(rgb)
    plate = _ramp(45, 55, h) * (1 - _ramp(125, 135, h)) * (1 - _ramp(0.32, 0.40, s)) * _ramp(0.28, 0.36, v)
    fur = np.clip(_ramp(0.28, 0.20, v) + _ramp(0.35, 0.45, s) * _ramp(5, 12, h) * (1 - _ramp(38, 45, h)), 0, 1)
    edge = np.clip(_blur(fur, 10.0) * 2.2, 0, 1) * plate
    local = _blur(v, 6.0)
    crevice = _ramp(0.02, 0.08, local - v) * plate
    n = _noise(v.shape, 96.0, 1101)
    # 1. pale bevel rims flattened toward the plate's own tone (the tiled look),
    # 2. tone between warm stone and moss, varying across the body, 3. moss in
    # the crevices between tiles, 4. plate edges into moss and dirt where they
    # meet the coat.
    v2 = v - np.clip(v - 0.42, 0, None) * 0.85 * plate
    stone_h = 34.0 + 46.0 * n
    stone_s = 0.20 + 0.22 * n
    h2, s2, v2 = _hsv_mix(h, s, v2, stone_h, stone_s, v2 * (0.78 + 0.30 * n), 0.8 * plate)
    h2, s2, v2 = _hsv_mix(h2, s2, v2, 72.0, 0.50, 0.22 + 0.05 * n, 0.75 * crevice)
    h2, s2, v2 = _hsv_mix(h2, s2, v2, 50.0, 0.42, 0.17 + 0.05 * n, 0.8 * edge)
    return T._rgb(h2, np.clip(s2, 0, 1), np.clip(v2, 0, 1)), plate


def plate_bramblebun(rgb):
    h, s, v = T._hsv(rgb)
    # Bark plates carry carved grain (local value s.d. ~0.08); the soft pale
    # belly and inner-ear fur (~0.02) is left alone.
    grain_sd = np.sqrt(np.clip(_blur(v * v, 3.0) - _blur(v, 3.0) ** 2, 0, None))
    pale = (1 - _ramp(0.18, 0.26, s)) * _ramp(0.30, 0.40, v)
    # Region vote: a plate is grainy across its area, so its smooth highlights
    # join it, and a fur patch's high-contrast border does not.
    region = _blur(_ramp(0.035, 0.055, grain_sd) * pale, 18.0) / np.maximum(_blur(pale, 18.0), 1e-3)
    bark = pale * _ramp(0.30, 0.45, region)
    green = _ramp(0.35, 0.45, s) * _ramp(75, 85, h) * (1 - _ramp(160, 170, h))
    moss = np.clip(_blur(green, 8.0) * 2.0, 0, 1) * bark
    n = _noise(v.shape, 48.0, 1102)
    grain = _noise(v.shape, 10.0, 1103)
    # Warm brown bark (hue 28-36, saturation under 0.5: clear of Team Tether
    # red), the carved grain kept as value contrast.
    bark_h = 28.0 + 8.0 * n
    bark_s = 0.36 + 0.12 * n
    bark_v = (0.12 + 0.40 * v) * (0.88 + 0.24 * grain)
    h2, s2, v2 = _hsv_mix(h, s, v, bark_h, bark_s, bark_v, 0.9 * bark)
    h2, s2, v2 = _hsv_mix(h2, s2, v2, 78.0, 0.48, 0.26 + 0.08 * n, 0.6 * moss)
    return T._rgb(h2, np.clip(s2, 0, 1), np.clip(v2, 0, 1)), bark


PLATES = {"terrapup": plate_terrapup, "bramblebun": plate_bramblebun}


def plate(species):
    stem = model_stem(species)
    rgb = np.asarray(Image.open(stem + "Image_0.jpg").convert("RGB")).astype(np.float64) / 255.0
    out, w = PLATES[species](rgb)
    h, s, v = T._hsv(out)
    signed = np.where(h > 180.0, h - 360.0, h)
    red = (signed >= -15.0) & (signed <= 26.0) & (s >= 0.55) & (v >= 0.12)
    before = T._hsv(rgb)
    sb = np.where(before[0] > 180.0, before[0] - 360.0, before[0])
    red_before = (sb >= -15.0) & (sb <= 26.0) & (before[1] >= 0.55) & (before[2] >= 0.12)
    target = stem + "Image_0_plate_blend.jpg"
    Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGB").save(target, quality=90)
    return {"species": species, "regraded_pct": round((w > 0.5).mean() * 100, 1),
            "reserved_red_pct": [round(red_before.mean() * 100, 3), round(red.mean() * 100, 3)],
            "target": os.path.relpath(target, ROOT)}


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "glow"
    names = sys.argv[2:]
    if mode == "glow":
        rows = [glow(s) for s in (names or species_with_masks())]
    else:
        rows = [plate(s) for s in (names or sorted(PLATES))]
    print(json.dumps(rows, indent=1))


if __name__ == "__main__":
    main()
