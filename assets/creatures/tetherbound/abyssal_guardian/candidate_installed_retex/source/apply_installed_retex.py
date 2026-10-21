#!/usr/bin/env python3
"""Installed-rig Meshy retexture candidates (round r6): Meshy maps on a copy of the installed rigged GLB.

    python3 assets/creatures/tetherbound/<species>/candidate_installed_retex/source/apply_installed_retex.py <species>
    ... <species> r7   (round r7: masked grade of the r6 maps, see main_r7)
    ... <species> r8   (round r8, abyssal_guardian and voltarach: see main_r8)

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
    'galewisp': {
        'installed': 'assets/creatures/tetherbound/galewisp/models/creature_galewisp_lod0.glb',
        'run': 'gw_r2-01a15d69-55f9-74d8-ae2f-ffcdc0fedb75',
        'hue_moves': [],
        'emissive': None,
        'roughness_floor': None,
        'safe_hue': 40.0,
    },
    'voltarach': {
        'installed': 'assets/creatures/tetherbound/voltarach/candidate/models/creature_voltarach_native.glb',
        'run': None,
        # brighter, more saturated blue eye cluster
        'hue_moves': [{'hue': [210, 260], 'sat_min': 0.45, 'val_min': 0.25, 'to_hue': 232.0, 'sat_lo': 0.75, 'val_mul': 1.6, 'val_add': 0.12}],
        'emissive': {'hue': [210, 260], 'sat_min': 0.45, 'val_min': 0.40, 'gain': 1.6},
        'roughness_floor': None,
        'safe_hue': 40.0,
    },
    'meadowhart': {
        'installed': 'assets/creatures/tetherbound/meadowhart/candidate/models/creature_meadowhart_native.glb',
        'run': 'mh_r1-01a15d6e-7bd9-75d6-b7cb-585227698c05',
        'hue_moves': [],
        'emissive': None,
        'roughness_floor': None,
        'safe_hue': 28.0,
    },
    'aeriex': {
        'installed': 'assets/creatures/tetherbound/aeriex/candidate/models/creature_aeriex_native.glb',
        'run': 'ae_r1-01a15d6f-cd08-7625-bbf7-c4982172c989',
        'hue_moves': [],
        'emissive': None,
        'roughness_floor': None,
        'safe_hue': 28.0,
    },
    'mirejaw': {
        'installed': 'assets/creatures/tetherbound/mirejaw/candidate/models/creature_mirejaw_native.glb',
        'run': 'mj_r1-01a15d79-4006-7474-862d-8f9d478d8391',
        # pink fronds/mouth that drift toward crimson are pulled to orchid pink (hue 312)
        'hue_moves': [{'hue': [318, 352], 'sat_min': 0.20, 'val_min': 0.20, 'to_hue': 312.0}],
        # the tail-tip tuft (bind-pose z < -3.5; the head is +z) is painted the dark mottled skin
        # (and stray pink on the feet, bind-pose height y < 0.6) is painted the dark mottled skin
        'region_recolor': [{'axis': 2, 'max': -3.0, 'hue': [280, 352], 'sat_min': 0.12, 'to_hue': 225.0, 'to_sat': 0.18, 'val_mul': 0.45},
                           {'axis': 1, 'max': 0.6, 'hue': [280, 352], 'sat_min': 0.12, 'to_hue': 225.0, 'to_sat': 0.18, 'val_mul': 0.45}],
        'emissive': None,
        'roughness_floor': None,
        'safe_hue': 312.0,
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


def _acc(gltf, chunks, i):
    a = gltf['accessors'][i]; v = gltf['bufferViews'][a['bufferView']]
    n = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[a['type']]
    dt = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}[a['componentType']]
    size = n * np.dtype(dt).itemsize; stride = v.get('byteStride', 0) or size
    data = view_bytes(gltf, chunks, a['bufferView']); off = a.get('byteOffset', 0)
    rows = [data[off + k * stride: off + k * stride + size] for k in range(a['count'])]
    return np.frombuffer(b''.join(rows), dt).reshape(a['count'], n).astype(np.float64 if dt == np.float32 else np.int64)


def position_map(gltf, chunks, size):
    """Rasterize the UV triangles: per-texel bind-pose position and a coverage mask."""
    P, U, T, base = [], [], [], 0
    for mesh in gltf['meshes']:
        for prim in mesh['primitives']:
            pos = _acc(gltf, chunks, prim['attributes']['POSITION']); uv = _acc(gltf, chunks, prim['attributes']['TEXCOORD_0'])
            P.append(pos); U.append(uv); T.append(_acc(gltf, chunks, prim['indices']).reshape(-1, 3) + base); base += len(pos)
    P, U, T = np.vstack(P), np.vstack(U), np.vstack(T)
    out = np.zeros((size, size, 3), np.float32); cov = np.zeros((size, size), bool)
    tx = U[:, 0] * size - 0.5; ty = U[:, 1] * size - 0.5
    for t in T:
        x = tx[t]; y = ty[t]
        x0 = max(int(np.floor(x.min())), 0); x1 = min(int(np.ceil(x.max())), size - 1)
        y0 = max(int(np.floor(y.min())), 0); y1 = min(int(np.ceil(y.max())), size - 1)
        if x1 < x0 or y1 < y0:
            continue
        X, Y = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
        d = (y[1] - y[2]) * (x[0] - x[2]) + (x[2] - x[1]) * (y[0] - y[2])
        if abs(d) < 1e-12:
            continue
        a = ((y[1] - y[2]) * (X - x[2]) + (x[2] - x[1]) * (Y - y[2])) / d
        b = ((y[2] - y[0]) * (X - x[2]) + (x[0] - x[2]) * (Y - y[2])) / d; c = 1 - a - b
        e = -0.6 / max(abs(d), 1); m = (a >= e) & (b >= e) & (c >= e)
        out[Y[m], X[m]] = a[m, None] * P[t[0]] + b[m, None] * P[t[1]] + c[m, None] * P[t[2]]
        cov[Y[m], X[m]] = True
    return out, cov


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
    for k, rr in enumerate(prof.get('region_recolor', [])):
        pos, cov = prof['_posmap']
        h, s, v = hsv(out)
        ax = pos[..., rr['axis']]
        region = cov & (ax >= rr.get('min', -1e9)) & (ax <= rr.get('max', 1e9))
        # grow into the UV gutter so bilinear/mip samples at island edges match
        grow = np.asarray(Image.fromarray((region * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(9))) > 0
        region = region | (grow & ~cov)
        m = region & in_hue(h, *rr['hue']) & (s >= rr.get('sat_min', 0))
        tgt = from_hsv(np.full_like(h, rr['to_hue']), np.full_like(s, rr['to_sat']), np.clip(v * rr['val_mul'], 0, 1))
        out = np.where(m[..., None], tgt, out)
        stats['region_recolor_%d_texels_pct' % k] = round(100 * float(m.mean()), 3)
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


# ---------------------------------------------------------------------------------------------
# Round r7: a deterministic masked grade of the r6 candidate's own maps (no Meshy task).
#     python3 .../apply_installed_retex.py <species> r7
# The r6 output GLB supplies base colour, metallic-roughness, normal and emissive; the regions are
# found per texel from the installed mesh's bind-pose position, normal and skin weights, so only the
# named regions change. Same refusal checks as r6 (mesh, skin, rig, clips byte-identical).
R6_OUT = 'assets/creatures/tetherbound/{sp}/candidate_installed_retex/models/creature_{sp}_installed_retex_r6_lod0.glb'
PROFILES_R7 = {
    'abyssal_guardian': {
        # cream throat, lower jaw, belly and tail underside (board 35); glow line kept and moved to
        # the upper flank beside the spine on the torso
        'cream_rgb': [0.93, 0.89, 0.80],
        'torso_ny': [0.12, -0.18],         # smoothstep on normal.y for torso/tail underside + lower flank
        'throat': [-0.12, 0.22],           # neck: smoothstep on normal.z + 0.6 * max(0, -normal.y)
        'neck_z': [0.45, 0.60],            # the neck base (spine-weighted) counts as neck from here
        'jaw_ny': [-0.10, -0.40],          # head: smoothstep on normal.y for the lower jaw
        'fin_groups': ['wing', 'leg'],     # flippers keep their blue and spots
        # tried in r7 and left off: moving the flank line onto the upper flank by grade smeared the
        # spine fins and left grey patches; the r6 line is kept as it is
        'line_move': None,
        'emissive_strength': None,
        'safe_hue': 210.0,
    },
    'voltarach': {
        # bigger glowing blue eye patch + soft halo around the eye cluster (board 45), material only
        'eye_hue': [210, 260], 'eye_sat_min': 0.45, 'eye_val_min': 0.30,
        'head_box': {'z_min': 2.0, 'y_min': 1.3, 'n_z_min': -0.05},
        'core_m': 0.12, 'halo_m': 0.40, 'halo_mix': 0.60,
        'eye_rgb': [0.23, 0.32, 1.0], 'highlight_rgb': [0.72, 0.80, 1.0],
        'emissive_core': 1.0, 'emissive_halo': 0.55,
        'emissive_strength': 2.5,
        'safe_hue': 40.0,
    },
}


def attr_maps(gltf, chunks, size, groups=()):
    """Rasterize bind-pose position, normal and summed skin weight per joint-name prefix group."""
    names = [gltf['nodes'][j].get('name', '') for j in gltf['skins'][0]['joints']] if gltf.get('skins') else []
    rows, U, T, base = [], [], [], 0
    for mesh in gltf['meshes']:
        for prim in mesh['primitives']:
            a = prim['attributes']
            pos = _acc(gltf, chunks, a['POSITION']); nrm = _acc(gltf, chunks, a['NORMAL'])
            cols = [pos, nrm]
            if groups:
                J = _acc(gltf, chunks, a['JOINTS_0']); W = _acc(gltf, chunks, a['WEIGHTS_0']).astype(np.float64)
                if W.max() > 1.5:
                    W = W / W.max()
                for g in groups:
                    ids = [i for i, n in enumerate(names) if n.startswith(g)]
                    cols.append((W * np.isin(J, ids)).sum(1, keepdims=True))
            rows.append(np.hstack(cols)); U.append(_acc(gltf, chunks, a['TEXCOORD_0']))
            T.append(_acc(gltf, chunks, prim['indices']).reshape(-1, 3) + base); base += len(pos)
    R, U, T = np.vstack(rows), np.vstack(U), np.vstack(T)
    out = np.zeros((size, size, R.shape[1]), np.float32); cov = np.zeros((size, size), bool)
    tx = U[:, 0] * size - 0.5; ty = U[:, 1] * size - 0.5
    for t in T:
        x = tx[t]; y = ty[t]
        x0 = max(int(np.floor(x.min())), 0); x1 = min(int(np.ceil(x.max())), size - 1)
        y0 = max(int(np.floor(y.min())), 0); y1 = min(int(np.ceil(y.max())), size - 1)
        if x1 < x0 or y1 < y0:
            continue
        X, Y = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
        d = (y[1] - y[2]) * (x[0] - x[2]) + (x[2] - x[1]) * (y[0] - y[2])
        if abs(d) < 1e-12:
            continue
        a = ((y[1] - y[2]) * (X - x[2]) + (x[2] - x[1]) * (Y - y[2])) / d
        b = ((y[2] - y[0]) * (X - x[2]) + (x[0] - x[2]) * (Y - y[2])) / d; c = 1 - a - b
        e = -0.6 / max(abs(d), 1); m = (a >= e) & (b >= e) & (c >= e)
        out[Y[m], X[m]] = a[m, None] * R[t[0]] + b[m, None] * R[t[1]] + c[m, None] * R[t[2]]
        cov[Y[m], X[m]] = True
    n = out[..., 3:6]; out[..., 3:6] = n / (np.linalg.norm(n, axis=-1, keepdims=True) + 1e-9)
    return out, cov


def smooth(x, a, b):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def gutter(w, cov, k=9):
    """Grow a weight map into the UV gutter so bilinear/mip samples at island edges match."""
    img = Image.fromarray((np.clip(w, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(k))
    return np.where(cov, w, np.asarray(img).astype(np.float32) / 255)


def _box(x, k, axis):
    c = np.cumsum(np.pad(x, [(k + 1, k) if a == axis else (0, 0) for a in range(x.ndim)], mode='edge'), axis=axis)
    hi = np.take(c, np.arange(2 * k + 1, c.shape[axis]), axis=axis)
    lo = np.take(c, np.arange(0, c.shape[axis] - 2 * k - 1), axis=axis)
    return (hi - lo) / (2 * k + 1)


def blur(x, r):
    """Approximate Gaussian blur (three box passes per axis) of a float map."""
    k = max(1, int(round(r * 0.87)))
    x = x.astype(np.float32)
    for _ in range(3):
        x = _box(_box(x, k, 0), k, 1)
    return x


def r7_abyssal_guardian(rgb, emis, maps, cov, prof, stats):
    pos, n = maps[..., :3], maps[..., 3:6]
    fin, head, neck = maps[..., 6], maps[..., 7], maps[..., 8]
    body = np.clip(1 - fin * 1.6, 0, 1)
    neck = np.clip(np.maximum(neck, smooth(pos[..., 2], *prof['neck_z'])) - head, 0, 1)
    torso = np.clip(1 - head - neck, 0, 1)
    glow = emis.max(-1)
    # back height per 2 cm slice (median of up-facing body texels): spine fins stand above it and
    # keep their blue and glowing tips
    zb = np.clip(((pos[..., 2] + 1.0) / 0.02).astype(int), 0, 100)
    up = cov & (torso > 0.6) & (body > 0.6) & (n[..., 1] > 0.9)
    top = np.full(101, 9.0, np.float32)
    for k in np.unique(zb[up]):
        top[k] = np.median(pos[..., 1][up & (zb == k)])
    below_back = smooth(top[zb] - pos[..., 1], 0.0, 0.02)
    w = torso * below_back * smooth(n[..., 1], *prof['torso_ny'])
    w = np.maximum(w, neck * smooth(n[..., 2] + 0.6 * np.maximum(0, -n[..., 1]), *prof['throat']))
    w = np.maximum(w, head * smooth(n[..., 1], *prof['jaw_ny']))
    w = w * body * cov
    # the glow line and spots stay as they are (cream fills around them)
    w = w * (1 - smooth(glow, 0.10, 0.30))
    w = gutter(w, cov)
    lum = rgb.mean(-1)
    detail = np.clip(lum / (blur(lum, 6) + 1e-3), 0.80, 1.18)       # keep the hex-scale relief
    cream = np.array(prof['cream_rgb'], np.float32)[None, None, :] * detail[..., None]
    out = rgb * (1 - w[..., None]) + cream * w[..., None]
    stats['cream_texels_pct'] = round(100 * float((w > 0.5).mean()), 3)
    lm = prof.get('line_move')
    if lm:
        zr = (pos[..., 2] >= lm['z_range'][0]) & (pos[..., 2] <= lm['z_range'][1])
        trunk = cov & zr & (torso > 0.6) & (body > 0.6)
        # back height per 2 cm slice (median of up-facing body texels); spine fins sit above it and
        # keep their glowing tips
        zb = np.clip(((pos[..., 2] - lm['z_range'][0]) / 0.02).astype(int), 0, 200)
        up = trunk & (n[..., 1] > 0.9)
        top = np.full(201, 9.0, np.float32)
        for k in np.unique(zb[up]):
            top[k] = np.median(pos[..., 1][up & (zb == k)])
        trunk = trunk & (pos[..., 1] <= top[zb] - 0.004)
        # old flank line: glowing texels on the torso side below the spine band
        old = trunk & (glow > 0.12) & (n[..., 1] < lm['old_ny_max']) & (np.abs(n[..., 0]) > 0.35)
        oldw = np.clip(blur(old.astype(np.float32), 1.5) * 2.0, 0, 1) * trunk
        keep = (~old) & cov
        fill = blur(out * keep[..., None], 7) / (blur(keep.astype(np.float32), 7)[..., None] + 1e-4)
        dark = np.clip(fill, 0, 1)
        out = out * (1 - oldw[..., None]) + dark * oldw[..., None]
        emis = emis * (1 - oldw[..., None])
        # new line: a narrow band on each upper flank beside the spine fins
        band = smooth(n[..., 1], lm['new_ny'][0] - 0.05, lm['new_ny'][0]) * (1 - smooth(n[..., 1], lm['new_ny'][1], lm['new_ny'][1] + 0.05))
        band = band * trunk * (np.abs(n[..., 0]) > 0.2)
        band = gutter(band, cov, 5)
        cyan = np.array([0.42, 0.93, 1.0], np.float32)[None, None, :]
        out = out * (1 - band[..., None]) + cyan * band[..., None]
        emis = np.maximum(emis, np.clip(cyan * lm['gain'], 0, 1) * band[..., None])
        stats['line_removed_texels_pct'] = round(100 * float(old.mean()), 3)
        stats['line_added_texels_pct'] = round(100 * float((band > 0.5).mean()), 3)
    return out, emis


def r7_voltarach(rgb, emis, maps, cov, prof, stats):
    pos, n = maps[..., :3], maps[..., 3:6]
    hb = prof['head_box']
    head = cov & (pos[..., 2] >= hb['z_min']) & (pos[..., 1] >= hb['y_min']) & (n[..., 2] >= hb['n_z_min'])
    h, s, v = hsv(rgb)
    eye = head & in_hue(h, *prof['eye_hue']) & (s >= prof['eye_sat_min']) & (v >= prof['eye_val_min'])
    E = pos[eye]
    E = E[:: max(1, len(E) // 4000)]
    idx = np.nonzero(head)
    P = pos[idx]
    dist = np.full(len(P), 1e9, np.float32)
    for k in range(0, len(P), 20000):
        chunk = P[k:k + 20000]
        dist[k:k + 20000] = np.sqrt(((chunk[:, None, :] - E[None, :, :]) ** 2).sum(-1)).min(1)
    D = np.full(cov.shape, 1e9, np.float32); D[idx] = dist
    D[eye] = 0.0
    core = 1 - smooth(D, prof['core_m'] * 0.7, prof['core_m'])
    halo = (1 - smooth(D, prof['core_m'], prof['halo_m'])) ** 2 * (1 - core)
    core = gutter(core, cov, 5); halo = gutter(halo, cov, 5)
    eye_c = np.array(prof['eye_rgb'], np.float32)[None, None, :]
    hi_c = np.array(prof['highlight_rgb'], np.float32)[None, None, :]
    # each orb saturated blue, its own brightest texels a pale specular dot, a dimmer halo around
    spec = gutter(blur((eye * smooth(v, 0.80, 0.98)).astype(np.float32), 1.0), cov, 5)
    core_col = eye_c * (1 - 0.6 * spec[..., None]) + hi_c * (0.6 * spec[..., None])
    hm = prof['halo_mix']
    out = rgb * (1 - halo[..., None] * hm) + eye_c * 0.6 * (halo[..., None] * hm)
    out = out * (1 - core[..., None]) + core_col * core[..., None]
    e = core_col * prof['emissive_core'] * core[..., None] + eye_c * prof['emissive_halo'] * halo[..., None]
    emis = np.maximum(emis, np.clip(e, 0, 1))
    stats['eye_texels_pct'] = round(100 * float(eye.mean()), 3)
    stats['eye_core_texels_pct'] = round(100 * float((core > 0.5).mean()), 3)
    stats['eye_halo_texels_pct'] = round(100 * float((halo > 0.2).mean()), 3)
    return out, emis


def main_r7(sp):
    prof = PROFILES_R7[sp]; tag = 'r7'
    installed = ROOT / PROFILES[sp]['installed']
    src_path = ROOT / R6_OUT.format(sp=sp)
    cdir = OUT_ROOT / f'assets/creatures/tetherbound/{sp}/candidate_installed_retex'
    out_path = cdir / f'models/creature_{sp}_installed_retex_{tag}_lod0.glb'
    report_path = cdir / f'source/apply-report-{tag}.json'
    base, base_chunks = read_glb(installed)
    original, original_chunks = read_glb(installed)
    src, src_chunks = read_glb(src_path)
    uv_a, uv_b = uv_set(base, base_chunks), uv_set(src, src_chunks)
    if uv_a != uv_b:
        sys.exit('UV sets differ; refusing to transfer maps')
    smat = src['materials'][0]; spbr = smat['pbrMetallicRoughness']
    mat = base['materials'][0]; pbr = mat.setdefault('pbrMetallicRoughness', {})
    blob, _ = image_of(src, src_chunks, spbr['baseColorTexture']['index'])
    rgb = np.asarray(Image.open(io.BytesIO(blob)).convert('RGB')).astype(np.float32) / 255
    blob, _ = image_of(src, src_chunks, smat['emissiveTexture']['index'])
    emis = np.asarray(Image.open(io.BytesIO(blob)).convert('RGB')).astype(np.float32) / 255
    groups = ('wing', 'leg', 'head', 'neck') if sp == 'abyssal_guardian' else ()
    maps, cov = attr_maps(base, base_chunks, rgb.shape[0], groups)
    if sp == 'abyssal_guardian':
        maps = np.concatenate([maps[..., :6], maps[..., 6:7] + maps[..., 7:8], maps[..., 8:10]], -1)
    stats = {}
    out, emis = globals()['r7_' + sp](rgb, emis, maps, cov, prof, stats)
    out = np.clip(out, 0, 1)
    h2, s2, v2 = hsv(out)
    rc = ((h2 < 15) | (h2 > 320)) & (s2 > CLAMP_SAT) & (v2 > CLAMP_VAL)
    out[rc] = from_hsv(np.full(int(rc.sum()), prof['safe_hue']), np.minimum(s2[rc], 0.55), v2[rc])
    stats['red_clamped_texels'] = int(rc.sum())
    gimg = Image.fromarray((out * 255).round().clip(0, 255).astype(np.uint8))
    pbr['baseColorTexture'] = {'index': put_image(base, base_chunks, pbr.get('baseColorTexture', {}).get('index'), png(gimg), 'image/png', 'base_color_' + tag)}
    blob, mime = image_of(src, src_chunks, spbr['metallicRoughnessTexture']['index'])
    pbr['metallicFactor'] = spbr.get('metallicFactor', 0.0); pbr['roughnessFactor'] = spbr.get('roughnessFactor', 1.0)
    pbr['metallicRoughnessTexture'] = {'index': put_image(base, base_chunks, pbr.get('metallicRoughnessTexture', {}).get('index'), blob, mime, 'metallic_roughness_' + tag)}
    blob, mime = image_of(src, src_chunks, smat['normalTexture']['index'])
    mat['normalTexture'] = {'index': put_image(base, base_chunks, mat.get('normalTexture', {}).get('index'), blob, mime, 'normal_' + tag)}
    eimg = Image.fromarray((np.clip(emis, 0, 1) * 255).round().astype(np.uint8))
    mat['emissiveTexture'] = {'index': put_image(base, base_chunks, mat.get('emissiveTexture', {}).get('index'), png(eimg), 'image/png', 'emissive_' + tag)}
    mat['emissiveFactor'] = [1.0, 1.0, 1.0]
    if prof.get('emissive_strength'):
        mat.setdefault('extensions', {})['KHR_materials_emissive_strength'] = {'emissiveStrength': prof['emissive_strength']}
        used = base.setdefault('extensionsUsed', [])
        if 'KHR_materials_emissive_strength' not in used:
            used.append('KHR_materials_emissive_strength')
    write_glb(out_path, base, base_chunks)
    o, o_chunks = read_glb(out_path)
    for key in ('meshes', 'accessors', 'skins', 'nodes', 'animations', 'scenes'):
        if o.get(key) != original.get(key):
            sys.exit('%s changed; refusing' % key)
    skip = image_views(original)
    non_image = [i for i in range(len(original['bufferViews'])) if i not in skip]
    for i in non_image:
        if view_bytes(o, o_chunks, i) != view_bytes(original, original_chunks, i):
            sys.exit('bufferView %d changed; refusing' % i)
    gr = (out * 255).round().astype(np.uint8).astype(np.float32) / 255
    report = {'species': sp, 'round': tag, 'installed': PROFILES[sp]['installed'], 'installed_sha256': hashlib.sha256(installed.read_bytes()).hexdigest(),
              'source_r6': str(src_path.relative_to(ROOT)), 'source_r6_sha256': hashlib.sha256(src_path.read_bytes()).hexdigest(),
              'output': str(out_path.relative_to(OUT_ROOT)), 'output_sha256': hashlib.sha256(out_path.read_bytes()).hexdigest(),
              'unique_uvs': len(uv_a), 'uv_sets_identical': True, 'profile': prof, 'grade': stats,
              'red_metric_strict_hue_lt15_gt320_sat_gt030_val_gt020_pct': {'r6': round(100 * float(red_mask(rgb).mean()), 4), 'candidate': round(100 * float(red_mask(gr).mean()), 4)},
              'kept_unchanged': ['meshes', 'accessors', 'skins', 'nodes', 'animations', 'scenes', 'all non-image bufferView bytes', 'normal and metallic-roughness maps (r6)'],
              'non_image_buffer_views_byte_identical': len(non_image),
              'material': o['materials'][0], 'animations': [a.get('name') for a in o.get('animations', [])]}
    report_path.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k not in ('material', 'profile')}, indent=1))


# ---------------------------------------------------------------------------------------------
# Round r8.
#     python3 .../apply_installed_retex.py abyssal_guardian r8
#     python3 .../apply_installed_retex.py voltarach r8
# abyssal_guardian: the r6 maps plus a cream (#EDE3CC) throat and underside. The cream region is
# r6's own pale underside (low saturation, bright, not glowing) united with a geometric underside
# (downward-facing torso/neck, lower jaw), never on up-facing surfaces (the neck-chest join's upper
# side stays blue). Its edge is feathered by 3D signed distance on the bind-pose surface (several
# cm, not texels), warmed and darkened toward #E2D6BA where it meets the blue, and broken up along
# the hex-scale luminance so no flat or bright band forms; inside r6's pale edge the blue is
# restored from nearby blue texels so the gradient runs both ways. Glow, normal and roughness maps
# are r6's, untouched.
# voltarach: base colour, metallic-roughness and normal from a Meshy retexture (original UVs) of the
# installed GLB with a drafted dark-carapace style image, then the r7 eye treatment on top (eye
# patch, halo, emissive strength 2.5, more saturated so it stays blue) and the red clamp.
RAW_R8 = 'assets_raw/{sp}/meshy-r8-1021/{run}/model.glb'
PROFILES_R8 = {
    'abyssal_guardian': {
        'cream_core_rgb': [0.929, 0.890, 0.800],   # #EDE3CC
        'cream_edge_rgb': [0.886, 0.839, 0.729],   # #E2D6BA
        'edge_darken': 0.90,                       # edge colour value scale at the blue side
        'pale_sat_max': 0.22, 'pale_val_min': 0.60,
        'geo_ny': [-0.40, -0.65],                  # geometric underside core: smoothstep on normal.y
        'jaw_ny': [-0.15, -0.45],
        'up_ny_max': 0.15,                         # no cream where normal.y is above this
        'feather_in': 0.020, 'feather_out': 0.028, # bind-pose units (1 unit ~ 8.8 m at 7.2 m height)
        'scale_breakup': 0.25,
        'lo_res': 1024,
        'safe_hue': 210.0,
    },
    'voltarach': {
        'run': 'vo_r8-01a15e00-e429-721e-ae9a-ceb86b1ec766',
        'eye': dict(PROFILES_R7['voltarach'], eye_rgb=[0.12, 0.17, 1.0], highlight_rgb=[0.36, 0.46, 1.0],
                    emissive_core=0.62, emissive_halo=0.40),
        'safe_hue': 40.0,
    },
}


def _nearest(P, Q, chunk=4000):
    """Distance from each row of P to its nearest row of Q (brute force, chunked)."""
    out = np.full(len(P), 1e9, np.float32)
    if len(Q) == 0 or len(P) == 0:
        return out
    Q = Q.astype(np.float32); q2 = (Q * Q).sum(1)
    for k in range(0, len(P), chunk):
        c = P[k:k + chunk].astype(np.float32)
        d2 = (c * c).sum(1)[:, None] + q2[None, :] - 2 * c @ Q.T
        out[k:k + chunk] = np.sqrt(np.maximum(d2.min(1), 0))
    return out


def r8_abyssal_guardian(rgb, emis, base, base_chunks, prof, stats):
    size = rgb.shape[0]; lo = prof['lo_res']; f = size // lo
    maps, cov = attr_maps(base, base_chunks, size, ('wing', 'leg', 'head', 'neck'))
    pos, n = maps[..., :3], maps[..., 3:6]
    fin, head = maps[..., 6] + maps[..., 7], maps[..., 8]
    body = np.clip(1 - fin * 1.6, 0, 1)
    glow = emis.max(-1)
    h, s, v = hsv(rgb)
    pale = cov & (s < prof['pale_sat_max']) & (v > prof['pale_val_min']) & (glow < 0.10)
    geo = np.where(head > 0.5, smooth(n[..., 1], *prof['jaw_ny']), smooth(n[..., 1], *prof['geo_ny']))
    M = cov & (body > 0.5) & (n[..., 1] <= prof['up_ny_max']) & (glow < 0.10) & (pale | (geo > 0.5))

    # signed 3D distance to the region edge on a lower-resolution raster, then upsampled
    def pool(x):
        return x.reshape(lo, f, lo, f).mean((1, 3))
    covl = pool(cov.astype(np.float32)) > 0.5
    Ml = (pool(M.astype(np.float32)) > 0.5) & covl
    bodyl = (pool(body * cov) > 0.5) & covl
    posl = pos.reshape(lo, f, lo, f, 3).mean((1, 3))
    rng = np.random.default_rng(8)

    def sample(mask, k=9000):
        P = posl[mask]
        return P[rng.choice(len(P), min(k, len(P)), replace=False)] if len(P) else P
    cell = max(prof['feather_in'], prof['feather_out']) * 1.6
    mn = posl[covl].min(0)
    gidx = np.floor((posl - mn) / cell).astype(int) + 1
    gidx = np.maximum(gidx, 0)
    gshape = gidx[covl].max(0) + 2

    def near(src_mask, mask):
        g = np.zeros(gshape, bool)
        i = gidx[src_mask]; g[i[:, 0], i[:, 1], i[:, 2]] = True
        for ax in range(3):
            g = g | np.roll(g, 1, ax) | np.roll(g, -1, ax)
        j = np.minimum(gidx, gshape - 1)
        return mask & g[j[..., 0], j[..., 1], j[..., 2]]
    out_set = bodyl & ~Ml
    cand_out = near(Ml, out_set)
    cand_in = near(out_set, Ml)
    sd = np.where(Ml, -1.0, 1.0).astype(np.float32)
    sd[cand_out] = _nearest(posl[cand_out], sample(Ml))
    sd[cand_in] = -_nearest(posl[cand_in], sample(out_set))
    wl = 1 - smooth(sd, -prof['feather_in'], prof['feather_out'])
    wl = np.where(bodyl, wl, Ml.astype(np.float32)).astype(np.float32)
    w = np.asarray(Image.fromarray(wl, 'F').resize((size, size), Image.BILINEAR)).astype(np.float32)
    # hard limits at full resolution: body, not glowing, never up-facing
    w = w * body * cov * (1 - smooth(glow, 0.10, 0.30)) * smooth(n[..., 1], prof['up_ny_max'] + 0.10, prof['up_ny_max'] - 0.05)
    lum = rgb.mean(-1)
    detail = np.clip(lum / (blur(lum, 6) + 1e-3), 0.80, 1.18)       # hex-scale relief
    nz = np.clip((detail - 1) / 0.12, -1, 1)
    w = np.clip(w + prof['scale_breakup'] * nz * 4 * w * (1 - w), 0, 1)
    w = gutter(w, cov)
    # blue under r6's pale edge: normalised blur of the nearby non-pale body texels
    keep = (cov & ~pale & (body > 0.5) & (glow < 0.10)).astype(np.float32)
    num = blur(rgb * keep[..., None], 14); den = blur(keep, 14)[..., None]
    mean_blue = (rgb * keep[..., None]).sum((0, 1)) / max(float(keep.sum()), 1.0)
    fill = np.where(den > 0.02, num / np.maximum(den, 1e-4), mean_blue[None, None, :])
    blue = np.where(pale[..., None], np.clip(fill * detail[..., None], 0, 1), rgb)
    core = np.array(prof['cream_core_rgb'], np.float32); edge = np.array(prof['cream_edge_rgb'], np.float32)
    t = smooth(w, 0.25, 1.0)[..., None]
    cream = (edge * (1 - t) + core * t) * (prof['edge_darken'] + (1 - prof['edge_darken']) * t) * detail[..., None]
    out = blue * (1 - w[..., None]) + cream * w[..., None]
    stats['cream_texels_pct'] = round(100 * float((w > 0.5).mean()), 3)
    stats['cream_feather_texels_pct'] = round(100 * float(((w > 0.05) & (w < 0.95)).mean()), 3)
    stats['r6_pale_texels_pct'] = round(100 * float(pale.mean()), 3)
    stats['up_facing_cream_texels_pct'] = round(100 * float(((w > 0.05) & cov & (n[..., 1] > prof['up_ny_max'] + 0.1)).mean()), 4)
    return out, emis


def main_r8(sp):
    prof = PROFILES_R8[sp]; tag = 'r8'
    installed = ROOT / PROFILES[sp]['installed']
    src_path = ROOT / (R6_OUT.format(sp=sp) if sp == 'abyssal_guardian' else RAW_R8.format(sp=sp, run=prof['run']))
    cdir = OUT_ROOT / f'assets/creatures/tetherbound/{sp}/candidate_installed_retex'
    out_path = cdir / f'models/creature_{sp}_installed_retex_{tag}_lod0.glb'
    report_path = cdir / f'source/apply-report-{tag}.json'
    base, base_chunks = read_glb(installed)
    original, original_chunks = read_glb(installed)
    src, src_chunks = read_glb(src_path)
    uv_a, uv_b = uv_set(base, base_chunks), uv_set(src, src_chunks)
    if uv_a != uv_b:
        sys.exit('UV sets differ (%d vs %d, %d shared); refusing to transfer maps' % (len(uv_a), len(uv_b), len(uv_a & uv_b)))
    smat = src['materials'][0]; spbr = smat['pbrMetallicRoughness']
    mat = base['materials'][0]; pbr = mat.setdefault('pbrMetallicRoughness', {})
    blob, _ = image_of(src, src_chunks, spbr['baseColorTexture']['index'])
    rgb = np.asarray(Image.open(io.BytesIO(blob)).convert('RGB')).astype(np.float32) / 255
    stats = {}
    if sp == 'abyssal_guardian':
        blob, _ = image_of(src, src_chunks, smat['emissiveTexture']['index'])
        emis = np.asarray(Image.open(io.BytesIO(blob)).convert('RGB')).astype(np.float32) / 255
        out, emis = r8_abyssal_guardian(rgb, emis, base, base_chunks, prof, stats)
        emis_strength = None
    else:
        maps, cov = attr_maps(base, base_chunks, rgb.shape[0])
        out, emis = r7_voltarach(rgb, np.zeros_like(rgb), maps, cov, prof['eye'], stats)
        emis_strength = prof['eye']['emissive_strength']
    out = np.clip(out, 0, 1)
    h2, s2, v2 = hsv(out)
    rc = ((h2 < 15) | (h2 > 320)) & (s2 > CLAMP_SAT) & (v2 > CLAMP_VAL)
    out[rc] = from_hsv(np.full(int(rc.sum()), prof['safe_hue']), np.minimum(s2[rc], 0.55), v2[rc])
    stats['red_clamped_texels'] = int(rc.sum())
    gimg = Image.fromarray((out * 255).round().clip(0, 255).astype(np.uint8))
    pbr['baseColorTexture'] = {'index': put_image(base, base_chunks, pbr.get('baseColorTexture', {}).get('index'), png(gimg), 'image/png', 'base_color_' + tag)}
    blob, mime = image_of(src, src_chunks, spbr['metallicRoughnessTexture']['index'])
    pbr['metallicFactor'] = spbr.get('metallicFactor', 0.0) if sp == 'abyssal_guardian' else 0.0
    pbr['roughnessFactor'] = spbr.get('roughnessFactor', 1.0)
    pbr['metallicRoughnessTexture'] = {'index': put_image(base, base_chunks, pbr.get('metallicRoughnessTexture', {}).get('index'), blob, mime, 'metallic_roughness_' + tag)}
    blob, mime = image_of(src, src_chunks, smat['normalTexture']['index'])
    mat['normalTexture'] = {'index': put_image(base, base_chunks, mat.get('normalTexture', {}).get('index'), blob, mime, 'normal_' + tag)}
    eimg = Image.fromarray((np.clip(emis, 0, 1) * 255).round().astype(np.uint8))
    mat['emissiveTexture'] = {'index': put_image(base, base_chunks, mat.get('emissiveTexture', {}).get('index'), png(eimg), 'image/png', 'emissive_' + tag)}
    mat['emissiveFactor'] = [1.0, 1.0, 1.0]
    if emis_strength:
        mat.setdefault('extensions', {})['KHR_materials_emissive_strength'] = {'emissiveStrength': emis_strength}
        used = base.setdefault('extensionsUsed', [])
        if 'KHR_materials_emissive_strength' not in used:
            used.append('KHR_materials_emissive_strength')
    write_glb(out_path, base, base_chunks)
    o, o_chunks = read_glb(out_path)
    for key in ('meshes', 'accessors', 'skins', 'nodes', 'animations', 'scenes'):
        if o.get(key) != original.get(key):
            sys.exit('%s changed; refusing' % key)
    skip = image_views(original)
    non_image = [i for i in range(len(original['bufferViews'])) if i not in skip]
    for i in non_image:
        if view_bytes(o, o_chunks, i) != view_bytes(original, original_chunks, i):
            sys.exit('bufferView %d changed; refusing' % i)
    gr = (out * 255).round().astype(np.uint8).astype(np.float32) / 255
    report = {'species': sp, 'round': tag, 'installed': PROFILES[sp]['installed'], 'installed_sha256': hashlib.sha256(installed.read_bytes()).hexdigest(),
              'source': str(src_path.relative_to(ROOT)), 'source_sha256': hashlib.sha256(src_path.read_bytes()).hexdigest(),
              'output': str(out_path.relative_to(OUT_ROOT)), 'output_sha256': hashlib.sha256(out_path.read_bytes()).hexdigest(),
              'unique_uvs': len(uv_a), 'uv_sets_identical': True, 'profile': prof, 'grade': stats,
              'red_metric_strict_hue_lt15_gt320_sat_gt030_val_gt020_pct': {'source': round(100 * float(red_mask(rgb).mean()), 4), 'candidate': round(100 * float(red_mask(gr).mean()), 4)},
              'kept_unchanged': ['meshes', 'accessors', 'skins', 'nodes', 'animations', 'scenes', 'all non-image bufferView bytes'] + (['normal, metallic-roughness and emissive maps (r6)'] if sp == 'abyssal_guardian' else []),
              'non_image_buffer_views_byte_identical': len(non_image),
              'material': o['materials'][0], 'animations': [a.get('name') for a in o.get('animations', [])]}
    report_path.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k not in ('material', 'profile')}, indent=1))


def png(img):
    b = io.BytesIO(); img.save(b, 'PNG', optimize=True); return b.getvalue()


def main():
    sp = sys.argv[1]; prof = PROFILES[sp]
    installed = ROOT / prof['installed']
    # run None: material pass on the installed GLB's own maps (no Meshy task)
    retex_path = ROOT / RAW.format(sp=sp, run=prof['run']) if prof['run'] else installed
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
    if prof.get('region_recolor'):
        prof = dict(prof, _posmap=position_map(base, base_chunks, rgb.shape[0]))
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
              'unique_uvs': len(uv_a), 'uv_sets_identical': True, 'profile': {k: v for k, v in prof.items() if k != '_posmap'}, 'grade': stats,
              'red_metric_strict_hue_lt15_gt320_sat_gt030_val_gt020_pct': {'retexture': round(100 * float(red_mask(rgb).mean()), 4), 'candidate': round(100 * float(red_mask(gr).mean()), 4)},
              'kept_unchanged': ['meshes', 'accessors', 'skins', 'nodes', 'animations', 'scenes', 'all non-image bufferView bytes'],
              'non_image_buffer_views_byte_identical': len(non_image),
              'joint_names': [out['nodes'][j].get('name') for j in out['skins'][0]['joints']],
              'material': out['materials'][0], 'animations': [a.get('name') for a in out.get('animations', [])]}
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k not in ('material', 'profile', 'joint_names')}, indent=1))


if __name__ == '__main__':
    mode = sys.argv[2] if len(sys.argv) > 2 else 'r6'
    {'r7': main_r7, 'r8': main_r8}.get(mode, lambda sp: main())(sys.argv[1])
