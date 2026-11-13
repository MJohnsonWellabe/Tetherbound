"""F41#18 Stormwood uniforms (LANE-BELOW6, 13 Nov 2026): mid-value storm cloth.

G-below6-uniforms and G-things-stormuniform (3/3): with an emission floor the near-black
uniforms carry "a chalky ghost wash"; without it they "blend into the dark mud and purple
mist". The judges ask for "lit mid-value cloth". The three row bodies' textures have a median
value of 0.13 to 0.17, so no light can make them read.

Inputs (the live body textures of the row's three characters):
  grunt_c/grunt_c_lod0_texture_0_vis1.png                 Lieutenant Dace
  officer_a/officer_a_lod0_texture_0_vis1.png             Lieutenant Varga
  former_tether_member/former_tether_member_lod0_texture_0.png   Sable
Outputs: the same names with `_cloth1.png` in place of `.png`.
  - near-neutral dark pixels (the cloth: value under about 0.46, excluding warm saturated pixels, with a softened mask) are lifted to a
    mid value on a curve and given a cool slate cast (toward RGB 0.60, 0.63, 0.70);
  - the fold and seam detail is put back on top (unsharp of the value channel);
  - skin, dark brown hair, leather belts and the chest emblem are left as they are.
Same meshes and UVs. Nothing is red.
"""
import hashlib
import numpy as np
from PIL import Image, ImageFilter

FILES = [
    "assets/characters/grunt_c/grunt_c_lod0_texture_0_vis1.png",
    "assets/characters/officer_a/officer_a_lod0_texture_0_vis1.png",
    "assets/characters/former_tether_member/former_tether_member_lod0_texture_0.png",
]
SLATE = np.array([0.60, 0.63, 0.70], dtype=np.float32)

for path in FILES:
    src = Image.open(path).convert("RGB")
    rgb = np.asarray(src, dtype=np.float32) / 255.0
    hsv = np.asarray(src.convert("HSV"), dtype=np.float32) / 255.0
    sat, val = hsv[..., 1], hsv[..., 2]
    hue = hsv[..., 0] * 360.0
    # Dark pixels are cloth unless they are warm and saturated: dark brown hair and leather
    # sit at hue 8 to 55 degrees with saturation over about 0.22, and must keep their colour.
    warm = np.clip(1.0 - np.abs(hue - 30.0) / 28.0, 0.0, 1.0) * np.clip((sat - 0.18) / 0.08, 0.0, 1.0)
    cloth = np.clip((0.46 - val) / 0.14, 0.0, 1.0) * (1.0 - warm)
    # Soften the mask so single texels do not stay as specks.
    cloth = np.asarray(Image.fromarray((cloth * 255).astype(np.uint8), "L").filter(
        ImageFilter.GaussianBlur(2.0)), dtype=np.float32) / 255.0
    lifted_v = np.clip(0.15 + val * 1.05, 0.0, 0.56)
    detail = np.asarray(src.convert("L").filter(ImageFilter.UnsharpMask(radius=4, percent=100, threshold=0)),
        dtype=np.float32) / 255.0
    lum = rgb.mean(-1)
    lifted_v = np.clip(lifted_v + (detail - lum) * 0.35, 0.08, 0.6)
    target = SLATE[None, None, :] * (lifted_v / SLATE.mean())[..., None]
    weight = cloth[..., None]
    out = np.clip(rgb * (1 - weight) + target * weight, 0.0, 1.0)
    dst = path[:-4] + "_cloth1.png"
    Image.fromarray((out * 255).astype(np.uint8), "RGB").save(dst)
    print(path.split("/")[-1], "sha256", hashlib.sha256(open(path, "rb").read()).hexdigest()[:16],
        "cloth share %.2f, median value %.2f -> %.2f" % (
            (cloth > 0.5).mean(), np.median(val), np.median(out.max(-1))))
