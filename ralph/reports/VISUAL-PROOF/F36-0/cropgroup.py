"""Crop a group of same-camera frames to one shared box around non-background pixels.
python3 -I cropgroup.py outdir in1.png in2.png ... ; writes outdir/<basename>.png"""
import sys, os
import numpy as np
from PIL import Image
out = sys.argv[1]; paths = sys.argv[2:]
box = None
for p in paths:
    a = np.asarray(Image.open(p).convert("RGB")).astype(np.int16)
    g = a.mean(axis=2)
    # local 5x5 variance via shifted sums: smooth floor/backdrop is low, detail is high
    pad = np.pad(g, 2, mode="edge")
    s = np.zeros_like(g); s2 = np.zeros_like(g)
    for dy in range(5):
        for dx in range(5):
            v = pad[dy:dy + g.shape[0], dx:dx + g.shape[1]]
            s += v; s2 += v * v
    var = s2 / 25 - (s / 25) ** 2
    mask = var > 30
    # erode by 3 px in each direction: antialiased floor edges are thin lines
    for _ in range(4):
        m = mask.copy()
        m[1:, :] &= mask[:-1, :]; m[:-1, :] &= mask[1:, :]
        m[:, 1:] &= mask[:, :-1]; m[:, :-1] &= mask[:, 1:]
        mask = m
    xs = np.nonzero(mask.sum(axis=0) >= 10)[0]
    ys = np.nonzero(mask.sum(axis=1) >= 10)[0]
    if len(xs) == 0: continue
    b = [xs.min(), ys.min(), xs.max(), ys.max()]
    box = b if box is None else [min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3])]
H, W = a.shape[:2]
x0, y0, x1, y1 = box
w, h = x1 - x0, y1 - y0
cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
w, h = w * 1.3 + 20, h * 1.3 + 20
if w / h < 16 / 9: w = h * 16 / 9
else: h = w * 9 / 16
w, h = min(w, W), min(h, H)
x0 = int(max(0, min(W - w, cx - w / 2))); y0 = int(max(0, min(H - h, cy - h / 2)))
crop = (x0, y0, int(x0 + w), int(y0 + h))
os.makedirs(out, exist_ok=True)
for p in paths:
    Image.open(p).convert("RGB").crop(crop).save(os.path.join(out, os.path.basename(os.path.dirname(p)) + "-" + os.path.basename(p)))
print(crop)
