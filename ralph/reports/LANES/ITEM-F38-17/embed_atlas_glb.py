"""F38#17 (LANE-KIT): copy an installed character GLB and swap its single
embedded atlas PNG for another PNG (the installed graded vis1 atlas), rebuilding
the BIN chunk. Geometry, skin, rig and clips are byte-identical.
usage: embed_atlas_glb.py SRC.glb ATLAS.png OUT.glb"""
import json, struct, sys

src, atlas, out = sys.argv[1:4]
b = open(src, 'rb').read()
jl = struct.unpack('<I', b[12:16])[0]
j = json.loads(b[20:20 + jl])
bin_off = 20 + jl
bl = struct.unpack('<I', b[bin_off:bin_off + 4])[0]
binc = b[bin_off + 8:bin_off + 8 + bl]
assert len(j['images']) == 1
img_bv = j['images'][0]['bufferView']
png = open(atlas, 'rb').read()
new = bytearray()
for i, bv in enumerate(j['bufferViews']):
    data = png if i == img_bv else binc[bv.get('byteOffset', 0):bv.get('byteOffset', 0) + bv['byteLength']]
    while len(new) % 4:
        new += b'\0'
    bv['byteOffset'] = len(new)
    bv['byteLength'] = len(data)
    new += data
while len(new) % 4:
    new += b'\0'
j['buffers'][0]['byteLength'] = len(new)
js = json.dumps(j, separators=(',', ':')).encode()
while len(js) % 4:
    js += b' '
total = 12 + 8 + len(js) + 8 + len(new)
o = struct.pack('<III', 0x46546C67, 2, total) + struct.pack('<II', len(js), 0x4E4F534A) + js \
    + struct.pack('<II', len(new), 0x004E4942) + bytes(new)
open(out, 'wb').write(o)
print(out, total)
