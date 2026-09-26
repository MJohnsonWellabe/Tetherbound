#!/usr/bin/env python3
"""Bake the Meadowhart's delivered saddle out of its production mesh, offline.

    python3 tools/art_pipeline/bare_meadowhart.py \
        --src assets/creatures/tetherbound/meadowhart/models/creature_meadowhart_lod0.glb \
        --out-dir assets/creatures/tetherbound/meadowhart/models [--report out.json]

VIS audit C1 (BLOCKER): the in-game Meadowhart had loose foreleg stumps, an
air gap under the chest and a smooth untextured "pill" torso, and the attack
clip lost its forelegs. Cause: the source glb carries a saddle, cinch, flaps
and stirrups fused into its one skinned surface (Meshy generated it from a
saddled reference sheet). The run-time adapter `meadowhart_bare_body.gd`
removes index-disconnected *components* in a tack band -- but the mesh is
split at every UV seam (185 index components, one after welding), so those
components are UV islands of the animal itself: the chest, shoulder and
foreleg tops went with the saddle, and a flat proxy torso was drawn over the
hole.

This tool keeps the animal whole and removes only the tack, by shape:

1. **Geometry.** In the saddle span (z between the rump and the withers) the
   body cross-section is modelled as an ellipse per slice, measured from the
   bare rump and withers slices either side. Every vertex outside it (seat,
   cantle, flaps, stirrups, straps) is pulled onto the ellipse, and tack that
   stood well proud goes just under it, so the delivered surface closes into
   a back. Vertices inside it (the real flank and belly) are untouched. The
   move is a pure function of position, so vertices duplicated along UV
   seams move together and no crack opens. Ends blend smoothly into the
   untouched rump and withers.
2. **Skin.** A moved vertex takes the joints/weights of the nearest unmoved
   body vertex, so a stirrup once weighted to a leg no longer drags a patch
   of the flank through the run clip.
3. **Texture.** The texels under each changed face are repainted with the
   animal's own coat: a tan-to-cream gradient by surface normal, sampled
   from that variant's clean rump and belly, with a fine grain taken from the
   rump itself. The normal map goes flat there and roughness takes the coat's
   median. The same mask repaints the base, shiny and vivid colourways.

Leaves (the shoulder mantle is the species' identity), head, legs, tail,
bones, bind pose and all six clips are untouched: the glb is edited in place
at the accessor level, never re-exported, so the clips cannot drift.

Deterministic, no network, no generator. Provenance: VIS audit C1, X04 lane.
"""

from __future__ import annotations

import argparse
import io
import json
import pathlib
import struct

import numpy as np
from PIL import Image

# Saddle span along the body (glTF z, head is +z) and its blend margins.
Z_REAR = -0.62
Z_FRONT = 0.06
BLEND = 0.10
# Where the bare reference slices are measured, beyond the blend margins.
REAR_SLICE = (-0.84, -0.72)
FRONT_SLICE = (0.14, 0.22)
# Slice centre height and a slight natural sag of the back between ends.
SAG = 0.02
# Tack standing this far outside the ellipse is tucked just under it.
TUCK_R = 1.04
TUCK_TO = 0.985
MOVE_EPS = 0.004
LEAF_HUE = (0.16, 0.45)
# Half-width inside which lower-body vertices are legs, never tack.
LEG_X = 0.29
# Between the fore and hind legs (glTF z) the lower body is belly, not leg.
LEG_Z = (-0.46, -0.04)
# In the saddle zone a face whose colour is this far from the coat is tack
# texture (leather, stitching, buckles) even where the surface was not moved.
COAT_DISTANCE = 0.09


def read_glb(path: pathlib.Path):
    raw = path.read_bytes()
    magic, version, _ = struct.unpack("<III", raw[:12])
    assert magic == 0x46546C67 and version == 2, "not a glb v2"
    jlen, jtype = struct.unpack("<II", raw[12:20])
    doc = json.loads(raw[20:20 + jlen])
    off = 20 + jlen
    blen, btype = struct.unpack("<II", raw[off:off + 8])
    return doc, bytearray(raw[off + 8:off + 8 + blen])


