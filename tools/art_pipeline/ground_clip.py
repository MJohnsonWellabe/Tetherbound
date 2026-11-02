#!/usr/bin/env python3
"""Keep a clip's skinned mesh on the floor, key by key (Creatures-ralph, 2 Nov 2026).

A deeper faint roll on the dog3 recipe sinks the body into the stage (up to
0.5 m on the r9 quadrupeds). At every root-translation key of the clip this
skins the mesh on the CPU and, where its lowest vertex is below y = 0, raises
that key by exactly the overlap (plus a 1 cm margin), so the pose rests on the
ground without floating. Rotations, other clips and the mesh are untouched.

    python3 tools/art_pipeline/ground_clip.py model.glb faint
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from relax_stretched_weights import Skin, load, save, view  # noqa: E402


def main():
    path, clip = sys.argv[1], sys.argv[2]
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
    lifted = 0
    for i, t in enumerate(times):
        low = float(skin.pose(joints, weights, anim, t)[:, 1].min())
        if low < 0.0:
            keys[i, 1] += -low + 0.01
            lifted += 1
    save(path, gltf, binary)
    print("%s: lifted %d of %d root keys onto the floor" % (clip, lifted, len(times)))


if __name__ == "__main__":
    main()
