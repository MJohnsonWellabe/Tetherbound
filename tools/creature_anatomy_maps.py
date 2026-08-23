#!/usr/bin/env python3
"""CREATURE-IDENTITY-2: build a per-species ANATOMY MAP in UV space.

Why this exists
---------------
Round 1 of the creature presentation work re-keyed hue and cleaned speckle.
The blind critic called the result "correct but half-depth": the owner board
(`docs/reference/owner-board-2026-08-15-creature-colors.png`) is not a set of
recoloured animals, it is a set of animals the *meadow has grown into* --
leaves sprouting from a rabbit's ears, moss carpeting a boar's shoulders and a
turtle's shell, a stag's antler tips greened, storm-blue tips on a hawk's
flight feathers. That layer is paint, not geometry, so it is allowed under the
hard rule (no new creature meshes, no Meshy for creatures). But painting it
straight into a texture by hand-picked UV rectangles is exactly how galecrest's
round-1 blue patches ended up reading as decals stamped across feather
boundaries: UV islands are laid out by an automatic unwrapper and carry no
anatomy at all. Texture space simply does not know where an ear is.

So this tool gives it anatomy. For each species glb it rasterises the mesh's
own UV triangles and writes, per texel:

  * `pos`   -- the surface point in MODEL space, normalised into the mesh's
               bounding box as 0..1 on each axis (x = lateral, y = height,
               z = fore/aft). "The top 15% of the animal" becomes `y > 0.85`.
  * `nrm`   -- the surface normal, unit length. "Upward-facing surfaces only"
               (which is where moss and snow actually sit) becomes `n.y > 0.3`.
  * `dist`  -- distance from the model's vertical axis, normalised by the
               widest half-extent. Separates a limb from a flank.
  * `valid` -- whether any triangle covered the texel at all. Gutter texels
               get no paint.

An overlay authored against those channels is anatomically logical by
construction and survives a re-unwrap, which a hand-picked UV rectangle does
not.

The maps are a pure function of the glb, so they are cached next to the model
as `<glb stem>_anatomy.npz` and rebuilt only when missing or `--force`. They
are NOT checked in (see .gitignore) -- they are derived data, a few MB each,
and every consumer can regenerate them in about a second.

The glb itself is never modified. Nothing here writes a mesh.

Usage:  python3 tools/creature_anatomy_maps.py [species...] [--force] [--size N]
"""
import json
import os
import struct
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CREATURES = os.path.join(ROOT, "assets", "creatures", "tetherbound")

## Anatomy maps are rasterised at this edge length unless asked otherwise.
## Matches `_finish_default.output_size` in data/creatures/shiny_colourways.json
## -- overlays are composited against the FINISHED texture, so building the
## anatomy any larger would only be resampled away again.
DEFAULT_SIZE = 1024

## glTF component type -> numpy dtype.
_COMPONENT = {5120: np.int8, 5121: np.uint8, 5122: np.int16,
              5123: np.uint16, 5125: np.uint32, 5126: np.float32}
_COUNT = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def read_glb(path):
    with open(path, "rb") as handle:
        data = handle.read()
    magic, _version, _length = struct.unpack_from("<III", data, 0)
    assert magic == 0x46546C67, f"{path} is not a glb"
    offset, gltf, binary = 12, None, None
    while offset < len(data):
        chunk_len, chunk_type = struct.unpack_from("<II", data, offset)
        chunk = data[offset + 8: offset + 8 + chunk_len]
        if chunk_type == 0x4E4F534A:
            gltf = json.loads(chunk)
        elif chunk_type == 0x004E4942:
            binary = chunk
        offset += 8 + chunk_len
    return gltf, binary


def accessor(gltf, binary, index):
    """Read one glTF accessor into an (n, components) float/int array.

    Handles the strided case: a bufferView may interleave several attributes,
    in which case `byteStride` is the step between consecutive elements rather
    than the element's own size.
    """
    acc = gltf["accessors"][index]
    view = gltf["bufferViews"][acc["bufferView"]]
    dtype = _COMPONENT[acc["componentType"]]
    comps = _COUNT[acc["type"]]
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    count = acc["count"]
    item = np.dtype(dtype).itemsize * comps
    stride = view.get("byteStride", item)
    if stride == item:
        flat = np.frombuffer(binary, dtype=dtype, count=count * comps, offset=start)
        return flat.reshape(count, comps).astype(np.float64)
    out = np.empty((count, comps), dtype=np.float64)
    for i in range(count):
        out[i] = np.frombuffer(binary, dtype=dtype, count=comps,
                               offset=start + i * stride)
    return out


