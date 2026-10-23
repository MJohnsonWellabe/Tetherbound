#!/usr/bin/env python3
"""F36#0 multiview candidates: Meshy red-free retexture maps on a copy of the rigged GLB.

    python3 tools/art_pipeline/apply_multiview_retex.py <species> [--uv-check]

Meshy retexture (enable_original_uv) kept the recovered multi-image model's UV
atlas, and the rigged ``candidate_multiview`` GLB still samples that same atlas
(its embedded Image_0 is byte-identical to the recovered model's texture), so the
retexture maps drop onto it. This copies the rigged candidate GLB byte-for-byte
except the material images: base colour, metallic-roughness and normal come from
the retexture. Mesh, UVs, skin, skeleton and animation data are verified
unchanged. ``--uv-check`` additionally projects every decimated candidate
triangle centroid onto the retexture surface and compares interpolated UVs.
Follows assets/creatures/tetherbound/cannonback/candidate_water_retex/source/apply_retex_textures.py.
"""
import hashlib, io, json, pathlib, struct, sys

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
SPECIES = {
    'bramblebun': {'retex': 'assets_raw/bramblebun/meshy-retex-1021/img1-01a15c5d-b29b-74c9-a05f-f83e4707599c',
                   'recovered': 'assets_raw/bramblebun/f36-recovered-01a142e8-f842-73d6-a027-b265f6b2c070/model.glb'},
    'burrowback': {'retex': 'assets_raw/burrowback/meshy-retex-1021/img2-01a15c60-34d3-7465-80cf-5adce09c88b4',
                   'recovered': 'assets_raw/burrowback/f36-recovered-01a14306-d610-76e7-a779-dee74fbe6462/model.glb'},
    'terrapup': {'retex': 'assets_raw/terrapup/meshy-retex-1021/img3m6-01a15c61-b69d-7256-aa3e-7e9986ce8f93',
                 'recovered': 'assets_raw/terrapup/f36-recovered-01a142f9-013c-7422-9129-a66f01b6a28c/model.glb',
                 # raw base colour has 1.07% reddish speckle; the retex worker's hue clamp removes it
                 'base_color_png': 'base_color_0_redclamp.png'},
}
KEPT = ['meshes', 'accessors', 'skins', 'nodes', 'animations', 'scenes', 'scene']


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


def image_of(gltf, chunks, texture_index):
    image = gltf['images'][gltf['textures'][texture_index]['source']]
    return view_bytes(gltf, chunks, image['bufferView']), image.get('mimeType', 'image/png')


def put_image(gltf, chunks, slot_texture, blob, mime, name):
    """Replace a texture's image bytes in place, or append a new image."""
    if slot_texture is not None:
        image = gltf['images'][gltf['textures'][slot_texture]['source']]
        index = image['bufferView']; view = gltf['bufferViews'][index]
        start, old = view.get('byteOffset', 0), view['byteLength']
        old_padded = old + (4 - old % 4) % 4
        pad = (4 - len(blob) % 4) % 4
        chunks[1][1] = chunks[1][1][:start] + bytearray(blob) + bytearray(b'\x00' * pad) + chunks[1][1][start + old_padded:]
        delta = len(blob) + pad - old_padded
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


def red_fraction(rgb):
    """Share of texels the retex worker's clamp treats as red/pink/rust."""
    hsv = np.asarray(Image.fromarray(rgb).convert('HSV'), dtype=np.float64)
    h, s, v = hsv[..., 0] * 360 / 255, hsv[..., 1] / 255, hsv[..., 2] / 255
    return float((((h < 24) | (h > 320)) & (s > 0.25) & (v > 0.12)).mean())


# ---- UV check (decimation-aware) -------------------------------------------------

def _acc(g, chunks, i):
    a = g['accessors'][i]
    n = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[a['type']]
    dt = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}[a['componentType']]
    data = view_bytes(g, chunks, a['bufferView'])
    stride = g['bufferViews'][a['bufferView']].get('byteStride', 0) or n * np.dtype(dt).itemsize
    rows = np.frombuffer(data, np.uint8)[a.get('byteOffset', 0):]
    rows = np.lib.stride_tricks.as_strided(rows, (a['count'], n * np.dtype(dt).itemsize), (stride, 1))
    return np.ascontiguousarray(rows).view(dt).reshape(a['count'], n).astype(np.float64)


