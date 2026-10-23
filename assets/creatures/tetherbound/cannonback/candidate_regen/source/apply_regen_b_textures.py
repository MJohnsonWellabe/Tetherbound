#!/usr/bin/env python3
"""Water Cannonback regen B: Meshy retexture maps (moss seams, blue limb speckle) on a copy of rigged regen 1.

    python3 assets/creatures/tetherbound/cannonback/candidate_regen/source/apply_regen_b_textures.py <retexture.glb>

Judges (art pass 3, fight camera, bar 6.7) scored regen 1 6.40, the best Cannonback, and asked for:
cannons ~15% smaller and seated deeper, moss patches in the shell seams, blue speckle on the cream
limbs and a saddle notch between the cannons. Regen 1 is ONE connected manifold mesh (14,005 vertices,
one island before and after position welding), so the cannons are not separable mesh islands and the
cannon/notch asks are not attempted here; only the texture asks are.
Meshy retexture (enable_original_uv, style image from regen 1 renders) of creature_cannonback_regen.glb
kept its UVs but is unskinned and unanimated. This copies the rigged regen GLB byte-for-byte except the
material images (base colour, metallic-roughness, normal from the retexture), then deterministically:
  * moss texels (hue 62-115, sat >0.30, value >0.12) are pulled from lime toward olive (hue 72 +0.3*(h-85),
    sat x0.85, value x0.88);
  * a red clamp recolours any saturated red/oxblood texel (hue <15 or >320, sat >0.45, value >0.15) to
    the bronze hue 34 at the same value (A2 method, commit 1fb0d6179).
Mesh, skin, rig, clips and every non-image bufferView stay byte-identical; the script refuses otherwise.
"""
import hashlib, io, json, os, pathlib, sys
import numpy as np
from PIL import Image

ROOT = pathlib.Path(os.environ.get('TB_ROOT') or pathlib.Path(__file__).resolve().parents[6])
sys.path.insert(0, str(ROOT / 'tools/art_pipeline'))
from apply_multiview_retex import read_glb, write_glb, view_bytes, image_of, put_image, red_fraction  # noqa: E402

DIR = ROOT / 'assets/creatures/tetherbound/cannonback/candidate_regen'
BASE = DIR / 'models/creature_cannonback_regen.glb'
OUT = pathlib.Path(os.environ.get('CB_OUT') or DIR / 'models/creature_cannonback_regen_b.glb')
REPORT = pathlib.Path(os.environ.get('CB_REPORT') or DIR / 'source/apply-report-B.json')
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
    out = rgb.copy()
    moss = (h > 62) & (h < 115) & (s > 0.30) & (v > 0.12)
    out[moss] = from_hsv(np.clip(72 + (h[moss] - 85) * 0.3, 62, 80), np.clip(s[moss] * 0.85, 0, 0.70), v[moss] * 0.88)
    h2, s2, v2 = hsv(out)
    rc = ((h2 < 15) | (h2 > 320)) & (s2 > 0.45) & (v2 > 0.15)
    out[rc] = from_hsv(np.full(int(rc.sum()), 34.0), np.minimum(s2[rc], 0.50), v2[rc])
    speck = (h > 195) & (h < 235) & (s > 0.35)
    return out, {'moss_texels_pct': round(100 * float(moss.mean()), 3), 'moss_target': 'hue 72+0.3*(h-85) clipped 62-80, sat x0.85, value x0.88',
                 'blue_texels_pct': round(100 * float(speck.mean()), 3), 'red_clamped_texels': int(rc.sum())}


def png(img):
    b = io.BytesIO(); img.save(b, 'PNG', optimize=True); return b.getvalue()


def uvs(gl, ch):
    out = set()
    for m in gl['meshes']:
        for p in m['primitives']:
            a = gl['accessors'][p['attributes']['TEXCOORD_0']]
            data = view_bytes(gl, ch, a['bufferView'])
            st = gl['bufferViews'][a['bufferView']].get('byteStride', 8)
            arr = np.frombuffer(data, np.uint8)
            rows = np.stack([np.frombuffer(data[a.get('byteOffset', 0) + i * st:][:8], np.float32) for i in range(a['count'])])
            out |= set(map(tuple, np.round(rows.astype(float), 4)))
    return out


