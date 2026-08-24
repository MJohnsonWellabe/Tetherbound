#!/usr/bin/env python3
"""Repaint the Team Tether rig's own texture into the faction's reserved oxblood.

WHY THIS EXISTS, and why the material-parameter approach it replaces could not
work. `assets/characters/grunt/grunt_lod0_texture_0.png` is a near-black tactical
outfit: median value 0.114, only 3.2% of it above 0.35, with tan leather straps
near 0.60. Three blind rounds in a row said the faction was illegible -- "eight
interchangeable dark-muddy figures", "collapses into near-black smears" -- and
two attempts to fix it in `character_model.gd` failed in opposite directions,
for reasons that are pure arithmetic:

    cloth 0.08 vs straps 0.60 is a 7.5x contrast ratio.
    a constant ADD of 0.13  -> 0.21 vs 0.73 = 3.5x. Contrast halved. A round
                               called the result "washed, blacks lifted to grey,
                               the faction looks like the least finished art in
                               the game".
    a MULTIPLY of 4x        -> 0.32 vs 2.40. Highlights blown off the top.

No single material parameter can raise a near-black texture into a readable
value band without either flattening its darks or clipping its lights, because
the texture's own dynamic range is the constraint. The fix has to happen where
the range lives: in the texture.

`CLAUDE.md` sanctions exactly this -- human NPCs are differentiated "per
material" and by texture, and `data/config/palette.json`'s `_reserved` note says
`tether_oxblood` belongs on Team Tether "banners, equipment AND UNIFORMS". This
writes the faction's colour into the faction's own rig once, correctly, instead
of asking a runtime tint to manufacture it every frame.

Two operations, both region-limited:

  HUE   the dark blue-purple CLOTH (hue 235-305, ~39% of chromatic texels) moves
        to oxblood. The tan LEATHER (hue 0-45) is left alone -- it is straps,
        buckles and holsters, it reads as leather, and recolouring it would turn
        the uniform into one flat red mass.
  VALUE a gamma lift on the cloth only. Gamma is monotonic, so it preserves the
        ordering and the local contrast of every fold and panel; unlike an add it
        does not raise the blacks and the mids by the same absolute amount, and
        unlike a gain it cannot clip. Some compression is unavoidable when
        brightening anything dark -- that is arithmetic, not a choice -- but
        gamma spends the least of it.

Idempotent: output is a pure function of the source. Run from the repo root.
    python3 tools/repaint_grunt_faction.py [--gamma 0.62] [--check]
"""
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "characters", "grunt", "grunt_lod0_texture_0.png")

CLOTH_HUE = (235.0, 305.0)   # the dark blue-purple uniform cloth
OXBLOOD_HUE = 355.0          # data/config/palette.json's reserved family
LEATHER_HUE = (0.0, 45.0)    # straps and buckles -- untouched


def rgb_to_hsv(a):
    mx = a.max(axis=2); mn = a.min(axis=2); d = mx - mn
    v = mx
    s = np.where(mx > 0, d / np.maximum(mx, 1e-9), 0.0)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    h = np.zeros_like(mx)
    m = d > 1e-9
    h = np.where(m & (mx == r), ((g - b) / np.maximum(d, 1e-9)) % 6, h)
    h = np.where(m & (mx == g), (b - r) / np.maximum(d, 1e-9) + 2, h)
    h = np.where(m & (mx == b), (r - g) / np.maximum(d, 1e-9) + 4, h)
    return h * 60.0, s, v


def hsv_to_rgb(h, s, v):
    h = h % 360.0
    c = v * s
    x = c * (1 - np.abs((h / 60.0) % 2 - 1))
    m = v - c
    z = np.zeros_like(h)
    i = (h / 60).astype(int) % 6
    r = np.select([i == 0, i == 1, i == 2, i == 3, i == 4, i == 5], [c, x, z, z, x, c])
    g = np.select([i == 0, i == 1, i == 2, i == 3, i == 4, i == 5], [x, c, c, x, z, z])
    b = np.select([i == 0, i == 1, i == 2, i == 3, i == 4, i == 5], [z, z, x, c, c, x])
    return np.stack([r + m, g + m, b + m], axis=-1)


def main():
    gamma = 0.62
    if "--gamma" in sys.argv:
        gamma = float(sys.argv[sys.argv.index("--gamma") + 1])
    check = "--check" in sys.argv

    img = Image.open(SRC).convert("RGB")
    a = np.asarray(img).astype(np.float64) / 255.0
    h, s, v = rgb_to_hsv(a)

    cloth = (h >= CLOTH_HUE[0]) & (h <= CLOTH_HUE[1]) & (s > 0.06)
    # Very dark near-neutral texels belong to the same garment and carry no usable
    # hue; without them the cloth recolours in patches and the seams show.
    cloth |= (v < 0.16) & (s <= 0.06) & ~((h >= LEATHER_HUE[0]) & (h <= LEATHER_HUE[1]) & (s > 0.18))

    before_v = v[cloth].mean() if cloth.any() else 0.0
    h2 = np.where(cloth, OXBLOOD_HUE, h)
    s2 = np.where(cloth, np.clip(np.maximum(s, 0.34) * 1.05, 0, 0.72), s)
    v2 = np.where(cloth, np.power(np.clip(v, 0, 1), gamma), v)

    out = np.clip(hsv_to_rgb(h2, s2, v2), 0, 1)
    print("cloth texels: %.1f%% of the sheet" % (100.0 * cloth.mean()))
    print("cloth value:  %.3f -> %.3f   (gamma %.2f)" % (before_v, v2[cloth].mean(), gamma))
    print("leather left untouched: %.1f%% of the sheet"
          % (100.0 * (((h >= LEATHER_HUE[0]) & (h <= LEATHER_HUE[1]) & (s > 0.18)).mean())))
    if check:
        print("--check: nothing written")
        return
    Image.fromarray((out * 255).round().astype(np.uint8)).save(SRC)
    print("wrote", os.path.relpath(SRC, ROOT))


if __name__ == "__main__":
    main()
