"""F36#46 / F41#13 Fulgocobra (LANE-BELOW6, 13 Nov 2026): dark olive scales with glowing gold veins.

G-below6-stormraven-r3 (3/3): the board shows olive-black scales with glowing gold vein lines; in
game the snake is navy with painted gold bands that "read as decorative stripes", and the copper
throat plates look bolted-on.

Inputs (the remake's live coat, lanekit_face_read_fulgocobra):
  creature_fulgocobra_owner1101_Image_0_face.png        albedo
  creature_fulgocobra_owner1101_glow_goldvein_face.png  emission
Outputs:
  creature_fulgocobra_owner1101_Image_0_olive.png   albedo
  creature_fulgocobra_owner1101_glow_vein_r1.png    emission
What changes:
  - navy and blue-grey scales turn dark olive (hue to about 78 degrees, value kept, slightly lifted);
  - each gold band is reduced to its centre line (the ridge of its distance transform), so the gold
    reads as thin branching veins; the rest of the band sinks into a dark olive-brown;
  - copper plates are pulled to a dark bronze so they sit in the body instead of on it;
  - the cyan arc cracks and the eye turn gold, so the snake has one element colour.
Same mesh, UVs, silhouette and scale pattern. Nothing is red.
"""
import hashlib
import numpy as np
from PIL import Image, ImageFilter

BASE = "assets/creatures/tetherbound/fulgocobra/candidate_owner1101/models/creature_fulgocobra_owner1101_"
SRC_A, SRC_G = BASE + "Image_0_face.png", BASE + "glow_goldvein_face.png"
DST_A, DST_G = BASE + "Image_0_olive.png", BASE + "glow_vein_r1.png"  # r2 overwrites both in place


def hsv_of(path):
    arr = np.asarray(Image.open(path).convert("RGB").convert("HSV"), dtype=np.float32) / 255.0
    return arr[..., 0] * 360.0, arr[..., 1], arr[..., 2]


def rgb_of(h, s, v):
    out = np.stack([np.mod(h, 360.0) / 360.0, s, v], axis=-1)
    return Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "HSV").convert("RGB")


def band(h, centre, width):
    """1 inside centre +- width, falling to 0 over a further 8 degrees."""
    return np.clip((width + 8.0 - np.abs(h - centre)) / 8.0, 0.0, 1.0)


def blur(arr, radius):
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "L")
    return np.asarray(img.filter(ImageFilter.GaussianBlur(radius)), dtype=np.float32) / 255.0


h, s, v = hsv_of(SRC_A)
gold = band(h, 40.0, 9.0) * np.clip((s - 0.3) * 5.0, 0, 1) * np.clip((v - 0.22) * 5.0, 0, 1)
copper = band(h, 20.0, 9.0) * np.clip((s - 0.25) * 5.0, 0, 1) * np.clip((v - 0.3) * 5.0, 0, 1) * (1 - gold)
cyan = band(h, 197.0, 18.0) * np.clip((s - 0.4) * 5.0, 0, 1) * np.clip((v - 0.5) * 5.0, 0, 1)
# Dark scales only: the pale grey plates stay neutral (they would turn bright green otherwise).
dark = np.clip((0.42 - v) * 6.0, 0, 1)
navy = np.clip(1.0 - gold - copper - cyan, 0.0, 1.0) * dark
plate = np.clip(1.0 - gold - copper - cyan, 0.0, 1.0) * (1 - dark)

# Vein lines: the ridge of each gold band (chessboard distance by repeated erosion; no scipy on the
# lane machines). The band mask is blurred first so the scale texture does not break it into dots.
layer = Image.fromarray(((blur(gold, 5.0) > 0.38) * 255).astype(np.uint8), "L")
dist = np.zeros(gold.shape, dtype=np.float32)
for _ in range(40):
    dist += np.asarray(layer, dtype=np.float32) / 255.0
    layer = layer.filter(ImageFilter.MinFilter(3))
peak = np.asarray(Image.fromarray(dist.astype(np.uint8), "L").filter(ImageFilter.MaxFilter(9)), dtype=np.float32)
ridge = (dist >= peak - 1.0) & (dist > 3.0)
ridge_img = Image.fromarray((ridge * 255).astype(np.uint8), "L").filter(ImageFilter.MaxFilter(5))
vein = np.clip(blur(np.asarray(ridge_img, dtype=np.float32) / 255.0, 1.5) * 1.5, 0.0, 1.0)
band_area = np.clip(blur(gold, 5.0) * 2.2, 0, 1)

# Albedo.
oh = np.full_like(h, 78.0)
h2 = h * (1 - navy) + oh * navy
s2 = s * (1 - navy) + np.clip(0.30 + s * 0.25, 0, 0.5) * navy
v2 = v * (1 - navy) + np.clip(v * 1.08 + 0.015, 0, 1) * navy
# Gold band body sinks to olive-brown; the vein keeps bright gold.
band_h, band_s, band_v = 58.0, 0.45, np.clip(v * 0.42, 0, 1)
keep = vein
g = np.maximum(gold, band_area * (1 - copper) * (1 - cyan))
h2 = h2 * (1 - g) + (44.0 * keep + band_h * (1 - keep)) * g
s2 = s2 * (1 - g) + (0.88 * keep + band_s * (1 - keep)) * g
# r2: the vein albedo stays a mid gold (the lit core clipped to white on the GPU at 0.55+).
v2 = v2 * (1 - g) + (np.clip(0.34 + v * 0.2, 0, 0.5) * keep + band_v * (1 - keep)) * g
# Pale plates: a little darker with a faint olive cast.
# r2: 0.14 saturation left the head and hood pale grey on the GPU; the plates are olive now.
h2 = h2 * (1 - plate) + 80.0 * plate
s2 = s2 * (1 - plate) + 0.30 * plate
v2 = v2 * (1 - plate) + v * 0.66 * plate
# Copper to dark bronze.
h2 = h2 * (1 - copper) + 34.0 * copper
s2 = s2 * (1 - copper) + np.clip(s * 0.85, 0.42, 1.0) * copper
v2 = v2 * (1 - copper) + v * 0.5 * copper
# Cyan arcs to gold.
h2 = h2 * (1 - cyan) + 46.0 * cyan
s2 = s2 * (1 - cyan) + np.clip(s * 0.9, 0, 1) * cyan
rgb_of(h2, s2, v2).save(DST_A)

# Emission: thin gold veins plus the former cyan arcs and eye, now gold.
gh, gs, gv = hsv_of(SRC_G)
g_cyan = band(gh, 195.0, 30.0) * np.clip(gv * 3.0, 0, 1)
vein_glow = np.clip(vein + blur(vein, 3.0) * 0.5, 0, 1)
# r2: a deeper amber at lower value so the core stays gold after tonemap; the eye and arc
# cracks keep their full strength (the eye glow was lost on the GPU in r1).
ev = np.clip(vein_glow * 0.72 + g_cyan * gv, 0, 1)
eh = np.full_like(gh, 40.0)
es = np.full_like(gs, 0.95)
rgb_of(eh, es, ev).save(DST_G)

for path in (SRC_A, SRC_G):
    print("src sha256", path.split("/")[-1], hashlib.sha256(open(path, "rb").read()).hexdigest())
print("shares: dark scales %.2f gold %.3f copper %.3f cyan %.3f vein %.4f; mean value %.3f -> %.3f" % (
    (navy > 0.5).mean(), (gold > 0.5).mean(), (copper > 0.5).mean(), (cyan > 0.5).mean(),
    (vein > 0.5).mean(), v.mean(), v2.mean()))
