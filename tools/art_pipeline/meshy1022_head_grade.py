#!/usr/bin/env python3
"""meshy1022_head_grade.py in.glb out.glb [--head-scale=S] [--head-joint=head] [--gamma=G] [--sat=K]

Close-1022 remake candidate: grows the face (vertices weighted to a leaf head
joint scale about that joint by 1 + (S-1) * weight, so the neck blends) and
lifts the albedo value (V ** G, S * K in HSV) of the embedded base colour image.
Bones, inverse binds and every clip are untouched."""
import io, json, struct, sys
import numpy as np
from PIL import Image

args = [a for a in sys.argv[1:] if not a.startswith('--')]
opt = dict(a[2:].split('=', 1) for a in sys.argv[1:] if a.startswith('--'))
src, dst = args
S = float(opt.get('head-scale', 1.0)); G = float(opt.get('gamma', 1.0)); K = float(opt.get('sat', 1.0))
joint_name = opt.get('head-joint', 'head')

b = open(src, 'rb').read()
jl = struct.unpack('<I', b[12:16])[0]
j = json.loads(b[20:20 + jl])
binoff = 20 + jl + 8
blob = bytearray(b[binoff:binoff + struct.unpack('<I', b[20 + jl:24 + jl])[0]])
views = [bytearray(blob[v.get('byteOffset', 0):v.get('byteOffset', 0) + v['byteLength']]) for v in j['bufferViews']]
CT = {5126: np.float32, 5121: np.uint8, 5123: np.uint16, 5125: np.uint32}
NC = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}


def acc(i):
    a = j['accessors'][i]
    v = j['bufferViews'][a['bufferView']]
    assert 'byteStride' not in v or v['byteStride'] == np.dtype(CT[a['componentType']]).itemsize * NC[a['type']]
    off = a.get('byteOffset', 0)
    arr = np.frombuffer(bytes(views[a['bufferView']]), CT[a['componentType']], a['count'] * NC[a['type']], off)
    return arr.reshape(a['count'], NC[a['type']]).copy(), a, off


if S != 1.0:
    skin = j['skins'][0]
    head = [j['nodes'][k].get('name') for k in skin['joints']].index(joint_name)
    assert not j['nodes'][skin['joints'][head]].get('children'), 'head joint must be a leaf'
    ibm, _, _ = acc(skin['inverseBindMatrices'])
    centre = np.linalg.inv(ibm[head].reshape(4, 4).T)[:3, 3]
    for mesh in j['meshes']:
        for prim in mesh['primitives']:
            at = prim['attributes']
            pos, pa, poff = acc(at['POSITION'])
            jt, _, _ = acc(at['JOINTS_0'])
            wt, wa, _ = acc(at['WEIGHTS_0'])
            if wa['componentType'] != 5126:
                wt = wt / float(np.iinfo(CT[wa['componentType']]).max)
            w = (wt * (jt == head)).sum(1)
            f = 1.0 + (S - 1.0) * w
            pos = (centre + (pos - centre) * f[:, None]).astype(np.float32)
            views[pa['bufferView']][poff:poff + pos.nbytes] = pos.tobytes()
            pa['min'] = pos.min(0).tolist(); pa['max'] = pos.max(0).tolist()
            print('head', joint_name, 'centre', centre.round(3).tolist(), 'verts moved', int((w > 0).sum()))

if G != 1.0 or K != 1.0:
    mat = j['materials'][0]['pbrMetallicRoughness']['baseColorTexture']['index']
    img = j['images'][j['textures'][mat]['source']]
    im = Image.open(io.BytesIO(bytes(views[img['bufferView']]))).convert('RGB')
    hsv = np.asarray(im.convert('HSV')).astype(np.float32) / 255.0
    hsv[..., 2] = hsv[..., 2] ** G
    hsv[..., 1] = np.clip(hsv[..., 1] * K, 0, 1)
    out = Image.fromarray((hsv * 255 + 0.5).astype(np.uint8), 'HSV').convert('RGB')
    buf = io.BytesIO(); out.save(buf, 'JPEG', quality=92)
    views[img['bufferView']] = bytearray(buf.getvalue())
    print('graded', img.get('name'), 'gamma', G, 'sat', K)

newblob = bytearray()
for v, data in zip(j['bufferViews'], views):
    while len(newblob) % 4: newblob.append(0)
    v['byteOffset'] = len(newblob); v['byteLength'] = len(data); newblob += data
while len(newblob) % 4: newblob.append(0)
j['buffers'][0]['byteLength'] = len(newblob)
js = json.dumps(j, separators=(',', ':')).encode()
js += b' ' * (-len(js) % 4)
total = 12 + 8 + len(js) + 8 + len(newblob)
with open(dst, 'wb') as fh:
    fh.write(struct.pack('<4sII', b'glTF', 2, total))
    fh.write(struct.pack('<I4s', len(js), b'JSON')); fh.write(js)
    fh.write(struct.pack('<I4s', len(newblob), b'BIN\x00')); fh.write(newblob)
