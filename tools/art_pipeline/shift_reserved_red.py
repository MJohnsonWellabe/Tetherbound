"""Hard rule: red/oxblood is reserved for Team Tether. The GPU F36 roster
baseline (24 Oct 2026) found crimson frills on Riverdrake and Mirejaw (land and
water forms share these textures). This shifts only the saturated reds of a
creature albedo to a gold-tan, keeping each texel's value, so the frills keep
their accent role without reading as the reserved colour. Browns and oranges
(below each target's saturation floor) are untouched.

Every target repaints from its untouched original, read from git at
ORIGINAL_REV (the commit before this tool first ran), so a re-run or a re-tune
never compounds. An image embedded in a GLB is rewritten in the GLB too, under
the same name, so a fresh import extracts the corrected texture; re-pin the
f36 recipe hash after a run.

GPU batch 1 (25 Oct): amber at 34 deg still read red-orange on Riverdrake's
crest, and Mirejaw's rust-brown frill roots sat just above the first band.
Each target now has its own band and a gold-tan target.

    python3 tools/art_pipeline/shift_reserved_red.py
"""
import io
import json
import os
import struct
import subprocess

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
C = os.path.join(ROOT, "assets", "creatures", "tetherbound")
ORIGINAL_REV = "f3d6d65f0^"
# (glb or None, image file, embedded image name or None, band)
RIVERDRAKE = {"hue": (-15.0, 32.0), "min_sat": 0.4, "min_val": 0.15, "to_hue": 42.0, "sat_scale": 0.7}
# Mirejaw's body is a warm taupe-brown (hue 20-40, sat under 0.55); only the
# saturated rust at the frill roots is moved.
MIREJAW = {"hue": (-15.0, 26.0), "min_sat": 0.55, "min_val": 0.12, "to_hue": 40.0, "sat_scale": 0.6}
TARGETS = [
    ("riverdrake/models/creature_riverdrake_lod0.glb", "riverdrake/models/creature_riverdrake_lod0_Image_0.jpg",
     "Image_0", RIVERDRAKE),
    (None, "riverdrake/models/riverdrake_extracted_base_color_vivid.png", None, RIVERDRAKE),
    ("mirejaw/candidate/models/creature_mirejaw_native.glb", "mirejaw/candidate/models/creature_mirejaw_native_Image_0.jpg",
     "Image_0", MIREJAW),
]


def _hsv(rgb):
    mx = rgb.max(-1)
    mn = rgb.min(-1)
    d = mx - mn
    s = np.where(mx > 0, d / np.maximum(mx, 1e-9), 0.0)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    h = np.zeros_like(mx)
    m = d > 1e-9
    rc = np.where(m, (mx - r) / np.maximum(d, 1e-9), 0)
    gc = np.where(m, (mx - g) / np.maximum(d, 1e-9), 0)
    bc = np.where(m, (mx - b) / np.maximum(d, 1e-9), 0)
    h = np.where((mx == r) & m, bc - gc, h)
    h = np.where((mx == g) & m, 2.0 + rc - bc, h)
    h = np.where((mx == b) & m, 4.0 + gc - rc, h)
    return (h / 6.0) % 1.0 * 360.0, s, mx


def _rgb(h, s, v):
    h6 = (h / 60.0) % 6.0
    c = v * s
    x = c * (1 - np.abs(h6 % 2 - 1))
    z = np.zeros_like(h)
    h6 = h6[..., None]
    out = np.select([h6 < 1, h6 < 2, h6 < 3, h6 < 4, h6 < 5],
                    [np.stack([c, x, z], -1), np.stack([x, c, z], -1), np.stack([z, c, x], -1),
                     np.stack([z, x, c], -1), np.stack([x, z, c], -1)], np.stack([c, z, x], -1))
    return out + (v - c)[..., None]


def shift(image, band):
    rgb = np.asarray(image.convert("RGB")).astype(np.float64) / 255.0
    h, s, v = _hsv(rgb)
    signed = np.where(h > 180.0, h - 360.0, h)
    lo, hi = band["hue"]
    mask = (signed >= lo) & (signed <= hi) & (s >= band["min_sat"]) & (v >= band["min_val"])
    out = rgb.copy()
    out[mask] = _rgb(np.full(mask.sum(), band["to_hue"]), s[mask] * band["sat_scale"], v[mask])
    result = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGB")
    if image.mode == "RGBA":
        result.putalpha(image.getchannel("A"))
    return result, float(mask.mean())


def _encode(img, ext):
    buf = io.BytesIO()
    if ext in (".jpg", ".jpeg"):
        img.convert("RGB").save(buf, "JPEG", quality=92)
    else:
        img.save(buf, "PNG", optimize=True)
    return buf.getvalue()


def _read_glb(path):
    data = open(path, "rb").read()
    n = struct.unpack_from("<I", data, 12)[0]
    gltf = json.loads(data[20:20 + n])
    blob = data[20 + n + 8:20 + n + 8 + struct.unpack_from("<I", data, 20 + n)[0]]
    views = [blob[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]] for v in gltf["bufferViews"]]
    return gltf, views


def _write_glb(path, gltf, views):
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
    out += struct.pack("<II", len(text), 0x4E4F534A) + text + struct.pack("<II", len(blob), 0x004E4942) + bytes(blob)
    open(path, "wb").write(out)


def main():
    for glb, image_path, embedded, band in TARGETS:
        src = os.path.join(C, image_path)
        ext = os.path.splitext(src)[1].lower()
        rel = os.path.relpath(src, ROOT)
        original = subprocess.run(["git", "-C", ROOT, "show", "%s:%s" % (ORIGINAL_REV, rel)],
                                  check=True, capture_output=True).stdout
        result, share = shift(Image.open(io.BytesIO(original)), band)
        data = _encode(result, ext)
        open(src, "wb").write(data)
        if glb:
            gltf, views = _read_glb(os.path.join(C, glb))
            image = next(i for i in gltf["images"] if i.get("name") == embedded)
            views[image["bufferView"]] = data
            image["mimeType"] = "image/jpeg" if ext in (".jpg", ".jpeg") else "image/png"
            _write_glb(os.path.join(C, glb), gltf, views)
        print("%s: %.2f%% shifted to hue %d%s" % (image_path, share * 100, band["to_hue"], " (+ GLB)" if glb else ""))

if __name__ == "__main__":
    main()
