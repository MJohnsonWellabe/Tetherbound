#!/usr/bin/env python3
"""Bramblebun installed retexture candidate: Meshy maps on a copy of the installed rigged lod0.

    python3 assets/creatures/tetherbound/bramblebun_redesign/candidate_installed_retex/source/apply_retex_textures.py

Meshy retexture v2_s2 01a15c91-740f-70cc-a4f6-91094c16a015 (enable_original_uv) of
the installed bound ``bramblebun_redesign/models/creature_bramblebun_redesign_lod0.glb``
kept its UVs, but its GLB is unskinned, unanimated and rescaled. This copies the
installed rigged GLB byte-for-byte except the material images: base colour,
metallic-roughness and normal come from the retexture's own embedded maps. Skin,
skeleton, mesh, UVs, clips and every other material field are untouched. It
refuses unless the two UV sets are identical and verifies every non-image
bufferView is byte-identical afterwards. The base colour is stored as PNG.
Adapted from the Tuskroot candidate_native_retex script (itself from Cannonback
candidate_water_retex_v2); GLB chunk helpers follow
tools/art_pipeline/regrade_tether_machine.py.

Bramblebun thresholds: the pink inner ears (sat 0.30-0.45, value 0.8-0.97) are
allowed natural pink and are not clamped. Only saturated red/oxblood (hue <15 or
>320, sat >0.45, value >0.15: rust speckles in the dark bark, the eye irises'
reddish rim and a small salmon cheek spot) is recoloured to the fur-brown hue at
the same value.
"""
import hashlib, io, json, pathlib, struct, sys

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[6]
SPECIES_DIR = ROOT / 'assets/creatures/tetherbound/bramblebun_redesign'
INSTALLED = SPECIES_DIR / 'models/creature_bramblebun_redesign_lod0.glb'
RETEX = ROOT / 'assets_raw/bramblebun/meshy-retex-installed-1021/v2_s2-01a15c91-740f-70cc-a4f6-91094c16a015/model.glb'
OUT = SPECIES_DIR / 'models/creature_bramblebun_installed_retex_lod0.glb'
REPORT = pathlib.Path(__file__).with_name('apply-report.json')
CLAMP_SAT, CLAMP_VAL = 0.45, 0.15


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
    gltf['textures'].append({'sampler': 0, 'source': len(gltf['images']) - 1})
    return len(gltf['textures']) - 1


def hsv_masks(rgb):
    mx = rgb.max(2); mn = rgb.min(2); d = mx - mn + 1e-6
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    s = d / (mx + 1e-6)
    return h, s, mx


def red_mask(rgb):
    """The shared red metric (hue <15 or >320, sat >0.30, value >0.20)."""
    h, s, mx = hsv_masks(rgb)
    return ((h < 15) | (h > 320)) & (s > 0.30) & (mx > 0.20)


def clamp_mask(rgb):
    h, s, mx = hsv_masks(rgb)
    return ((h < 15) | (h > 320)) & (s > CLAMP_SAT) & (mx > CLAMP_VAL)


def clamp_red(blob):
    """Recolour the clamp-mask texels to fur brown (hue 28) at the same value; store PNG."""
    rgb = np.asarray(Image.open(io.BytesIO(blob)).convert('RGB')).astype(np.float32) / 255
    before, vis_before = red_mask(rgb), clamp_mask(rgb)
    h, s, mx = hsv_masks(rgb)
    m = vis_before
    val = mx[m]; sat = np.minimum(s[m], 0.45); hh = 28 / 60.0
    c = val * sat; x = c * (1 - abs(hh % 2 - 1)); base = val - c
    rgb[..., 0][m] = c + base; rgb[..., 1][m] = x + base; rgb[..., 2][m] = base
    img = Image.fromarray((rgb * 255).round().clip(0, 255).astype(np.uint8))
    out = io.BytesIO(); img.save(out, 'PNG', optimize=True)
    back = np.asarray(Image.open(io.BytesIO(out.getvalue())).convert('RGB')).astype(np.float32) / 255
    after, vis_after = red_mask(back), clamp_mask(back)
    n = rgb.shape[0] * rgb.shape[1]
    pct = lambda a: round(100 * float(a.sum()) / n, 4)
    return out.getvalue(), 'image/png', {
        'encoded_as': 'image/png', 'clamp_mask': 'hue <15 or >320, sat >%.2f, value >%.2f' % (CLAMP_SAT, CLAMP_VAL),
        'recoloured_texels': int(m.sum()),
        'red_metric': 'hue <15 or >320, sat >0.30, value >0.20 (all texels)',
        'red_texels_pct_before': pct(before), 'red_texels_pct_after': pct(after),
        'clamp_mask_texels_pct_before': pct(vis_before), 'clamp_mask_texels_pct_after': pct(vis_after)}