def write_glb(path: pathlib.Path, doc: dict, binary: bytes) -> None:
    js = json.dumps(doc, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    binary = bytes(binary) + b"\0" * ((4 - len(binary) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(binary)
    out = struct.pack("<III", 0x46546C67, 2, total)
    out += struct.pack("<II", len(js), 0x4E4F534A) + js
    out += struct.pack("<II", len(binary), 0x004E4942) + binary
    path.write_bytes(out)


DTYPES = {5126: np.float32, 5123: np.uint16, 5125: np.uint32, 5121: np.uint8}
WIDTH = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def view(doc, binary, index):
    acc = doc["accessors"][index]
    bv = doc["bufferViews"][acc["bufferView"]]
    assert "byteStride" not in bv or bv["byteStride"] in (0, WIDTH[acc["type"]] *
                                                          np.dtype(DTYPES[acc["componentType"]]).itemsize)
    start = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    arr = np.frombuffer(binary, dtype=DTYPES[acc["componentType"]],
                        count=acc["count"] * WIDTH[acc["type"]], offset=start)
    return arr.reshape(acc["count"], WIDTH[acc["type"]]) if WIDTH[acc["type"]] > 1 else arr, start


def put(binary, start, arr):
    data = np.ascontiguousarray(arr).tobytes()
    binary[start:start + len(data)] = data


def smooth(t):
    t = np.clip(t, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def slice_profile(p, zlo, zhi):
    s = p[(p[:, 2] >= zlo) & (p[:, 2] <= zhi)]
    mid = s[np.abs(s[:, 0]) < 0.05]
    top = float(np.percentile(mid[:, 1], 98))
    belly = float(np.percentile(mid[:, 1], 2))
    centre = 0.5 * (top + belly)
    band = s[np.abs(s[:, 1] - centre) < 0.08]
    half = float(np.percentile(np.abs(band[:, 0]), 95))
    return top, belly, half


def rgb_to_hsv(rgb):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx = rgb.max(-1)
    mn = rgb.min(-1)
    d = mx - mn + 1e-6
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) / 6.0
    s = np.where(mx > 0, (mx - mn) / (mx + 1e-6), 0)
    return h, s, mx


def raster_mask(uv_tris, size):
    """Boolean mask of texels covered by the UV triangles (glTF uv: v down)."""
    w, h = size
    mask = np.zeros((h, w), dtype=bool)
    for tri in uv_tris:
        xs = tri[:, 0] * w
        ys = tri[:, 1] * h
        x0, x1 = int(np.floor(xs.min())) - 2, int(np.ceil(xs.max())) + 2
        y0, y1 = int(np.floor(ys.min())) - 2, int(np.ceil(ys.max())) + 2
        x0, y0 = max(x0, 0), max(y0, 0)
        x1, y1 = min(x1, w - 1), min(y1, h - 1)
        if x1 < x0 or y1 < y0:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        (ax, ay), (bx, by), (cx, cy) = zip(xs, ys)
        den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
        if abs(den) < 1e-9:
            continue
        l1 = ((by - cy) * (gx - cx) + (cx - bx) * (gy - cy)) / den
        l2 = ((cy - ay) * (gx - cx) + (ax - cx) * (gy - cy)) / den
        l3 = 1 - l1 - l2
        # ~2 texel dilation so the repaint covers mip/filter bleed at seams.
        e = -2.0 / max(w * (xs.max() - xs.min() + 1e-6), 4.0)
        inside = (l1 >= e) & (l2 >= e) & (l3 >= e)
        mask[y0:y1 + 1, x0:x1 + 1] |= inside
    return mask


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--report", default="")
    args = ap.parse_args()
    src = pathlib.Path(args.src)
    out_dir = pathlib.Path(args.out_dir)
    doc, binary = read_glb(src)
    prim = doc["meshes"][0]["primitives"][0]
    attrs = prim["attributes"]
    pos, pos_at = view(doc, binary, attrs["POSITION"])
    nrm, nrm_at = view(doc, binary, attrs["NORMAL"])
    uv, _ = view(doc, binary, attrs["TEXCOORD_0"])
    joints, joints_at = view(doc, binary, attrs["JOINTS_0"])
    weights, weights_at = view(doc, binary, attrs["WEIGHTS_0"])
    idx, _ = view(doc, binary, prim["indices"])
    tris = idx.reshape(-1, 3).astype(np.int64)
    p = pos.astype(np.float64).copy()

    rear = slice_profile(p, *REAR_SLICE)
    front = slice_profile(p, *FRONT_SLICE)

    # Blend weight along z: 1 inside the saddle span, easing to 0 at the ends.
    z = p[:, 2]
    w = smooth((z - (Z_REAR - BLEND)) / BLEND) * smooth(((Z_FRONT + BLEND) - z) / BLEND)
    t = np.clip((z - REAR_SLICE[1]) / (FRONT_SLICE[0] - REAR_SLICE[1]), 0, 1)
    top = rear[0] + (front[0] - rear[0]) * t - SAG * np.sin(np.pi * t)
    belly = rear[1] + (front[1] - rear[1]) * t
    half = rear[2] + (front[2] - rear[2]) * t
    centre = 0.5 * (top + belly)
    dy = p[:, 1] - centre
    b = np.where(dy >= 0, top - centre, centre - belly)
    r = np.sqrt((p[:, 0] / half) ** 2 + (dy / b) ** 2)
    target_r = np.where(r > TUCK_R, TUCK_TO, 1.0)
    scale = np.where(r > 1.0, target_r / np.maximum(r, 1e-9), 1.0)
    new = p.copy()
    new[:, 0] = p[:, 0] * (1 + (scale - 1) * w)
    new[:, 1] = centre + dy * (1 + (scale - 1) * w)
    moved = np.linalg.norm(new - p, axis=1) > MOVE_EPS
    # Only the saddle zone may change; leg tops below the belly line are not
    # tack even when they lie outside the ellipse's lower half.
    # Legs and thighs sit below the slice centre inside the flank line; only
    # lateral outliers (flaps, stirrups) are tack down there.
    leg_z = (p[:, 2] < LEG_Z[0]) | (p[:, 2] > LEG_Z[1])
    leg = leg_z & (p[:, 1] < centre) & (np.abs(p[:, 0]) < LEG_X)
    moved &= ~leg
    new[~moved] = p[~moved]

    # Skin: moved vertices copy the nearest unmoved body vertex's skin.
    anchor = np.where(~moved & (w > 0.0))[0]
    if anchor.size == 0:
        anchor = np.where(~moved)[0]
    for i in np.where(moved)[0]:
        d = np.sum((new[anchor] - new[i]) ** 2, axis=1)
        j = anchor[int(np.argmin(d))]
        joints[i] = joints[j]
        weights[i] = weights[j]

    # Normals: area-weighted, accumulated per welded position so UV seams stay smooth.
    key = np.round(new / 1e-4).astype(np.int64)
    _, weld = np.unique(key, axis=0, return_inverse=True)
    weld = weld.reshape(-1)
    fn = np.cross(new[tris[:, 1]] - new[tris[:, 0]], new[tris[:, 2]] - new[tris[:, 0]])
    acc = np.zeros((weld.max() + 1, 3))
    for k in range(3):
        np.add.at(acc, weld[tris[:, k]], fn)
    vn = acc[weld]
    vn /= np.maximum(np.linalg.norm(vn, axis=1, keepdims=True), 1e-12)
    touched_v = moved.copy()
    face_touched = touched_v[tris].any(axis=1)
    out_n = nrm.astype(np.float64).copy()
    # Recompute normals for every vertex of a touched face (its ring changed).
    ring = np.zeros(len(p), dtype=bool)
    ring[tris[face_touched].reshape(-1)] = True
    out_n[ring] = vn[ring]

    # Textures. Faces to repaint: every changed face, plus leather-dark faces
    # of the saddle zone that already lay inside the body line.
    images = {img["name"]: img for img in doc["images"]}

    def load_image(name):
        bv = doc["bufferViews"][images[name]["bufferView"]]
        s = bv.get("byteOffset", 0)
        return Image.open(io.BytesIO(bytes(binary[s:s + bv["byteLength"]])))

    base = np.asarray(load_image("base_color").convert("RGB")).astype(np.float32) / 255.0
    H, W = base.shape[:2]
    fuv = uv[tris].astype(np.float64)
    cen_uv = fuv.mean(axis=1)
    cx = np.clip((cen_uv[:, 0] * W).astype(int), 0, W - 1)
    cy = np.clip((cen_uv[:, 1] * H).astype(int), 0, H - 1)
    fh, fs, fv = rgb_to_hsv(base[cy, cx])
    fc = new[tris].mean(axis=1)
    fw = w[tris].mean(axis=1)
    leaf = (fh > LEAF_HUE[0]) & (fh < LEAF_HUE[1]) & (fs > 0.25)
    coat_guess = np.median(base[cy[(fw > 0.5) & ~leaf & ~face_touched & (fs > 0.3)],
                                  cx[(fw > 0.5) & ~leaf & ~face_touched & (fs > 0.3)]], axis=0)
    off_coat = np.linalg.norm(base[cy, cx] - coat_guess, axis=1) > COAT_DISTANCE
    spot = (fv > 0.75) & (fs < 0.3)
    in_zone = (fw > 0.5) & (fc[:, 1] > 0.6)
    repaint = (face_touched | (in_zone & off_coat & ~spot)) & ~leaf
    mask = raster_mask(fuv[repaint], (W, H))
    for _ in range(2):  # dilate two texels so filtering never reaches old leather
        mask = mask | np.roll(mask, 1, 0) | np.roll(mask, -1, 0) | np.roll(mask, 1, 1) | np.roll(mask, -1, 1)

    # Per-texel coat colour: interpolate the face normal's up-component over
    # the painted texels (flat per face is enough at 2048 on a 2 m animal),
    # then add the rump's own grain.
    up = np.zeros((H, W), dtype=np.float32)
    count = np.zeros((H, W), dtype=np.float32)
    fnu = fn[repaint] / np.maximum(np.linalg.norm(fn[repaint], axis=1, keepdims=True), 1e-12)
    for tri, n_up in zip(fuv[repaint], fnu[:, 1]):
        m = raster_mask([tri], (W, H))
        up[m] += n_up
        count[m] += 1
    up = np.where(count > 0, up / np.maximum(count, 1), 0.0)

    def rump_and_belly(img):
        rump_f = (fc[:, 2] > -0.84) & (fc[:, 2] < -0.70) & (fc[:, 1] > 0.95) & ~leaf
        rs = img[cy[rump_f], cx[rump_f]]
        # Rump carries white fawn spots: take the coat, not the spots.
        coat_only = rs[rgb_to_hsv(rs)[1] > 0.3]
        rs = coat_only if len(coat_only) > 8 else rs
        tan = np.median(rs, axis=0)
        # The underside is the coat lightened towards the cream chest; a
        # sampled belly is unreliable here (cinch leather and leg shadow).
        return tan, tan * 0.8 + 0.2 * np.array([0.93, 0.86, 0.74]), rs

    rng = np.random.default_rng(7)
    grain = rng.normal(0.0, 1.0, (H, W)).astype(np.float32)
    grain = np.asarray(Image.fromarray(((grain * 0.25 + 0.5).clip(0, 1) * 255).astype(np.uint8))
                       .resize((W // 4, H // 4), Image.BILINEAR).resize((W, H), Image.BICUBIC),
                       dtype=np.float32) / 255.0 - 0.5

    def paint(img):
        tan, cream, samples = rump_and_belly(img)
        spread = float(np.std(rgb_to_hsv(samples)[2])) if len(samples) > 8 else 0.05
        k = smooth((up + 0.55) / 0.75)[..., None]
        coat = cream[None, None, :] * (1 - k) + tan[None, None, :] * k
        coat = coat * (1.0 + grain[..., None] * min(spread * 2.2, 0.35))
        out = img.copy()
        out[mask] = np.clip(coat[mask], 0, 1)
        return out, tan, cream

    painted, tan, cream = paint(base)

    def paint_at(img):
        """A colourway at another resolution: paint at the base size, resample."""
        h, w = img.shape[:2]
        if (h, w) == (H, W):
            return paint(img)[0]
        big = np.asarray(Image.fromarray((img * 255 + 0.5).astype(np.uint8)).resize((W, H), Image.BICUBIC),
                         dtype=np.float32) / 255.0
        done = paint(big)[0]
        small = np.asarray(Image.fromarray((done * 255 + 0.5).astype(np.uint8)).resize((w, h), Image.LANCZOS),
                           dtype=np.float32) / 255.0
        m = np.asarray(Image.fromarray(mask.astype(np.uint8) * 255).resize((w, h), Image.BILINEAR)) > 0
        out = img.copy()
        out[m] = small[m]
        return out
    report = {"rear_slice": rear, "front_slice": front, "moved_vertices": int(moved.sum()),
              "repainted_faces": int(repaint.sum()), "repainted_texels": int(mask.sum()),
              "coat_tan": tan.tolist(), "coat_cream": cream.tolist()}

    def encode(arr, fmt):
        buf = io.BytesIO()
        Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8)).save(
            buf, fmt, **({"quality": 95} if fmt == "JPEG" else {"optimize": True}))
        return buf.getvalue()

    normal = np.asarray(load_image("normal").convert("RGB")).astype(np.float32) / 255.0
    normal[mask] = np.array([0.5, 0.5, 1.0])
    mr = np.asarray(load_image("metallic_roughness").convert("RGB")).astype(np.float32) / 255.0
    coat_rough = np.median(mr[cy[~repaint & ~leaf], cx[~repaint & ~leaf]], axis=0)
    mr[mask] = coat_rough
    new_images = {"base_color": encode(painted, "PNG"), "normal": encode(normal, "JPEG"),
                  "metallic_roughness": encode(mr, "PNG")}

    # Write vertex data in place, then rebuild the buffer with the new images.
    put(binary, pos_at, new.astype(np.float32))
    put(binary, nrm_at, out_n.astype(np.float32))
    put(binary, joints_at, joints)
    put(binary, weights_at, weights)
    pos_acc = doc["accessors"][attrs["POSITION"]]
    pos_acc["min"] = new.min(axis=0).astype(np.float32).tolist()
    pos_acc["max"] = new.max(axis=0).astype(np.float32).tolist()
    image_views = {doc["images"][i]["bufferView"]: doc["images"][i]["name"] for i in range(len(doc["images"]))}
    rebuilt = bytearray()
    for i, bv in enumerate(doc["bufferViews"]):
        s = bv.get("byteOffset", 0)
        chunk = bytes(binary[s:s + bv["byteLength"]])
        if i in image_views and image_views[i] in new_images:
            chunk = new_images[image_views[i]]
        rebuilt += b"\0" * ((4 - len(rebuilt) % 4) % 4)
        bv["byteOffset"] = len(rebuilt)
        bv["byteLength"] = len(chunk)
        rebuilt += chunk
    doc["buffers"][0]["byteLength"] = len(rebuilt)
    stem = src.stem
    write_glb(out_dir / src.name, doc, rebuilt)

    # The external colourway textures and the loose copies beside the glb.
    for suffix in ("", "_shiny", "_vivid"):
        path = out_dir / f"{stem}_base_color{suffix}.png"
        src_path = src.parent / path.name
        if not src_path.exists():
            continue
        img = np.asarray(Image.open(src_path).convert("RGB")).astype(np.float32) / 255.0
        painted_v = paint_at(img)
        Image.fromarray((painted_v * 255 + 0.5).astype(np.uint8)).save(path, optimize=True)
    for name, fmt, ext in (("normal", "JPEG", ".jpg"), ("metallic_roughness", "PNG", ".png")):
        path = out_dir / f"{stem}_{name}{ext}"
        if (src.parent / path.name).exists():
            path.write_bytes(new_images[name])
    if args.report:
        pathlib.Path(args.report).write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report))


if __name__ == "__main__":
    main()
