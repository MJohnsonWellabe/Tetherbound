"""rename_mesh_node.py in.glb out.glb OLD NEW: rename one glTF node (JSON only).

Meadowhart's riding contract (tests/test_meadowhart_riding_visual_repair_0912.gd)
finds the animal's single skinned mesh as `MeadowhartBareBody`; the pilot's
exporter named it `Mesh_0`. Geometry, skin and clips are untouched."""
import json, struct, sys
src, dst, old, new = sys.argv[1:5]
b = open(src, 'rb').read()
n = struct.unpack('<I', b[12:16])[0]
j = json.loads(b[20:20 + n])
hits = [x for x in j['nodes'] if x.get('name') == old and 'mesh' in x]
assert len(hits) == 1, hits
hits[0]['name'] = new
rest = b[20 + n:]
js = json.dumps(j, separators=(',', ':')).encode()
js += b' ' * (-len(js) % 4)
with open(dst, 'wb') as fh:
    fh.write(struct.pack('<4sII', b'glTF', 2, 12 + 8 + len(js) + len(rest)))
    fh.write(struct.pack('<I4s', len(js), b'JSON')); fh.write(js); fh.write(rest)
