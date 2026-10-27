"""dog3 Terrapup: flatten the raised plate lumps into the coat (25 Oct 2026).

CPU b40/b41: every retexture of dog3 (r1 graded, r3 with separate stones) still
reads as "a stone saddle or pack strapped on", because the mesh carries hard,
raised lumps under the plates that stop at the shoulders and haunches. The
coordinator approved a vertex-only edit: identity, rig, skin weights, clips,
UVs and height unchanged.

Method (no Blender in the lane container, so this works on the glTF buffers):
- The plate region is retex/grade_retex.py's plate mask in UV space, dilated
  and blurred so the edit feathers out into the coat.
- Each vertex takes the mask's weight at its UV, ramped in by height and
  windowed lengthwise so only the back and shoulders take part (seam duplicates are welded by position and
  share the largest weight, so no seam opens).
- The welded mesh is Laplacian-smoothed; that smoothed copy stands in for the
  body surface under the lumps.
- Each vertex moves FLATTEN of the way toward it, times its weight. The rest of
  the relief stays as low stones along the spine and shoulder blades.
- Normals are recomputed where a vertex moved; elsewhere they are untouched.
Only POSITION and NORMAL bytes change. The script refuses to write if the
mesh's top (the head) or its length changes.

    python3 assets/creatures/tetherbound/terrapup/candidate_dog3/source/flatten_plates.py [--dry-run]

It reads the pre-flatten GLB from git (BASE_REV), so a re-run never compounds,
and keeps the embedded textures of the working copy.
"""
import hashlib
import os
import subprocess
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as nd

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "art_pipeline"))
sys.path.insert(0, os.path.join(HERE, "..", "retex"))
import shift_reserved_red as T  # noqa: E402  (GLB reader/writer)
import grade_retex as G  # noqa: E402  (disk helper)
import grade_r4 as R4  # noqa: E402  (r6: the same pad mask the texture fill uses)

GLB = os.path.join(HERE, "..", "models", "creature_terrapup_dog3.glb")
GLB_REL = "assets/creatures/tetherbound/terrapup/candidate_dog3/models/creature_terrapup_dog3.glb"
# The r1-graded GLB before any vertex edit (tb/creatures-land ebec8e36).
BASE_REV = "ebec8e36732c9b4d8f573956f7953ba32e9cd8ea"
SOURCE = os.path.join(HERE, "..", "retex", "r1_base_color.png")
MASK_GROW_PX = 6
MASK_BLUR_PX = 5.0
WELD_M = 1e-5
SMOOTH_ITERATIONS = 60
SMOOTH_LAMBDA = 0.5
WEIGHT_SMOOTH_ITERATIONS = 3
FLATTEN = 0.7
# The plates sit on the back and shoulders (back top 2.6-2.7 m at 3.20 m tall).
# Other UV islands near the mask (legs, belly fill) must not move.
BACK_FROM_Y = (1.7, 2.1)  # weight ramps in between these heights
BACK_Z = (1.2, 1.5)  # full weight within +-1.2 m of mid-body (haunch to shoulders), none past 1.5 (head, tail)
WEIGHT_FLOOR = 0.05


def _accessor(gltf, views, index):
    a = gltf["accessors"][index]
    width = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
    dtype = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}[a["componentType"]]
    view = gltf["bufferViews"][a["bufferView"]]
    assert view.get("byteStride") in (None, width * np.dtype(dtype).itemsize), "interleaved buffers are not handled"
    data = np.frombuffer(views[a["bufferView"]], dtype=dtype, offset=a.get("byteOffset", 0), count=a["count"] * width)
    return data.reshape(a["count"], width).copy()


def _put(gltf, views, index, array):
    a = gltf["accessors"][index]
    raw = bytearray(views[a["bufferView"]])
    start = a.get("byteOffset", 0)
    blob = array.astype(np.float32).tobytes()
    raw[start:start + len(blob)] = blob
    views[a["bufferView"]] = bytes(raw)


def _plate_weight():
    rgb = np.asarray(Image.open(SOURCE).convert("RGB")).astype(np.float64) / 255.0
    plate = R4._plate_pad(rgb)
    grown = nd.binary_dilation(plate, structure=G._disk(MASK_GROW_PX))
    return np.clip(nd.gaussian_filter(grown.astype(np.float64), MASK_BLUR_PX), 0.0, 1.0)


def _laplacian(points, edges, iterations, lam):
    count = len(points)
    degree = np.bincount(edges.ravel(), minlength=count).astype(np.float64)
    degree[degree == 0] = 1.0
    out = points.copy()
    for _ in range(iterations):
        acc = np.zeros_like(out)
        np.add.at(acc, edges[:, 0], out[edges[:, 1]])
        np.add.at(acc, edges[:, 1], out[edges[:, 0]])
        out = out + lam * (acc / degree[:, None] - out)
    return out


