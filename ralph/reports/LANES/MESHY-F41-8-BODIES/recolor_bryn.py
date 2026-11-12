"""F41#8 (LANE-MESHY, 11 Nov): judge c (G-meshy-f41-8-distinct-bodies) says that at small size Hesk (alpha_tracker) and
Bryn (lost_traveler) share a tan-and-brown palette. This recolours only lost_traveler's darker olive/brown cloth
(hue 40-120 deg, saturation >= 0.12, value <= 0.55; the warmer brown hair, boots and bedroll sit below 40) to a muted teal-green. Skin (lighter peach), hair and face keep their pixels.
Maud's coat is blue-grey (hue 212) and Hesk's is tan, so Bryn now reads as the third palette. No red or oxblood.
  python3 recolor_bryn.py <out.png> [hue_deg=165] [sat_floor=0.45] [value_lift=1.2]
"""
import sys
import numpy as np
from PIL import Image
SRC = "assets/characters/lost_traveler/lost_traveler_lod0_texture_0_vis1.png"
out = sys.argv[1]
hue = float(sys.argv[2]) if len(sys.argv) > 2 else 165.0
floor = float(sys.argv[3]) if len(sys.argv) > 3 else 0.45
lift = float(sys.argv[4]) if len(sys.argv) > 4 else 1.2
im = Image.open(SRC).convert("RGB")
hsv = np.asarray(im.convert("HSV")).astype(float)
h, s, v = hsv[..., 0] * 360 / 255, hsv[..., 1] / 255, hsv[..., 2] / 255
mask = (h >= 40) & (h <= 120) & (s >= 0.12) & (v <= 0.55)
hsv[..., 0] = np.where(mask, hue / 360 * 255, hsv[..., 0])
hsv[..., 1] = np.where(mask, np.clip(np.maximum(hsv[..., 1], floor * 255), 0, 255), hsv[..., 1])
hsv[..., 2] = np.where(mask, np.clip(hsv[..., 2] * lift, 0, 255), hsv[..., 2])
Image.fromarray(hsv.astype(np.uint8), "HSV").convert("RGB").save(out)
print(out, "cloth texels %.3f" % mask.mean())
