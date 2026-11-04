# Drafted reference for the Meadows ridge backdrop (F38#24 / P2-014): a painted
# concept, not a render of the asset. python3 reference_concept.py out.png
import sys, numpy as np
from PIL import Image
W, H = 1600, 700
rng = np.random.default_rng(7)
def fbm(n, octaves, seed, rough=0.5):
    r = np.random.default_rng(seed); out = np.zeros(n)
    x = np.arange(n)
    for o in range(octaves):
        k = 4 * 2 ** o; pts = r.uniform(-1, 1, k + 2)
        out += np.interp(x * (k / n), np.arange(k + 2), pts) * rough ** o
    return out
def ridged(n, octaves, seed):
    r = np.random.default_rng(seed); out = np.zeros(n); x = np.arange(n); amp = 1.0
    for o in range(octaves):
        k = 3 * 2 ** o; pts = r.uniform(-1, 1, k + 2)
        v = 1 - np.abs(np.interp(x * (k / n), np.arange(k + 2), pts)); out += v * v * amp; amp *= 0.5
    return out
y = np.linspace(0, 1, H)[:, None]
sky_top, sky_hor = np.array([0.42, 0.58, 0.74]), np.array([0.72, 0.80, 0.84])
img = sky_hor[None, None, :] + (sky_top - sky_hor)[None, None, :] * ((1 - y) ** 1.4)[..., None]
img = np.broadcast_to(img, (H, W, 3)).copy()
layers = [  # base row, amplitude, colour (sRGB), haze, snow?
    (0.52, 0.30, np.array([0.33, 0.38, 0.44]), 0.55, True),
    (0.60, 0.18, np.array([0.27, 0.34, 0.33]), 0.38, False),
    (0.70, 0.09, np.array([0.18, 0.27, 0.19]), 0.18, False),
]
for i, (base, amp, col, haze, snow) in enumerate(layers):
    prof = ridged(W, 6, 11 + i) / 1.9
    mass = 0.55 + 0.45 * (fbm(W, 2, 31 + i) * 0.5 + 0.5)
    top = (base - amp * prof * mass) * H
    rows = np.arange(H)[:, None]
    mask = rows >= top[None, :]
    depth = np.clip((rows - top[None, :]) / (amp * H + 1e-3), 0, 1)
    # lit left faces / shaded right faces from the profile slope
    slope = np.convolve(np.gradient(top), np.ones(9) / 9, mode='same')[None, :]
    shade = np.clip(1.0 + np.tanh(slope * 0.4) * 0.18, 0.8, 1.2)
    # gullies: soft darker drainage lines running down each face
    gully = 0.92 + 0.08 * np.sin(np.arange(W)[None, :] * 0.11 + depth * 3.0 + fbm(W, 3, 50 + i)[None, :] * 6)
    shade = shade * gully
    c = col[None, None, :] * shade[..., None] * (0.9 + 0.1 * depth[..., None])
    if snow:
        sn = (rows < top[None, :] + 0.05 * H) & (top[None, :] < (base - amp * 0.55) * H)
        c = np.where(sn[..., None], np.array([0.80, 0.84, 0.88]) * shade[..., None], c)
    c = c * (1 - haze) + sky_hor * haze
    img = np.where(mask[..., None], c, img)
img[int(0.78 * H):] = img[int(0.78 * H):] * 0.0 + np.array([0.30, 0.42, 0.22])  # meadow foreground
Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).save(sys.argv[1])