def _normals(points, tris):
    face = np.cross(points[tris[:, 1]] - points[tris[:, 0]], points[tris[:, 2]] - points[tris[:, 0]])
    out = np.zeros_like(points)
    for k in range(3):
        np.add.at(out, tris[:, k], face)
    length = np.linalg.norm(out, axis=1, keepdims=True)
    return out / np.maximum(length, 1e-12)


def main():
    base = subprocess.run(["git", "-C", ROOT, "show", f"{BASE_REV}:{GLB_REL}"], check=True, capture_output=True).stdout
    gltf, views = T._read_glb(GLB)  # textures from the working copy
    base_gltf, base_views = T._read_glb_bytes(base) if hasattr(T, "_read_glb_bytes") else _read_bytes(base)
    prim = gltf["meshes"][0]["primitives"][0]
    pos_i, nrm_i = prim["attributes"]["POSITION"], prim["attributes"]["NORMAL"]
    pos = _accessor(base_gltf, base_views, pos_i).astype(np.float64)
    nrm = _accessor(base_gltf, base_views, nrm_i).astype(np.float64)
    uv = _accessor(base_gltf, base_views, prim["attributes"]["TEXCOORD_0"]).astype(np.float64)
    tris = _accessor(base_gltf, base_views, prim["indices"]).reshape(-1, 3).astype(np.int64)

    weight_map = _plate_weight()
    h, w = weight_map.shape
    px = np.clip((uv[:, 0] % 1.0) * w, 0, w - 1).astype(int)
    py = np.clip((uv[:, 1] % 1.0) * h, 0, h - 1).astype(int)
    vw = weight_map[py, px] * np.clip((pos[:, 1] - BACK_FROM_Y[0]) / (BACK_FROM_Y[1] - BACK_FROM_Y[0]), 0.0, 1.0)
    vw *= np.clip((BACK_Z[1] - np.abs(pos[:, 2])) / (BACK_Z[1] - BACK_Z[0]), 0.0, 1.0)
    vw[vw < WEIGHT_FLOOR] = 0.0

    key = np.round(pos / WELD_M).astype(np.int64)
    _, weld, inverse = np.unique(key, axis=0, return_index=True, return_inverse=True)
    inverse = inverse.ravel()
    wpos = pos[weld]
    ww = np.zeros(len(weld))
    np.maximum.at(ww, inverse, vw)
    wtris = inverse[tris]
    edges = np.concatenate([wtris[:, [0, 1]], wtris[:, [1, 2]], wtris[:, [2, 0]]])
    edges = np.unique(np.sort(edges, axis=1), axis=0)
    ww = _laplacian(ww[:, None], edges, WEIGHT_SMOOTH_ITERATIONS, 0.5)[:, 0]

    surface = _laplacian(wpos, edges, SMOOTH_ITERATIONS, SMOOTH_LAMBDA)
    moved = wpos + (FLATTEN * ww)[:, None] * (surface - wpos)
    new_pos = moved[inverse]
    shift = np.linalg.norm(new_pos - pos, axis=1)

    wn = _normals(moved, wtris)[inverse]
    blend = np.clip(ww[inverse] * 4.0, 0.0, 1.0)[:, None]
    new_nrm = nrm * (1 - blend) + wn * blend
    new_nrm /= np.maximum(np.linalg.norm(new_nrm, axis=1, keepdims=True), 1e-12)

    print("vertices %d, moved > 1 mm: %d, max shift %.3f m, mean shift (moved) %.3f m" % (
        len(pos), int((shift > 1e-3).sum()), shift.max(), shift[shift > 1e-3].mean() if (shift > 1e-3).any() else 0))
    for axis, name in ((1, "top"), (2, "length")):
        before = (pos[:, axis].min(), pos[:, axis].max())
        after = (new_pos[:, axis].min(), new_pos[:, axis].max())
        print("%s before %.4f..%.4f after %.4f..%.4f" % (name, before[0], before[1], after[0], after[1]))
        if abs(before[1] - after[1]) > 1e-3 or abs(before[0] - after[0]) > 1e-3:
            raise SystemExit("refusing: the %s extent changed, which would change the fitted scale" % name)
    if "--dry-run" in sys.argv:
        return
    _put(gltf, views, pos_i, new_pos)
    _put(gltf, views, nrm_i, new_nrm)
    acc = gltf["accessors"][pos_i]
    acc["min"] = new_pos.min(0).astype(np.float32).tolist()
    acc["max"] = new_pos.max(0).astype(np.float32).tolist()
    T._write_glb(GLB, gltf, views)
    print("before sha256", hashlib.sha256(base).hexdigest())
    print("after  sha256", hashlib.sha256(open(GLB, "rb").read()).hexdigest())


def _read_bytes(data):
    path = os.path.join(os.environ.get("TMPDIR", "/tmp"), "dog3_base_%d.glb" % os.getpid())
    with open(path, "wb") as f:
        f.write(data)
    try:
        return T._read_glb(path)
    finally:
        os.remove(path)


if __name__ == "__main__":
    main()