def _mesh(g, chunks):
    P, U, T, base = [], [], [], 0
    for m in g['meshes']:
        for pr in m['primitives']:
            P.append(_acc(g, chunks, pr['attributes']['POSITION'])); U.append(_acc(g, chunks, pr['attributes']['TEXCOORD_0']))
            T.append(_acc(g, chunks, pr['indices']).astype(np.int64).reshape(-1, 3) + base); base += len(P[-1])
    return np.vstack(P), np.vstack(U), np.vstack(T)


def _norm(P):
    lo, hi = P.min(0), P.max(0); c = (lo + hi) / 2; c[1] = lo[1]
    return (P - c) / (hi[1] - lo[1])


def _knn(A, B, k):
    out_i = np.empty((len(A), k), np.int64); out_d = np.empty((len(A), k))
    for s in range(0, len(A), 256):
        d = ((A[s:s + 256, None, :] - B[None, :, :]) ** 2).sum(-1)
        i = np.argpartition(d, k, axis=1)[:, :k]
        out_i[s:s + 256] = i; out_d[s:s + 256] = np.take_along_axis(d, i, 1)
    return out_i, np.sqrt(out_d)


def _closest_on_tri(p, a, b, c):
    ab, ac, ap = b - a, c - a, p - a
    d1 = (ab * ap).sum(-1); d2 = (ac * ap).sum(-1)
    bp = p - b; d3 = (ab * bp).sum(-1); d4 = (ac * bp).sum(-1)
    cp = p - c; d5 = (ab * cp).sum(-1); d6 = (ac * cp).sum(-1)
    va = d3 * d6 - d5 * d4; vb = d5 * d2 - d1 * d6; vc = d1 * d4 - d3 * d2
    n = len(p); bc = np.zeros((n, 3)); done = np.zeros(n, bool); one = np.ones(n); z = np.zeros(n)

    def setm(m, w):
        m = m & ~done; bc[m] = w[m]; done[m] = True
    setm((d1 <= 0) & (d2 <= 0), np.stack([one, z, z], -1))
    setm((d3 >= 0) & (d4 <= d3), np.stack([z, one, z], -1))
    with np.errstate(all='ignore'):
        v = d1 / (d1 - d3); setm((vc <= 0) & (d1 >= 0) & (d3 <= 0), np.stack([1 - v, v, z], -1))
        setm((d6 >= 0) & (d5 <= d6), np.stack([z, z, one], -1))
        w = d2 / (d2 - d6); setm((vb <= 0) & (d2 >= 0) & (d6 <= 0), np.stack([1 - w, z, w], -1))
        w = (d4 - d3) / ((d4 - d3) + (d5 - d6)); setm((va <= 0) & ((d4 - d3) >= 0) & ((d5 - d6) >= 0), np.stack([z, 1 - w, w], -1))
        den = 1 / (va + vb + vc); v = vb * den; w = vc * den
        setm(np.ones(n, bool), np.stack([1 - v - w, v, w], -1))
    bc = np.nan_to_num(bc)
    return a * bc[:, :1] + b * bc[:, 1:2] + c * bc[:, 2:], bc


