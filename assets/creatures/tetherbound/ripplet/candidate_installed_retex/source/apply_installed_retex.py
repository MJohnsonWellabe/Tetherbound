#!/usr/bin/env python3
"""Installed-rig Meshy retexture candidates (round r6): Meshy maps on a copy of the installed rigged GLB.

    python3 assets/creatures/tetherbound/<species>/candidate_installed_retex/source/apply_installed_retex.py <species>

The species is not on the standard 15-bone quadruped skeleton, so its geometry is kept: a Meshy
retexture (enable_original_uv) of the installed bound GLB keeps its UVs but comes back unskinned,
unanimated and rescaled. This copies the installed rigged GLB byte-for-byte except the material
images: base colour, metallic-roughness and normal come from the retexture's embedded maps, then a
deterministic per-species profile (PROFILES below) is applied:
  * hue_moves: texels inside a hue/sat/value window are moved toward a target hue/sat (soft edge);
  * emissive: texels matching a hue/sat/value window become an emissive map (their own colour,
    brightened), emissiveFactor 1; or the installed emissive map is kept;
  * roughness_floor: the roughness channel (G) is remapped to floor + (1 - floor) * g, metallic (B)
    is zeroed, which lowers gloss;
  * a red clamp recolours any saturated red/oxblood texel (hue <15 or >320, sat > CLAMP_SAT,
    value > CLAMP_VAL) to the profile's safe hue at the same value (red is Team Tether's).
Mesh, skin, rig, clips, UVs and every non-image bufferView stay byte-identical; the script refuses
otherwise. GLB helpers follow terrapup/candidate_installed_retex/source/apply_retex_textures_v3.py.
"""
import hashlib, io, json, os, pathlib, struct, sys

import numpy as np
from PIL import Image, ImageFilter

ROOT = pathlib.Path(os.environ.get('TB_ROOT') or pathlib.Path(__file__).resolve().parents[6])
# OUT_ROOT lets a staging copy write outside the checkout; outputs default to the checkout.
OUT_ROOT = pathlib.Path(os.environ.get('TB_OUT_ROOT') or ROOT)
RAW = 'assets_raw/{sp}/meshy-r6-1021/{run}/model.glb'

PROFILES = {
    'abyssal_guardian': {
        'installed': 'assets/creatures/tetherbound/abyssal_guardian/models/creature_abyssal_guardian_lod0.glb',
        'run': 'ag_r1-01a15d59-4c25-7632-9639-e43531aac12a',
        'hue_moves': [],
        # bright cyan glow line, spine tips, flipper spots and eye ring
        'emissive': {'hue': [165, 205], 'sat_min': 0.35, 'val_min': 0.62, 'gain': 1.25},
        'roughness_floor': 0.68,
        'safe_hue': 210.0,
    },
    'veridian': {
        'installed': 'assets/creatures/tetherbound/veridian/candidate/models/creature_veridian_native.glb',
        'run': 'ver_r1-01a15d5c-c62d-71eb-a282-4f14f94d25cb',
        'hue_moves': [],
        # teal chest gem glows softly
        'emissive': {'hue': [160, 190], 'sat_min': 0.50, 'val_min': 0.55, 'gain': 1.0},
        'roughness_floor': None,
        'safe_hue': 40.0,
    },
    'ripplet': {
        'installed': 'assets/creatures/tetherbound/ripplet/models/creature_ripplet_lod0.glb',
        'run': 'rip_r1-01a15d60-d723-704d-a18b-9dfdc42c0a80',
        # coral inner frill edge -> light coral-peach (hue 18), never red
        'hue_moves': [{'hue': [345, 17], 'sat_min': 0.30, 'val_min': 0.35, 'to_hue': 18.0, 'sat_hi': 0.55}],
        # glassy aqua frill/tail-fin membranes and teardrops get a soft glow (replaces the installed
        # emissive, which lit the old white dots)
        'emissive': {'hue': [165, 200], 'sat_min': 0.12, 'sat_max': 0.50, 'val_min': 0.72, 'gain': 0.40},
        'roughness_floor': None,
        'safe_hue': 18.0,
    },
}
CLAMP_SAT, CLAMP_VAL = 0.45, 0.20


