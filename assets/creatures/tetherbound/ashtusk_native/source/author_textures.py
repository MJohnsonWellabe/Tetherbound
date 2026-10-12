"""Native-UV Ashtusk colourway; reuses the installed CPU art pipeline.

Run from any directory. --output may select a private inspection directory.
Only the two derived PNGs are written; source geometry/textures are read-only.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / "tools"))
from creature_anatomy_maps import read_glb, mesh_arrays, rasterise
from creature_overlays import _smoothstep
from generate_aspect_variant_textures import build_glow_map
from repaint_creature_textures import repaint

MODEL = ROOT / "assets/creatures/tetherbound/tuskroot/candidate/models/creature_tuskroot_native.glb"
ALBEDO = MODEL.with_name("creature_tuskroot_native_Image_0.jpg")
MODEL_SHA = "acaefabb7ca82d24da26ca0019f6b409369f9fc616b4255bca40202bf5945427"
ALBEDO_SHA = "ad23a86a9308fa6f1a0343a8c20f03168cb56423d04ac6755d14254e0bcf2db5"
SIZE = 2048


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parents[1] / "models")
    args = parser.parse_args()
    for path, expected in [(MODEL, MODEL_SHA), (ALBEDO, ALBEDO_SHA)]:
        if hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            raise SystemExit(f"Native source changed; re-inspect before authoring: {path}")
    original = np.asarray(Image.open(ALBEDO).convert("RGB"))
    if original.shape != (SIZE, SIZE, 3):
        raise SystemExit("Native atlas must remain 2048 x 2048 RGB")
    spec = json.loads((ROOT / "data/creatures/aspect_variants.json").read_text())["variants"]["ashtusk"]
    # Preserve the established Ashtusk brown/soot rules. The native mesh adds
    # bright moss: convert only that native colour family to desaturated ash.
    rules = [{"match": {"hue": [55, 165], "sat_min": 0.12},
              "set_hue": 25, "set_sat": 0.10, "val_scale": 0.48}] + spec["rules"]
    args.output.mkdir(parents=True, exist_ok=True)
    albedo_path = args.output / "ashtusk_native_extracted_base_color_ashtusk.png"
    emissive_path = args.output / "ashtusk_native_extracted_emissive_ashtusk.png"
    # No output_size, resampling, despeckle or new overlays. Pixel coordinates
    # and source shading remain fixed through the established HSV operation.
    repaint(str(ALBEDO), rules, str(albedo_path), finish=spec["finish"])
    painted = np.asarray(Image.open(albedo_path).convert("RGB")).astype(np.float64) / 255.0
    source = original.astype(np.float64) / 255.0
    yy, xx = np.mgrid[:SIZE, :SIZE]
    eyes = np.zeros((SIZE, SIZE), dtype=np.float64)
    # Inspected native-atlas eye ellipses, not old-UV masks. Keep irises,
    # pupils, catchlights and eyelids unchanged; feather only the outer fur.
    for cx, cy, rx, ry in [(1168, 1653, 45, 56), (266, 1855, 49, 36)]:
        radius = np.sqrt(((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2)
        eyes = np.maximum(eyes, 1.0 - _smoothstep(1.0, 1.25, radius))
    painted = painted * (1.0 - eyes[..., None]) + source * eyes[..., None]
    encoded = np.rint(np.clip(painted, 0, 1) * 255).astype(np.uint8)
    Image.fromarray(encoded, "RGB").save(albedo_path, optimize=True)

    gltf, binary = read_glb(MODEL)
    pos, nrm, uv, tris = mesh_arrays(gltf, binary)
    positions, normals, valid = rasterise(pos, nrm, uv, tris, SIZE)
    lo, hi = pos.min(axis=0), pos.max(axis=0)
    extent = np.maximum(hi - lo, 1e-6)
    unit = np.clip((positions - lo) / extent, 0.0, 1.0)
    normals /= np.maximum(np.linalg.norm(normals, axis=-1, keepdims=True), 1e-9)
    radial = np.sqrt((positions[..., 0] - (lo[0] + hi[0]) * 0.5) ** 2
                     + (positions[..., 2] - (lo[2] + hi[2]) * 0.5) ** 2)
    radial /= max(float(max(extent[0], extent[2]) * 0.5), 1e-6)
    anatomy = {"unit": unit, "nrm": normals, "valid": valid, "radial": radial}
    # Native head faces +Z. Keep seam embers on the dorsal armour and out of
    # the eyes/legs/belly; pale tusks use their own source-colour selection.
    glow = json.loads(json.dumps(spec["glow"]))
    glow[0]["where"] = {"y_min": 0.62, "z_max": 0.80, "up_min": 0.0}
    glow[0]["softness"] = 0.04
    glow[1]["where"] = {"y_min": 0.25, "y_max": 0.70, "z_min": 0.80}
    glow[1]["softness"] = 0.035
    emission, notes = build_glow_map(painted, source, anatomy, glow, SIZE, seed_key="ashtusk_native")
    emission *= (1.0 - eyes[..., None])
    Image.fromarray(np.rint(emission * 255).astype(np.uint8), "RGB").save(emissive_path, optimize=True)
    print(json.dumps({"dimensions": [SIZE, SIZE], "glow": notes,
                      "eye_pixels_preserved": bool(np.array_equal(encoded[eyes == 1], original[eyes == 1])),
                      "outputs": {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                                  for p in [albedo_path, emissive_path]}}, indent=2))


if __name__ == "__main__":
    main()
