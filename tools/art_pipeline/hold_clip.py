#!/usr/bin/env python3
"""Hold one clip's peak pose through the end of the clip, in the GLB.

Visual lane (3 Nov 2026): three CPU judges on the stage-pose rows (v1/b7,
F38#2 and F36#56) say the hit react reads at mid-clip but "hit react end is
back to the idle silhouette, so the hurt state is lost". The game crossfades
to idle after the clip ends anyway, so the clip itself can keep the hunch.
The peak is the key time where the summed rotation deviation from rest is
largest (over --bones if given, else all bones); every rotation and
translation key after that time is set to its value at the peak. Timing,
scale, other clips and the mesh are untouched. No Blender.

    python3 tools/art_pipeline/hold_clip.py model.glb hit [--bones=spine,spine_2,root] [--dry-run]
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rigid_bind_region import load, save, view  # noqa: E402
from amplify_clip import qmul  # noqa: E402


def sample(times, values, t):
    i = int(np.searchsorted(times, t, side="right")) - 1
    return values[max(i, 0)].copy()


def main():
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    path, clip = args[0], args[1]
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
    channels = []
    for ch in anim["channels"]:
        if ch["target"]["path"] not in ("rotation", "translation"):
            continue
        node = gltf["nodes"][ch["target"]["node"]]
        sampler = anim["samplers"][ch["sampler"]]
        if sampler.get("interpolation", "LINEAR") == "CUBICSPLINE":
            raise SystemExit("%s: cubic-spline keys are not supported" % node.get("name", ""))
        if used[sampler["output"]] > 1:
            raise SystemExit("%s/%s output accessor is shared with another clip" % (clip, node.get("name", "")))
        times = view(gltf, binary, sampler["input"]).astype(float).reshape(-1)
        channels.append((ch, node, times, view(gltf, binary, sampler["output"])))
    # Peak: the key time with the largest summed rotation deviation from rest.
    all_times = np.unique(np.concatenate([c[2] for c in channels]))
    score = np.zeros(len(all_times))
    for ch, node, times, keys in channels:
        if ch["target"]["path"] != "rotation" or (bones is not None and node.get("name", "") not in bones):
            continue
        rest = np.array(node.get("rotation", [0, 0, 0, 1]), float)
        rest_inv = rest * np.array([-1, -1, -1, 1])
        for j, t in enumerate(all_times):
            d = qmul(rest_inv[None, :], sample(times, keys.astype(float), t)[None, :])[0]
            score[j] += 2 * np.arccos(np.clip(abs(d[3]), 0, 1))
    peak = float(all_times[int(np.argmax(score))])
    end = float(all_times[-1])
    print("%s: peak at %.3fs of %.3fs (deviation %.1f deg summed)" % (clip, peak, end, np.degrees(score.max())))
    held = 0
    for ch, node, times, keys in channels:
        after = times > peak + 1e-6
        if not after.any():
            continue
        keys[after] = sample(times, keys, peak).astype(keys.dtype)
        held += int(after.sum())
    print("%s: %d keys held at the peak pose" % (clip, held))
    if "--dry-run" not in sys.argv:
        save(path, gltf, binary)


if __name__ == "__main__":
    main()
