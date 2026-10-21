#!/usr/bin/env python3
"""Tuskroot belly/hoof retexture candidate: Meshy maps on a copy of the rigged lod0.

    python3 assets/creatures/tetherbound/tuskroot/candidate_belly_hoof_retex/source/apply_retex_textures.py

Meshy retexture 01a15c3f-5ba9-73b0-a4ed-8772864ecddb kept the installed UVs,
but its GLB is unskinned, unanimated and rescaled. This copies the installed
rigged ``creature_tuskroot_lod0.glb`` byte-for-byte except the material
images: base colour, metallic-roughness and normal come from the retexture's
own embedded maps; the installed black emissive map is kept. Skin, skeleton, mesh, UVs and animations are untouched.
It refuses unless the two UV sets are identical. GLB chunk helpers follow
tools/art_pipeline/regrade_tether_machine.py.
"""
import hashlib, json, pathlib, struct, sys

ROOT = pathlib.Path(__file__).resolve().parents[6]
SPECIES_DIR = ROOT / 'assets/creatures/tetherbound/tuskroot'
INSTALLED = SPECIES_DIR / 'models/creature_tuskroot_lod0.glb'
RETEX = ROOT / 'assets_raw/tuskroot/meshy-batch-1020/belly_hoof_retex_primary-01a15c3f-5ba9-73b0-a4ed-8772864ecddb/model.glb'
OUT = SPECIES_DIR / 'models/creature_tuskroot_belly_hoof_retex_lod0.glb'
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
              'unique_uvs': len(uv_a), 'uv_sets_identical': True,
              'kept_unchanged': ['meshes', 'accessors', 'skins', 'nodes', 'animations'],
              'material': base['materials'][0], 'animations': [a.get('name') for a in base.get('animations', [])]}
    REPORT.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k != 'material'}, indent=1))


if __name__ == '__main__':
    main()
