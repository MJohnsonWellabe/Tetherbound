"""F36#70 Sparkit legs (LANE-KIT, 7 Nov 2026), in-place GLB patch.
  python3 thicken_legs_glb.py <in.glb> <out.glb> <scale> <paw_keep>
A Blender glTF round-trip re-oriented this rig's bones and broke its clips
(collapsed "moving"/"hurt" stills, round 1), so this rewrites only the POSITION
accessor of the skinned mesh inside the original GLB: rig, weights, clips,
normals, materials and textures stay byte-identical. Each vertex whose
strongest weight is a leg joint is taken into that joint's bind space (the
... (superseded, see the selection note in the code) ... its distance from
the leg axis is scaled by one continuous hip-to-paw profile (s = 0 at
the hip, 0.5 at the knee, 1 at the paw: fades in over the top fifth, holds
`scale`, eases to (1 - paw_keep) of the gain at the paw), then mapped back. No
vertex moves along its bone, so length, stance and the 1.95 m height stay.
Upper bones' lengths come from their lower child's bind origin; lower bones use
the distance from their origin to the lowest vertex they own.
"""
import json, struct, sys
import numpy as np

src, dst, K, paw_keep = sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4])
data = bytearray(open(src, "rb").read())
jlen = struct.unpack("<I", data[12:16])[0]
gl = json.loads(data[20:20 + jlen])
bin_off = 20 + jlen + 8
CT = {5126: np.float32, 5121: np.uint8, 5123: np.uint16}
NC = {"SCALAR": 1, "VEC3": 3, "VEC4": 4, "MAT4": 16}

def view(acc_i):
    a = gl["accessors"][acc_i]; bv = gl["bufferViews"][a["bufferView"]]
    start = bin_off + bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    dt = np.dtype(CT[a["componentType"]]); n = NC[a["type"]]
    stride = bv.get("byteStride", dt.itemsize * n)
    assert stride == dt.itemsize * n, "interleaved buffers not handled"
    return start, np.frombuffer(bytes(data[start:start + a["count"] * stride]), dtype=dt).reshape(a["count"], n).copy()

prim = gl["meshes"][0]["primitives"][0]
pos_start, pos = view(prim["attributes"]["POSITION"])
_, joints = view(prim["attributes"]["JOINTS_0"])
_, weights = view(prim["attributes"]["WEIGHTS_0"])
weights = weights.astype(np.float64)
if gl["accessors"][prim["attributes"]["WEIGHTS_0"]]["componentType"] != 5126:
    weights /= 255.0 if weights.max() > 1.5 else 1.0
skin = gl["skins"][0]
_, ibm = view(skin["inverseBindMatrices"])
ibm = ibm.reshape(-1, 4, 4).transpose(0, 2, 1).astype(np.float64)  # column-major -> row-major
names = [gl["nodes"][i]["name"] for i in skin["joints"]]
leg = {i: n for i, n in enumerate(names) if n.startswith(("front_", "rear_"))}
bind = np.linalg.inv(ibm)  # joint space -> mesh space

def smooth(x):
    x = np.clip(x, 0.0, 1.0); return x * x * (3 - 2 * x)

# Selection is geometric, not by weight: this remake's auto-weights put most leg
# vertices on pelvis/spine (front-left leg owns no leg-joint vertex), and its leg
# bones sit off the leg geometry. Below the hip, vertices split into four legs by
# side (x) and front/rear (z); each 2 cm height slice of a leg is scaled in the
# horizontal plane about that slice's own centroid (legs stand near-vertical).
HIP, FADE, PAW, PAW_FADE, SLICE = 0.50, 0.12, 0.10, 0.08, 0.02
out = pos.astype(np.float64).copy()
y = out[:, 1]
mid_z = 0.5 * (np.median(bind[names.index("front_upper_l")][2, 3]) + np.median(bind[names.index("rear_upper_l")][2, 3]))
cand = np.where(y < HIP)[0]
moved = 0
for side in (-1, 1):
    for front in (True, False):
        sel = cand[(np.sign(out[cand, 0]) == side) & ((out[cand, 2] > mid_z) == front)]
        if not len(sel):
            continue
        bins = np.floor(y[sel] / SLICE).astype(int)
        for b in np.unique(bins):
            idx = sel[bins == b]
            c = out[idx][:, [0, 2]].mean(0)
            yy = y[idx]
            k = 1.0 + (K - 1.0) * smooth((HIP - yy) / FADE) * (1.0 - paw_keep * smooth((PAW - yy) / PAW_FADE))
            out[idx, 0] = c[0] + (out[idx, 0] - c[0]) * k
            out[idx, 2] = c[1] + (out[idx, 2] - c[1]) * k
        moved += len(sel)
        print("THICKEN leg", "L" if side < 0 else "R", "front" if front else "rear", len(sel))
new = out.astype(np.float32)
data[pos_start:pos_start + new.nbytes] = new.tobytes()
acc = gl["accessors"][prim["attributes"]["POSITION"]]
acc["min"] = new.min(0).tolist(); acc["max"] = new.max(0).tolist()
js = json.dumps(gl, separators=(",", ":")).encode()
js += b" " * ((4 - len(js) % 4) % 4)
body = data[20 + jlen:]
outb = bytearray(b"glTF") + struct.pack("<II", 2, 12 + 8 + len(js) + len(body)) + struct.pack("<I", len(js)) + b"JSON" + js + body
open(dst, "wb").write(outb)
print("THICKEN moved", moved, "of", len(pos), "height", float(new[:, 1].max() - new[:, 1].min()))