def main():
    retex_path = pathlib.Path(sys.argv[1]).resolve()
    g, chunks = read_glb(BASE); orig, orig_chunks = read_glb(BASE)
    r, rchunks = read_glb(retex_path)
    ua, ub = uvs(g, chunks), uvs(r, rchunks)
    if ua != ub:
        sys.exit('UV sets differ (%d vs %d, %d shared); refusing' % (len(ua), len(ub), len(ua & ub)))
    src = r['materials'][0]; spbr = src['pbrMetallicRoughness']
    mat = g['materials'][0]; pbr = mat['pbrMetallicRoughness']
    blob, _ = image_of(r, rchunks, spbr['baseColorTexture']['index'])
    rgb = np.asarray(Image.open(io.BytesIO(blob)).convert('RGB')).astype(np.float32) / 255
    graded, stats = grade(rgb)
    gimg = Image.fromarray((graded * 255).round().clip(0, 255).astype(np.uint8))
    put_image(g, chunks, pbr['baseColorTexture']['index'], png(gimg), 'image/png', 'base_color_b')
    blob, mime = image_of(r, rchunks, spbr['metallicRoughnessTexture']['index'])
    put_image(g, chunks, pbr['metallicRoughnessTexture']['index'], blob, mime, 'metallic_roughness_b')
    pbr['metallicFactor'] = spbr.get('metallicFactor', 1.0); pbr['roughnessFactor'] = spbr.get('roughnessFactor', 1.0)
    blob, mime = image_of(r, rchunks, src['normalTexture']['index'])
    put_image(g, chunks, mat['normalTexture']['index'], blob, mime, 'normal_b')
    for key in KEPT:
        if g.get(key) != orig.get(key):
            sys.exit(f'{key} changed; refusing')
    skip = {im['bufferView'] for im in orig['images']}
    for i in range(len(orig['bufferViews'])):
        if i not in skip and view_bytes(g, chunks, i) != view_bytes(orig, orig_chunks, i):
            sys.exit(f'bufferView {i} changed; refusing')
    write_glb(OUT, g, chunks)
    gr = (graded * 255).round().astype(np.uint8)
    rel = lambda p: str(p.relative_to(ROOT)) if p.is_relative_to(ROOT) else str(p)
    rep = {'base': rel(BASE), 'base_sha256': hashlib.sha256(BASE.read_bytes()).hexdigest(),
           'retexture': rel(retex_path), 'retexture_sha256': hashlib.sha256(retex_path.read_bytes()).hexdigest(),
           'output': rel(OUT), 'output_sha256': hashlib.sha256(OUT.read_bytes()).hexdigest(),
           'uv_sets_identical': True, 'unique_uvs': len(ua), 'grade': stats,
           'red_metric_strict_hue_lt15_gt320_sat_gt030_val_gt020_pct': {'before': round(100 * float(strict_red(rgb).mean()), 4), 'after': round(100 * float(strict_red(graded).mean()), 4)},
           'policy_red_pink_rust_h_lt24': {'before': round(red_fraction((rgb * 255).astype(np.uint8)), 4), 'after': round(red_fraction(gr), 4)},
           'kept_unchanged': KEPT + ['all non-image bufferView bytes'], 'material': g['materials'][0],
           'animations': [a.get('name') for a in g.get('animations', [])]}
    REPORT.write_text(json.dumps(rep, indent=2) + '\n')
    gimg.resize((768, 768)).save(REPORT.parent / '_cb_b_base_small.jpg') if not REPORT.is_relative_to(ROOT) else None
    print(json.dumps({k: v for k, v in rep.items() if k != 'material'}, indent=1))


if __name__ == '__main__':
    main()
