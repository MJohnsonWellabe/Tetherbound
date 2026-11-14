#!/usr/bin/env python3
"""BEINGS-STORMRAVEN-ARCS (F41#13, F36#74): branching white-violet arcs on the Stormraven.

F41#13 judges (G-things-wardenring-f41-13-closeout, 3/3): the raven's speckles "read
more like frost or sequins than lightning"; ask: "branching white-violet arcs along
the raven's feathers". The shipped glow (glow_read_r2) is scattered blobs because
it was picked texel by texel on a fragmented Meshy atlas.

This draws the arcs in the model's own space instead (tools/art_pipeline/
grade_vis_traits.py anatomy_for: each texel's model position and normal), seen
from the side: on each flank a jagged main bolt runs from the shoulder back along
the folded wing to the tip, with a few forks. A texel lights when it faces that
side and lies near a bolt, so a bolt crosses UV seams unbroken. The eye glow of
glow_read_r2 is kept on the head; elsewhere the old speckles stay at a third
of their strength as a faint feather sheen under the bolts. Albedo: the bolt cores are lightened a
little so the line still reads where emission is weak. Deterministic (seeded).

    python3 ralph/reports/LANES/BEINGS-STORMRAVEN-ARCS/make_arcs.py
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
sys.path.insert(0, os.path.join(ROOT, "tools", "art_pipeline"))
import grade_vis_traits as G  # noqa: E402

D = "assets/creatures/tetherbound/stormraven/candidate_owner1101/models/"
GLB = D + "creature_stormraven_owner1101.glb"
ALBEDO = D + "creature_stormraven_owner1101_Image_0_night.png"
OLD_GLOW = D + "creature_stormraven_owner1101_glow_read_r2.png"
OUT_ALBEDO = D + "creature_stormraven_owner1101_Image_0_night_arcs.png"
OUT_GLOW = D + "creature_stormraven_owner1101_glow_arcs.png"
CORE = np.array([0.92, 0.88, 1.0])     # white-violet
HALO = np.array([0.55, 0.42, 1.0])     # violet
CORE_W, HALO_W = 0.0085, 0.026
FLECK_KEEP = 0.33                      # the old speckle glow, kept faint as feather sheen         # in unit (0..1) body coordinates
HEAD_Z = 0.80                          # texels forward of this keep the old (eye) glow


def jagged(p0, p1, rng, depth=6, rough=0.22):
    pts = [np.array(p0, float), np.array(p1, float)]
    for _ in range(depth):
        out = [pts[0]]
        for a, b in zip(pts[:-1], pts[1:]):
            d = b - a
            n = np.array([-d[1], d[0]])
            mid = (a + b) / 2 + n * rng.uniform(-rough, rough)
            out += [mid, b]
        pts = out
        rough *= 0.62
    return np.array(pts)


def bolts(rng):
    # (z, y) in unit coords: head is +z, tail -z. Main bolt shoulder -> wing tip.
    # Placed on a side-facing map of the model (shoulder at about (0.70, 0.66),
    # folded wing tip at about (0.13, 0.24)).
    main = jagged((0.70, 0.64), (0.16, 0.27), rng, rough=0.2)
    out = [main]
    for t in (0.25, 0.48, 0.7):
        i = int(t * (len(main) - 1))
        start = main[i]
        end = start + np.array([rng.uniform(-0.12, -0.06), rng.uniform(-0.13, -0.06)])
        out.append(jagged(start, end, rng, depth=4, rough=0.2))
    return out


def seg_dist(points, lines):
    best = np.full(len(points), np.inf)
    for line in lines:
        a, b = line[:-1], line[1:]
        for p0, p1 in zip(a, b):
            d = p1 - p0
            t = np.clip(((points - p0) @ d) / max(d @ d, 1e-12), 0.0, 1.0)
            proj = p0 + t[:, None] * d
            best = np.minimum(best, np.linalg.norm(points - proj, axis=1))
    return best


def main():
    albedo = np.asarray(Image.open(os.path.join(ROOT, ALBEDO)).convert("RGB")).astype(np.float64) / 255.0
    old_glow = np.asarray(Image.open(os.path.join(ROOT, OLD_GLOW)).convert("RGB")).astype(np.float64) / 255.0
    size = albedo.shape[0]
    anatomy = G.anatomy_for(GLB, size)
    unit, nrm, valid = anatomy["unit"], anatomy["nrm"], anatomy["valid"] > 0
    core = np.zeros((size, size))
    halo = np.zeros((size, size))
    for side, seed in ((1.0, 11), (-1.0, 12)):
        facing = valid & (nrm[..., 0] * side > 0.25) & (unit[..., 2] < HEAD_Z)
        ys, xs = np.nonzero(facing)
        pts = np.stack([unit[ys, xs, 2], unit[ys, xs, 1]], axis=1)
        dist = seg_dist(pts, bolts(np.random.default_rng(seed)))
        core[ys, xs] = np.maximum(core[ys, xs], np.clip(1.0 - dist / CORE_W, 0.0, 1.0))
        halo[ys, xs] = np.maximum(halo[ys, xs], np.clip(1.0 - dist / HALO_W, 0.0, 1.0) ** 2)
    head = valid & (unit[..., 2] >= HEAD_Z)
    glow = core[..., None] * CORE + (halo * (1.0 - core))[..., None] * HALO * 0.55
    glow = np.maximum(glow, old_glow * FLECK_KEEP)
    glow = np.where(head[..., None], old_glow, glow)
    glow_image = Image.fromarray((np.clip(glow, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
    glow_image.save(os.path.join(ROOT, OUT_GLOW))
    lit = albedo * (1.0 - 0.55 * core[..., None]) + CORE * 0.55 * core[..., None]
    Image.fromarray((np.clip(lit, 0, 1) * 255).astype(np.uint8)).save(os.path.join(ROOT, OUT_ALBEDO))
    print("arc core texels %.3f%%, halo %.3f%% of the surface"
          % (100.0 * (core > 0.5).sum() / valid.sum(), 100.0 * (halo > 0.2).sum() / valid.sum()))


if __name__ == "__main__":
    main()