def read_glb(path):
    raw = path.read_bytes()
    total = struct.unpack('<I', raw[8:12])[0]
    off, chunks = 12, []
    while off < total:
        clen, ctype = struct.unpack('<I4s', raw[off:off + 8])
        chunks.append([ctype, bytearray(raw[off + 8:off + 8 + clen])])
        off += 8 + clen
    return json.loads(bytes(chunks[0][1]).decode('utf-8')), chunks


def write_glb(path, gltf, chunks):
    js = json.dumps(gltf, separators=(',', ':')).encode('utf-8')
    js += b' ' * ((4 - len(js) % 4) % 4)
    chunks[0][1] = bytearray(js)
    for c in chunks[1:]:
        c[1] += bytearray(b'\x00' * ((4 - len(c[1]) % 4) % 4))
    body = b''.join(struct.pack('<I4s', len(c[1]), c[0]) + bytes(c[1]) for c in chunks)
    path.write_bytes(b'glTF' + struct.pack('<II', 2, 12 + len(body)) + body)


def view_bytes(gltf, chunks, index):
    view = gltf['bufferViews'][index]
    start = view.get('byteOffset', 0)
    return bytes(chunks[1][1][start:start + view['byteLength']])


def uv_set(gltf, chunks):
    found = set()
    for mesh in gltf['meshes']:
        for prim in mesh['primitives']:
            if 'TEXCOORD_0' not in prim['attributes']:
                continue
            acc = gltf['accessors'][prim['attributes']['TEXCOORD_0']]
            view = gltf['bufferViews'][acc['bufferView']]
            data = view_bytes(gltf, chunks, acc['bufferView'])
            stride = view.get('byteStride', 8); base = acc.get('byteOffset', 0)
            for i in range(acc['count']):
                u, v = struct.unpack_from('<2f', data, base + i * stride)
                found.add((round(u, 4), round(v, 4)))
    return found


def image_of(gltf, chunks, texture_index):
    image = gltf['images'][gltf['textures'][texture_index]['source']]
    return view_bytes(gltf, chunks, image['bufferView']), image.get('mimeType', 'image/png')


def image_views(gltf):
    return {img['bufferView'] for img in gltf.get('images', []) if 'bufferView' in img}


def put_image(gltf, chunks, slot_texture, blob, mime, name):
    """Replace a texture's image bytes in place, or append a new image."""
    if slot_texture is not None:
        image = gltf['images'][gltf['textures'][slot_texture]['source']]
        index = image['bufferView']; view = gltf['bufferViews'][index]
        start, old = view.get('byteOffset', 0), view['byteLength']
        pad = (4 - len(blob) % 4) % 4
        chunks[1][1] = chunks[1][1][:start] + bytearray(blob) + bytearray(b'\x00' * pad) + chunks[1][1][start + old:]
        delta = len(blob) + pad - old
        view['byteLength'] = len(blob)
        for other in gltf['bufferViews']:
            if other is not view and other.get('byteOffset', 0) > start:
                other['byteOffset'] += delta
        image['mimeType'] = mime; image['name'] = name
        gltf['buffers'][0]['byteLength'] = len(chunks[1][1])
        return slot_texture
    chunks[1][1] += bytearray(b'\x00' * ((4 - len(chunks[1][1]) % 4) % 4))
    gltf['bufferViews'].append({'buffer': 0, 'byteOffset': len(chunks[1][1]), 'byteLength': len(blob)})
    chunks[1][1] += bytearray(blob)
    gltf['buffers'][0]['byteLength'] = len(chunks[1][1])
    gltf['images'].append({'bufferView': len(gltf['bufferViews']) - 1, 'mimeType': mime, 'name': name})
    if not gltf.get('samplers'):
        gltf['samplers'] = [{}]
    gltf['textures'].append({'sampler': 0, 'source': len(gltf['images']) - 1})
    return len(gltf['textures']) - 1


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


