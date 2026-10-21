#!/usr/bin/env python3
"""Installed-retex v2: deterministic, masked hue/value grading of the v1 base colour (no new Meshy pass).

    python3 assets/creatures/tetherbound/<species>/candidate_installed_retex/source/regrade_installed_retex_v2.py <species>

Creatures-lane judge asks (code-blind, round after v1):
  burrowback (v1 6.23): stones from blown-out light grey to matte warm grey-brown with darker cracks;
      let fur show between the plates; olive moss, not yellow.
  terrapup (v1 5.93): fur mid-brown (neither dark chocolate nor orange); cream blaze, muzzle and
      chest; stones mid-grey (albedo ~0.5) with olive moss in the cracks.
Input is the committed v1 candidate GLB (Meshy retexture maps on a byte-identical copy of the
installed rigged lod0). Only the base-colour image changes; mesh, UVs, skin, clips and every other
bufferView stay byte-identical (the script refuses otherwise). Masks, all in HSV on the 2048 atlas:
  stone   large uniform low-saturation blobs (sat <0.12, value 0.30-0.60, opened 9 px so thin
          stripe/edge gradients drop out), grown 14 px and limited to sat <0.20, value 0.12-0.88;
  moss    hue 40-80, sat >0.30 (outside stone);
  fur     hue <45 or >340, sat >0.18, value <0.80 (outside stone and moss);
  cream   (terrapup) warm low-saturation light texels (value >0.62, sat <0.30, hue <60), outside stone.
GLB helpers come from tools/art_pipeline/apply_multiview_retex.py; the red/oxblood clamp from the
v1 apply script (hue <15 or >320, sat >0.45, value >0.15 -> fur hue at the same value).
"""
import hashlib, io, json, pathlib, sys
import numpy as np
from PIL import Image, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parents[6]
sys.path.insert(0, str(ROOT / 'tools/art_pipeline'))
from apply_multiview_retex import read_glb, write_glb, view_bytes, image_of, put_image, red_fraction  # noqa: E402

KEPT = ['meshes', 'accessors', 'skins', 'nodes', 'animations', 'scenes', 'scene', 'samplers']


def hsv(rgb):
    mx = rgb.max(2); mn = rgb.min(2); d = mx - mn + 1e-6
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    return h, d / (mx + 1e-6), mx


def from_hsv(h, s, v):
    h = (h % 360) / 60.0; c = v * s; x = c * (1 - np.abs(h % 2 - 1)); m = v - c
    z = np.zeros_like(h); i = np.floor(h).astype(int) % 6
    r = np.choose(i, [c, x, z, z, x, c]); g = np.choose(i, [x, c, c, x, z, z]); b = np.choose(i, [z, z, x, c, c, x])
    return np.stack([r + m, g + m, b + m], -1)


def morph(mask, size, op):
    im = Image.fromarray((mask * 255).astype(np.uint8))
    im = im.filter(ImageFilter.MinFilter(size) if op == 'min' else ImageFilter.MaxFilter(size))
    return np.asarray(im) > 127


def soft(mask, radius):
    return np.asarray(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(radius))).astype(np.float32) / 255


def value_noise(shape, cell, seed):
    rng = np.random.default_rng(seed)
    gh, gw = shape[0] // cell + 2, shape[1] // cell + 2
    g = Image.fromarray((rng.random((gh, gw)) * 255).astype(np.uint8)).resize((gw * cell, gh * cell), Image.BICUBIC)
    return np.asarray(g, np.float32)[:shape[0], :shape[1]] / 255


def masks(rgb):
    h, s, v = hsv(rgb)
    core = (s < 0.12) & (v > 0.30) & (v < 0.60)
    core = morph(morph(core, 9, 'min'), 9, 'max')
    stone = morph(core, 29, 'max') & (s < 0.20) & (v > 0.12) & (v < 0.88)
    moss = (h > 40) & (h < 80) & (s > 0.30) & ~stone
    fur = ((h < 45) | (h > 340)) & (s > 0.18) & (v < 0.80) & ~stone & ~moss
    return h, s, v, stone, moss, fur


