#!/usr/bin/env python3
"""Layer a sideways recoil onto one clip, in a copy of the GLB.

Creatures-ralph (4 Nov 2026): F38#2 judges (qj rim10) say the Meadows hurt
frames "retain the idle silhouette": the authored hit is a fore-aft shove,
which barely changes the outline seen face-on (the field camera, and a
creature facing its trainer). A blow that also leans the body and tosses the
head to one side reads from any angle. This adds, per bone, a rotation about a
MODEL-space axis (glTF: +Y up, +Z forward) through the bone's own origin, on
top of every authored rotation key, scaled by an envelope over the clip:
ramp in to full by --peak (fraction of the clip, default 0.12, the species'
hit_impact.start_phase), hold to --release (default 0.5), ease out to zero at
the clip end. Translation, scale, other clips and the mesh are untouched.
No Blender.

    python3 tools/art_pipeline/lateral_recoil.py in.glb hit out.glb \
        --spec=spine:z:12,neck:y:18,head:z:14 [--peak=0.12] [--release=0.5] [--dry-run]
"""
import os
import shutil
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rigid_bind_region import load, save, view  # noqa: E402
from amplify_clip import qmul  # noqa: E402

AXES = {"x": (1.0, 0.0, 0.0), "y": (0.0, 1.0, 0.0), "z": (0.0, 0.0, 1.0)}


def qconj(q):
    return q * np.array([-1.0, -1.0, -1.0, 1.0])


def axis_angle(axis, deg):
    a = np.radians(deg) * 0.5
    v = np.asarray(axis, float)
    return np.concatenate([v / np.linalg.norm(v) * np.sin(a), [np.cos(a)]])


def smooth(x):
    x = np.clip(x, 0.0, 1.0)
    return x * x * (3.0 - 2.0 * x)


def envelope(t, dur, peak, release):
    p = max(peak * dur, 1e-4)
    r = release * dur
    rise = smooth(t / p)
    fall = 1.0 - smooth((t - r) / max(dur - r, 1e-4))
    return np.where(t <= r, rise, fall)


def global_rest(gltf):
    parent = {}
    for i, n in enumerate(gltf["nodes"]):
        for c in n.get("children", []):
            parent[c] = i
    memo = {}

    def g(i):
        if i in memo:
            return memo[i]
        local = np.array(gltf["nodes"][i].get("rotation", [0, 0, 0, 1]), float)
        out = qmul(g(parent[i])[None], local[None])[0] if i in parent else local
        memo[i] = out
        return out
    return parent, g


def main():
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    src, clip, out = args[0], args[1], args[2]
    peak = float(opts.get("peak", 0.12))
    release = float(opts.get("release", 0.5))
    spec = {}
    for part in opts["spec"].split(","):
        bone, axis, deg = part.split(":")
        spec[bone] = (AXES[axis], float(deg))
    gltf, binary = load(src)
    names = {i: n.get("name", "") for i, n in enumerate(gltf["nodes"])}
    parent, grest = global_rest(gltf)
    anim = [a for a in gltf["animations"] if a["name"] == clip]
    if not anim:
        raise SystemExit("no clip %s" % clip)
    anim = anim[0]
    used = {}
    for a in gltf["animations"]:
        for s in a["samplers"]:
            used[s["output"]] = used.get(s["output"], 0) + 1
    dur = 0.0
    for ch in anim["channels"]:
        dur = max(dur, float(view(gltf, binary, anim["samplers"][ch["sampler"]]["input"]).max()))
    done = set()
    for ch in anim["channels"]:
        node = ch["target"]["node"]
        bone = names[node]
        if ch["target"]["path"] != "rotation" or bone not in spec:
            continue
        sampler = anim["samplers"][ch["sampler"]]
        if used[sampler["output"]] > 1:
            raise SystemExit("%s/%s output accessor is shared with another clip" % (clip, bone))
        times = view(gltf, binary, sampler["input"]).astype(float).reshape(-1)
        keys = view(gltf, binary, sampler["output"])
        gp = grest(parent[node]) if node in parent else np.array([0, 0, 0, 1.0])
        axis, deg = spec[bone]
        env = envelope(times, dur, peak, release)
        q = keys.astype(float)
        outq = np.empty_like(q)
        for i, (k, e) in enumerate(zip(q, env)):
            r = axis_angle(axis, deg * e)
            local_r = qmul(qmul(qconj(gp)[None], r[None]), gp[None])[0]
            outq[i] = qmul(local_r[None], k[None])[0]
        print("%s %s: %+.1f deg about %s, %d keys, envelope max %.2f at %.3fs of %.3fs" % (
            clip, bone, deg, "xyz"["xyz".index([k for k, v in AXES.items() if v == axis][0])],
            len(q), env.max(), times[int(env.argmax())], dur))
        if "--dry-run" not in sys.argv:
            keys[:] = outq.astype(keys.dtype)
        done.add(bone)
    missing = set(spec) - done
    if missing:
        raise SystemExit("no %s rotation channel for %s" % (clip, sorted(missing)))
    if "--dry-run" not in sys.argv:
        if os.path.abspath(src) != os.path.abspath(out):
            shutil.copyfile(src, out)
        save(out, gltf, binary)


if __name__ == "__main__":
    main()