def main():
    base, base_chunks = read_glb(INSTALLED)
    original, original_chunks = read_glb(INSTALLED)
    retex, retex_chunks = read_glb(RETEX)
    uv_a, uv_b = uv_set(base, base_chunks), uv_set(retex, retex_chunks)
    if uv_a != uv_b:
        sys.exit('UV sets differ (%d vs %d, %d shared); refusing to transfer maps' % (len(uv_a), len(uv_b), len(uv_a & uv_b)))
    src = retex['materials'][0]; src_pbr = src['pbrMetallicRoughness']
    if len(base['materials']) != 1:
        sys.exit('expected one material on the installed model')
    mat = base['materials'][0]; pbr = mat.setdefault('pbrMetallicRoughness', {})
    blob, mime = image_of(retex, retex_chunks, src_pbr['baseColorTexture']['index'])
    blob, mime, red_stats = clamp_red(blob)
    pbr['baseColorTexture'] = {'index': put_image(base, base_chunks, pbr.get('baseColorTexture', {}).get('index'), blob, mime, 'base_color')}
    blob, mime = image_of(retex, retex_chunks, src_pbr['metallicRoughnessTexture']['index'])
    pbr['metallicRoughnessTexture'] = {'index': put_image(base, base_chunks, pbr.get('metallicRoughnessTexture', {}).get('index'), blob, mime, 'metallic_roughness')}
    pbr['metallicFactor'] = src_pbr.get('metallicFactor', 1.0); pbr['roughnessFactor'] = src_pbr.get('roughnessFactor', 1.0)
    blob, mime = image_of(retex, retex_chunks, src['normalTexture']['index'])
    mat['normalTexture'] = {'index': put_image(base, base_chunks, mat.get('normalTexture', {}).get('index'), blob, mime, 'normal')}
    write_glb(OUT, base, base_chunks)
    # Verify: structural JSON equal and every non-image bufferView byte-identical.
    out, out_chunks = read_glb(OUT)
    for key in ('meshes', 'accessors', 'skins', 'nodes', 'animations', 'scenes', 'samplers'):
        if out.get(key) != original.get(key):
            sys.exit('%s changed; refusing' % key)
    skip = image_views(original)
    non_image = [i for i in range(len(original['bufferViews'])) if i not in skip]
    for i in non_image:
        if view_bytes(out, out_chunks, i) != view_bytes(original, original_chunks, i):
            sys.exit('bufferView %d changed; refusing' % i)
    report = {'installed': str(INSTALLED.relative_to(ROOT)), 'installed_sha256': hashlib.sha256(INSTALLED.read_bytes()).hexdigest(),
              'retexture': str(RETEX.relative_to(ROOT)), 'retexture_sha256': hashlib.sha256(RETEX.read_bytes()).hexdigest(),
              'output': str(OUT.relative_to(ROOT)), 'output_sha256': hashlib.sha256(OUT.read_bytes()).hexdigest(),
              'unique_uvs': len(uv_a), 'uv_sets_identical': True, 'base_color_red_clamp': red_stats,
              'kept_unchanged': ['meshes', 'accessors', 'skins', 'nodes', 'animations', 'scenes', 'samplers'],
              'non_image_buffer_views_byte_identical': len(non_image),
              'joint_names': [out['nodes'][j].get('name') for j in out['skins'][0]['joints']],
              'material': out['materials'][0], 'animations': [a.get('name') for a in out.get('animations', [])]}
    REPORT.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k != 'material'}, indent=1))


if __name__ == '__main__':
    main()
