# F40#1 (LANE-CR): tileable pale strata (sides) and moss-lip (tops) textures. python3 strata_textures.py <outdir>
import sys, numpy as np
from PIL import Image
rng = np.random.default_rng(1107)
N = 1024
x = np.arange(N) / N
X, Y = np.meshgrid(x, x)
def fbm(fx, fy, oct=5, seed=0):
    r = np.random.default_rng(seed); v = np.zeros((N, N))
    for o in range(oct):
        f = 2 ** o
        for _ in range(3):
            kx, ky = r.integers(-3, 4) * fx * f, r.integers(1, 4) * fy * f
            ph = r.uniform(0, 2 * np.pi)
            v += np.sin(2 * np.pi * (kx * X + ky * Y) + ph) / (f * 1.6)
    return (v - v.min()) / (v.max() - v.min())
palette = np.array([[230, 223, 204], [214, 212, 203], [222, 205, 170], [200, 196, 184], [236, 230, 214], [210, 198, 176]], float)
# bands that sum to N (vertical tiling)
rows = np.zeros((N, 3)); seam = np.zeros(N); y = 0
while y < N:
    h = int(rng.integers(28, 110)); h = min(h, N - y)
    rows[y:y + h] = palette[rng.integers(0, len(palette))] * rng.uniform(0.93, 1.04)
    seam[y:min(y + 3, N)] = 1.0; y += h
img = rows[:, None, :].repeat(N, 1)
# band waviness: offset rows by a periodic horizontal wave
wave = (np.sin(2 * np.pi * (X * 2)) * 6 + np.sin(2 * np.pi * (X * 5 + 0.3)) * 3).astype(int)
idx = (np.arange(N)[:, None] + wave) % N
img = img[idx, np.arange(N)[None, :]]
sm = seam[idx]
grain = (0.5 * fbm(4, 1, seed=3) + 0.5 * fbm(12, 9, seed=8))[..., None]
blot = fbm(3, 2, seed=21)[..., None]
img = img * (0.72 + 0.42 * grain) * (0.9 + 0.18 * blot)
break_ = (fbm(6, 2, seed=4) > 0.42)
img = img * (1 - 0.30 * (sm * break_)[..., None])
# a few vertical joints
for cx in rng.integers(0, N, 9):
    w = (np.abs(((np.arange(N) - cx + N // 2) % N) - N // 2) < 2)
    mask = (fbm(1, 3, 2, seed=int(cx))[:, :] > 0.55) & w[None, :]
    img[mask] *= 0.72
# r1b: value matched to the installed Cloudreach cliffs (first build read near-white in engine)
img = img * 0.74
Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).save(sys.argv[1] + "/strata_side_Color.png")
# tops: moss-green turf with pale stone showing through
m = fbm(3, 3, seed=11)[..., None]
moss = np.array([92, 120, 58]) * (0.85 + 0.3 * fbm(8, 8, seed=5)[..., None])
stone = np.array([176, 170, 152]) * (0.85 + 0.25 * grain)
top = np.where(m > 0.70, stone, moss)
Image.fromarray(np.clip(top, 0, 255).astype(np.uint8)).save(sys.argv[1] + "/strata_top_Color.png")
print("ok")