def uv_check(cand, cand_chunks, retex, retex_chunks, texture_size):
    """Project each candidate triangle centroid onto the retexture surface; compare UVs."""
    Pc, Uc, Tc = _mesh(cand, cand_chunks); Pr, Ur, Tr = _mesh(retex, retex_chunks)
    A0, B = _norm(Pc), _norm(Pr)
    sub = A0[np.random.default_rng(0).choice(len(A0), min(3000, len(A0)), replace=False)]
    best = None
    for yaw in range(4):
        for mir in (1, -1):
            th = yaw * np.pi / 2
            R = np.array([[np.cos(th), 0, np.sin(th)], [0, 1, 0], [-np.sin(th), 0, np.cos(th)]])
            Bt = (B * [mir, 1, 1]) @ R.T
            score = _knn(sub, Bt, 1)[1].mean()
            if best is None or score < best[0]:
                best = (score, yaw, mir, Bt)
    score, yaw, mir, Bt = best
    A = A0[Tc].mean(1); Ua = Uc[Tc].mean(1)          # centroids sit inside one UV island
    order = np.argsort(Tr.ravel(), kind='stable'); tri_of = order // 3
    starts = np.searchsorted(Tr.ravel()[order], np.arange(len(Bt) + 1))
    nb, _ = _knn(A, Bt, 6)
    cv, ct = [], []
    for i in range(len(A)):
        ts = np.unique(np.concatenate([tri_of[starts[v]:starts[v + 1]] for v in nb[i]]))
        cv.append(np.full(len(ts), i)); ct.append(ts)
    cv = np.concatenate(cv); ct = np.concatenate(ct)
    q, bc = _closest_on_tri(A[cv], Bt[Tr[ct, 0]], Bt[Tr[ct, 1]], Bt[Tr[ct, 2]])
    dist = np.linalg.norm(q - A[cv], axis=1)
    uvq = Ur[Tr[ct, 0]] * bc[:, :1] + Ur[Tr[ct, 1]] * bc[:, 1:2] + Ur[Tr[ct, 2]] * bc[:, 2:]
    uverr = np.linalg.norm(uvq - Ua[cv], axis=1)
    res_d = np.full(len(A), np.inf); np.minimum.at(res_d, cv, dist)
    ok = dist <= res_d[cv] + 1e-6
    res_uv = np.full(len(A), np.inf); np.minimum.at(res_uv, cv[ok], uverr[ok])
    tex = 1.0 / texture_size
    # Outliers: are they decimation-collapsed triangles that already straddle UV islands in the candidate?
    edge = np.max(np.linalg.norm(Uc[Tc] - np.roll(Uc[Tc], 1, axis=1), axis=2), axis=1) / tex
    bad = res_uv > 4 * tex
    return {'method': 'candidate triangle centroids (decimated mesh) projected to the nearest retexture triangle after '
                      'bbox normalisation and best of 8 yaw/mirror alignments; interpolated UV compared to centroid UV',
            'candidate_triangles': int(len(A)), 'retexture_vertices': int(len(B)),
            'alignment': {'yaw_deg': int(yaw * 90), 'mirror_x': bool(mir == -1), 'mean_vertex_nn_dist_over_height': round(float(score), 6)},
            'surface_dist_over_height_p50_p99_max': [round(float(x), 6) for x in np.percentile(res_d, [50, 99, 100])],
            'uv_error_texels_p50_p95_p99': [round(float(x) / tex, 3) for x in np.percentile(res_uv, [50, 95, 99])],
            'pct_within_1_texel': round(100 * float((res_uv <= tex).mean()), 3),
            'pct_within_4_texels': round(100 * float((res_uv <= 4 * tex).mean()), 3),
            'longest_uv_edge_texels_p50': {'within_4_texels': round(float(np.median(edge[~bad])), 2),
                                           'outliers': round(float(np.median(edge[bad])), 2) if bad.any() else None},
            'outliers_with_uv_edge_over_64_texels_pct': round(100 * float((edge[bad] > 64).mean()), 2) if bad.any() else None}


