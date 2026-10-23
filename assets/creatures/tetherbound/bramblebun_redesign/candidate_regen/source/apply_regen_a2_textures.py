#!/usr/bin/env python3
"""Bramblebun regen candidate A2: Meshy leaf/loam/thorn-vine retexture on a copy of rigged regen A.

    python3 assets/creatures/tetherbound/bramblebun_redesign/candidate_regen/source/apply_regen_a2_textures.py <retexture.glb>

Meshy retexture a2_s4 01a15d45-80a5-7448-ba50-53628bd51f41 (enable_original_uv, style image
01a15d3e-244d-7077-ab59-ba47131ae70b: same tall-eared hare, tan-brown fur, leaves, loam and moss
layered over the whole body with thorn vines woven through, pink inner ears, small antlers) of
creature_bramblebun_regen_a.glb kept its UVs but is unskinned and unanimated. This copies the rigged
regen A GLB byte-for-byte except the material images: base colour, metallic-roughness and normal come
from the retexture. Adapted from the Staticub regen A2 script
(staticub/candidate_regen/source/apply_regen_a2_textures.py); GLB helpers follow
tools/art_pipeline/apply_multiview_retex.py.

Red clamp with ear protection: the only pink allowed is the inner ears. Each texel's bind-pose
height is rasterised from the mesh UVs; texels on the ears (height above EAR_Y of the body height)
keep their pink. Every other red/pink texel (hue <15 or >320, sat >0.30, value >0.15), including
texels outside the UV islands, is recoloured to the tan fur hue (30 deg) at the same value with
saturation capped at 0.50. Mesh, skin, rig, clips and every non-image bufferView stay byte-identical;
the script refuses otherwise.
"""
import hashlib, io, json, pathlib, sys
import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[6]
sys.path.insert(0, str(ROOT / 'tools/art_pipeline'))
from apply_multiview_retex import read_glb, write_glb, view_bytes, image_of, put_image, red_fraction, _mesh  # noqa: E402

DIR = ROOT / 'assets/creatures/tetherbound/bramblebun_redesign/candidate_regen'
BASE = DIR / 'models/creature_bramblebun_regen_a.glb'
OUT = DIR / 'models/creature_bramblebun_regen_a2.glb'
REPORT = DIR / 'source/apply-report-A2.json'
EAR_Y = 0.70          # ears start above 70% of the body height (head top ~0.62, ear tips 1.0)
FUR_HUE = 30.0
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


def height_map(g, chunks, n):
    """Per-texel normalised bind-pose height (NaN outside the UV islands)."""
    P, U, T = _mesh(g, chunks)
    y = (P[:, 1] - P[:, 1].min()) / (P[:, 1].max() - P[:, 1].min())
    out = np.full((n, n), np.nan, np.float32)
    tx = U[:, 0] * n - 0.5; ty = U[:, 1] * n - 0.5    # glTF UV origin is the image top-left
    for t in T:
        x = tx[t]; yy = ty[t]
        x0 = max(int(np.floor(x.min())), 0); x1 = min(int(np.ceil(x.max())), n - 1)
        y0 = max(int(np.floor(yy.min())), 0); y1 = min(int(np.ceil(yy.max())), n - 1)
        if x1 < x0 or y1 < y0:
            continue
        X, Y = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
        d = (yy[1] - yy[2]) * (x[0] - x[2]) + (x[2] - x[1]) * (yy[0] - yy[2])
        if abs(d) < 1e-12:
            continue
        a = ((yy[1] - yy[2]) * (X - x[2]) + (x[2] - x[1]) * (Y - yy[2])) / d
        b = ((yy[2] - yy[0]) * (X - x[2]) + (x[0] - x[2]) * (Y - yy[2])) / d
        c = 1 - a - b; m = (a >= -0.02) & (b >= -0.02) & (c >= -0.02)
        out[Y[m], X[m]] = a[m] * y[t[0]] + b[m] * y[t[1]] + c[m] * y[t[2]]
    return out


def grade(rgb, hmap):
    h, s, v = hsv(rgb)
    red = ((h < 15) | (h > 320)) & (s > 0.30) & (v > 0.15)
    ear = np.nan_to_num(hmap, nan=0.0) > EAR_Y
    clamp = red & ~ear
    out = rgb.copy()
    out[clamp] = from_hsv(np.full(int(clamp.sum()), FUR_HUE), np.minimum(s[clamp], 0.50), v[clamp])
    n = red.size
    return out, {'red_texels_pct_before': round(100 * float(red.mean()), 4), 'ear_pink_kept_pct': round(100 * float((red & ear).sum()) / n, 4),
                 'clamped_texels_pct': round(100 * float(clamp.sum()) / n, 4), 'ear_height_fraction': EAR_Y,
                 'uv_covered_pct': round(100 * float(np.isfinite(hmap).mean()), 2)}


