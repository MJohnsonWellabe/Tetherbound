"""F41#8 / F41#18 background bears (LANE-BELOW6, 13 Nov 2026): Staticub storm fur.

GPU panels (G-places-stormlight, G-things-stormuniform, G-below6-namedfaces; 3/3): the wild
bears behind the Stormwood cast are "flat salmon pink" and "read as placeholders". They are
wild Staticub (r10 model). The fur texture is warm brown (mean RGB 113,79,60); the shipped
value-lift copy is paler (138,101,79); Stormwood's violet light then adds blue, and the
body renders salmon (CPU crop mean 196,164,158 with the lift, 175,134,130 without).

Input:  creature_staticub_r10_Image_0.jpg (the model's own albedo, not the lifted copy)
Output: creature_staticub_r10_Image_0_storm.png
  - fur pixels (warm hues) are multiplied by (0.86, 0.80, 0.62): darker, and with blue pulled
    down so the violet light lands on brown instead of pink;
  - the local fur detail is put back (unsharp of the value channel);
  - the blue-violet arc flecks, the eyes and the pale muzzle keep their own colour.
Same mesh, UVs, silhouette and markings. Nothing is red.
"""
import hashlib
import numpy as np
from PIL import Image, ImageFilter

BASE = "assets/creatures/tetherbound/staticub/candidate_r10/models/creature_staticub_r10_"
SRC, DST = BASE + "Image_0.jpg", BASE + "Image_0_storm.png"

src = Image.open(SRC).convert("RGB")
rgb = np.asarray(src, dtype=np.float32) / 255.0
hsv = np.asarray(src.convert("HSV"), dtype=np.float32) / 255.0
hue, sat, val = hsv[..., 0] * 360.0, hsv[..., 1], hsv[..., 2]
# Warm fur: hue 0-50 degrees with some saturation. Arcs and eyes are blue-violet; the muzzle is pale.
warm = np.clip((55.0 - hue) / 12.0, 0.0, 1.0) * np.clip((sat - 0.18) * 6.0, 0.0, 1.0)
pale = np.clip((val - 0.78) / 0.12, 0.0, 1.0)
weight = (warm * (1.0 - pale))[..., None]
detail = np.asarray(src.convert("L").filter(ImageFilter.UnsharpMask(radius=3, percent=120, threshold=0)),
    dtype=np.float32) / 255.0
lum = rgb.mean(-1)
fur = rgb * np.array([0.86, 0.80, 0.62], dtype=np.float32) + ((detail - lum) * 0.5)[..., None]
out = np.clip(rgb * (1.0 - weight) + fur * weight, 0.0, 1.0)
Image.fromarray((out * 255).astype(np.uint8), "RGB").save(DST)
print("src sha256", hashlib.sha256(open(SRC, "rb").read()).hexdigest())
print("mean RGB src %s out %s; fur share %.2f" % (
    (rgb.reshape(-1, 3).mean(0) * 255).round(0), (out.reshape(-1, 3).mean(0) * 255).round(0), (weight > 0.5).mean()))
