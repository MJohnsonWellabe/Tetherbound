#!/usr/bin/env python3
"""Exaggerate one clip's bone rotations away from the rest pose, in the GLB.

Creatures-ralph (2 Nov 2026): batch-4 GPU judges on remakes whose recipe clips
move too little at the stage camera ("barely animates", "barely changes
between poses"). Each rotation key of the named clip becomes
rest * (rest^-1 * key)^factor (axis-angle scaled), optionally per bone, so the
same motion reads bigger with the same timing. Translation, scale, other clips
and the mesh are untouched. No Blender.

    python3 tools/art_pipeline/amplify_clip.py model.glb hit 2.2 [--bones=spine_2,head] [--dry-run]
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rigid_bind_region import load, save, view  # noqa: E402


def qmul(a, b):
    ax, ay, az, aw = a.T
    bx, by, bz, bw = b.T
    return np.stack([aw * bx + ax * bw + ay * bz - az * by,
                     aw * by - ax * bz + ay * bw + az * bx,
                     aw * bz + ax * by - ay * bx + az * bw,
                     aw * bw - ax * bx - ay * by - az * bz], -1)


def qpow(q, k):
    q = q * np.where(q[:, 3:4] < 0, -1.0, 1.0)
    w = np.clip(q[:, 3], -1.0, 1.0)
    ang = 2.0 * np.arccos(w)
    s = np.sqrt(np.maximum(1.0 - w * w, 1e-12))
    axis = q[:, :3] / s[:, None]
    half = ang * k * 0.5
    out = np.concatenate([axis * np.sin(half)[:, None], np.cos(half)[:, None]], -1)
    out[ang < 1e-6] = [0, 0, 0, 1]
    return out


def main():
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    path, clip, factor = args[0], args[1], float(args[2])
    bones = set(opts["bones"].split(",")) if "bones" in opts else None
    gltf, binary = load(path)
    anim = [a for a in gltf["animations"] if a["name"] == clip]
    if not anim:
        raise SystemExit("no clip %s" % clip)
    anim = anim[0]
    used = {}
    for a in gltf["animations"]:
        for s in a["samplers"]:
            used[s["output"]] = used.get(s["output"], 0) + 1
    for ch in anim["channels"]:
        if ch["target"]["path"] != "rotation":
            continue
        node = gltf["nodes"][ch["target"]["node"]]
        name = node.get("name", "")
        if bones is not None and name not in bones:
            continue
        sampler = anim["samplers"][ch["sampler"]]
        if used[sampler["output"]] > 1:
            raise SystemExit("%s/%s output accessor is shared with another clip" % (clip, name))
        keys = view(gltf, binary, sampler["output"])
        rest = np.array(node.get("rotation", [0, 0, 0, 1]), float)
        q = keys.astype(float)
        rest_inv = np.tile(rest * np.array([-1, -1, -1, 1]), (len(q), 1))
        delta = qmul(rest_inv, q)
        before = np.degrees(2 * np.arccos(np.clip(np.abs(delta[:, 3]), 0, 1))).max()
        out = qmul(np.tile(rest, (len(q), 1)), qpow(delta, factor))
        after = np.degrees(2 * np.arccos(np.clip(np.abs(qmul(rest_inv, out)[:, 3]), 0, 1))).max()
        print("%s %s: max %.1f -> %.1f deg over %d keys" % (clip, name, before, after, len(q)))
        if "--dry-run" not in sys.argv:
            keys[:] = out.astype(keys.dtype)
    if "--dry-run" not in sys.argv:
        save(path, gltf, binary)


if __name__ == "__main__":
    main()
