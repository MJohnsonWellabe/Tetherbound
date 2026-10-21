#!/usr/bin/env python3
"""Tuskroot native retexture candidate: Meshy maps on a copy of the installed native GLB.

    python3 assets/creatures/tetherbound/tuskroot/candidate_native_retex/source/apply_retex_textures.py

Meshy retexture A_latest 01a15c8a-e4e9-7698-b7a0-67cd650c16b8 (style image: the
native-standing-v1 reference with red/pink/rust desaturated) kept the installed
UVs, but its GLB is unskinned, unanimated and rescaled. This copies the
installed rigged ``candidate/models/creature_tuskroot_native.glb`` byte-for-byte
except the material images: base colour, metallic-roughness and normal come
from the retexture's own embedded maps. Skin, skeleton (incl. front_foot_l),
mesh, UVs and the eleven clips are untouched. It refuses unless the two UV sets
are identical. Before embedding, the few red/maroon base-colour texels Meshy
left in seam gutters and crevices (hue <15 or >320, sat >0.25, value >0.15) are
recoloured to the fur-brown hue at the same value. GLB chunk helpers follow
tools/art_pipeline/regrade_tether_machine.py; copied from the Cannonback
candidate_water_retex_v2 script.
"""
import hashlib, io, json, pathlib, struct, sys

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[6]
SPECIES_DIR = ROOT / 'assets/creatures/tetherbound/tuskroot'
INSTALLED = SPECIES_DIR / 'candidate/models/creature_tuskroot_native.glb'
RETEX = ROOT / 'assets_raw/tuskroot/meshy-retex-native-1021/A_latest-01a15c8a-e4e9-7698-b7a0-67cd650c16b8/model.glb'
OUT = SPECIES_DIR / 'candidate/models/creature_tuskroot_native_retex.glb'
REPORT = pathlib.Path(__file__).with_name('apply-report.json')


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
    h, s, mx = hsv_masks(rgb)
    return ((h < 15) | (h > 320)) & (s > 0.30) & (mx > 0.20)


def clamp_red(blob):
    """Recolour red/maroon texels to fur brown (hue 28) at the same value."""
    rgb = np.asarray(Image.open(io.BytesIO(blob)).convert('RGB')).astype(np.float32) / 255
    before = red_mask(rgb)
    h, s, mx = hsv_masks(rgb)
    m = ((h < 15) | (h > 320)) & (s > 0.25) & (mx > 0.15)
    val = mx[m]; sat = np.minimum(s[m], 0.45); hh = 28 / 60.0
    c = val * sat; x = c * (1 - abs(hh % 2 - 1)); base = val - c
    rgb[..., 0][m] = c + base; rgb[..., 1][m] = x + base; rgb[..., 2][m] = base
    img = Image.fromarray((rgb * 255).round().clip(0, 255).astype(np.uint8))
    for fmt, mime, kw in (('JPEG', 'image/jpeg', {'quality': 95, 'subsampling': 0}), ('PNG', 'image/png', {'optimize': True})):
        out = io.BytesIO(); img.save(out, fmt, **kw)
        after = red_mask(np.asarray(Image.open(io.BytesIO(out.getvalue())).convert('RGB')).astype(np.float32) / 255)
        if not after.any():
            break
    n = rgb.shape[0] * rgb.shape[1]
    return out.getvalue(), mime, {'encoded_as': mime, 'recoloured_texels': int(m.sum()), 'red_texels_pct_before': round(100 * before.sum() / n, 4),
                            'red_texels_pct_after': round(100 * after.sum() / n, 4)}


def main():
    base, base_chunks = read_glb(INSTALLED)
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
    report = {'installed': str(INSTALLED.relative_to(ROOT)), 'installed_sha256': hashlib.sha256(INSTALLED.read_bytes()).hexdigest(),
              'retexture': str(RETEX.relative_to(ROOT)), 'retexture_sha256': hashlib.sha256(RETEX.read_bytes()).hexdigest(),
              'output': str(OUT.relative_to(ROOT)), 'output_sha256': hashlib.sha256(OUT.read_bytes()).hexdigest(),
              'unique_uvs': len(uv_a), 'uv_sets_identical': True, 'base_color_red_clamp': red_stats,
              'kept_unchanged': ['meshes', 'accessors', 'skins', 'nodes', 'animations'],
              'joint_names': [base['nodes'][j].get('name') for j in base['skins'][0]['joints']],
              'material': base['materials'][0], 'animations': [a.get('name') for a in base.get('animations', [])]}
    REPORT.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k != 'material'}, indent=1))


if __name__ == '__main__':
    main()