def mesh_arrays(gltf, binary):
    """Concatenate every primitive of every mesh into one (pos, nrm, uv, tri)."""
    positions, normals, uvs, tris = [], [], [], []
    base = 0
    for mesh in gltf.get("meshes", []):
        for prim in mesh.get("primitives", []):
            attrs = prim.get("attributes", {})
            if "POSITION" not in attrs or "TEXCOORD_0" not in attrs:
                continue
            pos = accessor(gltf, binary, attrs["POSITION"])
            uv = accessor(gltf, binary, attrs["TEXCOORD_0"])
            if "NORMAL" in attrs:
                nrm = accessor(gltf, binary, attrs["NORMAL"])
            else:
                nrm = np.zeros_like(pos)
            if "indices" in prim:
                idx = accessor(gltf, binary, prim["indices"]).astype(np.int64).ravel()
            else:
                idx = np.arange(len(pos), dtype=np.int64)
            positions.append(pos)
            normals.append(nrm)
            uvs.append(uv)
            tris.append(idx.reshape(-1, 3) + base)
            base += len(pos)
    if not positions:
        raise SystemExit("glb has no UV-mapped geometry")
    return (np.concatenate(positions), np.concatenate(normals),
            np.concatenate(uvs), np.concatenate(tris))


def rasterise(pos, nrm, uv, tris, size):
    """Scanline-free barycentric rasterisation of the UV triangles.

    One triangle at a time over its own UV bounding box, vectorised inside that
    box. The roster's meshes are 10k-40k triangles and the boxes are small, so
    this finishes in about a second per species -- fast enough that caching is a
    convenience rather than a necessity.

    glTF's UV origin is the texture's UPPER LEFT corner -- (0,0) is pixel
    (row 0, column 0) -- and a PIL-loaded image's row 0 is also its top. So v
    maps straight to the row index with NO flip, and the map is indexable with
    the same [y, x] as the image it will be composited onto.

    The first version of this function flipped v "because glTF's origin is
    top-left", which is the same fact used backwards, and it cost a full
    regeneration round to find. The symptom is not an obvious mirror: UV
    islands are scattered, so a vertically mirrored anatomy map does not put
    the moss upside down, it puts it in unrelated places -- moss on a boar's
    snout, a leaf on a rabbit's chin, green on a deer's hooves. Confirmed
    against mosshell, whose shipped texture has an unmistakable tan shell over
    a green body: unflipped, the `y>0.58 up>0.18` shell predicate lands on
    median hue 46 (tan) with the belly at 87 (green); flipped, the belly comes
    back tan too, because it is sampling the shell.
    """
    pos_map = np.zeros((size, size, 3), dtype=np.float32)
    nrm_map = np.zeros((size, size, 3), dtype=np.float32)
    valid = np.zeros((size, size), dtype=bool)

    px = np.clip(uv[:, 0], -0.001, 1.001) * (size - 1)
    py = np.clip(uv[:, 1], -0.001, 1.001) * (size - 1)

    for tri in tris:
        a, b, c = tri
        x0, x1 = px[[a, b, c]].min(), px[[a, b, c]].max()
        y0, y1 = py[[a, b, c]].min(), py[[a, b, c]].max()
        ix0, ix1 = int(np.floor(x0)), int(np.ceil(x1)) + 1
        iy0, iy1 = int(np.floor(y0)), int(np.ceil(y1)) + 1
        ix0, iy0 = max(ix0, 0), max(iy0, 0)
        ix1, iy1 = min(ix1, size), min(iy1, size)
        if ix1 <= ix0 or iy1 <= iy0:
            continue
        xs = np.arange(ix0, ix1)
        ys = np.arange(iy0, iy1)
        gx, gy = np.meshgrid(xs, ys)
        ax, ay = px[a], py[a]
        bx, by = px[b], py[b]
        cx, cy = px[c], py[c]
        denom = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(denom) < 1e-12:
            continue
        w0 = ((by - cy) * (gx - cx) + (cx - bx) * (gy - cy)) / denom
        w1 = ((cy - ay) * (gx - cx) + (ax - cx) * (gy - cy)) / denom
        w2 = 1.0 - w0 - w1
        # A half-texel of slack so seam texels on an island edge are covered
        # rather than left as gutter, which is what makes an overlay stop
        # short of an island boundary and read as a torn decal.
        inside = (w0 >= -0.02) & (w1 >= -0.02) & (w2 >= -0.02)
        if not inside.any():
            continue
        sub_y, sub_x = np.nonzero(inside)
        yy = ys[sub_y]
        xx = xs[sub_x]
        bw = np.stack([w0[inside], w1[inside], w2[inside]], axis=-1)
        bw = np.clip(bw, 0.0, 1.0)
        bw /= np.maximum(bw.sum(axis=-1, keepdims=True), 1e-9)
        pos_map[yy, xx] = (bw @ pos[[a, b, c]]).astype(np.float32)
        nrm_map[yy, xx] = (bw @ nrm[[a, b, c]]).astype(np.float32)
        valid[yy, xx] = True
    return pos_map, nrm_map, valid


