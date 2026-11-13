"""F41#13 Stormraven r3 (LANE-BELOW6, 13 Nov 2026): a near-black feather base.

G-below6-stormraven-masonry (3/3): the bird reads as "flat, saturated royal-blue ... glossy plastic,
no feather detail", where the board shows a black raven with blue lightning. The albedo that ships is
the value-lifted copy, which is what reads royal blue.

Input:  creature_stormraven_owner1101_Image_0.jpg (the remake's own albedo).
Output: creature_stormraven_owner1101_Image_0_night.png
  - saturation cut to 42 percent and value pulled down with a gamma, so the feathers are near-black
    with a cool cast;
  - the local feather detail is put back on top (an unsharp of the value channel), so barbs and
    feather edges still read against the dark base;
  - the yellow beak, feet and the pale eye keep their own colour (anything not blue is left alone).
Same mesh, UVs, silhouette and markings; no hue is added and nothing is red.
"""
import hashlib
import numpy as np
from PIL import Image, ImageFilter

SRC = "assets/creatures/tetherbound/stormraven/candidate_owner1101/models/creature_stormraven_owner1101_Image_0.jpg"
DST = "assets/creatures/tetherbound/stormraven/candidate_owner1101/models/creature_stormraven_owner1101_Image_0_night.png"

src = Image.open(SRC).convert("RGB")
hsv = np.asarray(src.convert("HSV"), dtype=np.float32) / 255.0
h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
# Blue feathers: hue roughly 190-270 degrees.
blue = np.clip(1.0 - np.abs(h * 360.0 - 228.0) / 55.0, 0.0, 1.0) * np.clip(s * 4.0, 0.0, 1.0)
pale = np.clip((v - 0.72) / 0.15, 0.0, 1.0) * np.clip((0.45 - s) / 0.2 + 0.5, 0.0, 1.0)  # the eye and light flecks
weight = blue * (1.0 - pale)
detail = np.asarray(src.convert("L").filter(ImageFilter.UnsharpMask(radius=3, percent=180, threshold=0)), dtype=np.float32) / 255.0
v_dark = np.clip((v ** 1.12) * 0.74 + (detail - v) * 0.6, 0.0, 1.0)
s_dark = s * 0.42
out = np.stack([h, s * (1 - weight) + s_dark * weight, v * (1 - weight) + v_dark * weight], axis=-1)
Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "HSV").convert("RGB").save(DST)
print("src sha256", hashlib.sha256(open(SRC, "rb").read()).hexdigest())
print("mean value src %.3f out %.3f; mean saturation src %.3f out %.3f; blue share %.2f" % (
    v.mean(), out[..., 2].mean(), s.mean(), out[..., 1].mean(), (weight > 0.5).mean()))
