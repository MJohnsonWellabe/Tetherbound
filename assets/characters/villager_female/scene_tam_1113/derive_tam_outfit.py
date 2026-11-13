"""F38#16 (LANE-SCENE, 13 Nov 2026): Tam's outfit, derived from the installed
villager_female body texture. Only the olive-green cloth (hood, tunic) moves to
a slate blue; skin, leather, white cloth and eyes are untouched. Weighted by
hue distance from olive and by saturation, so edges blend. No red or oxblood.
Usage: python3 derive_tam_outfit.py <source.png> <out.png>"""
import sys

import numpy as np
from PIL import Image

src, out = sys.argv[1], sys.argv[2]
rgb = np.asarray(Image.open(src).convert("RGB"), dtype=np.float32) / 255.0
r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
mx = rgb.max(-1)
mn = rgb.min(-1)
v = mx
s = np.where(mx > 1e-5, (mx - mn) / np.maximum(mx, 1e-5), 0.0)
d = np.maximum(mx - mn, 1e-5)
h = np.where(mx == r, ((g - b) / d) % 6.0, np.where(mx == g, (b - r) / d + 2.0, (r - g) / d + 4.0)) / 6.0
h = np.where(mx - mn < 1e-5, 0.0, h)
# Measured on sampled pixels: the olive cloth is hue 0.13-0.19 with green at
# 0.89-1.00 of red; the brown leather is hue 0.08-0.10 with green at 0.50-0.72
# of red; skin is redder still. The mask takes hue 0.11-0.30 and ramps in
# between g/r 0.80 and 0.88, so leather, skin and brass stay out.
hue_w = np.clip(1.0 - np.abs(h - 0.20) / 0.09, 0.0, 1.0)
sat_w = np.clip((s - 0.10) / 0.15, 0.0, 1.0)
green_guard = np.clip((g / np.maximum(r, 1e-4) - 0.80) / 0.08, 0.0, 1.0)
hue_w = hue_w * green_guard
w = (hue_w * sat_w)[..., None]
# Slate blue at the pixel's own value: keeps folds, shading and stitching.
target_h, target_s = 0.60, 0.42
tv = v * 0.92
c = tv * target_s
hp = target_h * 6.0
x = c * (1 - abs(hp % 2 - 1))
m = tv - c
# hue 0.60 * 6 = 3.6 lies in sector 3 (r=0, g=x, b=c)
slate = np.stack([m, x + m, c + m], -1)
outrgb = rgb * (1.0 - w) + slate * w
Image.fromarray((np.clip(outrgb, 0, 1) * 255 + 0.5).astype(np.uint8)).save(out)
print("moved share", float((w[..., 0] > 0.5).mean()))