def in_hue(h, lo, hi):
    return (h >= lo) & (h <= hi) if lo <= hi else (h >= lo) | (h <= hi)


def red_mask(rgb):
    """The shared red metric (hue <15 or >320, sat >0.30, value >0.20)."""
    h, s, v = hsv(rgb)
    return ((h < 15) | (h > 320)) & (s > 0.30) & (v > 0.20)


def grade(rgb, prof):
    stats = {}
    out = rgb.copy()
    for k, mv in enumerate(prof['hue_moves']):
        h, s, v = hsv(out)
        m = in_hue(h, *mv['hue']) & (s >= mv.get('sat_min', 0)) & (v >= mv.get('val_min', 0)) & (v <= mv.get('val_max', 1.01))
        w = m.astype(np.float32) * mv.get('pull', 1.0)
        th = np.full_like(h, mv['to_hue']) if 'to_hue' in mv else h
        ts = np.clip(s * mv.get('sat_mul', 1.0), mv.get('sat_lo', 0), mv.get('sat_hi', 1))
        tv = np.clip(v * mv.get('val_mul', 1.0) + mv.get('val_add', 0.0), 0, 1)
        # shortest-arc hue blend
        dh = ((th - h + 180) % 360) - 180
        tgt = from_hsv(h + w * dh, s + w * (ts - s), v + w * (tv - v))
        out = np.where(m[..., None], tgt, out)
        stats['hue_move_%d_texels_pct' % k] = round(100 * float(m.mean()), 3)
    emis_img = None
    e = prof.get('emissive')
    if e:
        h, s, v = hsv(out)
        m = in_hue(h, *e['hue']) & (s >= e['sat_min']) & (s <= e.get('sat_max', 1.01)) & (v >= e['val_min'])
        w = np.clip((v - e['val_min']) / max(1e-3, 1 - e['val_min']) * 1.5 + 0.35, 0, 1) * m
        col = np.clip(out * e.get('gain', 1.0), 0, 1)
        emis = col * w[..., None]
        emis_img = Image.fromarray((emis * 255).round().clip(0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
        stats['emissive_texels_pct'] = round(100 * float(m.mean()), 3)
    h2, s2, v2 = hsv(out)
    rc = ((h2 < 15) | (h2 > 320)) & (s2 > CLAMP_SAT) & (v2 > CLAMP_VAL)
    out[rc] = from_hsv(np.full(int(rc.sum()), prof['safe_hue']), np.minimum(s2[rc], 0.55), v2[rc])
    stats['red_clamped_texels'] = int(rc.sum())
    return out, emis_img, stats


def png(img):
    b = io.BytesIO(); img.save(b, 'PNG', optimize=True); return b.getvalue()


def main():
    sp = sys.argv[1]; prof = PROFILES[sp]
    installed = ROOT / prof['installed']
    retex_path = ROOT / RAW.format(sp=sp, run=prof['run'])
    cdir = OUT_ROOT / f'assets/creatures/tetherbound/{sp}/candidate_installed_retex'
    out_path = cdir / f'models/creature_{sp}_installed_retex_r6_lod0.glb'
    report_path = cdir / 'source/apply-report-r6.json'
    out_path.parent.mkdir(parents=True, exist_ok=True)
    base, base_chunks = read_glb(installed)
    original, original_chunks = read_glb(installed)
    retex, retex_chunks = read_glb(retex_path)
    uv_a, uv_b = uv_set(base, base_chunks), uv_set(retex, retex_chunks)
    if uv_a != uv_b:
        sys.exit('UV sets differ (%d vs %d, %d shared); refusing to transfer maps' % (len(uv_a), len(uv_b), len(uv_a & uv_b)))
    if len(base['materials']) != 1:
        sys.exit('expected one material on the installed model')
    src = retex['materials'][0]; spbr = src['pbrMetallicRoughness']
    mat = base['materials'][0]; pbr = mat.setdefault('pbrMetallicRoughness', {})
    blob, _ = image_of(retex, retex_chunks, spbr['baseColorTexture']['index'])
    rgb = np.asarray(Image.open(io.BytesIO(blob)).convert('RGB')).astype(np.float32) / 255
    graded, emis_img, stats = grade(rgb, prof)
    gimg = Image.fromarray((graded * 255).round().clip(0, 255).astype(np.uint8))
    pbr['baseColorTexture'] = {'index': put_image(base, base_chunks, pbr.get('baseColorTexture', {}).get('index'), png(gimg), 'image/png', 'base_color_r6')}
    blob, mime = image_of(retex, retex_chunks, spbr['metallicRoughnessTexture']['index'])
    rf = prof.get('roughness_floor')
    if rf is not None:
        mr = np.asarray(Image.open(io.BytesIO(blob)).convert('RGB')).astype(np.float32) / 255
        stats['roughness_mean_before'] = round(float(mr[..., 1].mean()), 3)
        mr[..., 1] = rf + (1 - rf) * mr[..., 1]; mr[..., 2] = 0.0
        stats['roughness_mean_after'] = round(float(mr[..., 1].mean()), 3)
        blob, mime = png(Image.fromarray((mr * 255).round().astype(np.uint8))), 'image/png'
        pbr['metallicFactor'] = 0.0; pbr['roughnessFactor'] = 1.0
    else:
        pbr['metallicFactor'] = 0.0; pbr['roughnessFactor'] = spbr.get('roughnessFactor', 1.0)
    pbr['metallicRoughnessTexture'] = {'index': put_image(base, base_chunks, pbr.get('metallicRoughnessTexture', {}).get('index'), blob, mime, 'metallic_roughness_r6')}
    blob, mime = image_of(retex, retex_chunks, src['normalTexture']['index'])
    mat['normalTexture'] = {'index': put_image(base, base_chunks, mat.get('normalTexture', {}).get('index'), blob, mime, 'normal_r6')}
    if emis_img is not None:
        mat['emissiveTexture'] = {'index': put_image(base, base_chunks, mat.get('emissiveTexture', {}).get('index'), png(emis_img), 'image/png', 'emissive_r6')}
        mat['emissiveFactor'] = [1.0, 1.0, 1.0]
    write_glb(out_path, base, base_chunks)
    out, out_chunks = read_glb(out_path)
    for key in ('meshes', 'accessors', 'skins', 'nodes', 'animations', 'scenes'):
        if out.get(key) != original.get(key):
            sys.exit('%s changed; refusing' % key)
    skip = image_views(original)
    non_image = [i for i in range(len(original['bufferViews'])) if i not in skip]
    for i in non_image:
        if view_bytes(out, out_chunks, i) != view_bytes(original, original_chunks, i):
            sys.exit('bufferView %d changed; refusing' % i)
    gr = (graded * 255).round().astype(np.uint8).astype(np.float32) / 255
    report = {'species': sp, 'installed': prof['installed'], 'installed_sha256': hashlib.sha256(installed.read_bytes()).hexdigest(),
              'retexture': str(retex_path.relative_to(ROOT)), 'retexture_sha256': hashlib.sha256(retex_path.read_bytes()).hexdigest(),
              'output': str(out_path.relative_to(OUT_ROOT)), 'output_sha256': hashlib.sha256(out_path.read_bytes()).hexdigest(),
              'unique_uvs': len(uv_a), 'uv_sets_identical': True, 'profile': prof, 'grade': stats,
              'red_metric_strict_hue_lt15_gt320_sat_gt030_val_gt020_pct': {'retexture': round(100 * float(red_mask(rgb).mean()), 4), 'candidate': round(100 * float(red_mask(gr).mean()), 4)},
              'kept_unchanged': ['meshes', 'accessors', 'skins', 'nodes', 'animations', 'scenes', 'all non-image bufferView bytes'],
              'non_image_buffer_views_byte_identical': len(non_image),
              'joint_names': [out['nodes'][j].get('name') for j in out['skins'][0]['joints']],
              'material': out['materials'][0], 'animations': [a.get('name') for a in out.get('animations', [])]}
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k not in ('material', 'profile', 'joint_names')}, indent=1))


if __name__ == '__main__':
    main()