def main():
    species = sys.argv[1]
    cfg = SPECIES[species]
    models = ROOT / f'assets/creatures/tetherbound/{species}/candidate_multiview/models'
    cand_path = models / f'creature_{species}_multiview.glb'
    out_path = models / f'creature_{species}_multiview_retex.glb'
    report_path = ROOT / f'assets/creatures/tetherbound/{species}/candidate_multiview/source/retex/apply-report.json'
    retex_dir = ROOT / cfg['retex']; retex_path = retex_dir / 'model.glb'
    recovered_path = ROOT / cfg['recovered']

    base, base_chunks = read_glb(cand_path)
    cand_json = json.loads(json.dumps(base)); cand_views = [view_bytes(base, base_chunks, i) for i in range(len(base['bufferViews']))]
    retex, retex_chunks = read_glb(retex_path)
    recovered, recovered_chunks = read_glb(recovered_path)

    # Atlas identity: the candidate samples the recovered model's own texture atlas.
    cand_atlas = image_of(base, base_chunks, base['materials'][0]['pbrMetallicRoughness']['baseColorTexture']['index'])[0]
    rec_atlas = image_of(recovered, recovered_chunks, recovered['materials'][0]['pbrMetallicRoughness']['baseColorTexture']['index'])[0]
    if hashlib.sha256(cand_atlas).digest() != hashlib.sha256(rec_atlas).digest():
        sys.exit('candidate atlas is not the recovered model atlas; refusing')
    if len(base['materials']) != 1 or len(base['images']) != 1:
        sys.exit('expected one material and one image on the candidate')

    src = retex['materials'][0]; src_pbr = src['pbrMetallicRoughness']
    mat = base['materials'][0]; pbr = mat['pbrMetallicRoughness']
    if 'base_color_png' in cfg:
        # Embedded losslessly: JPEG ringing pushes ~1% of the clamped hue-28 texels back past the red threshold.
        bc_blob, bc_mime, bc_source = (retex_dir / cfg['base_color_png']).read_bytes(), 'image/png', cfg['base_color_png'] + ' (PNG, lossless)'
    else:
        bc_blob, bc_mime = image_of(retex, retex_chunks, src_pbr['baseColorTexture']['index']); bc_source = 'model.glb embedded base colour'
    bc_rgb = np.asarray(Image.open(io.BytesIO(bc_blob)).convert('RGB'))
    pbr['baseColorTexture'] = {'index': put_image(base, base_chunks, pbr['baseColorTexture']['index'], bc_blob, bc_mime, 'base_color')}
    blob, mime = image_of(retex, retex_chunks, src_pbr['metallicRoughnessTexture']['index'])
    pbr['metallicRoughnessTexture'] = {'index': put_image(base, base_chunks, None, blob, mime, 'metallic_roughness')}
    pbr['metallicFactor'] = src_pbr.get('metallicFactor', 1.0); pbr['roughnessFactor'] = src_pbr.get('roughnessFactor', 1.0)
    blob, mime = image_of(retex, retex_chunks, src['normalTexture']['index'])
    mat['normalTexture'] = {'index': put_image(base, base_chunks, None, blob, mime, 'normal')}

    # Mesh, skin, rig and clips unchanged: same JSON and same bytes in every non-image buffer view.
    image_views = {cand_json['images'][0]['bufferView']}
    for key in KEPT:
        if base.get(key) != cand_json.get(key):
            sys.exit(f'{key} changed; refusing')
    for i, data in enumerate(cand_views):
        if i not in image_views and view_bytes(base, base_chunks, i) != data:
            sys.exit(f'bufferView {i} bytes changed; refusing')
    write_glb(out_path, base, base_chunks)

    report = {'species': species,
              'candidate': str(cand_path.relative_to(ROOT)), 'candidate_sha256': hashlib.sha256(cand_path.read_bytes()).hexdigest(),
              'retexture': str(retex_path.relative_to(ROOT)), 'retexture_sha256': hashlib.sha256(retex_path.read_bytes()).hexdigest(),
              'output': str(out_path.relative_to(ROOT)), 'output_sha256': hashlib.sha256(out_path.read_bytes()).hexdigest(),
              'atlas_identity': 'candidate Image_0 is byte-identical to the recovered model texture (sha256 %s)' % hashlib.sha256(rec_atlas).hexdigest(),
              'base_color_source': bc_source, 'base_color_red_pink_rust_fraction': round(red_fraction(bc_rgb), 6),
              'kept_unchanged': KEPT + ['all non-image bufferView bytes (%d views)' % (len(cand_views) - 1)],
              'material': mat, 'animations': [a.get('name') for a in base.get('animations', [])]}
    if '--uv-check' in sys.argv:
        size = Image.open(io.BytesIO(bc_blob)).size[0]
        report['uv_check'] = uv_check(cand_json, read_glb(cand_path)[1], retex, retex_chunks, size)
    elif report_path.exists():
        old = json.loads(report_path.read_text())
        if 'uv_check' in old:
            report['uv_check'] = old['uv_check']
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k != 'material'}, indent=1))


if __name__ == '__main__':
    main()
