#!/usr/bin/env python3
"""Bramblebun regen B: red/oxblood clamp of the base colour on the rigged, clipped GLB (in place copy).

    python3 assets/creatures/tetherbound/bramblebun_redesign/candidate_regen/source/grade_regen_b_base_color.py <clipped.glb> <out.glb> <report.json>

Oxblood/red is reserved for Team Tether. The raw Meshy texture of regen B (multi-image-to-3d
01a15d83-395c-70ac-8c4b-9e3e2b056704) put 8.96% of texels in the strict red band (hue <15 or >320,
sat >0.30, value >0.20): dark reddish loam and vine shadows (median value 0.22) and the pink inner
ears/nose (median value 0.72). Deterministically:
  * dark band texels (value <=0.55): hue 320-345 -> plum hue 305 (sat <=0.45); hue >345 or <15 ->
    dark brown hue 24 (sat <=0.55); value kept;
  * bright band texels (value >0.55, the pink inner ears and nose): hue kept within 345-370, sat
    capped at 0.29 so they read soft pink, not red.
Only the base-colour image changes; mesh, skin, rig, clips and every non-image bufferView stay
byte-identical (the script refuses otherwise).
"""
import hashlib, io, json, os, pathlib, sys
import numpy as np
from PIL import Image

ROOT = pathlib.Path(os.environ.get('TB_ROOT') or pathlib.Path(__file__).resolve().parents[6])
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


def strict_red(rgb):
    h, s, v = hsv(rgb)
    return ((h < 15) | (h > 320)) & (s > 0.30) & (v > 0.20)


def grade(rgb):
    h, s, v = hsv(rgb)
    band = ((h < 15) | (h > 320)) & (s > 0.30) & (v > 0.15)
    out = rgb.copy()
    plum = band & (v <= 0.55) & (h >= 320) & (h <= 345)
    brown = band & (v <= 0.55) & ~plum
    pink = band & (v > 0.55)
    out[plum] = from_hsv(np.full(int(plum.sum()), 305.0), np.minimum(s[plum], 0.45), v[plum])
    out[brown] = from_hsv(np.full(int(brown.sum()), 24.0), np.minimum(s[brown], 0.55), v[brown])
    hp = np.where(h[pink] < 180, h[pink] + 360, h[pink])
    out[pink] = from_hsv(np.clip(hp, 345, 370) % 360, np.minimum(s[pink], 0.29), v[pink])
    return out, {'plum_texels_pct': round(100 * float(plum.mean()), 3), 'dark_brown_texels_pct': round(100 * float(brown.mean()), 3),
                 'soft_pink_texels_pct': round(100 * float(pink.mean()), 3)}


def main():
    src, dst, rep_path = (pathlib.Path(p).resolve() for p in sys.argv[1:4])
    g, chunks = read_glb(src); orig, orig_chunks = read_glb(src)
    tex = g['materials'][0]['pbrMetallicRoughness']['baseColorTexture']['index']
    blob, _ = image_of(g, chunks, tex)
    rgb = np.asarray(Image.open(io.BytesIO(blob)).convert('RGB')).astype(np.float32) / 255
    graded, stats = grade(rgb)
    b = io.BytesIO(); Image.fromarray((graded * 255).round().clip(0, 255).astype(np.uint8)).save(b, 'PNG', optimize=True)
    put_image(g, chunks, tex, b.getvalue(), 'image/png', 'base_color_b')
    for key in KEPT:
        if g.get(key) != orig.get(key):
            sys.exit(f'{key} changed; refusing')
    skip = {im['bufferView'] for im in orig['images']}
    for i in range(len(orig['bufferViews'])):
        if i not in skip and view_bytes(g, chunks, i) != view_bytes(orig, orig_chunks, i):
            sys.exit(f'bufferView {i} changed; refusing')
    write_glb(dst, g, chunks)
    gu = (graded * 255).round().astype(np.uint8)
    rel = lambda p: str(p.relative_to(ROOT)) if p.is_relative_to(ROOT) else str(p)
    rep = {'input': rel(src), 'input_sha256': hashlib.sha256(src.read_bytes()).hexdigest(),
           'output': rel(dst), 'output_sha256': hashlib.sha256(dst.read_bytes()).hexdigest(), 'grade': stats,
           'red_metric_strict_hue_lt15_gt320_sat_gt030_val_gt020_pct': {'before': round(100 * float(strict_red(rgb).mean()), 4), 'after': round(100 * float(strict_red(graded).mean()), 4)},
           'policy_red_pink_rust_h_lt24': {'before': round(red_fraction((rgb * 255).round().astype(np.uint8)), 4), 'after': round(red_fraction(gu), 4)},
           'kept_unchanged': KEPT + ['normal and metallic-roughness images', 'all non-image bufferView bytes'],
           'animations': [a.get('name') for a in g.get('animations', [])]}
    rep_path.write_text(json.dumps(rep, indent=2) + '\n')
    print(json.dumps(rep, indent=1))


if __name__ == '__main__':
    main()