def grade_burrowback(rgb):
    h, s, v, stone, moss, fur = masks(rgb)
    out = rgb.copy()
    # stones: matte warm grey-brown (hue 30, sat 0.26), median value ~0.36, darker cracks (gamma 1.8)
    sv = np.clip(0.36 * (v / 0.45) ** 1.8, 0.05, 0.56)
    out[stone] = from_hsv(np.full(int(stone.sum()), 30.0), np.full(int(stone.sum()), 0.26), sv[stone])
    # moss: olive (hue 70, sat x0.80, value x0.82), not yellow
    out[moss] = from_hsv(np.full(int(moss.sum()), 70.0) + (h[moss] - 52) * 0.3, np.clip(s[moss] * 0.80, 0, 0.62), v[moss] * 0.82)
    # fur between the plates: ~45% of the moss carpet (low-frequency noise) becomes fur brown, keeping the
    # moss's own luminance detail as fur breakup; the fur's median colour is measured from the atlas
    fh = float(np.median(h[fur & (h < 45)])); fs = float(np.median(s[fur])); fv = float(np.median(v[fur]))
    n = value_noise(v.shape, 48, 7) * 0.65 + value_noise(v.shape, 12, 8) * 0.35
    furpatch = moss & (n > np.quantile(n[moss], 0.55))
    w = soft(furpatch, 2.0) * moss
    lum = v / (np.median(v[moss]) + 1e-6)
    fur_rgb = from_hsv(np.full(v.shape, fh), np.full(v.shape, fs), np.clip(fv * lum, 0.05, 0.65))
    out = out * (1 - w[..., None]) + fur_rgb * w[..., None]
    return out, {'stone_pct': round(100 * float(stone.mean()), 3), 'moss_pct': round(100 * float(moss.mean()), 3),
                 'moss_to_fur_pct': round(100 * float(furpatch.mean()), 3), 'fur_reference_hsv': [round(fh, 1), round(fs, 3), round(fv, 3)],
                 'stone_target': 'hue 30, sat 0.26, value 0.36*(v/0.45)^1.8 clipped 0.05-0.56',
                 'moss_target': 'hue 70+0.3*(h-52), sat x0.80 (max 0.62), value x0.82'}, stone


def grade_terrapup(rgb):
    h, s, v, stone, moss, fur = masks(rgb)
    out = rgb.copy()
    # fur: mid-brown hue 26 (not orange, not red), sat 0.50, value lifted so the median sits at ~0.40
    fm = fur & (v < 0.62)
    med = float(np.median(v[fm]))
    fv = np.clip(0.40 * (v / med) ** 0.85, 0.06, 0.70)
    hh = 26 + (np.where(h > 300, h - 360, h) - 18) * 0.25
    out[fm] = from_hsv(np.clip(hh[fm], 20, 32), np.clip(s[fm] * 0.95, 0.30, 0.55), fv[fm])
    # cream blaze, muzzle and chest: warm cream (hue 40, sat 0.16-0.24), keep value
    cream = (v > 0.62) & (s < 0.30) & ((h < 60) | (s < 0.06)) & ~stone
    out[cream] = from_hsv(np.full(int(cream.sum()), 40.0), np.clip(s[cream] * 0.5 + 0.13, 0.13, 0.24), np.clip(v[cream], 0.62, 0.93))
    # stones: neutral mid-grey (hue 35, sat 0.05), median value 0.50
    sm = float(np.median(v[stone]))
    sv = np.clip(0.50 * (v / sm) ** 1.3, 0.10, 0.72)
    out[stone] = from_hsv(np.full(int(stone.sum()), 35.0), np.full(int(stone.sum()), 0.05), sv[stone])
    # moss in the cracks: olive (hue 72, sat x0.85, value x0.85)
    out[moss] = from_hsv(np.full(int(moss.sum()), 72.0) + (h[moss] - 59) * 0.3, np.clip(s[moss] * 0.85, 0, 0.60), v[moss] * 0.85)
    return out, {'stone_pct': round(100 * float(stone.mean()), 3), 'moss_pct': round(100 * float(moss.mean()), 3),
                 'fur_pct': round(100 * float(fm.mean()), 3), 'cream_pct': round(100 * float(cream.mean()), 3),
                 'fur_value_median_before': round(med, 3), 'stone_value_median_before': round(sm, 3),
                 'fur_target': 'hue 20-32 (26 centre), sat 0.30-0.55, value 0.40*(v/median)^0.85',
                 'cream_target': 'hue 40, sat 0.13-0.24, value kept (0.62-0.93)',
                 'stone_target': 'hue 35, sat 0.05, value 0.50*(v/median)^1.3 clipped 0.10-0.72',
                 'moss_target': 'hue 72+0.3*(h-59), sat x0.85 (max 0.60), value x0.85'}, stone


