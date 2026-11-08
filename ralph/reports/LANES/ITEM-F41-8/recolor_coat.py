"""F41#8 named silhouettes (LANE-KIT, 7 Nov 2026). Judges: "many distinct named
roles repeat the same face, body and outfit silhouettes". Stormwood's three
local_historian roles (Rodkeeper Hesk, Warden-elect Bryn, Elder Maud) share one
installed body and one coat. This keeps that installed mesh and its live albedo
(local_historian_lod0_texture_0_vis1.png) and recolours only the olive coat
cloth (hue 45-120 deg, saturation >= 0.06, value 0.08-0.85; brown leather sits below 45); skin, white hair,
eyes and the brown leather straps/boots keep their pixels. Identity (face,
hair, silhouette, rig) is unchanged; no red or oxblood.
  python3 recolor_coat.py <out.png> <target_hue_deg> <sat_scale> <value_scale> [source.png]
The matching portrait is the same recolour of the plate Stormwood already shows
for this body (stormwood_dialogue_presentation.json plates_by_profile:
local_historian -> old_perrin.png), so body and plate change together.
"""
import sys
import numpy as np
from PIL import Image
SRC = "assets/characters/local_historian/local_historian_lod0_texture_0_vis1.png"
out, hue, sat_k, val_k = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])
im = Image.open(sys.argv[5] if len(sys.argv) > 5 else SRC).convert("RGB")
hsv = np.asarray(im.convert("HSV")).astype(float)
h, s, v = hsv[..., 0] * 360 / 255, hsv[..., 1] / 255, hsv[..., 2] / 255
mask = (h >= 45) & (h <= 120) & (s >= 0.06) & (v >= 0.08) & (v <= 0.85)
hsv[..., 0] = np.where(mask, hue / 360 * 255, hsv[..., 0])
hsv[..., 1] = np.where(mask, np.clip(np.maximum(hsv[..., 1] * sat_k, 0.28 * 255), 0, 255), hsv[..., 1])
hsv[..., 2] = np.where(mask, np.clip(hsv[..., 2] * val_k, 0, 255), hsv[..., 2])
Image.fromarray(hsv.astype(np.uint8), "HSV").convert("RGB").save(out)
print(out, "coat texels %.3f" % mask.mean())
