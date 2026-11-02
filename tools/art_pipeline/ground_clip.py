#!/usr/bin/env python3
"""Keep a clip's skinned mesh on the floor, key by key (Creatures-ralph, 2 Nov 2026).

A deeper faint roll on the dog3 recipe sinks the body into the stage (up to
0.5 m on the r9 quadrupeds). At every root-translation key of the clip this
skins the mesh on the CPU and, where its lowest vertex is below y = 0, raises
that key by exactly the overlap (plus a 1 cm margin), so the pose rests on the
ground without floating. Rotations, other clips and the mesh are untouched.

    python3 tools/art_pipeline/ground_clip.py model.glb faint [--percentile=2]

--percentile grounds a low percentile of the vertices instead of the lowest
one, so a thin wing or fin swinging through the floor does not hold the body
up in the air (Tempestwing, Ribbonray). --settle also lowers keys whose
percentile sits above the floor, so a pose propped up on a limb comes down;
--hop=F scales the clip's root lift above its first key by F (a hit hop that
leaves the floor).
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from relax_stretched_weights import Skin, load, save, view  # noqa: E402


def main():
    path, clip = sys.argv[1], sys.argv[2]
    pct = 0.0
    settle = "--settle" in sys.argv[3:]
    hop = None
    for arg in sys.argv[3:]:
        if arg.startswith("--percentile="):
            pct = float(arg.split("=", 1)[1])
        if arg.startswith("--hop="):
            hop = float(arg.split("=", 1)[1])
    gltf, binary = load(path)
    prim = gltf["meshes"][0]["primitives"][0]
    skin = Skin(gltf, binary, prim)
    joints = view(gltf, binary, prim["attributes"]["JOINTS_0"]).astype(int)
    weights = view(gltf, binary, prim["attributes"]["WEIGHTS_0"]).astype(float)
    anim = [a for a in gltf["animations"] if a["name"] == clip][0]
    channel = [c for c in anim["channels"] if gltf["nodes"][c["target"]["node"]].get("name") == "root"
               and c["target"]["path"] == "translation"]
    if not channel:
        raise SystemExit("%s has no root translation channel" % clip)
    sampler = anim["samplers"][channel[0]["sampler"]]
    times = view(gltf, binary, sampler["input"]).ravel().astype(float)
    keys = view(gltf, binary, sampler["output"])
    if hop is not None:
        base = float(keys[0, 1])
        keys[:, 1] = base + (keys[:, 1] - base) * hop
    lifted = 0
    for i, t in enumerate(times):
        low = float(np.percentile(skin.pose(joints, weights, anim, t)[:, 1], pct))
        if low < 0.0 or (settle and low > 0.01):
            keys[i, 1] += -low + 0.01
            lifted += 1
    save(path, gltf, binary)
    print("%s: moved %d of %d root keys onto the floor" % (clip, lifted, len(times)))


if __name__ == "__main__":
    main()
