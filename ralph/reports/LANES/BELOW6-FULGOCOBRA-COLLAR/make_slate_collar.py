"""Fulgocobra collar plates off the reserved red (LANE-BELOW6, 13 Nov 2026).

G-things-wardenring-f41-13-closeout (LANE-SCOUT, tb/item-scout-1108 7d2ccb33b), 3/3: Fulgocobra's
"copper-red collar plates" sit near the reserved red range. Red and oxblood are Team Tether only.

Input:  creature_fulgocobra_owner1101_Image_0_face.png (the live coat's albedo, lanekit_face_read)
Output: creature_fulgocobra_owner1101_Image_0_face_slate.png
  - copper pixels (hue about 8 to 32 degrees, saturated, mid to bright) become gunmetal slate:
    hue 218 degrees, saturation 0.16, value x 0.82, so the plates keep their shading and edges;
  - gold bands (hue about 33 to 50), navy scales, cyan arcs and the eye are untouched.
Same mesh, UVs and pattern.
"""
import hashlib
import numpy as np
from PIL import Image

BASE = "assets/creatures/tetherbound/fulgocobra/candidate_owner1101/models/creature_fulgocobra_owner1101_"
SRC, DST = BASE + "Image_0_face.png", BASE + "Image_0_face_slate.png"

hsv = np.asarray(Image.open(SRC).convert("RGB").convert("HSV"), dtype=np.float32) / 255.0
h, s, v = hsv[..., 0] * 360.0, hsv[..., 1], hsv[..., 2]
# Copper: orange-red hues below the gold bands. Hue wraps, so reds just under 360 count too.
hue_from_red = np.minimum(h, 360.0 - h)
copper = np.clip((32.0 - hue_from_red) / 5.0, 0.0, 1.0) * np.clip((s - 0.22) * 6.0, 0.0, 1.0) \
    * np.clip((v - 0.22) * 6.0, 0.0, 1.0)
# Build the slate version of every pixel, then blend in RGB. Blending the hue itself walks
# partly-copper pixels through green on the way from orange to blue.
slate_hsv = np.stack([np.full_like(h, 218.0 / 360.0), np.full_like(s, 0.16), v * 0.82], axis=-1)
slate = np.asarray(Image.fromarray((np.clip(slate_hsv, 0, 1) * 255).astype(np.uint8), "HSV").convert("RGB"),
    dtype=np.float32)
original = np.asarray(Image.open(SRC).convert("RGB"), dtype=np.float32)
weight = copper[..., None]
Image.fromarray(np.clip(original * (1 - weight) + slate * weight, 0, 255).astype(np.uint8), "RGB").save(DST)
rgb = np.asarray(Image.open(DST).convert("RGB"), dtype=np.float32)
reddish = (rgb[..., 0] > rgb[..., 1] * 1.35) & (rgb[..., 0] > rgb[..., 2] * 1.6) & (rgb[..., 0] > 90)
print("src sha256", hashlib.sha256(open(SRC, "rb").read()).hexdigest())
print("copper share %.3f; strongly red-orange pixels left %.4f" % ((copper > 0.5).mean(), reddish.mean()))
