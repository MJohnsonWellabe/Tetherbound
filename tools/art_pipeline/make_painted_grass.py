"""Painted stylised grass albedo: clumps of short directional blade strokes over
the existing meadow colour field (low frequencies kept, smear replaced)."""
import sys, math, numpy as np
from PIL import Image, ImageDraw, ImageFilter
src, out, seed = sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 7
N = 1024; S = 2  # supersample
rng = np.random.default_rng(seed)
base = Image.open(src).convert('RGB').resize((N, N))
low = np.asarray(base.filter(ImageFilter.GaussianBlur(28)), dtype=np.float32)
# tileable clump mask from wrapped gaussian blobs
def wrapped_noise(cells, blur):
    a = rng.random((cells, cells)).astype(np.float32)
    im = Image.fromarray((a * 255).astype(np.uint8)).resize((N, N), Image.BICUBIC)
    t = np.tile(np.asarray(im, np.float32), (3, 3))
    t = np.asarray(Image.fromarray(t.astype(np.uint8)).filter(ImageFilter.GaussianBlur(blur)), np.float32)
    return t[N:2*N, N:2*N] / 255.0
clump = wrapped_noise(24, 10)
clump = (clump - clump.min()) / (clump.max() - clump.min())
canvas = Image.new('RGB', (N*S, N*S))
# underlayer: darker soil-green between clumps
under = (low * (0.62 + 0.25 * clump[..., None])).clip(0, 255).astype(np.uint8)
canvas.paste(Image.fromarray(under).resize((N*S, N*S), Image.BILINEAR))
d = ImageDraw.Draw(canvas)
count = 190000
xs = rng.random(count) * N; ys = rng.random(count) * N
for i in range(count):
    x, y = xs[i], ys[i]
    c = clump[int(y) % N, int(x) % N]
    if rng.random() > 0.25 + 0.75 * c:
        continue
    L = rng.uniform(5, 13) * (0.7 + 0.5 * c)
    ang = -math.pi / 2 + rng.normal(0, 0.55)
    col = low[int(y) % N, int(x) % N]
    v = rng.uniform(0.78, 1.28) * (0.85 + 0.3 * c)
    tipcol = np.clip(col * v * np.array([1.02, 1.06, 0.92]), 0, 255)
    w = max(1, int(round(rng.uniform(1.2, 2.4) * S)))
    dx, dy = math.cos(ang) * L, math.sin(ang) * L
    for ox in (-N, 0, N):
        for oy in (-N, 0, N):
            x0, y0 = x + ox, y + oy
            if -20 < x0 < N + 20 and -20 < y0 < N + 20:
                d.line([(x0*S, y0*S), ((x0+dx)*S, (y0+dy)*S)], fill=tuple(int(t) for t in tipcol), width=w)
img = canvas.resize((N, N), Image.LANCZOS)
# sparse soil/pebble specks
a = np.asarray(img, np.float32)
for i in range(260):
    x, y = rng.integers(0, N, 2); r = rng.integers(2, 5)
    yy, xx = np.ogrid[-r:r+1, -r:r+1]; m = xx*xx + yy*yy <= r*r
    tone = np.array([118, 104, 82]) * rng.uniform(0.8, 1.15)
    for oy in range(-r, r+1):
        for ox in range(-r, r+1):
            if m[oy+r, ox+r]: a[(y+oy) % N, (x+ox) % N] = a[(y+oy) % N, (x+ox) % N]*0.3 + tone*0.7
# keep the original mean colour
a = a * (np.asarray(base, np.float32).mean((0, 1)) / a.mean((0, 1)))
Image.fromarray(a.clip(0, 255).astype(np.uint8)).save(out)
# normal from luminance
lum = a.mean(2) / 255.0
gx = np.roll(lum, -1, 1) - np.roll(lum, 1, 1); gy = np.roll(lum, -1, 0) - np.roll(lum, 1, 0)
k = 3.0
nx, ny, nz = -gx * k, gy * k, np.ones_like(lum)
n = np.sqrt(nx*nx + ny*ny + nz*nz)
nm = np.stack([nx/n, ny/n, nz/n], -1) * 0.5 + 0.5
Image.fromarray((nm * 255).astype(np.uint8)).save(out.replace('_Color', '_NormalGL'))
print('ok', a.mean((0, 1)))
