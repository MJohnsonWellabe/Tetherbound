"""Owner touch pass (24 Oct 2026): "adding some energy, some elemental effects,
and some war torn appearance or hardened appearance ... Don't go overboard."

Bakes one or two light, region-placed touches (hardened/weathered patches,
scars) into a naturalistic remake's own albedo, on top of the existing model.
No new mesh: the GLB keeps every node, skin, clip and material; only its
base-colour image is replaced, as a JPEG under the same image name, so the
imported texture path (`<glb stem>_Image_0.jpg`) and every lookup keyed on it
(aspect-variant repaints, shiny/vivid colourways) stay where they were.

The untouched albedo is kept once, the first time a species is touched, at
`<remake>/source/touch/albedo_base.jpg` (a .gdignore folder), and every run
repaints from that copy, so re-running never compounds a touch.

Spec: data/creatures/creature_touches.json, keyed by species:
  {"source_model": "<species>/candidate_xxx", "overlays": [...],
   "also": ["<species>/candidate_yyy"]}
`also` lists builds of the same remake that share its UV layout and albedo
(Mudsnout's tusk build); each gets the same painted image.

`glow` (optional) lists energy seams in the same overlay vocabulary. They are
not baked into the albedo: they are written as an RGBA mask,
`<glb stem>_touch_glow.png` beside the model (colour where the seam is, alpha
its strength), which species.json names as the placeholder's `touch_glow` and
creature_body draws as a thin unshaded shell over the skinned mesh. Baking
emission into the material would switch off the night floor for that surface.
Overlays are tools/creature_overlays.py overlays (mode "shade" for hardened
patches and scars), placed by the remake's anatomy map.

  python3 tools/art_pipeline/creature_touch.py trailpup mudsnout
"""
import hashlib
import io
import json
import os
import struct
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from creature_overlays import apply_overlays  # noqa: E402

SPEC_PATH = os.path.join(ROOT, "data", "creatures", "creature_touches.json")
CREATURES = os.path.join(ROOT, "assets", "creatures", "tetherbound")
JPEG_QUALITY = 92


def read_glb(path):
    data = open(path, "rb").read()
    json_len = struct.unpack_from("<I", data, 12)[0]
    gltf = json.loads(data[20:20 + json_len])
    bin_at = 20 + json_len
    bin_len = struct.unpack_from("<I", data, bin_at)[0]
    return gltf, bytes(data[bin_at + 8:bin_at + 8 + bin_len])


def write_glb(path, gltf, views):
    """Rebuild the BIN chunk from the given per-bufferView byte strings."""
    blob = bytearray()
    for index, raw in enumerate(views):
        while len(blob) % 4:
            blob.append(0)
        gltf["bufferViews"][index]["byteOffset"] = len(blob)
        gltf["bufferViews"][index]["byteLength"] = len(raw)
        blob += raw
    while len(blob) % 4:
        blob.append(0)
    gltf["buffers"][0]["byteLength"] = len(blob)
    text = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    while len(text) % 4:
        text += b" "
    total = 12 + 8 + len(text) + 8 + len(blob)
    out = struct.pack("<III", 0x46546C67, 2, total)
    out += struct.pack("<II", len(text), 0x4E4F534A) + text
    out += struct.pack("<II", len(blob), 0x004E4942) + bytes(blob)
    with open(path, "wb") as f:
        f.write(out)


def base_color_image(gltf):
    material = gltf["materials"][0]
    texture = material["pbrMetallicRoughness"]["baseColorTexture"]["index"]
    return gltf["textures"][texture]["source"]


def _open(remake):
    models = os.path.join(CREATURES, remake, "models")
    glb_name = sorted(f for f in os.listdir(models) if f.endswith(".glb"))[0]
    glb = os.path.join(models, glb_name)
    gltf, blob = read_glb(glb)
    views = [blob[v.get("byteOffset", 0):v.get("byteOffset", 0) + v["byteLength"]]
             for v in gltf["bufferViews"]]
    return models, glb_name, glb, gltf, views


