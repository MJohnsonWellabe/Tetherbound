#!/usr/bin/env python3
"""Bind every vertex inside one or more model-space boxes rigidly to one joint.

Creatures-ralph (2 Nov 2026): Meshy remakes rigged by the dog3 recipe leave
some horn and tusk vertices partly weighted to the spine, so a head-down hit
react stretches the horn into a sheet. A horn or tusk is rigid: it must follow
the head bone alone. This rewrites JOINTS_0/WEIGHTS_0 in place (no Blender).

Boxes are in the mesh's own 0..1 bounding-box units (the anatomy-map frame,
tools/creature_anatomy_maps.py): x_min,x_max,y_min,y_max,z_min,z_max.

    python3 tools/art_pipeline/rigid_bind_region.py model.glb head \
        "0,0.31,0,0.6,0.87,1" "0.69,1,0,0.6,0.87,1" [--dry-run]
"""
import json
import struct
import sys

import numpy as np

CT = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def load(path):
    data = open(path, "rb").read()
    json_len = struct.unpack("<I", data[12:16])[0]
    gltf = json.loads(data[20:20 + json_len])
    off = 20 + json_len
    bin_len = struct.unpack("<I", data[off:off + 4])[0]
    return gltf, bytearray(data[off + 8:off + 8 + bin_len])


def view(gltf, binary, index):
    acc = gltf["accessors"][index]
    if "sparse" in acc:
        raise SystemExit("sparse accessor %d not supported" % index)
    bv = gltf["bufferViews"][acc["bufferView"]]
    dt = np.dtype(CT[acc["componentType"]])
    n = NC[acc["type"]]
    start = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = bv.get("byteStride", 0) or dt.itemsize * n
    return np.ndarray((acc["count"], n), dtype=dt, buffer=binary, offset=start,
                      strides=(stride, dt.itemsize))


def save(path, gltf, binary):
    js = json.dumps(gltf, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    bb = bytes(binary) + b"\0" * ((4 - len(binary) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(bb)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        f.write(struct.pack("<II", len(bb), 0x004E4942) + bb)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    path, joint_name, boxes = args[0], args[1], [[float(v) for v in b.split(",")] for b in args[2:]]
    gltf, binary = load(path)
    skin = gltf["skins"][0]
    names = [gltf["nodes"][j].get("name", "") for j in skin["joints"]]
    if joint_name not in names:
        raise SystemExit("joint %s not in skin %s" % (joint_name, names))
    joint = names.index(joint_name)
    total = 0
    for mesh in gltf["meshes"]:
        for prim in mesh["primitives"]:
            attrs = prim["attributes"]
            if "JOINTS_0" not in attrs:
                continue
            pos = view(gltf, binary, attrs["POSITION"]).astype(np.float64)
            lo, hi = pos.min(axis=0), pos.max(axis=0)
            unit = (pos - lo) / np.maximum(hi - lo, 1e-9)
            inside = np.zeros(len(pos), dtype=bool)
            for x0, x1, y0, y1, z0, z1 in boxes:
                inside |= ((unit[:, 0] >= x0) & (unit[:, 0] <= x1) & (unit[:, 1] >= y0)
                           & (unit[:, 1] <= y1) & (unit[:, 2] >= z0) & (unit[:, 2] <= z1))
            joints = view(gltf, binary, attrs["JOINTS_0"])
            weights = view(gltf, binary, attrs["WEIGHTS_0"])
            if weights.dtype != np.float32:
                raise SystemExit("normalised integer weights not supported")
            before = np.where(joints[inside] == joint, weights[inside], 0).sum(axis=1)
            print("%s: %d vertices in the boxes; %s weight before min %.3f mean %.3f"
                  % (mesh.get("name", "mesh"), inside.sum(), joint_name,
                     before.min() if inside.any() else 1.0, before.mean() if inside.any() else 1.0))
            if not dry:
                joints[inside] = 0
                joints[inside, 0] = joint
                weights[inside] = 0.0
                weights[inside, 0] = 1.0
            total += int(inside.sum())
    if not dry:
        save(path, gltf, binary)
    print("%s %d vertices -> %s" % ("would bind" if dry else "bound", total, joint_name))


if __name__ == "__main__":
    main()
