"""Give the Terrapup remake the installed dog3's rendered footprint.

PR #793 CI: with remake_owner1101_terrapup ON, tests/smoke_arena_contain.gd
could not engage the Burrow Warrens mouth fight: combat admission refused the
ally (rendered corner reach 5.30 m + 0.6 m clearance past the chamber-capped
ring). Admission sees a creature only through its rendered mesh box
(creature_body._fit / RENDER_BOUNDS.measure: corners, front extent, radial
footprint) plus its gameplay height and radius. The installed dog3 Terrapup
passes; its box is 1.2213 x 3.2 x 4.8958 m. The remake's is 1.4710 x 3.2 x
4.6767 m (wider plated shoulders, shorter body).

This re-proportions the remake to exactly the installed box: x scaled 0.830
(a leaner chest and shoulders) and z 1.047 about the box centre, height
unchanged, so every admission computation matches the installed creature's.
Bones keep their rest rotations; their rest positions move with the mesh, the
skin is rebound (inverse binds recomputed), normals/tangents follow, and each
baked translation key keeps its offset from the bone's rest. Rotation clips
are untouched. Idempotent: a model already at the target box is left alone.

    python3 assets/creatures/tetherbound/terrapup/candidate_owner1101/source/fit_installed_footprint.py
"""
import os
import struct
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "art_pipeline"))
import shift_reserved_red as T  # noqa: E402  (_read_glb / _write_glb)

MODEL = os.path.join(HERE, "..", "models", "creature_terrapup_owner1101.glb")
TARGET = np.array([1.2213, 3.2, 4.8958])  # installed candidate_dog3 mesh box (m)


def floats(gltf, views, index):
    acc = gltf["accessors"][index]
    assert acc["componentType"] == 5126 and "byteOffset" not in acc
    n = {"SCALAR": 1, "VEC3": 3, "VEC4": 4, "MAT4": 16}[acc["type"]]
    view = gltf["bufferViews"][acc["bufferView"]]
    assert view.get("byteStride", n * 4) == n * 4
    return np.frombuffer(views[acc["bufferView"]], np.float32, acc["count"] * n).reshape(acc["count"], n).astype(np.float64)


def store(gltf, views, index, array):
    acc = gltf["accessors"][index]
    raw = bytearray(views[acc["bufferView"]])
    data = np.ascontiguousarray(array, np.float32).ravel()
    struct.pack_into("<%df" % data.size, raw, 0, *data)
    views[acc["bufferView"]] = bytes(raw)
    if "min" in acc:
        acc["min"] = [float(v) for v in array.min(0)]
        acc["max"] = [float(v) for v in array.max(0)]


def quat_matrix(q):
    x, y, z, w = np.asarray(q, np.float64) / np.linalg.norm(q)
    return np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                     [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                     [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])


def main():
    gltf, views = T._read_glb(MODEL)
    nodes = gltf["nodes"]
    mesh_nodes = [n for n in nodes if "mesh" in n]
    assert len(mesh_nodes) == 1 and "skin" in mesh_nodes[0]
    prim = gltf["meshes"][mesh_nodes[0]["mesh"]]["primitives"]
    assert len(prim) == 1
    attrs = prim[0]["attributes"]
    pos = floats(gltf, views, attrs["POSITION"])
    lo, hi = pos.min(0), pos.max(0)
    size = hi - lo
    if np.allclose(size, TARGET, atol=1e-3):
        print("already at the installed footprint", size.round(4))
        return
    assert abs(size[1] - TARGET[1]) < 1e-3, size
    scale = np.array([TARGET[0] / size[0], 1.0, TARGET[2] / size[2]])
    centre = np.array([(lo[0] + hi[0]) * 0.5, 0.0, (lo[2] + hi[2]) * 0.5])

    def warp(p):
        return centre + (p - centre) * scale

    store(gltf, views, attrs["POSITION"], warp(pos))
    if "NORMAL" in attrs:
        n = floats(gltf, views, attrs["NORMAL"]) / scale
        store(gltf, views, attrs["NORMAL"], n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12))
    if "TANGENT" in attrs:
        t = floats(gltf, views, attrs["TANGENT"])
        v = t[:, :3] * scale
        t[:, :3] = v / np.maximum(np.linalg.norm(v, axis=1, keepdims=True), 1e-12)
        store(gltf, views, attrs["TANGENT"], t)

    skin = gltf["skins"][0]
    joints = skin["joints"]
    parent = {c: i for i, n in enumerate(nodes) for c in n.get("children", [])}
    for i in joints:
        assert np.allclose(nodes[i].get("scale", [1, 1, 1]), 1, atol=1e-4), nodes[i].get("name")
    for i, n in enumerate(nodes):
        if i not in joints and any(c in joints for c in n.get("children", [])):
            assert not any(k in n for k in ("translation", "rotation", "scale", "matrix")), "armature must be identity"
    world = {}

    def rest_world(i):
        if i not in world:
            m = np.eye(4)
            m[:3, :3] = quat_matrix(nodes[i].get("rotation", [0, 0, 0, 1]))
            m[:3, 3] = nodes[i].get("translation", [0, 0, 0])
            if i in parent and parent[i] in joints:
                m = rest_world(parent[i]) @ m
            world[i] = m
        return world[i]

    old_world = {i: rest_world(i).copy() for i in joints}
    new_world = {}
    for i in joints:
        m = old_world[i].copy()
        m[:3, 3] = warp(m[:3, 3])
        new_world[i] = m
    old_local_t = {i: np.array(nodes[i].get("translation", [0, 0, 0]), np.float64) for i in joints}
    new_local_t = {}
    for i in joints:
        if i in parent and parent[i] in joints:
            local = np.linalg.inv(new_world[parent[i]]) @ new_world[i]
        else:
            local = new_world[i]
        new_local_t[i] = local[:3, 3]
        nodes[i]["translation"] = [float(v) for v in local[:3, 3]]
    ibm = np.stack([np.linalg.inv(new_world[i]).T.ravel() for i in joints])
    store(gltf, views, skin["inverseBindMatrices"], ibm)

    shifted = set()
    for anim in gltf.get("animations", []):
        for channel in anim["channels"]:
            target = channel["target"]
            if target["path"] != "translation" or target.get("node") not in joints:
                continue
            sampler = anim["samplers"][channel["sampler"]]
            out = sampler["output"]
            if out in shifted:
                continue
            shifted.add(out)
            values = floats(gltf, views, out)
            store(gltf, views, out, values + (new_local_t[target["node"]] - old_local_t[target["node"]]))
    T._write_glb(MODEL, gltf, views)
    after = warp(pos)
    print("scale x %.4f z %.4f: box %s -> %s; %d translation tracks shifted"
          % (scale[0], scale[2], size.round(4), (after.max(0) - after.min(0)).round(4), len(shifted)))


if __name__ == "__main__":
    main()
