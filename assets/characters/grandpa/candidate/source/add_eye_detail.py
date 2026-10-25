"""F36#0 Grandpa eyes (24 Oct 2026, GPU re-confirm 7.21: every batch named the
solid black "bead" eyes). Same installed head, mesh, rig and UVs: only the dark
eye texels of the face albedo are repainted with a pupil, a warm hazel iris, a
darker limbal ring and a catch-light.

The eyes are split across UV islands, so the iris is laid out in MODEL space:
each dark eye texel is given its 3D position by rasterising the mesh's own
triangles into the texture, the dark texels are split into the two eyes, and
every painted ring and highlight is a distance from that eye's 3D centre. The
pattern is therefore continuous across the seams.

The untouched albedo is kept once at source/eye/eye_base.png (a .gdignore folder) and every run
repaints from it.

    python3 assets/characters/grandpa/candidate/source/add_eye_detail.py
"""
import io
import json
import os
import struct
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
MODELS = os.path.join(os.path.dirname(HERE), "models")
GLB = os.path.join(MODELS, "grandpa_native_face.glb")
IMAGE_NAME = "NativeFaceSkinAlbedo"
BASE = os.path.join(HERE, "eye", "eye_base.png")
# Texture regions holding the eyes (pixels, 2048 albedo), found by the dark
# blobs inside face skin: the right eye whole, the left eye split in two.
EYE_BOXES = [(640, 235, 730, 330), (1440, 500, 1530, 580), (320, 1880, 410, 1985)]
DARK = 0.22
PUPIL = 0.42
IRIS_INNER = (0.40, 0.27, 0.15)
IRIS_OUTER = (0.25, 0.17, 0.10)
LIMBAL = (0.09, 0.065, 0.05)
PUPIL_RGB = (0.035, 0.03, 0.03)
CATCH = (0.97, 0.96, 0.93)
CATCH_OFFSET = (0.30, 0.38)   # x, y fractions of the iris radius, same world side on both eyes
CATCH_RADIUS = 0.2


def read_glb(path):
    data = open(path, "rb").read()
    n = struct.unpack_from("<I", data, 12)[0]
    gltf = json.loads(data[20:20 + n])
    at = 20 + n
    blen = struct.unpack_from("<I", data, at)[0]
    return gltf, bytes(data[at + 8:at + 8 + blen])


def write_glb(path, gltf, views):
    blob = bytearray()
    for i, raw in enumerate(views):
        while len(blob) % 4:
            blob.append(0)
        gltf["bufferViews"][i]["byteOffset"] = len(blob)
        gltf["bufferViews"][i]["byteLength"] = len(raw)
        blob += raw
    while len(blob) % 4:
        blob.append(0)
    gltf["buffers"][0]["byteLength"] = len(blob)
    text = json.dumps(gltf, separators=(",", ":")).encode()
    while len(text) % 4:
        text += b" "
    out = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(text) + 8 + len(blob))
    out += struct.pack("<II", len(text), 0x4E4F534A) + text
    out += struct.pack("<II", len(blob), 0x004E4942) + bytes(blob)
    open(path, "wb").write(out)


def accessor(gltf, blob, index):
    acc = gltf["accessors"][index]
    view = gltf["bufferViews"][acc["bufferView"]]
    comps = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[acc["type"]]
    dtype = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}[acc["componentType"]]
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = view.get("byteStride", 0) or comps * np.dtype(dtype).itemsize
    raw = np.frombuffer(blob, dtype=np.uint8, count=stride * (acc["count"] - 1) + comps * np.dtype(dtype).itemsize,
                        offset=start)
    rows = np.lib.stride_tricks.as_strided(raw, (acc["count"], comps * np.dtype(dtype).itemsize), (stride, 1))
    return np.frombuffer(rows.copy().tobytes(), dtype=dtype).reshape(acc["count"], comps)


