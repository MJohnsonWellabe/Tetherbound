#!/usr/bin/env python3
"""Relax skin weights where a gameplay clip stretches the mesh into sheets.

Creatures-ralph (2 Nov 2026). Batch-4 GPU judges saw a "flat white sheet" in
Cliffspike's hit react and horns that "double or stretch" on Craghorn: on the
dog3-rigged Meshy remakes a long quill or horn has its base weighted to the
spine and its tip to the head or tail, so a clip pulls one triangle across the
body. This tool skins the mesh on the CPU (glTF linear blend skinning) at
sampled times of the named clips, marks every triangle with an edge that grows
more than --limit metres over its rest length, grows that region by --rings, and solves
the region's weights harmonically from the fixed weights around it (Jacobi
iterations on the mesh graph). A quill attached only at its base inherits the
base's weights and moves rigidly with the body. Mesh, UVs, clips and every
vertex outside the region are untouched. No Blender.

    python3 tools/art_pipeline/relax_stretched_weights.py model.glb \
        [--clips=hit,faint,attack,charged] [--limit=0.15] [--rings=1] [--dry-run]
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rigid_bind_region import load, save, view  # noqa: E402


def _quat_matrix(q):
    x, y, z, w = q
    return np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                     [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                     [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])


def _slerp(a, b, u):
    d = float(np.dot(a, b))
    if d < 0.0:
        b, d = -b, -d
    if d > 0.9995:
        q = a + (b - a) * u
        return q / np.linalg.norm(q)
    th = np.arccos(d)
    return (np.sin((1 - u) * th) * a + np.sin(u * th) * b) / np.sin(th)


class Skin:
    def __init__(self, gltf, binary, prim):
        self.g, self.b = gltf, binary
        self.parent = {}
        for i, node in enumerate(gltf["nodes"]):
            for c in node.get("children", []):
                self.parent[c] = i
        skin = gltf["skins"][0]
        self.joints = skin["joints"]
        self.ibm = view(gltf, binary, skin["inverseBindMatrices"]).reshape(-1, 4, 4).transpose(0, 2, 1).astype(float)
        attrs = prim["attributes"]
        self.P = view(gltf, binary, attrs["POSITION"]).astype(float)
        self.T = view(gltf, binary, prim["indices"]).reshape(-1, 3).astype(np.int64)

    def _local(self, i, anim, t):
        node = self.g["nodes"][i]
        tr = np.array(node.get("translation", [0, 0, 0]), float)
        rot = np.array(node.get("rotation", [0, 0, 0, 1]), float)
        sc = np.array(node.get("scale", [1, 1, 1]), float)
        if anim is not None:
            for ch in anim["channels"]:
                if ch["target"].get("node") != i:
                    continue
                sm = anim["samplers"][ch["sampler"]]
                ti = view(self.g, self.b, sm["input"]).ravel().astype(float)
                v = view(self.g, self.b, sm["output"]).astype(float)
                k = int(np.searchsorted(ti, t))
                if k <= 0:
                    val = v[0]
                elif k >= len(ti):
                    val = v[-1]
                else:
                    u = (t - ti[k - 1]) / max(ti[k] - ti[k - 1], 1e-9)
                    path = ch["target"]["path"]
                    val = _slerp(v[k - 1], v[k], u) if path == "rotation" else v[k - 1] * (1 - u) + v[k] * u
                path = ch["target"]["path"]
                if path == "translation":
                    tr = val
                elif path == "rotation":
                    rot = val
                elif path == "scale":
                    sc = val
        m = np.eye(4)
        m[:3, :3] = _quat_matrix(rot) * sc[None, :]
        m[:3, 3] = tr
        return m

    def _world(self, i, anim, t, cache):
        if i not in cache:
            m = self._local(i, anim, t)
            if i in self.parent:
                m = self._world(self.parent[i], anim, t, cache) @ m
            cache[i] = m
        return cache[i]

    def pose(self, J, W, anim=None, t=0.0):
        cache = {}
        mats = np.array([self._world(j, anim, t, cache) @ self.ibm[k] for k, j in enumerate(self.joints)])
        ph = np.c_[self.P, np.ones(len(self.P))]
        out = np.zeros((len(self.P), 3))
        for c in range(J.shape[1]):
            out += W[:, c:c + 1] * np.einsum("nij,nj->ni", mats[J[:, c]], ph)[:, :3]
        return out

    def edges(self, X):
        return np.stack([np.linalg.norm(X[self.T[:, a]] - X[self.T[:, b]], axis=1)
                         for a, b in ((0, 1), (1, 2), (2, 0))], 1)


def _clip_length(gltf, anim):
    return max(float(np.max(gltf["accessors"][s["input"]]["max"])) for s in anim["samplers"])


def worst_stretch(skin, J, W, anims, gltf, phases=9):
    """Per triangle, the largest growth of any edge over the clips, in metres
    (a ratio overstates a 7 mm quill tip; the judges see metres of sheet)."""
    rest = skin.edges(skin.pose(J, W))
    worst = np.zeros(len(skin.T))
    for anim in anims:
        length = _clip_length(gltf, anim)
        for ph in np.linspace(0.0, 1.0, phases):
            worst = np.maximum(worst, (skin.edges(skin.pose(J, W, anim, length * ph)) - rest).max(1))
    return worst


def main():
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    path = args[0]
    clips = opts.get("clips", "hit,faint,attack,charged").split(",")
    limit = float(opts.get("limit", 0.15))
    rings = int(opts.get("rings", 1))
    gltf, binary = load(path)
    prim = gltf["meshes"][0]["primitives"][0]
    skin = Skin(gltf, binary, prim)
    anims = [a for a in gltf.get("animations", []) if a["name"] in clips]
    jv = view(gltf, binary, prim["attributes"]["JOINTS_0"])
    wv = view(gltf, binary, prim["attributes"]["WEIGHTS_0"])
    J = jv.astype(np.int64)
    W = wv.astype(float)
    n, nj = len(skin.P), len(skin.joints)
    before = worst_stretch(skin, J, W, anims, gltf)
    bad = before > limit
    print("clips %s: %d of %d triangles stretch more than %.2f m (worst %.2f m)"
          % ([a["name"] for a in anims], bad.sum(), len(skin.T), limit, before.max()))
    if not bad.any():
        return
    # Weld coincident vertices (UV seams) so the graph is the surface.
    _, weld = np.unique(np.round(skin.P, 6), axis=0, return_inverse=True)
    weld = weld.ravel()
    region = np.zeros(weld.max() + 1, dtype=bool)
    region[weld[skin.T[bad]].ravel()] = True
    tri_w = weld[skin.T]
    for _ in range(rings):
        touch = region[tri_w].any(1)
        region[tri_w[touch].ravel()] = True
    # Dense weights on welded nodes.
    dense = np.zeros((weld.max() + 1, nj))
    np.add.at(dense, (np.repeat(weld, J.shape[1]), J.ravel()), W.ravel())
    counts = np.bincount(weld, minlength=weld.max() + 1)[:, None]
    dense /= np.maximum(counts, 1)
    e = np.concatenate([tri_w[:, [0, 1]], tri_w[:, [1, 2]], tri_w[:, [2, 0]]])
    e = np.concatenate([e, e[:, ::-1]])
    deg = np.bincount(e[:, 0], minlength=len(dense)).astype(float)[:, None]
    free = region
    for _ in range(int(opts.get("iterations", 400))):
        acc = np.zeros_like(dense)
        np.add.at(acc, e[:, 0], dense[e[:, 1]])
        avg = acc / np.maximum(deg, 1)
        dense[free] = avg[free]
    # Back to four influences per vertex.
    node_w = dense[weld]
    changed = free[weld]
    top = np.argsort(-node_w, axis=1)[:, :J.shape[1]]
    top_w = np.take_along_axis(node_w, top, 1)
    top_w /= np.maximum(top_w.sum(1, keepdims=True), 1e-9)
    J2, W2 = J.copy(), W.copy()
    J2[changed] = top[changed]
    W2[changed] = top_w[changed]
    after = worst_stretch(skin, J2, W2, anims, gltf)
    print("relaxed %d vertices: worst stretch %.2f m -> %.2f m; triangles over %.2f m %d -> %d"
          % (changed.sum(), before.max(), after.max(), limit, bad.sum(), (after > limit).sum()))
    if after.max() > before.max():
        print("refused: the relaxed weights stretch further than the source")
        return
    if not dry:
        jv[:] = J2.astype(jv.dtype)
        wv[:] = W2.astype(wv.dtype)
        save(path, gltf, binary)


if __name__ == "__main__":
    main()