def red_clamp(rgb):
    h, s, v = hsv(rgb)
    m = ((h < 15) | (h > 320)) & (s > 0.45) & (v > 0.15)
    rgb[m] = from_hsv(np.full(int(m.sum()), 28.0), np.minimum(s[m], 0.45), v[m])
    return int(m.sum())


def red_metric(rgb):
    h, s, v = hsv(rgb)
    return round(100 * float((((h < 15) | (h > 320)) & (s > 0.30) & (v > 0.20)).mean()), 4)


def main():
    sp = sys.argv[1]
    d = ROOT / f'assets/creatures/tetherbound/{sp}'
    src = d / f'models/creature_{sp}_installed_retex_lod0.glb'
    out_path = d / f'models/creature_{sp}_installed_retex_v2_lod0.glb'
    rep_path = d / 'candidate_installed_retex/source/regrade-report-v2.json'
    g, chunks = read_glb(src); orig, orig_chunks = read_glb(src)
    pbr = g['materials'][0]['pbrMetallicRoughness']; tex = pbr['baseColorTexture']['index']
    blob, _ = image_of(g, chunks, tex)
    rgb = np.asarray(Image.open(io.BytesIO(blob)).convert('RGB')).astype(np.float32) / 255
    graded, stats, stone = (grade_burrowback if sp == 'burrowback' else grade_terrapup)(rgb)
    graded = np.clip(graded, 0, 1)
    clamped = red_clamp(graded)
    img = Image.fromarray((graded * 255).round().astype(np.uint8))
    b = io.BytesIO(); img.save(b, 'PNG', optimize=True)
    put_image(g, chunks, tex, b.getvalue(), 'image/png', 'base_color_v2')
    for key in KEPT:
        if g.get(key) != orig.get(key):
            sys.exit(f'{key} changed; refusing')
    skip = {im['bufferView'] for im in orig['images']}
    for i in range(len(orig['bufferViews'])):
        if i not in skip and view_bytes(g, chunks, i) != view_bytes(orig, orig_chunks, i):
            sys.exit(f'bufferView {i} changed; refusing')
    write_glb(out_path, g, chunks)
    gu = (graded * 255).round().astype(np.uint8)
    rep = {'species': sp, 'method': 'deterministic masked HSV grading of the v1 Meshy retexture base colour (no new Meshy pass)',
           'input': str(src.relative_to(ROOT)), 'input_sha256': hashlib.sha256(src.read_bytes()).hexdigest(),
           'output': str(out_path.relative_to(ROOT)), 'output_sha256': hashlib.sha256(out_path.read_bytes()).hexdigest(),
           'grade': stats, 'red_clamped_texels': clamped,
           'red_metric_hue_lt15_gt320_sat_gt030_val_gt020_pct': {'before': red_metric(rgb), 'after': red_metric(graded)},
           'policy_red_pink_rust_h_lt24': {'before': round(red_fraction((rgb * 255).round().astype(np.uint8)), 4), 'after': round(red_fraction(gu), 4)},
           'stone_albedo_value_median': {'before': round(float(np.median(rgb.max(2)[stone])), 3), 'after': round(float(np.median(graded.max(2)[stone])), 3)},
           'base_color_embedding': 'PNG, lossless',
           'kept_unchanged': KEPT + ['metallic-roughness, normal and emissive images', 'all non-image bufferView bytes']}
    rep_path.write_text(json.dumps(rep, indent=2) + '\n')
    print(json.dumps(rep, indent=1))


if __name__ == '__main__':
    main()
