"""BEINGS-STATICUB-COOL (13 Nov 2026), Staticub world frames (G-closeout-staticub, 3/3):
under Stormwood light the shipped storm coat reads "orange / peach, almost plastic"; the ask
is to cool it toward the Stormursa purple-brown (that coat's albedo mean is RGB 89,62,56;
the shipped storm coat's is 99,65,40, i.e. far less blue).

Input:  creature_staticub_r10_Image_0_storm.png (the shipped coat)
Output: creature_staticub_r10_Image_0_cool.png
  - fur pixels (same warm-fur mask as make_storm_fur.py, read from the source albedo) are
    multiplied by (0.90, 0.95, 1.35): red down, blue up, toward Stormursa's balance;
  - arcs, eyes and pale muzzle keep their colour. Stormursa itself is untouched.
"""
import hashlib
import numpy as np
from PIL import Image

BASE = "assets/creatures/tetherbound/staticub/candidate_r10/models/creature_staticub_r10_"
SRC, STORM, DST = BASE + "Image_0.jpg", BASE + "Image_0_storm.png", BASE + "Image_0_cool.png"
src = Image.open(SRC).convert("RGB")
hsv = np.asarray(src.convert("HSV"), dtype=np.float32) / 255.0
hue, sat, val = hsv[..., 0] * 360.0, hsv[..., 1], hsv[..., 2]
warm = np.clip((55.0 - hue) / 12.0, 0.0, 1.0) * np.clip((sat - 0.18) * 6.0, 0.0, 1.0)
pale = np.clip((val - 0.78) / 0.12, 0.0, 1.0)
weight = (warm * (1.0 - pale))[..., None]
storm = np.asarray(Image.open(STORM).convert("RGB"), dtype=np.float32) / 255.0
cool = storm * np.array([0.90, 0.95, 1.35], dtype=np.float32)
out = np.clip(storm * (1.0 - weight) + cool * weight, 0.0, 1.0)
Image.fromarray((out * 255).astype(np.uint8), "RGB").save(DST)
print("storm sha256", hashlib.sha256(open(STORM, "rb").read()).hexdigest())
print("mean RGB storm %s cool %s" % ((storm.reshape(-1, 3).mean(0) * 255).round(0), (out.reshape(-1, 3).mean(0) * 255).round(0)))