def png(img):
    b = io.BytesIO(); img.save(b, 'PNG', optimize=True); return b.getvalue()


def main():
    retex_path = pathlib.Path(sys.argv[1]).resolve()
    g, chunks = read_glb(BASE); orig, orig_chunks = read_glb(BASE)
    r, rchunks = read_glb(retex_path)
    def uvs(gl, ch):
        _, U, _ = _mesh(gl, ch)
        return set(map(tuple, np.round(U, 4)))
    ua, ub = uvs(g, chunks), uvs(r, rchunks)
    if ua != ub:
        sys.exit('UV sets differ (%d vs %d, %d shared); refusing' % (len(ua), len(ub), len(ua & ub)))
    src = r['materials'][0]; spbr = src['pbrMetallicRoughness']
    mat = g['materials'][0]; pbr = mat['pbrMetallicRoughness']
    blob, _ = image_of(r, rchunks, spbr['baseColorTexture']['index'])
    rgb = np.asarray(Image.open(io.BytesIO(blob)).convert('RGB')).astype(np.float32) / 255
    hmap = height_map(g, chunks, rgb.shape[0])
    graded, stats = grade(rgb, hmap)
    gimg = Image.fromarray((graded * 255).round().clip(0, 255).astype(np.uint8))
    put_image(g, chunks, pbr['baseColorTexture']['index'], png(gimg), 'image/png', 'base_color_a2')
    if 'metallicRoughnessTexture' in spbr:
        blob, mime = image_of(r, rchunks, spbr['metallicRoughnessTexture']['index'])
        put_image(g, chunks, pbr.get('metallicRoughnessTexture', {}).get('index'), blob, mime, 'metallic_roughness_a2')
        pbr.setdefault('metallicRoughnessTexture', {'index': len(g['textures']) - 1})
    pbr['metallicFactor'] = spbr.get('metallicFactor', 1.0); pbr['roughnessFactor'] = spbr.get('roughnessFactor', 1.0)
    blob, mime = image_of(r, rchunks, src['normalTexture']['index'])
    put_image(g, chunks, mat.get('normalTexture', {}).get('index'), blob, mime, 'normal_a2')
    for key in KEPT:
        if g.get(key) != orig.get(key):
            sys.exit(f'{key} changed; refusing')
    skip = {im['bufferView'] for im in orig['images']}
    for i in range(len(orig['bufferViews'])):
        if i not in skip and view_bytes(g, chunks, i) != view_bytes(orig, orig_chunks, i):
            sys.exit(f'bufferView {i} changed; refusing')
    write_glb(OUT, g, chunks)
    gr = (graded * 255).round().astype(np.uint8)
    rep = {'base': str(BASE.relative_to(ROOT)), 'base_sha256': hashlib.sha256(BASE.read_bytes()).hexdigest(),
           'retexture': str(retex_path.relative_to(ROOT)) if retex_path.is_relative_to(ROOT) else str(retex_path),
           'retexture_sha256': hashlib.sha256(retex_path.read_bytes()).hexdigest(),
           'output': str(OUT.relative_to(ROOT)), 'output_sha256': hashlib.sha256(OUT.read_bytes()).hexdigest(),
           'uv_sets_identical': True, 'unique_uvs': len(ua), 'grade': stats,
           'red_metric_strict_hue_lt15_gt320_sat_gt030_val_gt020_pct': {'before': round(100 * float(strict_red(rgb).mean()), 4), 'after': round(100 * float(strict_red(graded).mean()), 4)},
           'policy_red_pink_rust_h_lt24': {'before': round(red_fraction((rgb * 255).astype(np.uint8)), 4), 'after': round(red_fraction(gr), 4)},
           'kept_unchanged': KEPT + ['all non-image bufferView bytes'], 'material': g['materials'][0],
           'animations': [a.get('name') for a in g.get('animations', [])]}
    REPORT.write_text(json.dumps(rep, indent=2) + '\n')
    print(json.dumps({k: v for k, v in rep.items() if k != 'material'}, indent=1))


if __name__ == '__main__':
    main()
