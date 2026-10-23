#!/usr/bin/env python3
"""Staticub regen candidate A2: Meshy retexture maps + blue-violet bolts on a copy of rigged regen A.

    python3 assets/creatures/tetherbound/staticub/candidate_regen/source/apply_regen_a2_textures.py <retexture.glb>

Meshy retexture a2_s1 01a15cc6-40e1-718a-8405-90d63a3038c9 (enable_original_uv, style image
01a15cc5-75f5-75ce-a319-bfdc3282ccd9: same cub, fur-strand albedo, #6E74FF bolts with a white-blue
core) of creature_staticub_regen_a.glb kept its UVs but is unskinned and unanimated. This copies the
rigged regen A GLB byte-for-byte except the material images: base colour, metallic-roughness and
normal come from the retexture. Then, deterministically:
  * the fur hue is compressed toward 23 deg (warm band -15..40 deg pulled 55%, falloff to zero at -25
    and 50 deg), as regrade_base_color.py did for regen A, so dark reddish shadows read chocolate;
  * bolt texels (hue 225-340, sat >0.12, value >0.40) are pulled to hue 237 (#6E74FF), the brightest
    low-saturation core toward #E4E8FF, and any mauve/pink fringe (hue 280-340) is rotated to 245-250;
  * an emissive map is written from the same bolt mask (bolt colour scaled by mask strength, core
    whiter), emissiveFactor 1, so the bolts glow blue-violet;
  * a red clamp recolours any saturated red/oxblood texel (hue <15 or >320, sat >0.45, value >0.15)
    to the fur hue at the same value.
Eyes (hue 185-232) are outside every band. Mesh, skin, rig, clips and every non-image bufferView
stay byte-identical; the script refuses otherwise. GLB helpers follow
tools/art_pipeline/apply_multiview_retex.py.
"""
import hashlib, io, json, pathlib, sys
import numpy as np
from PIL import Image, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parents[6]
sys.path.insert(0, str(ROOT / 'tools/art_pipeline'))
from apply_multiview_retex import read_glb, write_glb, view_bytes, image_of, put_image, red_fraction  # noqa: E402

DIR = ROOT / 'assets/creatures/tetherbound/staticub/candidate_regen'
BASE = DIR / 'models/creature_staticub_regen_a.glb'
OUT = DIR / 'models/creature_staticub_regen_a2.glb'
REPORT = DIR / 'source/apply-report-A2.json'
BOLT = np.array([0x6E, 0x74, 0xFF], np.float32) / 255
CORE = np.array([0xE4, 0xE8, 0xFF], np.float32) / 255
WARM_CENTRE, WARM_PULL = 23.0, 0.55
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


def compress_warm(rgb):
    """Fur hue compression: warm hues -15..40 deg pulled 55% toward 23 deg (falloff to 0 at -25 and 50)."""
    h, s, v = hsv(rgb)
    hw = np.where(h > 300, h - 360, h)
    w = np.clip((hw + 25) / 10, 0, 1) * np.clip((50 - hw) / 10, 0, 1)
    h2 = hw + w * WARM_PULL * (WARM_CENTRE - hw)
    return from_hsv(h2 % 360, s, v)


def grade(rgb):
    rgb = compress_warm(rgb)
    h, s, v = hsv(rgb)
    bolt = (h > 225) & (h < 340) & (s > 0.12) & (v > 0.40)
    # bolt strength: brighter = stronger glow
    w = np.clip((v - 0.40) / 0.45, 0, 1) * bolt
    out = rgb.copy()
    hb, sb, vb = hsv(BOLT[None, None, :])
    tgt = from_hsv(np.full_like(h, float(hb[0, 0])), np.clip(s, 0.45, 0.75), v)
    fringe = bolt & (h >= 280)
    tgt_f = from_hsv(np.where(fringe, 245 + 5 * np.clip((h - 280) / 60, 0, 1), h), np.minimum(s, 0.6), v)
    tgt = np.where(fringe[..., None], tgt_f, tgt)
    core = bolt & (v > 0.85) & (s < 0.40)
    tgt = np.where(core[..., None], CORE * np.clip(v, 0.9, 1.0)[..., None], tgt)
    out[bolt] = tgt[bolt]
    # red clamp (fur hue 28 at same value)
    h2, s2, v2 = hsv(out)
    rc = ((h2 < 15) | (h2 > 320)) & (s2 > 0.45) & (v2 > 0.15)
    out[rc] = from_hsv(np.full(int(rc.sum()), 28.0), np.minimum(s2[rc], 0.55), v2[rc])
    emis = BOLT[None, None, :] * w[..., None]
    emis = np.where(core[..., None], CORE * w[..., None], emis)
    emis_img = Image.fromarray((emis * 255).round().clip(0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))
    return out, emis_img, {'bolt_texels_pct': round(100 * float(bolt.mean()), 3), 'core_texels_pct': round(100 * float(core.mean()), 3),
                           'fringe_rotated_texels_pct': round(100 * float(fringe.mean()), 3), 'red_clamped_texels': int(rc.sum())}


def png(img):
    b = io.BytesIO(); img.save(b, 'PNG', optimize=True); return b.getvalue()


def main():
    retex_path = pathlib.Path(sys.argv[1]).resolve()
    g, chunks = read_glb(BASE); orig, orig_chunks = read_glb(BASE)
    r, rchunks = read_glb(retex_path)
    def uvs(gl, ch):
        out = set()
        for m in gl['meshes']:
            for p in m['primitives']:
                a = gl['accessors'][p['attributes']['TEXCOORD_0']]; vw = gl['bufferViews'][a['bufferView']]
                data = view_bytes(gl, ch, a['bufferView']); st = vw.get('byteStride', 8)
                arr = np.frombuffer(data, np.uint8)
                for i in range(a['count']):
                    o = a.get('byteOffset', 0) + i * st
                    out.add(tuple(np.round(np.frombuffer(data[o:o + 8], np.float32).astype(float), 4)))
        return out
    ua, ub = uvs(g, chunks), uvs(r, rchunks)
    if ua != ub:
        sys.exit('UV sets differ (%d vs %d, %d shared); refusing' % (len(ua), len(ub), len(ua & ub)))
    src = r['materials'][0]; spbr = src['pbrMetallicRoughness']
    mat = g['materials'][0]; pbr = mat['pbrMetallicRoughness']
    blob, _ = image_of(r, rchunks, spbr['baseColorTexture']['index'])
    rgb = np.asarray(Image.open(io.BytesIO(blob)).convert('RGB')).astype(np.float32) / 255
    graded, emis_img, stats = grade(rgb)
    gimg = Image.fromarray((graded * 255).round().clip(0, 255).astype(np.uint8))
    put_image(g, chunks, pbr['baseColorTexture']['index'], png(gimg), 'image/png', 'base_color_a2')
    blob, mime = image_of(r, rchunks, spbr['metallicRoughnessTexture']['index'])
    put_image(g, chunks, pbr['metallicRoughnessTexture']['index'], blob, mime, 'metallic_roughness_a2')
    pbr['metallicFactor'] = spbr.get('metallicFactor', 1.0); pbr['roughnessFactor'] = spbr.get('roughnessFactor', 1.0)
    blob, mime = image_of(r, rchunks, src['normalTexture']['index'])
    put_image(g, chunks, mat['normalTexture']['index'], blob, mime, 'normal_a2')
    mat['emissiveTexture'] = {'index': put_image(g, chunks, None, png(emis_img), 'image/png', 'emissive_a2')}
    mat['emissiveFactor'] = [1.0, 1.0, 1.0]
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
