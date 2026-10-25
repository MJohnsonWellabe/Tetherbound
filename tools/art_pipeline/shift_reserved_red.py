"""Hard rule: red/oxblood is reserved for Team Tether. The GPU F36 roster
baseline (24 Oct 2026) found crimson frills on Riverdrake and Mirejaw (land and
water forms share these textures). This shifts only the saturated reds of a
creature albedo to a warm amber, keeping each texel's value, so the frills keep
their accent role without reading as the reserved colour. Browns and oranges
(hue above the red band) are untouched.

Re-running is close to a no-op: shifted texels sit at the amber hue, outside the red
band (JPEG re-encoding leaves a few stray texels; it still rewrites the GLB, so
re-pin the f36 recipe hash). The untouched originals are in git history.
An image embedded in a GLB is rewritten in the GLB too, under the same name, so
a fresh import extracts the corrected texture.

    python3 tools/art_pipeline/shift_reserved_red.py
"""
import io
import json
import os
import struct

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
C = os.path.join(ROOT, "assets", "creatures", "tetherbound")
# (glb or None, image file, embedded image name or None)
TARGETS = [
    ("riverdrake/models/creature_riverdrake_lod0.glb", "riverdrake/models/creature_riverdrake_lod0_Image_0.jpg",
     "Image_0"),
    (None, "riverdrake/models/riverdrake_extracted_base_color_vivid.png", None),
    ("mirejaw/candidate/models/creature_mirejaw_native.glb", "mirejaw/candidate/models/creature_mirejaw_native_Image_0.jpg",
     "Image_0"),
]
RED_HUE = (-15.0, 20.0)      # degrees, wrapping through 0
MIN_SAT = 0.45
MIN_VAL = 0.25
AMBER_HUE = 34.0
SAT_SCALE = 0.9


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


def shift(image):
    rgb = np.asarray(image.convert("RGB")).astype(np.float64) / 255.0
    h, s, v = _hsv(rgb)
    signed = np.where(h > 180.0, h - 360.0, h)
    mask = (signed >= RED_HUE[0]) & (signed <= RED_HUE[1]) & (s >= MIN_SAT) & (v >= MIN_VAL)
    out = rgb.copy()
    out[mask] = _rgb(np.full(mask.sum(), AMBER_HUE), s[mask] * SAT_SCALE, v[mask])
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
    for glb, image_path, embedded in TARGETS:
        src = os.path.join(C, image_path)
        ext = os.path.splitext(src)[1].lower()
        result, share = shift(Image.open(src))
        if share == 0.0:
            print("%s: no reserved red left" % image_path)
            continue
        data = _encode(result, ext)
        open(src, "wb").write(data)
        if glb:
            gltf, views = _read_glb(os.path.join(C, glb))
            image = next(i for i in gltf["images"] if i.get("name") == embedded)
            views[image["bufferView"]] = data
            image["mimeType"] = "image/jpeg" if ext in (".jpg", ".jpeg") else "image/png"
            _write_glb(os.path.join(C, glb), gltf, views)
        print("%s: %.2f%% shifted red->amber%s" % (image_path, share * 100, " (+ GLB)" if glb else ""))


if __name__ == "__main__":
    main()