def texel_positions(gltf, blob, size):
    """3D position for every texel inside EYE_BOXES, by rasterising triangles in UV."""
    pos3 = np.full((size, size, 3), np.nan)
    for mesh in gltf["meshes"]:
        for prim in mesh["primitives"]:
            P = accessor(gltf, blob, prim["attributes"]["POSITION"]).astype(np.float64)
            UV = accessor(gltf, blob, prim["attributes"]["TEXCOORD_0"]).astype(np.float64) * size
            I = accessor(gltf, blob, prim["indices"]).reshape(-1, 3)
            for x0, y0, x1, y1 in EYE_BOXES:
                tri_uv = UV[I]
                lo, hi = tri_uv.min(axis=1), tri_uv.max(axis=1)
                hit = (hi[:, 0] >= x0) & (lo[:, 0] <= x1) & (hi[:, 1] >= y0) & (lo[:, 1] <= y1)
                for tri in I[hit]:
                    a, b, c = UV[tri]
                    bx0, by0 = int(max(np.floor(min(a[0], b[0], c[0])), x0)), int(max(np.floor(min(a[1], b[1], c[1])), y0))
                    bx1, by1 = int(min(np.ceil(max(a[0], b[0], c[0])), x1)), int(min(np.ceil(max(a[1], b[1], c[1])), y1))
                    if bx1 < bx0 or by1 < by0:
                        continue
                    xs, ys = np.meshgrid(np.arange(bx0, bx1 + 1) + 0.5, np.arange(by0, by1 + 1) + 0.5)
                    den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
                    if abs(den) < 1e-12:
                        continue
                    w0 = ((b[1] - c[1]) * (xs - c[0]) + (c[0] - b[0]) * (ys - c[1])) / den
                    w1 = ((c[1] - a[1]) * (xs - c[0]) + (a[0] - c[0]) * (ys - c[1])) / den
                    w2 = 1 - w0 - w1
                    inside = (w0 >= -1e-4) & (w1 >= -1e-4) & (w2 >= -1e-4)
                    if not inside.any():
                        continue
                    p = (w0[..., None] * P[tri[0]] + w1[..., None] * P[tri[1]] + w2[..., None] * P[tri[2]])
                    yy, xx = (ys[inside] - 0.5).astype(int), (xs[inside] - 0.5).astype(int)
                    pos3[yy, xx] = p[inside]
    return pos3


def main():
    gltf, blob = read_glb(GLB)
    views = [blob[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]] for v in gltf["bufferViews"]]
    image = next(i for i in gltf["images"] if i.get("name") == IMAGE_NAME)
    if not os.path.exists(BASE):
        os.makedirs(os.path.dirname(BASE), exist_ok=True)
        open(os.path.join(os.path.dirname(BASE), ".gdignore"), "w").close()
        open(BASE, "wb").write(views[image["bufferView"]])
    src = Image.open(BASE).convert("RGBA")
    rgba = np.asarray(src).astype(np.float64) / 255.0
    size = src.width
    pos3 = texel_positions(gltf, blob, size)
    # Eyes sit in the head: the top 18% of the figure. The eye boxes also catch
    # dark clothing texels on neighbouring islands, which this drops.
    top = max(float(gltf["accessors"][p["attributes"]["POSITION"]]["max"][1])
              for m in gltf["meshes"] for p in m["primitives"])
    with np.errstate(invalid="ignore"):
        dark = (rgba[..., :3].max(-1) < DARK) & (pos3[..., 1] > top * 0.82)
    pts = pos3[dark]
    if len(pts) < 20:
        sys.exit("no eye texels found")
    # Two eyes, left and right of the face's centre line (model x): two-means on
    # x, since the two eyes need not cover the same number of texels.
    axis = 0
    lo, hi = float(pts[:, axis].min()), float(pts[:, axis].max())
    for _ in range(20):
        split = (lo + hi) / 2.0
        lo, hi = float(pts[pts[:, axis] < split, axis].mean()), float(pts[pts[:, axis] >= split, axis].mean())
    out = rgba.copy()
    with np.errstate(invalid="ignore"):
        # The painted eye also takes the old dull grey highlight inside the iris,
        # so the new catch-light is not lost where that highlight sat.
        candidates = (rgba[..., :3].max(-1) < 0.5) & (pos3[..., 1] > top * 0.82)
    cys, cxs = np.nonzero(candidates)
    cpts = pos3[candidates]
    for side in (pts[:, axis] < split, pts[:, axis] >= split):
        centre = pts[side].mean(0)
        radius = float(np.percentile(np.linalg.norm(pts[side] - centre, axis=1), 95))
        catch = centre + radius * np.array([CATCH_OFFSET[0], CATCH_OFFSET[1], 0.0])
        dist = np.linalg.norm(cpts - centre, axis=1) / radius
        near = dist < 1.0
        for y, x, p, d in zip(cys[near], cxs[near], cpts[near], dist[near]):
            if d < PUPIL:
                colour = np.array(PUPIL_RGB)
            elif d < 0.86:
                t = (d - PUPIL) / (0.86 - PUPIL)
                colour = np.array(IRIS_INNER) * (1 - t) + np.array(IRIS_OUTER) * t
            else:
                colour = np.array(LIMBAL)
            c = np.linalg.norm(p - catch) / radius
            if c < CATCH_RADIUS:
                k = min(1.0, (CATCH_RADIUS - c) / (CATCH_RADIUS * 0.35))
                colour = colour * (1 - k) + np.array(CATCH) * k
            out[y, x, :3] = colour
        print("eye: centre %s radius %.4f texels %d" % (np.round(centre, 4), radius, int(near.sum())))
    img = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA")
    buffer = io.BytesIO()
    img.save(buffer, "PNG", optimize=True)
    png = buffer.getvalue()
    views[image["bufferView"]] = png
    write_glb(GLB, gltf, views)
    open(os.path.join(MODELS, "grandpa_native_face_%s.png" % IMAGE_NAME), "wb").write(png)
    print("painted", GLB)


if __name__ == "__main__":
    main()