def _write(remake, jpeg):
    models, glb_name, glb, gltf, views = _open(remake)
    image = gltf["images"][base_color_image(gltf)]
    views[image["bufferView"]] = jpeg
    image["mimeType"] = "image/jpeg"
    write_glb(glb, gltf, views)
    # The import extracts this image beside the GLB; write it too so the
    # extracted texture matches before the next reimport.
    extracted = os.path.join(models, "%s_%s.jpg" % (os.path.splitext(glb_name)[0], image.get("name", "Image_0")))
    with open(extracted, "wb") as f:
        f.write(jpeg)
    return glb


def touch(species, entry):
    remake = entry["source_model"]
    _models, _name, _glb, gltf, views = _open(remake)
    image = gltf["images"][base_color_image(gltf)]
    base_dir = os.path.join(CREATURES, remake, "source", "touch")
    base_path = os.path.join(base_dir, "albedo_base.jpg")
    if not os.path.exists(base_path):
        os.makedirs(base_dir, exist_ok=True)
        open(os.path.join(base_dir, ".gdignore"), "w").close()
        with open(base_path, "wb") as f:
            f.write(views[image["bufferView"]])
    source = Image.open(base_path).convert("RGB")
    rgb = np.asarray(source).astype(np.float64) / 255.0
    painted, notes = apply_overlays(rgb, remake, entry.get("overlays", []), source.width)
    out = Image.fromarray((np.clip(painted, 0, 1) * 255).astype(np.uint8), "RGB")
    buffer = io.BytesIO()
    out.save(buffer, "JPEG", quality=JPEG_QUALITY)
    jpeg = buffer.getvalue()
    for target in [remake] + list(entry.get("also", [])):
        glb = _write(target, jpeg)
        print("%s: touched %s (%d bytes, sha %s)" % (
            species, os.path.relpath(glb, ROOT), len(jpeg), hashlib.sha256(jpeg).hexdigest()[:12]))
    for note in notes:
        print("   %s" % note)
    if entry.get("glow"):
        _write_glow(species, remake, entry["glow"], source.width)


def _write_glow(species, remake, glows, size):
    """RGBA seam mask: each glow overlay's own colour, alpha its coverage."""
    rgb = np.zeros((size, size, 3))
    alpha = np.zeros((size, size))
    for glow in glows:
        # Paint the overlay's mask as pure value onto black to read it back.
        probe = dict(glow, mode="shade", set_val=1.0, set_sat=0.0)
        probe.pop("match", None)
        painted, notes = apply_overlays(np.zeros((size, size, 3)), remake, [probe], size)
        mask = painted.max(axis=-1) * float(glow.get("strength", 1.0))
        colour = np.array([int(str(glow["color"]).lstrip("#")[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])
        rgb = rgb * (1.0 - mask[..., None]) + colour * mask[..., None]
        alpha = np.maximum(alpha, mask)
        for note in notes:
            print("   glow %s" % note)
    out = np.dstack([np.clip(rgb, 0, 1), np.clip(alpha, 0, 1)])
    models, glb_name, _glb, _gltf, _views = _open(remake)
    path = os.path.join(models, "%s_touch_glow.png" % os.path.splitext(glb_name)[0])
    Image.fromarray((out * 255).astype(np.uint8), "RGBA").save(path, optimize=True)
    print("%s: glow mask %s (%.1f%% of the surface)" % (
        species, os.path.relpath(path, ROOT), 100.0 * float((alpha > 0.05).mean())))


def main():
    spec = json.load(open(SPEC_PATH))
    wanted = [a for a in sys.argv[1:] if not a.startswith("--")] or [k for k in spec if not k.startswith("_")]
    for species in wanted:
        touch(species, spec[species])


if __name__ == "__main__":
    main()
