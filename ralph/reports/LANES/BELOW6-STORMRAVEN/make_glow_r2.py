"""F41#13 Stormraven (LANE-BELOW6, 12 Nov 2026): a stronger read of the remake's own glow map.

Input:  creature_stormraven_owner1101_glow_read.png (electric feather lines and the two eyes).
Output: creature_stormraven_owner1101_glow_read_r2.png
  - the feather lines are widened (3 px dilation at the map's resolution, then a 1 px blur) so they
    survive at normal creature distance;
  - the two eye patches (the pale cyan eye patches in the albedo) get a
    soft filled disc 1.7x their size with a white-hot core, so the eye reads as a lit electric eye.
No hue change: the map stays the remake's blue-white. No new geometry, no generation.
"""
import hashlib, sys
import numpy as np
from PIL import Image, ImageFilter

SRC = "assets/creatures/tetherbound/stormraven/candidate_owner1101/models/creature_stormraven_owner1101_glow_read.png"
DST = "assets/creatures/tetherbound/stormraven/candidate_owner1101/models/creature_stormraven_owner1101_glow_read_r2.png"
# Eye spots read off the albedo atlas, as fractions of its width and height.
EYES = [(0.182, 0.293), (0.537, 0.746)]

src = Image.open(SRC).convert("RGB")
w, h = src.size
lines = src.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(1.0))
out = np.maximum(np.asarray(src, dtype=np.float32), np.asarray(lines, dtype=np.float32) * 0.9)
lum = np.asarray(src.convert("L"), dtype=np.float32)
albedo = np.asarray(Image.open(SRC.replace("_glow_read.png", "_Image_0.jpg")).convert("RGB").resize(src.size), dtype=np.float32)
yy, xx = np.mgrid[0:h, 0:w]
found = []
for fx, fy in EYES:
    cx, cy = int(fx * w), int(fy * h)
    r = int(0.03 * w)
    x0, x1, y0, y1 = max(0, cx - r), min(w, cx + r), max(0, cy - r), min(h, cy + r)
    # The eye is the pale cyan patch in the albedo (the glow map only has its ring).
    patch = albedo[y0:y1, x0:x1]
    mask = (patch[..., 2] > 200) & (patch[..., 1] > 170) & (patch.max(axis=2) - patch.min(axis=2) > 40)
    if mask.sum() == 0:
        found.append(None)
        continue
    ys, xs = np.nonzero(mask)
    # keep the largest tight cluster around the median so stray pale feathers do not pull it
    mx, my = np.median(xs), np.median(ys)
    near = (np.abs(xs - mx) < 0.012 * w) & (np.abs(ys - my) < 0.012 * w)
    xs, ys = xs[near], ys[near]
    ex, ey = x0 + xs.mean(), y0 + ys.mean()
    radius = max(0.006 * w, 1.7 * np.sqrt(len(xs) / np.pi))
    d = np.sqrt((xx - ex) ** 2 + (yy - ey) ** 2) / radius
    disc = np.clip(1.0 - d, 0.0, 1.0) ** 1.4
    colour = np.array([150.0, 215.0, 255.0])
    core = np.clip(1.0 - d * 2.2, 0.0, 1.0)
    eye = disc[..., None] * colour + core[..., None] * np.array([105.0, 40.0, 0.0])
    out = np.maximum(out, eye)
    found.append((round(float(ex)), round(float(ey)), round(float(radius), 1)))
Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).save(DST)
print("eyes", found, "size", (w, h))
print("src sha256", hashlib.sha256(open(SRC, "rb").read()).hexdigest())
print("lit share src %.4f out %.4f" % ((lum > 40).mean(), (out.max(axis=2) > 40).mean()))
