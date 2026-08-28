#!/usr/bin/env python3
"""GRASS-REROLL. Put a number on "the grass rerenders like every step".

    python3 tools/grass_reroll_diff.py shots/reroll_before shots/reroll_after

The `held-NN` frames from `tools/_probe_grass_walk.gd` are taken from a camera
that DOES NOT MOVE while the ring's own follow-camera walks. Wind is off. So
two consecutive held frames differ only by what the ring did when its centre
crossed a lattice cell, and the mean absolute difference between them is the
re-roll, in 0-255 units per channel, with nothing else in it.

The bottom band of the frame is reported separately because that is where a
single tuft is a hundred pixels tall and a re-roll is unmistakable, and the
whole-frame figure is diluted by a third of the image being sky.

The player model occupies the middle of the frame and is identical in every
held exposure, so it contributes zero to the difference and needs no mask.

This measures WHAT CHANGED BETWEEN FRAMES. It is not a performance
measurement and cannot be: `PERF-ROG-GPU` records that no container in this
project can measure GPU cost, and this one rasterises in software.
"""
import sys, os, glob
import numpy as np
from PIL import Image


def load(path):
    return np.asarray(Image.open(path).convert("RGB"), dtype=np.int16)


def report(directory, prefix="held-"):
    frames = sorted(glob.glob(os.path.join(directory, prefix + "*.png")))
    if len(frames) < 2:
        print(f"{directory}: fewer than two {prefix}frames, nothing to compare")
        return None
    first = load(frames[0])
    h = first.shape[0]
    ground = slice(int(h * 0.55), h)
    whole, near = [], []
    for a, b in zip(frames, frames[1:]):
        d = np.abs(load(a) - load(b))
        whole.append(d.mean())
        near.append(d[ground].mean())
    print(f"{directory}  ({len(frames)} frames, {len(whole)} consecutive pairs)")
    print(f"  whole frame : mean {np.mean(whole):6.3f}   worst pair {max(whole):6.3f}")
    print(f"  near ground : mean {np.mean(near):6.3f}   worst pair {max(near):6.3f}")
    print("  per pair (near ground): " + " ".join(f"{v:.2f}" for v in near))
    return np.mean(near), max(near)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        raise SystemExit(2)
    results = [report(d) for d in sys.argv[1:]]
    if len(results) == 2 and results[0] and results[1]:
        before, after = results[0][0], results[1][0]
        if before > 0:
            print(f"\nnear-ground change between consecutive held frames: "
                  f"{before:.3f} -> {after:.3f}  ({after / before - 1:+.0%})")