def build(species, size=DEFAULT_SIZE, force=False):
    """Return (dict of channels, path). Cached as <glb stem>_anatomy.npz."""
    models = os.path.join(CREATURES, species, "models")
    glbs = sorted(f for f in os.listdir(models) if f.endswith(".glb"))
    if not glbs:
        raise SystemExit(f"{species}: no glb to derive anatomy from")
    glb_path = os.path.join(models, glbs[0])
    cache = os.path.join(models, os.path.splitext(glbs[0])[0] + "_anatomy.npz")
    if os.path.exists(cache) and not force:
        stored = np.load(cache)
        if int(stored["size"]) == size:
            return {k: stored[k] for k in stored.files}, cache

    gltf, binary = read_glb(glb_path)
    pos, nrm, uv, tris = mesh_arrays(gltf, binary)
    pos_map, nrm_map, valid = rasterise(pos, nrm, uv, tris, size)

    lo = pos.min(axis=0)
    hi = pos.max(axis=0)
    extent = np.maximum(hi - lo, 1e-6)
    unit = (pos_map - lo) / extent          # 0..1 inside the model's own box
    unit = np.clip(unit, 0.0, 1.0)

    length = np.linalg.norm(nrm_map, axis=-1, keepdims=True)
    unit_nrm = nrm_map / np.maximum(length, 1e-9)

    # Distance from the vertical axis through the box centre, normalised by
    # the widest half-extent, so 0 is the spine and 1 is the outermost limb.
    centre_x = (lo[0] + hi[0]) * 0.5
    centre_z = (lo[2] + hi[2]) * 0.5
    half = max(extent[0], extent[2]) * 0.5
    radial = np.sqrt((pos_map[..., 0] - centre_x) ** 2
                     + (pos_map[..., 2] - centre_z) ** 2) / max(half, 1e-6)

    channels = {
        "unit": unit.astype(np.float32),
        "nrm": unit_nrm.astype(np.float32),
        "radial": np.clip(radial, 0.0, 1.5).astype(np.float32),
        "valid": valid,
        "size": np.int32(size),
    }
    np.savez_compressed(cache, **channels)
    return channels, cache


def main():
    argv = [a for a in sys.argv[1:]]
    force = "--force" in argv
    if force:
        argv.remove("--force")
    size = DEFAULT_SIZE
    if "--size" in argv:
        i = argv.index("--size")
        size = int(argv[i + 1])
        del argv[i:i + 2]
    wanted = argv or sorted(
        d for d in os.listdir(CREATURES)
        if os.path.isdir(os.path.join(CREATURES, d, "models"))
        and any(f.endswith(".glb") for f in os.listdir(os.path.join(CREATURES, d, "models"))))
    for species in wanted:
        try:
            channels, cache = build(species, size, force)
        except SystemExit as err:
            print(f"skip {species}: {err}")
            continue
        cover = float(channels["valid"].mean())
        print("%-12s %s  (%.0f%% of the map is surface)"
              % (species, os.path.relpath(cache, ROOT), cover * 100))


if __name__ == "__main__":
    main()
