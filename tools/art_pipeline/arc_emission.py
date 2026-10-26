"""Storm-creature arc emission (owner, 25 Oct: glow only where natural to the
element -- lightning arcs on storm creatures, never seams on fur or hide).

Some storm creatures have their lightning painted into the albedo with no
emissive map, so since the 24 Oct Forward+ emission-floor change their arcs
light like fur on Medium and High. Stormursa ships a real emissive map and is
the model here. This builds one from the albedo's own arc pixels (saturated
arc-hue pixels lifted above the fur around them) and embeds it as the
material's emissiveTexture. The base colour, mesh, rig and clips are untouched.

    python3 tools/art_pipeline/arc_emission.py tanglevolt
"""
import io
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)
import shift_reserved_red as T  # noqa: E402  (HSV helpers and GLB reader/writer)

SPEC = os.path.join(ROOT, "data", "creatures", "arc_emission.json")


def mask(rgb, rule):
    """Arc pixels: in the arc hue band, saturated, and brighter than the fur
    around them by `lift` (value minus a `blur_px` local mean). The lift is what
    separates a thin painted arc from violet fur of the same hue."""
    h, s, v = T._hsv(rgb)
    lo, hi = rule["hue"]
    local = np.asarray(Image.fromarray((v * 255).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(float(rule.get("blur_px", 6.0))))).astype(np.float64) / 255.0
    return (h >= lo) & (h <= hi) & (s >= rule["sat_min"]) & ((v - local) >= rule["lift"])


def build(species, rule):
    glb = os.path.join(ROOT, rule["model"])
    gltf, views = T._read_glb(glb)
    material = gltf["materials"][0]
    base_tex = material["pbrMetallicRoughness"]["baseColorTexture"]["index"]
    image_index = gltf["textures"][base_tex]["source"]
    raw = views[gltf["images"][image_index]["bufferView"]]
    rgb = np.asarray(Image.open(io.BytesIO(raw)).convert("RGB")).astype(np.float64) / 255.0
    arc = mask(rgb, rule)
    alpha = Image.fromarray((arc * 255).astype(np.uint8), "L").filter(
        ImageFilter.GaussianBlur(float(rule.get("soften_px", 1.0))))
    weight = np.asarray(alpha).astype(np.float64)[..., None] / 255.0
    emissive = np.clip(rgb * weight * float(rule.get("gain", 1.0)), 0.0, 1.0)
    out = Image.fromarray((emissive * 255).astype(np.uint8), "RGB")
    buf = io.BytesIO()
    out.save(buf, "PNG", optimize=True)
    data = buf.getvalue()
    name = "arc_emission"
    existing = next((i for i, img in enumerate(gltf["images"]) if img.get("name") == name), None)
    if existing is None:
        gltf["bufferViews"].append({"buffer": 0, "byteOffset": 0, "byteLength": 0})
        views.append(data)
        gltf["images"].append({"name": name, "mimeType": "image/png", "bufferView": len(views) - 1})
        sampler = gltf["textures"][base_tex].get("sampler")
        texture = {"source": len(gltf["images"]) - 1}
        if sampler is not None:
            texture["sampler"] = sampler
        gltf["textures"].append(texture)
        material["emissiveTexture"] = {"index": len(gltf["textures"]) - 1}
    else:
        views[gltf["images"][existing]["bufferView"]] = data
    material["emissiveFactor"] = [1.0, 1.0, 1.0]
    T._write_glb(glb, gltf, views)
    print("%s: arc emission over %.2f%% of the albedo -> %s" % (species, arc.mean() * 100, rule["model"]))


def main():
    spec = json.load(open(SPEC))["species"]
    for species in sys.argv[1:] or sorted(spec):
        build(species, spec[species])


if __name__ == "__main__":
    main()
