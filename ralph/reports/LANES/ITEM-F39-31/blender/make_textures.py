#!/usr/bin/env python3
"""Tileable 512px textures for the Blender Veilfall (F39#31/#2, LANE-TW). Usage: make_textures.py <out_dir> (write to a scratch dir; the GLB embeds them)"""
import sys, numpy as np
from PIL import Image
out = sys.argv[1]; N = 512; rng = np.random.default_rng(31)
def fbm(oct=5, base=4):
    acc = np.zeros((N, N)); amp = 1.0; tot = 0
    for o in range(oct):
        f = base * 2 ** o
        g = rng.standard_normal((f, f))
        img = np.array(Image.fromarray(g.astype(np.float32)).resize((N, N), Image.BICUBIC))
        # tileable: average with rolled copy edges
        acc += amp * img; tot += amp; amp *= 0.5
    a = acc / tot; return (a - a.min()) / (a.max() - a.min())
def tile(a):  # blend opposite halves so wrap is soft
    return 0.5 * (a + np.roll(np.roll(a, N // 2, 0), N // 2, 1))
def save(name, rgb):
    Image.fromarray(np.clip(rgb * 255, 0, 255).astype(np.uint8)).save(f"{out}/{name}.png")
y = np.linspace(0, 1, N, endpoint=False)[:, None]; x = np.linspace(0, 1, N, endpoint=False)[None, :]
# rock: warm grey limestone, broken strata, soft irregular weathering (no regular grid)
n = tile(fbm()); w = tile(fbm(4, 6))
strata = 0.5 + 0.5 * np.sin(2 * np.pi * (y * 5 + 0.9 * w + 0.3 * n))
strata = strata * (tile(fbm(3, 3)) > 0.45)
run = tile(fbm(5, 24)); streak = np.clip((run - 0.6) * 2.5, 0, 1) * np.clip((tile(fbm(3, 5)) - 0.4) * 3, 0, 1)
v = 0.46 + 0.26 * n + 0.05 * strata - 0.12 * streak
save("veilfall_rock", np.dstack([v * 1.00, v * 0.97, v * 0.90]))
# moss / ledge turf
n = tile(fbm(5, 8)); m = tile(fbm(3, 4))
base = np.array([0.36, 0.52, 0.25]); hi = np.array([0.55, 0.66, 0.33])
save("veilfall_moss", base * (1 - n[..., None] * 0.6) + hi * (n[..., None] * 0.6) - 0.06 * m[..., None])
# foliage: dark conifer/broadleaf canopy with light dapples
n = tile(fbm(5, 16)); d = np.clip((tile(fbm(3, 32)) - 0.55) * 4, 0, 1)
save("veilfall_foliage", np.array([0.16, 0.30, 0.15]) * (0.75 + 0.5 * n[..., None]) + np.array([0.20, 0.25, 0.10]) * d[..., None])
# falling water: white with faint blue-grey vertical streaks (streaks run along v)
s = tile(fbm(4, 32)); streak = 0.5 + 0.5 * np.sin(2 * np.pi * (x * 14 + 0.6 * s))
w = 0.86 + 0.12 * streak * (0.6 + 0.4 * s)
save("veilfall_water", np.dstack([w * 0.93, w * 0.97, w * 1.0]))
# foam / mist
n = tile(fbm(4, 8)); f = 0.88 + 0.12 * n
save("veilfall_foam", np.dstack([f * 0.95, f * 0.98, f]))
