#!/usr/bin/env python3
"""Open a Meshy ring building's interior: drop floor triangles inside the wall.

Image-to-3D returns a closed floor disc under hollow buildings. Every triangle
whose vertices all sit in the bottom --height-frac of the model and inside
--radius-frac of its outer radius becomes degenerate (same buffer layout, no
re-encoding). The outer plinth and the walls are kept.

    python3 tools/meshy_strip_floor.py <in.glb> <out.glb> [--height-frac 0.05] [--radius-frac 0.68]
"""
import argparse
import json
import struct

import numpy as np


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--height-frac", type=float, default=0.05)
    ap.add_argument("--radius-frac", type=float, default=0.68)
    a = ap.parse_args()
    raw = bytearray(open(a.src, "rb").read())
    jlen = struct.unpack("<I", raw[12:16])[0]
    doc = json.loads(raw[20:20 + jlen])
    bin0 = 20 + jlen + 8
    removed = 0
    for mesh in doc["meshes"]:
        for prim in mesh["primitives"]:
            pa = doc["accessors"][prim["attributes"]["POSITION"]]
            pv = doc["bufferViews"][pa["bufferView"]]
            po = bin0 + pv.get("byteOffset", 0) + pa.get("byteOffset", 0)
            pos = np.frombuffer(raw, np.float32, pa["count"] * 3, po).reshape(-1, 3)
            ia = doc["accessors"][prim["indices"]]
            iv = doc["bufferViews"][ia["bufferView"]]
            dtype = {5125: np.uint32, 5123: np.uint16}[ia["componentType"]]
            io = bin0 + iv.get("byteOffset", 0) + ia.get("byteOffset", 0)
            idx = np.frombuffer(raw, dtype, ia["count"], io).copy().reshape(-1, 3)
            lo, hi = pos.min(0), pos.max(0)
            centre = (lo + hi) / 2
            radius = np.hypot(pos[:, 0] - centre[0], pos[:, 2] - centre[2])
            outer = radius.max()
            floor = (pos[:, 1] < lo[1] + a.height_frac * (hi[1] - lo[1])) & (radius < a.radius_frac * outer)
            drop = floor[idx].all(1)
            idx[drop] = idx[drop][:, :1]
            removed += int(drop.sum())
            raw[io:io + idx.nbytes] = idx.astype(dtype).tobytes()
    open(a.dst, "wb").write(raw)
    print(f"{a.dst}: {removed} floor triangles made degenerate")


if __name__ == "__main__":
    main()
